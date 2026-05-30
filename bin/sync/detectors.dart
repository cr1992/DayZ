// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Deterministic R5 detectors for design-sync automation.

enum GeometryKind {
  fixed,
  content;

  static GeometryKind? parse(String? value) {
    switch (value?.trim()) {
      case 'fixed':
        return GeometryKind.fixed;
      case 'content':
        return GeometryKind.content;
      default:
        return null;
    }
  }
}

class ElementRegistryEntry {
  const ElementRegistryEntry({required this.className, this.geometry});

  final String className;
  final GeometryKind? geometry;
}

class ValueSetDiff {
  const ValueSetDiff({required this.added, required this.removed});

  final Set<String> added;
  final Set<String> removed;

  bool get isEmpty => added.isEmpty && removed.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class DomSequenceDiff {
  const DomSequenceDiff({required this.before, required this.after});

  final List<String> before;
  final List<String> after;

  bool get isEmpty => _listEquals(before, after);
  bool get isNotEmpty => !isEmpty;
}

class SubstantiveChangeResult {
  const SubstantiveChangeResult({
    required this.unmappedClasses,
    required this.dataWhenDiff,
    required this.domSequenceDiff,
  });

  final Set<String> unmappedClasses;
  final ValueSetDiff dataWhenDiff;
  final DomSequenceDiff domSequenceDiff;

  bool get hasSubstantiveChanges =>
      unmappedClasses.isNotEmpty ||
      dataWhenDiff.isNotEmpty ||
      domSequenceDiff.isNotEmpty;
}

Set<String> extractClassNames(String html) {
  final classes = <String>{};
  for (final match in _attributeMatches(html, 'class')) {
    classes.addAll(
      match
          .split(RegExp(r'\s+'))
          .map(normalizeClassName)
          .where((className) => className.isNotEmpty),
    );
  }
  return Set<String>.unmodifiable(_sorted(classes));
}

Set<String> extractDataWhenValues(String html) {
  final values = <String>{};
  for (final value in _attributeMatches(html, 'data-when')) {
    final separator = value.contains(',') ? RegExp(r'\s*,\s*') : RegExp(r'\s+');
    values.addAll(
      value
          .split(separator)
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty),
    );
  }
  return Set<String>.unmodifiable(_sorted(values));
}

Set<String> detectUnmappedClasses({
  required Set<String> extractedClasses,
  required Iterable<ElementRegistryEntry> registry,
  Set<String> ignoreClasses = const <String>{},
}) {
  final extracted = _normalizeClassSet(extractedClasses);
  final ignored = _normalizeClassSet(ignoreClasses);
  final mapped = <String>{};
  final missingGeometry = <String>{};

  for (final entry in registry) {
    final className = normalizeClassName(entry.className);
    if (className.isEmpty) continue;

    if (entry.geometry == null) {
      missingGeometry.add(className);
    } else {
      mapped.add(className);
    }
  }

  final unmapped = <String>{
    ...extracted.difference(mapped).difference(ignored),
    ...missingGeometry.intersection(extracted).difference(ignored),
  };
  return Set<String>.unmodifiable(_sorted(unmapped));
}

Set<String> detectUnmappedClassesFromDom({
  required String html,
  required Iterable<ElementRegistryEntry> registry,
  Set<String> ignoreClasses = const <String>{},
}) {
  return detectUnmappedClasses(
    extractedClasses: extractClassNames(html),
    registry: registry,
    ignoreClasses: ignoreClasses,
  );
}

ValueSetDiff diffDataWhenValues({
  required Set<String> before,
  required Set<String> after,
}) {
  final beforeValues = before
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty);
  final afterValues = after
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty);
  final beforeSet = Set<String>.of(beforeValues);
  final afterSet = Set<String>.of(afterValues);

  return ValueSetDiff(
    added: Set<String>.unmodifiable(_sorted(afterSet.difference(beforeSet))),
    removed: Set<String>.unmodifiable(_sorted(beforeSet.difference(afterSet))),
  );
}

ValueSetDiff detectDataWhenDiff({
  required String beforeHtml,
  required String afterHtml,
}) {
  return diffDataWhenValues(
    before: extractDataWhenValues(beforeHtml),
    after: extractDataWhenValues(afterHtml),
  );
}

List<String> normalizedDomChildSequence(
  String html, {
  Set<String> ignoreClasses = const <String>{},
}) {
  final root = _parseDom(html);
  final ignored = _normalizeClassSet(ignoreClasses);
  final sequence = <String>[];

  for (final child in root.children) {
    _appendNodeSequence(child, sequence, ignored);
  }

  return List<String>.unmodifiable(sequence);
}

DomSequenceDiff detectDomChildSequenceDiff({
  required String beforeHtml,
  required String afterHtml,
  Set<String> ignoreClasses = const <String>{},
}) {
  return DomSequenceDiff(
    before: normalizedDomChildSequence(
      beforeHtml,
      ignoreClasses: ignoreClasses,
    ),
    after: normalizedDomChildSequence(afterHtml, ignoreClasses: ignoreClasses),
  );
}

