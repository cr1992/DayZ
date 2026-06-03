// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/media/media_store.dart';

class EditorImageInserter {
  static Future<void> pickAndInsert({
    required BuildContext context,
    required EditorState editorState,
    required dynamic mediaStore,
    required String? entryId,
    Future<XFile?> Function()? pickImageOp,
  }) async {
    // Save selection synchronously before focus is lost during picking
    final selection = editorState.selection;
    if (selection == null) return;

    final image = pickImageOp != null
        ? await pickImageOp()
        : await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final stream = Stream<List<int>>.value(bytes);
    final fileSize = bytes.length;

    // Use default entry placeholder if none provided
    final effectiveEntryId = entryId ?? 'temp-entry';

    final relPath = await mediaStore.put(
      bytes: stream,
      entryId: effectiveEntryId,
      kind: MediaKind.image,
      mime: _mimeTypeFromPath(image.path),
      fileSize: fileSize,
    );

    // Delete picker temporary plain file if it is physical
    try {
      final file = File(image.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup error if it's read-only or permission-denied
    }

    // Extract media.id from relPath (e.g. 'media/media-1.bin' -> 'media-1')
    final mediaId = relPath.split('/').last.split('.').first;

    // Insert Image Node after saved selection
    final path = selection.start.path;
    final parentPath = path.sublist(0, path.length - 1);
    final nextIndex = path.last + 1;
    final insertPath = [...parentPath, nextIndex];

    final node = Node(
      type: ImageBlockKeys.type,
      attributes: {
        ImageBlockKeys.url: EditorImageReference.urlForMediaId(mediaId),
      },
    );

    final transaction = editorState.transaction
      ..insertNode(insertPath, node);

    await editorState.apply(transaction);
    editorState.selection = Selection.collapsed(
      Position(path: insertPath, offset: 0),
    );
  }

  static String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
