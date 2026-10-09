// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'dayz_fonts.dart';
import 'dayz_colors.dart';

/// DayZ Theme extension for custom typography styles.
///
/// Author: @Ray
class DayzTextTheme extends ThemeExtension<DayzTextTheme> {
  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle body;
  final TextStyle diary;
  final TextStyle caption;
  final TextStyle overline;

  const DayzTextTheme({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body,
    required this.diary,
    required this.caption,
    required this.overline,
  });

  /// Factory to generate typographies initialized with respective colors from [DayzColors]
  factory DayzTextTheme.fromColors(DayzColors colors) {
    return DayzTextTheme(
      display: TextStyle(
        fontFamily: DayzFonts.serif,
        fontFamilyFallback: DayzFonts.serifFallback,
        fontSize: 44,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 44,
        height: 1.1,
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink,
      ),
      h1: TextStyle(
        fontFamily: DayzFonts.serif,
        fontFamilyFallback: DayzFonts.serifFallback,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 30,
        height: 1.7,
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink,
      ),
      h2: TextStyle(
        fontFamily: DayzFonts.serif,
        fontFamilyFallback: DayzFonts.serifFallback,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.7,
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink,
      ),
      h3: TextStyle(
        fontFamily: DayzFonts.sans,
        fontFamilyFallback: DayzFonts.sansFallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.7,
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink,
      ),
      body: TextStyle(
        fontFamily: DayzFonts.sans,
        fontFamilyFallback: DayzFonts.sansFallback,
        fontSize: 16,
        height: 1.7,
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink,
      ),
      diary: TextStyle(
        fontFamily: DayzFonts.serif, // var(--font-diary) resolves to --font-serif
        fontFamilyFallback: DayzFonts.serifFallback,
        fontSize: 18,
        height: 1.8, // 对齐设计稿中文阅读行高规范（design-system 字体排印）
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink,
      ),
      caption: TextStyle(
        fontFamily: DayzFonts.sans,
        fontFamilyFallback: DayzFonts.sansFallback,
        fontSize: 13,
        height: 1.7,
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink2,
      ),
      overline: TextStyle(
        fontFamily: DayzFonts.sans,
        fontFamilyFallback: DayzFonts.sansFallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.14 * 12,
        height: 1.7,
        leadingDistribution: TextLeadingDistribution.even,
        color: colors.ink3,
      ),
    );
  }

  @override
  DayzTextTheme copyWith({
    TextStyle? display,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? body,
    TextStyle? diary,
    TextStyle? caption,
    TextStyle? overline,
  }) {
    return DayzTextTheme(
      display: display ?? this.display,
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      body: body ?? this.body,
      diary: diary ?? this.diary,
      caption: caption ?? this.caption,
      overline: overline ?? this.overline,
    );
  }

  @override
  DayzTextTheme lerp(ThemeExtension<DayzTextTheme>? other, double t) {
    if (other is! DayzTextTheme) {
      return this;
    }
    return DayzTextTheme(
      display: TextStyle.lerp(display, other.display, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      diary: TextStyle.lerp(diary, other.diary, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
    );
  }
}

/// Extension helper to retrieve [DayzTextTheme] directly from [BuildContext].
///
/// Author: @Ray
extension DayzTextThemeX on BuildContext {
  DayzTextTheme get dayzText => Theme.of(this).extension<DayzTextTheme>()!;
}
