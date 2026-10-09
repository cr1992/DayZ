// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/widgets/dayz_entry_card.dart';
import 'package:dayz/ui/widgets/dayz_favorite_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

/// Layout assertions for `.entry .card` (spec.css): the favourite star keeps
/// its 44px hit target without inflating the title row.
///
/// Author: @Ray
void main() {
  const cardWidth = 390.0;
  const titleFirstLineHeight = 17 * 1.25;

  Future<void> pumpCard(WidgetTester tester, {required bool favorite}) async {
    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('en'),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: cardWidth,
            child: DayzEntryCard(
              title: 'Title',
              summary: 'Summary',
              date: DateTime(2026, 5, 28),
              favorite: favorite,
              showFavorite: favorite,
              onFavoritePressed: favorite ? () {} : null,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('star stays 44px and centres on the title first line', (
    tester,
  ) async {
    await pumpCard(tester, favorite: true);

    final title = tester.getRect(find.byKey(DayzEntryCard.titleKey));
    final star = tester.getRect(find.byType(DayzFavoriteStar));
    final card = tester.getRect(find.byType(DayzEntryCard));

    expect(star.size, const Size.square(44));
    expect(
      (star.center.dy - (title.top + titleFirstLineHeight / 2)).abs(),
      lessThan(1.5),
      reason: 'star centre should sit on the title first-line centre',
    );
    // `.card .body { padding-right: 16px }` + 16px star → icon centre 24px in.
    expect((card.right - 24 - star.center.dx).abs(), lessThan(1.5));
  });

  testWidgets('summary gap is 6px with or without the star', (tester) async {
    for (final favorite in [false, true]) {
      await pumpCard(tester, favorite: favorite);
      final title = tester.getRect(find.byKey(DayzEntryCard.titleKey));
      final summary = tester.getRect(find.text('Summary'));
      expect(
        summary.top - title.bottom,
        closeTo(6, 1),
        reason: 'favorite=$favorite must not push the summary down',
      );
    }
  });
}
