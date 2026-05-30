// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/media/media_codec.dart';
import 'package:dayz/backup/backup_exporter.dart';
import 'package:dayz/backup/backup_format.dart';
import 'package:dayz/backup/exceptions.dart';
import 'package:dayz/backup/paths.dart';
import 'package:dayz/backup/manifest.dart';
import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;

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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_exporter_test');
    docsDir = Directory(p.join(tempDir.path, 'documents'))
      ..createSync(recursive: true);
    tDir = Directory(p.join(tempDir.path, 'temp'))..createSync(recursive: true);
    mockPathProvider(docsDir, tDir);

    dbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));

    final appKey = Uint8List.fromList(List.generate(32, (i) => i));
    final mediaKey = Uint8List.fromList(List.generate(32, (i) => i + 10));
    keyProvider = TestKeyProvider(appKey, mediaKey);

    db = await AppDatabase.openFile(dbFile, Uint8List.fromList(appKey));
    mediaStore = MediaStore(
      keyProvider: keyProvider,
      mediaRepo: MediaRepo(db),
      documentsDirectoryProvider: () async => docsDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Export a small database and verify encryption, content, and log exclusion',
    () async {
      // 1. Insert 3 entries
      final now = DateTime.utc(2026, 5, 30, 10);
      await db.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'entry_1',
          contentJson: const Value('{"insert":"one"}'),
          contentPlain: const Value('Diary entry one content. Hello World!'),
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
          contentJson: const Value('{"insert":"two"}'),
          contentPlain: const Value('Diary entry two content.'),
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
          id: 'entry_3',
          contentJson: const Value('{"insert":"three"}'),
          contentPlain: const Value('Diary entry three content.'),
          entryDtUtc: now,
          entryTz: 'UTC',
          localYear: 2026,
          localMonth: 5,
          localDay: 30,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 2. Add 2 media files
      final media1Bytes = utf8.encode('Encrypted Image 1 plaintext content');
      final media2Bytes = utf8.encode('Encrypted Image 2 plaintext content');
      await mediaStore.put(
        bytes: Stream.value(media1Bytes),
        entryId: 'entry_1',
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: media1Bytes.length,
      );
      await mediaStore.put(
        bytes: Stream.value(media2Bytes),
        entryId: 'entry_2',
        kind: MediaKind.image,
        mime: 'image/jpeg',
        fileSize: media2Bytes.length,
      );

      // Get media IDs
      final mediaRecords = await db.mediaDao.active().get();
      expect(mediaRecords.length, equals(2));
      final media1Id = mediaRecords[0].id;
      final media2Id = mediaRecords[1].id;

      // 3. Pre-create mock logs under temporary directory
      final logsDir = Directory(
        p.join(tempDir.path, 'ApplicationSupport', 'logs'),
      );
      await logsDir.create(recursive: true);
      final logFile = File(p.join(logsDir.path, 'app.log'));
      await logFile.writeAsString(
        'Mock diagnostic logs that should not be backed up.',
      );

      // 4. Perform export
      final backupFile = File(
        p.join(tempDir.path, 'exports', 'backup.mydiary'),
      );
      final exporter = BackupExporter(database: db, keyProvider: keyProvider);

      final phases = <String>[];
      await exporter.export(
        password: 'mypassword',
        outputPath: backupFile.path,
        onProgress: (phase, _, _) {
          phases.add(phase);
        },
      );

      // Verify progress phases were reported
      expect(phases, contains('vacuuming'));
      expect(phases, contains('exporting_db'));
      expect(phases, contains('exporting_media'));
      expect(phases, contains('finalizing'));

      expect(await backupFile.exists(), isTrue);

      // 5. Hexdump/Plaintext inspection: check no plain text of diaries or logs is in the file
      final backupBytes = await backupFile.readAsBytes();
      final backupStr = String.fromCharCodes(backupBytes);

      // Check header magic and salt are present
      expect(backupStr.substring(0, 8), equals(backupMagic));

      // But sensitive plain texts must NOT be present in the rest of the file
      expect(backupStr.contains('Diary entry one content'), isFalse);
      expect(
        backupStr.contains('Encrypted Image 1 plaintext content'),
        isFalse,
      );
      expect(backupStr.contains('diagnostic logs'), isFalse);
      expect(
        backupStr.contains('manifest.json'),
        isFalse,
      ); // nested manifest is encrypted, so string shouldn't appear

      // 6. Decrypt and verify TAR contents
      final raf = await backupFile.open();
      final header = await readHeader(raf);
      await raf.close();

      final salt = header.salt;
      final derivedKey = await keyProvider.deriveBackupKey(
        Uint8List.fromList(utf8.encode('mypassword')),
        salt,
      );

      // Read payload bytes
      final payloadOffset = 8 + 1 + 2 + salt.length + 8;
      final payloadBytes = backupBytes.sublist(payloadOffset);
      expect(payloadBytes.length, equals(header.encryptedPayloadSize));

      final decryptedPayloadStream = MediaCodec().decrypt(
        cipher: Stream.value(payloadBytes),
        key: derivedKey,
      );

      // Read entries from TAR
      final tarReader = TarReader(decryptedPayloadStream);
      final entryNames = <String>[];
      String? manifestJson;

      while (await tarReader.moveNext()) {
        final entry = tarReader.current;
        entryNames.add(entry.name);
        if (entry.name == 'manifest.json') {
          final decryptedManifestBytes = await MediaCodec()
              .decrypt(cipher: entry.contents, key: derivedKey)
              .fold<List<int>>([], (p, e) => p..addAll(e));
          manifestJson = utf8.decode(decryptedManifestBytes);
        } else {
          // Drain entry contents to allow reading next entry
          await entry.contents.drain();
        }
      }

      // Verify TAR entries
      expect(entryNames, contains('manifest.json'));
      expect(entryNames, contains('db/main.sqlite'));
      expect(entryNames, contains('media/$media1Id.bin'));
      expect(entryNames, contains('media/$media2Id.bin'));

      // VERIFY diagnostic logs are excluded
      expect(entryNames, isNot(contains(contains('app.log'))));
      expect(entryNames, isNot(contains(contains('logs/'))));

      // Verify Manifest content
      expect(manifestJson, isNotNull);
      final manifest = Manifest.fromJsonString(manifestJson!);
      expect(manifest.formatVersion, equals(1));
      expect(manifest.backupType, equals('full'));
      expect(manifest.schemaVersion, equals(db.schemaVersion));
      expect(manifest.entryCount, equals(3));
      expect(manifest.mediaCount, equals(2));
      expect(manifest.mediaIndex.any((m) => m.id == media1Id), isTrue);
    },
  );

  test('Export cancellation deletes temporary output files', () async {
    final backupFile = File(
      p.join(tempDir.path, 'exports', 'backup_cancelled.mydiary'),
    );
    final exporter = BackupExporter(database: db, keyProvider: keyProvider);

    final cancelCompleter = Completer<void>();

    // Start exporting, trigger cancellation immediately after we start media export
    final exportFuture = exporter.export(
      password: 'mypassword',
      outputPath: backupFile.path,
      onProgress: (phase, _, _) {
        if (phase == 'exporting_db') {
          if (!cancelCompleter.isCompleted) {
            cancelCompleter.complete();
          }
        }
      },
      onCancel: cancelCompleter.future,
    );

    await expectLater(exportFuture, throwsA(isA<BackupCancelledException>()));

    // Verify temporary and output files are deleted/cleaned up
    expect(await backupFile.exists(), isFalse);
    expect(await File('${backupFile.path}.tmp').exists(), isFalse);

    // Verify no vacuum temporary databases left behind
    final backupTemp = await getBackupTempDirectory();
    final tempFiles = await backupTemp.list().toList();
    expect(tempFiles, isEmpty);
  });
}
