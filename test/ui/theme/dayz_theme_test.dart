// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';

/// Unit and widget tests for [DayzThemes] assembly.
///
/// Author: @Ray
void main() {
  group('DayzTheme Assembly Tests', () {
    test('Brightness and extensions of the 6 configurations are correct', () {
      final configs = {
        'purpleLight': (
          DayzThemes.purpleLight,
          Brightness.light,
          DayzColors.purpleLight,
        ),
        'purpleDark': (
          DayzThemes.purpleDark,
          Brightness.dark,
          DayzColors.purpleDark,
        ),
        'amberLight': (
          DayzThemes.amberLight,
          Brightness.light,
          DayzColors.amberLight,
        ),
        'amberDark': (
          DayzThemes.amberDark,
          Brightness.dark,
          DayzColors.amberDark,
        ),
        'sageLight': (
          DayzThemes.sageLight,
          Brightness.light,
          DayzColors.sageLight,
        ),
        'sageDark': (DayzThemes.sageDark, Brightness.dark, DayzColors.sageDark),
      };

      configs.forEach((name, data) {
        final theme = data.$1;
        final expectedBrightness = data.$2;
        final expectedColors = data.$3;

        expect(
          theme.brightness,
          expectedBrightness,
          reason: '$name brightness mismatch',
        );

        final colors = theme.extension<DayzColors>();
        expect(colors, isNotNull, reason: '$name lacks DayzColors extension');
        expect(colors!.bg, expectedColors.bg, reason: '$name bg mismatch');
        expect(
          colors.accent,
          expectedColors.accent,
          reason: '$name accent mismatch',
        );
        expect(theme.splashFactory, same(NoSplash.splashFactory));
        expect(theme.splashColor, Colors.transparent);
        expect(theme.highlightColor, Colors.transparent);
      });
    });

    testWidgets('context.dayz returns correct values for pumped themes', (
      WidgetTester tester,
    ) async {
      final testCases = [
        (DayzThemes.purpleLight, DayzColors.purpleLight.accent),
        (DayzThemes.purpleDark, DayzColors.purpleDark.accent),
        (DayzThemes.amberLight, DayzColors.amberLight.accent),
        (DayzThemes.amberDark, DayzColors.amberDark.accent),
        (DayzThemes.sageLight, DayzColors.sageLight.accent),
        (DayzThemes.sageDark, DayzColors.sageDark.accent),
      ];

      for (final tc in testCases) {
        final theme = tc.$1;
        final expectedAccent = tc.$2;
        late Color actualAccent;

        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: theme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  actualAccent = context.dayz.accent;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(actualAccent, expectedAccent);
      }
    });
  });
}
