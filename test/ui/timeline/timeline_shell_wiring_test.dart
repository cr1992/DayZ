// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayz/app.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/l10n/locale_controller.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

import '../../app/app_test_db.dart';

void main() {
  late AppServices services;
  late LocaleController locale;

  setUpAll(initTimezoneData);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    locale = LocaleController();
    await locale.setLocale(const Locale('zh'));
    services = inMemoryServices();
    shellState.setJournals(const []);
    shellState.selectJournal(null);
    appRouter.go(Routes.timelinePath);
  });

  tearDown(() async {
    locale.dispose();
    await services.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      DayZApp(localeController: locale, services: services),
    );
    await settle(tester);
  }

  // push 的页面在匹配栈顶，取最后一个匹配的路径。
  String currentPath() =>
      appRouter.routerDelegate.currentConfiguration.last.matchedLocation;

  testWidgets('menu button opens the shell drawer', (tester) async {
    await pumpApp(tester);
    expect(find.byType(ShellDrawer), findsNothing);

    await tester.tap(find.byKey(TimelinePage.menuButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(ShellDrawer), findsOneWidget);
  });

  testWidgets('search and on-this-day buttons navigate to their routes', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(TimelinePage.searchButtonKey));
    await tester.pumpAndSettle();
    expect(currentPath(), Routes.searchPath);

    appRouter.go(Routes.timelinePath);
    await settle(tester);

    await tester.tap(find.byKey(TimelinePage.onThisDayButtonKey));
    await tester.pumpAndSettle();
    expect(currentPath(), Routes.onthisdayPath);
  });

  testWidgets('selecting a journal in the drawer re-scopes the timeline', (
    tester,
  ) async {
    late String workEntry;
    late String lifeEntry;
    await tester.runAsync(() async {
      final work = await services.journals.create('工作');
      final life = await services.journals.create('生活', sortOrder: 1);
      workEntry = (await addEntry(
        services,
        journalId: work.id,
        utc: DateTime.utc(2026, 9, 2),
        text: 'w',
      )).id;
      lifeEntry = (await addEntry(
        services,
        journalId: life.id,
        utc: DateTime.utc(2026, 9, 5),
        text: 'l',
      )).id;
    });
    await pumpApp(tester);
    expect(find.byKey(timelineEntryCardTestKey(workEntry)), findsOneWidget);
    expect(find.byKey(timelineEntryCardTestKey(lifeEntry)), findsOneWidget);

    await tester.tap(find.byKey(TimelinePage.menuButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(ShellDrawer), matching: find.text('生活')),
    );
    await settle(tester);
    if (find.byType(ShellDrawer).evaluate().isNotEmpty) {
      Navigator.of(tester.element(find.byType(ShellDrawer))).pop();
      await settle(tester);
    }

    expect(find.byKey(timelineEntryCardTestKey(lifeEntry)), findsOneWidget);
    expect(find.byKey(timelineEntryCardTestKey(workEntry)), findsNothing);
  });
}
