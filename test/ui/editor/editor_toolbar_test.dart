// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/toolbar/mobile/utils/keyboard_height_observer.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_toolbar.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('EditorToolbar', () {
    testWidgets('renders MobileToolbarV2 with the 8-item dock', (tester) async {
      final state = await _pumpEditorWithSelection(tester);

      expect(find.byType(MobileToolbarV2), findsOneWidget);

      final dockLabels = <String>[
        state.l10n.editorToolbarFormat,
        state.l10n.editorToolbarBold,
        state.l10n.editorToolbarItalic,
        state.l10n.editorToolbarColor,
        state.l10n.editorToolbarBulletedList,
        state.l10n.editorToolbarNumberedList,
        state.l10n.editorToolbarTodoList,
        state.l10n.editorToolbarImage,
      ];

      for (final label in dockLabels) {
        expect(
          _toolbarButton(label),
          findsOneWidget,
          reason: 'Failed to find toolbar item: $label',
        );
      }

      final menuOnlyLabels = <String>[
        state.l10n.editorToolbarUnderline,
        state.l10n.editorToolbarStrikethrough,
        state.l10n.editorToolbarCode,
        state.l10n.editorToolbarQuote,
        state.l10n.editorToolbarLink,
        state.l10n.editorToolbarDivider,
      ];

      for (final label in menuOnlyLabels) {
        expect(
          _toolbarButton(label),
          findsNothing,
          reason: '$label should be inside the Aa format panel, not the dock',
        );
      }
    });

    testWidgets(
      'Bold item toggles active color when selection bold state changes',
      (tester) async {
        final state = await _pumpEditorWithSelection(tester);
        final l10n = state.l10n;
        final editorState = state.editorState;
        final colors = state.colors;

        // Helper to find the color of the bold icon inside toolbar
        // Dock 加粗钮现为字母文本（设计稿），读其 Text 颜色而非 AFMobileIcon。
        Finder findBoldGlyph() {
          return find.descendant(
            of: find.descendant(
              of: find.byType(IconButton),
              matching: find.bySemanticsLabel(l10n.editorToolbarBold),
            ),
            matching: find.byType(Text),
          );
        }

        // 1. Initial State: Bold is not active
        var color = tester.widget<Text>(findBoldGlyph()).style?.color;
        expect(color, colors.ink2);

        // 2. Toggle Bold style on
        await tester.runAsync(() async {
          editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
        });
        await tester.pumpAndSettle();

        color = tester.widget<Text>(findBoldGlyph()).style?.color;
        expect(color, colors.accentInk);

        // 3. Toggle Bold style off
        await tester.runAsync(() async {
          editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
        });
        await tester.pumpAndSettle();

        color = tester.widget<Text>(findBoldGlyph()).style?.color;
        expect(color, colors.ink2);
      },
    );

    testWidgets('does not flat viewInsets.bottom manually', (tester) async {
      final editorState = _createEditorState();
      addTearDown(editorState.dispose);
      editorState.selection = Selection.collapsed(Position(path: [0]));

      // Pump with 0 bottom inset
      await tester.pumpWidget(
        localizedTestApp(
          child: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.zero),
            child: _ToolbarHarness(editorState: editorState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contentFinder = find.byKey(_ToolbarHarness.contentKey);
      final initialTopLeft = tester.getTopLeft(contentFinder);

      // Pump with 300 bottom inset
      await tester.pumpWidget(
        localizedTestApp(
          child: MediaQuery(
            data: const MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: _ToolbarHarness(editorState: editorState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final afterTopLeft = tester.getTopLeft(contentFinder);

      // The main view itself should not manually translate or shift its top-left coordinates.
      expect(afterTopLeft, initialTopLeft);
    });

    testWidgets(
      'every dock toolbar item hit test target is at least 44 square',
      (tester) async {
        final state = await _pumpEditorWithSelection(tester);

        final itemLabels = [
          state.l10n.editorToolbarFormat,
          state.l10n.editorToolbarBold,
          state.l10n.editorToolbarItalic,
          state.l10n.editorToolbarColor,
          state.l10n.editorToolbarBulletedList,
          state.l10n.editorToolbarNumberedList,
          state.l10n.editorToolbarTodoList,
          state.l10n.editorToolbarImage,
        ];

        for (final label in itemLabels) {
          final finder = _toolbarButton(label);
          expect(
            finder,
            findsOneWidget,
            reason: 'No IconButton for label: $label',
          );
          final size = tester.getSize(finder);
          expect(size.width, greaterThanOrEqualTo(44));
          expect(size.height, greaterThanOrEqualTo(44));
        }
      },
    );

    testWidgets('dock chrome follows editor-dock token parameters', (
      tester,
    ) async {
      final state = await _pumpEditorWithSelection(tester);

      final toolbar = tester.widget<MobileToolbarV2>(
        find.byType(MobileToolbarV2),
      );

      expect(toolbar.backgroundColor, state.colors.surface);
      expect(toolbar.foregroundColor, state.colors.ink2);
      expect(toolbar.iconColor, state.colors.ink2);
      expect(toolbar.itemHighlightColor, state.colors.accentSoft);
      expect(toolbar.itemOutlineColor, state.colors.hairline);
      expect(toolbar.outlineColor, state.colors.hairline);
      expect(toolbar.toolbarHeight, 52);
      expect(toolbar.buttonHeight, 44);
      expect(toolbar.buttonSpacing, 3);
      expect(toolbar.borderRadius, 10);
      expect(toolbar.showKeyboardDismissButton, isFalse);
    });

    testWidgets('all 8 dock actions are visible on a 390-wide viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _pumpEditorWithSelection(tester);

      final screenRight = tester.view.physicalSize.width;
      for (final label in [
        state.l10n.editorToolbarFormat,
        state.l10n.editorToolbarBold,
        state.l10n.editorToolbarItalic,
        state.l10n.editorToolbarColor,
        state.l10n.editorToolbarBulletedList,
        state.l10n.editorToolbarNumberedList,
        state.l10n.editorToolbarTodoList,
        state.l10n.editorToolbarImage,
      ]) {
        final rect = tester.getRect(_toolbarButton(label));
        expect(
          rect.right,
          lessThanOrEqualTo(screenRight),
          reason: '$label should be visible without horizontal scrolling',
        );
      }
    });

    testWidgets('dock group dividers follow editor-dock geometry', (
      tester,
    ) async {
      await _pumpEditorWithSelection(tester);

      for (final id in ['format', 'color', 'todo']) {
        final divider = find.byKey(
          ValueKey<String>('editor-toolbar-dock-divider-$id'),
        );
        expect(divider, findsOneWidget);
        expect(tester.getSize(divider).width, 1);
        expect(tester.getSize(divider).height, 22);
      }
    });

    testWidgets('Aa format panel exposes three sections and Body/H1/H2/H3', (
      tester,
    ) async {
      final state = await _pumpEditorWithSelection(tester);
      await _openFormatPanel(tester, state.l10n);

      final panel = _formatPanel();
      expect(
        find.descendant(
          of: panel,
          matching: find.text(state.l10n.editorFormatSectionParagraph),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(state.l10n.editorFormatSectionBlocks),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(state.l10n.editorFormatSectionText),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(state.l10n.editorHeadingParagraphGlyph),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text(state.l10n.editorHeadingParagraphLabel),
        ),
        findsWidgets,
      );
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('H3'), findsOneWidget);
      expect(find.text(state.l10n.editorHeadingLabelH1), findsOneWidget);

      for (final item in [
        _PanelItem('bulleted-list', state.l10n.editorToolbarBulletedList),
        _PanelItem('numbered-list', state.l10n.editorToolbarNumberedList),
        _PanelItem('todo-list', state.l10n.editorToolbarTodoList),
        _PanelItem('quote', state.l10n.editorToolbarQuote),
        _PanelItem('callout', state.l10n.editorToolbarCallout),
        _PanelItem('divider', state.l10n.editorToolbarDivider),
        _PanelItem('bold', state.l10n.editorToolbarBold),
        _PanelItem('italic', state.l10n.editorToolbarItalic),
        _PanelItem('underline', state.l10n.editorToolbarUnderline),
        _PanelItem('strikethrough', state.l10n.editorToolbarStrikethrough),
        _PanelItem('code', state.l10n.editorToolbarCode),
        _PanelItem('link', state.l10n.editorToolbarLink),
      ]) {
        expect(_menuItem(item.id), findsOneWidget);
        expect(_semanticsLabel(tester, _menuItem(item.id)), item.label);
      }
    });

    testWidgets('color menu shows DayZ warm swatches, not Material defaults', (
      tester,
    ) async {
      final state = await _pumpEditorWithSelection(tester);
      final l10n = state.l10n;

      // Open the color menu from the toolbar.
      await tester.tap(
        find.ancestor(
          of: find.bySemanticsLabel(l10n.editorToolbarColor),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      // Text-color swatches render their DayZ names (ColorButton draws the
      // name as colored text). Spot-check both ends of the warm palette.
      expect(find.text(l10n.editorColorTextRust), findsOneWidget);
      expect(find.text(l10n.editorColorTextLilac), findsOneWidget);
    });

    testWidgets('format panel cells follow design dimensions', (tester) async {
      final state = await _pumpEditorWithSelection(tester);
      await _openFormatPanel(tester, state.l10n);

      for (final id in [
        'bulleted-list',
        'numbered-list',
        'todo-list',
        'quote',
        'callout',
        'divider',
      ]) {
        expect(tester.getSize(_menuItem(id)).height, 46);
      }

      final markIds = [
        'bold',
        'italic',
        'underline',
        'strikethrough',
        'code',
        'link',
      ];
      final markRects = [
        for (final id in markIds) tester.getRect(_menuItem(id)),
      ];
      final first = markRects.first;
      for (final rect in markRects) {
        expect(rect.top, closeTo(first.top, 0.01));
        expect(rect.height, 44);
        expect(rect.width, closeTo(first.width, 0.01));
      }
    });

    testWidgets(
      'paragraph and block format selections are mutually exclusive',
      (tester) async {
        final state = await _pumpEditorWithSelection(tester);

        await tester.tap(_toolbarButton(state.l10n.editorToolbarBulletedList));
        await tester.pumpAndSettle();
        expect(_currentNodeType(state.editorState), BulletedListBlockKeys.type);

        await _openFormatPanel(tester, state.l10n);
        expect(_menuItem('bulleted-list'), findsOneWidget);

        await _tapMenuItem(tester, 'paragraph');

        expect(_currentNodeType(state.editorState), ParagraphBlockKeys.type);
        expect(_menuIconColor(tester, 'bulleted-list'), state.colors.ink2);
      },
    );

    testWidgets('dock and Aa panel keep list and text-style state in sync', (
      tester,
    ) async {
      final state = await _pumpEditorWithSelection(tester);

      await tester.tap(_toolbarButton(state.l10n.editorToolbarBulletedList));
      await tester.pumpAndSettle();
      expect(_currentNodeType(state.editorState), BulletedListBlockKeys.type);

      await _openFormatPanel(tester, state.l10n);
      expect(_menuIconColor(tester, 'bulleted-list'), state.colors.accentInk);

      await _tapMenuItem(tester, 'bold');
      expect(
        _toolbarIconColor(tester, state.l10n.editorToolbarBold),
        state.colors.accentInk,
      );

      await _tapMenuItem(tester, 'italic');
      expect(
        _toolbarIconColor(tester, state.l10n.editorToolbarItalic),
        state.colors.accentInk,
      );
    });

    testWidgets(
      'link lives in the text-style section and opens a single URL menu',
      (tester) async {
        final state = await _pumpEditorWithSelection(tester);

        expect(_toolbarButton(state.l10n.editorToolbarLink), findsNothing);

        await _openFormatPanel(tester, state.l10n);
        await _tapMenuItem(tester, 'link');

        expect(find.byType(MobileLinkMenu), findsOneWidget);
        expect(find.widgetWithText(TextField, 'URL'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(MobileLinkMenu),
            matching: find.byType(TextField),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('format panel follows keyboard height with 288 minimum', (
      tester,
    ) async {
      final state = await _pumpEditorWithSelection(
        tester,
        viewInsets: const EdgeInsets.only(bottom: 360),
      );

      await _openFormatPanel(tester, state.l10n);

      final panelFinder = find.byKey(EditorToolbarKeys.formatPanelKey);
      expect(panelFinder, findsOneWidget);
      expect(tester.getSize(panelFinder).height, greaterThanOrEqualTo(360));
    });

    testWidgets('format panel caps at 62vh', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _pumpEditorWithSelection(
        tester,
        viewInsets: const EdgeInsets.only(bottom: 600),
      );
      await _openFormatPanel(tester, state.l10n);

      final panelFinder = find.byKey(EditorToolbarKeys.formatPanelKey);
      expect(panelFinder, findsOneWidget);
      expect(tester.getSize(panelFinder).height, closeTo(844 * 0.62, 0.01));
    });

    testWidgets('Bold lights up when toggled with a collapsed caret', (
      tester,
    ) async {
      final state = await _pumpEditorWithSelection(tester);
      final l10n = state.l10n;
      final colors = state.colors;
      final editorState = state.editorState;

      // Collapsed caret (no range) — the case that used to leave the button dark.
      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 2),
      );
      await tester.pumpAndSettle();

      Finder boldGlyph() => find.descendant(
        of: find.descendant(
          of: find.byType(IconButton),
          matching: find.bySemanticsLabel(l10n.editorToolbarBold),
        ),
        matching: find.byType(Text),
      );

      expect(tester.widget<Text>(boldGlyph()).style?.color, colors.ink2);

      await tester.tap(
        find.ancestor(
          of: find.bySemanticsLabel(l10n.editorToolbarBold),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      // Toggling on a collapsed caret records the style in toggledStyle; the
      // button must light up immediately (it used to stay dark because the
      // toolbar only rebuilt item icons on selection changes).
      expect(tester.widget<Text>(boldGlyph()).style?.color, colors.accentInk);
      expect(
        editorState.toggledStyle.containsKey(AppFlowyRichTextKeys.bold),
        isTrue,
      );
    });

    testWidgets('decoration buttons reflect the caret context and stack', (
      tester,
    ) async {
      final state = await _pumpEditorWithSelection(tester);
      final l10n = state.l10n;
      final colors = state.colors;
      final editorState = state.editorState;

      // Make 'hello' both bold and italic.
      editorState.selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [0], offset: 5),
      );
      await tester.pumpAndSettle();
      editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
      await tester.pumpAndSettle();
      editorState.toggleAttribute(AppFlowyRichTextKeys.italic);
      await tester.pumpAndSettle();

      // Collapse the caret INSIDE the styled run (no toggledStyle in play):
      // the bold + italic buttons must both stay lit (stacked), underline must
      // not — reflecting the style newly-typed text would inherit there.
      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 3),
      );
      await tester.pumpAndSettle();

      await _openFormatPanel(tester, l10n);

      expect(_menuIconColor(tester, 'bold'), colors.accentInk);
      expect(_menuIconColor(tester, 'italic'), colors.accentInk);
      expect(_menuIconColor(tester, 'underline'), colors.ink2);
    });
  });
}

class _ToolbarState {
  const _ToolbarState({
    required this.l10n,
    required this.editorState,
    required this.colors,
  });

  final AppLocalizations l10n;
  final EditorState editorState;
  final DayzColors colors;
}

class _PanelItem {
  const _PanelItem(this.id, this.label);

  final String id;
  final String label;
}

Future<_ToolbarState> _pumpEditorWithSelection(
  WidgetTester tester, {
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  final editorState = _createEditorState();
  addTearDown(editorState.dispose);
  addTearDown(() => KeyboardHeightObserver.instance.notify(0));
  editorState.selection = Selection(
    start: Position(path: [0], offset: 0),
    end: Position(path: [0], offset: 5),
  );

  await tester.pumpWidget(
    localizedTestApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: viewInsets),
          child: child!,
        );
      },
      child: _ToolbarHarness(editorState: editorState),
    ),
  );
  await tester.pumpAndSettle();
  KeyboardHeightObserver.instance.notify(360);
  await tester.pumpAndSettle();

  final harnessContext = tester.element(find.byType(_ToolbarHarness));
  return _ToolbarState(
    l10n: AppLocalizations.of(harnessContext),
    editorState: editorState,
    colors: harnessContext.dayz,
  );
}