SubstantiveChangeResult detectSubstantiveChanges({
  required String beforeHtml,
  required String afterHtml,
  required Iterable<ElementRegistryEntry> registry,
  Set<String> ignoreClasses = const <String>{},
}) {
  return SubstantiveChangeResult(
    unmappedClasses: detectUnmappedClassesFromDom(
      html: afterHtml,
      registry: registry,
      ignoreClasses: ignoreClasses,
    ),
    dataWhenDiff: detectDataWhenDiff(
      beforeHtml: beforeHtml,
      afterHtml: afterHtml,
    ),
    domSequenceDiff: detectDomChildSequenceDiff(
      beforeHtml: beforeHtml,
      afterHtml: afterHtml,
      ignoreClasses: ignoreClasses,
    ),
  );
}

String normalizeClassName(String className) {
  var normalized = className.trim();
  while (normalized.startsWith('.')) {
    normalized = normalized.substring(1);
  }
  return normalized;
}

Iterable<String> _attributeMatches(String html, String attributeName) sync* {
  final safeName = RegExp.escape(attributeName);
  final pattern = RegExp(
    '(?:^|[\\s<])$safeName\\s*=\\s*'
    '("([^"]*)"|\\\'([^\\\']*)\\\'|([^\\s"\\\'=<>`]+))',
    caseSensitive: false,
  );

  for (final match in pattern.allMatches(html)) {
    yield match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
  }
}

Set<String> _normalizeClassSet(Iterable<String> classes) {
  return classes
      .map(normalizeClassName)
      .where((className) => className.isNotEmpty)
      .toSet();
}

List<String> _sorted(Iterable<String> values) {
  return values.toList()..sort();
}

_DomNode _parseDom(String html) {
  final root = _DomNode('root');
  final stack = <_DomNode>[root];
  final cleanHtml = _removeIgnoredHtmlBlocks(html);
  final tagPattern = RegExp(
    r'<\s*(/)?\s*([A-Za-z][A-Za-z0-9:_-]*)([^>]*)>',
    multiLine: true,
  );

  for (final match in tagPattern.allMatches(cleanHtml)) {
    final isClosing = match.group(1) != null;
    final tag = (match.group(2) ?? '').toLowerCase();
    final attrs = match.group(3) ?? '';

    if (tag.isEmpty || tag.startsWith('!')) continue;

    if (isClosing) {
      _closeNode(stack, tag);
      continue;
    }

    final node = _DomNode(tag, classes: _classesFromAttributes(attrs));
    stack.last.children.add(node);

    final isSelfClosing =
        attrs.trimRight().endsWith('/') || _voidTags.contains(tag);
    if (!isSelfClosing) {
      stack.add(node);
    }
  }

  return root;
}

String _removeIgnoredHtmlBlocks(String html) {
  var result = html.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  result = result.replaceAll(
    RegExp(r'<script\b[\s\S]*?</script\s*>', caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(r'<style\b[\s\S]*?</style\s*>', caseSensitive: false),
    '',
  );
  return result;
}

Set<String> _classesFromAttributes(String attrs) {
  final match = RegExp(
    "\\bclass\\s*=\\s*(\"([^\"]*)\"|'([^']*)'|([^\\s\"'=<>`]+))",
    caseSensitive: false,
  ).firstMatch(attrs);
  if (match == null) return const <String>{};

  final value = match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
  return value
      .split(RegExp(r'\s+'))
      .map(normalizeClassName)
      .where((className) => className.isNotEmpty)
      .toSet();
}

void _closeNode(List<_DomNode> stack, String tag) {
  for (var index = stack.length - 1; index > 0; index -= 1) {
    if (stack[index].tag == tag) {
      stack.removeRange(index, stack.length);
      return;
    }
  }
}

void _appendNodeSequence(
  _DomNode node,
  List<String> sequence,
  Set<String> ignoreClasses,
) {
  final visibleClasses = node.classes.difference(ignoreClasses);
  final isIgnoredWrapper = node.classes.intersection(ignoreClasses).isNotEmpty;

  if (!isIgnoredWrapper) {
    sequence.add(_nodeLabel(node.tag, visibleClasses));
  }

  for (final child in node.children) {
    _appendNodeSequence(child, sequence, ignoreClasses);
  }

  if (!isIgnoredWrapper) {
    sequence.add('/${_nodeLabel(node.tag, visibleClasses)}');
  }
}

String _nodeLabel(String tag, Set<String> classes) {
  if (classes.isEmpty) return tag;

  final classList = _sorted(classes).join('.');
  return '$tag.$classList';
}

bool _listEquals(List<String> left, List<String> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;

  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

class _DomNode {
  _DomNode(this.tag, {Set<String>? classes}) : classes = classes ?? <String>{};

  final String tag;
  final Set<String> classes;
  final List<_DomNode> children = <_DomNode>[];
}

const _voidTags = <String>{
  'area',
  'base',
  'br',
  'col',
  'embed',
  'hr',
  'img',
  'input',
  'link',
  'meta',
  'param',
  'source',
  'track',
  'wbr',
};
