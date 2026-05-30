// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:io';

const defaultDesignScreenIds = <String>[
  'timeline',
  'reader',
  'editor',
  'onthisday',
  'search',
  'settings',
];

class DesignRouteResult {
  const DesignRouteResult({
    required this.tokenChanged,
    required this.screenIds,
    required this.uiKitComponentsChanged,
  });

  final bool tokenChanged;
  final Set<String> screenIds;
  final bool uiKitComponentsChanged;

  bool get hasWork =>
      tokenChanged || screenIds.isNotEmpty || uiKitComponentsChanged;

  Map<String, Object> toJson() => <String, Object>{
    'tokenChanged': tokenChanged,
    'screenIds': (screenIds.toList()..sort()),
    'uiKitComponentsChanged': uiKitComponentsChanged,
  };

  @override
  bool operator ==(Object other) {
    return other is DesignRouteResult &&
        tokenChanged == other.tokenChanged &&
        uiKitComponentsChanged == other.uiKitComponentsChanged &&
        _setEquals(screenIds, other.screenIds);
  }

  @override
  int get hashCode => Object.hash(
    tokenChanged,
    uiKitComponentsChanged,
    Object.hashAll(screenIds.toList()..sort()),
  );
}

DesignRouteResult routeDesignChanges(
  Iterable<String> changedFiles, {
  Iterable<String> allScreenIds = defaultDesignScreenIds,
}) {
  var tokenChanged = false;
  var uiKitComponentsChanged = false;
  final routedScreens = <String>{};
  final allScreens = allScreenIds.toSet();

  for (final rawPath in changedFiles) {
    final path = normalizeDesignPath(rawPath);

    if (_isTokenPath(path)) {
      tokenChanged = true;
    }

    final screenId = _screenIdFromPath(path);
    if (screenId != null) {
      routedScreens.add(screenId);
    }

    if (_isSharedScreenAsset(path)) {
      routedScreens.addAll(allScreens);
    }

    if (_isTimelineAsset(path)) {
      routedScreens.add('timeline');
    }

    if (_isDesignRefPath(path)) {
      uiKitComponentsChanged = true;
    }
  }

  return DesignRouteResult(
    tokenChanged: tokenChanged,
    screenIds: routedScreens,
    uiKitComponentsChanged: uiKitComponentsChanged,
  );
}

List<String> changedFilesFromUnifiedDiff(String diffText) {
  final files = <String>[];
  final diffHeader = RegExp(r'^diff --git a/(.+?) b/(.+)$');
  for (final line in const LineSplitter().convert(diffText)) {
    final match = diffHeader.firstMatch(line);
    if (match != null) {
      files.add(match.group(2)!);
    }
  }
  return files;
}

String normalizeDesignPath(String path) {
  var normalized = path.replaceAll(r'\', '/');
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  const prefix = 'ui-design/current/';
  if (normalized.startsWith(prefix)) {
    normalized = normalized.substring(prefix.length);
  }
  return normalized;
}

bool _isTokenPath(String path) {
  return path == 'design-system/assets/tokens.css' ||
      path == 'pages/assets/tokens.css' ||
      path == 'prototype-kit/assets/tokens.css';
}

String? _screenIdFromPath(String path) {
  final match = RegExp(r'^pages/screens/([^/_][^/]*)\.html$').firstMatch(path);
  return match?.group(1);
}

bool _isSharedScreenAsset(String path) {
  return path == 'pages/assets/screen.css' || path == 'pages/assets/screen.js';
}

bool _isTimelineAsset(String path) {
  return path == 'pages/assets/timeline.css' ||
      path == 'pages/assets/timeline.js';
}

bool _isDesignRefPath(String path) {
  return path == 'docs/DESIGN-REF.md';
}

bool _setEquals(Set<Object?> a, Set<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  return a.containsAll(b);
}

void main(List<String> args) {
  final result = routeDesignChanges(args);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result.toJson()));
}
