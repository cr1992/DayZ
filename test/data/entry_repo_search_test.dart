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
  late EntryRepo repo;

  setUpAll(initTimezoneData);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EntryRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Entry> add(String text, DateTime utc, {String? journalId}) {
    return repo.create(
      journalId: journalId,
      contentJson: '{}',
      contentPlain: text,
      entryDtUtc: utc,
      entryTz: 'Etc/UTC',
    );
  }

  test('substring match on content_plain, newest first', () async {
    final older = await add('外婆教我腌的梅子\n玻璃罐', DateTime.utc(2025, 6, 12));
    final newer = await add('开了去年的那罐\n梅子的颜色变深', DateTime.utc(2026, 5, 27));
    await add('今天下雨', DateTime.utc(2026, 5, 28));

    final hits = await repo.search('梅子');
    expect(hits.map((entry) => entry.id), [newer.id, older.id]);
  });

  test('ASCII matching is case-insensitive', () async {
    final entry = await add('Plum jam with grandma', DateTime.utc(2026, 1, 1));
    expect((await repo.search('PLUM')).single.id, entry.id);
    expect((await repo.search('plum jam')).single.id, entry.id);
  });

  test('% and _ are matched literally, not as wildcards', () async {
    final percent = await add('完成了 100% 的计划', DateTime.utc(2026, 1, 1));
    final underscore = await add('file_name 命名', DateTime.utc(2026, 1, 2));
    await add('完成了 1000 个计划', DateTime.utc(2026, 1, 3));
    await add('filexname', DateTime.utc(2026, 1, 4));

    expect((await repo.search('100%')).single.id, percent.id);
    expect((await repo.search('e_n')).single.id, underscore.id);
    expect(await repo.search(r'\'), isEmpty);
  });

  test('soft-deleted entries are excluded', () async {
    final kept = await add('梅子一', DateTime.utc(2026, 1, 1));
    final gone = await add('梅子二', DateTime.utc(2026, 1, 2));
    await repo.softDelete(gone.id);

    expect((await repo.search('梅子')).single.id, kept.id);
  });

  test('journal and year filters narrow the result', () async {
    final journals = JournalRepo(db);
    final home = await journals.create('家', color: '#7c5cff', sortOrder: 0);
    final inHome2026 = await add(
      '梅子 家 2026',
      DateTime.utc(2026, 5, 1),
      journalId: home.id,
    );
    final inHome2025 = await add(
      '梅子 家 2025',
      DateTime.utc(2025, 5, 1),
      journalId: home.id,
    );
    final other2026 = await add('梅子 别处 2026', DateTime.utc(2026, 4, 1));

    expect(
      (await repo.search('梅子', journalId: home.id)).map((entry) => entry.id),
      [inHome2026.id, inHome2025.id],
    );
    expect((await repo.search('梅子', year: 2026)).map((entry) => entry.id), [
      inHome2026.id,
      other2026.id,
    ]);
    expect(
      (await repo.search('梅子', journalId: home.id, year: 2025)).single.id,
      inHome2025.id,
    );
  });

  test(
    'limit truncates; blank query returns empty; bad limit throws',
    () async {
      for (var day = 1; day <= 5; day++) {
        await add('梅子 $day', DateTime.utc(2026, 1, day));
      }
      final limited = await repo.search('梅子', limit: 2);
      expect(limited.map((entry) => entry.contentPlain), ['梅子 5', '梅子 4']);
      expect(await repo.search('   '), isEmpty);
      expect(() => repo.search('梅子', limit: 0), throwsArgumentError);
    },
  );
}
