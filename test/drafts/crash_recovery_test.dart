// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/editing_session_repo.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/lifecycle_bridge.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late EditingSessionRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EditingSessionRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('完整草稿残留在重启后可被 startupCheck 检测', () async {
    const draftJson = '{"type":"doc","content":[{"text":"kept"}]}';
    await repo.upsert(
      targetId: 'entry-1',
      draftJson: draftJson,
      isNew: false,
      cursorPos: 7,
    );

    final coordinator = DraftCoordinator(store: EditingSessionDraftStore(repo));
    final status = await coordinator.startupCheck();
    final rows = await db.select(db.editingSessions).get();

    expect(status.hasResidual, isTrue);
    expect(status.targetId, 'entry-1');
    expect(rows, hasLength(1));
    expect(jsonDecode(rows.single.draftJson!), isA<Map<String, Object?>>());
  });

  test('写盘异常不留下半截 JSON', () async {
    const previousJson = '{"type":"doc","content":[{"text":"previous"}]}';
    await repo.upsert(
      targetId: 'entry-1',
      draftJson: previousJson,
      isNew: false,
    );

    final store = _FailingDraftSessionStore(repo);
    final coordinator = DraftCoordinator(
      store: store,
      debounceDuration: Duration.zero,
      retryDelays: List<Duration>.filled(3, Duration.zero),
    );

    coordinator.onChanged(
      targetId: 'entry-1',
      draftJson: '{"type":"doc","content":[{"text":"new"}]}',
      isNew: false,
    );
    await coordinator.forceFlush();

    final rows = await db.select(db.editingSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.draftJson, previousJson);
    expect(jsonDecode(rows.single.draftJson!), isA<Map<String, Object?>>());
    expect(coordinator.saveErrors, hasLength(1));
  });

  test('paused 路径强制保存最新完整 JSON', () async {
    final coordinator = DraftCoordinator(
      store: EditingSessionDraftStore(repo),
      debounceDuration: const Duration(minutes: 1),
    );
    final bridge = LifecycleBridge(coordinator: coordinator);

    coordinator.onChanged(
      targetId: 'entry-2',
      draftJson: '{"type":"doc","content":[{"text":"latest"}]}',
      isNew: true,
      cursorPos: 11,
    );

    await bridge.handleLifecycleState(AppLifecycleState.paused);

    final rows = await db.select(db.editingSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.targetId, 'entry-2');
    expect(rows.single.isNew, isTrue);
    expect(rows.single.cursorPos, 11);
    expect(
      jsonDecode(rows.single.draftJson!),
      equals({
        'type': 'doc',
        'content': [
          {'text': 'latest'},
        ],
      }),
    );
  });

  test('多次 upsert 后 editing_session 始终至多一行', () async {
    final coordinator = DraftCoordinator(
      store: EditingSessionDraftStore(repo),
      debounceDuration: Duration.zero,
    );

    for (var i = 0; i < 5; i += 1) {
      coordinator.onChanged(
        targetId: 'entry-$i',
        draftJson: '{"type":"doc","content":[{"text":"draft-$i"}]}',
        isNew: false,
      );
      await coordinator.forceFlush();

      final rows = await db.select(db.editingSessions).get();
      expect(rows, hasLength(1));
      expect(jsonDecode(rows.single.draftJson!), isA<Map<String, Object?>>());
    }
  });
}

class _FailingDraftSessionStore implements DraftSessionStore {
  const _FailingDraftSessionStore(this._repo);

  final EditingSessionRepo _repo;

  @override
  Future<DraftSessionSnapshot?> current() async {
    final session = await _repo.current();
    if (session == null) {
      return null;
    }
    return DraftSessionSnapshot(
      targetId: session.targetId,
      draftJson: session.draftJson,
      isNew: session.isNew,
      cursorPos: session.cursorPos,
      lastUpdated: session.updatedAt,
    );
  }

  @override
  Future<void> upsert(DraftChange change) async {
    throw StateError('Injected write interruption');
  }

  @override
  Future<void> clear() {
    return _repo.clear();
  }
}
