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

  late File originalDbFile;
  late AppDatabase originalDb;
  late TestKeyProvider keyProvider;
  late MediaStore originalMediaStore;

  final appKey = Uint8List.fromList(List.generate(32, (i) => i));
  final mediaKey = Uint8List.fromList(List.generate(32, (i) => i + 10));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_restorer_apply_test');
    docsDir = Directory(p.join(tempDir.path, 'documents'))
      ..createSync(recursive: true);
    tDir = Directory(p.join(tempDir.path, 'temp'))..createSync(recursive: true);
    mockPathProvider(docsDir, tDir);

    originalDbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    keyProvider = TestKeyProvider(appKey, mediaKey);

    originalDb = await AppDatabase.openFile(
      originalDbFile,
      Uint8List.fromList(appKey),
    );
    originalMediaStore = MediaStore(
      keyProvider: keyProvider,
      mediaRepo: MediaRepo(originalDb),
      documentsDirectoryProvider: () async => docsDir,
    );
  });

  tearDown(() async {
    try {
      await originalDb.close();
    } catch (_) {}
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'apply restores new database and media files, and deletes thumbs',
    () async {
      // 1. Set up original database state with 1 entry and 1 media file
      final now = DateTime.utc(2026, 5, 30, 10);
      await originalDb.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'old_entry',
          contentJson: const Value('{"insert":"old"}'),
          contentPlain: const Value('Old entry content'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final oldMediaPath = await originalMediaStore.put(
        bytes: Stream.value(utf8.encode('Old image content')),
        entryId: 'old_entry',
        kind: MediaKind.image,
        mime: 'image/png',
      );

      // Create a mock thumbs folder & file
      final thumbsDir = Directory(p.join(docsDir.path, 'thumbs'));
      await thumbsDir.create(recursive: true);
      final thumbFile = File(p.join(thumbsDir.path, 'thumb_1.bin'));
      await thumbFile.writeAsString('thumb cached bytes');

      // Verify original state is set up
      final oldMediaRecords = await originalDb.mediaDao.active().get();
      expect(oldMediaRecords.length, equals(1));
      expect(await File(p.join(docsDir.path, oldMediaPath)).exists(), isTrue);
      expect(await thumbFile.exists(), isTrue);

      // 2. Setup a separate database for backup data, populate it, and export
      final backupDbFile = File(p.join(tempDir.path, 'backup_src.sqlite'));
      final backupDb = await AppDatabase.openFile(
        backupDbFile,
        Uint8List.fromList(appKey),
      );
      final backupMediaStore = MediaStore(
        keyProvider: keyProvider,
        mediaRepo: MediaRepo(backupDb),
        documentsDirectoryProvider: () async => docsDir,
      );

      await backupDb.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'new_entry_1',
          contentJson: const Value('{"insert":"new 1"}'),
          contentPlain: const Value('New entry 1 content'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await backupMediaStore.put(
        bytes: Stream.value(utf8.encode('New image content')),
        entryId: 'new_entry_1',
        kind: MediaKind.image,
        mime: 'image/png',
      );

      final backupFile = File(p.join(tempDir.path, 'backup.mydiary'));
      final exporter = BackupExporter(
        database: backupDb,
        keyProvider: keyProvider,
      );
      await exporter.export(
        password: 'restorepassword',
        outputPath: backupFile.path,
        onProgress: (_, _, _) {},
      );
      await backupDb.close();

      // 3. Perform parsing and confirmation on the originalDb
      final restorer = BackupRestorer(
        database: originalDb,
        keyProvider: keyProvider,
      );
      final session = await restorer.parseAndConfirm(
        inputPath: backupFile.path,
        password: 'restorepassword',
        confirmOverwrite: () async => true,
      );

      // 4. Apply restore
      final restoredDb = await restorer.apply(session);

      // 5. Verify restored state
      final restoredEntries = await restoredDb.entriesDao.active().get();
      expect(restoredEntries.length, equals(1));
      expect(restoredEntries.first.id, equals('new_entry_1'));
      expect(restoredEntries.first.contentPlain, equals('New entry 1 content'));

      final restoredMedia = await restoredDb.mediaDao.active().get();
      expect(restoredMedia.length, equals(1));
      final restoredMediaId = restoredMedia.first.id;
      final restoredFile = File(
        p.join(docsDir.path, restoredMedia.first.relPath),
      );
      expect(await restoredFile.exists(), isTrue);

      // Verify it decrypts to the new content
      final restoredMediaStore = MediaStore(
        keyProvider: keyProvider,
        mediaRepo: MediaRepo(restoredDb),
        documentsDirectoryProvider: () async => docsDir,
      );
      final decryptedBytes = await restoredMediaStore
          .openRead(MediaStore.mediaRelPathForId(restoredMediaId))
          .fold<List<int>>([], (p, e) => p..addAll(e));
      expect(utf8.decode(decryptedBytes), equals('New image content'));

      // Verify old files are cleaned up
      expect(await File(p.join(docsDir.path, oldMediaPath)).exists(), isFalse);
      expect(await thumbsDir.exists(), isFalse);

      await restoredDb.close();
    },
  );

  test(
    'Failure during temporary writing stage rolls back and keeps original database intact',
    () async {
      // 1. Set up original database state
      final now = DateTime.utc(2026, 5, 30, 10);
      await originalDb.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'keep_me_entry',
          contentJson: const Value('{"insert":"keep"}'),
          contentPlain: const Value('Original database data'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await originalMediaStore.put(
        bytes: Stream.value(utf8.encode('Original image data')),
        entryId: 'keep_me_entry',
        kind: MediaKind.image,
        mime: 'image/png',
      );
      final originalMediaId =
          (await originalDb.mediaDao.active().get()).first.id;

      // 2. Create a corrupted backup file
      final backupDbFile = File(p.join(tempDir.path, 'backup_src.sqlite'));
      final backupDb = await AppDatabase.openFile(
        backupDbFile,
        Uint8List.fromList(appKey),
      );
      await backupDb.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'corrupt_new_entry',
          contentJson: const Value('{"insert":"corrupt"}'),
          contentPlain: const Value('This won\'t restore'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final backupFile = File(p.join(tempDir.path, 'corrupt.mydiary'));
      final exporter = BackupExporter(
        database: backupDb,
        keyProvider: keyProvider,
      );
      await exporter.export(
        password: 'restorepassword',
        outputPath: backupFile.path,
        onProgress: (_, _, _) {},
      );
      await backupDb.close();

      // Parse the session successfully
      final restorer = BackupRestorer(
        database: originalDb,
        keyProvider: keyProvider,
      );
      final session = await restorer.parseAndConfirm(
        inputPath: backupFile.path,
        password: 'restorepassword',
        confirmOverwrite: () async => true,
      );

      // Corrupt the backup file before apply, truncating it so decryption/extraction throws an error
      final bytes = await backupFile.readAsBytes();
      // Truncate the file payload mid-way
      final truncatedBytes = bytes.sublist(0, bytes.length - 200);
      await backupFile.writeAsBytes(truncatedBytes);

      // 3. Try applying, which should fail
      var threw = false;
      AppDatabase? returnedDb;
      try {
        returnedDb = await restorer.apply(session);
      } catch (_) {
        threw = true;
      }
      expect(threw, isTrue);

      // 4. Verify that:
      // a. The returnedDb is the original database (or reopened original database)
      final dbToVerify =
          returnedDb ??
          await AppDatabase.openFile(
            originalDbFile,
            Uint8List.fromList(appKey),
          );

      // b. The original entry is still intact
      final entries = await dbToVerify.entriesDao.active().get();
      expect(entries.length, equals(1));
      expect(entries.first.id, equals('keep_me_entry'));
      expect(entries.first.contentPlain, equals('Original database data'));

      // c. The original media file is still present and decryptable
      final mediaStore = MediaStore(
        keyProvider: keyProvider,
        mediaRepo: MediaRepo(dbToVerify),
        documentsDirectoryProvider: () async => docsDir,
      );
      final decryptedBytes = await mediaStore
          .openRead(MediaStore.mediaRelPathForId(originalMediaId))
          .fold<List<int>>([], (p, e) => p..addAll(e));
      expect(utf8.decode(decryptedBytes), equals('Original image data'));

      // d. Temporary restoring files are cleaned up
      final restoringDb = File(
        p.join(docsDir.path, 'db', 'main.sqlite.restoring'),
      );
      final restoringMedia = Directory(
        p.join(docsDir.path, 'media', '.restoring'),
      );
      expect(await restoringDb.exists(), isFalse);
      expect(await restoringMedia.exists(), isFalse);

      await dbToVerify.close();
    },
  );

  test(
    'Failure before switch stage keeps active database and media untouched',
    () async {
      final now = DateTime.utc(2026, 5, 30, 10);
      await originalDb.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'active_entry',
          contentJson: const Value('{"insert":"active"}'),
          contentPlain: const Value('Active database data'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await originalMediaStore.put(
        bytes: Stream.value(utf8.encode('Active image data')),
        entryId: 'active_entry',
        kind: MediaKind.image,
        mime: 'image/png',
      );
      final originalMediaId =
          (await originalDb.mediaDao.active().get()).first.id;

      final backupDbFile = File(p.join(tempDir.path, 'switch_src.sqlite'));
      final backupDb = await AppDatabase.openFile(
        backupDbFile,
        Uint8List.fromList(appKey),
      );
      final backupMediaStore = MediaStore(
        keyProvider: keyProvider,
        mediaRepo: MediaRepo(backupDb),
        documentsDirectoryProvider: () async => docsDir,
      );
      await backupDb.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'new_entry',
          contentJson: const Value('{"insert":"new"}'),
          contentPlain: const Value('New database data'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await backupMediaStore.put(
        bytes: Stream.value(utf8.encode('New image data')),
        entryId: 'new_entry',
        kind: MediaKind.image,
        mime: 'image/png',
      );

      final backupFile = File(p.join(tempDir.path, 'switch_failure.mydiary'));
      final exporter = BackupExporter(
        database: backupDb,
        keyProvider: keyProvider,
      );
      await exporter.export(
        password: 'restorepassword',
        outputPath: backupFile.path,
        onProgress: (_, _, _) {},
      );
      await backupDb.close();

      // Block creation of the cutover staging directory after all restoring
      // files have been prepared, but before active media/db files are moved.
      final oldMediaBlocker = File(p.join(docsDir.path, 'media', '.old'));
      await oldMediaBlocker.create(recursive: true);

      final restorer = BackupRestorer(
        database: originalDb,
        keyProvider: keyProvider,
      );
      final session = await restorer.parseAndConfirm(
        inputPath: backupFile.path,
        password: 'restorepassword',
        confirmOverwrite: () async => true,
      );

      await expectLater(
        restorer.apply(session),
        throwsA(isA<FileSystemException>()),
      );

      final dbToVerify = await AppDatabase.openFile(
        originalDbFile,
        Uint8List.fromList(appKey),
      );
      final entries = await dbToVerify.entriesDao.active().get();
      expect(entries.length, equals(1));
      expect(entries.first.id, equals('active_entry'));
      expect(entries.first.contentPlain, equals('Active database data'));

      final mediaStore = MediaStore(
        keyProvider: keyProvider,
        mediaRepo: MediaRepo(dbToVerify),
        documentsDirectoryProvider: () async => docsDir,
      );
      final decryptedBytes = await mediaStore
          .openRead(MediaStore.mediaRelPathForId(originalMediaId))
          .fold<List<int>>([], (p, e) => p..addAll(e));
      expect(utf8.decode(decryptedBytes), equals('Active image data'));

      expect(
        await File(
          p.join(docsDir.path, 'db', 'main.sqlite.restoring'),
        ).exists(),
        isFalse,
      );
      expect(
        await Directory(p.join(docsDir.path, 'media', '.restoring')).exists(),
        isFalse,
      );

      await dbToVerify.close();
    },
  );
}
