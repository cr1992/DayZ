// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';

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

  /// 一块条目 id 的上限：远低于 SQLite 旧版 999 个绑定变量的限制。
  static const int tagsByEntryIdsChunkSize = 500;

  /// 按条目 id 集批量取标签：每块 id 只发 1 条 `entry_tags ⋈ tags` 查询。
  ///
  /// 每个请求过的 id（去重后）都有键；值只含未软删除的标签、按名称升序，
  /// 无标签或不存在的条目映射为空列表。空输入直接返回空映射，不查库。
  Future<Map<String, List<Tag>>> tagsByEntryIds(
    Iterable<String> entryIds,
  ) async {
    final ids = entryIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <String, List<Tag>>{};
    }

    final grouped = <String, List<Tag>>{for (final id in ids) id: <Tag>[]};
    for (var start = 0; start < ids.length; start += tagsByEntryIdsChunkSize) {
      final end = start + tagsByEntryIdsChunkSize < ids.length
          ? start + tagsByEntryIdsChunkSize
          : ids.length;
      final chunk = ids.sublist(start, end);
      final query =
          _db.select(_db.entryTags).join([
              innerJoin(_db.tags, _db.tags.id.equalsExp(_db.entryTags.tagId)),
            ])
            ..where(
              _db.entryTags.entryId.isIn(chunk) & _db.tags.deletedAt.isNull(),
            )
            ..orderBy([OrderingTerm.asc(_db.tags.name)]);

      for (final row in await query.get()) {
        final link = row.readTable(_db.entryTags);
        grouped[link.entryId]!.add(row.readTable(_db.tags));
      }
    }

    return {
      for (final entry in grouped.entries)
        entry.key: List<Tag>.unmodifiable(entry.value),
    };
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
