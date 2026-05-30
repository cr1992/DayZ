// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/draft_recovery_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraftRecoveryStatus', () {
    test('构造后四个字段如实回读', () {
      final timestamp = DateTime.utc(2026, 5, 30, 12, 30);
      final status = DraftRecoveryStatus(
        hasResidual: true,
        targetId: 'entry-1',
        isNew: true,
        lastUpdated: timestamp,
      );

      expect(status.hasResidual, isTrue);
      expect(status.targetId, 'entry-1');
      expect(status.isNew, isTrue);
      expect(status.lastUpdated, timestamp);
    });

    test('无残留状态允许 targetId 和 lastUpdated 为空', () {
      const status = DraftRecoveryStatus(hasResidual: false);

      expect(status.hasResidual, isFalse);
      expect(status.targetId, isNull);
      expect(status.isNew, isFalse);
      expect(status.lastUpdated, isNull);
    });
  });

  group('DraftCoordinator contract', () {
    test('onChanged 接受 plain payload 并记录最后一次输入', () {
      final coordinator = DraftCoordinator();

      coordinator.onChanged(
        targetId: 'entry-1',
        draftJson: '{"type":"doc","content":[]}',
        isNew: false,
        cursorPos: 8,
      );

      final change = coordinator.lastChange;
      expect(change, isNotNull);
      expect(change!.targetId, 'entry-1');
      expect(change.draftJson, '{"type":"doc","content":[]}');
      expect(change.isNew, isFalse);
      expect(change.cursorPos, 8);
    });

    test('onChanged 接受新建草稿和空 targetId', () {
      final coordinator = DraftCoordinator();

      coordinator.onChanged(
        targetId: null,
        draftJson: '{"text":"draft"}',
        isNew: true,
      );

      final change = coordinator.lastChange;
      expect(change, isNotNull);
      expect(change!.targetId, isNull);
      expect(change.draftJson, '{"text":"draft"}');
      expect(change.isNew, isTrue);
      expect(change.cursorPos, isNull);
    });

    test('clear 清空最后一次输入', () async {
      final coordinator = DraftCoordinator()
        ..onChanged(targetId: 'entry-1', draftJson: '{}', isNew: false);

      await coordinator.clear();

      expect(coordinator.lastChange, isNull);
    });

    test('startupCheck 骨架默认返回无残留状态', () async {
      final status = await DraftCoordinator().startupCheck();

      expect(status.hasResidual, isFalse);
      expect(status.targetId, isNull);
      expect(status.isNew, isFalse);
      expect(status.lastUpdated, isNull);
    });
  });
}
