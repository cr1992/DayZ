// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'entries dao softDelete filters active rows and hardDelete removes row',
    () async {
      final now = DateTime.utc(2026, 5, 30, 10);
      final deletedAt = DateTime.utc(2026, 5, 30, 11);

      await db.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'entry-1',
          contentJson: const Value('{"insert":"hello"}'),
          contentPlain: const Value('hello'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(await db.entriesDao.active().get(), hasLength(1));

      final softDeletedCount = await db.entriesDao.softDelete(
        'entry-1',
        deletedAt: deletedAt,
      );
      expect(softDeletedCount, equals(1));

      final rawRow = await db.entriesDao.byId('entry-1');
      expect(rawRow, isNotNull);
      expect(rawRow!.deletedAt?.toUtc(), equals(deletedAt));
      expect(rawRow.updatedAt.toUtc(), equals(deletedAt));
      expect(await db.entriesDao.active().get(), isEmpty);

      final hardDeletedCount = await db.entriesDao.hardDelete('entry-1');
      expect(hardDeletedCount, equals(1));
      expect(await db.entriesDao.byId('entry-1'), isNull);
    },
  );

  test('dao accessors compile and expose base operations', () async {
    final now = DateTime.utc(2026, 5, 30);

    await db.journalsDao.insertJournal(
      JournalsCompanion.insert(
        id: 'journal-1',
        name: 'Default',
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(await db.journalsDao.active().get(), hasLength(1));

    await db.tagsDao.insertTag(
      TagsCompanion.insert(id: 'tag-1', name: 'work', createdAt: now),
    );
    expect(await db.tagsDao.active().get(), hasLength(1));

    await db.entriesDao.insertEntry(
      EntriesCompanion.insert(
        id: 'entry-2',
        journalId: const Value('journal-1'),
        entryDtUtc: now,
        entryTz: 'UTC',
        localYear: 2026,
        localMonth: 5,
        localDay: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await db.mediaDao.insertMedia(
      MediaCompanion.insert(
        id: 'media-1',
        entryId: 'entry-2',
        kind: 'image',
        relPath: 'media-1.bin',
        updatedAt: now,
        createdAt: now,
      ),
    );
    expect(await db.mediaDao.listByEntry('entry-2').get(), hasLength(1));

    await db.entryTagsDao.attach('entry-2', 'tag-1');
    expect(await db.entryTagsDao.listByEntry('entry-2').get(), hasLength(1));
    expect(await db.entryTagsDao.listByTag('tag-1').get(), hasLength(1));

    await db.editingSessionDao.upsertSession(
      EditingSessionsCompanion.insert(
        id: 'current',
        targetId: const Value('entry-2'),
        draftJson: const Value('{"insert":"draft"}'),
        updatedAt: now,
      ),
    );
    expect(await db.editingSessionDao.byId('current'), isNotNull);
  });
}
