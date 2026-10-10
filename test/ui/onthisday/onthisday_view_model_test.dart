// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/onthisday/onthisday_view_model.dart';

void main() {
  group('OnThisDayData', () {
    test('flattens year groups in descending year order', () {
      final data = OnThisDayData(
        date: DateTime(2026, 5, 29),
        totalCount: 4,
        groups: [
          YearGroup(
            year: 2024,
            yearsAgo: 2,
            entries: [_entry('2024-a'), _entry('2024-b')],
          ),
          YearGroup(year: 2026, yearsAgo: 0, entries: [_entry('2026-a')]),
          YearGroup(year: 2025, yearsAgo: 1, entries: [_entry('2025-a')]),
        ],
      );

      final rows = flatten(data);

      expect(rows, hasLength(7));
      expect(rows[0], isA<YearSeparatorRow>());
      expect((rows[0] as YearSeparatorRow).year, 2026);
      expect((rows[0] as YearSeparatorRow).yearsAgo, 0);
      expect((rows[1] as EntryCardRow).entry.entryId, '2026-a');
      expect((rows[2] as YearSeparatorRow).year, 2025);
      expect((rows[3] as EntryCardRow).entry.entryId, '2025-a');
      expect((rows[4] as YearSeparatorRow).year, 2024);
      expect((rows[5] as EntryCardRow).entry.entryId, '2024-a');
      expect((rows[6] as EntryCardRow).entry.entryId, '2024-b');
    });

    test('returns an empty row list when groups are empty', () {
      final data = OnThisDayData(
        date: DateTime(2026, 5, 29),
        totalCount: 0,
        groups: const [],
      );

      expect(flatten(data), isEmpty);
      expect(data.isEmpty, isTrue);
    });

    test('exposes immutable entry card data without repo dependencies', () {
      final image = MemoryImage(Uint8List.fromList(<int>[0, 1, 2, 3]));
      final entry = EntryCardVM(
        entryId: 'entry-1',
        title: 'A clear morning',
        excerpt: 'Coffee on the balcony.',
        date: DateTime(2021, 5, 29),
        tags: const ['home'],
        place: 'Shanghai',
        favorite: true,
        coverImage: image,
      );

      expect(entry.entryId, 'entry-1');
      expect(entry.favorite, isTrue);
      expect(entry.coverImage, same(image));
      expect(entry.tags, ['home']);
      expect(entry.place, 'Shanghai');
      expect(entry.date, DateTime(2021, 5, 29));
    });
  });
}

EntryCardVM _entry(String id) {
  return EntryCardVM(
    entryId: id,
    title: 'Title $id',
    excerpt: 'Excerpt $id',
    date: DateTime(2024, 5, 29),
  );
}
