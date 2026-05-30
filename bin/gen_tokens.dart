// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' as css;

void main(List<String> args) {
  final inputPath = args.isNotEmpty
      ? args[0]
      : 'ui-design/current/design-system/assets/tokens.css';
  final outputPath = args.length > 1
      ? args[1]
      : 'lib/ui/theme/dayz_tokens.g.dart';

  try {
    generateTokens(inputPath, outputPath);
    print('Tokens generated successfully at $outputPath');
    exit(0);
  } catch (e, stack) {
    stderr.writeln('Error generating tokens: $e');
    stderr.writeln(stack);
    exit(1);
  }
}

class BoxShadowData {
  final double dx;
  final double dy;
  final double blur;
  final double spread;
  final String color;
  BoxShadowData(this.dx, this.dy, this.blur, this.spread, this.color);
}

void generateTokens(String inputCssPath, String outputDartPath) {
  final file = File(inputCssPath);
  if (!file.existsSync()) {
    throw FileSystemException('CSS file not found', inputCssPath);
  }

  final cssContent = file.readAsStringSync();
  final stylesheet = css.parse(cssContent);

  final spacing = <String, double>{};
  final radii = <String, double>{};
  final motion = <String, String>{};
  final fonts = <String, String>{};

  // Maps for mode colors (light/dark)
  final modeColors = <String, Map<String, String>>{
    'light': {},
    'dark': {},
  };

  // Maps for theme colors (purple_light, purple_dark, etc.)
  final themeColors = <String, Map<String, String>>{
    'purple_light': {},
    'purple_dark': {},
    'amber_light': {},
    'amber_dark': {},
    'sage_light': {},
    'sage_dark': {},
  };

  for (final node in stylesheet.topLevels) {
    if (node is css.RuleSet) {
      final selectorGroup = node.selectorGroup;
      if (selectorGroup == null) continue;
      final selectors = selectorGroup.selectors;
      for (final selector in selectors) {
        final span = selector.span;
        if (span == null) continue;
        final selText = span.text.replaceAll(RegExp(r'\s+'), '');
        
        if (selText == ':root') {
          // Parse global constants
          for (final decl in node.declarationGroup.declarations) {
            if (decl is css.Declaration) {
              final prop = decl.property;
              final expr = decl.expression;
              if (expr == null) continue;
              final val = _printNode(expr);
              if (prop.startsWith('--sp-')) {
                final key = 's' + prop.substring(5);
                spacing[key] = _parseLength(val);
              } else if (prop.startsWith('--r-')) {
                final key = _toCamelCase(prop.substring(4));
                radii[key] = _parseLength(val);
              } else if (prop.startsWith('--font-')) {
                final key = _toCamelCase(prop.substring(7));
                fonts[key] = val;
              } else if (prop == '--ease' || prop == '--dur') {
                final key = _toCamelCase(prop.substring(2));
                motion[key] = val;
              }
            }
          }
        } else if (selText.contains('[data-mode="light"]') &&
            !selText.contains('data-theme') &&
            !selText.contains('data-bg')) {
          // Light mode neutral colors & shadows
          _parseDeclarations(node, modeColors['light']!);
        } else if (selText.contains('[data-mode="dark"]') &&
            !selText.contains('data-theme') &&
            !selText.contains('data-bg')) {
          // Dark mode neutral colors & shadows
          _parseDeclarations(node, modeColors['dark']!);
        } else {
          // Check for theme & mode combinations
          for (final theme in ['purple', 'amber', 'sage']) {
            for (final mode in ['light', 'dark']) {
              if (selText.contains('[data-theme="$theme"]') &&
                  selText.contains('[data-mode="$mode"]')) {
                _parseDeclarations(node, themeColors['${theme}_$mode']!);
              }
            }
          }
        }
      }
    }
  }

  // Generate Dart file content
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.');
  buffer.writeln('// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.');
  buffer.writeln();
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln();

  // Spacing
  buffer.writeln('abstract final class DayzSpacing {');
  final sortedSpacing = spacing.keys.toList()..sort((a, b) {
    final numA = int.tryParse(a.substring(1)) ?? 0;
    final numB = int.tryParse(b.substring(1)) ?? 0;
    return numA.compareTo(numB);
  });
  for (final k in sortedSpacing) {
    buffer.writeln('  static const double $k = ${spacing[k]};');
  }
  buffer.writeln('}');
  buffer.writeln();

  // Radii
  buffer.writeln('abstract final class DayzRadii {');
  final sortedRadii = radii.keys.toList()..sort();
  for (final k in sortedRadii) {
    buffer.writeln('  static const double $k = ${radii[k]};');
  }
  buffer.writeln('}');
  buffer.writeln();

  // Motion
  buffer.writeln('abstract final class DayzMotion {');
  final sortedMotion = motion.keys.toList()..sort();
  for (final k in sortedMotion) {
    final val = motion[k]!;
    if (k == 'dur') {
      final ms = _parseDurationMs(val);
      buffer.writeln('  static const Duration dur = Duration(milliseconds: $ms);');
    } else {
      buffer.writeln("  static const String $k = '$val';");
    }
  }
  buffer.writeln('}');
  buffer.writeln();

  // Fonts
  buffer.writeln('abstract final class DayzFonts {');
  final sortedFonts = fonts.keys.toList()..sort();
  for (final k in sortedFonts) {
    buffer.writeln("  static const String $k = '${fonts[k]}';");
  }
  buffer.writeln('}');
  buffer.writeln();

  // Tokens
  buffer.writeln('abstract final class DayzTokens {');

  for (final theme in ['purple', 'amber', 'sage']) {
    for (final mode in ['light', 'dark']) {
      final prefix = _toCamelCase('${theme}-$mode');
      
      // Neutral colors & shadows for this mode
      final neutrals = modeColors[mode]!;
      final sortedNeutrals = neutrals.keys.toList()..sort();
      for (final k in sortedNeutrals) {
        final fieldName = '$prefix${k[0].toUpperCase()}${k.substring(1)}';
        final val = neutrals[k]!;
        if (k.startsWith('shadow')) {
          buffer.writeln('  static const List<BoxShadow> $fieldName = $val;');
        } else {
          buffer.writeln('  static const Color $fieldName = $val;');
        }
      }

      // Theme colors for this combination
      final themes = themeColors['${theme}_$mode']!;
      final sortedThemes = themes.keys.toList()..sort();
      for (final k in sortedThemes) {
        final fieldName = '$prefix${k[0].toUpperCase()}${k.substring(1)}';
        final val = themes[k]!;
        buffer.writeln('  static const Color $fieldName = $val;');
      }
    }
  }

  buffer.writeln('}');

  // Make sure target directory exists
  final outFile = File(outputDartPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(buffer.toString());
}

void _parseDeclarations(css.RuleSet node, Map<String, String> targetMap) {
  for (final decl in node.declarationGroup.declarations) {
    if (decl is css.Declaration) {
      final prop = decl.property;
      final expr = decl.expression;
      if (expr == null) continue;
      final val = _printNode(expr);
      final key = _formatPropertyName(prop);

      if (prop.startsWith('--shadow-')) {
        targetMap[key] = _parseShadows(val);
      } else {
        targetMap[key] = _parseColor(val);
      }
    }
  }
}

double _parseLength(String value) {
  if (value == '0') return 0.0;
  var s = value;
  if (s.endsWith('px')) {
    s = s.substring(0, s.length - 2);
  }
  final val = double.tryParse(s);
  if (val != null) return val;
  throw FormatException('Invalid length value: $value');
}

int _parseDurationMs(String value) {
  var s = value;
  if (s.endsWith('ms')) {
    s = s.substring(0, s.length - 2);
  }
  final val = int.tryParse(s);
  if (val != null) return val;
  throw FormatException('Invalid duration value: $value');
}

String _parseColor(String value) {
  final clean = value.trim();
  if (clean.startsWith('#')) {
    final hex = clean.substring(1);
    if (hex.length == 6) {
      return 'Color(0xFF${hex.toUpperCase()})';
    } else if (hex.length == 3) {
      final r = hex[0];
      final g = hex[1];
      final b = hex[2];
      return 'Color(0xFF$r$r$g$g$b$b)';
    }
  } else if (clean.startsWith('rgba')) {
    final regExp = RegExp(r'rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)');
    final match = regExp.firstMatch(clean);
    if (match != null) {
      final r = int.parse(match.group(1)!);
      final g = int.parse(match.group(2)!);
      final b = int.parse(match.group(3)!);
      final a = double.parse(match.group(4)!);
      final alpha = (a * 255).round();
      final hexR = r.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexG = g.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexB = b.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexA = alpha.toRadixString(16).padLeft(2, '0').toUpperCase();
      return 'Color(0x$hexA$hexR$hexG$hexB)';
    }
  } else if (clean.startsWith('rgb')) {
    final regExp = RegExp(r'rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)');
    final match = regExp.firstMatch(clean);
    if (match != null) {
      final r = int.parse(match.group(1)!);
      final g = int.parse(match.group(2)!);
      final b = int.parse(match.group(3)!);
      final hexR = r.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexG = g.toRadixString(16).padLeft(2, '0').toUpperCase();
      final hexB = b.toRadixString(16).padLeft(2, '0').toUpperCase();
      return 'Color(0xFF$hexR$hexG$hexB)';
    }
  }
  throw FormatException('Invalid color value: $value');
}

String _parseShadows(String value) {
  final layers = _splitByTopLevelComma(value);
  final buffer = StringBuffer('[\n');
  for (final layer in layers) {
    final shadow = _parseSingleShadow(layer);
    buffer.write('    BoxShadow(\n');
    buffer.write('      color: ${shadow.color},\n');
    buffer.write('      offset: Offset(${shadow.dx}, ${shadow.dy}),\n');
    buffer.write('      blurRadius: ${shadow.blur},\n');
    buffer.write('      spreadRadius: ${shadow.spread},\n');
    buffer.write('    ),\n');
  }
  buffer.write('  ]');
  return buffer.toString();
}

List<String> _splitByTopLevelComma(String value) {
  final parts = <String>[];
  var braceCount = 0;
  var currentPart = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char == '(') {
      braceCount++;
      currentPart.write(char);
    } else if (char == ')') {
      braceCount--;
      currentPart.write(char);
    } else if (char == ',' && braceCount == 0) {
      parts.add(currentPart.toString().trim());
      currentPart.clear();
    } else {
      currentPart.write(char);
    }
  }
  if (currentPart.isNotEmpty) {
    parts.add(currentPart.toString().trim());
  }
  return parts;
}

