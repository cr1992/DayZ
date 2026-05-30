// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/backup/paths.dart';
import 'package:dayz/backup/exceptions.dart';
import 'package:dayz/backup/backup_format.dart';
import 'package:dayz/backup/manifest.dart';
import 'package:dayz/media/media_codec.dart';
import 'package:dayz/media/paths.dart';

class BackupExporter {
  final AppDatabase database;
  final KeyProvider keyProvider;

  BackupExporter({required this.database, required this.keyProvider});

  /// Exports the backup to [outputPath].
  /// [onProgress] callback reports progress phases: 'vacuuming', 'exporting_db', 'exporting_media', 'finalizing'.
  /// [onCancel] is a Future that completes if the user cancels the backup.
  Future<void> export({
    required String password,
    required String outputPath,
    required void Function(String phase, int processed, int total) onProgress,
    Future<void>? onCancel,
  }) async {
    final tempDbDir = await getBackupTempDirectory();
    final tempDbFile = File(
      p.join(
        tempDbDir.path,
        'full_${DateTime.now().microsecondsSinceEpoch}.db',
      ),
    );
    final tempOutputFile = File('$outputPath.tmp');

    // Ensure parent output directory exists
    final outputDir = Directory(p.dirname(outputPath));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    try {
      // 1. Salt & Key Derivation
      final salt = keyProvider.generateBackupSalt();
      final passwordBytes = Uint8List.fromList(utf8.encode(password));
      final backupKey = await keyProvider.deriveBackupKey(passwordBytes, salt);

      // 2. Vacuum current DB into tempDbFile
      onProgress('vacuuming', 0, 100);
      await database.customStatement(
        "VACUUM INTO '${tempDbFile.path.replaceAll("'", "''")}';",
      );

      // Rekey the temp database file to backupKey
      final appDbKey = await keyProvider.getAppDbKey();
      final tempDb = await AppDatabase.openFile(tempDbFile, appDbKey);
      try {
        await tempDb.rekey(Uint8List.fromList(backupKey));
      } finally {
        await tempDb.close();
      }

      onProgress('vacuuming', 100, 100);

      // Check for cancellation before spawning the isolate
      if (onCancel != null) {
        bool cancelledBeforeStart = false;
        await Future.any([
          onCancel.then((_) => cancelledBeforeStart = true),
          Future.delayed(Duration.zero),
        ]);
        if (cancelledBeforeStart) {
          throw const BackupCancelledException();
        }
      }

      // 3. Gather metadata
      final activeMedia = await database.mediaDao.active().get();
      final docsDir = await applicationDocumentsDir();

      final mediaList = <Map<String, dynamic>>[];
      final manifestMediaItems = <ManifestMediaItem>[];

      for (final m in activeMedia) {
        final relPath = m.relPath;
        final file = File(p.join(docsDir.path, relPath));
        final encryptedFileSize = await file.exists()
            ? await file.length()
            : null;
        final plainSize =
            m.fileSize ??
            (encryptedFileSize == null
                ? 0
                : encryptedFileSize -
                      MediaCodec.headerLength -
                      MediaCodec.tagLength);
        final tarSize =
            plainSize + MediaCodec.headerLength + MediaCodec.tagLength;

        mediaList.add({'id': m.id, 'relPath': relPath, 'size': tarSize});

        manifestMediaItems.add(
          ManifestMediaItem(
            id: m.id,
            mime: m.mime ?? 'application/octet-stream',
            size: plainSize,
          ),
        );
      }

      final activeEntries = await database.entriesDao.active().get();
      const appVersion = '1.0.0'; // App version constant or read config

      final manifest = Manifest(
        formatVersion: 1,
        backupType: 'full',
        schemaVersion: database.schemaVersion,
        generatedAt: DateTime.now().toUtc(),
        appVersion: appVersion,
        entryCount: activeEntries.length,
        mediaCount: activeMedia.length,
        mediaIndex: manifestMediaItems,
      );

      final manifestJson = manifest.toJsonString();
      final deviceMediaKey = await keyProvider.getDeviceMediaKey();

      // 4. Set up Isolate Communication
      final receivePort = ReceivePort();
      final config = _ExportConfig(
        tempDbPath: tempDbFile.path,
        mediaList: mediaList,
        documentsDirPath: docsDir.path,
        outputPath: tempOutputFile.path,
        backupKey: backupKey,
        deviceMediaKey: deviceMediaKey,
        salt: salt,
        manifestJson: manifestJson,
        progressPort: receivePort.sendPort,
      );

      SendPort? isolateControlPort;
      final completer = Completer<void>();
      late final StreamSubscription sub;

      sub = receivePort.listen((message) {
        if (message is SendPort) {
          isolateControlPort = message;
        } else if (message is List) {
          final type = message[0] as String;
          if (type == 'progress') {
            final phase = message[1] as String;
            final processed = message[2] as int;
            final total = message[3] as int;
            onProgress(phase, processed, total);
          } else if (type == 'done') {
            completer.complete();
          } else if (type == 'error') {
            final err = message[1] as String;
            final stack = message[2] as String;
            if (err.contains('BackupCancelledException')) {
              completer.completeError(const BackupCancelledException());
            } else if (err.contains('BadPassword')) {
              completer.completeError(const BadPassword());
            } else if (err.contains('SchemaIncompatible')) {
              completer.completeError(const SchemaIncompatible());
            } else if (err.contains('ManifestCorrupted')) {
              completer.completeError(const ManifestCorrupted());
            } else if (err.contains('InvalidBackupFormatException')) {
              completer.completeError(const InvalidBackupFormatException());
            } else {
              completer.completeError(RemoteError(err, stack));
            }
          }
        }
      });

      // Handle cancel notifications
      StreamSubscription? cancelSub;
      if (onCancel != null) {
        cancelSub = onCancel.asStream().listen((_) {
          isolateControlPort?.send('cancel');
        });
      }

      // Spawn the background isolate
      await Isolate.spawn(_exportIsolateEntryPoint, config);

      try {
        await completer.future;
      } finally {
        await sub.cancel();
        await cancelSub?.cancel();
        receivePort.close();
      }

      // 5. Finalize: rename temporary output to final path
      onProgress('finalizing', 0, 100);
      if (await tempOutputFile.exists()) {
        if (await File(outputPath).exists()) {
          await File(outputPath).delete();
        }
        await tempOutputFile.rename(outputPath);
      } else {
        throw const BackupException('Temporary backup output file not found');
      }
      onProgress('finalizing', 100, 100);
    } catch (e) {
      // Clean up temporary output file on failure
      try {
        if (await tempOutputFile.exists()) {
          await tempOutputFile.delete();
        }
      } catch (_) {}
      rethrow;
    } finally {
      // Clean up temp DB file
      try {
        if (await tempDbFile.exists()) {
          await tempDbFile.delete();
        }
      } catch (_) {}
    }
  }
}

