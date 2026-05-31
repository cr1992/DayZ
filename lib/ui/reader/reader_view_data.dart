// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ignore_for_file: prefer_initializing_formals

import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/journal_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';

/// Read-only data port used by the reader screen.
///
/// Author: @Ray
abstract interface class ReaderRepository {
  Future<ReaderEntryRecord?> byId(String id);

  Future<List<ReaderMediaRecord>> listMedia(String entryId);

  Future<List<ReaderTagRecord>> listTags(String entryId);

  Future<void> updateFavorite(String id, bool isFavorite);

  Future<void> updateJournal(String id, String? journalId);

  Future<void> softDelete(String id);

  Future<void> restore(String id);

  Future<List<ReaderJournalRecord>> listJournals();
}

/// Adapter from the current data-layer repositories to the reader port.
///
/// Author: @Ray
class DataLayerReaderRepository implements ReaderRepository {
  DataLayerReaderRepository({
    required EntryRepo entryRepo,
    required MediaRepo mediaRepo,
    required TagRepo tagRepo,
    required JournalRepo journalRepo,
    Future<void> Function(String id)? restoreEntry,
    int Function(String journalId)? journalEntryCount,
  }) : _entryRepo = entryRepo,
       _mediaRepo = mediaRepo,
       _tagRepo = tagRepo,
       _journalRepo = journalRepo,
       _restoreEntry = restoreEntry,
       _journalEntryCount = journalEntryCount;

  final EntryRepo _entryRepo;
  final MediaRepo _mediaRepo;
  final TagRepo _tagRepo;
  final JournalRepo _journalRepo;
  final Future<void> Function(String id)? _restoreEntry;
  final int Function(String journalId)? _journalEntryCount;

  @override
  Future<ReaderEntryRecord?> byId(String id) async {
    final entry = await _entryRepo.byId(id);
    if (entry == null) {
      return null;
    }
    return ReaderEntryRecord(
      id: entry.id,
      journalId: entry.journalId,
      contentPlain: entry.contentPlain,
      contentJson: entry.contentJson,
      entryDtUtc: entry.entryDtUtc,
      entryTz: entry.entryTz,
      placeName: entry.placeName,
      weatherCode: entry.weatherCode,
      weatherTemp: entry.weatherTemp,
      isFavorite: entry.isFavorite,
    );
  }

  @override
  Future<List<ReaderJournalRecord>> listJournals() async {
    final journals = await _journalRepo.list();
    return [
      for (final journal in journals)
        ReaderJournalRecord(
          id: journal.id,
          name: journal.name,
          color: journal.color,
          entryCount: _journalEntryCount?.call(journal.id) ?? 0,
        ),
    ];
  }

  @override
  Future<List<ReaderMediaRecord>> listMedia(String entryId) async {
    final media = await _mediaRepo.listByEntry(entryId);
    return [
      for (final item in media)
        ReaderMediaRecord(
          id: item.id,
          entryId: item.entryId,
          kind: item.kind,
          relPath: item.relPath,
          width: item.width,
          height: item.height,
        ),
    ];
  }

  @override
  Future<List<ReaderTagRecord>> listTags(String entryId) async {
    final tags = await _tagRepo.listForEntry(entryId);
    return [
      for (final tag in tags) ReaderTagRecord(id: tag.id, name: tag.name),
    ];
  }

  @override
  Future<void> restore(String id) {
    final restoreEntry = _restoreEntry;
    if (restoreEntry == null) {
      throw UnsupportedError('Entry restore is not available yet.');
    }
    return restoreEntry(id);
  }

  @override
  Future<void> softDelete(String id) {
    return _entryRepo.softDelete(id);
  }

  @override
  Future<void> updateFavorite(String id, bool isFavorite) async {
    await _entryRepo.update(id, isFavorite: isFavorite);
  }

  @override
  Future<void> updateJournal(String id, String? journalId) async {
    await _entryRepo.update(id, journalId: journalId);
  }
}

class ReaderEntryRecord {
  const ReaderEntryRecord({
    required this.id,
    required this.journalId,
    required this.contentPlain,
    required this.contentJson,
    required this.entryDtUtc,
    required this.entryTz,
    required this.isFavorite,
    this.placeName,
    this.weatherCode,
    this.weatherTemp,
  });

