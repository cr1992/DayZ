// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:drift/drift.dart';
// ignore: experimental_member_use
import 'package:drift/remote.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/journals.dart';
import 'tables/entries.dart';
import 'tables/media.dart';
import 'tables/tags.dart';
import 'tables/entry_tags.dart';
import 'tables/editing_session.dart';
import 'package:dayz/security/key_provider.dart';

part 'database.g.dart';

typedef AppDatabaseUpgradeObserver =
    Future<void> Function(Migrator m, int from, int to);

class WrongKeyException implements Exception {
  final String message;
  const WrongKeyException([this.message = 'Wrong database key']);

  @override
  String toString() => 'WrongKeyException: $message';
}

@DriftDatabase(
  tables: [Journals, Entries, Media, Tags, EntryTags, EditingSessions],
  daos: [
    JournalsDao,
    EntriesDao,
    MediaDao,
    TagsDao,
    EntryTagsDao,
    EditingSessionDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(
    super.e, {
    this.onUpgradeForTesting,
    this.schemaVersionForTesting = 1,
  }) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final AppDatabaseUpgradeObserver? onUpgradeForTesting;
  final int schemaVersionForTesting;

  @override
  int get schemaVersion => schemaVersionForTesting;

  Future<void> rekey(Uint8List newKey) async {
    final hexKey = _toHex(newKey);
    try {
      await customStatement('PRAGMA rekey = "x\'$hexKey\'";');
    } finally {
      // Zero out the key
      for (var i = 0; i < newKey.length; i++) {
        newKey[i] = 0;
      }
    }
  }

  static QueryExecutor _createExecutor(File file, Uint8List key) {
    final hexKey = _toHex(key);
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA cipher = 'sqlcipher';");
        rawDb.execute("PRAGMA key = \"x'$hexKey'\";");

        final cipherResult = rawDb.select('PRAGMA cipher;');
        final cipherName = cipherResult.isEmpty
            ? null
            : cipherResult.first.values.first?.toString();

        if (cipherName != 'sqlcipher') {
          throw const WrongKeyException(
            'SQLite3MultipleCiphers SQLCipher mode is not loaded correctly.',
          );
        }

        try {
          rawDb.select('SELECT count(*) FROM sqlite_master;');
        } on SqliteException catch (error) {
          throw WrongKeyException(
            'Wrong database key or corrupted database: ${error.message}',
          );
        }
      },
    );
  }

  static Future<AppDatabase> open(KeyProvider keyProvider) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    final key = await keyProvider.getAppDbKey();
    return openFile(dbFile, key);
  }

  static Future<AppDatabase> openFile(File dbFile, Uint8List key) async {
    if (!await dbFile.parent.exists()) {
      await dbFile.parent.create(recursive: true);
    }

    try {
      final executor = _createExecutor(dbFile, key);
      final database = AppDatabase(executor);
      try {
        await database._verifyOpenWithCipher();
        return database;
      } on DriftRemoteException catch (error) {
        final cause = error.remoteCause;
        await database.close();
        if (cause is WrongKeyException) {
          throw cause;
        }
        rethrow;
      } on WrongKeyException {
        await database.close();
        rethrow;
      } catch (_) {
        await database.close();
        rethrow;
      }
    } finally {
      for (var i = 0; i < key.length; i++) {
        key[i] = 0;
      }
    }
  }

  static String _toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _verifyOpenWithCipher() async {
    try {
      final cipherVersionResult = await customSelect('PRAGMA cipher;').get();
      final cipherName = cipherVersionResult.isEmpty
          ? null
          : cipherVersionResult.first.readNullable<String>('sqlcipher');
      if (cipherName != 'sqlcipher') {
        throw const WrongKeyException(
          'SQLite3MultipleCiphers SQLCipher mode is not loaded correctly.',
        );
      }

      await customSelect('SELECT count(*) FROM sqlite_master;').getSingle();
    } on WrongKeyException {
      rethrow;
    } on SqliteException catch (error) {
      throw WrongKeyException(
        'Wrong database key or corrupted database: ${error.message}',
      );
    }
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        // Create indexes as required by the schema design
        await m.database.customStatement(
          'CREATE INDEX idx_entries_timeline ON entries(entry_dt_utc DESC) WHERE deleted_at IS NULL;',
        );
        await m.database.customStatement(
          'CREATE INDEX idx_entries_monthday ON entries(local_month, local_day) WHERE deleted_at IS NULL;',
        );
        await m.database.customStatement(
          'CREATE INDEX idx_entries_updated ON entries(updated_at);',
        );
        await m.database.customStatement(
          'CREATE INDEX idx_entries_sync ON entries(sync_status);',
        );
        await m.database.customStatement(
          'CREATE INDEX idx_media_entry ON media(entry_id);',
        );
        await m.database.customStatement(
          'CREATE INDEX idx_entrytags_tag ON entry_tags(tag_id);',
        );
        // UNIQUE index idx_tags_name on tags(name) for duplicate tag deduplication
        await m.database.customStatement(
          'CREATE UNIQUE INDEX idx_tags_name ON tags(name);',
        );
        // entries_fts virtual table for full-text search
        await m.database.customStatement(
          'CREATE VIRTUAL TABLE entries_fts USING fts5(content_plain);',
        );
      },
      onUpgrade: (m, from, to) async {
        await onUpgradeForTesting?.call(m, from, to);
        // TODO: future versions migration logic. Each future schema bump should
        // route by version range and keep migrations idempotent.
      },
    );
  }
}

