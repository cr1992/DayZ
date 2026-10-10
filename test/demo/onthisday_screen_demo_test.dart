// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/onthisday_screen_demo.dart';
import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/onthisday/onthisday_screen.dart';

import '../l10n/localized_test_app.dart';

void main() {
  test('onthisday demo is appended at the end of demos', () {
    final last = demos.last;
    expect(last.title, '往年今日屏 demo');
    expect(
      last.builder(_FakeContext()),
      isA<OnThisDayScreenDemo>(),
    );
  });

  testWidgets('Debug Home opens the onthisday demo', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));
    await tester.scrollUntilVisible(
      find.text('往年今日屏 demo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('往年今日屏 demo'));
    await tester.pumpAndSettle();

    expect(find.byType(OnThisDayScreenDemo), findsOneWidget);
    expect(find.byType(OnThisDayScreen), findsOneWidget);
  });

  testWidgets('demo switches between default and empty states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      localizedMaterialApp(home: const OnThisDayScreenDemo()),
    );
    await tester.pump();

    expect(find.byType(DayzYearSeparator), findsWidgets);
    expect(find.byType(DayzEntryCard), findsWidgets);
    expect(find.text(testL10n.onThisDayHeadline(4)), findsOneWidget);
    expect(find.byType(DayzEmptyState), findsNothing);

    await tester.tap(find.byKey(OnThisDayScreenDemo.emptySegmentKey));
    await tester.pumpAndSettle();

    expect(find.byType(DayzEmptyState), findsOneWidget);
    expect(find.text(testL10n.onThisDayEmptyTitle), findsOneWidget);
    expect(find.byType(DayzEntryCard), findsNothing);
    expect(find.byType(DayzYearSeparator), findsNothing);

    await tester.tap(find.byKey(OnThisDayScreenDemo.defaultSegmentKey));
    await tester.pumpAndSettle();
    expect(find.byType(DayzEntryCard), findsWidgets);
  });

  testWidgets('demo menu opens and memory entry stays inside the demo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      localizedMaterialApp(home: const OnThisDayScreenDemo()),
    );
    await tester.pump();

    await tester.tap(find.byKey(OnThisDayScreen.moreButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testL10n.onThisDayMenuMemoryCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OnThisDayScreen), findsOneWidget);
    expect(find.textContaining('5/29'), findsOneWidget);
  });
}

class _FakeContext extends Fake implements BuildContext {}
