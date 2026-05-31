// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

class FakeDraftChange {
  const FakeDraftChange({
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

class FakeDraftCoordinator {
  final List<FakeDraftChange> changes = <FakeDraftChange>[];

  int forceFlushCount = 0;
  bool disposed = false;

  FakeDraftChange? get lastChange => changes.isEmpty ? null : changes.last;

  void onChanged({
    required String? targetId,
    required String draftJson,
    required bool isNew,
    int? cursorPos,
  }) {
    changes.add(
      FakeDraftChange(
        targetId: targetId,
        draftJson: draftJson,
        isNew: isNew,
        cursorPos: cursorPos,
      ),
    );
  }

  Future<void> forceFlush() async {
    forceFlushCount += 1;
  }

  void dispose() {
    disposed = true;
  }
}
