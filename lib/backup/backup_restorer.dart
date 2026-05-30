// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'dart:isolate';
import 'package:dayz/data/database.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/media/media_codec.dart';
import 'package:dayz/media/exceptions.dart';
import 'package:dayz/media/paths.dart';
import 'package:dayz/thumbnails/thumbnail_cache.dart';
import 'package:dayz/backup/backup_format.dart';
import 'package:dayz/backup/exceptions.dart';
import 'package:dayz/backup/manifest.dart';
import 'package:tar/tar.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:path/path.dart' as p;

class BackupRestoreSession {
  final String inputPath;
  final Uint8List backupKey;
  final Manifest manifest;
  final BackupHeader header;
  final bool requiresMigration;

  const BackupRestoreSession({
    required this.inputPath,
    required this.backupKey,
    required this.manifest,
    required this.header,
    required this.requiresMigration,
  });
}

class BackupRestorer {
  final AppDatabase database;
  final KeyProvider keyProvider;
  final ThumbnailCache? thumbnailCache;

  BackupRestorer({
    required this.database,
    required this.keyProvider,
    this.thumbnailCache,
  });

  /// Parses the backup at [inputPath], validates it, and asks for overwrite confirmation.
  /// Throws [BadPassword] if the password is wrong.
  /// Throws [SchemaIncompatible] if the backup schema is newer than the app's.
  /// Throws [ManifestCorrupted] if the manifest is missing, invalid, or corrupted.
  /// Throws [BackupCancelledException] if [confirmOverwrite] returns false.
  Future<BackupRestoreSession> parseAndConfirm({
    required String inputPath,
    required String password,
    required Future<bool> Function() confirmOverwrite,
  }) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidBackupFormatException('Backup file not found');
    }

    final raf = await file.open(mode: FileMode.read);
    BackupHeader header;
    try {
      header = await readHeader(raf);
    } finally {
      await raf.close();
    }

    // Derive backup key
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final backupKey = await keyProvider.deriveBackupKey(
      passwordBytes,
      header.salt,
    );

    // Skip the header to read the payload
    final headerLength = 8 + 1 + 2 + header.salt.length + 8;
    final fileStream = file.openRead(headerLength);

    final decryptedPayload = MediaCodec().decrypt(
      cipher: fileStream,
      key: backupKey,
    );

    final tarReader = TarReader(decryptedPayload);
    Manifest? manifest;

    try {
      while (await tarReader.moveNext()) {
        final entry = tarReader.current;
        if (entry.name == 'manifest.json') {
          // Decrypt manifest contents
          final decryptedManifestStream = MediaCodec().decrypt(
            cipher: entry.contents,
            key: backupKey,
          );
          final manifestBytes = await decryptedManifestStream.fold<List<int>>(
            [],
            (p, e) => p..addAll(e),
          );
          final manifestStr = utf8.decode(manifestBytes);
          manifest = Manifest.fromJsonString(manifestStr);
          break;
        } else {
          await entry.contents.drain();
        }
      }
    } on MediaCorruptedException {
      throw const BadPassword();
    } on TarException catch (e) {
      throw ManifestCorrupted(
        'Invalid TAR structure or corrupted backup: ${e.message}',
      );
    } on FormatException catch (e) {
      throw ManifestCorrupted('Manifest is not valid JSON: ${e.message}');
    } finally {
      await tarReader.cancel();
    }

    if (manifest == null) {
      throw const ManifestCorrupted(
        'manifest.json not found in backup package',
      );
    }

    // Check schema compatibility
    final currentSchema = database.schemaVersion;
    if (manifest.schemaVersion > currentSchema) {
      throw SchemaIncompatible(
        'Backup schema version ${manifest.schemaVersion} is newer than App schema version $currentSchema',
      );
    }

    final requiresMigration = manifest.schemaVersion < currentSchema;

    // Trigger overwrite confirmation callback
    final confirmed = await confirmOverwrite();
    if (!confirmed) {
      throw const BackupCancelledException();
    }

    return BackupRestoreSession(
      inputPath: inputPath,
      backupKey: backupKey,
      manifest: manifest,
      header: header,
      requiresMigration: requiresMigration,
    );
  }

  /// Applies the backup from the [session], performing the actual database restore
  /// and media re-encryption under the new device media key.
  /// Returns the newly opened [AppDatabase] instance.
  Future<AppDatabase> apply(BackupRestoreSession session) async {
    final appDbKey = await keyProvider.getAppDbKey();
    final deviceMediaKey = await keyProvider.getDeviceMediaKey();
    final docsDir = await applicationDocumentsDir();

    // Close active database connection first
    await database.close();

    final headerLength = 8 + 1 + 2 + session.header.salt.length + 8;

    final config = _RestoreIsolateConfig(
      inputPath: session.inputPath,
      headerLength: headerLength,
      backupKey: Uint8List.fromList(session.backupKey),
      appDbKey: appDbKey,
      deviceMediaKey: deviceMediaKey,
      documentsDirPath: docsDir.path,
    );

    try {
      await Isolate.run(() => _restoreIsolateEntryPoint(config));
    } catch (e) {
      rethrow;
    }

    // Restore succeeded! Reopen the new database
    final reopenedKey = await keyProvider.getAppDbKey();
    final dbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    final newDb = await AppDatabase.openFile(dbFile, reopenedKey);

    // Rebuild FTS
    await rebuildFts(newDb);

    // Kick off thumbnail warmup
    final activeMedia = await newDb.mediaDao.active().get();
    final allLivingMediaIds = activeMedia.map((m) => m.id).toList();
    kickoffThumbnailWarmup(newDb, allLivingMediaIds);

    return newDb;
  }

  Future<void> rebuildFts(AppDatabase db) async {
    await db.customStatement('DELETE FROM entries_fts;');
    await db.customStatement(
      'INSERT INTO entries_fts(rowid, content_plain) SELECT rowid, content_plain FROM entries WHERE deleted_at IS NULL;',
    );
  }

  void kickoffThumbnailWarmup(AppDatabase db, List<String> mediaIds) {
    thumbnailCache?.warmup(mediaIds);
  }
}

