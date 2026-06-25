// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math' as math;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';

abstract final class EditorToolbarKeys {
  static const Key formatPanelKey = ValueKey<String>(
    'editor-toolbar-format-panel',
  );

  static Key formatPanelItemKey(String id) {
    return ValueKey<String>('editor-toolbar-format-panel-item-$id');
  }

  static Key dockDividerKey(String id) {
    return ValueKey<String>('editor-toolbar-dock-divider-$id');
  }
}

class DayzEditorMobileToolbar extends StatelessWidget {
  const DayzEditorMobileToolbar({
    super.key,
    required this.editorState,
    required this.toolbarItems,
    required this.child,
  });

  final EditorState editorState;
  final List<MobileToolbarItem> toolbarItems;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;

    return MobileToolbarV2(
      editorState: editorState,
      toolbarItems: toolbarItems,
      backgroundColor: colors.surface,
      foregroundColor: colors.ink2,
      iconColor: colors.ink2,
      itemHighlightColor: colors.accentSoft,
      primaryColor: colors.accent,
      onPrimaryColor: colors.onAccent,
      itemOutlineColor: colors.hairline,
      outlineColor: colors.hairline,
      clearDiagonalLineColor: colors.danger,
      toolbarHeight: 52,
      buttonHeight: 44,
      buttonSpacing: 3,
      borderRadius: DayzRadii.sm,
      showKeyboardDismissButton: false,
      child: child,
    );
  }
}

List<MobileToolbarItem> buildDayzToolbarItems({
  required BuildContext context,
  required AppLocalizations l10n,
  required VoidCallback onImageTap,
}) {
  return [
    buildFormatItem(l10n),
    buildTextDecorationItem(
      attributeName: AppFlowyRichTextKeys.bold,
      icon: AFMobileIcons.bold,
      semanticLabel: l10n.editorToolbarBold,
    ),
    buildTextDecorationItem(
      attributeName: AppFlowyRichTextKeys.italic,
      icon: AFMobileIcons.italic,
      semanticLabel: l10n.editorToolbarItalic,
    ),
    buildColorItem(l10n),
    buildBulletedListItem(l10n),
    buildNumberedListItem(l10n),
    buildTodoListItem(l10n),
    buildImageItem(l10n, onImageTap),
  ];
}

const _toolbarSelectionExtraInfo = {
  selectionExtraInfoDoNotAttachTextService: true,
};

Color _toolbarItemColor(BuildContext context, {required bool selected}) {
  final colors = context.dayz;
  return selected ? colors.accentInk : colors.ink2;
}

Widget _toolbarItemFrame(
  BuildContext context, {
  required Widget child,
  String? dividerAfter,
}) {
  return SizedBox.square(
    dimension: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Center(child: child),
        if (dividerAfter != null)
          PositionedDirectional(
            end: 0,
            top: 11,
            bottom: 11,
            child: SizedBox(
              key: EditorToolbarKeys.dockDividerKey(dividerAfter),
              width: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.dayz.hairline2),
              ),
            ),
          ),
      ],
    ),
  );
}

MobileToolbarItem buildFormatItem(AppLocalizations l10n) {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      final active =
          _isHeadingActive(editorState, selection) ||
          _currentNodeType(editorState, selection) != ParagraphBlockKeys.type ||
          _isAttributeActive(
            editorState,
            selection,
            AppFlowyRichTextKeys.bold,
          ) ||
          _isAttributeActive(
            editorState,
            selection,
            AppFlowyRichTextKeys.italic,
          );
      return Semantics(
        label: l10n.editorToolbarFormat,
        child: _toolbarItemFrame(
          context,
          dividerAfter: 'format',
          child: ExcludeSemantics(
            child: Text(
              'Aa',
              style: context.dayzText.body.copyWith(
                fontFamily: context.dayzText.h2.fontFamily,
                fontFamilyFallback: context.dayzText.h2.fontFamilyFallback,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1,
                color: _toolbarItemColor(context, selected: active),
              ),
            ),
          ),
        ),
      );
    },
    itemMenuBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return const SizedBox.shrink();
      return _DayzFormatPanel(
        editorState: editorState,
        selection: selection,
        l10n: l10n,
      );
    },
  );
}

