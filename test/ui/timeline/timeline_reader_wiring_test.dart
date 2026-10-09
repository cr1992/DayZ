// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/shell_state.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

import '../../l10n/localized_test_app.dart';
import 'fake_entry_repo.dart';

void main() {
  late FakeEntryRepo repo;
  late GoRouter router;
  late List<Object?> readerExtras;

  setUp(() {
    readerExtras = <Object?>[];
    repo = FakeEntryRepo(
      entries: [
        fakeEntry(
          id: 'entry-1',
          entryDtUtc: DateTime.utc(2026, 6, 18, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 18,
          contentPlain: '第一篇\nSummary',
        ),
      ],
    );
    final shellState = ShellState();
    router = GoRouter(
      initialLocation: Routes.timelinePath,
      routes: [
        GoRoute(
          name: Routes.timeline,
          path: Routes.timelinePath,
          builder: (context, state) =>
              TimelineShellPage(repo: repo, shellState: shellState),
        ),
        GoRoute(
          name: Routes.reader,
          path: Routes.readerPath,
          builder: (context, state) {
            readerExtras.add(state.extra);
            return Scaffold(
              body: TextButton(
                onPressed: () => context.pop(),
                child: const Text('reader-stub'),
              ),
            );
          },
        ),
      ],
    );
  });

  tearDown(() => router.dispose());

  testWidgets('tapping a card pushes the reader so back returns to timeline', (
    tester,
  ) async {
    await tester.pumpWidget(localizedRouterTestApp(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('第一篇'));
    await tester.pumpAndSettle();

    expect(find.text('reader-stub'), findsOneWidget);
    expect(readerExtras, ['entry-1']);

    await tester.tap(find.text('reader-stub'));
    await tester.pumpAndSettle();

    expect(find.text('第一篇'), findsOneWidget);
  });

  testWidgets('a write landing while the timeline is covered refreshes it', (
    tester,
  ) async {
    await tester.pumpWidget(localizedRouterTestApp(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('新写的一篇'), findsNothing);

    repo.addEntry(
      fakeEntry(
        id: 'entry-2',
        entryDtUtc: DateTime.utc(2026, 6, 19, 10),
        localYear: 2026,
        localMonth: 6,
        localDay: 19,
        contentPlain: '新写的一篇\nSummary',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('新写的一篇'), findsOneWidget);
    expect(find.text('第一篇'), findsOneWidget);
  });
}
