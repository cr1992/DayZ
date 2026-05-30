// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';

void main() {
  late AppDatabase db;
  late EntryRepo repo;

  setUpAll(initTimezoneData);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EntryRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('timeline cursor pagination is stable for equal timestamps', () async {
    final sameTime = DateTime.utc(2026, 5, 30, 12);
    final olderTime = DateTime.utc(2026, 5, 29, 12);

    final first = await repo.create(
      contentJson: '{"insert":"first"}',
      contentPlain: 'first',
      entryDtUtc: sameTime,
      entryTz: 'UTC',
    );
    final second = await repo.create(
      contentJson: '{"insert":"second"}',
      contentPlain: 'second',
      entryDtUtc: sameTime,
      entryTz: 'UTC',
    );
    final third = await repo.create(
      contentJson: '{"insert":"third"}',
      contentPlain: 'third',
      entryDtUtc: olderTime,
      entryTz: 'UTC',
    );

    final orderedSameTime = [first, second]
      ..sort((a, b) => b.id.compareTo(a.id));

    final page1 = await repo.timeline(limit: 2);
    expect(page1.items.map((row) => row.id), [
      orderedSameTime[0].id,
      orderedSameTime[1].id,
    ]);
    expect(page1.nextCursor, isNotNull);

    final page2 = await repo.timeline(cursor: page1.nextCursor, limit: 2);
    expect(page2.items.map((row) => row.id), [third.id]);
    expect(page2.nextCursor, isNull);

    final allIds = [...page1.items, ...page2.items].map((row) => row.id);
    expect(allIds.toSet(), hasLength(3));
  });

  test(
    'onThisDay filters active rows and sorts by local year descending',
    () async {
      final older = await repo.create(
        contentJson: '{"insert":"older"}',
        contentPlain: 'older',
        entryDtUtc: DateTime.utc(2024, 5, 30, 10),
        entryTz: 'UTC',
      );
      final newer = await repo.create(
        contentJson: '{"insert":"newer"}',
        contentPlain: 'newer',
        entryDtUtc: DateTime.utc(2026, 5, 30, 10),
        entryTz: 'UTC',
      );
      final deleted = await repo.create(
        contentJson: '{"insert":"deleted"}',
        contentPlain: 'deleted',
        entryDtUtc: DateTime.utc(2025, 5, 30, 10),
        entryTz: 'UTC',
      );

      await repo.softDelete(deleted.id);

      expect((await repo.onThisDay(5, 30)).map((row) => row.id), [
        newer.id,
        older.id,
      ]);
    },
  );

  test('update recomputes local date when time zone changes', () async {
    final entry = await repo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30, 22),
      entryTz: 'UTC',
    );
    expect(entry.localDay, 30);

    final updated = await repo.update(entry.id, entryTz: 'Asia/Shanghai');

    expect(updated.entryTz, 'Asia/Shanghai');
    expect(updated.localYear, 2026);
    expect(updated.localMonth, 5);
    expect(updated.localDay, 31);
  });

  test('crud and delete behavior use active rows by default', () async {
    final entry = await repo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30, 10),
      entryTz: 'UTC',
      isFavorite: true,
    );

    expect(await repo.byId(entry.id), isNotNull);

    final updated = await repo.update(
      entry.id,
      contentPlain: 'changed',
      isFavorite: false,
    );
    expect(updated.contentPlain, 'changed');
    expect(updated.isFavorite, isFalse);

    await repo.softDelete(entry.id);
    expect(await repo.byId(entry.id), isNull);
    expect(await db.entriesDao.byId(entry.id), isNotNull);

    await repo.hardDelete(entry.id);
    expect(await db.entriesDao.byId(entry.id), isNull);
  });
}
