// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:io';

class ElementMapEntry {
  const ElementMapEntry({required this.cssClass, this.key, this.geometry});

  final String cssClass;
  final String? key;
  final String? geometry;

  String get normalizedClass => normalizeClassName(cssClass);

  bool get hasValidGeometry => geometry == 'fixed' || geometry == 'content';
}

class SubstantialChangeResult {
  const SubstantialChangeResult({
    required this.unmappedClasses,
    required this.missingGeometryClasses,
    required this.newDataWhenValues,
    required this.removedDataWhenValues,
    required this.domOrderChanged,
  });

  final Set<String> unmappedClasses;
  final Set<String> missingGeometryClasses;
  final Set<String> newDataWhenValues;
  final Set<String> removedDataWhenValues;
  final bool domOrderChanged;

  bool get hasSubstantialChange =>
      unmappedClasses.isNotEmpty ||
      newDataWhenValues.isNotEmpty ||
      removedDataWhenValues.isNotEmpty ||
      domOrderChanged;

  Map<String, Object> toJson() => <String, Object>{
    'unmappedClasses': _sorted(unmappedClasses),
    'missingGeometryClasses': _sorted(missingGeometryClasses),
    'newDataWhenValues': _sorted(newDataWhenValues),
    'removedDataWhenValues': _sorted(removedDataWhenValues),
    'domOrderChanged': domOrderChanged,
    'hasSubstantialChange': hasSubstantialChange,
  };
}

SubstantialChangeResult detectSubstantialChanges({
  required Set<String> extractedClasses,
  required Iterable<ElementMapEntry> registry,
  Set<String> ignoredClasses = const <String>{},
  Set<String> beforeDataWhenValues = const <String>{},
  Set<String> afterDataWhenValues = const <String>{},
  List<String> beforeDomSequence = const <String>[],
  List<String> afterDomSequence = const <String>[],
}) {
  final normalizedExtracted = extractedClasses.map(normalizeClassName).toSet();
  final normalizedIgnored = ignoredClasses.map(normalizeClassName).toSet();
  final normalizedRegistry = <String>{};
  final missingGeometry = <String>{};

  for (final entry in registry) {
    final className = entry.normalizedClass;
    normalizedRegistry.add(className);
    if (!entry.hasValidGeometry) {
      missingGeometry.add(className);
    }
  }

  final unmapped = normalizedExtracted
      .difference(normalizedRegistry)
      .difference(normalizedIgnored);
  unmapped.addAll(missingGeometry);

  final beforeStates = beforeDataWhenValues.toSet();
  final afterStates = afterDataWhenValues.toSet();

  return SubstantialChangeResult(
    unmappedClasses: unmapped,
    missingGeometryClasses: missingGeometry,
    newDataWhenValues: afterStates.difference(beforeStates),
    removedDataWhenValues: beforeStates.difference(afterStates),
    domOrderChanged: !_listEquals(beforeDomSequence, afterDomSequence),
  );
}

Set<String> extractClassesFromHtml(String html) {
  final classes = <String>{};
  final attrPattern = RegExp(
    r'''\bclass\s*=\s*(["'])(.*?)\1''',
    multiLine: true,
    dotAll: true,
  );

  for (final match in attrPattern.allMatches(html)) {
    final value = match.group(2)!;
    for (final className in value.split(RegExp(r'\s+'))) {
      final normalized = normalizeClassName(className);
      if (normalized.isNotEmpty) {
        classes.add(normalized);
      }
    }
  }

  return classes;
}

Set<String> extractDataWhenValues(String html) {
  final values = <String>{};
  final attrPattern = RegExp(
    r'''\bdata-when\s*=\s*(["'])(.*?)\1''',
    multiLine: true,
    dotAll: true,
  );

  for (final match in attrPattern.allMatches(html)) {
    final value = match.group(2)!.trim();
    if (value.isNotEmpty) {
      values.add(value);
    }
  }

  return values;
}

