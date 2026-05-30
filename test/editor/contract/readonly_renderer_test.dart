// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/editor/contract/blocks/location_block.dart';
import 'package:dayz/editor/contract/readonly_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('ReadonlyRenderer', () {
    test('editable and readonly registries expose the same content types', () {
      final editableTypes = EditorBlockRegistry.contentTypesOf(
        EditorBlockRegistry.editableBuilders(),
      );
      final readonlyTypes = ReadonlyRenderer.registeredTypes();

      expect(editableTypes, equals(readonlyTypes));
      expect(readonlyTypes, equals(EditorBlockTypes.supported));
    });

    testWidgets(
      'unknown blocks degrade safely while known blocks still render',
      (tester) async {
        final document = Document(
          root: pageNode(
            children: [
              locationNode(placeName: '上海', lat: 31.2304, lng: 121.4737),
              Node(
                type: 'unknown_block',
                attributes: {
                  'delta': [
                    {'insert': '未知块文本'},
                  ],
                },
              ),
            ],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ReadonlyRenderer(document: document)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('上海'), findsOneWidget);
        expect(find.text('未知块文本'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
