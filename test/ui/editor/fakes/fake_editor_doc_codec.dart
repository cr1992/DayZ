// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/plain_text_extractor.dart';

class FakeEditorDocCodec {
  static const int currentDocVersion = 1;

  final List<Document> encodedDocuments = <Document>[];
  final List<String> decodedSources = <String>[];

  String encode(Document document) {
    encodedDocuments.add(document);
    final payload = document.toJson();
    return jsonEncode({
      'docVersion': currentDocVersion,
      'document': payload['document'],
    });
  }

  ({int version, Document document}) decode(String source) {
    decodedSources.add(source);
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return (
      version: decoded['docVersion'] as int? ?? currentDocVersion,
      document: Document.fromJson({
        'document': Map<String, dynamic>.from(decoded['document'] as Map),
      }),
    );
  }

  String extractPlainText(Document document) {
    return EditorPlainTextExtractor.extract(document);
  }
}
