// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_draft_coordinator.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('EditorDraftBridge', () {
    testWidgets(
      'pushes onChanged on edits and flips navTitle to Draft Saved after the first flush',
      (tester) async {
        final coordinator = FakeDraftCoordinator();

        await tester.pumpWidget(
          localizedTestApp(
            child: EditorScreen.empty(
              entryDate: DateTime(2026),
              entryId: 'test-entry-id',
              draftCoordinator: coordinator,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScreen)),
        );

        // Initially title is "New Entry"
        expect(find.text(l10n.editorTitleNew), findsOneWidget);

        final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
        final editorState = editor.editorState;

        await tester.runAsync(() async {
          final transaction = editorState.transaction
            ..insertNode(
              [0],
              paragraphNode(text: 'Draft content'),
            );
          await editorState.apply(transaction);
          // Let the bridge's forceFlush-gated confirmation complete.
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();

        // The edit was forwarded to the coordinator (R8 autosave).
        expect(coordinator.changes, isNotEmpty);
        final change = coordinator.lastChange!;
        expect(change.targetId, 'test-entry-id');
        expect(change.isNew, isTrue);
        expect(change.draftJson, contains('Draft content'));

        // The title flips only after a real content edit has been flushed (D4).
        expect(coordinator.forceFlushCount, greaterThanOrEqualTo(1));
        expect(find.text(l10n.editorTitleDraftSaved), findsOneWidget);
      },
    );

    testWidgets(
      'a bare cursor move does not flip the title to Draft Saved',
      (tester) async {
        final coordinator = FakeDraftCoordinator();

        await tester.pumpWidget(
          localizedTestApp(
            child: EditorScreen.empty(
              entryDate: DateTime(2026),
              entryId: 'test-entry-id',
              draftCoordinator: coordinator,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScreen)),
        );

        final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
        final editorState = editor.editorState;

        // Move the caret only — no content typed yet.
        editorState.selection = Selection.collapsed(
          Position(path: [0], offset: 0),
        );
        await tester.pumpAndSettle();

        // No flush happened, so the title must stay "New Entry" (not flip early).
        expect(coordinator.forceFlushCount, 0);
        expect(find.text(l10n.editorTitleNew), findsOneWidget);
        expect(find.text(l10n.editorTitleDraftSaved), findsNothing);
      },
    );

    testWidgets('triggers forceFlush on coordinator when completed', (
      tester,
    ) async {
      final coordinator = FakeDraftCoordinator();
      bool doneCalled = false;

      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.empty(
            entryDate: DateTime(2026),
            entryId: 'test-entry-id',
            draftCoordinator: coordinator,
            onDone: () => doneCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(coordinator.forceFlushCount, 0);

      // Tap completion button
      final doneButton = find.byKey(EditorScreen.doneButtonKey);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(coordinator.forceFlushCount, 1);
      expect(doneCalled, isTrue);
    });

    testWidgets('triggers forceFlush on coordinator when closed', (
      tester,
    ) async {
      final coordinator = FakeDraftCoordinator();
      bool closeCalled = false;

      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.empty(
            entryDate: DateTime(2026),
            entryId: 'test-entry-id',
            draftCoordinator: coordinator,
            onClose: () => closeCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(coordinator.forceFlushCount, 0);

      // Tap close button
      final closeButton = find.byKey(EditorScreen.closeButtonKey);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(coordinator.forceFlushCount, 1);
      expect(closeCalled, isTrue);
    });
  });
}
