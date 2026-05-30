// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';

void main() {
  late AppDatabase db;
  late EntryRepo entryRepo;
  late MediaRepo mediaRepo;

  setUpAll(initTimezoneData);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    entryRepo = EntryRepo(db);
    mediaRepo = MediaRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'addMeta preserves caller provided id and manages thumbnail/deletes',
    () async {
      final entry = await entryRepo.create(
        contentJson: '{"insert":"hello"}',
        contentPlain: 'hello',
        entryDtUtc: DateTime.utc(2026, 5, 30),
        entryTz: 'UTC',
      );

      final media = await mediaRepo.addMeta(
        'media-from-store',
        entry.id,
        'image',
        'media-from-store.bin',
        width: 320,
        height: 240,
      );

      expect(media.id, 'media-from-store');
      expect(media.entryId, entry.id);
      expect(media.width, 320);
      expect(await mediaRepo.listByEntry(entry.id), hasLength(1));

      final srcUpdatedAt = DateTime.utc(2026, 5, 30, 12);
      final withThumb = await mediaRepo.updateThumb(
        media.id,
        thumbPath: 'thumbs/media-from-store.jpg',
        w: 80,
        h: 60,
        srcUpdatedAt: srcUpdatedAt,
      );
      expect(withThumb.thumbPath, 'thumbs/media-from-store.jpg');
      expect(withThumb.thumbW, 80);
      expect(withThumb.thumbSrcUpdatedAt?.toUtc(), srcUpdatedAt);

      await mediaRepo.softDelete(media.id);
      expect(await mediaRepo.listByEntry(entry.id), isEmpty);
      expect(await db.mediaDao.byId(media.id), isNotNull);

      await mediaRepo.hardDelete(media.id);
      expect(await db.mediaDao.byId(media.id), isNull);
    },
  );
}