EditorState _createEditorState() {
  return EditorState(
    document: Document(
      root: pageNode(children: [paragraphNode(text: 'hello')]),
    ),
  );
}

class _ToolbarHarness extends StatelessWidget {
  const _ToolbarHarness({required this.editorState});

  static const contentKey = ValueKey<String>('editor-toolbar-test-content');

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DayzEditorMobileToolbar(
      editorState: editorState,
      toolbarItems: buildDayzToolbarItems(
        context: context,
        l10n: l10n,
        onImageTap: () {},
      ),
      child: AppFlowyEditor(key: contentKey, editorState: editorState),
    );
  }
}

Finder _toolbarButton(String label) {
  return find.descendant(
    of: find.byType(IconButton),
    matching: find.bySemanticsLabel(label),
  );
}

Finder _formatPanel() {
  return find.byKey(EditorToolbarKeys.formatPanelKey);
}

Finder _menuItem(String id) {
  return find.byKey(EditorToolbarKeys.formatPanelItemKey(id));
}

Finder _menuButton(String id) {
  final item = _menuItem(id);
  final innerInkWell = find.descendant(
    of: item,
    matching: find.byType(InkWell),
  );
  if (innerInkWell.evaluate().isNotEmpty) {
    return innerInkWell.last;
  }

  return item;
}

Future<void> _tapMenuItem(WidgetTester tester, String id) async {
  final button = _menuButton(id);
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _openFormatPanel(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(_toolbarButton(l10n.editorToolbarFormat));
  await tester.pumpAndSettle();
}

String? _currentNodeType(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) return null;
  return editorState.getNodeAtPath(selection.start.path)?.type;
}

Color _toolbarIconColor(WidgetTester tester, String label) {
  // Dock 加粗/斜体现为字母文本（设计稿）；读其 Text 颜色。
  final glyph = find.descendant(
    of: _toolbarButton(label),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(glyph.first).style!.color!;
}

Color _menuIconColor(WidgetTester tester, String id) {
  final svgIcon = find.descendant(
    of: _menuButton(id),
    matching: find.byType(AFMobileIcon),
  );
  if (svgIcon.evaluate().isNotEmpty) {
    return tester.widget<AFMobileIcon>(svgIcon).color!;
  }
  final text = tester.widget<Text>(
    find.descendant(of: _menuButton(id), matching: find.byType(Text)).first,
  );
  return text.style!.color!;
}

String? _semanticsLabel(WidgetTester tester, Finder finder) {
  return tester.widget<Semantics>(finder).properties.label;
}
