// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/app.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/draft_recovery_status.dart';
import 'package:dayz/main.dart' as app_main;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(DraftRecoveryHolder.resetForTesting);

  test('启动流程调用 startupCheck 并写入 DraftRecoveryHolder', () async {
    final timestamp = DateTime.utc(2026, 5, 30, 10);
    final coordinator = _StartupCheckCoordinator(
      status: DraftRecoveryStatus(
        hasResidual: true,
        targetId: 'entry-1',
        isNew: true,
        lastUpdated: timestamp,
      ),
    );

    final status = await app_main.initializeDraftRecovery(coordinator);

    expect(coordinator.startupCheckCallCount, 1);
    expect(status.hasResidual, isTrue);
    expect(status.targetId, 'entry-1');
    expect(status.isNew, isTrue);
    expect(status.lastUpdated, timestamp);
    expect(DraftRecoveryHolder.lastStatus, same(status));
  });

  test('startupCheck 同步段小于 50ms', () async {
    final coordinator = _StartupCheckCoordinator(
      status: DraftRecoveryStatus(
        hasResidual: true,
        targetId: 'entry-1',
        isNew: false,
        lastUpdated: DateTime.utc(2026, 5, 30),
      ),
    );

    final stopwatch = Stopwatch()..start();
    await app_main.initializeDraftRecovery(coordinator);
    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds, lessThan(50));
  });

  testWidgets('根 widget 挂载后 LifecycleBridge 已 start', (tester) async {
    final coordinator = _FlushCountingCoordinator();
    await tester.pumpWidget(DayZApp(draftCoordinator: coordinator));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(coordinator.flushCallCount, 1);
  });
}

class _StartupCheckCoordinator extends DraftCoordinator {
  _StartupCheckCoordinator({required this.status});

  final DraftRecoveryStatus status;
  int startupCheckCallCount = 0;

  @override
  Future<DraftRecoveryStatus> startupCheck() async {
    startupCheckCallCount += 1;
    return status;
  }
}

class _FlushCountingCoordinator extends DraftCoordinator {
  int flushCallCount = 0;

  @override
  Future<void> forceFlush() async {
    flushCallCount += 1;
  }
}
