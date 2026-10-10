// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/search/search_page.dart';

import '../../l10n/localized_test_app.dart';
import 'fake_search_source.dart';

void main() {
  testWidgets('results: stat above cards, cards in hit order, no overflow, '
      'no sticky header (D3)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ids = ['e1', 'e2', 'e3'];
    final source = FakeSearchSource(
      hits: {
        '梅子': [
          for (final id in ids)
            fakeHit(
              id,
              title: '梅子 $id 很长很长的标题会换行吗会的会的会的会的会的',
              excerpt: '摘要里也有梅子，' * 6,
              place: '杭州',
            ),
        ],
      },
    );
    await tester.pumpWidget(
      localizedMaterialApp(
        home: SearchPage(source: source, initialQuery: '梅子'),
      ),
    );
    await tester.pumpAndSettle();

    final stat = tester.getRect(find.byKey(SearchPage.resultStatKey));
    final first = tester.getRect(find.byKey(SearchPage.hitCardKey('e1')));
    expect(stat.bottom, lessThanOrEqualTo(first.top));

    // 卡片纵向顺序 == hits 顺序（可见部分），且不越出视口宽度。
    var previousTop = double.negativeInfinity;
    for (final id in ids) {
      final finder = find.byKey(SearchPage.hitCardKey(id));
      if (finder.evaluate().isEmpty) {
        continue; // 视口外未构建（朴素 ListView.builder 懒加载）
      }
      final rect = tester.getRect(finder);
      expect(rect.top, greaterThan(previousTop), reason: id);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
      previousTop = rect.top;
    }
    expect(tester.takeException(), isNull);

    // 朴素列表：不引入吸顶。
    expect(find.byType(SliverPersistentHeader), findsNothing);

    // 滚到底，最后一张卡仍按顺序出现在前一张之后。
    await tester.dragUntilVisible(
      find.byKey(SearchPage.hitCardKey('e3')),
      find.byKey(SearchPage.resultsListKey),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    final second = tester.getRect(find.byKey(SearchPage.hitCardKey('e2')));
    final third = tester.getRect(find.byKey(SearchPage.hitCardKey('e3')));
    expect(third.top, greaterThan(second.top));
    expect(third.right, lessThanOrEqualTo(390));
  });
}
