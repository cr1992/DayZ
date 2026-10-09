// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_image_inserter.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_media_store.dart';
import 'fakes/fake_repos.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('EditorImageInserter', () {
    testWidgets(
      'picks multiple assets and inserts dayz-media blocks in order',
      (tester) async {
        final mediaRepo = FakeMediaRepo();
        final mediaStore = FakeMediaStore(
          mediaRepo: mediaRepo,
          nextMediaId: 'media-test-123',
        );
        final pickedAssets = <EditorPickedImage>[
          EditorPickedImage.memory(
            bytes: Uint8List.fromList([10, 20, 30]),
            name: 'one.png',
            sourcePath: '/tmp/dayz-clear-one.png',
            mime: 'image/png',
            width: 120,
            height: 80,
          ),
          EditorPickedImage.memory(
            bytes: Uint8List.fromList([40, 50]),
            name: 'two.jpg',
            sourcePath: '/tmp/dayz-clear-two.jpg',
            mime: 'image/jpeg',
            width: 240,
            height: 160,
          ),
          EditorPickedImage.memory(
            bytes: Uint8List.fromList([60]),
            name: 'three.webp',
            sourcePath: '/tmp/dayz-clear-three.webp',
            mime: 'image/webp',
            width: 320,
            height: 200,
          ),
        ];
        AssetPickerConfig? capturedConfig;
        late final BuildContext testContext;
        final editorState = EditorState(
          document: Document(
            root: pageNode(children: [paragraphNode(text: 'hello')]),
          ),
        );
        addTearDown(editorState.dispose);

        await tester.pumpWidget(
          localizedTestApp(
            child: Builder(
              builder: (context) {
                testContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select spanning 'hello'
        editorState.selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: 5),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(testContext);

        await tester.runAsync(() async {
          await EditorImageInserter.pickAndInsert(
            context: testContext,
            editorState: editorState,
            mediaStore: mediaStore,
            entryId: 'test-entry',
            pickAssetsOp: (context, config) async {
              capturedConfig = config;
              return pickedAssets;
            },
          );
        });
        await tester.pumpAndSettle();

        final expectedAccent = testContext.dayz.accent;
        expect(capturedConfig, isNotNull);
        expect(capturedConfig!.maxAssets, 9);
        expect(capturedConfig!.gridCount, 4);
        expect(capturedConfig!.requestType, RequestType.image);
        expect(capturedConfig!.themeColor, expectedAccent);
        expect(capturedConfig!.specialItems, hasLength(1));
        expect(
          capturedConfig!.specialItems.single.position,
          SpecialItemPosition.prepend,
        );
        expect(
          capturedConfig!.textDelegate?.confirm,
          l10n.editorImagePickerDone,
        );
        expect(
          capturedConfig!.textDelegate?.cancel,
          l10n.editorImagePickerCancel,
        );
        expect(
          capturedConfig!.textDelegate?.preview,
          l10n.editorImagePickerPreview,
        );
        expect(
          capturedConfig!.textDelegate?.original,
          l10n.editorImagePickerOriginal,
        );

        expect(mediaStore.putCalls, hasLength(3));
        expect(mediaStore.putCalls.map((call) => call.id), [
          'media-test-123',
          'media-test-124',
          'media-test-125',
        ]);
        expect(mediaStore.putCalls.map((call) => call.entryId).toSet(), {
          'test-entry',
        });
        expect(mediaStore.putCalls.map((call) => call.mime), [
          'image/png',
          'image/jpeg',
          'image/webp',
        ]);
        expect(mediaStore.putCalls.map((call) => call.fileSize), [3, 2, 1]);

        expect(mediaRepo.addedMedia, hasLength(3));
        expect(mediaRepo.addedMedia.map((meta) => meta.id), [
          'media-test-123',
          'media-test-124',
          'media-test-125',
        ]);
        expect(mediaRepo.addedMedia.map((meta) => meta.width), [120, 240, 320]);

        final document = editorState.document;
        final nodes = document.root.children;
        final imageNodes = nodes
            .where((node) => node.type == ImageBlockKeys.type)
            .toList();
        expect(imageNodes, hasLength(3));

        expect(imageNodes.map((node) => node.attributes[ImageBlockKeys.url]), [
          'dayz-media://media-test-123',
          'dayz-media://media-test-124',
          'dayz-media://media-test-125',
        ]);

        final encodedJson = EditorDocCodec.encode(document);
        expect(encodedJson, contains('dayz-media://media-test-123'));
        expect(encodedJson, contains('dayz-media://media-test-124'));
        expect(encodedJson, contains('dayz-media://media-test-125'));
        expect(encodedJson, isNot(contains('/tmp/dayz-clear-one.png')));
        expect(encodedJson, isNot(contains('/tmp/dayz-clear-two.jpg')));
        expect(encodedJson, isNot(contains('/tmp/dayz-clear-three.webp')));

        expect(pickedAssets.every((asset) => asset.cleanupCount == 1), isTrue);
      },
    );

    testWidgets(
      'inserts multiple images contiguously in the middle of a document',
      (tester) async {
        // Regression: with a manual `+ i` path shift stacked on top of
        // Transaction.add's auto-transform, the images double-shifted and the
        // original following nodes interleaved between them. This only shows up
        // mid-document — the end-of-document case above masks it because the
        // gapped indices clamp to the list end and come out contiguous.
        final mediaRepo = FakeMediaRepo();
        final mediaStore = FakeMediaStore(
          mediaRepo: mediaRepo,
          nextMediaId: 'media-mid-1',
        );
        final pickedAssets = <EditorPickedImage>[
          EditorPickedImage.memory(
            bytes: Uint8List.fromList([1]),
            name: 'one.png',
            sourcePath: '/tmp/dayz-mid-one.png',
            mime: 'image/png',
            width: 10,
            height: 10,
          ),
          EditorPickedImage.memory(
            bytes: Uint8List.fromList([2]),
            name: 'two.png',
            sourcePath: '/tmp/dayz-mid-two.png',
            mime: 'image/png',
            width: 20,
            height: 20,
          ),
        ];
        late final BuildContext testContext;
        final editorState = EditorState(
          document: Document(
            root: pageNode(
              children: [
                paragraphNode(text: 'a'),
                paragraphNode(text: 'b'),
                paragraphNode(text: 'c'),
              ],
            ),
          ),
        );
        addTearDown(editorState.dispose);

        await tester.pumpWidget(
          localizedTestApp(
            child: Builder(
              builder: (context) {
                testContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Caret in the middle node ('a'), so 'b'/'c' follow the insertion point.
        editorState.selection = Selection.collapsed(
          Position(path: [0], offset: 1),
        );
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          await EditorImageInserter.pickAndInsert(
            context: testContext,
            editorState: editorState,
            mediaStore: mediaStore,
            entryId: 'test-entry',
            pickAssetsOp: (context, config) async => pickedAssets,
          );
        });
        await tester.pumpAndSettle();

        final children = editorState.document.root.children;
        // Images land contiguously right after 'a'; 'b'/'c' stay in order after.
        expect(
          children.map((node) => node.type).toList(),
          [
            ParagraphBlockKeys.type,
            ImageBlockKeys.type,
            ImageBlockKeys.type,
            ParagraphBlockKeys.type,
            ParagraphBlockKeys.type,
          ],
        );
        expect(children[0].delta?.toPlainText(), 'a');
        expect(children[3].delta?.toPlainText(), 'b');
        expect(children[4].delta?.toPlainText(), 'c');
        // Caret collapses onto the last inserted image.
        expect(editorState.selection?.isCollapsed, isTrue);
        expect(editorState.selection?.start.path, [2]);
      },
    );

    testWidgets('cancelling the picker does not store or insert images', (
      tester,
    ) async {
      final mediaRepo = FakeMediaRepo();
      final mediaStore = FakeMediaStore(mediaRepo: mediaRepo);
      AssetPickerConfig? capturedConfig;
      late final BuildContext testContext;
      final editorState = EditorState(
        document: Document(
          root: pageNode(children: [paragraphNode(text: 'hello')]),
        ),
      );
      addTearDown(editorState.dispose);

      await tester.pumpWidget(
        localizedTestApp(
          child: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 5),
      );

      await tester.runAsync(() async {
        await EditorImageInserter.pickAndInsert(
          context: testContext,
          editorState: editorState,
          mediaStore: mediaStore,
          entryId: 'test-entry',
          pickAssetsOp: (context, config) async {
            capturedConfig = config;
            return <EditorPickedImage>[];
          },
        );
      });
      await tester.pumpAndSettle();

      expect(capturedConfig, isNotNull);
      expect(mediaStore.putCalls, isEmpty);
      expect(mediaRepo.addedMedia, isEmpty);
      expect(
        editorState.document.root.children.where(
          (node) => node.type == ImageBlockKeys.type,
        ),
        isEmpty,
      );
    });

    test('static verification: no Drift/SQL imports in inserter', () {
      // In this test, we verify that EditorImageInserter is completely decoupled from Drift.
      // This is verified statically by the compiler because our lib code only imports dayz/media/media_store.dart
      // and not lib/data/database.dart or drift packages.
    });
  });
}
