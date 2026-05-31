// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dayz/app.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/l10n/locale_controller.dart';
import 'package:dayz/demo/i18n_demo.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/ui/shell/app_router.dart';

import '../l10n/localized_test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appRouter.go(Routes.timelinePath);
  });

  testWidgets('demos 列表含 i18n Demo 入口', (tester) async {
    final entry = demos.firstWhere((e) => e.title == 'i18n Demo');
    expect(entry.subtitle, '国际化：语言切换 + 文案取值示范');
  });

  testWidgets('zh locale → demo 文案为中文', (tester) async {
    final controller = LocaleController();
    await controller.init();
    final zhL10n = lookupAppLocalizations(const Locale('zh'));

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('zh'),
        child: I18nDemo(localeController: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(zhL10n.languageSetting), findsWidgets);
    expect(find.text(zhL10n.onThisDayCount(0)), findsOneWidget);
    expect(find.text(zhL10n.onThisDayCount(3)), findsOneWidget);
  });

  testWidgets('en locale → demo 文案为英文', (tester) async {
    final controller = LocaleController();
    await controller.init();
    final enL10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('en'),
        child: I18nDemo(localeController: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(enL10n.languageSetting), findsWidgets);
    expect(find.text(enL10n.onThisDayCount(0)), findsOneWidget);
    expect(find.text(enL10n.onThisDayCount(3)), findsOneWidget);
  });

  testWidgets('点击 demo 语言选项 → DayZApp locale 随之切换', (tester) async {
    final controller = LocaleController();
    await controller.setLocale(const Locale('zh'));
    final zhL10n = lookupAppLocalizations(const Locale('zh'));
    final enL10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(DayZApp(localeController: controller));
    await tester.pumpAndSettle();

    appRouter.goNamed(Routes.debugHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('i18n Demo'));
    await tester.pumpAndSettle();

    expect(find.text(zhL10n.languageSetting), findsWidgets);
    expect(find.text(zhL10n.onThisDayCount(3)), findsOneWidget);

    await tester.tap(find.text(zhL10n.locale_en).first);
    await tester.pumpAndSettle();

    expect(find.text(enL10n.languageSetting), findsWidgets);
    expect(find.text(enL10n.onThisDayCount(3)), findsOneWidget);
    expect(find.text(zhL10n.onThisDayCount(3)), findsNothing);

    await tester.tap(find.text(enL10n.locale_zh).first);
    await tester.pumpAndSettle();

    expect(find.text(zhL10n.languageSetting), findsWidgets);
    expect(find.text(zhL10n.onThisDayCount(3)), findsOneWidget);
  });
}
