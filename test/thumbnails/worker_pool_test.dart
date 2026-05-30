// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/thumbnails/cancel_token.dart';
import 'package:dayz/thumbnails/worker_pool.dart';

void main() {
  group('WorkerPool Tests', () {
    test('concurrency limit - max 2 tasks concurrent', () async {
      final pool = WorkerPool(maxConcurrency: 2);
      final completers = List.generate(5, (_) => completerHelper());
      var runningCount = 0;
      var peakRunningCount = 0;

      Future<void> runTask(int index) async {
        runningCount++;
        if (runningCount > peakRunningCount) {
          peakRunningCount = runningCount;
        }
        await completers[index].future;
        runningCount--;
      }

      final futures = List.generate(5, (i) {
        return pool.submit(() => runTask(i), CancelToken());
      });

      // 允许微任务调度
      await Future.delayed(const Duration(milliseconds: 10));

      expect(peakRunningCount, lessThanOrEqualTo(2));
      expect(pool.activeCount, equals(2));
      expect(pool.queueLength, equals(3));

      // 完成前两个
      completers[0].complete();
      completers[1].complete();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(peakRunningCount, lessThanOrEqualTo(2));
      expect(pool.activeCount, equals(2));
      expect(pool.queueLength, equals(1));

      // 完成后三个
      completers[2].complete();
      completers[3].complete();
      completers[4].complete();
      await Future.wait(futures);

      expect(pool.activeCount, equals(0));
      expect(pool.queueLength, equals(0));
      expect(peakRunningCount, lessThanOrEqualTo(2));
    });

    test('cancel release slot within 100ms', () async {
      final pool = WorkerPool(maxConcurrency: 2);
      final cancelToken = CancelToken();
      final completer = completerHelper();

      final future = pool.submit(() async {
        await completer.future;
      }, cancelToken);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(pool.activeCount, equals(1));

      final stopwatch = Stopwatch()..start();
      cancelToken.cancel();

      expect(future, throwsA(isA<CancelledException>()));
      await future.catchError((_) {});

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(pool.activeCount, equals(0));
    });

    test('cancel pending task directly', () async {
      final pool = WorkerPool(maxConcurrency: 1);
      final cancelToken = CancelToken();
      final activeCompleter = completerHelper();

      // 第一个占满 slot
      final first = pool.submit(() async {
        await activeCompleter.future;
      }, CancelToken());

      // 第二个排队并取消
      final second = pool.submit(() async {}, cancelToken);

      cancelToken.cancel();
      expect(second, throwsA(isA<CancelledException>()));
      await second.catchError((_) {});

      expect(pool.queueLength, equals(0));

      activeCompleter.complete();
      await first;
    });
  });
}

// 辅助返回 Dynamic 类型的 Completer，避免 generic type 警告
Completer<dynamic> completerHelper() => Completer<dynamic>();
