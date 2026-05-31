// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/app_shell.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/shell/shell_state.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

import '../../l10n/localized_test_app.dart';
import 'fake_entry_repo.dart';

void main() {
  late ShellState shellState;
  late FakeEntryRepo repo;
  late GoRouter router;

  setUp(() {
    shellState = ShellState(
      initialJournals: const [
        JournalSummary(
          id: 'journal-a',
          name: '工作日志',
          color: '#786CAD',
          count: 1,
        ),
        JournalSummary(
          id: 'journal-b',
          name: '旅行手记',
          color: '#C67D33',
          count: 1,
        ),
      ],
      initialJournalId: 'journal-a',
    );
    repo = FakeEntryRepo(
      entries: [
        fakeEntry(
          id: 'journal-a-entry',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 6, 18, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 18,
          contentPlain: '工作日志首篇\nSummary',
        ),
        fakeEntry(
          id: 'journal-b-entry',
          journalId: 'journal-b',
          entryDtUtc: DateTime.utc(2026, 6, 16, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 16,
          contentPlain: '旅行手记首篇\nSummary',
        ),
      ],
    );
    router = GoRouter(
      initialLocation: Routes.timelinePath,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return ListenableBuilder(
              listenable: shellState,
              builder: (context, _) {
                return AppShell(
                  body: child,
                  journals: shellState.journals,
                  currentJournalId: shellState.currentJournalId,
                  currentRoute: state.topRoute?.name ?? state.name,
                  onSelectJournal: shellState.selectJournal,
                  onNavigate: (route) => context.pushNamed(route),
                  onNewJournal: () {},
                );
              },
            );
          },
          routes: [
            GoRoute(
              name: Routes.timeline,
              path: Routes.timelinePath,
              builder: (context, state) => TimelineShellPage(
                repo: repo,
                shellState: shellState,
              ),
            ),
          ],
        ),
        GoRoute(
          name: Routes.search,
          path: Routes.searchPath,
          builder: (context, state) => const Text('Search Route Content'),
        ),
        GoRoute(
          name: Routes.onthisday,
          path: Routes.onthisdayPath,
          builder: (context, state) => const Text('On This Day Route Content'),
        ),
      ],
    );
  });

  testWidgets('shell journal selection reloads timeline without duplicate app bar', (
    tester,
  ) async {
    await tester.pumpWidget(localizedRouterTestApp(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('工作日志首篇'), findsOneWidget);
    expect(find.text(testL10n.timeline), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('timeline-page-title')),
      findsNothing,
    );

    await tester.tap(find.bySemanticsLabel(testL10n.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('旅行手记'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.timelineJournalIds, ['journal-a', 'journal-b']);
    expect(find.text('旅行手记首篇'), findsOneWidget);
    expect(find.text('工作日志首篇'), findsNothing);
  });

  testWidgets('timeline shell actions navigate to search and on-this-day routes', (
    tester,
  ) async {
    await tester.pumpWidget(localizedRouterTestApp(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(testL10n.search));
    await tester.pumpAndSettle();
    expect(find.text('Search Route Content'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(testL10n.onThisDay));
    await tester.pumpAndSettle();
    expect(find.text('On This Day Route Content'), findsOneWidget);
  });
}
