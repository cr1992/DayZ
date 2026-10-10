// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';

class CalloutBlockKeys {
  const CalloutBlockKeys._();

  static const String type = EditorBlockTypes.callout;
  static const String delta = blockComponentDelta;
  static const String textDirection = blockComponentTextDirection;
}

Node calloutNode({
  String? text,
  Delta? delta,
  String? textDirection,
  Attributes? attributes,
  Iterable<Node> children = const [],
}) {
  final nodeAttributes = <String, dynamic>{
    CalloutBlockKeys.delta: (delta ?? (Delta()..insert(text ?? ''))).toJson(),
  };
  if (attributes != null) {
    nodeAttributes.addAll(attributes);
  }
  if (textDirection != null) {
    nodeAttributes[CalloutBlockKeys.textDirection] = textDirection;
  }

  return Node(
    type: CalloutBlockKeys.type,
    attributes: nodeAttributes,
    children: children,
  );
}

/// 块外距：`.compose-body .cb-callout { margin: var(--sp-4) 0 }`。
EdgeInsets _calloutBlockPadding(Node node) =>
    const EdgeInsets.symmetric(vertical: DayzSpacing.s4);

/// callout 默认块配置（只覆盖块外距，其余沿用 AppFlowy 默认）。
const BlockComponentConfiguration calloutBlockComponentConfiguration =
    BlockComponentConfiguration(padding: _calloutBlockPadding);

class CalloutBlockComponentBuilder extends BlockComponentBuilder {
  CalloutBlockComponentBuilder({
    BlockComponentConfiguration? configuration,
    this.readOnly = false,
  }) : super(
         configuration: configuration ?? calloutBlockComponentConfiguration,
       );

  final bool readOnly;

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta != null;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CalloutBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      readOnly: readOnly,
      showActions: showActions(node),
      actionBuilder: (context, state) =>
          actionBuilder(blockComponentContext, state),
      actionTrailingBuilder: (context, state) =>
          actionTrailingBuilder(blockComponentContext, state),
    );
  }
}

class CalloutBlockComponentWidget extends BlockComponentStatefulWidget {
  const CalloutBlockComponentWidget({
    super.key,
    required super.node,
    required this.readOnly,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  final bool readOnly;

  @override
  State<CalloutBlockComponentWidget> createState() =>
      _CalloutBlockComponentWidgetState();
}

class _CalloutBlockComponentWidgetState
    extends State<CalloutBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin,
        BlockComponentAlignMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: CalloutBlockKeys.type,
  );

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  late final editorState = Provider.of<EditorState>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    // `.compose-body .cb-callout`：display:flex; gap:--sp-3;
    // background:--accent-soft; border-radius:--r-md; padding:--sp-3 --sp-4。
    Widget child = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(DayzRadii.md),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: DayzSpacing.s3,
        horizontal: DayzSpacing.s4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: textDirection,
        children: [
          Padding(
            // `.cb-callout .ic { margin-top: 2px }`
            padding: const EdgeInsets.only(top: 2),
            // `.cb-callout .ic svg { width: 20px; height: 20px }`，色 --accent-ink
            child: DayzIcon(
              DayzIcons.callout,
              size: 20,
              color: colors.accentInk,
            ),
          ),
          const SizedBox(width: DayzSpacing.s3),
          Flexible(
            child: AppFlowyRichText(
              key: forwardKey,
              delegate: this,
              node: widget.node,
              editorState: editorState,
              textAlign: alignment?.toTextAlign ?? textAlign,
              placeholderText: placeholderText,
              textSpanDecorator: (textSpan) => textSpan.updateTextStyle(
                textStyleWithTextSpan(
                  textSpan: textSpan,
                ).copyWith(color: colors.ink),
              ),
              placeholderTextSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(
                    placeholderTextStyleWithTextSpan(
                      textSpan: textSpan,
                    ).copyWith(color: colors.ink),
                  ),
              textDirection: textDirection,
              cursorColor: editorState.editorStyle.cursorColor,
              selectionColor: editorState.editorStyle.selectionColor,
              cursorWidth: editorState.editorStyle.cursorWidth,
            ),
          ),
        ],
      ),
    );

    child = Container(key: blockComponentKey, padding: padding, child: child);

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    return child;
  }
}
