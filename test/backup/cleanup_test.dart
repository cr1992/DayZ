// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:dayz/data/database.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/backup/backup_exporter.dart';
import 'package:dayz/backup/backup_restorer.dart';
import 'package:dayz/backup/exceptions.dart';
import 'package:dayz/backup/paths.dart';

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

  final appKey = Uint8List.fromList(List.generate(32, (i) => i));
  final mediaKey = Uint8List.fromList(List.generate(32, (i) => i + 10));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_cleanup_test');
    docsDir = Directory(p.join(tempDir.path, 'documents'))
      ..createSync(recursive: true);
    tDir = Directory(p.join(tempDir.path, 'temp'))..createSync(recursive: true);
    mockPathProvider(docsDir, tDir);

    dbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    keyProvider = TestKeyProvider(appKey, mediaKey);

    db = await AppDatabase.openFile(dbFile, Uint8List.fromList(appKey));
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Export normal path cleans up temporary files', () async {
    final backupFile = File(p.join(tempDir.path, 'exports', 'normal.mydiary'));
    final exporter = BackupExporter(database: db, keyProvider: keyProvider);

    await exporter.export(
      password: 'mypassword',
      outputPath: backupFile.path,
      onProgress: (_, _, _) {},
    );

    // Verify final file exists but temporary output file and temp db files are deleted
    expect(await backupFile.exists(), isTrue);
    expect(await File('${backupFile.path}.tmp').exists(), isFalse);

    final tempDbDir = await getBackupTempDirectory();
    final tempDbFiles = await tempDbDir.list().toList();
    expect(tempDbFiles, isEmpty);
  });

  test('Export cancellation cleans up temporary files', () async {
    final backupFile = File(p.join(tempDir.path, 'exports', 'cancel.mydiary'));
    final exporter = BackupExporter(database: db, keyProvider: keyProvider);
    final cancelCompleter = Completer<void>();

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

    // Verify no files are left behind
    expect(await backupFile.exists(), isFalse);
    expect(await File('${backupFile.path}.tmp').exists(), isFalse);

    final tempDbDir = await getBackupTempDirectory();
    final tempDbFiles = await tempDbDir.list().toList();
    expect(tempDbFiles, isEmpty);
  });

  test('Restore exceptional path cleans up restoring files', () async {
    // 1. Create a valid backup file
    final backupFile = File(p.join(tempDir.path, 'valid.mydiary'));
    final exporter = BackupExporter(database: db, keyProvider: keyProvider);
    await exporter.export(
      password: 'mypassword',
      outputPath: backupFile.path,
      onProgress: (_, _, _) {},
    );

    // 2. Parse successfully
    final restorer = BackupRestorer(database: db, keyProvider: keyProvider);
    final session = await restorer.parseAndConfirm(
      inputPath: backupFile.path,
      password: 'mypassword',
      confirmOverwrite: () async => true,
    );

    // 3. Corrupt backup file so apply fails during extraction
    final bytes = await backupFile.readAsBytes();
    final truncatedBytes = bytes.sublist(0, bytes.length - 150);
    await backupFile.writeAsBytes(truncatedBytes);

    // 4. Try applying, which will fail
    var threw = false;
    try {
      final reopenedDb = await restorer.apply(session);
      await reopenedDb.close();
    } catch (_) {
      threw = true;
    }
    expect(threw, isTrue);

    // 5. Verify that restoring temporary files and directories are cleaned up
    final restoringDb = File(
      p.join(docsDir.path, 'db', 'main.sqlite.restoring'),
    );
    final restoringMedia = Directory(
      p.join(docsDir.path, 'media', '.restoring'),
    );
    final oldMedia = Directory(p.join(docsDir.path, 'media', '.old'));

    expect(await restoringDb.exists(), isFalse);
    expect(await restoringMedia.exists(), isFalse);
    expect(await oldMedia.exists(), isFalse);
  });
}
