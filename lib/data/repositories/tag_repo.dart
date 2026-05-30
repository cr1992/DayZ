// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart' show Value;

import '../database.dart';
import '../ids.dart';

class TagRepo {
  final AppDatabase _db;

  TagRepo(this._db);

  Future<Tag> create(String name) async {
    final existing = await _db.tagsDao.byName(name);
    if (existing != null) {
      if (existing.deletedAt != null) {
        await (_db.update(_db.tags)
              ..where((table) => table.id.equals(existing.id)))
            .write(const TagsCompanion(deletedAt: Value(null)));
      }
      return _requireActiveTag(existing.id);
    }

    final id = Ids.next();
    await _db.tagsDao.insertTag(
      TagsCompanion.insert(
        id: id,
        name: name,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    return _requireActiveTag(id);
  }

  Future<List<Tag>> list() {
    return _db.tagsDao.active().get();
  }

  Future<void> softDelete(String id) async {
    await _requireActiveTag(id);
    await _db.tagsDao.softDelete(id);
  }

  Future<void> hardDelete(String id) async {
    await _db.tagsDao.hardDelete(id);
  }

  Future<void> attach(String entryId, String tagId) async {
    await _db.entryTagsDao.attach(entryId, tagId);
  }

  Future<void> detach(String entryId, String tagId) async {
    await _db.entryTagsDao.detach(entryId, tagId);
  }

  Future<List<Tag>> listForEntry(String entryId) async {
    final links = await _db.entryTagsDao.listByEntry(entryId).get();
    final tags = <Tag>[];
    for (final link in links) {
      final tag = await _db.tagsDao.byId(link.tagId);
      if (tag != null && tag.deletedAt == null) {
        tags.add(tag);
      }
    }
    tags.sort((a, b) => a.name.compareTo(b.name));
    return tags;
  }

  Future<List<Entry>> listEntriesForTag(String tagId) async {
    final links = await _db.entryTagsDao.listByTag(tagId).get();
    final entries = <Entry>[];
    for (final link in links) {
      final entry = await _db.entriesDao.byId(link.entryId);
      if (entry != null && entry.deletedAt == null) {
        entries.add(entry);
      }
    }
    entries.sort((a, b) {
      final dateOrder = b.entryDtUtc.compareTo(a.entryDtUtc);
      return dateOrder == 0 ? b.id.compareTo(a.id) : dateOrder;
    });
    return entries;
  }

  Future<Tag> _requireActiveTag(String id) async {
    final tag = await _db.tagsDao.byId(id);
    if (tag == null || tag.deletedAt != null) {
      throw StateError('Tag not found: $id');
    }
    return tag;
  }
}
