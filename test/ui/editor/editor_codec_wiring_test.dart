// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_repos.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('EditorDocCodec Wiring', () {
    testWidgets('loads existing content from initialContentJson', (
      tester,
    ) async {
      // Create valid JSON with docVersion=1
      final doc = Document(
        root: pageNode(children: [
          paragraphNode(text: 'Hello from decoded JSON!'),
        ]),
      );
      final jsonSource = EditorDocCodec.encode(doc);

      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.writing(
            entryDate: DateTime(2026, 5, 29),
            entryId: 'entry-id-1',
            initialContentJson: jsonSource,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      final plainText = EditorDocCodec.extractPlainText(editor.editorState.document);
      expect(plainText, contains('Hello from decoded JSON!'));
    });

    testWidgets('saves content through EntryRepo on done', (tester) async {
      final entryRepo = FakeEntryRepo();
      bool doneCalled = false;

      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.writing(
            entryDate: DateTime(2026, 5, 29),
            entryId: 'entry-save-123',
            title: 'My Secret Title',
            bodyPreview: 'First body content',
            entryRepo: entryRepo,
            onDone: () => doneCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap completion button
      final doneButton = find.byKey(EditorScreen.doneButtonKey);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(doneCalled, isTrue);
      expect(entryRepo.savedEntries, hasLength(1));

      final saved = entryRepo.savedEntries.first;
      expect(saved.id, 'entry-save-123');

      // Assert contentJson contains docVersion=1 and the actual content
      expect(saved.contentJson, contains('"docVersion":1'));
      expect(saved.contentJson, contains('First body content'));

      // Assert contentPlain has title as the first line and editor text content as subsequent lines
      final lines = saved.contentPlain.split('\n');
      expect(lines.first, 'My Secret Title');
      expect(lines.skip(1).join('\n'), contains('First body content'));
    });
  });
}
