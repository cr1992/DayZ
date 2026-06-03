// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('EditorToolbar', () {
    testWidgets('renders MobileToolbarV2 and bundles all 14 items', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.writing(
            entryDate: DateTime(2026),
            bodyPreview: 'hello',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure MobileToolbarV2 is rendered
      expect(find.byType(MobileToolbarV2), findsOneWidget);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EditorScreen)),
      );

      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      editor.editorState.selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [0], offset: 5),
      );
      await tester.pumpAndSettle();

      final labels = <String>[
        l10n.editorToolbarHeading,
        l10n.editorToolbarBold,
        l10n.editorToolbarItalic,
        l10n.editorToolbarUnderline,
        l10n.editorToolbarStrikethrough,
        l10n.editorToolbarCode,
        l10n.editorToolbarColor,
        l10n.editorToolbarBulletedList,
        l10n.editorToolbarNumberedList,
        l10n.editorToolbarTodoList,
        l10n.editorToolbarQuote,
        l10n.editorToolbarLink,
        l10n.editorToolbarDivider,
        l10n.editorToolbarImage,
      ];

      for (final label in labels) {
        expect(
          find.descendant(
            of: find.byType(IconButton),
            matching: find.bySemanticsLabel(label),
          ),
          findsOneWidget,
          reason: 'Failed to find toolbar item: $label',
        );
      }
    });

    testWidgets('Bold item toggles active color when selection bold state changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.writing(
            entryDate: DateTime(2026),
            bodyPreview: 'hello',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EditorScreen)),
      );

      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      final editorState = editor.editorState;

      // Set range selection spanning 'hello'
      editorState.selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [0], offset: 5),
      );
      await tester.pumpAndSettle();

      final colors = tester.element(find.byType(EditorScreen)).dayz;

      // Helper to find the color of the bold icon inside toolbar
      Finder findBoldIcon() {
        return find.descendant(
          of: find.descendant(
            of: find.byType(IconButton),
            matching: find.bySemanticsLabel(l10n.editorToolbarBold),
          ),
          matching: find.byType(AFMobileIcon),
        );
      }

      // 1. Initial State: Bold is not active
      var icon = tester.widget<AFMobileIcon>(findBoldIcon());
      expect(icon.color, colors.ink);

      // 2. Toggle Bold style on
      await tester.runAsync(() async {
        editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
      });
      await tester.pumpAndSettle();

      icon = tester.widget<AFMobileIcon>(findBoldIcon());
      expect(icon.color, colors.accent);

      // 3. Toggle Bold style off
      await tester.runAsync(() async {
        editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
      });
      await tester.pumpAndSettle();

      icon = tester.widget<AFMobileIcon>(findBoldIcon());
      expect(icon.color, colors.ink);
    });

    testWidgets('does not flat viewInsets.bottom manually', (tester) async {
      final editorScreen = EditorScreen.empty(entryDate: DateTime(2026));

      // Pump with 0 bottom inset
      await tester.pumpWidget(
        localizedTestApp(
          child: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.zero),
            child: Scaffold(body: editorScreen),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollFinder = find.byType(CustomScrollView);
      final initialTopLeft = tester.getTopLeft(scrollFinder);

      // Pump with 300 bottom inset
      await tester.pumpWidget(
        localizedTestApp(
          child: MediaQuery(
            data: const MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: Scaffold(body: editorScreen),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final afterTopLeft = tester.getTopLeft(scrollFinder);

      // The main view itself should not manually translate or shift its top-left coordinates.
      expect(afterTopLeft, initialTopLeft);
    });

    testWidgets('every toolbar item hit test target is at least 44 square', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.writing(
            entryDate: DateTime(2026),
            bodyPreview: 'hello',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      editor.editorState.selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [0], offset: 5),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EditorScreen)),
      );

      final itemLabels = [
        l10n.editorToolbarHeading,
        l10n.editorToolbarBold,
        l10n.editorToolbarItalic,
        l10n.editorToolbarUnderline,
        l10n.editorToolbarStrikethrough,
        l10n.editorToolbarCode,
        l10n.editorToolbarColor,
        l10n.editorToolbarBulletedList,
        l10n.editorToolbarNumberedList,
        l10n.editorToolbarTodoList,
        l10n.editorToolbarQuote,
        l10n.editorToolbarLink,
        l10n.editorToolbarDivider,
        l10n.editorToolbarImage,
      ];

      for (final label in itemLabels) {
        final finder = find.descendant(
          of: find.byType(IconButton),
          matching: find.bySemanticsLabel(label),
        );
        expect(finder, findsOneWidget, reason: 'No IconButton for label: $label');
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });
  });
}
