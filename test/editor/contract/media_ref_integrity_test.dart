// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encoded editor docs keep image references path-free', () {
    final document = Document(
      root: pageNode(
        children: [
          imageNode(
            url: EditorImageReference.urlForMediaId('media-1'),
            width: 320,
            height: 180,
          ),
        ],
      ),
    );

    final encoded = EditorDocCodec.encode(document);

    expect(encoded, contains('dayz-media://media-1'));
    expect(encoded, isNot(contains('/var/mobile')));
    expect(encoded, isNot(contains('/data/data')));
    expect(encoded, isNot(contains('media-1.bin')));
    expect(encoded, isNot(contains('<app_documents>')));
  });
}