class _ExportConfig {
  final String tempDbPath;
  final List<Map<String, dynamic>> mediaList;
  final String documentsDirPath;
  final String outputPath;
  final Uint8List backupKey;
  final Uint8List deviceMediaKey;
  final Uint8List salt;
  final String manifestJson;
  final SendPort progressPort;

  _ExportConfig({
    required this.tempDbPath,
    required this.mediaList,
    required this.documentsDirPath,
    required this.outputPath,
    required this.backupKey,
    required this.deviceMediaKey,
    required this.salt,
    required this.manifestJson,
    required this.progressPort,
  });
}

void _exportIsolateEntryPoint(_ExportConfig config) async {
  final controlPort = ReceivePort();
  config.progressPort.send(controlPort.sendPort);

  bool isCancelled = false;
  controlPort.listen((message) {
    if (message == 'cancel') {
      isCancelled = true;
    }
  });

  IOSink? outputSink;
  try {
    final mediaCodec = MediaCodec();
    final outputFile = File(config.outputPath);
    outputSink = outputFile.openWrite();

    // 1. Write Header placeholder with encryptedPayloadSize = 0
    final headerPlaceholder = BackupHeader(
      magic: backupMagic,
      version: backupVersion,
      salt: config.salt,
      encryptedPayloadSize: 0,
    );
    writeHeader(outputSink, headerPlaceholder);
    await outputSink.flush();

    // 2. Prepare TAR stream & encode
    final tarController = StreamController<TarEntry>();
    final tarWriterStream = tarController.stream.transform(tarWriter);

    // Encrypt TAR stream with backupKey
    final encryptedPayload = mediaCodec.encrypt(
      plain: tarWriterStream,
      key: config.backupKey,
    );

    int payloadBytesWritten = 0;
    final payloadWriteCompleter = Completer<void>();
    // Pre-register error handler to avoid unhandled exception warning in Dart zones
    payloadWriteCompleter.future.catchError((_) {});

    encryptedPayload.listen(
      (List<int> chunk) {
        if (isCancelled) {
          payloadWriteCompleter.completeError(const BackupCancelledException());
          return;
        }
        outputSink!.add(chunk);
        payloadBytesWritten += chunk.length;
      },
      onError: (e, s) {
        payloadWriteCompleter.completeError(e, s);
      },
      onDone: () {
        payloadWriteCompleter.complete();
      },
      cancelOnError: true,
    );

    // Sequential helpers
    Stream<List<int>> withCancel(Stream<List<int>> source) async* {
      await for (final chunk in source) {
        if (isCancelled) {
          throw const BackupCancelledException();
        }
        yield chunk;
      }
    }

    Stream<List<int>> trackDbProgress(Stream<List<int>> source) async* {
      await for (final chunk in source) {
        if (isCancelled) {
          throw const BackupCancelledException();
        }
        yield chunk;
      }
      config.progressPort.send(['progress', 'exporting_db', 100, 100]);
    }

    int mediaProcessedCount = 0;
    Stream<List<int>> trackMediaProgress(
      Stream<List<int>> source,
      String id,
    ) async* {
      await for (final chunk in source) {
        if (isCancelled) {
          throw const BackupCancelledException();
        }
        yield chunk;
      }
      mediaProcessedCount++;
      config.progressPort.send([
        'progress',
        'exporting_media',
        mediaProcessedCount,
        config.mediaList.length,
      ]);
    }

    // A. Add db/main.sqlite
    config.progressPort.send(['progress', 'exporting_db', 0, 100]);
    final tempDbFile = File(config.tempDbPath);
    if (!await tempDbFile.exists()) {
      throw const BackupException('Vacuumed temporary database file not found');
    }
    final dbSize = tempDbFile.lengthSync();
    final dbPlainStream = withCancel(tempDbFile.openRead());
    final dbEncryptedStream = trackDbProgress(
      mediaCodec.encrypt(plain: dbPlainStream, key: config.backupKey),
    );

    tarController.add(
      TarEntry(
        TarHeader(
          name: 'db/main.sqlite',
          mode: 420,
          size: dbSize + MediaCodec.headerLength + MediaCodec.tagLength,
        ),
        dbEncryptedStream,
      ),
    );

    // B. Add media files
    config.progressPort.send([
      'progress',
      'exporting_media',
      0,
      config.mediaList.length,
    ]);

    for (final media in config.mediaList) {
      final id = media['id'] as String;
      final relPath = media['relPath'] as String;
      final size = media['size'] as int;

      final mediaFile = File(p.join(config.documentsDirPath, relPath));
      if (!await mediaFile.exists()) {
        throw BackupException('Media file not found: $relPath');
      }

      final rawStream = withCancel(mediaFile.openRead());
      final decryptedStream = mediaCodec.decrypt(
        cipher: rawStream,
        key: config.deviceMediaKey,
      );
      final encryptedStream = mediaCodec.encrypt(
        plain: decryptedStream,
        key: config.backupKey,
      );
      final trackedStream = trackMediaProgress(encryptedStream, id);

      tarController.add(
        TarEntry(
          TarHeader(name: 'media/$id.bin', mode: 420, size: size),
          trackedStream,
        ),
      );
    }

    // C. Add manifest.json
    final manifestBytes = utf8.encode(config.manifestJson);
    final manifestStream = withCancel(Stream.value(manifestBytes));
    final encryptedManifestStream = mediaCodec.encrypt(
      plain: manifestStream,
      key: config.backupKey,
    );

    tarController.add(
      TarEntry(
        TarHeader(
          name: 'manifest.json',
          mode: 420,
          size:
              manifestBytes.length +
              MediaCodec.headerLength +
              MediaCodec.tagLength,
        ),
        encryptedManifestStream,
      ),
    );

    // Close tar controller to finish encoding TAR content
    await tarController.close();

    // Wait for the payload stream to finish writing to output file
    await payloadWriteCompleter.future;
    await outputSink.close();
    outputSink = null;

    // 3. Overwrite the header placeholder with the actual payload size
    final raf = await outputFile.open(mode: FileMode.append);
    try {
      final sizeOffset = 8 + 1 + 2 + config.salt.length;
      await raf.setPosition(sizeOffset);
      final sizeBytes = Uint8List(8);
      final sizeData = ByteData.view(sizeBytes.buffer);
      sizeData.setUint64(0, payloadBytesWritten, Endian.big);
      await raf.writeFrom(sizeBytes);
    } finally {
      await raf.close();
    }

    config.progressPort.send(['done']);
  } catch (e, s) {
    config.progressPort.send(['error', e.toString(), s.toString()]);
  } finally {
    if (outputSink != null) {
      try {
        await outputSink.close();
      } catch (_) {}
    }
    controlPort.close();
  }
}
