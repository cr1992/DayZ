// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayz/app.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/router_ports.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/l10n/locale_controller.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/shell/placeholder_screen.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';

import '../l10n/localized_test_app.dart';
import 'app_test_db.dart';

void main() {
  late AppServices services;
  late LocaleController localeController;

  setUpAll(initTimezoneData);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localeController = LocaleController();
    await localeController.setLocale(const Locale('zh'));
    services = inMemoryServices();
    bindRouterPorts(services);
    shellState.setJournals(const []);
    shellState.selectJournal(null);
    appRouter.go(Routes.timelinePath);
  });

  tearDown(() async {
    unbindRouterPorts();
    localeController.dispose();
    await services.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      DayZApp(localeController: localeController, services: services),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('cold start renders real timeline entries, not a placeholder', (
    tester,
  ) async {
    final entry = await tester.runAsync(
      () => addEntry(services, utc: DateTime.utc(2026, 9, 12), text: 'hello'),
    );

    await pumpApp(tester);

    expect(find.byType(TimelinePage), findsOneWidget);
    expect(find.byType(PlaceholderScreen), findsNothing);
    expect(find.text(testL10n.shellPlaceholderSuffix), findsNothing);
    expect(find.byKey(timelineMonthHeaderTestKey(2026, 9)), findsOneWidget);
    expect(find.byKey(timelineEntryCardTestKey(entry!.id)), findsOneWidget);
  });

  testWidgets('empty database shows the timeline empty state', (tester) async {
    await pumpApp(tester);

    expect(find.byType(DayzEmptyState), findsOneWidget);
    expect(find.text(testL10n.timelineEmptyTitle), findsOneWidget);
  });

  testWidgets('shell owns the only app bar above the real timeline', (
    tester,
  ) async {
    await pumpApp(tester);
    // 顶栏归外壳：时间线页在外壳内不再自带第二条顶栏。
    expect(find.byType(DayzGlassAppBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TimelinePage),
        matching: find.byType(DayzGlassAppBar),
      ),
      findsNothing,
    );
    expect(find.byType(NestedScrollView), findsOneWidget);
  });

  testWidgets('drawer journals come from the database with entry counts', (
    tester,
  ) async {
    final work = await tester.runAsync(() => services.journals.create('工作'));
    await tester.runAsync(() async {
      await addEntry(
        services,
        journalId: work!.id,
        utc: DateTime.utc(2026, 9, 1),
        text: 'a',
      );
      await addEntry(
        services,
        journalId: work.id,
        utc: DateTime.utc(2026, 9, 2),
        text: 'b',
      );
    });

    await pumpApp(tester);

    expect(shellState.journals.map((j) => (j.name, j.count)), [('工作', 2)]);
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('工作'), findsOneWidget);
  });

  testWidgets('creating a journal persists it and refreshes the drawer', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.runAsync(
      () => services.createJournal(shellState, name: '旅行', color: '#5C8A68'),
    );
    await tester.pump();

    final rows = await tester.runAsync(() => services.journals.list());
    expect(rows!.map((r) => (r.name, r.color)), [('旅行', '#5C8A68')]);
    expect(shellState.journals.map((j) => j.id), [rows.single.id]);
  });

  testWidgets('switching journal in shell state re-scopes the timeline', (
    tester,
  ) async {
    late String workEntryId;
    late String lifeEntryId;
    late String lifeId;
    await tester.runAsync(() async {
      final work = await services.journals.create('Work');
      final life = await services.journals.create('Life');
      lifeId = life.id;
      workEntryId = (await addEntry(
        services,
        journalId: work.id,
        utc: DateTime.utc(2026, 8, 3),
        text: 'w',
      )).id;
      lifeEntryId = (await addEntry(
        services,
        journalId: life.id,
        utc: DateTime.utc(2026, 8, 4),
        text: 'l',
      )).id;
    });

    await pumpApp(tester);
    expect(find.byKey(timelineEntryCardTestKey(workEntryId)), findsOneWidget);

    shellState.selectJournal(lifeId);
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.byKey(timelineEntryCardTestKey(lifeEntryId)), findsOneWidget);
    expect(find.byKey(timelineEntryCardTestKey(workEntryId)), findsNothing);
  });
}
