// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/blocks/callout_block.dart';
import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:dayz/ui/editor/editor_style.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('CalloutBlockComponentBuilder', () {
    test(
      'callout nodes keep text in native delta and validate as text blocks',
      () {
        final node = calloutNode(text: '记得复盘');
        final builder = CalloutBlockComponentBuilder();

        expect(node.type, EditorBlockTypes.callout);
        expect(node.delta?.toPlainText(), '记得复盘');
        expect(builder.validate(node), isTrue);
        expect(builder.validate(Node(type: EditorBlockTypes.callout)), isFalse);
      },
    );

    test('codec preserves callout type and delta text byte-for-byte', () {
      final document = Document(
        root: pageNode(children: [calloutNode(text: '记得复盘')]),
      );

      final decoded = EditorDocCodec.decode(
        EditorDocCodec.encode(document),
      ).document;
      final decodedNode = decoded.root.children.single;

      expect(decodedNode.type, EditorBlockTypes.callout);
      expect(decodedNode.delta?.toPlainText(), '记得复盘');
    });

    test('editable and readonly registries expose the callout builder', () {
      expect(
        EditorBlockRegistry.editableBuilders()[EditorBlockTypes.callout],
        isA<CalloutBlockComponentBuilder>(),
      );
      expect(
        EditorBlockRegistry.readonlyBuilders()[EditorBlockTypes.callout],
        isA<CalloutBlockComponentBuilder>(),
      );
    });

    testWidgets('renders with DayZ theme tokens and no left border', (
      tester,
    ) async {
      await _pumpCalloutEditor(tester, theme: DayzThemes.amberDark);
      _expectCalloutTheme(tester, DayzColors.amberDark);

      await _pumpCalloutEditor(tester, theme: DayzThemes.sageLight);
      _expectCalloutTheme(tester, DayzColors.sageLight);
    });

    test('builder default block padding mirrors .cb-callout margin', () {
      final node = calloutNode(text: '记得复盘');

      expect(
        CalloutBlockComponentBuilder().configuration.padding(node),
        const EdgeInsets.symmetric(vertical: DayzSpacing.s4),
      );
      expect(
        (EditorBlockRegistry.editableBuilders()[EditorBlockTypes.callout]!)
            .configuration
            .padding(node),
        const EdgeInsets.symmetric(vertical: DayzSpacing.s4),
      );

      final custom = CalloutBlockComponentBuilder(
        configuration: BlockComponentConfiguration(
          padding: (_) => EdgeInsets.zero,
        ),
      );
      expect(custom.configuration.padding(node), EdgeInsets.zero);
    });

    testWidgets('readonly callout keeps the same .cb-callout geometry', (
      tester,
    ) async {
      await _pumpCalloutEditor(
        tester,
        theme: DayzThemes.purpleLight,
        readOnly: true,
      );
      _expectCalloutTheme(tester, DayzColors.purpleLight);
    });

    testWidgets('decoded callouts render through the registry, not fallback', (
      tester,
    ) async {
      final document = Document(
        root: pageNode(children: [calloutNode(text: '记得复盘')]),
      );
      final decoded = EditorDocCodec.decode(
        EditorDocCodec.encode(document),
      ).document;

      await _pumpCalloutEditor(
        tester,
        theme: DayzThemes.amberDark,
        document: decoded,
        readOnly: true,
      );

      expect(find.textContaining('记得复盘', findRichText: true), findsOneWidget);
      expect(find.textContaining('[未支持块]', findRichText: true), findsNothing);
    });
  });
}

Future<void> _pumpCalloutEditor(
  WidgetTester tester, {
  required ThemeData theme,
  Document? document,
  bool readOnly = false,
}) async {
  final editorState = EditorState(
    document:
        document ??
        Document(
          root: pageNode(children: [calloutNode(text: '记得复盘')]),
        ),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return AppFlowyEditor(
              editorState: editorState,
              editable: !readOnly,
              disableKeyboardService: readOnly,
              disableSelectionService: readOnly,
              blockComponentBuilders: readOnly
                  ? EditorBlockRegistry.readonlyBuilders()
                  : EditorBlockRegistry.editableBuilders(),
              editorStyle: dayzEditorStyle(context),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectCalloutTheme(WidgetTester tester, DayzColors colors) {
  final calloutFinder = find.byType(CalloutBlockComponentWidget);
  expect(calloutFinder, findsOneWidget);
  expect(find.textContaining('记得复盘', findRichText: true), findsOneWidget);

  // `.cb-callout .ic`：DayzIcons.callout，20px，--accent-ink；不得回落 Icons.*。
  final icon = tester.widget<DayzIcon>(
    find.descendant(of: calloutFinder, matching: find.byType(DayzIcon)),
  );
  expect(icon.markup, DayzIcons.callout);
  expect(icon.size, 20);
  expect(icon.color, colors.accentInk);
  expect(
    find.descendant(of: calloutFinder, matching: find.byType(Icon)),
    findsNothing,
  );

  final container = tester
      .widgetList<Container>(
        find.descendant(of: calloutFinder, matching: find.byType(Container)),
      )
      .singleWhere(
        (container) =>
            container.decoration is BoxDecoration &&
            (container.decoration! as BoxDecoration).color == colors.accentSoft,
      );
  final decoration = container.decoration! as BoxDecoration;

  expect(decoration.color, colors.accentSoft);
  expect(decoration.borderRadius, BorderRadius.circular(DayzRadii.md));
  expect(decoration.border, isNull);
  expect(
    container.padding,
    const EdgeInsets.symmetric(
      vertical: DayzSpacing.s3,
      horizontal: DayzSpacing.s4,
    ),
  );

  // `.cb-callout { gap: var(--sp-3) }`：图标与正文之间的间距。
  final gaps = tester
      .widgetList<SizedBox>(
        find.descendant(of: calloutFinder, matching: find.byType(SizedBox)),
      )
      .where((box) => box.width == DayzSpacing.s3 && box.height == null);
  expect(gaps, isNotEmpty);

  final richTextHasInk = tester
      .widgetList<RichText>(find.byType(RichText))
      .any(
        (richText) => _spanTreeContains(
          richText.text,
          (span) =>
              span.toPlainText().contains('记得复盘') &&
              span.style?.color == colors.ink,
        ),
      );
  expect(richTextHasInk, isTrue);
}

bool _spanTreeContains(
  InlineSpan span,
  bool Function(TextSpan span) predicate,
) {
  if (span is TextSpan && predicate(span)) {
    return true;
  }
  final children = span is TextSpan ? span.children : null;
  if (children == null) {
    return false;
  }
  return children.any((child) => _spanTreeContains(child, predicate));
}
