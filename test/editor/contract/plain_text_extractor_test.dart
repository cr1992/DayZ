// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/blocks/location_block.dart';
import 'package:dayz/editor/contract/blocks/weather_block.dart';
import 'package:dayz/editor/contract/plain_text_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorPlainTextExtractor', () {
    test('covers each supported block with the expected fallback text', () {
      final root = pageNode(
        children: [
          Node(
            type: ParagraphBlockKeys.type,
            attributes: {
              ParagraphBlockKeys.delta: [
                {'insert': '段落正文'},
              ],
            },
          ),
          Node(
            type: HeadingBlockKeys.type,
            attributes: {
              HeadingBlockKeys.level: 2,
              HeadingBlockKeys.delta: [
                {'insert': '第二层标题'},
              ],
            },
          ),
          Node(
            type: BulletedListBlockKeys.type,
            attributes: {
              BulletedListBlockKeys.delta: [
                {'insert': '无序项'},
              ],
            },
            children: [
              Node(
                type: BulletedListBlockKeys.type,
                attributes: {
                  BulletedListBlockKeys.delta: [
                    {'insert': '嵌套无序项'},
                  ],
                },
              ),
            ],
          ),
          Node(
            type: NumberedListBlockKeys.type,
            attributes: {
              NumberedListBlockKeys.delta: [
                {'insert': '第一项'},
              ],
            },
          ),
          Node(
            type: NumberedListBlockKeys.type,
            attributes: {
              NumberedListBlockKeys.delta: [
                {'insert': '第二项'},
              ],
            },
          ),
          Node(
            type: TodoListBlockKeys.type,
            attributes: {
              TodoListBlockKeys.checked: true,
              TodoListBlockKeys.delta: [
                {'insert': '已完成任务'},
              ],
            },
          ),
          Node(
            type: TodoListBlockKeys.type,
            attributes: {
              TodoListBlockKeys.checked: false,
              TodoListBlockKeys.delta: [
                {'insert': '待处理任务'},
              ],
            },
          ),
          Node(
            type: QuoteBlockKeys.type,
            attributes: {
              QuoteBlockKeys.delta: [
                {'insert': '引用内容'},
              ],
            },
          ),
          dividerNode(),
          imageNode(url: EditorImageReference.urlForMediaId('media-1')),
          locationNode(placeName: '上海', lat: 31.2304, lng: 121.4737),
          weatherNode(weatherCode: '晴', weatherTemp: 18),
        ],
      );

      final plainText = EditorPlainTextExtractor.extract(Document(root: root));

      expect(
        plainText,
        '段落正文\n'
        '第二层标题\n'
        '• 无序项\n'
        '• 嵌套无序项\n'
        '1. 第一项\n'
        '2. 第二项\n'
        '[x] 已完成任务\n'
        '[ ] 待处理任务\n'
        '> 引用内容\n'
        '\n'
        '[图片]\n'
        '📍 上海\n'
        '🌤 18°C',
      );
    });

    test('weather and location blocks degrade with missing values safely', () {
      final document = Document(
        root: pageNode(
          children: [
            locationNode(),
            weatherNode(weatherCode: '多云'),
            weatherNode(),
          ],
        ),
      );

      expect(EditorPlainTextExtractor.extract(document), '\n🌤 多云\n');
    });

    test('title equals the first emitted line and empty docs stay empty', () {
      final titledDocument = Document(
        root: pageNode(
          children: [
            Node(
              type: HeadingBlockKeys.type,
              attributes: {
                HeadingBlockKeys.level: 1,
                HeadingBlockKeys.delta: [
                  {'insert': '今日标题'},
                ],
              },
            ),
            Node(
              type: ParagraphBlockKeys.type,
              attributes: {
                ParagraphBlockKeys.delta: [
                  {'insert': '正文'},
                ],
              },
            ),
          ],
        ),
      );

      expect(EditorPlainTextExtractor.extractTitle(titledDocument), '今日标题');
      expect(EditorPlainTextExtractor.extract(Document.blank()), '');
      expect(EditorPlainTextExtractor.extractTitle(Document.blank()), '');
    });

    test('unknown blocks fall back to delta text or are skipped', () {
      final document = Document(
        root: pageNode(
          children: [
            Node(
              type: 'unknown_with_delta',
              attributes: {
                'delta': [
                  {'insert': '未知文本'},
                ],
              },
            ),
            Node(type: 'unknown_without_delta'),
          ],
        ),
      );

      expect(EditorPlainTextExtractor.extract(document), '未知文本');
    });

    test('extractor performs no filesystem I/O', () {
      var createFileCalled = false;
      var createDirectoryCalled = false;
      var statCalled = false;
      final document = Document(
        root: pageNode(
          children: [
            imageNode(url: EditorImageReference.urlForMediaId('media-1')),
            locationNode(placeName: '上海'),
            weatherNode(weatherCode: '晴', weatherTemp: 18),
          ],
        ),
      );

      final output = IOOverrides.runZoned(
        () => EditorPlainTextExtractor.extract(document),
        createFile: (path) {
          createFileCalled = true;
          return File(path);
        },
        createDirectory: (path) {
          createDirectoryCalled = true;
          return Directory(path);
        },
        stat: (path) async {
          statCalled = true;
          return FileStat.stat(path);
        },
      );

      expect(output, '[图片]\n📍 上海\n🌤 18°C');
      expect(createFileCalled, isFalse);
      expect(createDirectoryCalled, isFalse);
      expect(statCalled, isFalse);
    });
  });
}
