// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_fonts.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';

/// Unit and widget tests for [DayzTextTheme] and [DayzFonts].
///
/// Author: @Ray
void main() {
  group('DayzTextTheme Tests', () {
    final colors = DayzColors.purpleLight;
    final textTheme = DayzTextTheme.fromColors(colors);

    test('Font family and fallbacks are correct', () {
      // D3 fonts assertion
      expect(DayzFonts.sans, 'Hanken Grotesk');
      expect(DayzFonts.serif, 'Newsreader');
      expect(DayzFonts.sansFallback, contains('PingFang SC'));
      expect(DayzFonts.serifFallback, contains('Songti SC'));

      // TextTheme families
      expect(textTheme.body.fontFamily, DayzFonts.sans);
      expect(textTheme.body.fontFamilyFallback, DayzFonts.sansFallback);
      expect(textTheme.diary.fontFamily, DayzFonts.serif);
      expect(textTheme.diary.fontFamilyFallback, DayzFonts.serifFallback);
    });

    test('Line height and leading distribution are correct', () {
      // Body (regular text) height is 1.7
      expect(textTheme.body.height, 1.7);
      expect(textTheme.body.leadingDistribution, TextLeadingDistribution.even);

      // Diary height is 1.8 (对齐设计稿中文阅读行高规范)
      expect(textTheme.diary.height, 1.8);
      expect(textTheme.diary.leadingDistribution, TextLeadingDistribution.even);

      // Other items have even leading distribution
      expect(textTheme.display.leadingDistribution, TextLeadingDistribution.even);
      expect(textTheme.h1.leadingDistribution, TextLeadingDistribution.even);
      expect(textTheme.h2.leadingDistribution, TextLeadingDistribution.even);
      expect(textTheme.h3.leadingDistribution, TextLeadingDistribution.even);
      expect(textTheme.caption.leadingDistribution, TextLeadingDistribution.even);
      expect(textTheme.overline.leadingDistribution, TextLeadingDistribution.even);
    });

    test('copyWith works correctly', () {
      final modified = textTheme.copyWith(
        body: textTheme.body.copyWith(fontSize: 20),
      );
      expect(modified.body.fontSize, 20);
      expect(modified.body.height, 1.7);
      expect(modified.diary.fontSize, textTheme.diary.fontSize);
    });

    test('lerp works correctly', () {
      final a = DayzTextTheme.fromColors(DayzColors.purpleLight);
      final b = DayzTextTheme.fromColors(DayzColors.purpleDark);

      final lerped = a.lerp(b, 0.5);
      expect(lerped.body.height, 1.7);
      expect(lerped.diary.height, 1.8);
      expect(lerped.body.color, Color.lerp(a.body.color, b.body.color, 0.5));
    });

    testWidgets('context.dayzText extension retrieves correct textTheme', (WidgetTester tester) async {
      late DayzTextTheme themeFromContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [textTheme],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                themeFromContext = context.dayzText;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(themeFromContext, isNotNull);
      expect(themeFromContext.body.fontSize, 16);
      expect(themeFromContext.diary.fontSize, 18);
    });
  });
}
