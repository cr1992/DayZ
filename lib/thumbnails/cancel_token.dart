// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';

class CancelToken {
  bool _isCancelled = false;
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _completer.complete();
  }

  Future<void> get whenCancelled => _completer.future;
}
