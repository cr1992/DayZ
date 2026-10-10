// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';

import 'fake_entry_repo.dart';

/// 假仓 + 标签能力：记录每次批量请求的 id 列表。
class _TaggedFakeRepo extends FakeEntryRepo
    implements TimelineEntryTagsRepository {
  _TaggedFakeRepo({super.entries, required this.tagsById});

  final Map<String, List<String>> tagsById;
  final List<List<String>> tagRequests = <List<String>>[];

  @override
  Future<Map<String, List<String>>> tagNamesByEntryIds(
    List<String> entryIds,
  ) async {
    tagRequests.add(List<String>.of(entryIds));
    return {for (final id in entryIds) id: tagsById[id] ?? const <String>[]};
  }
}

final _entries = [
  fakeEntry(id: 'e3', entryDtUtc: DateTime.utc(2026, 5, 3, 10)),
  fakeEntry(id: 'e2', entryDtUtc: DateTime.utc(2026, 5, 2, 10)),
  fakeEntry(id: 'e1', entryDtUtc: DateTime.utc(2026, 4, 1, 10)),
];

Map<String, List<String>> _tagsOf(TimelineController controller) {
  return {
    for (final TimelineEntry entry in controller.sections.expand(
      (section) => section.entries,
    ))
      entry.id: entry.tags,
  };
}

void main() {
  test(
    'R3: each page load issues exactly one batch tag request for that page',
    () async {
      final repo = _TaggedFakeRepo(
        entries: _entries,
        tagsById: {
          'e3': ['art', 'work'],
          'e1': ['travel'],
        },
      );
      final controller = TimelineController(repo: repo, pageSize: 2);
      addTearDown(controller.dispose);

      await controller.loadInitial(null);
      expect(repo.tagRequests, [
        ['e3', 'e2'],
      ]);
      expect(_tagsOf(controller), {
        'e3': ['art', 'work'],
        'e2': <String>[],
      });

      await controller.loadMore();
      expect(repo.tagRequests.length, 2);
      expect(repo.tagRequests.last, ['e1']);
      expect(_tagsOf(controller)['e1'], ['travel']);

      await controller.refresh();
      expect(repo.tagRequests.length, 3);
      expect(repo.tagRequests.last.toSet(), {'e3', 'e2', 'e1'});
      expect(_tagsOf(controller), {
        'e3': ['art', 'work'],
        'e2': <String>[],
        'e1': ['travel'],
      });
    },
  );

  test(
    'R4: repo without tag capability still paginates with empty tags',
    () async {
      final repo = FakeEntryRepo(entries: _entries);
      final controller = TimelineController(repo: repo, pageSize: 2);
      addTearDown(controller.dispose);

      await controller.loadInitial(null);
      await controller.loadMore();

      expect(controller.reachedEnd, isTrue);
      final tags = _tagsOf(controller);
      expect(tags.keys.toSet(), {'e3', 'e2', 'e1'});
      expect(tags.values.every((value) => value.isEmpty), isTrue);
    },
  );
}
