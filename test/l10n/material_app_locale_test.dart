// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/l10n/locale_controller.dart';

/// 最小 MaterialApp，只挂 l10n 并展示 seed 文案 + locale 文本。
Widget _buildTestApp({Locale? locale}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    localeResolutionCallback: (locale, supportedLocales) {
      if (locale != null &&
          supportedLocales.any((s) => s.languageCode == locale.languageCode)) {
        return locale;
      }
      return const Locale('zh');
    },
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          body: Column(
            children: [
              Text(l10n.appTitle),
              Text(l10n.languageSetting),
              Text(l10n.onThisDayCount(3)),
            ],
          ),
        );
      },
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('locale=en → 渲染英文 seed 文案', (tester) async {
    await tester.pumpWidget(_buildTestApp(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('DayZ'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('3 entries today'), findsOneWidget);
  });

  testWidgets('locale=zh → 渲染中文 seed 文案', (tester) async {
    await tester.pumpWidget(_buildTestApp(locale: const Locale('zh')));
    await tester.pumpAndSettle();

    expect(find.text('DayZ'), findsOneWidget);
    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('今天共 3 篇'), findsOneWidget);
  });

  testWidgets('不支持的 locale(fr) → 回退中文', (tester) async {
    await tester.pumpWidget(_buildTestApp(locale: const Locale('fr')));
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('今天共 3 篇'), findsOneWidget);
  });
}
