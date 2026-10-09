// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/toolbar/mobile/utils/keyboard_height_observer.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_toolbar.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

const _toolbarBoundaryKey = ValueKey<String>('editor-toolbar-visual-boundary');

void main() {
  setUpAll(() async {
    await AppFlowyEditorLocalizations.load(
      const Locale.fromSubtags(languageCode: 'zh'),
    );
  });

  patrolTest('editor toolbar shows 8-item dock and Aa format panel', ($) async {
    final editorState = EditorState(
      document: Document(
        root: pageNode(children: [paragraphNode(text: 'hello')]),
      ),
    );
    addTearDown(editorState.dispose);
    addTearDown(() => KeyboardHeightObserver.instance.notify(0));
    editorState.selection = Selection(
      start: Position(path: [0], offset: 0),
      end: Position(path: [0], offset: 5),
    );

    await $.pumpWidget(_ToolbarVisualHost(editorState: editorState));
    await $.pumpAndSettle();
    KeyboardHeightObserver.instance.notify(360);
    await $.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('zh'));
    for (final label in [
      l10n.editorToolbarFormat,
      l10n.editorToolbarBold,
      l10n.editorToolbarItalic,
      l10n.editorToolbarColor,
      l10n.editorToolbarBulletedList,
      l10n.editorToolbarNumberedList,
      l10n.editorToolbarTodoList,
      l10n.editorToolbarImage,
    ]) {
      expect(find.bySemanticsLabel(label), findsWidgets);
    }

    final dock = await _writeScreenshot($.tester, 'editor_toolbar_dock');
    $.log('Editor toolbar dock screenshot: ${dock.path}');

    await $.tester.tap(_toolbarButton(l10n.editorToolbarFormat));
    await $.pumpAndSettle();

    expect(find.byKey(EditorToolbarKeys.formatPanelKey), findsOneWidget);
    expect(find.text(l10n.editorFormatSectionParagraph), findsWidgets);
    expect(find.text(l10n.editorFormatSectionBlocks), findsOneWidget);
    expect(find.text(l10n.editorFormatSectionText), findsOneWidget);
    expect(
      find.byKey(EditorToolbarKeys.formatPanelItemKey('link')),
      findsOneWidget,
    );
    expect(
      find.byKey(EditorToolbarKeys.formatPanelItemKey('code')),
      findsOneWidget,
    );

    final panel = await _writeScreenshot(
      $.tester,
      'editor_toolbar_format_panel',
    );
    $.log('Editor toolbar format panel screenshot: ${panel.path}');

    expect(dock.lengthSync(), greaterThan(0));
    expect(panel.lengthSync(), greaterThan(0));
  });
}

class _ToolbarVisualHost extends StatelessWidget {
  const _ToolbarVisualHost({required this.editorState});

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DayzThemes.purpleLight,
      builder: (context, child) {
        return RepaintBoundary(key: _toolbarBoundaryKey, child: child);
      },
      home: Builder(
        builder: (context) {
          final colors = context.dayz;
          final l10n = AppLocalizations.of(context);

          return Scaffold(
            backgroundColor: colors.bg,
            body: DayzEditorMobileToolbar(
              editorState: editorState,
              toolbarItems: buildDayzToolbarItems(
                context: context,
                l10n: l10n,
                onImageTap: () {},
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 84, 24, 24),
                child: AppFlowyEditor(
                  editorState: editorState,
                  editorStyle: EditorStyle.mobile(
                    cursorColor: colors.accent,
                    selectionColor: colors.accentSoft2,
                    textStyleConfiguration: TextStyleConfiguration(
                      text: context.dayzText.diary.copyWith(color: colors.ink),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Finder _toolbarButton(String label) {
  return find.descendant(
    of: find.byType(IconButton),
    matching: find.bySemanticsLabel(label),
  );
}

Future<File> _writeScreenshot(WidgetTester tester, String name) async {
  await tester.pump();

  final boundary =
      tester.renderObject(find.byKey(_toolbarBoundaryKey))
          as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  final imageBytes = bytes!.buffer.asUint8List();
  final hostFile = File('/private/tmp/dayz-patrol-screenshots/$name.png');
  try {
    await hostFile.parent.create(recursive: true);
    await hostFile.writeAsBytes(imageBytes);
    return hostFile;
  } catch (_) {
    final containerRoot = Directory.systemTemp.parent;
    final dir = Directory(
      '${containerRoot.path}/Documents/dayz-patrol-screenshots',
    )..createSync(recursive: true);
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(imageBytes);
    return file;
  }
}
