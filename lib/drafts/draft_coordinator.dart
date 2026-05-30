// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'draft_recovery_status.dart';

class DraftChange {
  const DraftChange({
    required this.targetId,
    required this.draftJson,
    required this.isNew,
    required this.cursorPos,
  });

  final String? targetId;
  final String draftJson;
  final bool isNew;
  final int? cursorPos;
}

class DraftCoordinator {
  DraftChange? _lastChange;

  DraftChange? get lastChange => _lastChange;

  void onChanged({
    required String? targetId,
    required String draftJson,
    required bool isNew,
    int? cursorPos,
  }) {
    _lastChange = DraftChange(
      targetId: targetId,
      draftJson: draftJson,
      isNew: isNew,
      cursorPos: cursorPos,
    );
  }

  Future<void> forceFlush() async {}

  Future<void> clear() async {
    _lastChange = null;
  }

  Future<DraftRecoveryStatus> startupCheck() async {
    return const DraftRecoveryStatus(hasResidual: false);
  }
}