class _RestoreIsolateConfig {
  final String inputPath;
  final int headerLength;
  final Uint8List backupKey;
  final Uint8List appDbKey;
  final Uint8List deviceMediaKey;
  final String documentsDirPath;

  _RestoreIsolateConfig({
    required this.inputPath,
    required this.headerLength,
    required this.backupKey,
    required this.appDbKey,
    required this.deviceMediaKey,
    required this.documentsDirPath,
  });
}

void _restoreIsolateEntryPoint(_RestoreIsolateConfig config) async {
  final mediaCodec = MediaCodec();

  final restoringDbFile = File(
    p.join(config.documentsDirPath, 'db', 'main.sqlite.restoring'),
  );
  if (!await restoringDbFile.parent.exists()) {
    await restoringDbFile.parent.create(recursive: true);
  }

  final activeMediaDir = Directory(p.join(config.documentsDirPath, 'media'));
  final restoringMediaDir = Directory(
    p.join(activeMediaDir.path, '.restoring'),
  );
  final oldMediaDir = Directory(p.join(activeMediaDir.path, '.old'));
  final activeDbFile = File(
    p.join(config.documentsDirPath, 'db', 'main.sqlite'),
  );
  final oldDbFile = File('${activeDbFile.path}.old');

  if (await restoringMediaDir.exists()) {
    await restoringMediaDir.delete(recursive: true);
  }
  await restoringMediaDir.create(recursive: true);

  final fileStream = File(config.inputPath).openRead(config.headerLength);
  final decryptedPayload = mediaCodec.decrypt(
    cipher: fileStream,
    key: config.backupKey,
  );

  final tarReader = TarReader(decryptedPayload);

  try {
    while (await tarReader.moveNext()) {
      final entry = tarReader.current;
      if (entry.name == 'db/main.sqlite') {
        final decryptedDbStream = mediaCodec.decrypt(
          cipher: entry.contents,
          key: config.backupKey,
        );
        final sink = restoringDbFile.openWrite();
        try {
          await sink.addStream(decryptedDbStream);
          await sink.flush();
        } finally {
          await sink.close();
        }

        // Rekey the restoring database from backupKey to appDbKey
        final rawDb = sqlite.sqlite3.open(restoringDbFile.path);
        try {
          rawDb.execute("PRAGMA cipher = 'sqlcipher';");
          final hexOldKey = _toHex(config.backupKey);
          rawDb.execute("PRAGMA key = \"x'$hexOldKey'\";");
          final hexNewKey = _toHex(config.appDbKey);
          rawDb.execute("PRAGMA rekey = \"x'$hexNewKey'\";");
        } finally {
          rawDb.close();
        }
      } else if (entry.name.startsWith('media/') &&
          entry.name.endsWith('.bin')) {
        final id = p.basenameWithoutExtension(entry.name);
        final targetFile = File(p.join(restoringMediaDir.path, '$id.bin'));

        final decryptedStream = mediaCodec.decrypt(
          cipher: entry.contents,
          key: config.backupKey,
        );
        final reencryptedStream = mediaCodec.encrypt(
          plain: decryptedStream,
          key: config.deviceMediaKey,
        );

        final sink = targetFile.openWrite();
        try {
          await sink.addStream(reencryptedStream);
          await sink.flush();
        } finally {
          await sink.close();
        }
      } else {
        await entry.contents.drain();
      }
    }

    // Atomic swaps
    if (await oldMediaDir.exists()) {
      await oldMediaDir.delete(recursive: true);
    }
    if (await oldDbFile.exists()) {
      await oldDbFile.delete();
    }

    await activeMediaDir.create(recursive: true);
    await oldMediaDir.create(recursive: true);
    await _moveRegularFiles(activeMediaDir, oldMediaDir);
    await _moveRegularFiles(restoringMediaDir, activeMediaDir);
    if (await restoringMediaDir.exists()) {
      await restoringMediaDir.delete(recursive: true);
    }

    if (await activeDbFile.exists()) {
      await activeDbFile.rename(oldDbFile.path);
    }
    final journalFile = File('${activeDbFile.path}-journal');
    if (await journalFile.exists()) {
      await journalFile.delete();
    }
    final walFile = File('${activeDbFile.path}-wal');
    if (await walFile.exists()) {
      await walFile.delete();
    }
    final shmFile = File('${activeDbFile.path}-shm');
    if (await shmFile.exists()) {
      await shmFile.delete();
    }

    await restoringDbFile.rename(activeDbFile.path);

    if (await oldDbFile.exists()) {
      await oldDbFile.delete();
    }
    if (await oldMediaDir.exists()) {
      await oldMediaDir.delete(recursive: true);
    }

    final thumbsDir = Directory(p.join(config.documentsDirPath, 'thumbs'));
    if (await thumbsDir.exists()) {
      await thumbsDir.delete(recursive: true);
    }
  } catch (e) {
    // Cleanup temporary restoration files
    try {
      if (await restoringDbFile.exists()) {
        await restoringDbFile.delete();
      }
    } catch (_) {}
    try {
      if (await restoringMediaDir.exists()) {
        await restoringMediaDir.delete(recursive: true);
      }
    } catch (_) {}
    try {
      await _restoreOldDatabase(activeDbFile, oldDbFile);
    } catch (_) {}
    try {
      await _restoreOldMedia(activeMediaDir, oldMediaDir);
    } catch (_) {}
    rethrow;
  } finally {
    await tarReader.cancel();
    _zero(config.backupKey);
    _zero(config.appDbKey);
    _zero(config.deviceMediaKey);
  }
}

