// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/draft_recovery_status.dart';
import 'package:dayz/drafts/lifecycle_bridge.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/l10n/locale_controller.dart';

class DraftRecoveryHolder {
  DraftRecoveryHolder._();

  static DraftRecoveryStatus lastStatus = const DraftRecoveryStatus(
    hasResidual: false,
  );

  static void update(DraftRecoveryStatus status) {
    lastStatus = status;
  }

  static void resetForTesting() {
    lastStatus = const DraftRecoveryStatus(hasResidual: false);
  }
}

class DayZApp extends StatefulWidget {
  /// 可选注入 [LocaleController]，方便测试。
  final LocaleController? localeController;

  /// 可选注入草稿协调器；生产入口注入后由根 Widget 挂生命周期桥。
  final DraftCoordinator? draftCoordinator;

  const DayZApp({super.key, this.localeController, this.draftCoordinator});

  @override
  State<DayZApp> createState() => _DayZAppState();
}

class _DayZAppState extends State<DayZApp> {
  late final LocaleController _localeController;
  LifecycleBridge? _draftLifecycleBridge;

  @override
  void initState() {
    super.initState();
    _localeController = widget.localeController ?? LocaleController();
    _localeController.addListener(_onLocaleChanged);
    _localeController.init();
    _startDraftLifecycleBridge();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  void _startDraftLifecycleBridge() {
    final coordinator = widget.draftCoordinator;
    if (coordinator == null) {
      return;
    }

    _draftLifecycleBridge = LifecycleBridge(coordinator: coordinator)..start();
  }

  @override
  void dispose() {
    _draftLifecycleBridge?.stop();
    _localeController.removeListener(_onLocaleChanged);
    // 只 dispose 自己创建的 controller。
    if (widget.localeController == null) {
      _localeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleControllerScope(
      controller: _localeController,
      child: MaterialApp(
        title: 'DayZ',
        theme: ThemeData(useMaterial3: true),
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
              supportedLocales.any(
                (s) => s.languageCode == locale.languageCode,
              )) {
            return locale;
          }
          return const Locale('zh');
        },
        home: const DebugHome(),
      ),
    );
  }
}
