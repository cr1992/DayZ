// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/journal_repo.dart';

void main() {
  late AppDatabase db;
  late JournalRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = JournalRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates lists renames reorders and deletes journals', () async {
    final first = await repo.create('Work', color: '#ff0000', sortOrder: 2);
    final second = await repo.create('Life', color: '#00ff00', sortOrder: 1);

    expect(first.name, 'Work');
    expect(first.color, '#ff0000');
    expect((await repo.list()).map((row) => row.id), [second.id, first.id]);

    final renamed = await repo.rename(first.id, 'Archive');
    expect(renamed.name, 'Archive');
    expect(
      renamed.updatedAt.toUtc().isBefore(first.updatedAt.toUtc()),
      isFalse,
    );

    final reordered = await repo.reorder(first.id, 0);
    expect(reordered.sortOrder, 0);
    expect((await repo.list()).map((row) => row.id), [first.id, second.id]);

    await repo.softDelete(first.id);
    expect((await repo.list()).map((row) => row.id), [second.id]);

    final softDeleted = await db.journalsDao.byId(first.id);
    expect(softDeleted, isNotNull);
    expect(softDeleted!.deletedAt, isNotNull);

    await repo.hardDelete(first.id);
    expect(await db.journalsDao.byId(first.id), isNull);
  });
}
