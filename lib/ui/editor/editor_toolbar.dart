// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';

List<MobileToolbarItem> buildDayzToolbarItems({
  required BuildContext context,
  required AppLocalizations l10n,
  required VoidCallback onImageTap,
}) {
  return [
    // H
    buildHeadingItem(l10n),
    // B
    buildTextDecorationItem(
      attributeName: AppFlowyRichTextKeys.bold,
      icon: AFMobileIcons.bold,
      semanticLabel: l10n.editorToolbarBold,
    ),
    // I
    buildTextDecorationItem(
      attributeName: AppFlowyRichTextKeys.italic,
      icon: AFMobileIcons.italic,
      semanticLabel: l10n.editorToolbarItalic,
    ),
    // U
    buildTextDecorationItem(
      attributeName: AppFlowyRichTextKeys.underline,
      icon: AFMobileIcons.underline,
      semanticLabel: l10n.editorToolbarUnderline,
    ),
    // S
    buildTextDecorationItem(
      attributeName: AppFlowyRichTextKeys.strikethrough,
      icon: AFMobileIcons.strikethrough,
      semanticLabel: l10n.editorToolbarStrikethrough,
    ),
    // Code
    buildTextDecorationItem(
      attributeName: AppFlowyRichTextKeys.code,
      icon: AFMobileIcons.code,
      semanticLabel: l10n.editorToolbarCode,
    ),
    // Color
    buildColorItem(l10n),
    // Bulleted list
    buildBulletedListItem(l10n),
    // Numbered list
    buildNumberedListItem(l10n),
    // Todo list
    buildTodoListItem(l10n),
    // Quote
    buildQuoteItem(l10n),
    // Link
    buildLinkItem(l10n),
    // Divider
    buildDividerItem(l10n),
    // Image
    buildImageItem(l10n, onImageTap),
  ];
}

bool _isAttributeActive(EditorState editorState, Selection selection, String attributeName) {
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

MobileToolbarItem buildTextDecorationItem({
  required String attributeName,
  required AFMobileIcons icon,
  required String semanticLabel,
}) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      final theme = MobileToolbarTheme.of(context);
      // Also rebuild on toggledStyle changes: with a collapsed caret, toggling
      // a decoration updates toggledStyle (the style for the next typed text)
      // without changing the selection. MobileToolbarV2 only rebuilds item
      // icons on selection changes, so without this the button would not light
      // up until text is actually selected/typed.
      return ListenableBuilder(
        listenable: editorState.toggledStyleNotifier,
        builder: (_, _) {
          final isSelected =
              _isAttributeActive(editorState, selection, attributeName);
          return Semantics(
            label: semanticLabel,
            child: AFMobileIcon(
              afMobileIcons: icon,
              color: isSelected ? theme.primaryColor : theme.iconColor,
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
      final isSelected = selection != null && _isHeadingActive(editorState, selection);
      final theme = MobileToolbarTheme.of(context);
      return Semantics(
        label: l10n.editorToolbarHeading,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.heading,
          color: isSelected ? theme.primaryColor : theme.iconColor,
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
      child: origin.itemIconBuilder!(context, editorState, service)!,
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
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == 'bulleted_list';
      final theme = MobileToolbarTheme.of(context);
      return Semantics(
        label: l10n.editorToolbarBulletedList,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.bulletedList,
          color: isSelected ? theme.primaryColor : theme.iconColor,
        ),
      );
    },
    actionHandler: (context, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == 'bulleted_list';
      editorState.formatNode(
        selection,
        (node) => node.copyWith(
          type: isSelected ? ParagraphBlockKeys.type : 'bulleted_list',
          attributes: {
            ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
          },
        ),
      );
    },
  );
}

MobileToolbarItem buildNumberedListItem(AppLocalizations l10n) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, editorState, _) {
      final selection = editorState.selection;
      if (selection == null) return null;
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == 'numbered_list';
      final theme = MobileToolbarTheme.of(context);
      return Semantics(
        label: l10n.editorToolbarNumberedList,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.numberedList,
          color: isSelected ? theme.primaryColor : theme.iconColor,
        ),
      );
    },
    actionHandler: (context, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == 'numbered_list';
      editorState.formatNode(
        selection,
        (node) => node.copyWith(
          type: isSelected ? ParagraphBlockKeys.type : 'numbered_list',
          attributes: {
            ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
          },
        ),
      );
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
      final theme = MobileToolbarTheme.of(context);
      return Semantics(
        label: l10n.editorToolbarTodoList,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.checkbox,
          color: isSelected ? theme.primaryColor : theme.iconColor,
        ),
      );
    },
    actionHandler: (context, editorState) {
      final selection = editorState.selection;
      if (selection == null) return;
      final node = editorState.getNodeAtPath(selection.start.path);
      final isSelected = node?.type == TodoListBlockKeys.type;
      editorState.formatNode(
        selection,
        (node) => node.copyWith(
          type: isSelected ? ParagraphBlockKeys.type : TodoListBlockKeys.type,
          attributes: {
            ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
          },
        ),
      );
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
      final theme = MobileToolbarTheme.of(context);
      return Semantics(
        label: l10n.editorToolbarQuote,
        child: AFMobileIcon(
          afMobileIcons: AFMobileIcons.quote,
          color: isSelected ? theme.primaryColor : theme.iconColor,
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

MobileToolbarItem buildImageItem(AppLocalizations l10n, VoidCallback onImageTap) {
  return MobileToolbarItem.action(
    itemIconBuilder: (context, _, _) {
      final theme = MobileToolbarTheme.of(context);
      return Semantics(
        label: l10n.editorToolbarImage,
        child: SvgPicture.string(
          _svg(DayzIcons.imagePath),
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            theme.iconColor,
            BlendMode.srcIn,
          ),
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
    final currentLevel =
        isHeading ? node?.attributes[HeadingBlockKeys.level] as int? : null;
    // Anything that is not a heading falls back to "body" — covers paragraphs
    // as well as list/quote blocks where switching to body is still valid.
    final isParagraph = !isHeading;

    final options = <_HeadingOption>[
      _HeadingOption(
        glyph: widget.l10n.editorHeadingParagraphGlyph,
        glyphSize: 17,
        label: widget.l10n.editorHeadingParagraphLabel,
        level: null,
        selected: isParagraph,
      ),
      _HeadingOption(
        glyph: 'H1',
        glyphSize: 23,
        label: widget.l10n.editorHeadingLabelH1,
        level: 1,
        selected: currentLevel == 1,
      ),
      _HeadingOption(
        glyph: 'H2',
        glyphSize: 20,
        label: widget.l10n.editorHeadingLabelH2,
        level: 2,
        selected: currentLevel == 2,
      ),
      _HeadingOption(
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
    required this.glyph,
    required this.glyphSize,
    required this.label,
    required this.level,
    required this.selected,
  });

  final String glyph;
  final double glyphSize;
  final String label;
  final int? level;
  final bool selected;
}