bool _isAttributeActive(
  EditorState editorState,
  Selection selection,
  String attributeName,
) {
  if (selection.isCollapsed) {
    // Reflect the style that newly-typed text would actually receive at the
    // caret, so the button stays lit while the caret sits inside styled text
    // (not only for the single tap before typing). This mirrors what
    // Transaction.insertText applies: the sliced attributes of the adjacent
    // character, with any pending toggledStyle layered on top. Each decoration
    // is checked independently, so stacked styles (B/I/U…) all light up.
    final delta = editorState.getNodeAtPath(selection.start.path)?.delta;
    final effective = <String, dynamic>{
      ...?delta?.sliceAttributes(selection.startIndex),
      ...editorState.toggledStyle,
    };
    return effective[attributeName] == true;
  }
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(selection, (delta) {
    return delta.everyAttributes(
      (attributes) => attributes[attributeName] == true,
    );
  });
}

String? _currentNodeType(EditorState editorState, Selection selection) {
  return editorState.getNodeAtPath(selection.start.path)?.type;
}

bool _isNodeTypeActive(
  EditorState editorState,
  Selection selection,
  String type,
) {
  return _currentNodeType(editorState, selection) == type;
}

Future<void> _toggleNodeType(
  EditorState editorState,
  Selection selection,
  String type,
) {
  final current = editorState.getNodeAtPath(selection.start.path);
  final isSelected = current?.type == type;
  return editorState.formatNode(
    selection,
    (node) => node.copyWith(
      type: isSelected ? ParagraphBlockKeys.type : type,
      attributes: _attributesForNodeType(
        node,
        isSelected ? ParagraphBlockKeys.type : type,
      ),
    ),
    selectionExtraInfo: _toolbarSelectionExtraInfo,
  );
}

Attributes _attributesForNodeType(Node node, String type) {
  final delta = (node.delta ?? Delta()).toJson();
  final background = node.attributes[blockComponentBackgroundColor];
  return {
    if (type != DividerBlockKeys.type) blockComponentDelta: delta,
    blockComponentBackgroundColor: ?background,
    if (type == TodoListBlockKeys.type) TodoListBlockKeys.checked: false,
    if (type == NumberedListBlockKeys.type) NumberedListBlockKeys.number: 1,
  };
}

Future<void> _toggleAttribute(
  EditorState editorState,
  Selection selection,
  String attributeName,
) {
  return editorState.toggleAttribute(
    attributeName,
    selectionExtraInfo: _toolbarSelectionExtraInfo,
  );
}

MobileToolbarItem buildTextDecorationItem({
  required String attributeName,
  required AFMobileIcons icon,
  required String semanticLabel,
}) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      // Also rebuild on toggledStyle changes: with a collapsed caret, toggling
      // a decoration updates toggledStyle (the style for the next typed text)
      // without changing the selection. MobileToolbarV2 only rebuilds item
      // icons on selection changes, so without this the button would not light
      // up until text is actually selected/typed.
      return ListenableBuilder(
        listenable: editorState.toggledStyleNotifier,
        builder: (_, _) {
          final isSelected = _isAttributeActive(
            editorState,
            selection,
            attributeName,
          );
          return Semantics(
            label: semanticLabel,
            child: AFMobileIcon(
              afMobileIcons: icon,
              color: _toolbarItemColor(context, selected: isSelected),
              size: 18,
            ),
          );
        },
      );
    },
    actionHandler: (_, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      editorState.toggleAttribute(
        attributeName,
        selectionExtraInfo: const {
          selectionExtraInfoDoNotAttachTextService: true,
        },
      );
    },
  );
}

MobileToolbarItem buildHeadingItem(AppLocalizations l10n) {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      final isSelected =
          selection != null && _isHeadingActive(editorState, selection);
      return Semantics(
        label: l10n.editorToolbarHeading,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.heading,
          color: _toolbarItemColor(context, selected: isSelected),
          size: 18,
        ),
      );
    },
    // AppFlowy's stock heading menu only offers H1/H2/H3 and relies on
    // re-tapping the active level to return to body text (not discoverable).
    // The design adds an explicit four-up menu (正文 · H1 · H2 · H3), so we
    // supply our own builder mirroring pages/screens/editor.html.
    itemMenuBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return const SizedBox.shrink();
      return _DayzHeadingMenu(
        editorState: editorState,
        selection: selection,
        l10n: l10n,
      );
    },
  );
}

