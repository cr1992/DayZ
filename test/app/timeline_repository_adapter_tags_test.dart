// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';

import 'app_test_db.dart';

void main() {
  late AppServices services;

  setUpAll(initTimezoneData);

  setUp(() {
    services = inMemoryServices();
  });

  tearDown(() => services.close());

  test(
    'R3: production timeline repo fills TimelineEntry.tags from the DB',
    () async {
      final tagged = await addEntry(
        services,
        utc: DateTime.utc(2026, 3, 9),
        text: 'tagged',
      );
      final plain = await addEntry(
        services,
        utc: DateTime.utc(2026, 3, 2),
        text: 'plain',
      );
      final tags = TagRepo(services.database);
      final work = await tags.create('work');
      final art = await tags.create('art');
      final gone = await tags.create('gone');
      await tags.attach(tagged.id, work.id);
      await tags.attach(tagged.id, art.id);
      await tags.attach(tagged.id, gone.id);
      await tags.softDelete(gone.id);

      final controller = TimelineController(repo: services.timelineRepo);
      addTearDown(controller.dispose);
      await controller.loadInitial(null);

      final byId = {
        for (final entry in controller.sections.expand((s) => s.entries))
          entry.id: entry.tags,
      };
      expect(byId[tagged.id], ['art', 'work']);
      expect(byId[plain.id], isEmpty);
    },
  );
}
