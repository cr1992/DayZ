// E2E on a real simulator: the caret must sit on the visible glyphs, not float
// above them. The widget-test harness only exercises a single (first) line —
// which has no leading and is already aligned — so it cannot reproduce the
// on-device overhang that appears on wrapped / non-first lines under the diary
// body's generous 1.85 line-height. This runs on the real engine (real fonts)
// and asserts the caret top matches the glyph top.
//
// Run: flutter test integration_test/editor_caret_e2e.dart -d <ios-sim-id>
import 'dart:ui' show BoxHeightStyle;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Widget _app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DayzThemes.purpleLight,
      home: Scaffold(body: home),
    );

const _body =
    '周六去西山走一圈，趁天气好。出发前把要点记下来，免得临时手忙脚乱，去年那条南坡今年封了，路线装备都要想清楚，免得到了山脚才发现漏带东西。';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('caret hugs the glyphs across wrapped lines', (tester) async {
    await AppFlowyEditorLocalizations.load(const Locale('en'));
    await tester.pumpWidget(
      _app(EditorScreen.writing(
        entryDate: DateTime(2026, 5, 29),
        bodyPreview: _body,
      )),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(AppFlowyRichText).first) as dynamic;
    RenderParagraph? body;
    for (final rp in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      if (rp.text.toPlainText().contains('周六')) {
        body = rp;
        break;
      }
    }
    expect(body, isNotNull, reason: 'body paragraph not found');

    for (final off in [2, 16, 30, 46, 60]) {
      if (off >= _body.length) continue;
      final caret = state.getCursorRectInPosition(
        Position(path: const [0], offset: off),
      ) as Rect?;
      final boxes = body!.getBoxesForSelection(
        TextSelection(baseOffset: off, extentOffset: off + 1),
        boxHeightStyle: BoxHeightStyle.tight,
      );
      final glyph = boxes.first.toRect();
      final overhang = glyph.top - caret!.top;
      // ignore: avoid_print
      print('E2E off=$off caret=(dy=${caret.top.toStringAsFixed(1)},'
          'h=${caret.height.toStringAsFixed(1)}) '
          'glyph=(top=${glyph.top.toStringAsFixed(1)},'
          'h=${glyph.height.toStringAsFixed(1)}) '
          'overhang=${overhang.toStringAsFixed(1)}');
      // The caret top must land on the glyph top (was ~4px above on wrapped
      // lines), and the caret must not be taller than the glyph box.
      expect(overhang.abs(), lessThan(2.5),
          reason: 'caret top floats off the glyph at offset $off');
      expect(caret.height, lessThan(glyph.height + 2.5),
          reason: 'caret taller than the glyph box at offset $off');
    }
  });

  testWidgets('empty-editor caret aligns with the hint', (tester) async {
    await AppFlowyEditorLocalizations.load(const Locale('en'));
    await tester.pumpWidget(
      _app(EditorScreen.empty(entryDate: DateTime(2026, 5, 29))),
    );
    await tester.pumpAndSettle();

    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
    editor.editorState.selection = Selection.collapsed(
      Position(path: [0], offset: 0),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(AppFlowyRichText).first) as dynamic;
    final caretLocal =
        state.getCursorRectInPosition(Position(path: const [0], offset: 0))
            as Rect?;
    final caretTop = (state.localToGlobal(Offset(0, caretLocal!.top)) as Offset).dy;
    final caretBottom =
        (state.localToGlobal(Offset(0, caretLocal.bottom)) as Offset).dy;

    final hintRp = tester
        .renderObjectList<RenderParagraph>(find.descendant(
          of: find.byKey(EditorScreen.bodyPlaceholderKey),
          matching: find.byType(RichText),
        ))
        .first;
    final hintGlyph = hintRp
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
          boxHeightStyle: BoxHeightStyle.tight,
        )
        .first
        .toRect();
    final hintTop = hintRp.localToGlobal(hintGlyph.topLeft).dy;
    final hintBottom = hintRp.localToGlobal(hintGlyph.bottomLeft).dy;

    // ignore: avoid_print
    print('E2E EMPTY caretGlobal=[${caretTop.toStringAsFixed(1)}..'
        '${caretBottom.toStringAsFixed(1)}] '
        'hintGlyphGlobal=[${hintTop.toStringAsFixed(1)}..'
        '${hintBottom.toStringAsFixed(1)}] '
        'topDelta=${(caretTop - hintTop).toStringAsFixed(1)} '
        'caretH=${(caretBottom - caretTop).toStringAsFixed(1)} '
        'hintH=${(hintBottom - hintTop).toStringAsFixed(1)}');
    // The empty caret must land on the hint glyph top AND match its height
    // (it used to collapse to the bare Latin font default ~18 and read shorter
    // than the CJK hint ~25). P006 sizes the empty caret to a CJK reference
    // grapheme in the node style.
    expect((caretTop - hintTop).abs(), lessThan(2.5));
    expect((caretBottom - caretTop) - (hintBottom - hintTop), greaterThan(-2.5),
        reason: 'empty caret is shorter than the hint');
  });

  testWidgets('Bold lights up on a collapsed caret', (tester) async {
    await AppFlowyEditorLocalizations.load(const Locale('en'));
    await tester.pumpWidget(
      _app(EditorScreen.writing(
        entryDate: DateTime(2026, 5, 29),
        bodyPreview: 'hello',
      )),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(EditorScreen)));
    final colors = tester.element(find.byType(EditorScreen)).dayz;
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
    editor.editorState.selection = Selection.collapsed(
      Position(path: [0], offset: 2),
    );
    await tester.pumpAndSettle();

    Finder boldIcon() => find.descendant(
          of: find.descendant(
            of: find.byType(IconButton),
            matching: find.bySemanticsLabel(l10n.editorToolbarBold),
          ),
          matching: find.byType(AFMobileIcon),
        );

    expect(tester.widget<AFMobileIcon>(boldIcon()).color, colors.ink);
    await tester.tap(
      find.ancestor(
        of: find.bySemanticsLabel(l10n.editorToolbarBold),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('E2E issue2 boldColorAfter=${tester.widget<AFMobileIcon>(boldIcon()).color} '
        'accent=${colors.accent}');
    expect(tester.widget<AFMobileIcon>(boldIcon()).color, colors.accent);
  });
}
