// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/journal_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';

void main() {
  late AppDatabase db;
  late EntryRepo entries;
  late JournalRepo journals;
  late String workId;
  late String lifeId;

  setUpAll(initTimezoneData);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    entries = EntryRepo(db);
    journals = JournalRepo(db);
    workId = (await journals.create('Work')).id;
    lifeId = (await journals.create('Life')).id;
  });

  tearDown(() async {
    await db.close();
  });

  Future<Entry> add(String? journalId, DateTime utc, String text) {
    return entries.create(
      journalId: journalId,
      contentJson: '{}',
      contentPlain: text,
      entryDtUtc: utc,
      entryTz: 'Etc/UTC',
    );
  }

  test('timeline filters by journal in SQL and keeps cursor paging', () async {
    for (var day = 1; day <= 5; day++) {
      await add(workId, DateTime.utc(2026, 3, day, 9), 'work $day');
      await add(lifeId, DateTime.utc(2026, 3, day, 10), 'life $day');
    }

    final first = await entries.timeline(journalId: workId, limit: 3);
    expect(first.items.map((e) => e.journalId).toSet(), {workId});
    expect(first.items.map((e) => e.contentPlain), [
      'work 5',
      'work 4',
      'work 3',
    ]);
    expect(first.nextCursor, isNotNull);

    final second = await entries.timeline(
      journalId: workId,
      cursor: first.nextCursor,
      limit: 3,
    );
    expect(second.items.map((e) => e.contentPlain), ['work 2', 'work 1']);
    expect(second.nextCursor, isNull);

    final all = await entries.timeline(limit: 100);
    expect(all.items, hasLength(10));
  });

  test('countByMonth groups by local month, excludes soft-deleted', () async {
    await add(workId, DateTime.utc(2026, 1, 3), 'a');
    await add(workId, DateTime.utc(2026, 1, 20), 'b');
    final deleted = await add(workId, DateTime.utc(2026, 1, 21), 'c');
    await add(lifeId, DateTime.utc(2026, 2, 14), 'd');
    await add(null, DateTime.utc(2025, 12, 31), 'e');
    await entries.softDelete(deleted.id);

    expect(await entries.countByMonth(), {
      (2026, 1): 2,
      (2026, 2): 1,
      (2025, 12): 1,
    });
    expect(await entries.countByMonth(journalId: workId), {(2026, 1): 2});
    expect(await entries.countByMonth(journalId: lifeId), {(2026, 2): 1});
  });

  test('entryDaysOfMonth returns distinct days per journal', () async {
    await add(workId, DateTime.utc(2026, 4, 2, 8), 'a');
    await add(workId, DateTime.utc(2026, 4, 2, 20), 'b');
    await add(lifeId, DateTime.utc(2026, 4, 9), 'c');
    final deleted = await add(workId, DateTime.utc(2026, 4, 30), 'd');
    await add(workId, DateTime.utc(2026, 5, 1), 'e');
    await entries.softDelete(deleted.id);

    expect(await entries.entryDaysOfMonth(year: 2026, month: 4), {2, 9});
    expect(
      await entries.entryDaysOfMonth(journalId: workId, year: 2026, month: 4),
      {2},
    );
    expect(await entries.entryDaysOfMonth(year: 2026, month: 6), isEmpty);
  });
}
