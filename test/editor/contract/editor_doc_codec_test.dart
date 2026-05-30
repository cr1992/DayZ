// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorDocCodec', () {
    test('encode writes docVersion 1 and round-trips document losslessly', () {
      final original = Document(
        root: pageNode(
          children: [
            Node(
              type: ParagraphBlockKeys.type,
              attributes: {
                ParagraphBlockKeys.delta: [
                  {'insert': 'Hello DayZ'},
                ],
              },
            ),
            Node(
              type: ImageBlockKeys.type,
              attributes: {
                ImageBlockKeys.url: 'dayz-media://media-1',
                ImageBlockKeys.width: 320.0,
                ImageBlockKeys.height: 180.0,
                ImageBlockKeys.align: 'center',
                'custom_passthrough': 'ok',
              },
            ),
            Node(
              type: 'location',
              attributes: {'place_name': '上海', 'lat': 31.2304, 'lng': 121.4737},
            ),
          ],
        ),
      );

      final encoded = EditorDocCodec.encode(original);
      final payload = jsonDecode(encoded) as Map<String, dynamic>;
      final decoded = EditorDocCodec.decode(encoded);

      expect(payload['docVersion'], EditorDocCodec.currentDocVersion);
      expect(decoded.version, EditorDocCodec.currentDocVersion);
      expect(decoded.document.toJson(), equals(original.toJson()));
    });

    test('decode tolerates legacy payload without docVersion', () {
      final legacyPayload = jsonEncode({
        'document': {
          'type': 'page',
          'children': [
            {
              'type': 'paragraph',
              'data': {
                'delta': [
                  {'insert': 'Legacy'},
                ],
              },
            },
          ],
        },
      });

      final decoded = EditorDocCodec.decode(legacyPayload);

      expect(decoded.version, EditorDocCodec.currentDocVersion);
      expect(decoded.document.first?.delta?.toPlainText(), 'Legacy');
    });

    test('decode rejects non-integer docVersion explicitly', () {
      final invalidPayload = jsonEncode({
        'docVersion': '1',
        'document': {'type': 'page', 'children': []},
      });

      expect(
        () => EditorDocCodec.decode(invalidPayload),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode rejects unsupported docVersion explicitly', () {
      final invalidPayload = jsonEncode({
        'docVersion': 2,
        'document': {'type': 'page', 'children': []},
      });

      expect(
        () => EditorDocCodec.decode(invalidPayload),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
