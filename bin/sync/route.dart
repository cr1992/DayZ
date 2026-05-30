// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:io';

/// Phase 1 deterministic routing for design-sync automation.
const phase1DefaultScreenIds = <String>[
  'timeline',
  'reader',
  'editor',
  'onthisday',
  'search',
  'settings',
];

/// One changed design file plus optional section metadata.
///
/// `DESIGN-REF.md` only routes to ui-kit when the changed sections include
/// section 3, so callers that know hunk headings should preserve them here.
class DesignDiffEntry {
  const DesignDiffEntry(this.path, {this.changedSections = const <String>{}});

  factory DesignDiffEntry.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'Diff entry must not be empty.');
    }

    var path = trimmed;
    var sectionPart = '';

    final hashIndex = trimmed.indexOf('#');
    if (hashIndex >= 0) {
      path = trimmed.substring(0, hashIndex).trim();
      sectionPart = trimmed.substring(hashIndex + 1);
    } else {
      final sectionMatch = RegExp(
        r'\s+§\s*([0-9][0-9A-Za-z._-]*)',
      ).firstMatch(trimmed);
      if (sectionMatch != null) {
        path = trimmed.substring(0, sectionMatch.start).trim();
        sectionPart = sectionMatch.group(1) ?? '';
      }
    }

    return DesignDiffEntry(
      path,
      changedSections: _parseSectionList(sectionPart),
    );
  }

  final String path;
  final Set<String> changedSections;
}

/// Deterministic affected areas produced by Phase 1.
class DesignRouteResult {
  const DesignRouteResult({
    required this.requiresTokenRegen,
    required this.screenIds,
    required this.components,
  });

  final bool requiresTokenRegen;
  final List<String> screenIds;
  final List<String> components;

  bool get isEmpty =>
      !requiresTokenRegen && screenIds.isEmpty && components.isEmpty;

  Map<String, Object> toJson() => <String, Object>{
    'requiresTokenRegen': requiresTokenRegen,
    'screenIds': screenIds,
    'components': components,
  };

  @override
  String toString() => toJson().toString();
}

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    stdout.writeln('Usage: dart run bin/sync/route.dart [changed-path ...]');
    stdout.writeln(
      '       git diff --name-only -- ui-design/current | '
      'dart run bin/sync/route.dart --from-git-diff ui-design/current',
    );
    return;
  }

  final pathArgs = <String>[];
  var skipNext = false;
  for (var index = 0; index < args.length; index += 1) {
    if (skipNext) {
      skipNext = false;
      continue;
    }

    final arg = args[index];
    if (arg == '--from-git-diff') {
      skipNext = index + 1 < args.length;
      continue;
    }
    if (arg.startsWith('--')) {
      continue;
    }
    pathArgs.add(arg);
  }

  final lines = <String>[...pathArgs];
  if (!stdin.hasTerminal) {
    final input = await stdin.transform(utf8.decoder).join();
    lines.addAll(
      const LineSplitter()
          .convert(input)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty),
    );
  }

  final result = routeDesignChanges(lines.map(DesignDiffEntry.parse));
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result.toJson()));
}

/// Routes plain changed paths.
///
/// Use [routeDesignChanges] instead when a `DESIGN-REF.md` hunk section is
/// available; plain paths cannot distinguish section 3 from other sections.
DesignRouteResult routeChangedPaths(
  Iterable<String> paths, {
  List<String> allScreenIds = phase1DefaultScreenIds,
}) {
  return routeDesignChanges(
    paths.map(DesignDiffEntry.new),
    allScreenIds: allScreenIds,
  );
}

/// Routes changed design entries to token regen, affected screens, and ui-kit.
DesignRouteResult routeDesignChanges(
  Iterable<DesignDiffEntry> changes, {
  List<String> allScreenIds = phase1DefaultScreenIds,
}) {
  var requiresTokenRegen = false;
  final screens = <String>{};
  final components = <String>{};

  for (final change in changes) {
    final path = normalizeDesignPath(change.path);

    if (_isTokensCss(path)) {
      requiresTokenRegen = true;
      screens.addAll(allScreenIds);
    }

    final screenId = _screenIdFromPath(path);
    if (screenId != null) {
      screens.add(screenId);
    }

    if (_isSharedScreenAsset(path)) {
      screens.addAll(allScreenIds);
    }

    if (_isTimelineAsset(path)) {
      screens.add('timeline');
    }

    if (_isDesignRef(path) && _containsSection3(change.changedSections)) {
      components.add('ui-kit');
    }
  }

  return DesignRouteResult(
    requiresTokenRegen: requiresTokenRegen,
    screenIds: _orderedScreenIds(screens, allScreenIds),
    components: _sorted(components),
  );
}

String normalizeDesignPath(String path) {
  var normalized = path.trim().replaceAll('\\', '/');
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }

  const marker = 'ui-design/current/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex >= 0) {
    normalized = normalized.substring(markerIndex + marker.length);
  }

  if (normalized.startsWith('current/')) {
    normalized = normalized.substring('current/'.length);
  }

  while (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }
  return normalized;
}

bool _isTokensCss(String path) {
  return path == 'design-system/assets/tokens.css' ||
      path == 'pages/assets/tokens.css' ||
      path.endsWith('/tokens.css');
}

String? _screenIdFromPath(String path) {
  final match = RegExp(
    r'(^|/)pages/screens/([A-Za-z0-9_-]+)\.html$',
  ).firstMatch(path);
  if (match == null) return null;

  final id = match.group(2)!;
  if (id.startsWith('_')) return null;
  return id;
}

bool _isSharedScreenAsset(String path) {
  return path == 'pages/assets/screen.css' || path == 'pages/assets/screen.js';
}

bool _isTimelineAsset(String path) {
  return path == 'pages/assets/timeline.css' ||
      path == 'pages/assets/timeline.js';
}

bool _isDesignRef(String path) {
  return path == 'docs/DESIGN-REF.md' || path.endsWith('/docs/DESIGN-REF.md');
}

bool _containsSection3(Set<String> sections) {
  return sections.map(_normalizeSection).any((section) {
    return section == '3' ||
        section.startsWith('3.') ||
        section.startsWith('3b') ||
        section.startsWith('3c');
  });
}

Set<String> _parseSectionList(String raw) {
  if (raw.trim().isEmpty) return const <String>{};

  return raw
      .split(RegExp(r'[,;\s]+'))
      .map(_normalizeSection)
      .where((section) => section.isNotEmpty)
      .toSet();
}

String _normalizeSection(String section) {
  var normalized = section.trim().toLowerCase();
  normalized = normalized.replaceFirst(RegExp(r'^section[-_:]*'), '');
  normalized = normalized.replaceFirst(RegExp(r'^§\s*'), '');
  return normalized;
}

List<String> _orderedScreenIds(Set<String> screenIds, List<String> order) {
  final result = <String>[];
  for (final id in order) {
    if (screenIds.contains(id)) {
      result.add(id);
    }
  }

  final remaining = screenIds.where((id) => !order.contains(id)).toList()
    ..sort();
  result.addAll(remaining);
  return List<String>.unmodifiable(result);
}

List<String> _sorted(Set<String> values) {
  final result = values.toList()..sort();
  return List<String>.unmodifiable(result);
}
