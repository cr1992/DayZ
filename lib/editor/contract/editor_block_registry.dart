// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/editor/contract/blocks/location_block.dart';
import 'package:dayz/editor/contract/blocks/weather_block.dart';
import 'package:dayz/editor/contract/image_url_resolver.dart';
import 'package:dayz/editor/contract/plain_text_extractor.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';

abstract final class EditorBlockRegistry {
  static const Set<String> supportedTypes = EditorBlockTypes.supported;

  static Map<String, BlockComponentBuilder> editableBuilders({
    ImageUrlResolver? imageUrlResolver,
  }) {
    return _builders(
      imageUrlResolver: imageUrlResolver ?? ImageUrlResolver.unresolved(),
      readOnly: false,
    );
  }

  static Map<String, BlockComponentBuilder> readonlyBuilders({
    ImageUrlResolver? imageUrlResolver,
  }) {
    return _builders(
      imageUrlResolver: imageUrlResolver ?? ImageUrlResolver.unresolved(),
      readOnly: true,
    );
  }

  static Set<String> contentTypesOf(
    Map<String, BlockComponentBuilder> builders,
  ) {
    return builders.keys.where((type) {
      return type != PageBlockKeys.type &&
          type != errorBlockComponentBuilderKey;
    }).toSet();
  }

  static Map<String, BlockComponentBuilder> _builders({
    required ImageUrlResolver imageUrlResolver,
    required bool readOnly,
  }) {
    return {
      PageBlockKeys.type: PageBlockComponentBuilder(),
      ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
        configuration: standardBlockComponentConfiguration.copyWith(
          placeholderText: (_) => ' ',
        ),
      ),
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        configuration: standardBlockComponentConfiguration.copyWith(
          placeholderText: (node) =>
              'Heading ${node.attributes[HeadingBlockKeys.level]}',
        ),
      ),
      BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
        configuration: standardBlockComponentConfiguration.copyWith(
          placeholderText: (_) =>
              AppFlowyEditorL10n.current.listItemPlaceholder,
        ),
      ),
      NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
        configuration: standardBlockComponentConfiguration.copyWith(
          placeholderText: (_) =>
              AppFlowyEditorL10n.current.listItemPlaceholder,
        ),
      ),
      TodoListBlockKeys.type: TodoListBlockComponentBuilder(
        configuration: standardBlockComponentConfiguration.copyWith(
          placeholderText: (_) => AppFlowyEditorL10n.current.toDoPlaceholder,
        ),
        toggleChildrenTriggers: const [],
      ),
      QuoteBlockKeys.type: QuoteBlockComponentBuilder(
        configuration: standardBlockComponentConfiguration.copyWith(
          placeholderText: (_) => AppFlowyEditorL10n.current.quote,
        ),
      ),
      DividerBlockKeys.type: DividerBlockComponentBuilder(
        configuration: standardBlockComponentConfiguration.copyWith(
          padding: (node) => const EdgeInsets.symmetric(vertical: 8.0),
        ),
      ),
      ImageBlockKeys.type: readOnly
          ? ResolvedImageBlockComponentBuilder.readonly(
              imageUrlResolver: imageUrlResolver,
            )
          : ResolvedImageBlockComponentBuilder.editable(
              imageUrlResolver: imageUrlResolver,
            ),
      EditorBlockTypes.location: LocationBlockComponentBuilder(
        readOnly: readOnly,
      ),
      EditorBlockTypes.weather: WeatherBlockComponentBuilder(
        readOnly: readOnly,
      ),
      errorBlockComponentBuilderKey: _UnknownBlockComponentBuilder(),
    };
  }
}

class _UnknownBlockComponentBuilder extends BlockComponentBuilder {
  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return _UnknownBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) =>
          actionBuilder(blockComponentContext, state),
      actionTrailingBuilder: (context, state) =>
          actionTrailingBuilder(blockComponentContext, state),
    );
  }
}

class _UnknownBlockComponentWidget extends BlockComponentStatefulWidget {
  const _UnknownBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<_UnknownBlockComponentWidget> createState() =>
      _UnknownBlockComponentWidgetState();
}

class _UnknownBlockComponentWidgetState
    extends State<_UnknownBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final blockKey = GlobalKey();
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    final fallbackText = EditorPlainTextExtractor.lineForNode(node) ?? '[未支持块]';

    Widget child = Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: Colors.grey.shade500),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(fallbackText),
    );

    child = Padding(key: blockKey, padding: padding, child: child);

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      cursorColor: editorState.editorStyle.cursorColor,
      selectionColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
        BlockSelectionType.cursor,
        BlockSelectionType.selection,
      ],
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

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    return getRectsInSelection(Selection.invalid()).first;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return null;
    }
    return getRectsInSelection(
      Selection.collapsed(position),
      shiftWithBaseOffset: shiftWithBaseOffset,
    ).firstOrNull;
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final parentBox = context.findRenderObject();
    final childBox = blockKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && childBox is RenderBox) {
      return [
        (shiftWithBaseOffset
                ? childBox.localToGlobal(Offset.zero, ancestor: parentBox)
                : Offset.zero) &
            childBox.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) =>
      _renderBox!.localToGlobal(offset);

  @override
  TextDirection textDirection() => TextDirection.ltr;
}
