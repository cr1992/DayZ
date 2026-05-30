// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'cancel_token.dart';

enum ThumbnailState { pending, ready, failed, cancelled }

enum ThumbnailPriority { normal, low }

class ThumbnailResult {
  final String relPath;
  final int w;
  final int h;

  ThumbnailResult({
    required this.relPath,
    required this.w,
    required this.h,
  });
}

class ThumbnailHandle {
  final CancelToken cancelToken;
  final Completer<ThumbnailResult> _completer = Completer<ThumbnailResult>();
  ThumbnailState _state = ThumbnailState.pending;

  ThumbnailHandle({required this.cancelToken}) {
    // 监听 cancelToken
    cancelToken.whenCancelled.then((_) {
      if (_state == ThumbnailState.pending) {
        _state = ThumbnailState.cancelled;
        if (!_completer.isCompleted) {
          _completer.completeError(Exception('Cancelled'));
        }
      }
    });
  }

  ThumbnailState get state => _state;
  Future<ThumbnailResult> get future => _completer.future;

  void cancel() {
    if (_state == ThumbnailState.pending) {
      _state = ThumbnailState.cancelled;
      cancelToken.cancel();
      if (!_completer.isCompleted) {
        _completer.completeError(Exception('Cancelled'));
      }
    }
  }

  void complete(ThumbnailResult result) {
    if (_state == ThumbnailState.pending) {
      _state = ThumbnailState.ready;
      if (!_completer.isCompleted) {
        _completer.complete(result);
      }
    }
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_state == ThumbnailState.pending) {
      _state = ThumbnailState.failed;
      if (!_completer.isCompleted) {
        _completer.completeError(error, stackTrace);
      }
    }
  }

  void markCancelled() {
    if (_state == ThumbnailState.pending) {
      _state = ThumbnailState.cancelled;
      if (!_completer.isCompleted) {
        _completer.completeError(Exception('Cancelled'));
      }
    }
  }
}
