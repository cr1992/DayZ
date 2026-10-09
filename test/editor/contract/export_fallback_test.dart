// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/blocks/callout_block.dart';
import 'package:dayz/editor/contract/blocks/location_block.dart';
import 'package:dayz/editor/contract/blocks/weather_block.dart';
import 'package:dayz/editor/contract/export_fallback.dart';
import 'package:dayz/editor/contract/plain_text_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'export fallback lines stay byte-identical to plain text extraction',
    () {
      final nodes = <Node>[
        Node(
          type: ParagraphBlockKeys.type,
          attributes: {
            ParagraphBlockKeys.delta: [
              {'insert': '段落'},
            ],
          },
        ),
        Node(
          type: HeadingBlockKeys.type,
          attributes: {
            HeadingBlockKeys.level: 1,
            HeadingBlockKeys.delta: [
              {'insert': '标题'},
            ],
          },
        ),
        Node(
          type: BulletedListBlockKeys.type,
          attributes: {
            BulletedListBlockKeys.delta: [
              {'insert': '无序'},
            ],
          },
        ),
        Node(
          type: NumberedListBlockKeys.type,
          attributes: {
            NumberedListBlockKeys.delta: [
              {'insert': '有序'},
            ],
          },
        ),
        Node(
          type: TodoListBlockKeys.type,
          attributes: {
            TodoListBlockKeys.checked: true,
            TodoListBlockKeys.delta: [
              {'insert': '待办'},
            ],
          },
        ),
        Node(
          type: QuoteBlockKeys.type,
          attributes: {
            QuoteBlockKeys.delta: [
              {'insert': '引用'},
            ],
          },
        ),
        dividerNode(),
        imageNode(url: EditorImageReference.urlForMediaId('media-1')),
        calloutNode(text: '标注'),
        locationNode(placeName: '上海', lat: 31.2304, lng: 121.4737),
        weatherNode(weatherCode: '晴', weatherTemp: 18),
      ];

      for (final node in nodes) {
        expect(
          EditorExportFallback.fallbackLineForNode(node),
          EditorPlainTextExtractor.lineForNode(node),
        );
      }
    },
  );

  test('callout falls back to plain text and markdown quote syntax', () {
    final node = calloutNode(text: '记得复盘');

    expect(EditorExportFallback.fallbackLineForNode(node), '记得复盘');
    expect(
      EditorExportFallback.fallbackLineForNode(
        node,
        format: EditorExportFallbackFormat.markdown,
      ),
      '> 记得复盘',
    );
  });

  test(
    'plain text extraction includes callout text without markdown prefix',
    () {
      final document = Document(
        root: pageNode(children: [calloutNode(text: '记得复盘')]),
      );

      expect(EditorPlainTextExtractor.extract(document), '记得复盘');
    },
  );

  test('empty callout delta degrades to an empty line without throwing', () {
    final node = calloutNode();
    final document = Document(root: pageNode(children: [node]));

    expect(EditorExportFallback.fallbackLineForNode(node), '');
    expect(
      EditorExportFallback.fallbackLineForNode(
        node,
        format: EditorExportFallbackFormat.markdown,
      ),
      '',
    );
    expect(EditorPlainTextExtractor.extract(document), '');
  });
}
