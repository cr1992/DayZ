// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dayz/ui/search/search_page.dart';
import 'package:dayz/ui/search/search_state.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';
import 'package:dayz/ui/widgets/dayz_search_field.dart';
import 'package:dayz/ui/widgets/dayz_tag.dart';

import '../../l10n/localized_test_app.dart';
import 'fake_search_source.dart';

const _title1 = '外婆教我腌的梅子';
const _excerpt1 = '玻璃罐要先用开水烫过，梅子和冰糖一层一层码好。';
const _title2 = '开了去年的那罐';
const _excerpt2 = '放了一整年，梅子的颜色变得很深。';

FakeSearchSource sampleSource() {
  return FakeSearchSource(
    hits: {
      '梅子': [
        fakeHit(
          'e1',
          title: _title1,
          excerpt: _excerpt1,
          date: DateTime(2026, 5, 27),
          place: '杭州',
        ),
        fakeHit(
          'e2',
          title: _title2,
          excerpt: _excerpt2,
          date: DateTime(2025, 6, 12),
        ),
      ],
      '生活': [fakeHit('e3', title: '生活碎片')],
    },
    failing: {'坏'},
    recentSearches: const [
      RecentSearch(term: '梅子', count: 2),
      RecentSearch(term: '没事别熬夜'),
    ],
    tagSuggestions: const [
      TagSuggestion(id: 't1', name: '生活'),
      TagSuggestion(id: 't2', name: '家'),
    ],
  );
}

Widget host(SearchPage page) => localizedMaterialApp(home: page);

/// 找根 TextSpan 下文本 == [text] 的子 span。
TextSpan spanWithText(WidgetTester tester, Key key, String text) {
  final root = tester.widget<Text>(find.byKey(key)).textSpan! as TextSpan;
  return root.children!.cast<TextSpan>().firstWhere(
    (span) => span.text == text,
  );
}

DayzColors colorsOf(WidgetTester tester) =>
    tester.element(find.byType(SearchPage)).dayz;