bool _isHeadingActive(EditorState editorState, Selection selection) {
  if (selection.isCollapsed) {
    final node = editorState.getNodeAtPath(selection.start.path);
    return node?.type == HeadingBlockKeys.type;
  }
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.any((node) => node.type == HeadingBlockKeys.type);
}

MobileToolbarItem buildColorItem(AppLocalizations l10n) {
  // Feed the DayZ warm palette into AppFlowy's color menu (it exposes
  // textColorOptions / backgroundColorOptions hooks) — the inline keyboard
  // panel mode stays, only the swatches change. The "default ink" / "no
  // highlight" reset is supplied automatically by AppFlowy's ClearColorButton,
  // so the lists below carry just the 6 text + 5 highlight swatches.
  final origin = buildTextAndBackgroundColorMobileToolbarItem(
    textColorOptions: _dayzTextColorOptions(l10n),
    backgroundColorOptions: _dayzHighlightColorOptions(l10n),
  );
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, service) => Semantics(
      label: l10n.editorToolbarColor,
      child: _toolbarItemFrame(
        context,
        dividerAfter: 'color',
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.color,
          color: _toolbarItemColor(context, selected: false),
          size: 18,
        ),
      ),
    ),
    itemMenuBuilder: origin.itemMenuBuilder!,
  );
}

// DayZ warm text colors. Source of truth: docs/handoff/editor.md §2 +
// pages/assets/editor.js TEXT_COLORS. Opaque `font_color` (0xff + RRGGBB).
List<ColorOption> _dayzTextColorOptions(AppLocalizations l10n) => [
  ColorOption(colorHex: '0xffB5524B', name: l10n.editorColorTextRust),
  ColorOption(colorHex: '0xffC2772F', name: l10n.editorColorTextAmber),
  ColorOption(colorHex: '0xffB07D2A', name: l10n.editorColorTextBronze),
  ColorOption(colorHex: '0xff5E7F4E', name: l10n.editorColorTextOlive),
  ColorOption(colorHex: '0xff4E7A99', name: l10n.editorColorTextSlate),
  ColorOption(colorHex: '0xff7A6BA8', name: l10n.editorColorTextLilac),
];

// DayZ highlights. Source of truth: docs/handoff/editor.md §2. Translucent
// `bg_color` (0x40 ≈ 25% alpha over a saturated base) so a single value reads
// cleanly on both the light paper and the dark charcoal background.
List<ColorOption> _dayzHighlightColorOptions(AppLocalizations l10n) => [
  ColorOption(colorHex: '0x40E8C84A', name: l10n.editorColorHighlightYellow),
  ColorOption(colorHex: '0x4093C16E', name: l10n.editorColorHighlightGreen),
  ColorOption(colorHex: '0x405B9BD0', name: l10n.editorColorHighlightBlue),
  ColorOption(colorHex: '0x40967ED8', name: l10n.editorColorHighlightPurple),
  ColorOption(colorHex: '0x40D08A98', name: l10n.editorColorHighlightPink),
];

MobileToolbarItem buildBulletedListItem(AppLocalizations l10n) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      final isSelected = _isNodeTypeActive(
        editorState,
        selection,
        BulletedListBlockKeys.type,
      );
      return Semantics(
        label: l10n.editorToolbarBulletedList,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.bulletedList,
          color: _toolbarItemColor(context, selected: isSelected),
          size: 18,
        ),
      );
    },
    actionHandler: (context, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      _toggleNodeType(editorState, selection, BulletedListBlockKeys.type);
    },
  );
}

MobileToolbarItem buildNumberedListItem(AppLocalizations l10n) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      final isSelected = _isNodeTypeActive(
        editorState,
        selection,
        NumberedListBlockKeys.type,
      );
      return Semantics(
        label: l10n.editorToolbarNumberedList,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.numberedList,
          color: _toolbarItemColor(context, selected: isSelected),
          size: 18,
        ),
      );
    },
    actionHandler: (context, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      _toggleNodeType(editorState, selection, NumberedListBlockKeys.type);
    },
  );
}

