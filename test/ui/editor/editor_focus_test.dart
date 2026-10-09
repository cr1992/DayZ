// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('EditorScreen focus (empty entry)', () {
    testWidgets('a brand-new empty entry seeds an editable paragraph', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.empty(entryDate: DateTime(2026, 5, 29)),
        ),
      );
      await tester.pumpAndSettle();

      final editor = tester.widget<AppFlowyEditor>(
        find.byType(AppFlowyEditor),
      );
      // Regression guard for the focus bug: the empty document MUST carry at
      // least one editable block, otherwise there is nothing to tap into and
      // the cursor/IME can never attach.
      expect(
        editor.editorState.document.root.children,
        isNotEmpty,
        reason: 'empty entry must seed an editable paragraph block',
      );
    });

    testWidgets('tapping the body of an empty entry acquires a selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.empty(entryDate: DateTime(2026, 5, 29)),
        ),
      );
      await tester.pumpAndSettle();

      final editor = tester.widget<AppFlowyEditor>(
        find.byType(AppFlowyEditor),
      );
      final editorState = editor.editorState;

      expect(editorState.selection, isNull);

      await tester.tap(find.byType(AppFlowyEditor));
      await tester.pumpAndSettle();

      // After tapping, the editor must hold a collapsed selection so the
      // soft keyboard can attach and the user can start typing.
      expect(
        editorState.selection,
        isNotNull,
        reason: 'tapping the empty body must place a cursor',
      );
    });
  });
}
