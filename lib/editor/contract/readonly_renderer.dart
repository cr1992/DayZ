// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/editor/contract/image_url_resolver.dart';
import 'package:flutter/material.dart';

class ReadonlyRenderer extends StatefulWidget {
  const ReadonlyRenderer({
    super.key,
    required this.document,
    this.imageUrlResolver,
    this.editorStyle = const EditorStyle.desktop(),
    this.enableSelection = false,
    this.shrinkWrap = true,
  });

  final Document document;
  final ImageUrlResolver? imageUrlResolver;
  final EditorStyle editorStyle;
  final bool enableSelection;
  final bool shrinkWrap;

  static Set<String> registeredTypes({ImageUrlResolver? imageUrlResolver}) {
    return EditorBlockRegistry.contentTypesOf(
      EditorBlockRegistry.readonlyBuilders(imageUrlResolver: imageUrlResolver),
    );
  }

  @override
  State<ReadonlyRenderer> createState() => _ReadonlyRendererState();
}

class _ReadonlyRendererState extends State<ReadonlyRenderer> {
  late final EditorState _editorState;

  @override
  void initState() {
    super.initState();
    _editorState = EditorState(document: widget.document);
  }

  @override
  void dispose() {
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyEditor(
      editorState: _editorState,
      editable: false,
      shrinkWrap: widget.shrinkWrap,
      disableKeyboardService: true,
      disableSelectionService: !widget.enableSelection,
      blockComponentBuilders: EditorBlockRegistry.readonlyBuilders(
        imageUrlResolver:
            widget.imageUrlResolver ?? ImageUrlResolver.unresolved(),
      ),
      editorStyle: widget.editorStyle,
    );
  }
}