MobileToolbarItem buildTodoListItem(AppLocalizations l10n) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == TodoListBlockKeys.type;
      return Semantics(
        label: l10n.editorToolbarTodoList,
        child: _toolbarItemFrame(
          context,
          dividerAfter: 'todo',
          child: AFMobileIcon(
            afMobileIcons: AFMobileIcons.checkbox,
            color: _toolbarItemColor(context, selected: isSelected),
            size: 18,
          ),
        ),
      );
    },
    actionHandler: (context, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      _toggleNodeType(editorState, selection, TodoListBlockKeys.type);
    },
  );
}

MobileToolbarItem buildQuoteItem(AppLocalizations l10n) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == QuoteBlockKeys.type;
      return Semantics(
        label: l10n.editorToolbarQuote,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.quote,
          color: _toolbarItemColor(context, selected: isSelected),
          size: 18,
        ),
      );
    },
    actionHandler: (context, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == QuoteBlockKeys.type;
      editorState.formatNode(
        selection,
        (node) => node.copyWith(
          type: isSelected ? ParagraphBlockKeys.type : QuoteBlockKeys.type,
          attributes: {
            ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
          },
        ),
      );
    },
  );
}

MobileToolbarItem buildLinkItem(AppLocalizations l10n) {
  final origin = linkMobileToolbarItem;
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, service) => Semantics(
      label: l10n.editorToolbarLink,
      child: origin.itemIconBuilder!(context, editorState, service)!,
    ),
    itemMenuBuilder: origin.itemMenuBuilder!,
  );
}

MobileToolbarItem buildDividerItem(AppLocalizations l10n) {
  final origin = dividerMobileToolbarItem;
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, service) => Semantics(
      label: l10n.editorToolbarDivider,
      child: origin.itemIconBuilder!(context, editorState, service)!,
    ),
    actionHandler: origin.actionHandler!,
  );
}

MobileToolbarItem buildImageItem(
  AppLocalizations l10n,
  VoidCallback onImageTap,
) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, _, _) {
      return Semantics(
        label: l10n.editorToolbarImage,
        child: SvgPicture.string(
          _svg(DayzIcons.imagePath),
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(context.dayz.ink2, BlendMode.srcIn),
        ),
      );
    },
    actionHandler: (context, editorState) {
      onImageTap();
    },
  );
}

String _svg(String path) {
  return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
}

class _DayzFormatPanel extends StatefulWidget {
  const _DayzFormatPanel({
    required this.editorState,
    required this.selection,
    required this.l10n,
  });

  final EditorState editorState;
  final Selection selection;
  final AppLocalizations l10n;

  @override
  State<_DayzFormatPanel> createState() => _DayzFormatPanelState();
}

class _DayzFormatPanelState extends State<_DayzFormatPanel> {
  bool _showLinkMenu = false;

  @override
  Widget build(BuildContext context) {
    final minPanelHeight = math.max(
      288.0,
      MediaQuery.of(context).viewInsets.bottom,
    );
    final maxPanelHeight = math.max(
      288.0,
      MediaQuery.sizeOf(context).height * 0.62,
    );
    final panelHeight = math.min(minPanelHeight, maxPanelHeight);

    return OverflowBox(
      alignment: Alignment.bottomCenter,
      minHeight: panelHeight,
      maxHeight: panelHeight,
      child: SizedBox(
        key: EditorToolbarKeys.formatPanelKey,
        height: panelHeight,
        child: _showLinkMenu ? _buildLinkMenu() : _buildFormatSections(context),
      ),
    );
  }

