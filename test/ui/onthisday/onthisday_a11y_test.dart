// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/onthisday/onthisday_screen.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart' show DayzMotion;

import '../../l10n/localized_test_app.dart';
import 'onthisday_test_data.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool disableAnimations = false,
  ValueChanged<String>? onOpenEntry,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    localizedMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: OnThisDayScreen(data: otdSampleData(), onOpenEntry: onOpenEntry),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('back, more and cards have at least 44x44 hit areas', (
    tester,
  ) async {
    await _pump(tester);

    for (final finder in [
      find.byKey(OnThisDayScreen.backButtonKey),
      find.byKey(OnThisDayScreen.moreButtonKey),
      find.byKey(OnThisDayScreen.entryCardKey('a-2024')),
      find.byKey(OnThisDayScreen.entryCardKey('b-2021')),
    ]) {
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('back, more, favorite star and cards expose semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    String? opened;
    await _pump(tester, onOpenEntry: (id) => opened = id);

    expect(find.bySemanticsLabel(testL10n.onThisDayBack), findsOneWidget);
    expect(find.bySemanticsLabel(testL10n.more), findsOneWidget);
    // 收藏星语义由 ui-kit 卡片提供：只读星读状态「已收藏」、不标按钮（ui-kit-patch R3）。
    final star = find.bySemanticsLabel(testL10n.favorited);
    expect(star, findsOneWidget);
    expect(tester.getSemantics(star).flagsCollection.isButton, isFalse);
    expect(find.bySemanticsLabel(testL10n.unfavorite), findsNothing);

    final card = find.bySemanticsLabel(
      testL10n.onThisDayOpenEntry('Title a-2024'),
    );
    expect(card, findsOneWidget);
    final node = tester.getSemantics(card);
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    tester.semantics.tap(
      find.semantics.byLabel(testL10n.onThisDayOpenEntry('Title a-2024')),
    );
    await tester.pump();
    expect(opened, 'a-2024');
    handle.dispose();
  });

  testWidgets('reduce-motion opens the menu sheet without animation', (
    tester,
  ) async {
    await _pump(tester, disableAnimations: true);
    expect(
      dayzMotionDuration(tester.element(find.byKey(OnThisDayScreen.headerKey))),
      Duration.zero,
    );

    await tester.tap(find.byKey(OnThisDayScreen.moreButtonKey));
    await tester.pump();
    await tester.pump();

    final frame = find.byKey(const ValueKey('dayz-sheet-frame'));
    expect(frame, findsOneWidget);
    final settled = tester.getRect(frame);
    await tester.pumpAndSettle();
    expect(tester.getRect(frame), settled, reason: 'no slide-in animation');
  });

  testWidgets('with animations the sheet still slides in (control)', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      dayzMotionDuration(tester.element(find.byKey(OnThisDayScreen.headerKey))),
      DayzMotion.dur,
    );

    await tester.tap(find.byKey(OnThisDayScreen.moreButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final frame = find.byKey(const ValueKey('dayz-sheet-frame'));
    final midway = tester.getRect(frame);
    await tester.pumpAndSettle();
    expect(tester.getRect(frame).top, lessThan(midway.top));
  });
}
