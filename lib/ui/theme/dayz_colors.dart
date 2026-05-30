// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'dayz_tokens.g.dart';

/// DayZ Theme extension for custom semantic colors and shadows.
///
/// Author: @Ray
class DayzColors extends ThemeExtension<DayzColors> {
  final Color bg;
  final Color bg2;
  final Color danger;
  final Color dangerSoft;
  final Color favorite;
  final Color hairline;
  final Color hairline2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;
  final Color overlay;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowSm;
  final Color surface;
  final Color surface2;
  final Color accent;
  final Color accentInk;
  final Color accentRing;
  final Color accentSoft;
  final Color accentSoft2;
  final Color accentStrong;
  final Color onAccent;

  const DayzColors({
    required this.bg,
    required this.bg2,
    required this.danger,
    required this.dangerSoft,
    required this.favorite,
    required this.hairline,
    required this.hairline2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.overlay,
    required this.shadowLg,
    required this.shadowMd,
    required this.shadowSm,
    required this.surface,
    required this.surface2,
    required this.accent,
    required this.accentInk,
    required this.accentRing,
    required this.accentSoft,
    required this.accentSoft2,
    required this.accentStrong,
    required this.onAccent,
  });

  /// 80% opacity surface for glass effect (derived from screen.css scrolled state background)
  Color get glassSurface => surface.withValues(alpha: 0.8);

