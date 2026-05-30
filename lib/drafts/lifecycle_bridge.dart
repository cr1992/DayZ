// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../observability/app_logger.dart';
import 'draft_coordinator.dart';

class LifecycleFlushError {
  const LifecycleFlushError({
    required this.error,
    required this.stackTrace,
    required this.state,
    required this.occurredAt,
  });

  final Object error;
  final StackTrace stackTrace;
  final AppLifecycleState state;
  final DateTime occurredAt;
}

class LifecycleBridge {
  LifecycleBridge({required DraftCoordinator coordinator})
    : this._(coordinator);

  LifecycleBridge._(this._coordinator);

  final DraftCoordinator _coordinator;
  AppLifecycleListener? _listener;
  Future<void>? pendingFlush;
  LifecycleFlushError? lastError;

  bool get isStarted => _listener != null;

  Future<void> handleLifecycleState(AppLifecycleState state) async {
    if (!_shouldFlush(state)) {
      return;
    }

    AppLogger.instance.logInfo('draft.lifecycle.flush.start', fields: {
      'state': state.name,
    });
    try {
      await _coordinator.forceFlush();
      AppLogger.instance.logInfo('draft.lifecycle.flush.success', fields: {
        'state': state.name,
      });
    } catch (e) {
      // Re-throw so the listener's catchError block handles and records it.
      rethrow;
    }
  }

  void start() {
    if (_listener != null) {
      return;
    }

    _listener = AppLifecycleListener(
      onStateChange: (state) {
        if (!_shouldFlush(state)) {
          return;
        }

        AppLogger.instance.logInfo('draft.lifecycle.stateChanged', fields: {
          'state': state.name,
        });

        final flush = handleLifecycleState(state);
        pendingFlush = flush;
        unawaited(
          flush.catchError((Object error, StackTrace stackTrace) {
            AppLogger.instance.logSevere('draft.lifecycle.flush.failed', fields: {
              'state': state.name,
              'error': error.toString(),
            });
            lastError = LifecycleFlushError(
              error: error,
              stackTrace: stackTrace,
              state: state,
              occurredAt: DateTime.now().toUtc(),
            );
          }),
        );
      },
    );
  }

  void stop() {
    _listener?.dispose();
    _listener = null;
  }

  bool _shouldFlush(AppLifecycleState state) {
    return state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;
  }
}
