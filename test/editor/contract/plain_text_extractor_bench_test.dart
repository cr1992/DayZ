// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/plain_text_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorPlainTextExtractor benchmark', () {
    test('50 blocks average under 5ms', () {
      final document = _buildDocument(blockCount: 50);
      final averageMicroseconds = _measureAverageMicros(
        document: document,
        iterations: 1000,
      );

      expect(averageMicroseconds, lessThan(5000));
    });

    test('1000 blocks average under 50ms', () {
      final document = _buildDocument(blockCount: 1000);
      final averageMicroseconds = _measureAverageMicros(
        document: document,
        iterations: 100,
      );

      expect(averageMicroseconds, lessThan(50000));
    });
  });
}

Document _buildDocument({required int blockCount}) {
  final random = Random(42);
  final children = <Node>[];

  for (var i = 0; i < blockCount; i += 1) {
    final kind = i % 8;
    switch (kind) {
      case 0:
        children.add(
          Node(
            type: ParagraphBlockKeys.type,
            attributes: {
              ParagraphBlockKeys.delta: [
                {'insert': 'Paragraph $i'},
              ],
            },
          ),
        );
      case 1:
        children.add(
          Node(
            type: HeadingBlockKeys.type,
            attributes: {
              HeadingBlockKeys.level: (i % 3) + 1,
              HeadingBlockKeys.delta: [
                {'insert': 'Heading $i'},
              ],
            },
          ),
        );
      case 2:
        children.add(
          Node(
            type: BulletedListBlockKeys.type,
            attributes: {
              BulletedListBlockKeys.delta: [
                {'insert': 'Bullet $i'},
              ],
            },
          ),
        );
      case 3:
        children.add(
          Node(
            type: NumberedListBlockKeys.type,
            attributes: {
              NumberedListBlockKeys.delta: [
                {'insert': 'Number $i'},
              ],
            },
          ),
        );
      case 4:
        children.add(
          Node(
            type: TodoListBlockKeys.type,
            attributes: {
              TodoListBlockKeys.checked: i.isEven,
              TodoListBlockKeys.delta: [
                {'insert': 'Todo $i'},
              ],
            },
          ),
        );
      case 5:
        children.add(
          Node(
            type: QuoteBlockKeys.type,
            attributes: {
              QuoteBlockKeys.delta: [
                {'insert': 'Quote $i'},
              ],
            },
          ),
        );
      case 6:
        children.add(
          imageNode(url: EditorImageReference.urlForMediaId('media-$i')),
        );
      default:
        children.add(
          Node(
            type: random.nextBool()
                ? EditorBlockTypes.location
                : EditorBlockTypes.weather,
            attributes: random.nextBool()
                ? {
                    'place_name': 'Place $i',
                    'lat': 30 + (i / 100),
                    'lng': 120 + (i / 100),
                  }
                : {'weather_code': '晴', 'weather_temp': 18 + (i % 10)},
          ),
        );
    }
  }

  return Document(root: pageNode(children: children));
}

int _measureAverageMicros({
  required Document document,
  required int iterations,
}) {
  for (var i = 0; i < 10; i += 1) {
    EditorPlainTextExtractor.extract(document);
  }

  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < iterations; i += 1) {
    EditorPlainTextExtractor.extract(document);
  }
  stopwatch.stop();

  return stopwatch.elapsedMicroseconds ~/ iterations;
}
