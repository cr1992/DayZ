// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/l10n/locale_controller.dart';

enum _LocaleChoice { system, zh, en }

/// i18n demo 页：语言切换 + 文案取值示范。
///
/// 可选注入 [LocaleController]，默认从 widget 树上找。
class I18nDemo extends StatelessWidget {
  final LocaleController? localeController;

  const I18nDemo({super.key, this.localeController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).languageCode;
    final controller = localeController ?? LocaleControllerScope.of(context);
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
                  RadioGroup<_LocaleChoice>(
                    groupValue: _choiceOf(controller.locale),
                    onChanged: (choice) {
                      _setChoice(controller, choice ?? _LocaleChoice.system);
                    },
                    child: Column(
                      children: [
                        _buildLocaleOption(
                          l10n.followSystem,
                          _LocaleChoice.system,
                        ),
                        _buildLocaleOption(l10n.locale_zh, _LocaleChoice.zh),
                        _buildLocaleOption(l10n.locale_en, _LocaleChoice.en),
                      ],
                    ),
                  ),
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

  _LocaleChoice _choiceOf(Locale? locale) {
    return switch (locale?.languageCode) {
      'zh' => _LocaleChoice.zh,
      'en' => _LocaleChoice.en,
      _ => _LocaleChoice.system,
    };
  }

  void _setChoice(LocaleController controller, _LocaleChoice choice) {
    switch (choice) {
      case _LocaleChoice.system:
        controller.followSystem();
      case _LocaleChoice.zh:
        controller.setLocale(const Locale('zh'));
      case _LocaleChoice.en:
        controller.setLocale(const Locale('en'));
    }
  }

  Widget _buildLocaleOption(String label, _LocaleChoice choice) {
    return RadioListTile<_LocaleChoice>(title: Text(label), value: choice);
  }
}
