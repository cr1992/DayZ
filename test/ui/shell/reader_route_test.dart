// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/theme_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import '../reader/fakes/fake_repos.dart';

void main() {
  late ThemeController themeController;
  late FakeReaderRepository repo;

  setUp(() {
    themeController = ThemeController();
    repo = FakeReaderRepository(
      entries: {
        'entry-1': ReaderEntryRecord(
          id: 'entry-1',
          journalId: null,
          contentPlain: '雨后的院子\n木桌上还留着水印。',
          contentJson: '{}',
          entryDtUtc: DateTime.utc(2026, 5, 31, 13, 18),
          entryTz: 'Asia/Shanghai',
          isFavorite: false,
        ),
      },
    );
    registerReaderRepository(repo);
    appRouter.go(Routes.timelinePath);
  });

  tearDown(() {
    registerReaderRepository(null);
    themeController.dispose();
  });

  Widget routerTestApp() => localizedRouterTestApp(
    routerConfig: appRouter,
    builder: (context, child) => ThemeControllerScope(
      controller: themeController,
      child: child ?? const SizedBox.shrink(),
    ),
  );

  testWidgets('registered reader route renders the real reader and pops back', (
    tester,
  ) async {
    await tester.pumpWidget(routerTestApp());
    await tester.pumpAndSettle();

    appRouter.pushNamed(Routes.reader, extra: 'entry-1');
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text(testL10n.shellPlaceholderSuffix), findsNothing);
    expect(find.text('木桌上还留着水印。'), findsOneWidget);
    expect(repo.byIdCalls, ['entry-1']);

    // Navigation above the reader rebuilds its route; that must not reload it.
    appRouter.pushNamed(Routes.settings);
    await tester.pumpAndSettle();
    appRouter.pop();
    await tester.pumpAndSettle();
    expect(repo.byIdCalls, ['entry-1']);

    await tester.tap(find.byTooltip(testL10n.close));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsNothing);
    expect(find.text(testL10n.timeline), findsAtLeastNWidgets(1));
  });

  testWidgets('reader route without an entry id stays a placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(routerTestApp());
    await tester.pumpAndSettle();

    appRouter.goNamed(Routes.reader);
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsNothing);
    expect(find.text(testL10n.shellPlaceholderSuffix), findsOneWidget);
  });
}
