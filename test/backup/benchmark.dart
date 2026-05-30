// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray
// ignore_for_file: avoid_print

import 'dart:async';
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
    tempDir = await Directory.systemTemp.createTemp('dayz_benchmark');
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

  test(
    'Benchmark: 10000 entries + 500 media files (1.5 GB total)',
    () async {
      print('\n==================================================');
      print('Starting DayZ Backup & Restore Performance Benchmark');
      print('==================================================');

      // 1. Seed database with 10,000 entries (Batch insertion for speed)
      print('Seeding 10,000 entries into the database...');
      final now = DateTime.utc(2026, 5, 31, 10);
      final stopwatch = Stopwatch()..start();

      await db.batch((batch) {
        for (int i = 0; i < 10000; i++) {
          batch.insert(
            db.entries,
            EntriesCompanion.insert(
              id: 'entry_$i',
              contentPlain: Value(
                'Entry number $i plaintext content for searching banana apple grape fruits.',
              ),
              entryDtUtc: now,
              entryTz: 'UTC',
              localYear: 2026,
              localMonth: 5,
              localDay: 31,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
      print('10,000 entries seeded in ${stopwatch.elapsed.inMilliseconds} ms.');

      // 2. Seed 500 media files of 3MB each (total 1.5 GB)
      print('Writing 500 media files of 3MB each to disk (Total 1.5 GB)...');
      final dummyBytes = Uint8List(3 * 1024 * 1024); // 3 MB
      stopwatch.reset();

      for (int i = 0; i < 500; i++) {
        if (i > 0 && i % 100 == 0) {
          print('Written $i / 500 media files...');
        }
        await mediaStore.put(
          bytes: Stream.value(dummyBytes),
          entryId: 'entry_${i % 10000}',
          kind: MediaKind.image,
          mime: 'image/png',
          fileSize: dummyBytes.length,
        );
      }
      print(
        '500 media files encrypted and written in ${stopwatch.elapsed.inSeconds} seconds.',
      );

      // Initialize FTS table initially
      await db.customStatement('DELETE FROM entries_fts;');
      await db.customStatement(
        'INSERT INTO entries_fts(rowid, content_plain) SELECT rowid, content_plain FROM entries WHERE deleted_at IS NULL;',
      );

      // 3. Measure Export Performance (NF1)
      print('\n--------------------------------------------------');
      print('Running NF1 Export Benchmark...');
      final backupFile = File(
        p.join(tempDir.path, 'exports', 'benchmark.mydiary'),
      );
      final exporter = BackupExporter(database: db, keyProvider: keyProvider);

      stopwatch.reset();
      await exporter.export(
        password: 'benchmarkpassword',
        outputPath: backupFile.path,
        onProgress: (phase, processed, total) {
          // Output progress every 100 media files during exporting_media
          if (phase == 'exporting_media' && processed % 100 == 0) {
            print('Export Progress: $phase ($processed / $total)');
          }
        },
      );
      final exportSeconds = stopwatch.elapsed.inSeconds;
      final fileSizeMB = (backupFile.lengthSync() / (1024 * 1024))
          .toStringAsFixed(1);

      print('\n[NF1 EXPORT RESULT]:');
      print('Time taken: $exportSeconds seconds');
      print('Backup file size: $fileSizeMB MB');
      final exportPassed = exportSeconds < 180; // 3 minutes limit
      print('Benchmark Target: < 180 seconds');
      print('Status: ${exportPassed ? "PASS" : "FAIL"}');
      print('--------------------------------------------------');

      // 4. WIPE the active state to prepare for restore
      print('\nWiping local state for restore testing...');
      await db.close();

      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      final mediaDir = Directory(p.join(docsDir.path, 'media'));
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
      }

      // Reopen as a fresh empty DB
      db = await AppDatabase.openFile(dbFile, Uint8List.fromList(appKey));
      expect(await db.entriesDao.active().get(), isEmpty);
      expect(await db.mediaDao.active().get(), isEmpty);

      // 5. Measure Restore Performance (NF2)
      print('\n--------------------------------------------------');
      print('Running NF2 Restore Benchmark...');
      final restorer = BackupRestorer(database: db, keyProvider: keyProvider);

      final session = await restorer.parseAndConfirm(
        inputPath: backupFile.path,
        password: 'benchmarkpassword',
        confirmOverwrite: () async => true,
      );

      stopwatch.reset();
      final restoredDb = await restorer.apply(session);
      db = restoredDb; // Sync connection for teardown
      final restoreSeconds = stopwatch.elapsed.inSeconds;

      print('\n[NF2 RESTORE RESULT]:');
      print('Time taken: $restoreSeconds seconds');
      final restorePassed = restoreSeconds < 240; // 4 minutes limit
      print('Benchmark Target: < 240 seconds');
      print('Status: ${restorePassed ? "PASS" : "FAIL"}');
      print('--------------------------------------------------');

      // 6. Verify restored database validity
      final restoredEntriesCount = (await db.entriesDao.active().get()).length;
      final restoredMediaCount = (await db.mediaDao.active().get()).length;
      expect(restoredEntriesCount, equals(10000));
      expect(restoredMediaCount, equals(500));

      final ftsSearchResult = await db
          .customSelect(
            "SELECT rowid FROM entries_fts WHERE entries_fts MATCH 'grape';",
          )
          .get();
      expect(ftsSearchResult.length, equals(10000));

      print('\n==================================================');
      print('Benchmark Summary:');
      print(
        'Export (NF1): $exportSeconds seconds (Target < 180s) -> ${exportPassed ? "PASSED" : "FAILED"}',
      );
      print(
        'Restore (NF2): $restoreSeconds seconds (Target < 240s) -> ${restorePassed ? "PASSED" : "FAILED"}',
      );
      print('All data integrity assertions verified successfully!');
      print('==================================================\n');

      expect(exportPassed, isTrue, reason: 'Export took too long');
      expect(restorePassed, isTrue, reason: 'Restore took too long');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