BoxShadowData _parseSingleShadow(String shadowStr) {
  final colorRegExp = RegExp(r'(rgba?\(.*?\)|#[0-9a-fA-F]+)');
  final colorMatch = colorRegExp.firstMatch(shadowStr);
  if (colorMatch == null) {
    throw FormatException('No color found in shadow: $shadowStr');
  }
  final colorStr = colorMatch.group(0)!;
  final cleanShadowStr = shadowStr.replaceFirst(colorStr, '').trim();

  final lengthParts = cleanShadowStr.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  final lengths = lengthParts.map((s) {
    final numStr = s.replaceAll('px', '');
    return double.parse(numStr);
  }).toList();

  double dx = 0;
  double dy = 0;
  double blur = 0;
  double spread = 0;
  if (lengths.isNotEmpty) {
    dx = lengths[0];
  }
  if (lengths.length >= 2) {
    dy = lengths[1];
  }
  if (lengths.length >= 3) {
    blur = lengths[2];
  }
  if (lengths.length >= 4) {
    spread = lengths[3];
  }

  return BoxShadowData(dx, dy, blur, spread, _parseColor(colorStr));
}

String _formatPropertyName(String name) {
  if (name.startsWith('--sp-')) {
    return 's' + name.substring(5);
  }
  if (name.startsWith('--r-')) {
    return name.substring(4);
  }
  return _toCamelCase(name);
}

String _toCamelCase(String prop) {
  var s = prop;
  if (s.startsWith('--')) {
    s = s.substring(2);
  }
  final parts = s.split('-');
  final buffer = StringBuffer(parts[0]);
  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.isNotEmpty) {
      buffer.write(part[0].toUpperCase() + part.substring(1));
    }
  }
  return buffer.toString();
}

String _printNode(css.TreeNode node) {
  final printer = css.CssPrinter();
  node.visit(printer);
  return printer.toString();
}
