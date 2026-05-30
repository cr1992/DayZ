// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

void main() {
  group('AppLocalizations — zh', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = lookupAppLocalizations(const Locale('zh'));
    });

    test('appTitle 返回中文值', () {
      expect(l10n.appTitle, 'DayZ');
    });

    test('onThisDayCount plural — 0', () {
      expect(l10n.onThisDayCount(0), '今天还没有记录');
    });

    test('onThisDayCount plural — 3', () {
      expect(l10n.onThisDayCount(3), '今天共 3 篇');
    });

    test('yearsAgo plural — 0', () {
      expect(l10n.yearsAgo(0), '今年');
    });

    test('yearsAgo plural — 1', () {
      expect(l10n.yearsAgo(1), '1 年前');
    });

    test('yearsAgo plural — 5', () {
      expect(l10n.yearsAgo(5), '5 年前');
    });

    test('languageSetting 返回中文', () {
      expect(l10n.languageSetting, '语言设置');
    });
  });

  group('AppLocalizations — en', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = lookupAppLocalizations(const Locale('en'));
    });

    test('appTitle 返回英文值', () {
      expect(l10n.appTitle, 'DayZ');
    });

    test('onThisDayCount plural — 0', () {
      expect(l10n.onThisDayCount(0), 'No entries today');
    });

    test('onThisDayCount plural — 1', () {
      expect(l10n.onThisDayCount(1), '1 entry today');
    });

    test('onThisDayCount plural — 3', () {
      expect(l10n.onThisDayCount(3), '3 entries today');
    });

    test('yearsAgo plural — 0', () {
      expect(l10n.yearsAgo(0), 'This year');
    });

    test('yearsAgo plural — 1', () {
      expect(l10n.yearsAgo(1), '1 year ago');
    });

    test('yearsAgo plural — 5', () {
      expect(l10n.yearsAgo(5), '5 years ago');
    });

    test('languageSetting 返回英文', () {
      expect(l10n.languageSetting, 'Language');
    });
  });
}
