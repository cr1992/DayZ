// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

Widget _routerTestApp() => localizedRouterTestApp(routerConfig: appRouter);

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('Editor route test', () {
    testWidgets('Routes.editor parses to EditorScreen', (tester) async {
      await tester.pumpWidget(_routerTestApp());
      await tester.pumpAndSettle();

      appRouter.goNamed(Routes.editor);
      await tester.pumpAndSettle();

      expect(find.byType(EditorScreen), findsOneWidget);
    });

    testWidgets('Routes.editorPath parses to EditorScreen', (tester) async {
      await tester.pumpWidget(_routerTestApp());
      await tester.pumpAndSettle();

      appRouter.go(Routes.editorPath);
      await tester.pumpAndSettle();

      expect(find.byType(EditorScreen), findsOneWidget);
    });

    testWidgets('Routes.editor accepts a structured Map extra', (tester) async {
      await tester.pumpWidget(_routerTestApp());
      await tester.pumpAndSettle();

      appRouter.goNamed(
        Routes.editor,
        extra: <String, dynamic>{
          'mode': EditorScreenMode.writing,
          'entryDate': DateTime(2026, 5, 29),
          'title': 'Hello',
          'entryId': 'entry-1',
        },
      );
      await tester.pumpAndSettle();

      final screen = tester.widget<EditorScreen>(find.byType(EditorScreen));
      expect(screen.mode, EditorScreenMode.writing);
      expect(screen.entryId, 'entry-1');
      expect(screen.title, 'Hello');
    });

    testWidgets('Routes.editor tolerates a bare String extra (no crash)', (
      tester,
    ) async {
      await tester.pumpWidget(_routerTestApp());
      await tester.pumpAndSettle();

      // A String extra used to throw _TypeError on the Map cast. It must now
      // be treated as an entryId opened for editing.
      appRouter.goNamed(Routes.editor, extra: 'entry_123');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final screen = tester.widget<EditorScreen>(find.byType(EditorScreen));
      expect(screen.entryId, 'entry_123');
      expect(screen.mode, EditorScreenMode.writing);
    });
  });
}
