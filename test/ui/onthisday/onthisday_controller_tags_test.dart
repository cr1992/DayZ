// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/app/router_ports.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/onthisday/onthisday_controller.dart';
import 'package:dayz/ui/onthisday/onthisday_view_model.dart';

import '../../app/app_test_db.dart';

/// 统计读 entry_tags 的 SELECT 次数（只在 [counting] 打开后计）。
class _EntryTagSelectCounter extends QueryInterceptor {
  int selects = 0;
  bool counting = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (counting && statement.contains('entry_tags')) {
      selects += 1;
    }
    return super.runSelect(executor, statement, args);
  }
}

Map<String, List<String>> _tagsByEntry(OnThisDayData data) {
  return {
    for (final EntryCardVM card in data.groups.expand((g) => g.entries))
      card.entryId: card.tags,
  };
}

void main() {
  setUpAll(initTimezoneData);

  group('DataLayerOnThisDayRepository with tags', () {
    late _EntryTagSelectCounter counter;
    late AppDatabase db;
    late EntryRepo entries;
    late MediaRepo media;
    late TagRepo tags;
    late String older;
    late String newer;
    late String untagged;

    setUp(() async {
      counter = _EntryTagSelectCounter();
      db = AppDatabase(NativeDatabase.memory().interceptWith(counter));
      entries = EntryRepo(db);
      media = MediaRepo(db);
      tags = TagRepo(db);

      Future<String> add(DateTime utc, String text) async {
        final entry = await entries.create(
          contentJson: '{}',
          contentPlain: text,
          entryDtUtc: utc,
          entryTz: 'Etc/UTC',
        );
        return entry.id;
      }

      older = await add(DateTime.utc(2021, 5, 29, 9), 'older\nbody');
      newer = await add(DateTime.utc(2024, 5, 29, 9), 'newer\nbody');
      untagged = await add(DateTime.utc(2023, 5, 29, 9), 'plain\nbody');
      await add(DateTime.utc(2024, 5, 28, 9), 'other day');

      final work = await tags.create('work');
      final art = await tags.create('art');
      final gone = await tags.create('gone');
      await tags.attach(older, work.id);
      await tags.attach(older, art.id);
      await tags.attach(older, gone.id);
      await tags.attach(newer, work.id);
      await tags.softDelete(gone.id);
    });

    tearDown(() => db.close());

    test(
      'R5: VM cards carry sorted active tag names via one batch query',
      () async {
        final controller = OnThisDayController(
          repository: DataLayerOnThisDayRepository(
            entryRepo: entries,
            mediaRepo: media,
            tagRepo: tags,
          ),
          clock: () => DateTime(2026, 5, 29),
        );
        addTearDown(controller.dispose);

        counter.counting = true;
        await controller.load();

        expect(counter.selects, 1);
        expect(_tagsByEntry(controller.data!), {
          newer: ['work'],
          untagged: <String>[],
          older: ['art', 'work'],
        });
      },
    );

    test('R5: port without a tag repo keeps cards tag-less', () async {
      final controller = OnThisDayController(
        repository: DataLayerOnThisDayRepository(
          entryRepo: entries,
          mediaRepo: media,
        ),
        clock: () => DateTime(2026, 5, 29),
      );
      addTearDown(controller.dispose);

      counter.counting = true;
      await controller.load();

      expect(counter.selects, 0);
      final data = controller.data!;
      expect(data.totalCount, 3);
      expect(_tagsByEntry(data).values.every((t) => t.isEmpty), isTrue);
      expect(data.groups.first.entries.single.title, 'newer');
    });
  });

  test('R5: bindRouterPorts registers an on-this-day port with tags', () async {
    final services = inMemoryServices();
    addTearDown(services.close);
    final entry = await addEntry(
      services,
      utc: DateTime.utc(2022, 5, 29, 9),
      text: 'tagged',
    );
    final tags = TagRepo(services.database);
    await tags.attach(entry.id, (await tags.create('trip')).id);

    bindRouterPorts(services);
    addTearDown(unbindRouterPorts);

    final records = await onThisDayRepositoryPort!.onThisDay(5, 29);
    expect(records.single.tags, ['trip']);
  });
}
