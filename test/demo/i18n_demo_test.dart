// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dayz/app.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/l10n/locale_controller.dart';
import 'package:dayz/demo/i18n_demo.dart';
import 'package:dayz/demo/demo_entry.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('demos 列表含 i18n Demo 入口', (tester) async {
    final entry = demos.firstWhere((e) => e.title == 'i18n Demo');
    expect(entry.subtitle, '国际化：语言切换 + 文案取值示范');
  });

  testWidgets('zh locale → demo 文案为中文', (tester) async {
    final controller = LocaleController();
    await controller.init();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: I18nDemo(localeController: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsWidgets);
    expect(find.text('今天还没有记录'), findsOneWidget);
    expect(find.text('今天共 3 篇'), findsOneWidget);
  });

  testWidgets('en locale → demo 文案为英文', (tester) async {
    final controller = LocaleController();
    await controller.init();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: I18nDemo(localeController: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsWidgets);
    expect(find.text('No entries today'), findsOneWidget);
    expect(find.text('3 entries today'), findsOneWidget);
  });

  testWidgets('点击 demo 语言选项 → DayZApp locale 随之切换', (tester) async {
    final controller = LocaleController();
    await controller.setLocale(const Locale('zh'));

    await tester.pumpWidget(DayZApp(localeController: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('i18n Demo'));
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsWidgets);
    expect(find.text('今天共 3 篇'), findsOneWidget);

    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsWidgets);
    expect(find.text('3 entries today'), findsOneWidget);
    expect(find.text('今天共 3 篇'), findsNothing);

    await tester.tap(find.text('中文').first);
    await tester.pumpAndSettle();

    expect(find.text('语言设置'), findsWidgets);
    expect(find.text('今天共 3 篇'), findsOneWidget);
  });
}
