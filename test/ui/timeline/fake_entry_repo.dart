// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';

class FakeEntryRepo
    implements
        EntryRepo,
        TimelineJournalScopedRepository,
        TimelineMonthMetadataRepository {
  FakeEntryRepo({List<Entry> entries = const <Entry>[]})
    : _entries = _sortEntries(entries);

  final List<Entry> _entries;
  final List<String?> timelineJournalIds = <String?>[];
  int timelineCallCount = 0;
  Future<void> Function()? beforeTimelineResponse;

  @override
  Future<Entry?> byId(String id) async {
    try {
      return _entries.firstWhere(
        (entry) => entry.id == id && entry.deletedAt == null,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<Entry> create({
    String? journalId,
    required String contentJson,
    required String contentPlain,
    required DateTime entryDtUtc,
    required String entryTz,
    double? lat,
    double? lng,
    String? placeName,
    String? weatherCode,
    double? weatherTemp,
    bool isFavorite = false,
    int syncStatus = 0,
    String? serverRev,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Set<int>> entryDaysInMonth(
    String? journalId,
    int year,
    int month,
  ) async {
    final filtered = _filterByJournal(journalId);
    return filtered
        .where((entry) => entry.localYear == year && entry.localMonth == month)
        .map((entry) => entry.localDay)
        .toSet();
  }

  @override
  Future<void> hardDelete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Map<TimelineMonthKey, int>> monthCounts(String? journalId) async {
    final counts = <TimelineMonthKey, int>{};
    for (final entry in _filterByJournal(journalId)) {
      final key = TimelineMonthKey(entry.localYear, entry.localMonth);
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  @override
  Future<List<Entry>> onThisDay(int month, int day) async {
    return _entries
        .where(
          (entry) =>
              entry.deletedAt == null &&
              entry.localMonth == month &&
              entry.localDay == day,
        )
        .toList(growable: false);
  }

  @override
  Future<void> softDelete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<EntryTimelinePage> timeline({
    String? journalId,
    EntryTimelineCursor? cursor,
    int limit = TimelineController.defaultPageSize,
  }) async {
    timelineCallCount += 1;
    timelineJournalIds.add(journalId);
    if (beforeTimelineResponse != null) {
      await beforeTimelineResponse!.call();
    }

    final rows = _filterByJournal(journalId)
        .where((entry) => _isAfterCursor(entry, cursor))
        .take(limit + 1)
        .toList(growable: false);
    final items = rows.length > limit ? rows.take(limit).toList() : rows;
    final nextCursor = rows.length > limit
        ? EntryTimelineCursor(
            entryDtUtc: items.last.entryDtUtc.toUtc(),
            id: items.last.id,
          )
        : null;

    return EntryTimelinePage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<Entry> update(
    String id, {
    String? journalId,
    String? contentJson,
    String? contentPlain,
    DateTime? entryDtUtc,
    String? entryTz,
    double? lat,
    double? lng,
    String? placeName,
    String? weatherCode,
    double? weatherTemp,
    bool? isFavorite,
    int? syncStatus,
    String? serverRev,
  }) {
    throw UnimplementedError();
  }

  List<Entry> _filterByJournal(String? journalId) {
    return _entries
        .where(
          (entry) =>
              entry.deletedAt == null &&
              (journalId == null || entry.journalId == journalId),
        )
        .toList(growable: false);
  }

  bool _isAfterCursor(Entry entry, EntryTimelineCursor? cursor) {
    if (cursor == null) {
      return true;
    }

    final compareTime = entry.entryDtUtc.toUtc().compareTo(cursor.entryDtUtc);
    return compareTime < 0 ||
        (compareTime == 0 && entry.id.compareTo(cursor.id) < 0);
  }

  static List<Entry> _sortEntries(List<Entry> entries) {
    final sorted = List<Entry>.from(entries);
    sorted.sort((a, b) {
      final dateCompare = b.entryDtUtc.toUtc().compareTo(a.entryDtUtc.toUtc());
      if (dateCompare != 0) {
        return dateCompare;
      }
      return b.id.compareTo(a.id);
    });
    return List<Entry>.unmodifiable(sorted);
  }
}

Entry fakeEntry({
  required String id,
  required DateTime entryDtUtc,
  String? journalId,
  String contentPlain = 'Title\nSummary',
  String contentJson = '{"insert":"Title"}',
  String entryTz = 'Etc/UTC',
  int? localYear,
  int? localMonth,
  int? localDay,
  bool isFavorite = false,
  String? placeName,
  String? weatherCode,
  double? weatherTemp,
}) {
  final utc = entryDtUtc.toUtc();
  return Entry(
    id: id,
    journalId: journalId,
    contentJson: contentJson,
    contentPlain: contentPlain,
    entryDtUtc: utc,
    entryTz: entryTz,
    localYear: localYear ?? utc.year,
    localMonth: localMonth ?? utc.month,
    localDay: localDay ?? utc.day,
    lat: null,
    lng: null,
    placeName: placeName,
    weatherCode: weatherCode,
    weatherTemp: weatherTemp,
    isFavorite: isFavorite,
    createdAt: utc,
    updatedAt: utc,
    deletedAt: null,
    syncStatus: 0,
    serverRev: null,
  );
}
