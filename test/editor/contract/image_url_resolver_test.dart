// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/image_url_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('ImageUrlResolver', () {
    test('resolves media.id references to runtime paths', () {
      final resolver = ImageUrlResolver(
        mediaPathResolver: (mediaId) => switch (mediaId) {
          'media-1' => '/mock/runtime/media-1.bin',
          _ => null,
        },
      );
      final node = imageNode(
        url: EditorImageReference.urlForMediaId('media-1'),
        width: 200,
        height: 120,
      );

      expect(resolver.mediaIdFromNode(node), 'media-1');
      expect(resolver.resolveNodeUrl(node), '/mock/runtime/media-1.bin');
    });

    test('passes through non-dayz urls unchanged', () {
      final resolver = ImageUrlResolver.unresolved();
      final node = imageNode(url: 'https://example.com/demo.png');

      expect(resolver.mediaIdFromNode(node), isNull);
      expect(resolver.resolveNodeUrl(node), 'https://example.com/demo.png');
    });

    testWidgets('shows placeholder when media reference cannot be resolved', (
      tester,
    ) async {
      final editorState = EditorState(
        document: Document(
          root: pageNode(
            children: [
              imageNode(
                url: EditorImageReference.urlForMediaId('missing-id'),
                width: 180,
                height: 100,
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFlowyEditor(
              editorState: editorState,
              blockComponentBuilders: {
                ...standardBlockComponentBuilderMap,
                ImageBlockKeys.type:
                    ResolvedImageBlockComponentBuilder.editable(
                      imageUrlResolver: ImageUrlResolver.unresolved(),
                    ),
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('[图片不可用: missing-id]'), findsOneWidget);
    });
  });
}
