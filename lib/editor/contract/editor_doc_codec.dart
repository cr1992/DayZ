// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';

import 'plain_text_extractor.dart';

abstract final class EditorDocCodec {
  static const int currentDocVersion = 1;

  static String encode(Document document) {
    final payload = document.toJson();
    return jsonEncode({
      'docVersion': currentDocVersion,
      'document': payload['document'],
    });
  }

  static ({int version, Document document}) decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException(
        'Editor document payload must be a JSON object.',
      );
    }

    final payload = Map<String, dynamic>.from(decoded);
    final documentPayload = payload['document'];
    if (documentPayload is! Map) {
      throw const FormatException(
        'Editor document payload is missing a valid document node.',
      );
    }

    final version = _decodeDocVersion(payload['docVersion']);
    if (version != currentDocVersion) {
      throw FormatException('Unsupported editor docVersion: $version');
    }

    return (
      version: version,
      document: Document.fromJson({
        'document': Map<String, dynamic>.from(documentPayload),
      }),
    );
  }

  static int _decodeDocVersion(dynamic rawVersion) {
    if (rawVersion == null) {
      return currentDocVersion;
    }
    if (rawVersion is int) {
      return rawVersion;
    }
    throw FormatException(
      'Editor docVersion must be an integer when present, got: $rawVersion',
    );
  }

  static String extractPlainText(Document document) {
    return EditorPlainTextExtractor.extract(document);
  }
}
