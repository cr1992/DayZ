// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_meta_bar.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

void main() {
  group('EditorScreen skeleton', () {
    testWidgets(
      'renders empty state with localized title, placeholders, and meta chips',
      (tester) async {
        await tester.pumpWidget(
          localizedTestApp(
            child: EditorScreen.empty(entryDate: DateTime(2026, 5, 29)),
          ),
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScreen)),
        );

        expect(find.text(l10n.editorTitleNew), findsOneWidget);
        expect(find.text(l10n.editorTitlePlaceholder), findsOneWidget);
        expect(find.text(l10n.editorBodyPlaceholderEmpty), findsOneWidget);
        expect(find.text(l10n.editorMetaMood), findsOneWidget);
        expect(find.text(l10n.editorMetaWeather), findsOneWidget);
        expect(find.text(l10n.editorMetaLocation), findsOneWidget);
        expect(find.text(l10n.editorMetaTags), findsOneWidget);
      },
    );

    testWidgets(
      'renders localized strings without zh literals in English locale',
      (tester) async {
        await tester.pumpWidget(
          localizedTestApp(
            locale: const Locale('en'),
            child: EditorScreen.empty(entryDate: DateTime(2026, 5, 29)),
          ),
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(EditorScreen)),
        );
        expect(find.text(l10n.editorTitleNew), findsOneWidget);
        expect(find.text(l10n.editorTitlePlaceholder), findsOneWidget);
        expect(find.text('新日记'), findsNothing);
        expect(find.text('标题'), findsNothing);
      },
    );

    testWidgets('renders writing and rich states with draft saved title', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.writing(
            entryDate: DateTime(2026, 5, 29),
            title: 'May note',
            bodyPreview: 'Writing body',
          ),
        ),
      );

      var l10n = AppLocalizations.of(tester.element(find.byType(EditorScreen)));
      expect(find.text(l10n.editorTitleDraftSaved), findsOneWidget);
      expect(find.text('May note'), findsOneWidget);
      expect(find.text('Writing body'), findsOneWidget);

      await tester.pumpWidget(
        localizedTestApp(
          child: EditorScreen.rich(
            entryDate: DateTime(2026, 5, 29),
            title: 'Rich note',
            bodyPreview: 'Quote and todo',
          ),
        ),
      );

      l10n = AppLocalizations.of(tester.element(find.byType(EditorScreen)));
      expect(find.text(l10n.editorTitleDraftSaved), findsOneWidget);
      expect(find.text('Rich note'), findsOneWidget);
      expect(find.text('Quote and todo'), findsOneWidget);
    });

    testWidgets('keeps title TextField borderless before and after focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(child: EditorScreen.empty(entryDate: DateTime(2026))),
      );

      final titleFieldFinder = find.byKey(EditorScreen.titleFieldKey);
      var titleField = tester.widget<TextField>(titleFieldFinder);
      expect(titleField.decoration?.border, InputBorder.none);
      expect(titleField.decoration?.enabledBorder, InputBorder.none);
      expect(titleField.decoration?.focusedBorder, InputBorder.none);

      await tester.tap(titleFieldFinder);
      await tester.pump();

      titleField = tester.widget<TextField>(titleFieldFinder);
      expect(titleField.decoration?.border, InputBorder.none);
      expect(titleField.decoration?.enabledBorder, InputBorder.none);
      expect(titleField.decoration?.focusedBorder, InputBorder.none);
    });

    testWidgets('exposes semantics and keeps tap targets at least 44 square', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(child: EditorScreen.empty(entryDate: DateTime(2026))),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(EditorScreen)),
      );
      final labels = <String>[
        l10n.editorCloseSemanticLabel,
        l10n.editorDoneSemanticLabel,
        l10n.editorMetaMood,
        l10n.editorMetaWeather,
        l10n.editorMetaLocation,
        l10n.editorMetaTags,
      ];

      for (final label in labels) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }

      final targetFinders = <Finder>[
        find.byKey(EditorScreen.closeButtonKey),
        find.byKey(EditorScreen.doneButtonKey),
        find.byKey(EditorMetaBar.moodChipKey),
        find.byKey(EditorMetaBar.weatherChipKey),
        find.byKey(EditorMetaBar.locationChipKey),
        find.byKey(EditorMetaBar.tagsChipKey),
      ];

      for (final finder in targetFinders) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });
  });
}