String _toHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void _zero(Uint8List bytes) {
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = 0;
  }
}

Future<void> _moveRegularFiles(Directory from, Directory to) async {
  if (!await from.exists()) {
    return;
  }
  await to.create(recursive: true);
  await for (final entity in from.list(followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    await entity.rename(p.join(to.path, p.basename(entity.path)));
  }
}

Future<void> _deleteRegularFiles(Directory directory) async {
  if (!await directory.exists()) {
    return;
  }
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is File) {
      await entity.delete();
    }
  }
}

Future<void> _restoreOldDatabase(File activeDbFile, File oldDbFile) async {
  if (!await oldDbFile.exists()) {
    return;
  }
  if (await activeDbFile.exists()) {
    await activeDbFile.delete();
  }
  await oldDbFile.rename(activeDbFile.path);
}

Future<void> _restoreOldMedia(
  Directory activeMediaDir,
  Directory oldMediaDir,
) async {
  if (!await oldMediaDir.exists()) {
    return;
  }
  await activeMediaDir.create(recursive: true);
  await _deleteRegularFiles(activeMediaDir);
  await _moveRegularFiles(oldMediaDir, activeMediaDir);
  if (await oldMediaDir.exists()) {
    await oldMediaDir.delete(recursive: true);
  }
}
