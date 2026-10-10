// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';

/// 统计打到库上的 SELECT（只算读 entry_tags 的查询，排除建表 / 写入）。
class _SelectCounter extends QueryInterceptor {
  int entryTagSelects = 0;
  bool counting = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (counting && statement.contains('entry_tags')) {
      entryTagSelects += 1;
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late EntryRepo entryRepo;
  late TagRepo tagRepo;
  late _SelectCounter counter;

  setUpAll(initTimezoneData);

  setUp(() {
    counter = _SelectCounter();
    db = AppDatabase(NativeDatabase.memory().interceptWith(counter));
    entryRepo = EntryRepo(db);
    tagRepo = TagRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> newEntry(int day) async {
    final entry = await entryRepo.create(
      contentJson: '{}',
      contentPlain: 'entry $day',
      entryDtUtc: DateTime.utc(2026, 5, day),
      entryTz: 'Etc/UTC',
    );
    return entry.id;
  }

  test(
    'R1: maps every requested id to its active tags sorted by name',
    () async {
      final a = await newEntry(1);
      final b = await newEntry(2);
      final untagged = await newEntry(3);
      final work = await tagRepo.create('work');
      final art = await tagRepo.create('art');
      final travel = await tagRepo.create('travel');
      final gone = await tagRepo.create('gone');

      await tagRepo.attach(a, work.id);
      await tagRepo.attach(a, art.id);
      await tagRepo.attach(a, gone.id);
      await tagRepo.attach(b, travel.id);
      await tagRepo.attach(b, art.id);
      await tagRepo.softDelete(gone.id);

      final result = await tagRepo.tagsByEntryIds([
        a,
        b,
        untagged,
        'missing-id',
        a,
      ]);

      expect(result.keys.toSet(), {a, b, untagged, 'missing-id'});
      expect(result[a]!.map((tag) => tag.name), ['art', 'work']);
      expect(result[b]!.map((tag) => tag.name), ['art', 'travel']);
      expect(result[untagged], isEmpty);
      expect(result['missing-id'], isEmpty);
      // 与逐条 listForEntry 的结果一致（同一份真相）。
      for (final id in [a, b, untagged]) {
        expect(
          result[id]!.map((tag) => tag.id),
          (await tagRepo.listForEntry(id)).map((tag) => tag.id),
        );
      }
    },
  );

  test('R2: empty input returns {} without touching the database', () async {
    counter.counting = true;
    final result = await tagRepo.tagsByEntryIds(const <String>[]);

    expect(result, isEmpty);
    expect(counter.entryTagSelects, 0);
  });

  test('R2: one batch of ids is read with exactly one JOIN query', () async {
    final tag = await tagRepo.create('daily');
    final ids = <String>[];
    for (var day = 1; day <= 28; day += 1) {
      final id = await newEntry(day);
      await tagRepo.attach(id, tag.id);
      ids.add(id);
    }

    counter.counting = true;
    final result = await tagRepo.tagsByEntryIds(ids);

    expect(counter.entryTagSelects, 1);
    expect(result.length, 28);
    expect(result.values.every((tags) => tags.single.name == 'daily'), isTrue);
  });

  test(
    'R2: ids beyond the chunk limit split into one query per chunk',
    () async {
      final tag = await tagRepo.create('bulk');
      final tagged = await newEntry(1);
      await tagRepo.attach(tagged, tag.id);
      final ids = <String>[
        tagged,
        for (var i = 0; i < TagRepo.tagsByEntryIdsChunkSize; i += 1) 'ghost-$i',
      ];

      counter.counting = true;
      final result = await tagRepo.tagsByEntryIds(ids);

      expect(counter.entryTagSelects, 2);
      expect(result.length, TagRepo.tagsByEntryIdsChunkSize + 1);
      expect(result[tagged]!.map((tag) => tag.name), ['bulk']);
      expect(
        result.entries
            .where((entry) => entry.key != tagged)
            .every((entry) => entry.value.isEmpty),
        isTrue,
      );
    },
  );
}
