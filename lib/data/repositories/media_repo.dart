// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart' show Value;

import '../database.dart';

class MediaRepo {
  final AppDatabase _db;

  MediaRepo(this._db);

  Future<MediaData> addMeta(
    String id,
    String entryId,
    String kind,
    String relPath, {
    String? mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    final now = DateTime.now().toUtc();

    await _db.mediaDao.insertMedia(
      MediaCompanion.insert(
        id: id,
        entryId: entryId,
        kind: kind,
        relPath: relPath,
        mime: _optional(mime),
        width: _optional(width),
        height: _optional(height),
        durationMs: _optional(durationMs),
        fileSize: _optional(fileSize),
        updatedAt: now,
        createdAt: now,
      ),
    );

    return _requireActiveMedia(id);
  }

  Future<List<MediaData>> listByEntry(String entryId) {
    return _db.mediaDao.listByEntry(entryId).get();
  }

  Future<MediaData> updateThumb(
    String id, {
    String? thumbPath,
    int? w,
    int? h,
    DateTime? srcUpdatedAt,
  }) async {
    final media = await _requireActiveMedia(id);
    final updated = media.copyWith(
      thumbPath: Value(thumbPath),
      thumbW: Value(w),
      thumbH: Value(h),
      thumbSrcUpdatedAt: Value(srcUpdatedAt?.toUtc()),
      updatedAt: DateTime.now().toUtc(),
    );

    await _db.mediaDao.updateMedia(updated.toCompanion(false));
    return _requireActiveMedia(id);
  }

  Future<void> softDelete(String id) async {
    await _requireActiveMedia(id);
    await _db.mediaDao.softDelete(id);
  }

  Future<void> hardDelete(String id) async {
    await _db.mediaDao.hardDelete(id);
  }

  Future<MediaData> _requireActiveMedia(String id) async {
    final media = await _db.mediaDao.byId(id);
    if (media == null || media.deletedAt != null) {
      throw StateError('Media not found: $id');
    }
    return media;
  }

  Value<T> _optional<T>(T? value) {
    return value == null ? const Value.absent() : Value(value);
  }
}
