// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/timeline/timeline_controller.dart';

import 'fake_entry_repo.dart';

void main() {
  group('TimelineController', () {
    test('paginates without duplicates and groups by local month', () async {
      final repo = FakeEntryRepo(
        entries: [
          fakeEntry(
            id: 'e6',
            journalId: 'journal-a',
            entryDtUtc: DateTime.utc(2026, 5, 31, 16),
            localYear: 2026,
            localMonth: 6,
            localDay: 1,
            contentPlain: 'June entry\nLate night',
          ),
          fakeEntry(
            id: 'e5',
            journalId: 'journal-a',
            entryDtUtc: DateTime.utc(2026, 5, 31, 10),
            localYear: 2026,
            localMonth: 5,
            localDay: 31,
            contentPlain: 'May entry\nOne',
          ),
          fakeEntry(
            id: 'e4',
            journalId: 'journal-a',
            entryDtUtc: DateTime.utc(2026, 5, 30, 10),
            localYear: 2026,
            localMonth: 5,
            localDay: 30,
            contentPlain: 'May entry\nTwo',
          ),
          fakeEntry(
            id: 'e3',
            journalId: 'journal-a',
            entryDtUtc: DateTime.utc(2026, 4, 30, 10),
            localYear: 2026,
            localMonth: 4,
            localDay: 30,
            contentPlain: 'April entry\nThree',
          ),
          fakeEntry(
            id: 'e2',
            journalId: 'journal-a',
            entryDtUtc: DateTime.utc(2025, 12, 31, 10),
            localYear: 2025,
            localMonth: 12,
            localDay: 31,
            contentPlain: 'December entry\nFour',
          ),
        ],
      );
      final controller = TimelineController(repo: repo, pageSize: 2);

      await controller.loadInitial('journal-a');
      await controller.loadMore();
      await controller.loadMore();

      expect(
        controller.sections.map((section) => (section.year, section.month)),
        [(2026, 6), (2026, 5), (2026, 4), (2025, 12)],
      );
      expect(
        controller.sections
            .expand((section) => section.entries)
            .map((entry) => entry.id),
        ['e6', 'e5', 'e4', 'e3', 'e2'],
      );
      expect(controller.sections[1].count, 2);
      expect(controller.sections[0].entries.single.localDate.month, 6);
    });

    test('does not start a concurrent page load while loading', () async {
      final barrier = Completer<void>();
      final repo = FakeEntryRepo(
        entries: [
          fakeEntry(
            id: 'e1',
            journalId: 'journal-a',
            entryDtUtc: DateTime.utc(2026, 5, 31, 10),
          ),
        ],
      )..beforeTimelineResponse = () => barrier.future;
      final controller = TimelineController(repo: repo, pageSize: 1);

      final initialLoad = controller.loadInitial('journal-a');
      await Future<void>.delayed(Duration.zero);

      expect(controller.isLoading, isTrue);
      expect(repo.timelineCallCount, 1);

      await controller.loadMore();

      expect(repo.timelineCallCount, 1);

      barrier.complete();
      await initialLoad;
    });

    test('stops requesting pages after reaching the end', () async {
      final repo = FakeEntryRepo(
        entries: [
          fakeEntry(
            id: 'e1',
            journalId: 'journal-a',
            entryDtUtc: DateTime.utc(2026, 5, 31, 10),
          ),
        ],
      );
      final controller = TimelineController(repo: repo, pageSize: 5);

      await controller.loadInitial('journal-a');
      final callCount = repo.timelineCallCount;

      expect(controller.reachedEnd, isTrue);

      await controller.loadMore();

      expect(repo.timelineCallCount, callCount);
    });

    test(
      'jumpToMonth keeps loading until the target month is available',
      () async {
        final repo = FakeEntryRepo(
          entries: [
            fakeEntry(
              id: 'e4',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 5, 31, 10),
              localYear: 2026,
              localMonth: 5,
              localDay: 31,
            ),
            fakeEntry(
              id: 'e3',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 4, 30, 10),
              localYear: 2026,
              localMonth: 4,
              localDay: 30,
            ),
            fakeEntry(
              id: 'e2',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 3, 31, 10),
              localYear: 2026,
              localMonth: 3,
              localDay: 31,
            ),
          ],
        );
        final controller = TimelineController(repo: repo, pageSize: 1);

        await controller.loadInitial('journal-a');
        await controller.jumpToMonth(2026, 3);

        expect(
          controller.sections.any(
            (section) => section.year == 2026 && section.month == 3,
          ),
          isTrue,
        );
      },
    );

    test(
      'switchJournal resets state and re-queries with the new journal id',
      () async {
        final repo = FakeEntryRepo(
          entries: [
            fakeEntry(
              id: 'a2',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 5, 31, 10),
            ),
            fakeEntry(
              id: 'a1',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 5, 30, 10),
            ),
            fakeEntry(
              id: 'b2',
              journalId: 'journal-b',
              entryDtUtc: DateTime.utc(2026, 5, 29, 10),
            ),
            fakeEntry(
              id: 'b1',
              journalId: 'journal-b',
              entryDtUtc: DateTime.utc(2026, 5, 28, 10),
            ),
          ],
        );
        final controller = TimelineController(repo: repo, pageSize: 4);

        await controller.loadInitial('journal-a');
        await controller.switchJournal('journal-b');

        expect(controller.journalId, 'journal-b');
        expect(
          controller.sections
              .expand((section) => section.entries)
              .map((entry) => entry.id),
          ['b2', 'b1'],
        );
        expect(repo.timelineJournalIds, ['journal-a', 'journal-b']);
        expect(controller.contentEpoch, 1);
      },
    );
  });
}
