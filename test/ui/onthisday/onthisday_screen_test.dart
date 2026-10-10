// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/onthisday/onthisday_screen.dart';
import 'package:dayz/ui/onthisday/onthisday_view_model.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_fonts.dart' as fonts;
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart' hide DayzFonts;
import 'package:dayz/ui/widgets/dayz_icon.dart';

import '../../l10n/localized_test_app.dart';
import 'onthisday_test_data.dart';

Future<void> _pump(
  WidgetTester tester,
  OnThisDayData data, {
  ValueChanged<String>? onOpenEntry,
}) async {
  await tester.pumpWidget(
    localizedMaterialApp(
      home: OnThisDayScreen(data: data, onOpenEntry: onOpenEntry),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders separators and cards in flatten order', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final data = otdSampleData();
    await _pump(tester, data);

    expect(find.byType(DayzYearSeparator), findsNWidgets(3));
    expect(find.byType(DayzEntryCard), findsNWidgets(5));

    final rows = flatten(data);
    final keys = [
      for (final row in rows)
        switch (row) {
          YearSeparatorRow(:final year) => OnThisDayScreen.yearSeparatorKey(
            year,
          ),
          EntryCardRow(:final entry) => OnThisDayScreen.entryCardKey(
            entry.entryId,
          ),
        },
    ];
    final tops = [for (final key in keys) tester.getRect(find.byKey(key)).top];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: 'row $i out of order');
    }

    // 屏头在列表之前；无溢出。
    expect(
      tester.getRect(find.byKey(OnThisDayScreen.headerKey)).bottom,
      lessThanOrEqualTo(tops.first),
    );
    for (final key in keys) {
      expect(tester.getRect(find.byKey(key)).right, lessThanOrEqualTo(390));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('header shows intl date kicker and headline count', (
    tester,
  ) async {
    final data = otdSampleData();
    await _pump(tester, data);

    expect(find.text(testL10n.onThisDayHeadline(5)), findsOneWidget);
    expect(find.text(testL10n.onThisDaySubtitle), findsOneWidget);
    expect(
      find.text(DateFormat.MMMd('zh').format(otdToday).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(testL10n.onThisDay), findsOneWidget);
  });

  testWidgets('header styles come from tokens', (tester) async {
    await _pump(tester, otdSampleData());

    final colors = DayzThemes.purpleLight.extension<DayzColors>()!;
    final kicker = tester.widget<Text>(find.byKey(OnThisDayScreen.kickerKey));
    expect(kicker.style!.color, colors.accentInk);
    final headline = tester.widget<Text>(
      find.byKey(OnThisDayScreen.headlineKey),
    );
    expect(headline.style!.fontFamily, fonts.DayzFonts.serif);
    expect(headline.style!.fontSize, 25);
    final subtitle = tester.widget<Text>(
      find.byKey(OnThisDayScreen.subtitleKey),
    );
    expect(subtitle.style!.color, colors.ink2);

    final header = tester.widget<Padding>(
      find.byKey(OnThisDayScreen.headerKey),
    );
    expect(
      header.padding,
      const EdgeInsets.fromLTRB(
        DayzSpacing.s5,
        DayzSpacing.s2,
        DayzSpacing.s5,
        DayzSpacing.s4,
      ),
    );
  });

  testWidgets('year separators scroll away instead of pinning', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, otdSampleData());

    final sep = find.byKey(OnThisDayScreen.yearSeparatorKey(2024));
    expect(
      find.ancestor(of: sep, matching: find.byType(SliverPersistentHeader)),
      findsNothing,
    );
    final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
    final before = tester.getRect(sep).top;

    tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .jumpTo(180);
    await tester.pump();

    final after = tester.getRect(sep).top;
    expect(before - after, closeTo(180, 1));
    // 吸顶头会停在顶栏下沿；普通行则越过顶栏下沿继续上移。
    expect(after, lessThan(appBarBottom));
  });

  testWidgets('favorite star only on favorited cards', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, otdSampleData());

    expect(
      find.descendant(
        of: find.byKey(OnThisDayScreen.entryCardKey('b-2021')),
        matching: find.byType(DayzFavoriteStar),
      ),
      findsOneWidget,
    );
    for (final id in ['a-2024', 'c-2019', 'd-2019', 'e-2019']) {
      expect(
        find.descendant(
          of: find.byKey(OnThisDayScreen.entryCardKey(id)),
          matching: find.byType(DayzFavoriteStar),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('tapping a card opens that entry', (tester) async {
    String? opened;
    await _pump(tester, otdSampleData(), onOpenEntry: (id) => opened = id);

    await tester.tap(find.text('Title a-2024'));
    await tester.pump();

    expect(opened, 'a-2024');
  });

  testWidgets('back button draws the ui-kit chevron-left icon', (
    tester,
  ) async {
    await _pump(tester, otdSampleData());

    final icon = tester.widget<DayzIcon>(
      find.descendant(
        of: find.byKey(OnThisDayScreen.backButtonKey),
        matching: find.byType(DayzIcon),
      ),
    );
    expect(icon.markup, '<path d="${DayzIcons.chevronLeftPath}"/>');
  });
}
