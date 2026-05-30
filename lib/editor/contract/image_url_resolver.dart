// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';

typedef MediaPathResolver = String? Function(String mediaId);

class ImageUrlResolver {
  ImageUrlResolver({required MediaPathResolver mediaPathResolver})
    : this._(mediaPathResolver);

  ImageUrlResolver._(this._mediaPathResolver);

  factory ImageUrlResolver.unresolved() {
    return ImageUrlResolver(mediaPathResolver: (_) => null);
  }

  final MediaPathResolver _mediaPathResolver;

  bool isMediaUrl(String url) =>
      url.startsWith(EditorImageReference.schemePrefix);

  String? mediaIdFromUrl(String? url) {
    if (url == null || !isMediaUrl(url)) {
      return null;
    }
    final mediaId = url.substring(EditorImageReference.schemePrefix.length);
    final normalized = mediaId.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? mediaIdFromNode(Node node) {
    return mediaIdFromUrl(node.attributes[ImageBlockKeys.url]?.toString());
  }

  String? resolveNodeUrl(Node node) {
    final rawUrl = node.attributes[ImageBlockKeys.url]?.toString();
    if (rawUrl == null) {
      return null;
    }

    final mediaId = mediaIdFromUrl(rawUrl);
    if (mediaId == null) {
      return rawUrl;
    }

    return _mediaPathResolver(mediaId);
  }
}

class ResolvedImageBlockComponentBuilder extends BlockComponentBuilder {
  ResolvedImageBlockComponentBuilder.editable({
    required this.imageUrlResolver,
    super.configuration,
  }) : _readOnly = false;

  ResolvedImageBlockComponentBuilder.readonly({
    required this.imageUrlResolver,
    super.configuration,
  }) : _readOnly = true;

  final ImageUrlResolver imageUrlResolver;
  final bool _readOnly;

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ResolvedImageBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      imageUrlResolver: imageUrlResolver,
      readOnly: _readOnly,
      showActions: showActions(node),
      actionBuilder: (context, state) =>
          actionBuilder(blockComponentContext, state),
      actionTrailingBuilder: (context, state) =>
          actionTrailingBuilder(blockComponentContext, state),
    );
  }
}

class ResolvedImageBlockComponentWidget extends BlockComponentStatefulWidget {
  const ResolvedImageBlockComponentWidget({
    super.key,
    required super.node,
    required this.imageUrlResolver,
    required this.readOnly,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  final ImageUrlResolver imageUrlResolver;
  final bool readOnly;

  @override
  State<ResolvedImageBlockComponentWidget> createState() =>
      _ResolvedImageBlockComponentWidgetState();
}

class _ResolvedImageBlockComponentWidgetState
    extends State<ResolvedImageBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final imageKey = GlobalKey();
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  Alignment _alignmentFromName(String? alignmentName) {
    switch (alignmentName) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();
    final attributes = node.attributes;
    final resolvedSrc = widget.imageUrlResolver.resolveNodeUrl(node);
    final mediaId = widget.imageUrlResolver.mediaIdFromNode(node);

    final alignment = _alignmentFromName(
      attributes[ImageBlockKeys.align]?.toString(),
    );
    final width =
        (attributes[ImageBlockKeys.width] as num?)?.toDouble() ??
        MediaQuery.of(context).size.width;
    final height = (attributes[ImageBlockKeys.height] as num?)?.toDouble();

    Widget child;
    if (resolvedSrc == null) {
      child = Container(
        height: height ?? 120,
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: Colors.grey.shade500),
          color: Colors.grey.withValues(alpha: 0.08),
        ),
        padding: const EdgeInsets.all(12),
        child: Text(
          mediaId == null ? '[图片不可用]' : '[图片不可用: $mediaId]',
          textAlign: TextAlign.center,
        ),
      );
    } else {
      child = ResizableImage(
        src: resolvedSrc,
        width: width,
        height: height,
        editable: editorState.editable && !widget.readOnly,
        alignment: alignment,
        onResize: (newWidth) {
          final transaction = editorState.transaction
            ..updateNode(node, {ImageBlockKeys.width: newWidth});
          editorState.apply(transaction);
        },
      );
    }

    child = Padding(key: imageKey, padding: padding, child: child);

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
    final childBox = imageKey.currentContext?.findRenderObject();
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
