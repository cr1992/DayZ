// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dayz/ui/onthisday/onthisday_screen.dart';
import 'package:dayz/ui/shell/app_router.dart';

import '../../l10n/localized_test_app.dart';
import 'onthisday_test_data.dart';

void main() {
  Object? memoryExtra;
  late GoRouter router;

  setUp(() {
    memoryExtra = null;
    router = GoRouter(
      initialLocation: Routes.onthisdayPath,
      routes: [
        GoRoute(
          name: Routes.onthisday,
          path: Routes.onthisdayPath,
          builder: (context, state) => OnThisDayScreen(data: otdSampleData()),
        ),
        GoRoute(
          name: Routes.memory,
          path: Routes.memoryPath,
          builder: (context, state) {
            memoryExtra = state.extra;
            return const Scaffold(body: Text('memory-page'));
          },
        ),
      ],
    );
  });

  tearDown(() => router.dispose());

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pumpWidget(localizedRouterTestApp(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OnThisDayScreen.moreButtonKey));
    await tester.pumpAndSettle();
  }

  testWidgets('more button opens a sheet with the two actions', (
    tester,
  ) async {
    await openMenu(tester);

    expect(find.text(testL10n.onThisDayMenuMemoryCard), findsOneWidget);
    expect(find.text(testL10n.onThisDayMenuMemoryCardDesc), findsOneWidget);
    expect(find.text(testL10n.onThisDayMenuShare), findsOneWidget);
  });

  testWidgets('memory card item pushes Routes.memory with month/day', (
    tester,
  ) async {
    await openMenu(tester);

    await tester.tap(find.text(testL10n.onThisDayMenuMemoryCard));
    await tester.pumpAndSettle();

    expect(find.text('memory-page'), findsOneWidget);
    expect(memoryExtra, {'month': 5, 'day': 29});
    expect(find.text(testL10n.onThisDayMenuShare), findsNothing);

    // push 而非 go：返回仍是往年今日。
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OnThisDayScreen), findsOneWidget);
  });

  testWidgets('share item closes the sheet and shows a toast', (tester) async {
    await openMenu(tester);

    await tester.tap(find.text(testL10n.onThisDayMenuShare));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(testL10n.onThisDayShareDone), findsOneWidget);
    expect(find.text(testL10n.onThisDayMenuMemoryCard), findsNothing);
  });

  testWidgets('without a router the memory callback receives the day', (
    tester,
  ) async {
    DateTime? opened;
    await tester.pumpWidget(
      localizedMaterialApp(
        home: OnThisDayScreen(
          data: otdSampleData(),
          onOpenMemory: (date) => opened = date,
        ),
      ),
    );
    await tester.tap(find.byKey(OnThisDayScreen.moreButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testL10n.onThisDayMenuMemoryCard));
    await tester.pumpAndSettle();

    expect(opened, otdToday);
  });
}