void main() {
  testWidgets('idle shows recent searches and tag suggestions (R5)', (
    tester,
  ) async {
    await tester.pumpWidget(host(SearchPage(source: sampleSource())));
    await tester.pumpAndSettle();

    expect(find.byKey(SearchPage.suggestionsKey), findsOneWidget);
    expect(find.text(testL10n.searchRecent.toUpperCase()), findsOneWidget);
    expect(find.text(testL10n.searchTags.toUpperCase()), findsOneWidget);
    expect(find.byKey(SearchPage.suggestRowKey('梅子')), findsOneWidget);
    expect(find.text(testL10n.searchRecentCount(2)), findsOneWidget);
    expect(find.byKey(SearchPage.suggestRowKey('没事别熬夜')), findsOneWidget);
    expect(find.text(testL10n.searchTagChip('生活')), findsOneWidget);
    expect(find.text(testL10n.searchTagChip('家')), findsOneWidget);
    expect(find.text(testL10n.searchHint), findsOneWidget);
  });

  testWidgets('typing → querying → results state machine (R1)', (tester) async {
    final source = sampleSource()..delay = const Duration(milliseconds: 200);
    await tester.pumpWidget(host(SearchPage(source: source)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(DayzSearchField.inputKey), '梅子');
    await tester.pump();
    // typing：建议仍在，尚未发查询。
    expect(find.byKey(SearchPage.suggestionsKey), findsOneWidget);
    expect(source.calls, isEmpty);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text(testL10n.searchQuerying), findsOneWidget);
    expect(source.calls.single.query, '梅子');

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.resultsListKey), findsOneWidget);
    expect(find.text(testL10n.searchQuerying), findsNothing);
  });

  testWidgets('results: stat count == card count, highlight + stat styles '
      '(R3/R4/NF4)', (tester) async {
    await tester.pumpWidget(
      host(SearchPage(source: sampleSource(), initialQuery: '梅子')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SearchPage.hitCardKey('e1')), findsOneWidget);
    expect(find.byKey(SearchPage.hitCardKey('e2')), findsOneWidget);
    final stat = tester.widget<Text>(find.byKey(SearchPage.resultStatKey));
    expect(stat.textSpan!.toPlainText(), testL10n.searchResultStat(2));

    final colors = colorsOf(tester);
    // `.search-stat` ink-3，`<b>` 段 ink-2 / 600。
    final statRoot = stat.textSpan! as TextSpan;
    expect(statRoot.style!.color, colors.ink3);
    final number = statRoot.children!.cast<TextSpan>().firstWhere(
      (span) => span.text == '2',
    );
    expect(number.style!.color, colors.ink2);
    expect(number.style!.fontWeight, FontWeight.w600);

    // 标题尾部命中 `.hl`。
    final titleHit = spanWithText(tester, SearchPage.hitTitleKey('e1'), '梅子');
    expect(titleHit.style!.backgroundColor, colors.accentSoft2);
    expect(titleHit.style!.color, colors.accentInk);
    final titleRest = spanWithText(
      tester,
      SearchPage.hitTitleKey('e1'),
      '外婆教我腌的',
    );
    expect(titleRest.style!.backgroundColor, isNull);
    expect(titleRest.style!.color, colors.ink);
    // 标题拼回原文（同一段 Text.rich）。
    expect(
      tester
          .widget<Text>(find.byKey(SearchPage.hitTitleKey('e1')))
          .textSpan!
          .toPlainText(),
      _title1,
    );

    // 摘要命中同样高亮；无命中的标题整段常规样式。
    final excerptHit = spanWithText(
      tester,
      SearchPage.hitExcerptKey('e2'),
      '梅子',
    );
    expect(excerptHit.style!.backgroundColor, colors.accentSoft2);
    expect(excerptHit.style!.color, colors.accentInk);
    final plainTitle =
        tester.widget<Text>(find.byKey(SearchPage.hitTitleKey('e2'))).textSpan!
            as TextSpan;
    expect(plainTitle.children, hasLength(1));
    expect(
      (plainTitle.children!.single as TextSpan).style!.backgroundColor,
      isNull,
    );
    // 地点 meta。
    expect(find.text('杭州'), findsOneWidget);
  });

  testWidgets('cancel text color is accent-ink (.search-cancel)', (
    tester,
  ) async {
    await tester.pumpWidget(host(SearchPage(source: sampleSource())));
    await tester.pumpAndSettle();
    final button = tester.widget<TextButton>(
      find.byKey(DayzSearchField.cancelButtonKey),
    );
    final color = button.style!.foregroundColor!.resolve(<WidgetState>{});
    expect(color, colorsOf(tester).accentInk);
    expect(find.text(testL10n.cancel), findsOneWidget);
  });

  testWidgets('zero hits → empty state with the query in its title (R4)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SearchPage(source: sampleSource(), initialQuery: '梅子酱')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SearchPage.emptyStateKey), findsOneWidget);
    expect(find.byType(DayzEmptyState), findsOneWidget);
    expect(find.text(testL10n.searchEmptyTitle('梅子酱')), findsOneWidget);
    expect(find.text(testL10n.searchEmptyDescription), findsOneWidget);
  });

  testWidgets('error shows retry; retry re-queries the same word (R8)', (
    tester,
  ) async {
    final source = sampleSource();
    await tester.pumpWidget(
      host(SearchPage(source: source, initialQuery: '坏')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SearchPage.errorStateKey), findsOneWidget);
    expect(find.text(testL10n.searchErrorTitle), findsOneWidget);
    expect(find.text(testL10n.searchRetry), findsOneWidget);

    source.failing.clear();
    source.hits['坏'] = [fakeHit('ok', title: '坏天气')];
    await tester.tap(find.byKey(SearchPage.retryButtonKey));
    await tester.pumpAndSettle();

    expect(source.calls.map((call) => call.query), ['坏', '坏']);
    expect(find.byKey(SearchPage.hitCardKey('ok')), findsOneWidget);
  });

  testWidgets('tapping a recent row / tag chip fills the input and queries '
      '(R5)', (tester) async {
    final source = sampleSource();
    await tester.pumpWidget(host(SearchPage(source: source)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SearchPage.suggestRowKey('梅子')));
    await tester.pumpAndSettle();
    expect(source.calls.last.query, '梅子');
    expect(find.byKey(SearchPage.resultsListKey), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(DayzSearchField.inputKey),
    );
    expect(field.controller!.text, '梅子');

    // 清空回 idle，再点标签。
    await tester.tap(find.byKey(DayzSearchField.clearButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.suggestionsKey), findsOneWidget);
    await tester.tap(find.byKey(SearchPage.tagChipKey('t1')));
    await tester.pumpAndSettle();
    expect(source.calls.last.query, '生活');
    expect(field.controller!.text, '生活');
    expect(find.byKey(SearchPage.hitCardKey('e3')), findsOneWidget);
  });

  testWidgets('removing a filter chip re-queries with narrowed filters (D8)', (
    tester,
  ) async {
    final source = sampleSource();
    const filters = SearchFilters(
      journal: SearchJournalFilter(id: 'j1', name: '家'),
      year: 2026,
    );
    await tester.pumpWidget(
      host(
        SearchPage(source: source, initialQuery: '梅子', initialFilters: filters),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SearchPage.filtersKey), findsOneWidget);
    expect(find.text(testL10n.searchFilters.toUpperCase()), findsOneWidget);
    final yearLabel = DateFormat.y('zh').format(DateTime(2026));
    expect(find.text(yearLabel), findsOneWidget);
    expect(source.calls.single.filters, filters);

    final journalChip = find.byKey(
      SearchPage.filterChipKey(SearchFilterKind.journal),
    );
    await tester.tap(
      find.descendant(of: journalChip, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();

    expect(source.calls.last.query, '梅子');
    expect(source.calls.last.filters, const SearchFilters(year: 2026));
    expect(journalChip, findsNothing);
    expect(
      find.byKey(SearchPage.filterChipKey(SearchFilterKind.year)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<DayzTag>(
            find.byKey(SearchPage.filterChipKey(SearchFilterKind.year)),
          )
          .removeSemanticLabel,
      testL10n.searchRemoveFilter(yearLabel),
    );
  });

  testWidgets('changes event silently re-queries current results (R10)', (
    tester,
  ) async {
    final source = sampleSource();
    await tester.pumpWidget(
      host(SearchPage(source: source, initialQuery: '梅子')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.hitCardKey('e2')), findsOneWidget);

    source.hits['梅子'] = [source.hits['梅子']!.first];
    source.emitChange();
    await tester.pumpAndSettle();

    expect(source.calls, hasLength(2));
    expect(find.byKey(SearchPage.hitCardKey('e2')), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(SearchPage.resultStatKey))
          .textSpan!
          .toPlainText(),
      testL10n.searchResultStat(1),
    );
  });

  group('navigation', () {
    late GoRouter router;
    late FakeSearchSource source;
    Object? readerExtra;

    setUp(() {
      readerExtra = null;
      source = sampleSource();
      router = GoRouter(
        initialLocation: '/origin',
        routes: [
          GoRoute(
            path: '/origin',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.pushNamed(Routes.search),
                child: const Text('origin-page'),
              ),
            ),
          ),
          GoRoute(
            name: Routes.search,
            path: Routes.searchPath,
            builder: (context, state) => SearchPage(
              source: source,
              initialQuery: state.extra as String?,
            ),
          ),
          GoRoute(
            name: Routes.reader,
            path: Routes.readerPath,
            builder: (context, state) {
              readerExtra = state.extra;
              return const Scaffold(body: Text('reader-page'));
            },
          ),
        ],
      );
    });

    tearDown(() => router.dispose());

    Future<void> openSearch(WidgetTester tester) async {
      await tester.pumpWidget(localizedRouterTestApp(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('origin-page'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsOneWidget);
    }

    testWidgets('tapping a result card pushes Routes.reader with id (R7)', (
      tester,
    ) async {
      await openSearch(tester);
      await tester.enterText(find.byKey(DayzSearchField.inputKey), '梅子');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(SearchPage.hitTitleKey('e1')));
      await tester.pumpAndSettle();
      expect(find.text('reader-page'), findsOneWidget);
      expect(readerExtra, 'e1');
    });

    testWidgets('cancel pops back to the origin page (R6)', (tester) async {
      await openSearch(tester);
      await tester.enterText(find.byKey(DayzSearchField.inputKey), '梅');
      await tester.pump();

      await tester.tap(find.byKey(DayzSearchField.cancelButtonKey));
      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsNothing);
      expect(find.text('origin-page'), findsOneWidget);
    });
  });
}
