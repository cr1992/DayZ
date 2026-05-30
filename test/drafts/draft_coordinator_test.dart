// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraftCoordinator', () {
    testWidgets('连续 onChanged 仅一次写盘并保存最后一次输入', (tester) async {
      final store = _RecordingDraftSessionStore();
      final coordinator = DraftCoordinator(store: store);

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"first"}',
        isNew: false,
        cursorPos: 1,
      );
      await tester.pump(const Duration(milliseconds: 500));
      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"second"}',
        isNew: false,
        cursorPos: 2,
      );
      await tester.pump(const Duration(milliseconds: 500));
      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"third"}',
        isNew: false,
        cursorPos: 3,
      );

      await tester.pump(const Duration(milliseconds: 1499));
      expect(store.upserts, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(store.upserts, hasLength(1));
      expect(store.upserts.single.targetId, 'entry-1');
      expect(store.upserts.single.draftJson, '{"body":"third"}');
      expect(store.upserts.single.cursorPos, 3);
    });

    testWidgets('相同 draftJson hash 跳过实际写盘', (tester) async {
      final store = _RecordingDraftSessionStore();
      final coordinator = DraftCoordinator(store: store);

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"same"}',
        isNew: false,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"same"}',
        isNew: false,
        cursorPos: 99,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(store.upserts, hasLength(1));
      expect(store.upserts.single.draftJson, '{"body":"same"}');
    });

    testWidgets('不同 draftJson 触发新的写盘', (tester) async {
      final store = _RecordingDraftSessionStore();
      final coordinator = DraftCoordinator(store: store);

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"first"}',
        isNew: false,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"second"}',
        isNew: false,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(store.upserts.map((change) => change.draftJson), [
        '{"body":"first"}',
        '{"body":"second"}',
      ]);
    });

    testWidgets('保存失败最多重试 3 次后进入异常队列', (tester) async {
      final store = _RecordingDraftSessionStore(failuresBeforeSuccess: 4);
      final coordinator = DraftCoordinator(
        store: store,
        retryDelays: List<Duration>.filled(3, Duration.zero),
      );

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"fail"}',
        isNew: false,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();
      await tester.pump();

      expect(store.upsertAttempts, 4);
      expect(store.upserts, isEmpty);
      expect(coordinator.saveErrors, hasLength(1));
      expect(coordinator.saveErrors.single.attempts, 4);
      expect(coordinator.saveErrors.single.change.draftJson, '{"body":"fail"}');
    });

    testWidgets('切换 targetId 时先 flush 旧 target 再处理新 target', (tester) async {
      final store = _RecordingDraftSessionStore();
      final coordinator = DraftCoordinator(store: store);

      coordinator.onChanged(
        targetId: 'entry-a',
        draftJson: '{"body":"a"}',
        isNew: false,
      );
      coordinator.onChanged(
        targetId: 'entry-b',
        draftJson: '{"body":"b"}',
        isNew: false,
      );

      await tester.pump();
      expect(store.upserts, hasLength(1));
      expect(store.upserts.single.targetId, 'entry-a');

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(store.upserts, hasLength(2));
      expect(store.upserts.map((change) => change.targetId), [
        'entry-a',
        'entry-b',
      ]);
    });

    testWidgets('串行队列按入队顺序完成写盘', (tester) async {
      final store = _RecordingDraftSessionStore(autoComplete: false);
      final coordinator = DraftCoordinator(store: store);

      coordinator.onChanged(
        targetId: 'entry-a',
        draftJson: '{"body":"a"}',
        isNew: false,
      );
      coordinator.onChanged(
        targetId: 'entry-b',
        draftJson: '{"body":"b"}',
        isNew: false,
      );
      coordinator.onChanged(
        targetId: 'entry-c',
        draftJson: '{"body":"c"}',
        isNew: false,
      );
      unawaited(coordinator.forceFlush());

      await tester.pump();
      expect(store.pendingUpsertLabels, ['entry-a']);

      store.completeNextUpsert();
      await tester.pump();
      expect(store.pendingUpsertLabels, ['entry-b']);

      store.completeNextUpsert();
      await tester.pump();
      expect(store.pendingUpsertLabels, ['entry-c']);

      store.completeNextUpsert();
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(store.completedUpserts.map((change) => change.targetId), [
        'entry-a',
        'entry-b',
        'entry-c',
      ]);
    });

    testWidgets('100 次并发 onChanged 输出确定', (tester) async {
      final store = _RecordingDraftSessionStore();
      final coordinator = DraftCoordinator(store: store);

      for (var i = 0; i < 100; i += 1) {
        coordinator.onChanged(
          targetId: 'entry-1',
          draftJson: '{"body":"draft-$i"}',
          isNew: false,
          cursorPos: i,
        );
      }

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(store.upserts, hasLength(1));
      expect(store.upserts.single.draftJson, '{"body":"draft-99"}');
      expect(store.upserts.single.cursorPos, 99);
      expect(coordinator.saveErrors, isEmpty);
    });

    test('startupCheck 将残留行包装为恢复状态并播种 hash', () async {
      final store = _RecordingDraftSessionStore(
        initialSnapshot: DraftSessionSnapshot(
          targetId: 'entry-1',
          draftJson: '{"body":"residual"}',
          isNew: true,
          cursorPos: 4,
          lastUpdated: DateTime.utc(2026, 5, 30, 9),
        ),
      );
      final coordinator = DraftCoordinator(
        store: store,
        debounceDuration: Duration.zero,
      );

      final status = await coordinator.startupCheck();
      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"residual"}',
        isNew: true,
      );
      await coordinator.forceFlush();

      expect(status.hasResidual, isTrue);
      expect(status.targetId, 'entry-1');
      expect(status.isNew, isTrue);
      expect(status.lastUpdated, DateTime.utc(2026, 5, 30, 9));
      expect(store.upserts, isEmpty);
    });

    test('clear 清空 store 与 hash，后续相同内容会重新写盘', () async {
      final store = _RecordingDraftSessionStore();
      final coordinator = DraftCoordinator(
        store: store,
        debounceDuration: Duration.zero,
      );

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"same"}',
        isNew: false,
      );
      await coordinator.forceFlush();

      await coordinator.clear();
      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"body":"same"}',
        isNew: false,
      );
      await coordinator.forceFlush();

      expect(store.clearCount, 1);
      expect(store.upserts, hasLength(2));
    });
  });
}

