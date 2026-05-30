// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/export_fallback.dart';

abstract final class EditorPlainTextExtractor {
  static const Set<String> supportedTypes = EditorBlockTypes.supported;

  static String extract(Document document) {
    final lines = <String>[];
    for (final node in document.root.children) {
      _appendNode(node, lines);
    }
    return lines.join('\n');
  }

  static String extractTitle(Document document) {
    final plainText = extract(document);
    if (plainText.isEmpty) {
      return '';
    }
    return plainText.split('\n').first;
  }

  static String? lineForNode(Node node, {int? orderedListIndex}) {
    return EditorExportFallback.fallbackLineForNode(
      node,
      orderedListIndex: orderedListIndex ?? _orderedListIndex(node),
    );
  }

  static void _appendNode(Node node, List<String> lines) {
    final line = lineForNode(node);
    if (line != null) {
      lines.add(line);
    }

    for (final child in node.children) {
      _appendNode(child, lines);
    }
  }

  static int _orderedListIndex(Node node) {
    if (node.type != EditorBlockTypes.numberedList) {
      return 1;
    }
    final siblings = node.parent?.children ?? const <Node>[];
    var index = 0;
    for (final sibling in siblings) {
      if (sibling.type == EditorBlockTypes.numberedList) {
        index += 1;
      }
      if (identical(sibling, node)) {
        return index == 0 ? 1 : index;
      }
    }
    return 1;
  }
}
