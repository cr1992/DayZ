// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/editor/contract/export_fallback.dart';
import 'package:dayz/editor/contract/plain_text_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'block inventory stays aligned across archived contract, active extensions, and runtime registries',
    () {
      final designTypes = {
        ..._readTypesFromArchivedContractDesign(),
        ..._activeEditorRichBlockExtensions(),
      };
      final runtimeTypes = EditorBlockRegistry.contentTypesOf(
        EditorBlockRegistry.readonlyBuilders(),
      );

      expect(EditorBlockTypes.supported, equals(designTypes));
      expect(EditorPlainTextExtractor.supportedTypes, equals(designTypes));
      expect(EditorExportFallback.supportedTypes, equals(designTypes));
      expect(runtimeTypes, equals(designTypes));
    },
  );
}

Set<String> _readTypesFromArchivedContractDesign() {
  final design = File(
    'specs/archive/2026-05-30-editor-json-contract/design.md',
  ).readAsLinesSync();
  final types = <String>{};
  final typeRegex = RegExp(r'`([^`]+)`');

  for (final line in design) {
    if (!line.startsWith('|')) {
      continue;
    }
    final columns = line.split('|');
    if (columns.length < 3) {
      continue;
    }
    final typeColumn = columns[2].trim();
    final match = typeRegex.firstMatch(typeColumn);
    final type = match?.group(1);
    if (type == null || type.isEmpty || type == '—') {
      continue;
    }
    if (type.startsWith('dayz-media://')) {
      continue;
    }
    types.add(type);
  }

  return types;
}

Set<String> _activeEditorRichBlockExtensions() {
  return const {EditorBlockTypes.callout};
}
