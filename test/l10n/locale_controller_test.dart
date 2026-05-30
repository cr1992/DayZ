// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dayz/l10n/locale_controller.dart';

void main() {
  group('LocaleController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('init() 无持久化值 → locale == null（跟随系统）', () async {
      final controller = LocaleController();
      await controller.init();
      expect(controller.locale, isNull);
    });

    test('setLocale(en) → locale == Locale("en") 且持久化写入', () async {
      final controller = LocaleController();
      await controller.init();

      await controller.setLocale(const Locale('en'));
      expect(controller.locale, const Locale('en'));

      // 验证持久化
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_override'), 'en');
    });

    test('init() 有持久化值时优先采用', () async {
      SharedPreferences.setMockInitialValues({'locale_override': 'en'});
      final controller = LocaleController();
      await controller.init();
      expect(controller.locale, const Locale('en'));
    });

    test('followSystem() → locale == null 且持久化清空', () async {
      SharedPreferences.setMockInitialValues({'locale_override': 'en'});
      final controller = LocaleController();
      await controller.init();
      expect(controller.locale, const Locale('en'));

      await controller.followSystem();
      expect(controller.locale, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_override'), isNull);
    });

    test('setLocale 触发 notifyListeners', () async {
      final controller = LocaleController();
      await controller.init();

      var notified = false;
      controller.addListener(() => notified = true);
      await controller.setLocale(const Locale('zh'));
      expect(notified, isTrue);
    });

    test('followSystem 触发 notifyListeners', () async {
      SharedPreferences.setMockInitialValues({'locale_override': 'en'});
      final controller = LocaleController();
      await controller.init();

      var notified = false;
      controller.addListener(() => notified = true);
      await controller.followSystem();
      expect(notified, isTrue);
    });

    test('init() 持久化值为空字符串 → 跟随系统', () async {
      SharedPreferences.setMockInitialValues({'locale_override': ''});
      final controller = LocaleController();
      await controller.init();
      expect(controller.locale, isNull);
    });
  });
}
