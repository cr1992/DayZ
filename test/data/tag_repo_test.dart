// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';

void main() {
  late AppDatabase db;
  late EntryRepo entryRepo;
  late TagRepo tagRepo;

  setUpAll(initTimezoneData);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    entryRepo = EntryRepo(db);
    tagRepo = TagRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('deduplicates names and manages entry associations', () async {
    final entry = await entryRepo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30),
      entryTz: 'UTC',
    );
    final tag = await tagRepo.create('work');
    final duplicate = await tagRepo.create('work');

    expect(duplicate.id, tag.id);
    expect(await tagRepo.list(), hasLength(1));

    await tagRepo.attach(entry.id, tag.id);
    await tagRepo.attach(entry.id, tag.id);
    expect((await tagRepo.listForEntry(entry.id)).map((row) => row.id), [
      tag.id,
    ]);
    expect((await tagRepo.listEntriesForTag(tag.id)).map((row) => row.id), [
      entry.id,
    ]);

    await tagRepo.detach(entry.id, tag.id);
    expect(await tagRepo.listForEntry(entry.id), isEmpty);

    await tagRepo.softDelete(tag.id);
    expect(await tagRepo.list(), isEmpty);

    final restored = await tagRepo.create('work');
    expect(restored.id, tag.id);
    expect(restored.deletedAt, isNull);

    await tagRepo.hardDelete(tag.id);
    expect(await db.tagsDao.byId(tag.id), isNull);
  });
}