  Widget _buildFormatSections(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s2,
        DayzSpacing.s1,
        DayzSpacing.s2,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(widget.l10n.editorFormatSectionParagraph),
          const SizedBox(height: DayzSpacing.s3),
          _DayzHeadingMenu(
            editorState: widget.editorState,
            selection: widget.selection,
            l10n: widget.l10n,
          ),
          const SizedBox(height: DayzSpacing.s3),
          _SectionTitle(widget.l10n.editorFormatSectionBlocks),
          const SizedBox(height: DayzSpacing.s3),
          _buildBlockGrid(),
          const SizedBox(height: DayzSpacing.s3),
          _SectionTitle(widget.l10n.editorFormatSectionText),
          const SizedBox(height: DayzSpacing.s3),
          Row(
            children: [
              _InlineFormatButton(
                id: 'bold',
                editorState: widget.editorState,
                selection: widget.selection,
                label: widget.l10n.editorToolbarBold,
                icon: AFMobileIcons.bold,
                attributeName: AppFlowyRichTextKeys.bold,
              ),
              const SizedBox(width: DayzSpacing.s2),
              _InlineFormatButton(
                id: 'italic',
                editorState: widget.editorState,
                selection: widget.selection,
                label: widget.l10n.editorToolbarItalic,
                icon: AFMobileIcons.italic,
                attributeName: AppFlowyRichTextKeys.italic,
              ),
              const SizedBox(width: DayzSpacing.s2),
              _InlineFormatButton(
                id: 'underline',
                editorState: widget.editorState,
                selection: widget.selection,
                label: widget.l10n.editorToolbarUnderline,
                icon: AFMobileIcons.underline,
                attributeName: AppFlowyRichTextKeys.underline,
              ),
              const SizedBox(width: DayzSpacing.s2),
              _InlineFormatButton(
                id: 'strikethrough',
                editorState: widget.editorState,
                selection: widget.selection,
                label: widget.l10n.editorToolbarStrikethrough,
                icon: AFMobileIcons.strikethrough,
                attributeName: AppFlowyRichTextKeys.strikethrough,
              ),
              const SizedBox(width: DayzSpacing.s2),
              _InlineFormatButton(
                id: 'code',
                editorState: widget.editorState,
                selection: widget.selection,
                label: widget.l10n.editorToolbarCode,
                icon: AFMobileIcons.code,
                attributeName: AppFlowyRichTextKeys.code,
              ),
              const SizedBox(width: DayzSpacing.s2),
              Expanded(
                child: _TextStyleFormatButton(
                  itemKey: EditorToolbarKeys.formatPanelItemKey('link'),
                  label: widget.l10n.editorToolbarLink,
                  selected: _hasLinkAttribute(),
                  icon: AFMobileIcons.link,
                  onTap: () => setState(() => _showLinkMenu = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockGrid() {
    final blocks = [
      _NodeFormatSpec(
        id: 'bulleted-list',
        label: widget.l10n.editorToolbarBulletedList,
        icon: AFMobileIcons.bulletedList,
        type: BulletedListBlockKeys.type,
      ),
      _NodeFormatSpec(
        id: 'numbered-list',
        label: widget.l10n.editorToolbarNumberedList,
        icon: AFMobileIcons.numberedList,
        type: NumberedListBlockKeys.type,
      ),
      _NodeFormatSpec(
        id: 'todo-list',
        label: widget.l10n.editorToolbarTodoList,
        icon: AFMobileIcons.checkbox,
        type: TodoListBlockKeys.type,
      ),
      _NodeFormatSpec(
        id: 'quote',
        label: widget.l10n.editorToolbarQuote,
        icon: AFMobileIcons.quote,
        type: QuoteBlockKeys.type,
      ),
      _NodeFormatSpec(
        id: 'callout',
        label: widget.l10n.editorToolbarCallout,
        materialIcon: Icons.info_outline_rounded,
        type: EditorBlockTypes.callout,
      ),
      _NodeFormatSpec(
        id: 'divider',
        label: widget.l10n.editorToolbarDivider,
        icon: AFMobileIcons.divider,
        type: DividerBlockKeys.type,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: DayzSpacing.s2,
      crossAxisSpacing: DayzSpacing.s2,
      mainAxisExtent: 46,
      children: [
        for (final spec in blocks)
          _NodeFormatButton(
            editorState: widget.editorState,
            selection: widget.selection,
            spec: spec,
          ),
      ],
    );
  }

  Widget _buildLinkMenu() {
    final linkText = widget.editorState.getDeltaAttributeValueInSelection(
      AppFlowyRichTextKeys.href,
      widget.selection,
    );
    return MobileLinkMenu(
      editorState: widget.editorState,
      linkText: linkText,
      onSubmitted: (value) async {
        if (value.isNotEmpty) {
          await widget.editorState.formatDelta(widget.selection, {
            AppFlowyRichTextKeys.href: value,
          });
        }
        if (mounted) {
          setState(() => _showLinkMenu = false);
        }
      },
      onCancel: () => setState(() => _showLinkMenu = false),
    );
  }

  bool _hasLinkAttribute() {
    return widget.editorState
            .getDeltaAttributeValueInSelection(
              AppFlowyRichTextKeys.href,
              widget.selection,
            )
            ?.isNotEmpty ==
        true;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.dayzText.caption.copyWith(
        color: context.dayz.ink3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.24,
      ),
    );
  }
}

class _NodeFormatButton extends StatefulWidget {
  const _NodeFormatButton({
    required this.editorState,
    required this.selection,
    required this.spec,
  });

  final EditorState editorState;
  final Selection selection;
  final _NodeFormatSpec spec;

  @override
  State<_NodeFormatButton> createState() => _NodeFormatButtonState();
}

class _NodeFormatButtonState extends State<_NodeFormatButton> {
  @override
  Widget build(BuildContext context) {
    return _FormatPanelButton(
      itemKey: EditorToolbarKeys.formatPanelItemKey(widget.spec.id),
      label: widget.spec.label,
      selected: _isNodeTypeActive(
        widget.editorState,
        widget.selection,
        widget.spec.type,
      ),
      icon: widget.spec.icon,
      materialIcon: widget.spec.materialIcon,
      onTap: () async {
        await _toggleNodeType(
          widget.editorState,
          widget.selection,
          widget.spec.type,
        );
        if (mounted) setState(() {});
      },
    );
  }
}

class _InlineFormatButton extends StatefulWidget {
  const _InlineFormatButton({
    required this.id,
    required this.editorState,
    required this.selection,
    required this.label,
    required this.icon,
    required this.attributeName,
  });

  final String id;
  final EditorState editorState;
  final Selection selection;
  final String label;
  final AFMobileIcons icon;
  final String attributeName;

  @override
  State<_InlineFormatButton> createState() => _InlineFormatButtonState();
}

class _InlineFormatButtonState extends State<_InlineFormatButton> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListenableBuilder(
        listenable: widget.editorState.toggledStyleNotifier,
        builder: (context, _) {
          return _TextStyleFormatButton(
            itemKey: EditorToolbarKeys.formatPanelItemKey(widget.id),
            label: widget.label,
            selected: _isAttributeActive(
              widget.editorState,
              widget.selection,
              widget.attributeName,
            ),
            icon: widget.icon,
            onTap: () async {
              await _toggleAttribute(
                widget.editorState,
                widget.selection,
                widget.attributeName,
              );
              if (mounted) setState(() {});
            },
          );
        },
      ),
    );
  }
}

class _TextStyleFormatButton extends StatelessWidget {
  const _TextStyleFormatButton({
    required this.itemKey,
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final Key itemKey;
  final String label;
  final bool selected;
  final AFMobileIcons icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final foreground = selected ? colors.accentInk : colors.ink2;
    final radius = BorderRadius.circular(DayzRadii.md);

    return Semantics(
      key: itemKey,
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? colors.accentSoft : colors.bg,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? Colors.transparent : colors.hairline,
              ),
            ),
            child: Center(
              child: AFMobileIcon(
                afMobileIcons: icon,
                color: foreground,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatPanelButton extends StatelessWidget {
  const _FormatPanelButton({
    required this.itemKey,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.materialIcon,
  });

  final Key itemKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AFMobileIcons? icon;
  final IconData? materialIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final foreground = selected ? colors.accentInk : colors.ink2;

    Widget leading;
    if (icon != null) {
      leading = AFMobileIcon(afMobileIcons: icon!, color: foreground, size: 20);
    } else {
      leading = Icon(materialIcon, size: 20, color: foreground);
    }

    return Semantics(
      key: itemKey,
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? colors.accentSoft : colors.bg,
        borderRadius: BorderRadius.circular(DayzRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DayzRadii.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: DayzSpacing.s3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DayzRadii.md),
              border: Border.all(
                color: selected ? Colors.transparent : colors.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading,
                const SizedBox(width: DayzSpacing.s1),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: text.caption.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeFormatSpec {
  const _NodeFormatSpec({
    required this.id,
    required this.label,
    required this.type,
    this.icon,
    this.materialIcon,
  }) : assert(icon != null || materialIcon != null);

  final String id;
  final String label;
  final String type;
  final AFMobileIcons? icon;
  final IconData? materialIcon;
}

/// Heading panel matching the design's four equal options
/// (正文/段落 · H1/大标题 · H2/中标题 · H3/小标题). Real source:
/// `pages/screens/editor.html` `.tb-headings` + `pages/assets/editor.css`.
class _DayzHeadingMenu extends StatefulWidget {
  const _DayzHeadingMenu({
    required this.editorState,
    required this.selection,
    required this.l10n,
  });

  final EditorState editorState;
  final Selection selection;
  final AppLocalizations l10n;

  @override
  State<_DayzHeadingMenu> createState() => _DayzHeadingMenuState();
}

class _DayzHeadingMenuState extends State<_DayzHeadingMenu> {
  @override
  Widget build(BuildContext context) {
    final node = widget.editorState.getNodeAtPath(widget.selection.start.path);
    final isHeading = node?.type == HeadingBlockKeys.type;
    final currentLevel = isHeading
        ? node?.attributes[HeadingBlockKeys.level] as int?
        : null;
    // Anything that is not a heading falls back to "body" — covers paragraphs
    // as well as list/quote blocks where switching to body is still valid.
    final isParagraph = !isHeading;

    final options = <_HeadingOption>[
      _HeadingOption(
        id: 'paragraph',
        glyph: widget.l10n.editorHeadingParagraphGlyph,
        glyphSize: 17,
        label: widget.l10n.editorHeadingParagraphLabel,
        level: null,
        selected: isParagraph,
      ),
      _HeadingOption(
        id: 'heading-1',
        glyph: 'H1',
        glyphSize: 23,
        label: widget.l10n.editorHeadingLabelH1,
        level: 1,
        selected: currentLevel == 1,
      ),
      _HeadingOption(
        id: 'heading-2',
        glyph: 'H2',
        glyphSize: 20,
        label: widget.l10n.editorHeadingLabelH2,
        level: 2,
        selected: currentLevel == 2,
      ),
      _HeadingOption(
        id: 'heading-3',
        glyph: 'H3',
        glyphSize: 16,
        label: widget.l10n.editorHeadingLabelH3,
        level: 3,
        selected: currentLevel == 3,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: DayzSpacing.s2),
          Expanded(child: _buildOption(context, options[i])),
        ],
      ],
    );
  }

  Widget _buildOption(BuildContext context, _HeadingOption opt) {
    final colors = context.dayz;
    final text = context.dayzText;
    final glyphColor = opt.selected ? colors.accentInk : colors.ink;
    final labelColor = opt.selected ? colors.accentInk : colors.ink3;

    return Semantics(
      key: EditorToolbarKeys.formatPanelItemKey(opt.id),
      button: true,
      selected: opt.selected,
      label: opt.label,
      child: Material(
        color: opt.selected ? colors.accentSoft : colors.bg,
        borderRadius: BorderRadius.circular(DayzRadii.md),
        child: InkWell(
          onTap: () => _apply(opt),
          borderRadius: BorderRadius.circular(DayzRadii.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DayzRadii.md),
              border: Border.all(
                color: opt.selected ? Colors.transparent : colors.hairline,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  opt.glyph,
                  style: text.diary.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: opt.glyphSize,
                    color: glyphColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  opt.label,
                  style: text.body.copyWith(
                    fontSize: 11,
                    color: labelColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _apply(_HeadingOption opt) {
    final node = widget.editorState.getNodeAtPath(widget.selection.start.path);
    if (node == null) return;
    final delta = (node.delta ?? Delta()).toJson();
    final background = node.attributes[blockComponentBackgroundColor];
    setState(() {
      widget.editorState.formatNode(
        widget.selection,
        (n) => n.copyWith(
          type: opt.level == null
              ? ParagraphBlockKeys.type
              : HeadingBlockKeys.type,
          attributes: {
            if (opt.level != null) HeadingBlockKeys.level: opt.level,
            blockComponentBackgroundColor: background,
            ParagraphBlockKeys.delta: delta,
          },
        ),
        selectionExtraInfo: const {
          selectionExtraInfoDoNotAttachTextService: true,
        },
      );
    });
  }
}

class _HeadingOption {
  const _HeadingOption({
    required this.id,
    required this.glyph,
    required this.glyphSize,
    required this.label,
    required this.level,
    required this.selected,
  });

  final String id;
  final String glyph;
  final double glyphSize;
  final String label;
  final int? level;
  final bool selected;
}
