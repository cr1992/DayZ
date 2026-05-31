// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:dayz/ui/editor/editor_style.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_fonts.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('dayzEditorStyle', () {
    testWidgets('uses DayZ diary typography and accent token colors', (
      tester,
    ) async {
      late EditorStyle style;
      late DayzColors colors;
      late DayzTextTheme text;

      await tester.pumpWidget(
        localizedTestApp(
          child: Builder(
            builder: (context) {
              style = dayzEditorStyle(context);
              colors = context.dayz;
              text = context.dayzText;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(style.cursorColor, colors.accent);
      expect(style.dragHandleColor, colors.accent);
      expect(style.selectionColor, colors.accentSoft2);
      expect(style.textStyleConfiguration.text.fontFamily, DayzFonts.serif);
      expect(style.textStyleConfiguration.text.height, text.diary.height);
      expect(style.textStyleConfiguration.text.color, colors.ink);
      expect(style.textStyleConfiguration.lineHeight, text.diary.height);
    });

    testWidgets('changes editor accent colors when DayZ theme changes', (
      tester,
    ) async {
      late EditorStyle purpleStyle;
      late DayzColors purpleColors;
      late EditorStyle amberStyle;
      late DayzColors amberColors;

      await tester.pumpWidget(
        localizedTestApp(
          theme: DayzThemes.purpleLight,
          child: Builder(
            builder: (context) {
              purpleStyle = dayzEditorStyle(context);
              purpleColors = context.dayz;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        localizedTestApp(
          theme: DayzThemes.amberLight,
          child: Builder(
            builder: (context) {
              amberStyle = dayzEditorStyle(context);
              amberColors = context.dayz;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(purpleStyle.cursorColor, purpleColors.accent);
      expect(purpleStyle.selectionColor, purpleColors.accentSoft2);
      expect(amberStyle.cursorColor, amberColors.accent);
      expect(amberStyle.selectionColor, amberColors.accentSoft2);
    });

    testWidgets('EditorScreen renders AppFlowyEditor with the DayZ style', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(child: EditorScreen.empty(entryDate: DateTime(2026))),
      );
      await tester.pumpAndSettle();

      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
      final context = tester.element(find.byType(EditorScreen));
      final colors = context.dayz;

      expect(editor.editorStyle.cursorColor, colors.accent);
      expect(editor.editorStyle.textStyleConfiguration.text.fontFamily,
          DayzFonts.serif);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
