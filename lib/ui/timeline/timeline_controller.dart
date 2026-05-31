// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:dayz/data/repositories/entry_repo.dart';

import 'timeline_month_section.dart';

abstract interface class TimelineJournalScopedRepository {
  Future<EntryTimelinePage> timeline({
    String? journalId,
    EntryTimelineCursor? cursor,
    int limit = TimelineController.defaultPageSize,
  });
}

abstract interface class TimelineMonthMetadataRepository {
  Future<Map<TimelineMonthKey, int>> monthCounts(String? journalId);

  Future<Set<int>> entryDaysInMonth(String? journalId, int year, int month);
}

class TimelineController extends ChangeNotifier {
  TimelineController({required this._repo, this.pageSize = defaultPageSize});

  static const int defaultPageSize = 30;

  final EntryRepo _repo;
  final int pageSize;

  List<MonthSection> _sections = const <MonthSection>[];
  EntryTimelineCursor? _cursor;
  bool _isLoading = false;
  bool _reachedEnd = false;
  String? _journalId;
  int _contentEpoch = 0;
  Map<TimelineMonthKey, int>? _monthCounts;
  final Map<TimelineMonthKey, Set<int>> _loadedEntryDays =
      <TimelineMonthKey, Set<int>>{};
  final Map<TimelineMonthKey, Set<int>> _resolvedEntryDays =
      <TimelineMonthKey, Set<int>>{};

  List<MonthSection> get sections => UnmodifiableListView(_sections);
  EntryTimelineCursor? get cursor => _cursor;
  bool get isLoading => _isLoading;
  bool get reachedEnd => _reachedEnd;
  String? get journalId => _journalId;
  int get contentEpoch => _contentEpoch;
  List<TimelineMonthKey> get availableMonths {
    final keys = (_monthCounts?.keys ?? _sections.map((section) => section.key))
        .toSet()
        .toList(growable: false);
    keys.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) {
        return yearCompare;
      }
      return b.month.compareTo(a.month);
    });
    return List<TimelineMonthKey>.unmodifiable(keys);
  }

  Future<void> loadInitial(String? journalId) async {
    _journalId = journalId;
    _cursor = null;
    _reachedEnd = false;
    _sections = const <MonthSection>[];
    _monthCounts = null;
    _loadedEntryDays.clear();
    _resolvedEntryDays.clear();
    notifyListeners();

    await loadMore();
  }

  Future<void> loadMore() async {
    if (_isLoading || _reachedEnd) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _monthCounts ??= await _loadMonthCounts();

      final page = await _loadTimelinePage(cursor: _cursor, limit: pageSize);
      final entries = _mapPageEntries(page.items);
      _cursor = page.nextCursor;
      _reachedEnd = page.nextCursor == null;
      _sections = mergeMonthSections(
        current: _sections,
        incomingEntries: entries,
        monthCounts: _monthCounts,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> jumpToMonth(int year, int month) async {
    while (!_containsMonth(year, month) && !_reachedEnd) {
      await loadMore();
    }
  }

  Future<void> switchJournal(String? journalId) async {
    if (_journalId == journalId && (_sections.isNotEmpty || _reachedEnd)) {
      return;
    }

    _contentEpoch += 1;
    await loadInitial(journalId);
  }

  int? monthCountFor(int year, int month) {
    final key = TimelineMonthKey(year, month);
    final section = _sections.cast<MonthSection?>().firstWhere(
      (candidate) => candidate?.year == year && candidate?.month == month,
      orElse: () => null,
    );
    return _monthCounts?[key] ?? section?.count;
  }

  Future<Set<int>> entryDaysInMonth(int year, int month) async {
    final key = TimelineMonthKey(year, month);
    final cached = _resolvedEntryDays[key];
    if (cached != null) {
      return Set<int>.unmodifiable(cached);
    }

    final metadataRepo = _repo is TimelineMonthMetadataRepository
        ? _repo as TimelineMonthMetadataRepository
        : null;
    if (metadataRepo != null) {
      final days = await metadataRepo.entryDaysInMonth(_journalId, year, month);
      _resolvedEntryDays[key] = Set<int>.from(days);
      return Set<int>.unmodifiable(days);
    }

    final loaded = _loadedEntryDays[key] ?? const <int>{};
    return Set<int>.unmodifiable(loaded);
  }

  bool _containsMonth(int year, int month) {
    return _sections.any(
      (section) => section.year == year && section.month == month,
    );
  }

  Future<Map<TimelineMonthKey, int>?> _loadMonthCounts() async {
    final metadataRepo = _repo is TimelineMonthMetadataRepository
        ? _repo as TimelineMonthMetadataRepository
        : null;
    if (metadataRepo == null) {
      return null;
    }

    return metadataRepo.monthCounts(_journalId);
  }

  Future<EntryTimelinePage> _loadTimelinePage({
    EntryTimelineCursor? cursor,
    required int limit,
  }) async {
    final scopedRepo = _repo is TimelineJournalScopedRepository
        ? _repo as TimelineJournalScopedRepository
        : null;
    if (scopedRepo != null) {
      return scopedRepo.timeline(
        journalId: _journalId,
        cursor: cursor,
        limit: limit,
      );
    }

    if (_journalId == null) {
      return _repo.timeline(cursor: cursor, limit: limit);
    }

    final matchedEntries = <Object>[];
    EntryTimelineCursor? nextCursor = cursor;

    while (matchedEntries.length < limit) {
      final page = await _repo.timeline(cursor: nextCursor, limit: limit);
      matchedEntries.addAll(
        page.items.where((entry) => entry.journalId == _journalId),
      );
      nextCursor = page.nextCursor;

      if (page.nextCursor == null || matchedEntries.length >= limit) {
        break;
      }
    }

    final items = matchedEntries
        .take(limit)
        .cast<dynamic>()
        .toList(growable: false);
    return EntryTimelinePage(items: items.cast(), nextCursor: nextCursor);
  }

  List<TimelineEntry> _mapPageEntries(Iterable<Object> pageItems) {
    return [for (final row in pageItems) _mapEntryRow(row)];
  }

  TimelineEntry _mapEntryRow(Object row) {
    final entry = row as dynamic;
    final plain = (entry.contentPlain as String?)?.trim() ?? '';
    final localDate = DateTime(
      entry.localYear as int,
      entry.localMonth as int,
      entry.localDay as int,
    );
    final monthKey = TimelineMonthKey(
      entry.localYear as int,
      entry.localMonth as int,
    );
    (_loadedEntryDays[monthKey] ??= <int>{}).add(entry.localDay as int);

    return TimelineEntry(
      id: entry.id as String,
      journalId: entry.journalId as String?,
      title: _extractTitle(plain),
      summary: _extractSummary(plain),
      localDate: localDate,
      sortDateUtc: (entry.entryDtUtc as DateTime).toUtc(),
      placeName: entry.placeName as String?,
      weatherCode: entry.weatherCode as String?,
      weatherTemp: entry.weatherTemp as double?,
      isFavorite: entry.isFavorite as bool? ?? false,
    );
  }

  String _extractTitle(String plain) {
    if (plain.isEmpty) {
      return '';
    }

    final firstLine = plain
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    return firstLine;
  }

  String _extractSummary(String plain) {
    if (plain.isEmpty) {
      return '';
    }

    final lines = plain
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.length <= 1) {
      return '';
    }

    return lines.skip(1).join(' ');
  }
}
