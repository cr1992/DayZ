// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dayz_colors.dart';
import 'dayz_fonts.dart';
import 'dayz_text_theme.dart';

/// Theme type options corresponding to the design.
///
/// Author: @Ray
enum DayzThemeType { purple, amber, sage }

/// Factory and assembly methods for the 6 ThemeData variants.
///
/// Author: @Ray
ThemeData dayzTheme(DayzThemeType type, Brightness brightness) {
  final DayzColors colors;
  final bool isDark = brightness == Brightness.dark;

  switch (type) {
    case DayzThemeType.purple:
      colors = isDark ? DayzColors.purpleDark : DayzColors.purpleLight;
      break;
    case DayzThemeType.amber:
      colors = isDark ? DayzColors.amberDark : DayzColors.amberLight;
      break;
    case DayzThemeType.sage:
      colors = isDark ? DayzColors.sageDark : DayzColors.sageLight;
      break;
  }

  final textTheme = DayzTextTheme.fromColors(colors);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
    ),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
        ).copyWith(
          surface: colors.surface,
          onSurface: colors.ink,
          primary: colors.accent,
          onPrimary: colors.onAccent,
        ),
    scaffoldBackgroundColor: colors.bg,
    fontFamily: DayzFonts.sans,
    fontFamilyFallback: DayzFonts.sansFallback,
    textTheme: TextTheme(
      displayLarge: textTheme.display,
      headlineLarge: textTheme.h1,
      headlineMedium: textTheme.h2,
      titleLarge: textTheme.h3,
      bodyLarge: textTheme.body,
      bodyMedium: textTheme.body,
      bodySmall: textTheme.caption,
      labelSmall: textTheme.overline,
    ),
    extensions: [colors, textTheme],
  );
}

/// Static registry of the 6 standard DayZ ThemeData configurations.
///
/// Author: @Ray
abstract final class DayzThemes {
  static ThemeData get purpleLight =>
      dayzTheme(DayzThemeType.purple, Brightness.light);
  static ThemeData get purpleDark =>
      dayzTheme(DayzThemeType.purple, Brightness.dark);

  static ThemeData get amberLight =>
      dayzTheme(DayzThemeType.amber, Brightness.light);
  static ThemeData get amberDark =>
      dayzTheme(DayzThemeType.amber, Brightness.dark);

  static ThemeData get sageLight =>
      dayzTheme(DayzThemeType.sage, Brightness.light);
  static ThemeData get sageDark =>
      dayzTheme(DayzThemeType.sage, Brightness.dark);

  /// Helper map of themes.
  static Map<String, ThemeData> get all => {
    'purpleLight': purpleLight,
    'purpleDark': purpleDark,
    'amberLight': amberLight,
    'amberDark': amberDark,
    'sageLight': sageLight,
    'sageDark': sageDark,
  };
}
