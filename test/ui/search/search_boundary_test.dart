// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 解析一个 Dart 源文件的 import 指令 URI（只看依赖关系，不看业务文本）。
List<String> importsOf(String path) {
  final pattern = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');
  return [
    for (final line in File(path).readAsLinesSync())
      if (pattern.firstMatch(line) case final match?) match.group(1)!,
  ];
}

bool touchesData(String uri) =>
    uri.startsWith('package:drift') ||
    uri.startsWith('package:dayz/data/') ||
    uri.contains('/data/');

void main() {
  const screenSide = [
    'lib/ui/search/search_page.dart',
    'lib/ui/search/search_controller.dart',
    'lib/ui/search/search_state.dart',
    'lib/ui/search/search_highlight.dart',
  ];

  test('screen / controller / state / highlight never import Drift or the '
      'data layer (NF2)', () {
    for (final path in screenSide) {
      final offending = importsOf(path).where(touchesData).toList();
      expect(offending, isEmpty, reason: path);
    }
  });

  test('only the adapter touches Repository public API — no Drift, no '
      'database handle (NF2)', () {
    final imports = importsOf('lib/ui/search/search_source.dart');
    final dataImports = imports.where(touchesData).toList();
    expect(dataImports, isNotEmpty);
    for (final uri in dataImports) {
      expect(
        uri.startsWith('package:dayz/data/repositories/'),
        isTrue,
        reason: uri,
      );
    }
    expect(imports.where((uri) => uri.startsWith('package:drift')), isEmpty);
    expect(imports.where((uri) => uri.endsWith('database.dart')), isEmpty);
  });

  test('every Dart file under lib/ui/search is covered by the boundary', () {
    final files = Directory('lib/ui/search')
        .listSync()
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('.dart'))
        .toSet();
    expect(files, {...screenSide, 'lib/ui/search/search_source.dart'});
  });
}
