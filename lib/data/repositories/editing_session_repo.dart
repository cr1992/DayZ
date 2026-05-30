// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart' show Value;

import '../database.dart';

class EditingSessionRepo {
  static const String currentId = 'current';

  final AppDatabase _db;

  EditingSessionRepo(this._db);

  Future<EditingSession?> current() {
    return _db.editingSessionDao.byId(currentId);
  }

  Future<EditingSession> upsert({
    String? targetId,
    String? draftJson,
    bool isNew = false,
    int? cursorPos,
  }) {
    return _db.transaction(() async {
      await _db.delete(_db.editingSessions).go();
      await _db.editingSessionDao.upsertSession(
        EditingSessionsCompanion.insert(
          id: currentId,
          targetId: Value(targetId),
          draftJson: Value(draftJson),
          cursorPos: Value(cursorPos),
          isNew: Value(isNew),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final session = await current();
      if (session == null) {
        throw StateError('Editing session upsert failed');
      }
      return session;
    });
  }

  Future<void> clear() async {
    await _db.editingSessionDao.deleteSession(currentId);
  }
}
