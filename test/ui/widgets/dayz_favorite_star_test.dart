// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

/// Widget tests for [DayzFavoriteStar].
///
/// Author: @Ray
void main() {
  testWidgets('favorite star keeps one canonical path for both states', (
    tester,
  ) async {
    expect(
      DayzIcons.favoriteStarPath,
      'M12 2.5L14.47 8.6 21.04 9.06 16 13.3 17.58 19.69 12 16.2 6.42 19.69 8.01 13.3 2.97 9.06 9.53 8.6Z',
    );

    await tester.pumpWidget(
      localizedTestApp(
        child: const Row(
          textDirection: TextDirection.ltr,
          children: [
            DayzFavoriteStar(isFavorite: true),
            DayzFavoriteStar(isFavorite: false),
          ],
        ),
      ),
    );

    // The canonical key now sits on the [DayzIcon] wrapper; the actual painted
    // SvgPicture is its descendant.
    final filledSvg = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(const ValueKey('dayz-favorite-star-filled')),
        matching: find.byType(SvgPicture),
      ),
    );
    final outlineSvg = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(const ValueKey('dayz-favorite-star-outline')),
        matching: find.byType(SvgPicture),
      ),
    );

    expect(
      filledSvg.colorFilter,
      ColorFilter.mode(DayzColors.purpleLight.favorite, BlendMode.srcIn),
    );
    expect(
      outlineSvg.colorFilter,
      ColorFilter.mode(DayzColors.purpleLight.ink3, BlendMode.srcIn),
    );
  });

  testWidgets('favorite star exposes semantics and 44px hit target', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      localizedTestApp(
        child: DayzFavoriteStar(isFavorite: false, onPressed: () => taps += 1),
      ),
    );

    expect(find.bySemanticsLabel(testL10n.favorite), findsOneWidget);
    expect(
      tester.getSize(find.byType(DayzFavoriteStar)),
      const Size.square(44),
    );

    await tester.tap(find.byType(DayzFavoriteStar));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('interactive filled star reads unfavorite as a button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedTestApp(
        child: DayzFavoriteStar(isFavorite: true, onPressed: () {}),
      ),
    );

    final star = find.bySemanticsLabel(testL10n.unfavorite);
    expect(star, findsOneWidget);
    expect(tester.getSemantics(star).flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('read-only filled star reads its state, not an action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedTestApp(child: const DayzFavoriteStar(isFavorite: true)),
    );

    final star = find.bySemanticsLabel(testL10n.favorited);
    expect(star, findsOneWidget);
    expect(tester.getSemantics(star).flagsCollection.isButton, isFalse);
    expect(find.bySemanticsLabel(testL10n.unfavorite), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
    handle.dispose();
  });

  testWidgets('read-only outline star exposes no semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedTestApp(child: const DayzFavoriteStar(isFavorite: false)),
    );

    for (final label in [
      testL10n.favorite,
      testL10n.unfavorite,
      testL10n.favorited,
    ]) {
      expect(find.bySemanticsLabel(label), findsNothing);
    }
    expect(find.byType(Tooltip), findsNothing);
    handle.dispose();
  });

  testWidgets('entry card read-only star follows the same rule', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedTestApp(
        child: DayzEntryCard(
          title: 'Title',
          summary: 'Summary',
          date: DateTime(2026, 10, 10),
          favorite: true,
        ),
      ),
    );

    final star = find.bySemanticsLabel(testL10n.favorited);
    expect(star, findsOneWidget);
    expect(tester.getSemantics(star).flagsCollection.isButton, isFalse);
    expect(find.bySemanticsLabel(testL10n.unfavorite), findsNothing);
    handle.dispose();
  });

  testWidgets('entry card interactive star keeps the action label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedTestApp(
        child: DayzEntryCard(
          title: 'Title',
          summary: 'Summary',
          date: DateTime(2026, 10, 10),
          onFavoritePressed: () {},
        ),
      ),
    );

    final star = find.bySemanticsLabel(testL10n.favorite);
    expect(star, findsOneWidget);
    expect(tester.getSemantics(star).flagsCollection.isButton, isTrue);
    handle.dispose();
  });
}