  final String id;
  final String? journalId;
  final String contentPlain;
  final String contentJson;
  final DateTime entryDtUtc;
  final String entryTz;
  final String? placeName;
  final String? weatherCode;
  final double? weatherTemp;
  final bool isFavorite;
}

class ReaderMediaRecord {
  const ReaderMediaRecord({
    required this.id,
    required this.entryId,
    required this.kind,
    required this.relPath,
    this.width,
    this.height,
  });

  final String id;
  final String entryId;
  final String kind;
  final String relPath;
  final int? width;
  final int? height;
}

class ReaderTagRecord {
  const ReaderTagRecord({required this.id, required this.name});

  final String id;
  final String name;
}

class ReaderJournalRecord {
  const ReaderJournalRecord({
    required this.id,
    required this.name,
    required this.entryCount,
    this.color,
  });

  final String id;
  final String name;
  final String? color;
  final int entryCount;
}

class ReaderMediaViewData {
  const ReaderMediaViewData({
    required this.id,
    required this.relPath,
    this.width,
    this.height,
  });

  final String id;
  final String relPath;
  final int? width;
  final int? height;
}

class ReaderTagViewData {
  const ReaderTagViewData({required this.id, required this.name});

  final String id;
  final String name;
}

class ReaderWeatherViewData {
  const ReaderWeatherViewData({
    required this.code,
    required this.temperatureCelsius,
    this.label,
  });

  final String code;
  final double? temperatureCelsius;
  final String? label;

  String get displayLabel {
    final explicitLabel = label;
    if (explicitLabel != null && explicitLabel.trim().isNotEmpty) {
      return explicitLabel.trim();
    }
    final temperature = temperatureCelsius;
    if (temperature == null) {
      return code;
    }
    return '$code ${temperature.round()}°C';
  }
}

class ReaderViewData {
  const ReaderViewData({
    required this.id,
    required this.dateTimeLocal,
    required this.title,
    required this.bodyParagraphs,
    required this.favorite,
    this.cover,
    this.weather,
    this.place,
    this.mood,
    this.tags = const <ReaderTagViewData>[],
    this.galleryImages = const <ReaderMediaViewData>[],
    this.journalId,
  });

  final String id;
  final ReaderMediaViewData? cover;
  final ReaderWeatherViewData? weather;
  final String? place;
  final String? mood;
  final List<ReaderTagViewData> tags;
  final List<ReaderMediaViewData> galleryImages;
  final String title;
  final List<String> bodyParagraphs;
  final DateTime dateTimeLocal;
  final String? journalId;
  final bool favorite;
}

Future<ReaderViewData?> buildReaderViewData(
  String entryId,
  ReaderRepository repository,
) async {
  final entry = await repository.byId(entryId);
  if (entry == null) {
    return null;
  }

  final media = await repository.listMedia(entryId);
  final tags = await repository.listTags(entryId);
  final images = media
      .where((item) => item.kind == 'image')
      .map(
        (item) => ReaderMediaViewData(
          id: item.id,
          relPath: item.relPath,
          width: item.width,
          height: item.height,
        ),
      )
      .toList(growable: false);
  final paragraphs = _splitParagraphs(entry.contentPlain);

  return ReaderViewData(
    id: entry.id,
    dateTimeLocal: entry.entryDtUtc,
    title: paragraphs.isEmpty ? '' : paragraphs.first,
    bodyParagraphs: paragraphs,
    cover: images.isEmpty ? null : images.first,
    galleryImages: images.length <= 1
        ? const <ReaderMediaViewData>[]
        : images.skip(1).toList(growable: false),
    weather: entry.weatherCode == null
        ? null
        : ReaderWeatherViewData(
            code: entry.weatherCode!,
            temperatureCelsius: entry.weatherTemp,
          ),
    place: _blankToNull(entry.placeName),
    tags: _sortedTags(tags),
    journalId: entry.journalId,
    favorite: entry.isFavorite,
  );
}

List<String> _splitParagraphs(String contentPlain) {
  return contentPlain
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

List<ReaderTagViewData> _sortedTags(List<ReaderTagRecord> tags) {
  final sorted = List<ReaderTagRecord>.from(tags)
    ..sort((a, b) => a.name.compareTo(b.name));
  return [
    for (final tag in sorted) ReaderTagViewData(id: tag.id, name: tag.name),
  ];
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value;
}
