// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';

import '../database.dart';
import '../ids.dart';
import '../time_zone_triple.dart';

class EntryTimelineCursor {
  final DateTime entryDtUtc;
  final String id;

  const EntryTimelineCursor({required this.entryDtUtc, required this.id});
}

class EntryTimelinePage {
  final List<Entry> items;
  final EntryTimelineCursor? nextCursor;

  const EntryTimelinePage({required this.items, required this.nextCursor});
}

class EntryRepo {
  final AppDatabase _db;

  EntryRepo(this._db);

  Future<EntryTimelinePage> timeline({
    EntryTimelineCursor? cursor,
    int limit = 30,
  }) async {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }

    final query = _db.select(_db.entries)
      ..where((table) {
        final cursorPredicate = cursor == null
            ? const Variable(true)
            : table.entryDtUtc.isSmallerThanValue(cursor.entryDtUtc.toUtc()) |
                  (table.entryDtUtc.equals(cursor.entryDtUtc.toUtc()) &
                      table.id.isSmallerThanValue(cursor.id));
        return table.deletedAt.isNull() & cursorPredicate;
      })
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.entryDtUtc, mode: OrderingMode.desc),
        (table) => OrderingTerm(expression: table.id, mode: OrderingMode.desc),
      ])
      ..limit(limit + 1);

    final rows = await query.get();
    final items = rows.length > limit ? rows.take(limit).toList() : rows;
    final nextCursor = rows.length > limit
        ? EntryTimelineCursor(
            entryDtUtc: items.last.entryDtUtc.toUtc(),
            id: items.last.id,
          )
        : null;

    return EntryTimelinePage(items: items, nextCursor: nextCursor);
  }

  Future<List<Entry>> onThisDay(int month, int day) {
    final query = _db.select(_db.entries)
      ..where(
        (table) =>
            table.deletedAt.isNull() &
            table.localMonth.equals(month) &
            table.localDay.equals(day),
      )
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.localYear, mode: OrderingMode.desc),
        (table) =>
            OrderingTerm(expression: table.entryDtUtc, mode: OrderingMode.desc),
        (table) => OrderingTerm(expression: table.id, mode: OrderingMode.desc),
      ]);

    return query.get();
  }

  Future<Entry?> byId(String id) async {
    final entry = await _db.entriesDao.byId(id);
    if (entry == null || entry.deletedAt != null) {
      return null;
    }
    return entry;
  }

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
  }) async {
    final now = DateTime.now().toUtc();
    final id = Ids.next();
    final utcDt = entryDtUtc.toUtc();
    final triple = TimeZoneTriple.compute(utcDt, entryTz);

    await _db.entriesDao.insertEntry(
      EntriesCompanion.insert(
        id: id,
        journalId: Value(journalId),
        contentJson: Value(contentJson),
        contentPlain: Value(contentPlain),
        entryDtUtc: utcDt,
        entryTz: entryTz,
        localYear: triple.year,
        localMonth: triple.month,
        localDay: triple.day,
        lat: _optional(lat),
        lng: _optional(lng),
        placeName: _optional(placeName),
        weatherCode: _optional(weatherCode),
        weatherTemp: _optional(weatherTemp),
        isFavorite: Value(isFavorite),
        createdAt: now,
        updatedAt: now,
        syncStatus: Value(syncStatus),
        serverRev: _optional(serverRev),
      ),
    );

    return _requireActiveEntry(id);
  }

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
  }) async {
    final entry = await _requireActiveEntry(id);
    final utcDt = (entryDtUtc ?? entry.entryDtUtc).toUtc();
    final timeZone = entryTz ?? entry.entryTz;
    final triple = entryDtUtc != null || entryTz != null
        ? TimeZoneTriple.compute(utcDt, timeZone)
        : (year: entry.localYear, month: entry.localMonth, day: entry.localDay);

    final updated = entry.copyWith(
      journalId: journalId == null ? const Value.absent() : Value(journalId),
      contentJson: contentJson,
      contentPlain: contentPlain,
      entryDtUtc: utcDt,
      entryTz: timeZone,
      localYear: triple.year,
      localMonth: triple.month,
      localDay: triple.day,
      lat: lat == null ? const Value.absent() : Value(lat),
      lng: lng == null ? const Value.absent() : Value(lng),
      placeName: placeName == null ? const Value.absent() : Value(placeName),
      weatherCode: weatherCode == null
          ? const Value.absent()
          : Value(weatherCode),
      weatherTemp: weatherTemp == null
          ? const Value.absent()
          : Value(weatherTemp),
      isFavorite: isFavorite,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: syncStatus,
      serverRev: serverRev == null ? const Value.absent() : Value(serverRev),
    );

    await _db.entriesDao.updateEntry(updated.toCompanion(false));
    return _requireActiveEntry(id);
  }

  Future<void> softDelete(String id) async {
    await _requireActiveEntry(id);
    await _db.entriesDao.softDelete(id);
  }

  Future<void> hardDelete(String id) async {
    await _db.entriesDao.hardDelete(id);
  }

  Future<Entry> _requireActiveEntry(String id) async {
    final entry = await byId(id);
    if (entry == null) {
      throw StateError('Entry not found: $id');
    }
    return entry;
  }

  Value<T> _optional<T>(T? value) {
    return value == null ? const Value.absent() : Value(value);
  }
}
