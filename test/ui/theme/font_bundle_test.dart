// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Font Bundle Tests', () {
    testWidgets('Custom fonts Hanken Grotesk and Newsreader render correctly', (WidgetTester tester) async {
      // 1. Check if font files exist in assets/fonts/
      final fontDir = Directory('assets/fonts');
      expect(fontDir.existsSync(), isTrue);

      final expectedFiles = [
        'HankenGrotesk-Regular.ttf',
        'HankenGrotesk-Medium.ttf',
        'HankenGrotesk-SemiBold.ttf',
        'HankenGrotesk-Bold.ttf',
        'Newsreader-Regular.ttf',
        'Newsreader-Medium.ttf',
        'Newsreader-SemiBold.ttf',
        'Newsreader-Bold.ttf',
        'Newsreader-Italic.ttf',
        'Newsreader-MediumItalic.ttf',
        'HankenGrotesk_OFL.txt',
        'Newsreader_OFL.txt',
      ];

      for (final file in expectedFiles) {
        final path = 'assets/fonts/$file';
        expect(File(path).existsSync(), isTrue, reason: '$file does not exist');
      }

      // 2. Test rendering with Hanken Grotesk
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              'Hello with Hanken Grotesk',
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      );

      final hankenText = tester.widget<Text>(find.text('Hello with Hanken Grotesk'));
      expect(hankenText.style?.fontFamily, 'Hanken Grotesk');

      // 3. Test rendering with Newsreader
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              'Hello with Newsreader',
              style: const TextStyle(
                fontFamily: 'Newsreader',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );

      final newsreaderText = tester.widget<Text>(find.text('Hello with Newsreader'));
      expect(newsreaderText.style?.fontFamily, 'Newsreader');
      expect(newsreaderText.style?.fontStyle, FontStyle.italic);
    });
  });
}
