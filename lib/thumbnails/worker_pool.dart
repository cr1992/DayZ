// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'cancel_token.dart';

class CancelledException implements Exception {
  @override
  String toString() => 'CancelledException';
}

class _PendingTask {
  final void Function() run;
  final CancelToken cancelToken;
  final Completer<dynamic> completer;

  _PendingTask(this.run, this.cancelToken, this.completer);
}

class WorkerPool {
  final int maxConcurrency;
  int _activeCount = 0;
  final List<_PendingTask> _queue = [];

  WorkerPool({this.maxConcurrency = 2});

  int get activeCount => _activeCount;
  int get queueLength => _queue.length;

  Future<T> submit<T>(
    Future<T> Function() task,
    CancelToken cancelToken,
  ) async {
    final completer = Completer<T>();

    void runTask() async {
      if (cancelToken.isCancelled) {
        completer.completeError(CancelledException());
        _processQueue();
        return;
      }

      _activeCount++;
      try {
        if (cancelToken.isCancelled) {
          throw CancelledException();
        }

        // 使用 Future.any 监听任务和取消信号。
        // 一旦取消信号触发，则抛出 CancelledException 并释放 slot。
        final result = await Future.any([
          task(),
          cancelToken.whenCancelled.then((_) => throw CancelledException()),
        ]);

        if (cancelToken.isCancelled) {
          throw CancelledException();
        }

        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _activeCount--;
        _processQueue();
      }
    }

    if (_activeCount < maxConcurrency) {
      runTask();
    } else {
      final pending = _PendingTask(runTask, cancelToken, completer);
      _queue.add(pending);

      // 如果在排队中就被取消了，从队列移除并 completeError
      cancelToken.whenCancelled.then((_) {
        if (_queue.contains(pending)) {
          _queue.remove(pending);
          if (!completer.isCompleted) {
            completer.completeError(CancelledException());
          }
        }
      });
    }

    return completer.future;
  }

  void _processQueue() {
    if (_activeCount < maxConcurrency && _queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.run();
    }
  }
}
