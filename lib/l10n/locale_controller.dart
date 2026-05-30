// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言偏好控制器。
///
/// 持 [Locale]? override（null = 跟随系统），通过 [SharedPreferences]
/// 持久化，切换后 [notifyListeners] 通知 [MaterialApp] 重建。
class LocaleController extends ChangeNotifier {
  static const String _prefsKey = 'locale_override';

  Locale? _locale;

  /// 当前覆盖 locale，null 表示跟随系统。
  Locale? get locale => _locale;

  /// 从持久化层读取偏好，异常时静默回落跟随系统。
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
      }
    } catch (_) {
      // 持久化读失败 → 跟随系统，不抛。
      _locale = null;
    }
    notifyListeners();
  }

  /// 设置覆盖 locale 并持久化。
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (_) {
      // 写入失败静默，状态已更新。
    }
  }

  /// 清除覆盖 → 跟随系统，并清空持久化。
  Future<void> followSystem() async {
    _locale = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {
      // 清除失败静默。
    }
  }
}