class _RecordingDraftSessionStore implements DraftSessionStore {
  _RecordingDraftSessionStore({
    this.failuresBeforeSuccess = 0,
    this.autoComplete = true,
    DraftSessionSnapshot? initialSnapshot,
  }) : _snapshot = initialSnapshot;

  final int failuresBeforeSuccess;
  final bool autoComplete;
  final List<DraftChange> upserts = <DraftChange>[];
  final List<DraftChange> completedUpserts = <DraftChange>[];
  final List<_PendingUpsert> _pendingUpserts = <_PendingUpsert>[];

  DraftSessionSnapshot? _snapshot;
  int upsertAttempts = 0;
  int clearCount = 0;

  List<String?> get pendingUpsertLabels =>
      _pendingUpserts.map((pending) => pending.change.targetId).toList();

  @override
  Future<DraftSessionSnapshot?> current() async {
    return _snapshot;
  }

  @override
  Future<void> upsert(DraftChange change) {
    upsertAttempts += 1;
    if (upsertAttempts <= failuresBeforeSuccess) {
      throw StateError('Injected save failure #$upsertAttempts');
    }

    if (autoComplete) {
      _commit(change);
      return Future<void>.value();
    }

    final pending = _PendingUpsert(change);
    _pendingUpserts.add(pending);
    return pending.completer.future.then((_) {
      _pendingUpserts.remove(pending);
      _commit(change);
    });
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    _snapshot = null;
  }

  void completeNextUpsert() {
    if (_pendingUpserts.isEmpty) {
      throw StateError('No pending upsert to complete.');
    }
    _pendingUpserts.first.completer.complete();
  }

  void _commit(DraftChange change) {
    upserts.add(change);
    completedUpserts.add(change);
    _snapshot = DraftSessionSnapshot(
      targetId: change.targetId,
      draftJson: change.draftJson,
      isNew: change.isNew,
      cursorPos: change.cursorPos,
      lastUpdated: DateTime.utc(2026, 5, 30),
    );
  }
}

class _PendingUpsert {
  _PendingUpsert(this.change);

  final DraftChange change;
  final Completer<void> completer = Completer<void>();
}
