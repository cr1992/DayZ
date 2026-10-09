// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';

import 'app_test_db.dart';

void main() {
  late AppServices services;
  late String workId;
  late String lifeId;

  setUpAll(initTimezoneData);

  setUp(() async {
    services = inMemoryServices();
    workId = (await services.journals.create('Work')).id;
    lifeId = (await services.journals.create('Life')).id;
    await addEntry(
      services,
      journalId: workId,
      utc: DateTime.utc(2026, 3, 2),
      text: 'w1',
    );
    await addEntry(
      services,
      journalId: workId,
      utc: DateTime.utc(2026, 3, 9),
      text: 'w2',
    );
    await addEntry(
      services,
      journalId: lifeId,
      utc: DateTime.utc(2026, 2, 5),
      text: 'l1',
    );
  });

  tearDown(() => services.close());

  test(
    'adapter exposes SQL month counts and entry days as timeline types',
    () async {
      final repo = services.timelineRepo;

      expect(await repo.monthCounts(null), {
        const TimelineMonthKey(2026, 3): 2,
        const TimelineMonthKey(2026, 2): 1,
      });
      expect(await repo.monthCounts(lifeId), {
        const TimelineMonthKey(2026, 2): 1,
      });
      expect(await repo.entryDaysInMonth(workId, 2026, 3), {2, 9});
      expect(await repo.entryDaysInMonth(lifeId, 2026, 3), isEmpty);
    },
  );

  test(
    'controller over adapter filters journal via repo and uses SQL counts',
    () async {
      final controller = TimelineController(repo: services.timelineRepo);
      addTearDown(controller.dispose);

      await controller.loadInitial(workId);
      final ids = controller.sections
          .expand((s) => s.entries)
          .map((e) => e.journalId);
      expect(ids.toSet(), {workId});
      expect(controller.reachedEnd, isTrue);
      expect(controller.monthCountFor(2026, 3), 2);
      expect(await controller.entryDaysInMonth(2026, 3), {2, 9});

      // 每页 1 条时二月尚未加载，计数仍可得：说明来自 SQL 计数而非已加载分页累计。
      final paged = TimelineController(
        repo: services.timelineRepo,
        pageSize: 1,
      );
      addTearDown(paged.dispose);
      await paged.loadInitial(null);
      expect(paged.sections.map((s) => s.key), [
        const TimelineMonthKey(2026, 3),
      ]);
      expect(paged.monthCountFor(2026, 2), 1);
      expect(await paged.entryDaysInMonth(2026, 2), {5});
    },
  );
}
