// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/l10n/locale_controller.dart';

class DayZApp extends StatefulWidget {
  /// 可选注入 [LocaleController]，方便测试。
  final LocaleController? localeController;

  const DayZApp({super.key, this.localeController});

  @override
  State<DayZApp> createState() => _DayZAppState();
}

class _DayZAppState extends State<DayZApp> {
  late final LocaleController _localeController;

  @override
  void initState() {
    super.initState();
    _localeController = widget.localeController ?? LocaleController();
    _localeController.addListener(_onLocaleChanged);
    _localeController.init();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _localeController.removeListener(_onLocaleChanged);
    // 只 dispose 自己创建的 controller。
    if (widget.localeController == null) {
      _localeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DayZ',
      theme: ThemeData(
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _localeController.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null &&
            supportedLocales
                .any((s) => s.languageCode == locale.languageCode)) {
          return locale;
        }
        return const Locale('zh');
      },
      home: const DebugHome(),
    );
  }
}
