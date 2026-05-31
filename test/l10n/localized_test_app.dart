// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final AppLocalizations testL10n = lookupAppLocalizations(const Locale('zh'));
final AppLocalizations testEnL10n = lookupAppLocalizations(const Locale('en'));

/// Wraps widget tests with DayZ theme and generated localizations.
///
/// Author: @Ray
Widget localizedTestApp({
  required Widget child,
  Locale locale = const Locale('zh'),
  ThemeData? theme,
  TransitionBuilder? builder,
}) {
  return localizedMaterialApp(
    locale: locale,
    theme: theme,
    builder: builder,
    home: Scaffold(body: child),
  );
}

/// Wraps widget tests with DayZ theme, generated localizations, and a custom home.
///
/// Author: @Ray
Widget localizedMaterialApp({
  required Widget home,
  Locale locale = const Locale('zh'),
  ThemeData? theme,
  TransitionBuilder? builder,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme ?? DayzThemes.purpleLight,
    builder: builder,
    home: home,
  );
}

/// Wraps router widget tests with DayZ theme and generated localizations.
///
/// Author: @Ray
Widget localizedRouterTestApp({
  required RouterConfig<Object> routerConfig,
  Locale locale = const Locale('zh'),
  ThemeData? theme,
  TransitionBuilder? builder,
}) {
  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme ?? DayzThemes.purpleLight,
    builder: builder,
    routerConfig: routerConfig,
  );
}
