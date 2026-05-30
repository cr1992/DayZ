// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/l10n/locale_controller.dart';

/// i18n demo 页：语言切换 + 文案取值示范。
///
/// 可选注入 [LocaleController]，默认从 widget 树上找。
class I18nDemo extends StatefulWidget {
  final LocaleController? localeController;

  const I18nDemo({super.key, this.localeController});

  @override
  State<I18nDemo> createState() => _I18nDemoState();
}

class _I18nDemoState extends State<I18nDemo> {
  late final LocaleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.localeController ?? LocaleController();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSetting)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 语言切换控件
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageSetting,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildLocaleOption(l10n.followSystem, null),
                  _buildLocaleOption(l10n.locale_zh, const Locale('zh')),
                  _buildLocaleOption(l10n.locale_en, const Locale('en')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seed 文案展示
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Divider(),

                  // Plural 示例
                  Text(l10n.onThisDayCount(0)),
                  Text(l10n.onThisDayCount(1)),
                  Text(l10n.onThisDayCount(3)),
                  const Divider(),

                  // yearsAgo plural
                  Text(l10n.yearsAgo(0)),
                  Text(l10n.yearsAgo(1)),
                  Text(l10n.yearsAgo(5)),
                  const Divider(),

                  // DateFormat — 按当前 locale 格式化
                  Text(DateFormat.yMMMMd(localeName).format(now)),
                  Text(DateFormat.jm(localeName).format(now)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocaleOption(String label, Locale? locale) {
    final isSelected = _controller.locale == locale;
    return RadioListTile<Locale?>(
      title: Text(label),
      value: locale,
      groupValue: _controller.locale,
      onChanged: (value) {
        if (value == null) {
          _controller.followSystem();
        } else {
          _controller.setLocale(value);
        }
      },
    );
  }
}
