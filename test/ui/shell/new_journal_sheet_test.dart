// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/shell/new_journal_sheet.dart';
import '../../l10n/localized_test_app.dart';

void main() {
  void ignoreSubmit(String name, String color) {}

  Widget buildSheetHost({
    required void Function(String name, String color) onSubmit,
    bool disableAnimations = false,
  }) {
    return localizedMaterialApp(
      home: MediaQuery(
        data: const MediaQueryData().copyWith(
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showNewJournalSheet(context, onSubmit: onSubmit);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('renders all widgets on sheet open', (tester) async {
    await tester.pumpWidget(buildSheetHost(onSubmit: ignoreSubmit));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify Title and input fields are rendered
    expect(find.text(testL10n.newJournal), findsOneWidget);
    expect(find.text(testL10n.journalNameLabel), findsOneWidget);
    expect(find.text(testL10n.journalColorLabel), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify 6 color palette buttons are rendered
    for (final hex in kJournalColorPalette) {
      expect(find.bySemanticsLabel(hex), findsOneWidget);
    }

    // Verify Create button is rendered
    expect(find.text(testL10n.sheetCreate), findsOneWidget);
  });

  testWidgets('selecting a color updates selection state', (tester) async {
    await tester.pumpWidget(buildSheetHost(onSubmit: ignoreSubmit));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // First color should be selected by default
    final firstColorSemantics = tester.getSemantics(
      find.bySemanticsLabel(kJournalColorPalette[0]),
    );
    expect(firstColorSemantics.flagsCollection.isSelected, Tristate.isTrue);

    // Second color should not be selected initially
    final secondColorSemantics = tester.getSemantics(
      find.bySemanticsLabel(kJournalColorPalette[1]),
    );
    expect(
      secondColorSemantics.flagsCollection.isSelected,
      isNot(Tristate.isTrue),
    );

    // Tap second color
    await tester.tap(find.bySemanticsLabel(kJournalColorPalette[1]));
    await tester.pumpAndSettle();

    // Now second color should be selected
    final secondColorSemanticsNew = tester.getSemantics(
      find.bySemanticsLabel(kJournalColorPalette[1]),
    );
    expect(secondColorSemanticsNew.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets(
    'submit is disabled when name is empty, enables on name input, and fires onSubmit on confirm',
    (tester) async {
      String? submittedName;
      String? submittedColor;
      var submitFired = false;

      await tester.pumpWidget(
        buildSheetHost(
          onSubmit: (name, color) {
            submittedName = name;
            submittedColor = color;
            submitFired = true;
          },
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Create button is initially disabled because name is empty
      final confirmButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(testL10n.sheetCreate),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(confirmButton.onPressed, isNull);

      // Type name
      await tester.enterText(find.byType(TextField), 'Personal Thoughts');
      await tester.pumpAndSettle();

      // Create button should now be enabled
      final confirmButtonEnabled = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(testL10n.sheetCreate),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(confirmButtonEnabled.onPressed, isNotNull);

      // Tap Create
      await tester.tap(find.text(testL10n.sheetCreate));
      await tester.pumpAndSettle();

      // Verify onSubmit callback parameter correctness and sheet closure
      expect(submitFired, true);
      expect(submittedName, 'Personal Thoughts');
      expect(submittedColor, kJournalColorPalette.first);
      expect(find.text(testL10n.newJournal), findsNothing);
    },
  );

  testWidgets('color item hit area >= 44px', (tester) async {
    await tester.pumpWidget(buildSheetHost(onSubmit: ignoreSubmit));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final colorBtn = find.bySemanticsLabel(kJournalColorPalette[0]);
    final size = tester.getSize(colorBtn);

    expect(size.width, greaterThanOrEqualTo(44.0));
    expect(size.height, greaterThanOrEqualTo(44.0));
  });

  testWidgets('disableAnimations opens sheet in one frame', (tester) async {
    await tester.pumpWidget(
      buildSheetHost(disableAnimations: true, onSubmit: ignoreSubmit),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text(testL10n.newJournal), findsOneWidget);
  });
}
