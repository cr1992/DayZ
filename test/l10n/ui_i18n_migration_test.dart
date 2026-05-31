// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';
import 'package:dayz/ui/widgets/dayz_favorite_star.dart';
import 'package:dayz/ui/widgets/dayz_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('legacy UI defaults follow English locale', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            DayzEmptyState(),
            DayzFavoriteStar(isFavorite: false),
            DayzSearchField(onCancel: _noop),
          ],
        ),
      ),
    );

    expect(find.text('No content yet'), findsOneWidget);
    expect(
      find.text('Write your first journal entry and it will appear here.'),
      findsOneWidget,
    );
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.bySemanticsLabel('Favorite'), findsOneWidget);

    expect(find.text('这里还没有内容'), findsNothing);
    expect(find.text('搜索'), findsNothing);
    expect(find.bySemanticsLabel('收藏'), findsNothing);
  });
}

void _noop() {}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: DayzThemes.purpleLight,
    home: Scaffold(body: child),
  );
}
