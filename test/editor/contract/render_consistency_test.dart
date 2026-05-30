// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/blocks/location_block.dart';
import 'package:dayz/editor/contract/blocks/weather_block.dart';
import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/editor/contract/readonly_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  testWidgets(
    'editable and readonly renderers expose the same visible semantics for contract blocks',
    (tester) async {
      final document = Document(
        root: pageNode(
          children: [
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
              type: ParagraphBlockKeys.type,
              attributes: {
                ParagraphBlockKeys.delta: [
                  {'insert': '正文'},
                ],
              },
            ),
            Node(
              type: ParagraphBlockKeys.type,
              attributes: {
                ParagraphBlockKeys.delta: [
                  {
                    'insert': '粗体',
                    'attributes': {'bold': true},
                  },
                  {'insert': ' '},
                  {
                    'insert': '斜体',
                    'attributes': {'italic': true},
                  },
                  {'insert': ' '},
                  {
                    'insert': '下划线',
                    'attributes': {'underline': true},
                  },
                  {'insert': ' '},
                  {
                    'insert': '删除线',
                    'attributes': {'strikethrough': true},
                  },
                  {'insert': ' '},
                  {
                    'insert': '代码',
                    'attributes': {'code': true},
                  },
                  {
                    'insert': ' 链接',
                    'attributes': {'href': 'https://example.com'},
                  },
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
            ),
            Node(
              type: NumberedListBlockKeys.type,
              attributes: {
                NumberedListBlockKeys.delta: [
                  {'insert': '有序项'},
                ],
              },
            ),
            Node(
              type: TodoListBlockKeys.type,
              attributes: {
                TodoListBlockKeys.checked: true,
                TodoListBlockKeys.delta: [
                  {'insert': '待办项'},
                ],
              },
            ),
            Node(
              type: QuoteBlockKeys.type,
              attributes: {
                QuoteBlockKeys.delta: [
                  {'insert': '引用项'},
                ],
              },
            ),
            dividerNode(),
            imageNode(url: EditorImageReference.urlForMediaId('missing-media')),
            locationNode(placeName: '上海', lat: 31.2304, lng: 121.4737),
            weatherNode(weatherCode: '晴', weatherTemp: 18),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFlowyEditor(
              editorState: EditorState(document: document),
              blockComponentBuilders: EditorBlockRegistry.editableBuilders(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      _expectSharedVisibleContent(tester);
      _expectInlineStyleSemantics(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ReadonlyRenderer(document: document)),
        ),
      );
      await tester.pumpAndSettle();

      _expectSharedVisibleContent(tester);
      _expectInlineStyleSemantics(tester);
    },
  );
}

void _expectSharedVisibleContent(WidgetTester tester) {
  expect(find.textContaining('标题', findRichText: true), findsOneWidget);
  expect(find.textContaining('正文', findRichText: true), findsOneWidget);
  expect(find.textContaining('无序项', findRichText: true), findsOneWidget);
  expect(find.textContaining('有序项', findRichText: true), findsOneWidget);
  expect(find.textContaining('待办项', findRichText: true), findsOneWidget);
  expect(find.textContaining('引用项', findRichText: true), findsOneWidget);
  expect(find.byType(Divider), findsOneWidget);
  expect(find.text('[图片不可用: missing-media]'), findsOneWidget);
  expect(find.text('上海'), findsOneWidget);
  expect(find.text('18°C'), findsOneWidget);
}

void _expectInlineStyleSemantics(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));

  bool hasSpan(bool Function(TextSpan span) predicate) {
    for (final richText in richTexts) {
      if (_spanTreeContains(richText.text, predicate)) {
        return true;
      }
    }
    return false;
  }

  expect(
    hasSpan(
      (span) =>
          span.toPlainText() == '粗体' &&
          span.style?.fontWeight == FontWeight.bold,
    ),
    isTrue,
  );
  expect(
    hasSpan(
      (span) =>
          span.toPlainText() == '斜体' &&
          span.style?.fontStyle == FontStyle.italic,
    ),
    isTrue,
  );
  expect(
    hasSpan(
      (span) =>
          span.toPlainText() == '下划线' &&
          (span.style?.decoration?.contains(TextDecoration.underline) ?? false),
    ),
    isTrue,
  );
  expect(
    hasSpan(
      (span) =>
          span.toPlainText() == '删除线' &&
          (span.style?.decoration?.contains(TextDecoration.lineThrough) ??
              false),
    ),
    isTrue,
  );
  expect(
    hasSpan(
      (span) =>
          span.toPlainText() == '代码' && span.style?.backgroundColor != null,
    ),
    isTrue,
  );
  expect(
    hasSpan(
      (span) => span.toPlainText().trim() == '链接' && span.recognizer != null,
    ),
    isTrue,
  );
}

bool _spanTreeContains(
  InlineSpan span,
  bool Function(TextSpan span) predicate,
) {
  if (span is TextSpan) {
    if (predicate(span)) {
      return true;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      if (_spanTreeContains(child, predicate)) {
        return true;
      }
    }
  }
  return false;
}
