// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';

/// Translates AppFlowy editor changes into plain-payload draft updates and
/// feeds them to the (injected) `DraftCoordinator`.
///
/// This bridge only translates — it does NOT implement debounce/transactions/
/// retry (those belong to the auto-save-draft spec). It calls the coordinator's
/// public `onChanged`/`forceFlush` API.
class EditorDraftBridge {
  EditorDraftBridge({
    required this.editorState,
    required this.draftCoordinator,
    required this.targetId,
    required this.isNew,
    this.onFirstDraftFlushed,
  }) {
    _documentSubscription =
        editorState.transactionStream.listen((_) => _onContentChanged());
    _selectionListener = _onSelectionChanged;
    editorState.selectionNotifier.addListener(_selectionListener!);
  }

  final EditorState editorState;
  final dynamic draftCoordinator;
  final String? targetId;
  final bool isNew;

  /// Invoked once, after the FIRST real content edit has been successfully
  /// flushed by the coordinator. The screen uses this to switch the app-bar
  /// title to "草稿已存" (D4). It deliberately does NOT fire on bare cursor
  /// moves or before a flush completes.
  final VoidCallback? onFirstDraftFlushed;

  StreamSubscription? _documentSubscription;
  VoidCallback? _selectionListener;
  bool _firstFlushPending = false;
  bool _firstFlushDone = false;

  void _push() {
    final draftJson = EditorDocCodec.encode(editorState.document);
    final cursorPos = editorState.selection?.start.offset;

    draftCoordinator.onChanged(
      targetId: targetId,
      draftJson: draftJson,
      isNew: isNew,
      cursorPos: cursorPos,
    );
  }

  /// Cursor/selection moves feed autosave (so cursorPos stays current) but
  /// MUST NOT flip the "draft saved" title — that is reserved for a real,
  /// persisted content edit.
  void _onSelectionChanged() => _push();

  void _onContentChanged() {
    _push();
    unawaited(_confirmFirstFlush());
  }

  Future<void> _confirmFirstFlush() async {
    if (_firstFlushDone || _firstFlushPending || onFirstDraftFlushed == null) {
      return;
    }
    _firstFlushPending = true;
    try {
      await draftCoordinator.forceFlush();
      _firstFlushDone = true;
      onFirstDraftFlushed?.call();
    } catch (_) {
      // Flush failed; leave _firstFlushDone false so a later edit retries.
    } finally {
      _firstFlushPending = false;
    }
  }

  void dispose() {
    _documentSubscription?.cancel();
    if (_selectionListener != null) {
      editorState.selectionNotifier.removeListener(_selectionListener!);
    }
  }
}
