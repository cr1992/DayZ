// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

class TimelineDemo extends StatefulWidget {
  const TimelineDemo({super.key});

  @override
  State<TimelineDemo> createState() => _TimelineDemoState();
}

class _TimelineDemoState extends State<TimelineDemo> {
  late TimelineController _controller;
  bool _showEmpty = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    unawaited(_controller.loadInitial(_demoJournalId));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DayzSpacing.s4,
                DayzSpacing.s4,
                DayzSpacing.s4,
                DayzSpacing.s2,
              ),
              child: Wrap(
                spacing: DayzSpacing.s2,
                runSpacing: DayzSpacing.s2,
                children: [
                  ChoiceChip(
                    label: Text(l10n.timeline),
                    selected: !_showEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        _switchMode(showEmpty: false);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.timelineEmptyTitle),
                    selected: _showEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        _switchMode(showEmpty: true);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: TimelinePage(controller: _controller)),
          ],
        ),
      ),
    );
  }

  TimelineController _createController() {
    return TimelineController(
      repo: _TimelineDemoRepo(
        entries: _showEmpty ? const <Entry>[] : _demoEntries,
      ),
      pageSize: 2,
    );
  }

  void _switchMode({required bool showEmpty}) {
    if (_showEmpty == showEmpty) {
      return;
    }

    final previous = _controller;
    setState(() {
      _showEmpty = showEmpty;
      _controller = _createController();
    });
    previous.dispose();
    unawaited(_controller.loadInitial(_demoJournalId));
  }
}

class _TimelineDemoRepo
    implements
        EntryRepo,
        TimelineJournalScopedRepository,
        TimelineMonthMetadataRepository {
  _TimelineDemoRepo({List<Entry> entries = const <Entry>[]})
    : _entries = _sortEntries(entries);

  final List<Entry> _entries;

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
    return _filterByJournal(journalId)
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

const String _demoJournalId = 'timeline-demo';

final List<Entry> _demoEntries = <Entry>[
  _demoEntry(
    id: 'timeline-demo-june-22',
    entryDtUtc: DateTime.utc(2026, 6, 22, 10),
    localYear: 2026,
    localMonth: 6,
    localDay: 22,
    contentPlain: '六月二十二日\n沿着海边走了很久。',
  ),
  _demoEntry(
    id: 'timeline-demo-june-18',
    entryDtUtc: DateTime.utc(2026, 6, 18, 10),
    localYear: 2026,
    localMonth: 6,
    localDay: 18,
    contentPlain: '六月十八日\n云层压得很低。',
  ),
  _demoEntry(
    id: 'timeline-demo-may-12',
    entryDtUtc: DateTime.utc(2026, 5, 12, 10),
    localYear: 2026,
    localMonth: 5,
    localDay: 12,
    contentPlain: '五月十二日\n把旧照片整理了一遍。',
  ),
  _demoEntry(
    id: 'timeline-demo-april-24',
    entryDtUtc: DateTime.utc(2026, 4, 24, 10),
    localYear: 2026,
    localMonth: 4,
    localDay: 24,
    contentPlain: '四月二十四日\n下午写完了那封信。',
  ),
];

Entry _demoEntry({
  required String id,
  required DateTime entryDtUtc,
  required int localYear,
  required int localMonth,
  required int localDay,
  required String contentPlain,
}) {
  final utc = entryDtUtc.toUtc();
  return Entry(
    id: id,
    journalId: _demoJournalId,
    contentJson: '{"insert":"$contentPlain"}',
    contentPlain: contentPlain,
    entryDtUtc: utc,
    entryTz: 'Etc/UTC',
    localYear: localYear,
    localMonth: localMonth,
    localDay: localDay,
    lat: null,
    lng: null,
    placeName: null,
    weatherCode: null,
    weatherTemp: null,
    isFavorite: false,
    createdAt: utc,
    updatedAt: utc,
    deletedAt: null,
    syncStatus: 0,
    serverRev: null,
  );
}
