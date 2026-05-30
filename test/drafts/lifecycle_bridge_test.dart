// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/lifecycle_bridge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LifecycleBridge', () {
    test('handleLifecycleState paused/inactive await forceFlush 完成', () async {
      final coordinator = _ControlledDraftCoordinator();
      final bridge = LifecycleBridge(coordinator: coordinator);

      final pausedFlush = bridge.handleLifecycleState(AppLifecycleState.paused);
      expect(coordinator.flushCallCount, 1);
      expect(coordinator.hasPendingFlush, isTrue);

      coordinator.completeNextFlush();
      await pausedFlush;
      expect(coordinator.completedFlushCount, 1);

      final inactiveFlush = bridge.handleLifecycleState(
        AppLifecycleState.inactive,
      );
      expect(coordinator.flushCallCount, 2);

      coordinator.completeNextFlush();
      await inactiveFlush;
      expect(coordinator.completedFlushCount, 2);
    });

    test('handleLifecycleState 对非 paused/inactive 状态 no-op', () async {
      final coordinator = _ControlledDraftCoordinator();
      final bridge = LifecycleBridge(coordinator: coordinator);

      await bridge.handleLifecycleState(AppLifecycleState.resumed);
      await bridge.handleLifecycleState(AppLifecycleState.detached);
      await bridge.handleLifecycleState(AppLifecycleState.hidden);

      expect(coordinator.flushCallCount, 0);
      expect(bridge.pendingFlush, isNull);
      expect(bridge.lastError, isNull);
    });

    testWidgets('AppLifecycleListener 同步创建 pendingFlush 且最终完成', (tester) async {
      final coordinator = _ControlledDraftCoordinator();
      final bridge = LifecycleBridge(coordinator: coordinator);
      addTearDown(bridge.stop);

      bridge.start();
      expect(bridge.isStarted, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

      final pending = bridge.pendingFlush;
      expect(pending, isNotNull);
      expect(coordinator.flushCallCount, 1);
      expect(coordinator.hasPendingFlush, isTrue);

      var completed = false;
      pending!.then((_) {
        completed = true;
      });

      coordinator.completeNextFlush();
      await tester.pump();

      expect(completed, isTrue);
      expect(coordinator.completedFlushCount, 1);
      expect(bridge.lastError, isNull);
    });

    testWidgets('forceFlush 失败进入可观察错误状态', (tester) async {
      final coordinator = _ControlledDraftCoordinator();
      final bridge = LifecycleBridge(coordinator: coordinator);
      addTearDown(bridge.stop);

      bridge.start();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);

      final pending = bridge.pendingFlush;
      expect(pending, isNotNull);

      coordinator.failNextFlush(StateError('flush failed'));
      await tester.pump();

      await expectLater(pending, throwsStateError);
      expect(bridge.lastError, isNotNull);
      expect(bridge.lastError!.state, AppLifecycleState.inactive);
      expect(bridge.lastError!.error, isA<StateError>());
    });

    test('start/stop 幂等维护启动状态', () {
      final bridge = LifecycleBridge(
        coordinator: _ControlledDraftCoordinator(),
      );

      bridge.start();
      bridge.start();
      expect(bridge.isStarted, isTrue);

      bridge.stop();
      bridge.stop();
      expect(bridge.isStarted, isFalse);
    });
  });
}

class _ControlledDraftCoordinator extends DraftCoordinator {
  final List<Completer<void>> _pendingFlushes = <Completer<void>>[];

  int flushCallCount = 0;
  int completedFlushCount = 0;

  bool get hasPendingFlush => _pendingFlushes.isNotEmpty;

  @override
  Future<void> forceFlush() {
    flushCallCount += 1;
    final completer = Completer<void>();
    _pendingFlushes.add(completer);
    return completer.future.then((_) {
      completedFlushCount += 1;
    });
  }

  void completeNextFlush() {
    final completer = _removeNextFlush();
    completer.complete();
  }

  void failNextFlush(Object error) {
    final completer = _removeNextFlush();
    completer.completeError(error, StackTrace.current);
  }

  Completer<void> _removeNextFlush() {
    if (_pendingFlushes.isEmpty) {
      throw StateError('No pending flush to complete.');
    }
    return _pendingFlushes.removeAt(0);
  }
}
