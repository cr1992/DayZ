// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
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
    return editorState.toggledStyle.containsKey(attributeName);
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
      final isSelected = _isAttributeActive(editorState, selection, attributeName);
      final theme = MobileToolbarTheme.of(context);
      return Semantics(
        label: semanticLabel,
        child: AFMobileIcon(
          afMobileIcons: icon,
          color: isSelected ? theme.primaryColor : theme.iconColor,
        ),
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
    itemMenuBuilder: headingMobileToolbarItem.itemMenuBuilder!,
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
  final origin = buildTextAndBackgroundColorMobileToolbarItem();
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, service) => Semantics(
      label: l10n.editorToolbarColor,
      child: origin.itemIconBuilder!(context, editorState, service)!,
    ),
    itemMenuBuilder: origin.itemMenuBuilder!,
  );
}

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