List<String> normalizedDomChildSequence(String html) {
  final sequence = <String>[];
  final tagPattern = RegExp(r'''<([a-zA-Z][\w:-]*)(\s[^<>]*)?>''');
  final classPattern = RegExp(r'''\bclass\s*=\s*(["'])(.*?)\1''');
  final dataWhenPattern = RegExp(r'''\bdata-when\s*=\s*(["'])(.*?)\1''');
  final idPattern = RegExp(r'''\bid\s*=\s*(["'])(.*?)\1''');
  const ignoredTags = <String>{
    'html',
    'head',
    'meta',
    'link',
    'script',
    'style',
    'title',
  };

  for (final tagMatch in tagPattern.allMatches(html)) {
    final tag = tagMatch.group(1)!.toLowerCase();
    if (ignoredTags.contains(tag)) {
      continue;
    }

    final attrs = tagMatch.group(2) ?? '';
    final classes = <String>[];
    final classMatch = classPattern.firstMatch(attrs);
    if (classMatch != null) {
      classes.addAll(
        classMatch
            .group(2)!
            .split(RegExp(r'\s+'))
            .map(normalizeClassName)
            .where((className) => className.isNotEmpty),
      );
      classes.sort();
    }

    final id = idPattern.firstMatch(attrs)?.group(2)?.trim();
    final dataWhen = dataWhenPattern.firstMatch(attrs)?.group(2)?.trim();
    final buffer = StringBuffer(tag);
    if (id != null && id.isNotEmpty) {
      buffer.write('#$id');
    }
    if (classes.isNotEmpty) {
      buffer.write('.');
      buffer.write(classes.join('.'));
    }
    if (dataWhen != null && dataWhen.isNotEmpty) {
      buffer.write('[data-when=$dataWhen]');
    }
    sequence.add(buffer.toString());
  }

  return sequence;
}

List<ElementMapEntry> parseElementMapYaml(String content) {
  final entries = <ElementMapEntry>[];
  String? cssClass;
  String? key;
  String? geometry;

  void saveCurrent() {
    if (cssClass != null) {
      entries.add(
        ElementMapEntry(cssClass: cssClass, key: key, geometry: geometry),
      );
    }
  }

  for (var line in const LineSplitter().convert(content)) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    if (line.startsWith('-')) {
      saveCurrent();
      cssClass = null;
      key = null;
      geometry = null;
      line = line.substring(1).trim();
      if (line.isEmpty) {
        continue;
      }
    }

    final colon = line.indexOf(':');
    if (colon == -1) {
      continue;
    }
    final field = line.substring(0, colon).trim();
    final value = _unquote(line.substring(colon + 1).trim());

    switch (field) {
      case 'class':
        cssClass = value;
      case 'key':
        key = value;
      case 'geometry':
        geometry = value;
    }
  }
  saveCurrent();

  return entries;
}

String normalizeClassName(String className) {
  var normalized = className.trim();
  while (normalized.startsWith('.')) {
    normalized = normalized.substring(1);
  }
  return normalized;
}

String _unquote(String value) {
  if (value.length >= 2) {
    final first = value.codeUnitAt(0);
    final last = value.codeUnitAt(value.length - 1);
    if ((first == 0x22 && last == 0x22) || (first == 0x27 && last == 0x27)) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}

List<String> _sorted(Set<String> values) => values.toList()..sort();

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void main(List<String> args) {
  if (args.length != 2 || args.first != 'scan-html') {
    stderr.writeln('Usage: dart run bin/sync/detectors.dart scan-html <html>');
    exitCode = 64;
    return;
  }

  final html = File(args[1]).readAsStringSync();
  final output = <String, Object>{
    'classes': _sorted(extractClassesFromHtml(html)),
    'dataWhenValues': _sorted(extractDataWhenValues(html)),
    'domSequence': normalizedDomChildSequence(html),
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
}
