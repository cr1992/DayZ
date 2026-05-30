// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/media/media_codec.dart';
import 'package:dayz/backup/backup_restorer.dart';
import 'package:dayz/backup/backup_format.dart';
import 'package:dayz/backup/exceptions.dart';
import 'package:dayz/backup/manifest.dart';
import 'package:dayz/backup/tar_stream.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

class TestKeyProvider extends KeyProvider {
  final Uint8List _appKey;
  final Uint8List _mediaKey;

  TestKeyProvider(this._appKey, this._mediaKey);

  @override
  Future<Uint8List> getAppDbKey() async => _appKey;

  @override
  Future<Uint8List> getDeviceMediaKey() async => _mediaKey;

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

Future<void> createTestBackup({
  required File file,
  required String password,
  required Uint8List salt,
  required Manifest manifest,
  bool corruptManifest = false,
  bool corruptTar = false,
}) async {
  final keyProvider = TestKeyProvider(Uint8List(32), Uint8List(32));
  final backupKey = await keyProvider.deriveBackupKey(
    Uint8List.fromList(utf8.encode(password)),
    salt,
  );

  List<int> payloadBytes;

  if (corruptTar) {
    payloadBytes = utf8.encode('Totally corrupted payload - not a TAR');
  } else {
    final tempTarFile = File('${file.path}.temp_tar');
    final tarSink = tempTarFile.openWrite();
    final writer = TarStreamWriter(tarSink);

    final manifestBytes = corruptManifest
        ? utf8.encode('{invalid json: true')
        : utf8.encode(manifest.toJsonString());

    final encryptedManifestStream = MediaCodec().encrypt(
      plain: Stream.value(manifestBytes),
      key: backupKey,
    );

    await writer.addEntry(
      'manifest.json',
      encryptedManifestStream,
      size:
          manifestBytes.length + MediaCodec.headerLength + MediaCodec.tagLength,
    );
    await writer.close();
    await tarSink.close();

    payloadBytes = await tempTarFile.readAsBytes();
    try {
      await tempTarFile.delete();
    } catch (_) {}
  }

  // Encrypt payload
  final encryptedPayloadBytes = await MediaCodec()
      .encrypt(plain: Stream.value(payloadBytes), key: backupKey)
      .fold<List<int>>([], (p, e) => p..addAll(e));

  final outputSink = file.openWrite();
  final header = BackupHeader(
    magic: backupMagic,
    version: backupVersion,
    salt: salt,
    encryptedPayloadSize: encryptedPayloadBytes.length,
  );
  writeHeader(outputSink, header);
  outputSink.add(encryptedPayloadBytes);
  await outputSink.flush();
  await outputSink.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory docsDir;
  late Directory tDir;
  late File dbFile;
  late AppDatabase db;
  late TestKeyProvider keyProvider;
  final salt = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_restorer_parse_test');
    docsDir = Directory(p.join(tempDir.path, 'documents'))
      ..createSync(recursive: true);
    tDir = Directory(p.join(tempDir.path, 'temp'))..createSync(recursive: true);
    mockPathProvider(docsDir, tDir);

    dbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    final appKey = Uint8List.fromList(List.generate(32, (i) => i));
    final mediaKey = Uint8List.fromList(List.generate(32, (i) => i + 10));
    keyProvider = TestKeyProvider(appKey, mediaKey);

    db = await AppDatabase.openFile(dbFile, appKey);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('parseAndConfirm parses valid backup package successfully', () async {
    final file = File(p.join(tempDir.path, 'valid.mydiary'));
    final manifest = Manifest(
      formatVersion: 1,
      backupType: 'full',
      schemaVersion: db.schemaVersion,
      generatedAt: DateTime.now().toUtc(),
      appVersion: '1.0.0',
      entryCount: 0,
      mediaCount: 0,
      mediaIndex: [],
    );

    await createTestBackup(
      file: file,
      password: 'correct_password',
      salt: salt,
      manifest: manifest,
    );

    final restorer = BackupRestorer(database: db, keyProvider: keyProvider);
    final session = await restorer.parseAndConfirm(
      inputPath: file.path,
      password: 'correct_password',
      confirmOverwrite: () async => true,
    );

    expect(session.inputPath, equals(file.path));
    expect(session.manifest, equals(manifest));
    expect(session.requiresMigration, isFalse);
  });

  test('Throws BadPassword when incorrect password is provided', () async {
    final file = File(p.join(tempDir.path, 'bad_password.mydiary'));
    final manifest = Manifest(
      formatVersion: 1,
      backupType: 'full',
      schemaVersion: db.schemaVersion,
      generatedAt: DateTime.now().toUtc(),
      appVersion: '1.0.0',
      entryCount: 0,
      mediaCount: 0,
      mediaIndex: [],
    );

    await createTestBackup(
      file: file,
      password: 'correct_password',
      salt: salt,
      manifest: manifest,
    );

    final restorer = BackupRestorer(database: db, keyProvider: keyProvider);

    await expectLater(
      restorer.parseAndConfirm(
        inputPath: file.path,
        password: 'wrong_password',
        confirmOverwrite: () async => true,
      ),
      throwsA(isA<BadPassword>()),
    );
  });

  test(
    'Throws SchemaIncompatible when backup schema version is newer than app',
    () async {
      final file = File(p.join(tempDir.path, 'newer_schema.mydiary'));
      final manifest = Manifest(
        formatVersion: 1,
        backupType: 'full',
        schemaVersion: db.schemaVersion + 1, // newer schema
        generatedAt: DateTime.now().toUtc(),
        appVersion: '1.0.0',
        entryCount: 0,
        mediaCount: 0,
        mediaIndex: [],
      );

      await createTestBackup(
        file: file,
        password: 'correct_password',
        salt: salt,
        manifest: manifest,
      );

      final restorer = BackupRestorer(database: db, keyProvider: keyProvider);

      await expectLater(
        restorer.parseAndConfirm(
          inputPath: file.path,
          password: 'correct_password',
          confirmOverwrite: () async => true,
        ),
        throwsA(isA<SchemaIncompatible>()),
      );
    },
  );

  test(
    'Flags requiresMigration when backup schema version is older than app',
    () async {
      // Open a database with a custom high version to simulate newer app
      await db.close();
      db = AppDatabase(
        _createExecutorForFile(
          dbFile,
          Uint8List.fromList(List.generate(32, (i) => i)),
        ),
        schemaVersionForTesting: 2, // app version is 2
      );

      final file = File(p.join(tempDir.path, 'older_schema.mydiary'));
      final manifest = Manifest(
        formatVersion: 1,
        backupType: 'full',
        schemaVersion: 1, // backup version is 1
        generatedAt: DateTime.now().toUtc(),
        appVersion: '1.0.0',
        entryCount: 0,
        mediaCount: 0,
        mediaIndex: [],
      );

      await createTestBackup(
        file: file,
        password: 'correct_password',
        salt: salt,
        manifest: manifest,
      );

      final restorer = BackupRestorer(database: db, keyProvider: keyProvider);
      final session = await restorer.parseAndConfirm(
        inputPath: file.path,
        password: 'correct_password',
        confirmOverwrite: () async => true,
      );

      expect(session.requiresMigration, isTrue);
    },
  );

  test(
    'Throws ManifestCorrupted when manifest is corrupted or missing',
    () async {
      final file = File(p.join(tempDir.path, 'corrupted_manifest.mydiary'));
      final manifest = Manifest(
        formatVersion: 1,
        backupType: 'full',
        schemaVersion: db.schemaVersion,
        generatedAt: DateTime.now().toUtc(),
        appVersion: '1.0.0',
        entryCount: 0,
        mediaCount: 0,
        mediaIndex: [],
      );

      // Write with corrupted JSON
      await createTestBackup(
        file: file,
        password: 'correct_password',
        salt: salt,
        manifest: manifest,
        corruptManifest: true,
      );

      final restorer = BackupRestorer(database: db, keyProvider: keyProvider);

      await expectLater(
        restorer.parseAndConfirm(
          inputPath: file.path,
          password: 'correct_password',
          confirmOverwrite: () async => true,
        ),
        throwsA(isA<ManifestCorrupted>()),
      );
    },
  );

  test(
    'Throws BackupCancelledException when confirmOverwrite returns false',
    () async {
      final file = File(p.join(tempDir.path, 'cancel.mydiary'));
      final manifest = Manifest(
        formatVersion: 1,
        backupType: 'full',
        schemaVersion: db.schemaVersion,
        generatedAt: DateTime.now().toUtc(),
        appVersion: '1.0.0',
        entryCount: 0,
        mediaCount: 0,
        mediaIndex: [],
      );

      await createTestBackup(
        file: file,
        password: 'correct_password',
        salt: salt,
        manifest: manifest,
      );

      final restorer = BackupRestorer(database: db, keyProvider: keyProvider);

      await expectLater(
        restorer.parseAndConfirm(
          inputPath: file.path,
          password: 'correct_password',
          confirmOverwrite: () async => false, // reject overwrite
        ),
        throwsA(isA<BackupCancelledException>()),
      );
    },
  );
}

// A helper to reconstruct NativeDatabase for testing older schema versions
QueryExecutor _createExecutorForFile(File file, Uint8List key) {
  return NativeDatabase.createInBackground(
    file,
    setup: (rawDb) {
      final hexKey = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      rawDb.execute('PRAGMA key = "x\'$hexKey\'";');
    },
  );
}
