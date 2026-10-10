// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/search_demo.dart';
import 'package:dayz/ui/search/search_page.dart';
import 'package:dayz/ui/widgets/dayz_search_field.dart';

import '../l10n/localized_test_app.dart';

void main() {
  test('search demo is appended at the end of demos', () {
    final last = demos.last;
    expect(last.title, '搜索屏 demo');
    expect(last.builder(_FakeContext()), isA<SearchDemo>());
  });

  testWidgets('Debug Home opens the search demo', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));
    await tester.scrollUntilVisible(
      find.text('搜索屏 demo'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('搜索屏 demo'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchDemo), findsOneWidget);
    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('all six states are reachable in the demo (R9)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localizedMaterialApp(home: const SearchDemo()));
    await tester.pumpAndSettle();

    // idle
    expect(find.byKey(SearchPage.suggestionsKey), findsOneWidget);
    expect(find.text(testL10n.searchRecent.toUpperCase()), findsOneWidget);

    // typing（防抖窗口内）→ results（命中模式）
    await tester.enterText(find.byKey(DayzSearchField.inputKey), '梅子');
    await tester.pump();
    expect(find.byKey(SearchPage.suggestionsKey), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.resultsListKey), findsOneWidget);
    expect(find.byKey(SearchPage.hitCardKey('demo-plum-1')), findsOneWidget);
    expect(find.byKey(SearchPage.filtersKey), findsOneWidget);

    // querying（慢查询模式）
    await tester.tap(find.byKey(SearchDemo.modeKey(SearchDemoMode.slow)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SearchPage.suggestRowKey('梅子')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(testL10n.searchQuerying), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.resultsListKey), findsOneWidget);

    // empty
    await tester.tap(find.byKey(SearchDemo.modeKey(SearchDemoMode.empty)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SearchPage.suggestRowKey('梅雨')));
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.emptyStateKey), findsOneWidget);
    expect(find.text(testL10n.searchEmptyTitle('梅雨')), findsOneWidget);

    // error
    await tester.tap(find.byKey(SearchDemo.modeKey(SearchDemoMode.error)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SearchPage.tagChipKey('demo-life')));
    await tester.pumpAndSettle();
    expect(find.byKey(SearchPage.errorStateKey), findsOneWidget);
    expect(find.byKey(SearchPage.retryButtonKey), findsOneWidget);
  });
}

class _FakeContext extends Fake implements BuildContext {}
