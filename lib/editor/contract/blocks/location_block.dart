// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';

Node locationNode({
  String? placeName,
  num? lat,
  num? lng,
}) {
  final attributes = <String, Object>{};
  if (placeName != null) {
    attributes[LocationBlockDataKeys.placeName] = placeName;
  }
  if (lat != null) {
    attributes[LocationBlockDataKeys.lat] = lat;
  }
  if (lng != null) {
    attributes[LocationBlockDataKeys.lng] = lng;
  }

  return Node(
    type: EditorBlockTypes.location,
    attributes: attributes,
  );
}

class LocationBlockComponentBuilder extends BlockComponentBuilder {
  LocationBlockComponentBuilder({
    super.configuration,
    this.readOnly = false,
  });

  final bool readOnly;

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return LocationBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      readOnly: readOnly,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(
        blockComponentContext,
        state,
      ),
    );
  }
}

class LocationBlockComponentWidget extends BlockComponentStatefulWidget {
  const LocationBlockComponentWidget({
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
  State<LocationBlockComponentWidget> createState() =>
      _LocationBlockComponentWidgetState();
}

class _LocationBlockComponentWidgetState
    extends State<LocationBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final blockKey = GlobalKey();
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  String? get _placeName {
    final value = node.attributes[LocationBlockDataKeys.placeName];
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  String? get _coordinates {
    final lat = (node.attributes[LocationBlockDataKeys.lat] as num?)
        ?.toStringAsFixed(4);
    final lng = (node.attributes[LocationBlockDataKeys.lng] as num?)
        ?.toStringAsFixed(4);
    if (lat == null && lng == null) {
      return null;
    }
    return [lat, lng].whereType<String>().join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();

    Widget child = Container(
      decoration: BoxDecoration(
        color: widget.readOnly
            ? Colors.teal.withValues(alpha: 0.08)
            : Colors.teal.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: Colors.teal.withValues(alpha: widget.readOnly ? 0.18 : 0.28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Text('📍'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _placeName ?? '位置',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                  ),
                ),
                if (_coordinates != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _coordinates!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    child = Padding(
      key: blockKey,
      padding: padding,
      child: child,
    );

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
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
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
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) =>
      _renderBox!.localToGlobal(offset);

  @override
  TextDirection textDirection() => TextDirection.ltr;
}
