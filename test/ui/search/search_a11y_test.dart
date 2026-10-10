// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/search/search_page.dart';
import 'package:dayz/ui/search/search_state.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_search_field.dart';

import '../../l10n/localized_test_app.dart';
import '../theme/contrast_test.dart'
    show calculateContrastRatio, parseXFailYaml;
import 'fake_search_source.dart';

FakeSearchSource a11ySource() {
  return FakeSearchSource(
    hits: {
      '梅子': [
        fakeHit('e1', title: '外婆教我腌的梅子', excerpt: '梅子和冰糖'),
        fakeHit('e2', title: '开了去年的那罐', excerpt: '梅子的颜色变得很深'),
      ],
    },
    failing: {'坏'},
    recentSearches: const [RecentSearch(term: '梅雨', count: 5)],
    tagSuggestions: const [TagSuggestion(id: 't1', name: '生活')],
  );
}

Widget reducedMotion(Widget home, {required bool disable}) {
  return localizedMaterialApp(
    home: home,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: disable),
      child: child!,
    ),
  );
}

void expectHitBox(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(44), reason: '$finder width');
  expect(size.height, greaterThanOrEqualTo(44), reason: '$finder height');
}

void main() {
  group('Semantics labels (NF1)', () {
    testWidgets('cancel / input / result card', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        localizedMaterialApp(
          home: SearchPage(source: a11ySource(), initialQuery: '梅子'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(testL10n.cancel), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^${testL10n.searchInputLabel}')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(testL10n.searchOpenEntry('外婆教我腌的梅子')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(testL10n.searchOpenEntry('开了去年的那罐')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('empty state and retry button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        localizedMaterialApp(
          home: SearchPage(source: a11ySource(), initialQuery: '梅子酱'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(testL10n.searchEmptyTitle('梅子酱')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        localizedMaterialApp(
          home: SearchPage(
            key: const ValueKey('error'),
            source: a11ySource(),
            initialQuery: '坏',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(testL10n.searchErrorTitle), findsOneWidget);
      expect(find.bySemanticsLabel(testL10n.searchRetry), findsOneWidget);
      handle.dispose();
    });
  });

  group('hit targets >= 44x44 (NF1)', () {
    testWidgets('cancel / suggest row / tag chip', (tester) async {
      await tester.pumpWidget(
        localizedMaterialApp(home: SearchPage(source: a11ySource())),
      );
      await tester.pumpAndSettle();

      expectHitBox(tester, find.byKey(DayzSearchField.cancelButtonKey));
      expectHitBox(tester, find.byKey(SearchPage.suggestRowKey('梅雨')));
      expectHitBox(tester, find.byKey(SearchPage.tagChipKey('t1')));
    });

    testWidgets('filter remove x / result card', (tester) async {
      await tester.pumpWidget(
        localizedMaterialApp(
          home: SearchPage(
            source: a11ySource(),
            initialQuery: '梅子',
            initialFilters: const SearchFilters(year: 2026),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final remove = find.descendant(
        of: find.byKey(SearchPage.filterChipKey(SearchFilterKind.year)),
        matching: find.byType(IconButton),
      );
      expectHitBox(tester, remove);
      expectHitBox(tester, find.byKey(SearchPage.hitCardKey('e1')));
      expectHitBox(tester, find.byKey(SearchPage.hitCardKey('e2')));
    });
  });

  group('reduce-motion (NF1)', () {
    testWidgets('state transitions are instant when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        reducedMotion(SearchPage(source: a11ySource()), disable: true),
      );
      await tester.pump();
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byKey(SearchPage.switcherKey),
      );
      expect(switcher.duration, Duration.zero);
    });

    testWidgets('default motion uses the DayzMotion token', (tester) async {
      await tester.pumpWidget(
        reducedMotion(SearchPage(source: a11ySource()), disable: false),
      );
      await tester.pump();
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byKey(SearchPage.switcherKey),
      );
      expect(switcher.duration, DayzMotion.dur);
    });
  });

  // 2026-10-10 实测 amberLight 该对组 4.41（< 4.5）且未登记在 tokens-theme 的
  // contrast_xfail.yaml（本 spec 不可改该真源）→ 已升级 @Ray 决定「登记 xfail /
  // 调 token」。这里显式钉住待决集合：新增失败主题、或 amberLight 转为达标，
  // 测试都会红，提示同步清理——不是静默放行。
  const pendingEscalation = {'amberLight'};

  test('highlight accentInk on accentSoft2 meets AA in six themes, '
      'unless registered in contrast_xfail.yaml (NF1)', () {
    final xfails = parseXFailYaml(
      File('test/ui/theme/contrast_xfail.yaml').readAsStringSync(),
    );
    final themes = {
      'purpleLight': DayzColors.purpleLight,
      'purpleDark': DayzColors.purpleDark,
      'amberLight': DayzColors.amberLight,
      'amberDark': DayzColors.amberDark,
      'sageLight': DayzColors.sageLight,
      'sageDark': DayzColors.sageDark,
    };
    final violations = <String>{};
    for (final MapEntry(key: name, value: colors) in themes.entries) {
      final ratio = calculateContrastRatio(
        colors.accentInk,
        colors.accentSoft2,
      );
      final registered = xfails.any(
        (c) =>
            c.theme == name &&
            c.foreground == 'accentInk' &&
            c.background == 'accentSoft2',
      );
      if (ratio < 4.5 && !registered) {
        violations.add(name);
      }
    }
    // 一旦 yaml 登记了该对组，待决集合应随之清空。
    final stillPending = pendingEscalation.where(
      (name) => !xfails.any(
        (c) =>
            c.theme == name &&
            c.foreground == 'accentInk' &&
            c.background == 'accentSoft2',
      ),
    );
    expect(violations, stillPending.toSet());
  });
}