  /// 3-stop top-lighted linear gradient for FAB (derived from spec.css .fab-main background)
  Gradient get fabGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accent, const Color(0xFFFFFFFF), 0.08)!,
          accent,
          accentStrong,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  @override
  DayzColors copyWith({
    Color? bg,
    Color? bg2,
    Color? danger,
    Color? dangerSoft,
    Color? favorite,
    Color? hairline,
    Color? hairline2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? overlay,
    List<BoxShadow>? shadowLg,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowSm,
    Color? surface,
    Color? surface2,
    Color? accent,
    Color? accentInk,
    Color? accentRing,
    Color? accentSoft,
    Color? accentSoft2,
    Color? accentStrong,
    Color? onAccent,
  }) {
    return DayzColors(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      favorite: favorite ?? this.favorite,
      hairline: hairline ?? this.hairline,
      hairline2: hairline2 ?? this.hairline2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      overlay: overlay ?? this.overlay,
      shadowLg: shadowLg ?? this.shadowLg,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowSm: shadowSm ?? this.shadowSm,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentRing: accentRing ?? this.accentRing,
      accentSoft: accentSoft ?? this.accentSoft,
      accentSoft2: accentSoft2 ?? this.accentSoft2,
      accentStrong: accentStrong ?? this.accentStrong,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  DayzColors lerp(ThemeExtension<DayzColors>? other, double t) {
    if (other is! DayzColors) {
      return this;
    }
    return DayzColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairline2: Color.lerp(hairline2, other.hairline2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      ink4: Color.lerp(ink4, other.ink4, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t) ?? shadowLg,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t) ?? shadowMd,
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t) ?? shadowSm,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentRing: Color.lerp(accentRing, other.accentRing, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentSoft2: Color.lerp(accentSoft2, other.accentSoft2, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }

  // Predefined instances for the 6 themes
  static final DayzColors purpleLight = DayzColors(
    bg: DayzTokens.purpleLightBg,
    bg2: DayzTokens.purpleLightBg2,
    danger: DayzTokens.purpleLightDanger,
    dangerSoft: DayzTokens.purpleLightDangerSoft,
    favorite: DayzTokens.purpleLightFavorite,
    hairline: DayzTokens.purpleLightHairline,
    hairline2: DayzTokens.purpleLightHairline2,
    ink: DayzTokens.purpleLightInk,
    ink2: DayzTokens.purpleLightInk2,
    ink3: DayzTokens.purpleLightInk3,
    ink4: DayzTokens.purpleLightInk4,
    overlay: DayzTokens.purpleLightOverlay,
    shadowLg: DayzTokens.purpleLightShadowLg,
    shadowMd: DayzTokens.purpleLightShadowMd,
    shadowSm: DayzTokens.purpleLightShadowSm,
    surface: DayzTokens.purpleLightSurface,
    surface2: DayzTokens.purpleLightSurface2,
    accent: DayzTokens.purpleLightAccent,
    accentInk: DayzTokens.purpleLightAccentInk,
    accentRing: DayzTokens.purpleLightAccentRing,
    accentSoft: DayzTokens.purpleLightAccentSoft,
    accentSoft2: DayzTokens.purpleLightAccentSoft2,
    accentStrong: DayzTokens.purpleLightAccentStrong,
    onAccent: DayzTokens.purpleLightOnAccent,
  );

  static final DayzColors purpleDark = DayzColors(
    bg: DayzTokens.purpleDarkBg,
    bg2: DayzTokens.purpleDarkBg2,
    danger: DayzTokens.purpleDarkDanger,
    dangerSoft: DayzTokens.purpleDarkDangerSoft,
    favorite: DayzTokens.purpleDarkFavorite,
    hairline: DayzTokens.purpleDarkHairline,
    hairline2: DayzTokens.purpleDarkHairline2,
    ink: DayzTokens.purpleDarkInk,
    ink2: DayzTokens.purpleDarkInk2,
    ink3: DayzTokens.purpleDarkInk3,
    ink4: DayzTokens.purpleDarkInk4,
    overlay: DayzTokens.purpleDarkOverlay,
    shadowLg: DayzTokens.purpleDarkShadowLg,
    shadowMd: DayzTokens.purpleDarkShadowMd,
    shadowSm: DayzTokens.purpleDarkShadowSm,
    surface: DayzTokens.purpleDarkSurface,
    surface2: DayzTokens.purpleDarkSurface2,
    accent: DayzTokens.purpleDarkAccent,
    accentInk: DayzTokens.purpleDarkAccentInk,
    accentRing: DayzTokens.purpleDarkAccentRing,
    accentSoft: DayzTokens.purpleDarkAccentSoft,
    accentSoft2: DayzTokens.purpleDarkAccentSoft2,
    accentStrong: DayzTokens.purpleDarkAccentStrong,
    onAccent: DayzTokens.purpleDarkOnAccent,
  );

  static final DayzColors amberLight = DayzColors(
    bg: DayzTokens.amberLightBg,
    bg2: DayzTokens.amberLightBg2,
    danger: DayzTokens.amberLightDanger,
    dangerSoft: DayzTokens.amberLightDangerSoft,
    favorite: DayzTokens.amberLightFavorite,
    hairline: DayzTokens.amberLightHairline,
    hairline2: DayzTokens.amberLightHairline2,
    ink: DayzTokens.amberLightInk,
    ink2: DayzTokens.amberLightInk2,
    ink3: DayzTokens.amberLightInk3,
    ink4: DayzTokens.amberLightInk4,
    overlay: DayzTokens.amberLightOverlay,
    shadowLg: DayzTokens.amberLightShadowLg,
    shadowMd: DayzTokens.amberLightShadowMd,
    shadowSm: DayzTokens.amberLightShadowSm,
    surface: DayzTokens.amberLightSurface,
    surface2: DayzTokens.amberLightSurface2,
    accent: DayzTokens.amberLightAccent,
    accentInk: DayzTokens.amberLightAccentInk,
    accentRing: DayzTokens.amberLightAccentRing,
    accentSoft: DayzTokens.amberLightAccentSoft,
    accentSoft2: DayzTokens.amberLightAccentSoft2,
    accentStrong: DayzTokens.amberLightAccentStrong,
    onAccent: DayzTokens.amberLightOnAccent,
  );

  static final DayzColors amberDark = DayzColors(
    bg: DayzTokens.amberDarkBg,
    bg2: DayzTokens.amberDarkBg2,
    danger: DayzTokens.amberDarkDanger,
    dangerSoft: DayzTokens.amberDarkDangerSoft,
    favorite: DayzTokens.amberDarkFavorite,
    hairline: DayzTokens.amberDarkHairline,
    hairline2: DayzTokens.amberDarkHairline2,
    ink: DayzTokens.amberDarkInk,
    ink2: DayzTokens.amberDarkInk2,
    ink3: DayzTokens.amberDarkInk3,
    ink4: DayzTokens.amberDarkInk4,
    overlay: DayzTokens.amberDarkOverlay,
    shadowLg: DayzTokens.amberDarkShadowLg,
    shadowMd: DayzTokens.amberDarkShadowMd,
    shadowSm: DayzTokens.amberDarkShadowSm,
    surface: DayzTokens.amberDarkSurface,
    surface2: DayzTokens.amberDarkSurface2,
    accent: DayzTokens.amberDarkAccent,
    accentInk: DayzTokens.amberDarkAccentInk,
    accentRing: DayzTokens.amberDarkAccentRing,
    accentSoft: DayzTokens.amberDarkAccentSoft,
    accentSoft2: DayzTokens.amberDarkAccentSoft2,
    accentStrong: DayzTokens.amberDarkAccentStrong,
    onAccent: DayzTokens.amberDarkOnAccent,
  );

  static final DayzColors sageLight = DayzColors(
    bg: DayzTokens.sageLightBg,
    bg2: DayzTokens.sageLightBg2,
    danger: DayzTokens.sageLightDanger,
    dangerSoft: DayzTokens.sageLightDangerSoft,
    favorite: DayzTokens.sageLightFavorite,
    hairline: DayzTokens.sageLightHairline,
    hairline2: DayzTokens.sageLightHairline2,
    ink: DayzTokens.sageLightInk,
    ink2: DayzTokens.sageLightInk2,
    ink3: DayzTokens.sageLightInk3,
    ink4: DayzTokens.sageLightInk4,
    overlay: DayzTokens.sageLightOverlay,
    shadowLg: DayzTokens.sageLightShadowLg,
    shadowMd: DayzTokens.sageLightShadowMd,
    shadowSm: DayzTokens.sageLightShadowSm,
    surface: DayzTokens.sageLightSurface,
    surface2: DayzTokens.sageLightSurface2,
    accent: DayzTokens.sageLightAccent,
    accentInk: DayzTokens.sageLightAccentInk,
    accentRing: DayzTokens.sageLightAccentRing,
    accentSoft: DayzTokens.sageLightAccentSoft,
    accentSoft2: DayzTokens.sageLightAccentSoft2,
    accentStrong: DayzTokens.sageLightAccentStrong,
    onAccent: DayzTokens.sageLightOnAccent,
  );

  static final DayzColors sageDark = DayzColors(
    bg: DayzTokens.sageDarkBg,
    bg2: DayzTokens.sageDarkBg2,
    danger: DayzTokens.sageDarkDanger,
    dangerSoft: DayzTokens.sageDarkDangerSoft,
    favorite: DayzTokens.sageDarkFavorite,
    hairline: DayzTokens.sageDarkHairline,
    hairline2: DayzTokens.sageDarkHairline2,
    ink: DayzTokens.sageDarkInk,
    ink2: DayzTokens.sageDarkInk2,
    ink3: DayzTokens.sageDarkInk3,
    ink4: DayzTokens.sageDarkInk4,
    overlay: DayzTokens.sageDarkOverlay,
    shadowLg: DayzTokens.sageDarkShadowLg,
    shadowMd: DayzTokens.sageDarkShadowMd,
    shadowSm: DayzTokens.sageDarkShadowSm,
    surface: DayzTokens.sageDarkSurface,
    surface2: DayzTokens.sageDarkSurface2,
    accent: DayzTokens.sageDarkAccent,
    accentInk: DayzTokens.sageDarkAccentInk,
    accentRing: DayzTokens.sageDarkAccentRing,
    accentSoft: DayzTokens.sageDarkAccentSoft,
    accentSoft2: DayzTokens.sageDarkAccentSoft2,
    accentStrong: DayzTokens.sageDarkAccentStrong,
    onAccent: DayzTokens.sageDarkOnAccent,
  );
}

/// Extension helper to retrieve [DayzColors] directly from [BuildContext].
///
/// Author: @Ray
extension DayzColorsX on BuildContext {
  DayzColors get dayz => Theme.of(this).extension<DayzColors>()!;
}
