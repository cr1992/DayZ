// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';

enum EditorExportFallbackFormat { plain, markdown }

abstract final class EditorExportFallback {
  static const Set<String> supportedTypes = EditorBlockTypes.supported;

  static String? fallbackLineForNode(
    Node node, {
    int orderedListIndex = 1,
    EditorExportFallbackFormat format = EditorExportFallbackFormat.plain,
  }) {
    switch (node.type) {
      case EditorBlockTypes.paragraph:
      case EditorBlockTypes.heading:
        return _plainText(node) ?? '';
      case EditorBlockTypes.bulletedList:
        return '• ${_plainText(node) ?? ''}';
      case EditorBlockTypes.numberedList:
        return '$orderedListIndex. ${_plainText(node) ?? ''}';
      case EditorBlockTypes.todoList:
        final checked = node.attributes[TodoListBlockKeys.checked] == true;
        return checked
            ? '[x] ${_plainText(node) ?? ''}'
            : '[ ] ${_plainText(node) ?? ''}';
      case EditorBlockTypes.quote:
        return '> ${_plainText(node) ?? ''}';
      case EditorBlockTypes.divider:
        return '';
      case EditorBlockTypes.image:
        return '[图片]';
      case EditorBlockTypes.callout:
        return _calloutFallback(node, format);
      case EditorBlockTypes.location:
        final placeName = _textValue(
          node.attributes[LocationBlockDataKeys.placeName],
        );
        return placeName == null ? '' : '📍 $placeName';
      case EditorBlockTypes.weather:
        final weatherTemp = _displayValue(
          node.attributes[WeatherBlockDataKeys.weatherTemp],
        );
        if (weatherTemp != null) {
          return '🌤 $weatherTemp°C';
        }
        final weatherCode = _displayValue(
          node.attributes[WeatherBlockDataKeys.weatherCode],
        );
        return weatherCode == null ? '' : '🌤 $weatherCode';
      default:
        return _unknownFallback(node);
    }
  }

  static String _calloutFallback(Node node, EditorExportFallbackFormat format) {
    final text = _plainText(node) ?? '';
    if (format == EditorExportFallbackFormat.markdown && text.isNotEmpty) {
      return '> $text';
    }
    return text;
  }

  static String? _unknownFallback(Node node) {
    final text = _plainText(node)?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static String? _plainText(Node node) {
    return node.delta?.toPlainText();
  }

  static String? _textValue(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static String? _displayValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value % 1 == 0 ? value.toInt().toString() : value.toString();
    }
    return _textValue(value);
  }
}
