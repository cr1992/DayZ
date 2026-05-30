// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

/// Unit and widget tests for [DayzColors].
///
/// Author: @Ray
void main() {
  group('DayzColors Tests', () {
    test('copyWith works correctly', () {
      final base = DayzColors.purpleLight;
      final modified = base.copyWith(
        bg: const Color(0xFF112233),
        ink: const Color(0xFF445566),
      );

      expect(modified.bg, const Color(0xFF112233));
      expect(modified.ink, const Color(0xFF445566));
      expect(modified.bg2, base.bg2);
      expect(modified.danger, base.danger);
    });

    test('lerp works correctly', () {
      final a = DayzColors.purpleLight;
      final b = DayzColors.purpleDark;

      final lerp0 = a.lerp(b, 0.0);
      expect(lerp0.bg, a.bg);
      expect(lerp0.ink, a.ink);

      final lerp1 = a.lerp(b, 1.0);
      expect(lerp1.bg, b.bg);
      expect(lerp1.ink, b.ink);

      final lerp05 = a.lerp(b, 0.5);
      expect(lerp05.bg, Color.lerp(a.bg, b.bg, 0.5));
      expect(lerp05.ink, Color.lerp(a.ink, b.ink, 0.5));
    });

    test('glassSurface and fabGradient values match specification', () {
      final colors = DayzColors.purpleLight;
      expect(colors.glassSurface, colors.surface.withValues(alpha: 0.8));
      
      final grad = colors.fabGradient as LinearGradient;
      expect(grad.colors.length, 3);
      expect(grad.colors[0], Color.lerp(colors.accent, const Color(0xFFFFFFFF), 0.08));
      expect(grad.colors[1], colors.accent);
      expect(grad.colors[2], colors.accentStrong);
      expect(grad.stops, const [0.0, 0.5, 1.0]);
    });

    testWidgets('context.dayz extension retrieves correct theme colors', (WidgetTester tester) async {
      late DayzColors colorsFromContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [DayzColors.purpleLight],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                colorsFromContext = context.dayz;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(colorsFromContext, isNotNull);
      expect(colorsFromContext.bg, DayzColors.purpleLight.bg);
      expect(colorsFromContext.accent, DayzColors.purpleLight.accent);
    });
  });
}
