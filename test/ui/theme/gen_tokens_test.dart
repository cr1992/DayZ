// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../bin/gen_tokens.dart';

void main() {
  group('gen_tokens.dart Generator Tests', () {
    final tempDir = Directory.systemTemp.createTempSync('gen_tokens_test_');
    
    tearDownAll(() {
      tempDir.deleteSync(recursive: true);
    });

    test('Parses correct CSS and generates exact Dart structures', () {
      final inputPath = 'test/ui/theme/fixtures/test_tokens.css';
      final outputPath = '${tempDir.path}/dayz_tokens.g.dart';
      
      generateTokens(inputPath, outputPath);
      
      final outFile = File(outputPath);
      expect(outFile.existsSync(), isTrue);
      
      final content = outFile.readAsStringSync();
      
      // Spacing assertions
      expect(content, contains('abstract final class DayzSpacing {'));
      expect(content, contains('static const double s1 = 4.0;'));
      expect(content, contains('static const double s2 = 8.0;'));
      
      // Radii assertions
      expect(content, contains('abstract final class DayzRadii {'));
      expect(content, contains('static const double xs = 6.0;'));
      expect(content, contains('static const double full = 999.0;'));
      
      // Motion assertions
      expect(content, contains('abstract final class DayzMotion {'));
      expect(content, contains('static const Duration dur = Duration(milliseconds: 220);'));
      expect(content, contains("static const String ease = 'cubic-bezier(0.32, 0.72, 0, 1)';"));
      
      // Fonts assertions
      expect(content, contains('abstract final class DayzFonts {'));
      expect(content, contains("static const String sans = '\"Hanken Grotesk\", sans-serif';"));
      expect(content, contains("static const String serif = '\"Newsreader\", serif';"));
      
      // Color assertions & alpha rounding (0.32 * 255 = 81.6 -> 82 -> 0x52)
      // R=44=0x2C, G=40=0x28, B=33=0x21
      expect(content, contains('static const Color purpleLightOverlay = Color(0x522C2821);'));
      
      // Shadow assertions (shadowSm contains two BoxShadow structures)
      expect(content, contains('static const List<BoxShadow> purpleLightShadowSm = [\n'
          '    BoxShadow(\n'
          '      color: Color(0x0F3C3223),\n'
          '      offset: Offset(0.0, 1.0),\n'
          '      blurRadius: 2.0,\n'
          '      spreadRadius: 0.0,\n'
          '    ),\n'
          '    BoxShadow(\n'
          '      color: Color(0x0D3C3223),\n'
          '      offset: Offset(0.0, 1.0),\n'
          '      blurRadius: 3.0,\n'
          '      spreadRadius: 0.0,\n'
          '    ),\n'
          '  ];'));
    });

    test('Throws FormatException on malformed input CSS', () {
      final inputPath = 'test/ui/theme/fixtures/malformed_tokens.css';
      final outputPath = '${tempDir.path}/malformed_dayz_tokens.g.dart';
      
      expect(
        () => generateTokens(inputPath, outputPath),
        throwsFormatException,
      );
      
      final outFile = File(outputPath);
      expect(outFile.existsSync(), isFalse);
    });

    test('Deterministic output: same input produces identical output', () {
      final inputPath = 'test/ui/theme/fixtures/test_tokens.css';
      final outputPath1 = '${tempDir.path}/dayz_tokens_1.g.dart';
      final outputPath2 = '${tempDir.path}/dayz_tokens_2.g.dart';
      
      generateTokens(inputPath, outputPath1);
      generateTokens(inputPath, outputPath2);
      
      final content1 = File(outputPath1).readAsStringSync();
      final content2 = File(outputPath2).readAsStringSync();
      
      expect(content1, content2);
    });
  });
}
