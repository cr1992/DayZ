// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/editor_screen_demo.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../l10n/localized_test_app.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  test('demos list exposes editor screen demo', () {
    final entry = demos.singleWhere((entry) => entry.title == '编辑页 demo');

    expect(entry.subtitle, '编辑页三状态与六套主题演示');
    expect(entry.builder, isNotNull);
  });

  testWidgets('EditorScreenDemo renders and allows switching states', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const EditorScreenDemo()));
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsOneWidget);

    // Default mode is empty, expect body placeholder empty text
    expect(find.byKey(EditorScreen.bodyPlaceholderKey), findsOneWidget);

    // Switch to writing mode
    await tester.tap(find.text('writing'));
    await tester.pumpAndSettle();

    // Verify title and editor state
    expect(find.text('写一段话'), findsOneWidget);
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
    expect(EditorDocCodec.extractPlainText(editor.editorState.document), contains('记录今天的日常'));
  });

  testWidgets('EditorScreenDemo edits drive the draft coordinator without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const EditorScreenDemo()));
    await tester.pumpAndSettle();

    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
    final editorState = editor.editorState;

    // Drive a real transaction so the EditorDraftBridge calls the demo
    // coordinator's onChanged. A signature mismatch would surface here as a
    // NoSuchMethodError (the exact bug this guards against).
    await tester.runAsync(() async {
      final transaction = editorState.transaction
        ..insertNode([0], paragraphNode(text: 'hello demo'));
      await editorState.apply(transaction);
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('EditorScreenDemo allows switching themes', (tester) async {
    await tester.pumpWidget(localizedTestApp(child: const EditorScreenDemo()));
    await tester.pumpAndSettle();

    // Switch to amberDark theme
    await tester.tap(find.text('amberDark'));
    await tester.pumpAndSettle();

    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor));
    final expectedColors = DayzThemes.amberDark.extension<DayzColors>()!;
    expect(editor.editorStyle.cursorColor, expectedColors.accent);
  });

  testWidgets('Debug Home can navigate to editor screen demo', (tester) async {
    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('编辑页 demo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑页 demo'), findsOneWidget);

    await tester.tap(find.text('编辑页 demo'));
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreenDemo), findsOneWidget);
    expect(find.byType(EditorScreen), findsOneWidget);
  });
}
