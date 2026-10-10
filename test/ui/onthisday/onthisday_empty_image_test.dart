// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/onthisday/onthisday_screen.dart';
import 'package:dayz/ui/onthisday/onthisday_view_model.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';

import '../../l10n/localized_test_app.dart';
import 'onthisday_test_data.dart';

Future<void> _pump(WidgetTester tester, OnThisDayData data) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    localizedMaterialApp(home: OnThisDayScreen(data: data)),
  );
  await tester.pump();
}

void main() {
  testWidgets('empty data shows the empty state only', (tester) async {
    await _pump(tester, otdEmptyData());

    expect(find.byType(DayzEmptyState), findsOneWidget);
    expect(find.text(testL10n.onThisDayEmptyTitle), findsOneWidget);
    expect(find.text(testL10n.onThisDayEmptyDescription), findsOneWidget);
    expect(find.byType(DayzEntryCard), findsNothing);
    expect(find.byType(DayzYearSeparator), findsNothing);
    expect(find.byKey(OnThisDayScreen.headerKey), findsNothing);
    expect(find.text(testL10n.onThisDayHeadline(0)), findsNothing);
    // 顶栏仍在（可返回 / 可弹菜单）。
    expect(find.byKey(OnThisDayScreen.backButtonKey), findsOneWidget);
    expect(find.byKey(OnThisDayScreen.moreButtonKey), findsOneWidget);

    final illustration = tester.widget<DayzIcon>(
      find.byKey(OnThisDayScreen.emptyIllustrationKey),
    );
    expect(illustration.markup, contains(DayzIcons.historyClockPath));
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups with no entries also count as empty', (tester) async {
    await _pump(
      tester,
      OnThisDayData(
        date: otdToday,
        totalCount: 0,
        groups: const [YearGroup(year: 2020, yearsAgo: 6, entries: [])],
      ),
    );

    expect(find.byType(DayzEmptyState), findsOneWidget);
    expect(find.byType(DayzYearSeparator), findsNothing);
  });

  testWidgets('only entries with a cover render the photo slot', (
    tester,
  ) async {
    await _pump(tester, otdSampleData());

    final coverCard = find.byKey(OnThisDayScreen.entryCardKey('b-2021'));
    final images = find.descendant(of: coverCard, matching: find.byType(Image));
    expect(images, findsOneWidget);
    expect(tester.widget<Image>(images).image, same(otdCoverImage));

    // 占位 = 卡片图位自带的 accentSoft2 底（图未解码前即可见）。
    final colors = DayzThemes.purpleLight.extension<DayzColors>()!;
    final placeholder = find.ancestor(
      of: images,
      matching: find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == colors.accentSoft2,
      ),
    );
    expect(placeholder, findsOneWidget);

    for (final id in ['a-2024', 'c-2019', 'd-2019', 'e-2019']) {
      expect(
        find.descendant(
          of: find.byKey(OnThisDayScreen.entryCardKey(id)),
          matching: find.byType(Image),
        ),
        findsNothing,
        reason: '$id has no cover',
      );
    }
  });
}
