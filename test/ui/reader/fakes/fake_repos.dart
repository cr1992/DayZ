// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/reader/reader_view_data.dart';

/// In-memory reader repository fake shared by reader-screen tests.
///
/// Author: @Ray
class FakeReaderRepository implements ReaderRepository {
  FakeReaderRepository({
    Map<String, ReaderEntryRecord> entries =
        const <String, ReaderEntryRecord>{},
    Map<String, List<ReaderMediaRecord>> media =
        const <String, List<ReaderMediaRecord>>{},
    Map<String, List<ReaderTagRecord>> tags =
        const <String, List<ReaderTagRecord>>{},
    List<ReaderJournalRecord> journals = const <ReaderJournalRecord>[],
  }) : _entries = Map<String, ReaderEntryRecord>.from(entries),
       _media = _copyLists(media),
       _tags = _copyLists(tags),
       _journals = List<ReaderJournalRecord>.from(journals);

  final Map<String, ReaderEntryRecord> _entries;
  final Map<String, List<ReaderMediaRecord>> _media;
  final Map<String, List<ReaderTagRecord>> _tags;
  final List<ReaderJournalRecord> _journals;

  final List<String> byIdCalls = <String>[];
  final List<String> listMediaCalls = <String>[];
  final List<String> listTagsCalls = <String>[];
  final List<({String id, bool isFavorite})> favoriteUpdates =
      <({String id, bool isFavorite})>[];
  final List<({String id, String? journalId})> journalUpdates =
      <({String id, String? journalId})>[];
  final List<String> softDeleteCalls = <String>[];
  final List<String> restoreCalls = <String>[];

  Object? favoriteFailure;
  Object? journalFailure;
  Object? deleteFailure;
  Object? restoreFailure;

  @override
  Future<ReaderEntryRecord?> byId(String id) async {
    byIdCalls.add(id);
    return _entries[id];
  }

  @override
  Future<List<ReaderJournalRecord>> listJournals() async {
    return List<ReaderJournalRecord>.unmodifiable(_journals);
  }

  @override
  Future<List<ReaderMediaRecord>> listMedia(String entryId) async {
    listMediaCalls.add(entryId);
    return List<ReaderMediaRecord>.unmodifiable(
      _media[entryId] ?? const <ReaderMediaRecord>[],
    );
  }

  @override
  Future<List<ReaderTagRecord>> listTags(String entryId) async {
    listTagsCalls.add(entryId);
    return List<ReaderTagRecord>.unmodifiable(
      _tags[entryId] ?? const <ReaderTagRecord>[],
    );
  }

  @override
  Future<void> restore(String id) async {
    restoreCalls.add(id);
    final failure = restoreFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> softDelete(String id) async {
    softDeleteCalls.add(id);
    final failure = deleteFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> updateFavorite(String id, bool isFavorite) async {
    favoriteUpdates.add((id: id, isFavorite: isFavorite));
    final failure = favoriteFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> updateJournal(String id, String? journalId) async {
    journalUpdates.add((id: id, journalId: journalId));
    final failure = journalFailure;
    if (failure != null) {
      throw failure;
    }
  }

  static Map<String, List<T>> _copyLists<T>(Map<String, List<T>> source) {
    return source.map(
      (key, value) => MapEntry<String, List<T>>(key, List<T>.from(value)),
    );
  }
}

ReaderEntryRecord fakeReaderEntryRecord({
  String id = 'entry-1',
  String? journalId = 'journal-1',
  String contentPlain = '清晨\n院子里有桂花香。',
  String contentJson = '{"insert":"清晨"}',
  DateTime? entryDtUtc,
  String entryTz = 'Etc/UTC',
  String? placeName = '杭州',
  String? weatherCode = 'sunny',
  double? weatherTemp = 23.5,
  bool isFavorite = true,
}) {
  return ReaderEntryRecord(
    id: id,
    journalId: journalId,
    contentPlain: contentPlain,
    contentJson: contentJson,
    entryDtUtc: entryDtUtc ?? DateTime.utc(2026, 5, 27, 8, 30),
    entryTz: entryTz,
    placeName: placeName,
    weatherCode: weatherCode,
    weatherTemp: weatherTemp,
    isFavorite: isFavorite,
  );
}

ReaderMediaRecord fakeReaderMediaRecord({
  String id = 'media-1',
  String entryId = 'entry-1',
  String kind = 'image',
  String relPath = 'media/media-1.bin',
  int? width = 1200,
  int? height = 900,
}) {
  return ReaderMediaRecord(
    id: id,
    entryId: entryId,
    kind: kind,
    relPath: relPath,
    width: width,
    height: height,
  );
}

ReaderTagRecord fakeReaderTagRecord({String id = 'tag-1', String name = '生活'}) {
  return ReaderTagRecord(id: id, name: name);
}

ReaderJournalRecord fakeReaderJournalRecord({
  String id = 'journal-1',
  String name = '日常',
  String? color = '#786CAD',
  int entryCount = 7,
}) {
  return ReaderJournalRecord(
    id: id,
    name: name,
    color: color,
    entryCount: entryCount,
  );
}
