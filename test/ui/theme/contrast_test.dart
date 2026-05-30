// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

/// Contrast registry case loaded from contrast_xfail.yaml
class XFailCase {
  final String theme;
  final String foreground;
  final String background;
  final String reason;

  XFailCase({
    required this.theme,
    required this.foreground,
    required this.background,
    required this.reason,
  });
}

/// Simple regex-based YAML parser for contrast_xfail.yaml.
/// Avoids external package:yaml dependency.
List<XFailCase> parseXFailYaml(String content) {
  final List<XFailCase> cases = [];
  final lines = content.split('\n');
  String? theme;
  String? foreground;
  String? background;
  String? reason;

  void saveCurrent() {
    if (theme != null && foreground != null && background != null) {
      cases.add(XFailCase(
        theme: theme!,
        foreground: foreground!,
        background: background!,
        reason: reason ?? '',
      ));
    }
  }

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    
    if (line.startsWith('-')) {
      saveCurrent();
      theme = null;
      foreground = null;
      background = null;
      reason = null;
      line = line.substring(1).trim();
    }

    final colonIdx = line.indexOf(':');
    if (colonIdx != -1) {
      final key = line.substring(0, colonIdx).trim();
      final val = line.substring(colonIdx + 1).trim().replaceAll('"', '').replaceAll("'", "");
      
      if (key == 'theme') theme = val;
      if (key == 'foreground') foreground = val;
      if (key == 'background') background = val;
      if (key == 'reason') reason = val;
    }
  }
  saveCurrent();
  return cases;
}

double calculateLuminance(Color color) {
  double convert(double channelValue) {
    final double s = channelValue / 255.0;
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  final double r = convert(color.red.toDouble());
  final double g = convert(color.green.toDouble());
  final double b = convert(color.blue.toDouble());

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double calculateContrastRatio(Color color1, Color color2) {
  final double l1 = calculateLuminance(color1);
  final double l2 = calculateLuminance(color2);

  final double brightest = math.max(l1, l2);
  final double darkest = math.min(l1, l2);

  return (brightest + 0.05) / (darkest + 0.05);
}

Color getColorByName(DayzColors colors, String name) {
  switch (name) {
    case 'bg': return colors.bg;
    case 'bg2': return colors.bg2;
    case 'danger': return colors.danger;
    case 'dangerSoft': return colors.dangerSoft;
    case 'favorite': return colors.favorite;
    case 'hairline': return colors.hairline;
    case 'hairline2': return colors.hairline2;
    case 'ink': return colors.ink;
    case 'ink2': return colors.ink2;
    case 'ink3': return colors.ink3;
    case 'ink4': return colors.ink4;
    case 'overlay': return colors.overlay;
    case 'surface': return colors.surface;
    case 'surface2': return colors.surface2;
    case 'accent': return colors.accent;
    case 'accentInk': return colors.accentInk;
    case 'accentRing': return colors.accentRing;
    case 'accentSoft': return colors.accentSoft;
    case 'accentSoft2': return colors.accentSoft2;
    case 'accentStrong': return colors.accentStrong;
    case 'onAccent': return colors.onAccent;
    default: throw ArgumentError('Unknown color name: $name');
  }
}

/// Unit test asserting WCAG contrast guidelines and checking expected failures against contrast_xfail.yaml
///
/// Author: @Ray
void main() {
  group('Contrast Verification Tests', () {
    late List<XFailCase> xfails;

    setUpAll(() {
      final file = File('test/ui/theme/contrast_xfail.yaml');
      expect(file.existsSync(), isTrue, reason: 'contrast_xfail.yaml is missing');
      xfails = parseXFailYaml(file.readAsStringSync());
    });

    bool isExpectedFail(String theme, String fg, String bg) {
      return xfails.any((c) =>
          c.theme == theme && c.foreground == fg && c.background == bg);
    }

    test('Verify theme color contrast ratios', () {
      final themes = {
        'purpleLight': DayzColors.purpleLight,
        'purpleDark': DayzColors.purpleDark,
        'amberLight': DayzColors.amberLight,
        'amberDark': DayzColors.amberDark,
        'sageLight': DayzColors.sageLight,
        'sageDark': DayzColors.sageDark,
      };

      final testPairs = [
        // (foreground, background, requiredRatio)
        ('ink', 'bg', 4.5),
        ('ink', 'surface', 4.5),
        ('ink2', 'bg', 4.5),
        ('ink2', 'surface', 4.5),
        ('accentInk', 'accentSoft', 4.5),
        ('accentInk', 'bg', 4.5),
        ('accentInk', 'surface', 4.5),
        ('onAccent', 'accent', 4.5),
        ('accent', 'bg', 3.0),
        ('ink3', 'bg', 4.5),
        ('ink3', 'surface', 4.5),
      ];

      for (final themeEntry in themes.entries) {
        final themeName = themeEntry.key;
        final colors = themeEntry.value;

        for (final pair in testPairs) {
          final fgName = pair.$1 as String;
          final bgName = pair.$2 as String;
          final requiredRatio = pair.$3 as double;

          final fgColor = getColorByName(colors, fgName);
          final bgColor = getColorByName(colors, bgName);
          final ratio = calculateContrastRatio(fgColor, bgColor);

          final expectedFail = isExpectedFail(themeName, fgName, bgName);

          if (ratio < requiredRatio) {
            if (expectedFail) {
              // Known registered failure, print warning and allow pass
              print('[XFAIL] Contrast failure expected and allowed: $themeName $fgName vs $bgName is ${ratio.toStringAsFixed(2)} (< $requiredRatio)');
            } else {
              // Unregistered failure, fail the test
              fail('Contrast violation in $themeName: $fgName vs $bgName is ${ratio.toStringAsFixed(2)} but requires >= $requiredRatio');
            }
          } else {
            if (expectedFail) {
              // It was expected to fail, but passed! Alert Ray to update the YAML file.
              print('[ALERT] Expected fail case $themeName $fgName vs $bgName now PASSES with ${ratio.toStringAsFixed(2)}. Please update contrast_xfail.yaml.');
            }
          }
        }
      }
    });
  });
}
