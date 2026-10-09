// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';

import '../database.dart';
import '../ids.dart';

class JournalRepo {
  final AppDatabase _db;

  JournalRepo(this._db);

  Future<List<Journal>> list() {
    return _db.journalsDao.active().get();
  }

  /// 各日记本的未删除条目数（未归属日记本的条目不计入）。
  Future<Map<String, int>> entryCounts() async {
    final count = _db.entries.id.count();
    final query = _db.selectOnly(_db.entries)
      ..addColumns([_db.entries.journalId, count])
      ..where(_db.entries.deletedAt.isNull() & _db.entries.journalId.isNotNull())
      ..groupBy([_db.entries.journalId]);

    final rows = await query.get();
    return {
      for (final row in rows) row.read(_db.entries.journalId)!: row.read(count)!,
    };
  }

  Future<Journal> create(
    String name, {
    String? color,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final id = Ids.next();

    await _db.journalsDao.insertJournal(
      JournalsCompanion.insert(
        id: id,
        name: name,
        color: Value(color),
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return _requireActiveJournal(id);
  }

  Future<Journal> rename(String id, String name) async {
    final journal = await _requireActiveJournal(id);
    final updated = journal.copyWith(
      name: name,
      updatedAt: DateTime.now().toUtc(),
    );
    await _db.journalsDao.updateJournal(updated.toCompanion(false));
    return _requireActiveJournal(id);
  }

  Future<Journal> reorder(String id, int sortOrder) async {
    final journal = await _requireActiveJournal(id);
    final updated = journal.copyWith(
      sortOrder: sortOrder,
      updatedAt: DateTime.now().toUtc(),
    );
    await _db.journalsDao.updateJournal(updated.toCompanion(false));
    return _requireActiveJournal(id);
  }

  Future<void> softDelete(String id) async {
    await _requireActiveJournal(id);
    await _db.journalsDao.softDelete(id);
  }

  Future<void> hardDelete(String id) async {
    await _db.journalsDao.hardDelete(id);
  }

  Future<Journal> _requireActiveJournal(String id) async {
    final journal = await _db.journalsDao.byId(id);
    if (journal == null || journal.deletedAt != null) {
      throw StateError('Journal not found: $id');
    }
    return journal;
  }
}
