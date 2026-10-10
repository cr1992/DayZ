// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/journal_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/search/search_source.dart';
import 'package:dayz/ui/search/search_state.dart';

void main() {
  late AppDatabase db;
  late EntryRepo entries;

  setUpAll(initTimezoneData);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    entries = EntryRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Entry> add(
    String text,
    DateTime utc, {
    String? journalId,
    String? placeName,
    String tz = 'Etc/UTC',
  }) {
    return entries.create(
      journalId: journalId,
      contentJson: '{}',
      contentPlain: text,
      entryDtUtc: utc,
      entryTz: tz,
      placeName: placeName,
    );
  }

  test('maps entries to hits: title / excerpt / local date / place', () async {
    final entry = await add(
      '\n  外婆教我腌的梅子  \n玻璃罐要先用开水烫过\n\n她说急不得',
      // 东八区 5/27 07:30 = UTC 5/26 23:30：日期取本地年月日。
      DateTime.utc(2026, 5, 26, 23, 30),
      tz: 'Asia/Shanghai',
      placeName: '  杭州 ',
    );
    await add('别的', DateTime.utc(2026, 1, 1), placeName: '   ');

    final source = RepoSearchSource(entryRepo: entries);
    final hit = (await source.search('梅子', SearchFilters.none)).single;

    expect(hit.id, entry.id);
    expect(hit.title, '外婆教我腌的梅子');
    expect(hit.excerpt, '玻璃罐要先用开水烫过 她说急不得');
    expect(hit.date, DateTime(2026, 5, 27));
    expect(hit.place, '杭州');
    expect(hit.tags, isEmpty);

    final blankPlace = (await source.search('别的', SearchFilters.none)).single;
    expect(blankPlace.place, isNull);
    expect(blankPlace.excerpt, '');
  });

  test('filters are passed through to EntryRepo.search', () async {
    final home = await JournalRepo(db).create('家');
    final inHome = await add(
      '梅子 家',
      DateTime.utc(2026, 5, 1),
      journalId: home.id,
    );
    await add('梅子 别处', DateTime.utc(2026, 4, 1));
    await add('梅子 去年', DateTime.utc(2025, 4, 1), journalId: home.id);

    final source = RepoSearchSource(entryRepo: entries);
    final hits = await source.search(
      '梅子',
      SearchFilters(
        journal: SearchJournalFilter(id: home.id, name: '家'),
        year: 2026,
      ),
    );
    expect(hits.map((hit) => hit.id), [inHome.id]);
  });

  test('recent searches: dedupe, newest first, capped, with counts', () async {
    await add('梅子', DateTime.utc(2026, 1, 1));
    await add('梅子 梅雨', DateTime.utc(2026, 1, 2));
    final source = RepoSearchSource(entryRepo: entries);
    expect(await source.recent(), isEmpty);

    await source.search('梅子', SearchFilters.none);
    await source.search('梅雨', SearchFilters.none);
    await source.search('  梅子 ', SearchFilters.none);
    var recent = await source.recent();
    expect(recent.map((item) => item.term), ['梅子', '梅雨']);
    expect(recent.map((item) => item.count), [2, 1]);

    for (final term in ['a', 'b', 'c', 'd', 'e']) {
      await source.search(term, SearchFilters.none);
    }
    recent = await source.recent();
    expect(recent, hasLength(RepoSearchSource.maxRecent));
    expect(recent.first.term, 'e');
    expect(recent.first.count, 0);
    expect(recent.map((item) => item.term), isNot(contains('梅雨')));
  });

  test('tags(): empty without TagRepo, active tags with it', () async {
    expect(await RepoSearchSource(entryRepo: entries).tags(), isEmpty);

    final tagRepo = TagRepo(db);
    final life = await tagRepo.create('生活');
    final gone = await tagRepo.create('旧标签');
    await tagRepo.softDelete(gone.id);

    final tags = await RepoSearchSource(
      entryRepo: entries,
      tagRepo: tagRepo,
    ).tags();
    expect(tags.map((tag) => (tag.id, tag.name)), [(life.id, '生活')]);
  });

  test('changes() emits when entries are written', () async {
    final source = RepoSearchSource(entryRepo: entries);
    final first = source.changes().first;
    await add('新写的一篇', DateTime.utc(2026, 1, 1));
    await expectLater(first, completes);
  });
}
