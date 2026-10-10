// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/router_ports.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/onthisday/onthisday_controller.dart';
import 'package:dayz/ui/onthisday/onthisday_screen.dart';
import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/placeholder_screen.dart';

import '../../app/app_test_db.dart';
import '../../l10n/localized_test_app.dart';

void main() {
  setUpAll(initTimezoneData);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpRouterAt(WidgetTester tester, String location) async {
    appRouter.go(location);
    await tester.pumpWidget(localizedRouterTestApp(routerConfig: appRouter));
    await settle(tester);
  }

  testWidgets('before data arrives only the top bar skeleton renders', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedMaterialApp(home: const OnThisDayScreen(data: null)),
    );

    expect(find.byKey(OnThisDayScreen.backButtonKey), findsOneWidget);
    expect(find.byKey(OnThisDayScreen.headerKey), findsNothing);
    expect(find.byType(DayzEmptyState), findsNothing);
    final more = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(OnThisDayScreen.moreButtonKey),
        matching: find.byType(IconButton),
      ),
    );
    expect(more.onPressed, isNull);
  });

  group('ports not registered', () {
    setUp(unbindRouterPorts);

    testWidgets('onthisday route stays a placeholder', (tester) async {
      await pumpRouterAt(tester, Routes.onthisdayPath);

      expect(onThisDayRepositoryPort, isNull);
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.byType(OnThisDayScreen), findsNothing);
    });
  });

  group('ports bound to an in-memory library', () {
    late AppServices services;
    final now = DateTime.now();
    // 条目时区取 Etc/UTC，本地月/日即 UTC 月/日；与「今天」的月/日对齐。
    DateTime pastUtc(int yearsAgo, {int hour = 12}) =>
        DateTime.utc(now.year - yearsAgo, now.month, now.day, hour);

    setUp(() {
      services = inMemoryServices();
      bindRouterPorts(services);
    });

    tearDown(() async {
      unbindRouterPorts();
      await services.close();
    });

    testWidgets('onthisday route renders the real screen with past entries', (
      tester,
    ) async {
      final older = await tester.runAsync(
        () => addEntry(services, utc: pastUtc(4), text: '四年前\n那天的风'),
      );
      final newer = await tester.runAsync(
        () => addEntry(services, utc: pastUtc(1), text: '去年今天'),
      );
      await tester.runAsync(
        () => addEntry(
          services,
          utc: pastUtc(1).subtract(const Duration(days: 3)),
          text: '别的日子',
        ),
      );

      await pumpRouterAt(tester, Routes.onthisdayPath);

      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(find.byType(OnThisDayPage), findsOneWidget);
      expect(find.byType(OnThisDayScreen), findsOneWidget);
      expect(find.byKey(OnThisDayScreen.entryCardKey(newer!.id)), findsOneWidget);
      expect(find.byKey(OnThisDayScreen.entryCardKey(older!.id)), findsOneWidget);
      expect(find.text('别的日子'), findsNothing);
      expect(find.text(testL10n.onThisDayHeadline(2)), findsOneWidget);
      expect(find.byType(DayzYearSeparator), findsNWidgets(2));
    });

    testWidgets('empty library shows the onthisday empty state', (
      tester,
    ) async {
      await pumpRouterAt(tester, Routes.onthisdayPath);

      expect(find.byType(OnThisDayScreen), findsOneWidget);
      expect(find.text(testL10n.onThisDayEmptyTitle), findsOneWidget);
    });

    testWidgets('writes to the library refresh the open screen', (
      tester,
    ) async {
      await pumpRouterAt(tester, Routes.onthisdayPath);
      expect(find.text(testL10n.onThisDayEmptyTitle), findsOneWidget);

      final entry = await tester.runAsync(
        () => addEntry(services, utc: pastUtc(2), text: '后来补写的一篇'),
      );
      await settle(tester);

      expect(find.byKey(OnThisDayScreen.entryCardKey(entry!.id)), findsOneWidget);
      expect(find.text(testL10n.onThisDayEmptyTitle), findsNothing);
    });

    testWidgets('tapping a card opens the reader for that entry', (
      tester,
    ) async {
      final entry = await tester.runAsync(
        () => addEntry(services, utc: pastUtc(3), text: '点我进阅读'),
      );
      await pumpRouterAt(tester, Routes.onthisdayPath);

      await tester.tap(find.byKey(OnThisDayScreen.entryCardKey(entry!.id)));
      await settle(tester);

      final reader = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
      expect(reader.entryId, entry.id);
    });

    testWidgets('other routes are unaffected by the onthisday wiring', (
      tester,
    ) async {
      await pumpRouterAt(tester, Routes.calendarPath);
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.byType(OnThisDayScreen), findsNothing);

      appRouter.go(Routes.memoryPath);
      await settle(tester);
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.byType(OnThisDayScreen), findsNothing);
      expect(find.text(testL10n.memoryCardExport), findsWidgets);
    });
  });
}
