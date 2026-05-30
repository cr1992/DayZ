// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

typedef DebounceCallback<T> = FutureOr<void> Function(T payload);

class Debouncer<T> {
  Debouncer({required this.duration, required this.onFire}) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'Must not be negative.');
    }
  }

  final Duration duration;
  final DebounceCallback<T> onFire;

  Timer? _timer;
  T? _pending;
  bool _hasPending = false;

  bool get hasPending => _hasPending;

  void fire(T payload) {
    _timer?.cancel();
    _pending = payload;
    _hasPending = true;
    _timer = Timer(duration, () {
      unawaited(flushNow());
    });
  }

  Future<void> flushNow() async {
    if (!_hasPending) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    final payload = _pending as T;
    _pending = null;
    _hasPending = false;

    await onFire(payload);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
    _hasPending = false;
  }

  void dispose() {
    cancel();
  }
}
