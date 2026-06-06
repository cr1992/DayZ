// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/blocks/callout_block.dart';
import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:dayz/editor/contract/export_fallback.dart';
import 'package:dayz/editor/contract/plain_text_extractor.dart';
import 'package:dayz/ui/editor/editor_style.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

const _surfaceKey = ValueKey('editor-callout-visual-surface');

void main() {
  setUpAll(() async {
    await AppFlowyEditorLocalizations.load(
      const Locale.fromSubtags(languageCode: 'en'),
    );
  });

  patrolTest('editor callout renders themed visual and keeps contract chain', (
    $,
  ) async {
    final inserted = calloutNode(text: '记得复盘');
    final document = Document(root: pageNode(children: [inserted]));
    final decoded = EditorDocCodec.decode(
      EditorDocCodec.encode(document),
    ).document;
    final decodedNode = decoded.root.children.single;

    expect(decodedNode.type, CalloutBlockKeys.type);
    expect(decodedNode.delta?.toPlainText(), '记得复盘');
    expect(EditorPlainTextExtractor.extract(decoded), '记得复盘');
    expect(
      EditorExportFallback.fallbackLineForNode(
        decodedNode,
        format: EditorExportFallbackFormat.markdown,
      ),
      '> 记得复盘',
    );

    await _pumpVisualHarness($, theme: DayzThemes.amberDark, document: decoded);
    _expectCalloutTheme($.tester, DayzColors.amberDark);
    final amberPng = await _captureSurfacePng($.tester);
    final amberPath = await _writeScreenshot(
      amberPng,
      'editor_callout_amber_dark.png',
    );
    $.log('callout amberDark screenshot: $amberPath');

    await _pumpVisualHarness($, theme: DayzThemes.sageLight, document: decoded);
    _expectCalloutTheme($.tester, DayzColors.sageLight);
    final sagePng = await _captureSurfacePng($.tester);
    final sagePath = await _writeScreenshot(
      sagePng,
      'editor_callout_sage_light.png',
    );
    $.log('callout sageLight screenshot: $sagePath');

    expect(amberPng.length, greaterThan(1000));
    expect(sagePng.length, greaterThan(1000));
    expect(amberPng, isNot(equals(sagePng)));
  });
}

Future<void> _pumpVisualHarness(
  PatrolIntegrationTester $, {
  required ThemeData theme,
  required Document document,
}) async {
  await $.pumpWidgetAndSettle(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return RepaintBoundary(
              key: _surfaceKey,
              child: AppFlowyEditor(
                editorState: EditorState(document: document),
                blockComponentBuilders: EditorBlockRegistry.editableBuilders(),
                editorStyle: dayzEditorStyle(context),
              ),
            );
          },
        ),
      ),
    ),
  );
}

void _expectCalloutTheme(WidgetTester tester, DayzColors colors) {
  final calloutFinder = find.byType(CalloutBlockComponentWidget);
  expect(calloutFinder, findsOneWidget);
  expect(find.textContaining('记得复盘', findRichText: true), findsOneWidget);

  final icon = tester.widget<Icon>(
    find.descendant(
      of: calloutFinder,
      matching: find.byIcon(Icons.info_outline_rounded),
    ),
  );
  expect(icon.color, colors.accentInk);

  final decoration = tester
      .widgetList<Container>(
        find.descendant(of: calloutFinder, matching: find.byType(Container)),
      )
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .singleWhere((decoration) => decoration.color == colors.accentSoft);

  expect(decoration.borderRadius, BorderRadius.circular(8));
  expect(decoration.border, isNull);
}

Future<Uint8List> _captureSurfacePng(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_surfaceKey),
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  expect(byteData, isNotNull);
  return byteData!.buffer.asUint8List();
}

Future<String> _writeScreenshot(Uint8List bytes, String name) async {
  final directory = Directory(
    '${Directory.systemTemp.path}/dayz-patrol-screenshots',
  );
  await directory.create(recursive: true);
  final file = File('${directory.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