@DriftAccessor(tables: [Journals])
class JournalsDao extends DatabaseAccessor<AppDatabase>
    with _$JournalsDaoMixin {
  JournalsDao(super.db);

  Selectable<Journal> active() {
    return select(journals)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.createdAt),
      ]);
  }

  Future<Journal?> byId(String id) {
    return (select(
      journals,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertJournal(JournalsCompanion journal) {
    return into(journals).insert(journal);
  }

  Future<bool> updateJournal(JournalsCompanion journal) {
    return update(journals).replace(journal);
  }

  Future<int> softDelete(String id, {DateTime? deletedAt}) {
    final timestamp = deletedAt ?? DateTime.now().toUtc();
    return (update(journals)..where((table) => table.id.equals(id))).write(
      JournalsCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
      ),
    );
  }

  Future<int> hardDelete(String id) {
    return (delete(journals)..where((table) => table.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [Entries])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.db);

  Selectable<Entry> active() {
    return select(entries)..where((table) => table.deletedAt.isNull());
  }

  Future<Entry?> byId(String id) {
    return (select(
      entries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertEntry(EntriesCompanion entry) {
    return into(entries).insert(entry);
  }

  Future<bool> updateEntry(EntriesCompanion entry) {
    return update(entries).replace(entry);
  }

  Future<int> softDelete(String id, {DateTime? deletedAt}) {
    final timestamp = deletedAt ?? DateTime.now().toUtc();
    return (update(entries)..where((table) => table.id.equals(id))).write(
      EntriesCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
      ),
    );
  }

  Future<int> hardDelete(String id) {
    return (delete(entries)..where((table) => table.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [Media])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(super.db);

  Selectable<MediaData> active() {
    return select(media)..where((table) => table.deletedAt.isNull());
  }

  Selectable<MediaData> listByEntry(String entryId) {
    return select(media)
      ..where(
        (table) => table.entryId.equals(entryId) & table.deletedAt.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
  }

  Future<MediaData?> byId(String id) {
    return (select(
      media,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertMedia(MediaCompanion mediaRow) {
    return into(media).insert(mediaRow);
  }

  Future<bool> updateMedia(MediaCompanion mediaRow) {
    return update(media).replace(mediaRow);
  }

  Future<int> softDelete(String id, {DateTime? deletedAt}) {
    final timestamp = deletedAt ?? DateTime.now().toUtc();
    return (update(media)..where((table) => table.id.equals(id))).write(
      MediaCompanion(deletedAt: Value(timestamp), updatedAt: Value(timestamp)),
    );
  }

  Future<int> hardDelete(String id) {
    return (delete(media)..where((table) => table.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [Tags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Selectable<Tag> active() {
    return select(tags)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
  }

  Future<Tag?> byId(String id) {
    return (select(
      tags,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<Tag?> byName(String name) {
    return (select(
      tags,
    )..where((table) => table.name.equals(name))).getSingleOrNull();
  }

  Future<int> insertTag(TagsCompanion tag) {
    return into(tags).insert(tag);
  }

  Future<int> upsertTag(TagsCompanion tag) {
    return into(tags).insertOnConflictUpdate(tag);
  }

  Future<int> softDelete(String id, {DateTime? deletedAt}) {
    final timestamp = deletedAt ?? DateTime.now().toUtc();
    return (update(tags)..where((table) => table.id.equals(id))).write(
      TagsCompanion(deletedAt: Value(timestamp)),
    );
  }

  Future<int> hardDelete(String id) {
    return (delete(tags)..where((table) => table.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [EntryTags])
class EntryTagsDao extends DatabaseAccessor<AppDatabase>
    with _$EntryTagsDaoMixin {
  EntryTagsDao(super.db);

  Selectable<EntryTag> listByEntry(String entryId) {
    return select(entryTags)..where((table) => table.entryId.equals(entryId));
  }

  Selectable<EntryTag> listByTag(String tagId) {
    return select(entryTags)..where((table) => table.tagId.equals(tagId));
  }

  Future<int> attach(String entryId, String tagId) {
    return into(entryTags).insert(
      EntryTagsCompanion.insert(entryId: entryId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> detach(String entryId, String tagId) {
    return (delete(entryTags)..where(
          (table) => table.entryId.equals(entryId) & table.tagId.equals(tagId),
        ))
        .go();
  }

  Future<int> detachAllForEntry(String entryId) {
    return (delete(
      entryTags,
    )..where((table) => table.entryId.equals(entryId))).go();
  }
}

@DriftAccessor(tables: [EditingSessions])
class EditingSessionDao extends DatabaseAccessor<AppDatabase>
    with _$EditingSessionDaoMixin {
  EditingSessionDao(super.db);

  Future<EditingSession?> byId(String id) {
    return (select(
      editingSessions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> upsertSession(EditingSessionsCompanion session) {
    return into(
      editingSessions,
    ).insert(session, mode: InsertMode.insertOrReplace);
  }

  Future<int> deleteSession(String id) {
    return (delete(
      editingSessions,
    )..where((table) => table.id.equals(id))).go();
  }
}
