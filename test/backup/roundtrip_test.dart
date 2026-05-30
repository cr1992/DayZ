// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' show Value;
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/backup/backup_exporter.dart';
import 'package:dayz/backup/backup_restorer.dart';

class TestKeyProvider extends KeyProvider {
  final Uint8List _appKey;
  final Uint8List _mediaKey;

  TestKeyProvider(this._appKey, this._mediaKey);

  @override
  Future<Uint8List> getAppDbKey() async => Uint8List.fromList(_appKey);

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(_mediaKey);

  @override
  Future<Uint8List> deriveBackupKey(Uint8List password, Uint8List salt) async {
    final key = Uint8List(32);
    for (var i = 0; i < key.length; i++) {
      key[i] = password[i % password.length] ^ salt[i % salt.length] ^ i;
    }
    return key;
  }
}

void mockPathProvider(Directory documentsDir, Directory tempDir) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return documentsDir.path;
          }
          if (methodCall.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory docsDir;
  late Directory tDir;

  late File dbFile;
  late AppDatabase db;
  late TestKeyProvider keyProvider;
  late MediaStore mediaStore;

  final appKey = Uint8List.fromList(List.generate(32, (i) => i));
  final mediaKey = Uint8List.fromList(List.generate(32, (i) => i + 10));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_roundtrip_test');
    docsDir = Directory(p.join(tempDir.path, 'documents'))
      ..createSync(recursive: true);
    tDir = Directory(p.join(tempDir.path, 'temp'))..createSync(recursive: true);
    mockPathProvider(docsDir, tDir);

    dbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    keyProvider = TestKeyProvider(appKey, mediaKey);

    db = await AppDatabase.openFile(dbFile, Uint8List.fromList(appKey));
    mediaStore = MediaStore(
      keyProvider: keyProvider,
      mediaRepo: MediaRepo(db),
      documentsDirectoryProvider: () async => docsDir,
    );
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Full-scale export -> wipe -> restore roundtrip integration test', () async {
    // 1. Seed database with 3 entries and 2 media files
    final now = DateTime.utc(2026, 5, 30, 10);
    await db.entriesDao.insertEntry(
      EntriesCompanion.insert(
        id: 'entry_1',
        contentJson: const Value('{"insert":"entry one json"}'),
        contentPlain: const Value('Diary entry number one plaintext content.'),
        entryDtUtc: now,
        entryTz: 'UTC',
        localYear: 2026,
        localMonth: 5,
        localDay: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.entriesDao.insertEntry(
      EntriesCompanion.insert(
        id: 'entry_2',
        contentJson: const Value('{"insert":"entry two json"}'),
        contentPlain: const Value('Diary entry number two plaintext content.'),
        entryDtUtc: now.add(const Duration(hours: 1)),
        entryTz: 'UTC',
        localYear: 2026,
        localMonth: 5,
        localDay: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.entriesDao.insertEntry(
      EntriesCompanion.insert(
        id: 'entry_3',
        contentJson: const Value('{"insert":"entry three json"}'),
        contentPlain: const Value(
          'Diary entry number three plaintext content.',
        ),
        entryDtUtc: now.add(const Duration(hours: 2)),
        entryTz: 'UTC',
        localYear: 2026,
        localMonth: 5,
        localDay: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final image1Bytes = utf8.encode('Encrypted photo 1 content');
    final image2Bytes = utf8.encode('Encrypted photo 2 content');

    final media1Path = await mediaStore.put(
      bytes: Stream.value(image1Bytes),
      entryId: 'entry_1',
      kind: MediaKind.image,
      mime: 'image/png',
    );
    final media2Path = await mediaStore.put(
      bytes: Stream.value(image2Bytes),
      entryId: 'entry_2',
      kind: MediaKind.image,
      mime: 'image/jpeg',
    );

    final mediaRecords = await db.mediaDao.active().get();
    expect(mediaRecords.length, equals(2));

    // 2. Export to backup file
    final backupFile = File(p.join(tempDir.path, 'exports', 'backup.mydiary'));
    final exporter = BackupExporter(database: db, keyProvider: keyProvider);
    await exporter.export(
      password: 'mypassword',
      outputPath: backupFile.path,
      onProgress: (_, _, _) {},
    );

    // 3. WIPE database and all documents directory media files (simulate a new device or hard reset)
    await db.close();

    // Delete files
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    final mediaDir = Directory(p.join(docsDir.path, 'media'));
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }

    // Confirm wiped state by creating a new empty db connection
    db = await AppDatabase.openFile(dbFile, Uint8List.fromList(appKey));
    expect(await db.entriesDao.active().get(), isEmpty);
    expect(await db.mediaDao.active().get(), isEmpty);

    // 4. Initialize Restorer and perform Restore
    final restorer = BackupRestorer(database: db, keyProvider: keyProvider);
    final session = await restorer.parseAndConfirm(
      inputPath: backupFile.path,
      password: 'mypassword',
      confirmOverwrite: () async => true,
    );

    // This closes db, restores files, and returns the new AppDatabase connection
    final restoredDb = await restorer.apply(session);
    db = restoredDb; // Keep variable synced for tearDown

    // 5. Verify restored Entries
    final restoredEntries = await db.entriesDao.active().get();
    expect(restoredEntries.length, equals(3));

    final restoredEntry1 = restoredEntries.firstWhere((e) => e.id == 'entry_1');
    expect(
      restoredEntry1.contentPlain,
      equals('Diary entry number one plaintext content.'),
    );
    expect(restoredEntry1.entryDtUtc.toUtc(), equals(now));

    final restoredEntry2 = restoredEntries.firstWhere((e) => e.id == 'entry_2');
    expect(
      restoredEntry2.contentPlain,
      equals('Diary entry number two plaintext content.'),
    );

    final restoredEntry3 = restoredEntries.firstWhere((e) => e.id == 'entry_3');
    expect(
      restoredEntry3.contentPlain,
      equals('Diary entry number three plaintext content.'),
    );

    // 6. Verify restored Media Files
    final restoredMediaRecords = await db.mediaDao.active().get();
    expect(restoredMediaRecords.length, equals(2));

    final restoredMediaStore = MediaStore(
      keyProvider: keyProvider,
      mediaRepo: MediaRepo(db),
      documentsDirectoryProvider: () async => docsDir,
    );

    // Decrypt media and match content bytes directly
    final decrypted1Bytes = await restoredMediaStore
        .openRead(media1Path)
        .fold<List<int>>([], (p, e) => p..addAll(e));
    expect(decrypted1Bytes, equals(image1Bytes));

    final decrypted2Bytes = await restoredMediaStore
        .openRead(media2Path)
        .fold<List<int>>([], (p, e) => p..addAll(e));
    expect(decrypted2Bytes, equals(image2Bytes));

    // 7. Verify FTS Table search works
    final ftsSearchResults = await db
        .customSelect(
          "SELECT rowid FROM entries_fts WHERE entries_fts MATCH 'plaintext';",
        )
        .get();
    expect(ftsSearchResults, isNotEmpty);
  });
}
