// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../data/ids.dart';
import '../data/repositories/media_repo.dart';
import '../observability/app_logger.dart';
import '../security/key_provider.dart';
import 'exceptions.dart';
import 'media_codec.dart';
import 'paths.dart';

enum MediaKind { image, audio, video }

abstract interface class MediaMetadataRepository {
  Future<void> addMeta(
    String id,
    String entryId,
    String kind,
    String relPath, {
    String? mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  });

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);
}

class MediaRepoMetadataRepository implements MediaMetadataRepository {
  final MediaRepo _repo;

  const MediaRepoMetadataRepository(this._repo);

  @override
  Future<void> addMeta(
    String id,
    String entryId,
    String kind,
    String relPath, {
    String? mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    await _repo.addMeta(
      id,
      entryId,
      kind,
      relPath,
      mime: mime,
      width: width,
      height: height,
      durationMs: durationMs,
      fileSize: fileSize,
    );
  }

  @override
  Future<void> softDelete(String id) {
    return _repo.softDelete(id);
  }

  @override
  Future<void> hardDelete(String id) {
    return _repo.hardDelete(id);
  }
}

typedef DeviceMediaKeyLoader = Future<Uint8List> Function();
typedef DocumentsDirectoryProvider = Future<Directory> Function();

class MediaStore {
  final DeviceMediaKeyLoader _deviceMediaKeyLoader;
  final MediaMetadataRepository _mediaRepo;
  final DocumentsDirectoryProvider _documentsDirectoryProvider;
  final String Function() _idGenerator;
  final MediaCodec _codec;

  MediaStore({
    required KeyProvider keyProvider,
    required MediaRepo mediaRepo,
    DocumentsDirectoryProvider? documentsDirectoryProvider,
    String Function()? idGenerator,
    MediaCodec? codec,
  }) : this.withRepository(
         loadDeviceMediaKey: keyProvider.getDeviceMediaKey,
         metadataRepository: MediaRepoMetadataRepository(mediaRepo),
         documentsDirectoryProvider: documentsDirectoryProvider,
         idGenerator: idGenerator,
         codec: codec,
       );

  MediaStore.withRepository({
    required DeviceMediaKeyLoader loadDeviceMediaKey,
    required MediaMetadataRepository metadataRepository,
    DocumentsDirectoryProvider? documentsDirectoryProvider,
    String Function()? idGenerator,
    MediaCodec? codec,
  }) : _deviceMediaKeyLoader = loadDeviceMediaKey,
       _mediaRepo = metadataRepository,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? applicationDocumentsDir,
       _idGenerator = idGenerator ?? Ids.next,
       _codec = codec ?? MediaCodec();

  Future<String> put({
    required Stream<List<int>> bytes,
    required String entryId,
    required MediaKind kind,
    required String mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    AppLogger.instance.logInfo('media.store.put.start', fields: {
      'entryId': entryId,
      'kind': kind.name,
      'mime': mime,
    });
    final key = await _loadDeviceMediaKey();
    final id = _idGenerator();
    final relPath = mediaRelPathForId(id);
    final root = await mediaRootDir(
      documentsDir: await _documentsDirectoryProvider(),
    );
    final target = File(p.join(root.path, '$id.bin'));
    final tmp = File('${target.path}.tmp');
    var renamed = false;
    IOSink? sink;

    try {
      if (await target.exists()) {
        throw StateError('Media target already exists: $relPath');
      }
      if (await tmp.exists()) {
        await tmp.delete();
      }

      sink = tmp.openWrite();
      await sink.addStream(_codec.encrypt(plain: bytes, key: key));
      await sink.close();
      sink = null;

      await tmp.rename(target.path);
      renamed = true;

      await _mediaRepo.addMeta(
        id,
        entryId,
        kind.name,
        relPath,
        mime: mime,
        width: width,
        height: height,
        durationMs: durationMs,
        fileSize: fileSize,
      );
      AppLogger.instance.logInfo('media.store.put.success', fields: {
        'entryId': entryId,
        'relPath': relPath,
        'fileSize': fileSize,
      });
      return relPath;
    } catch (error) {
      AppLogger.instance.logSevere('media.store.put.failed', fields: {
        'entryId': entryId,
        'error': error.toString(),
      });
      try {
        await sink?.close();
      } catch (_) {
        // Best-effort cleanup keeps the original failure visible.
      }
      await _deleteIfExists(tmp);
      if (renamed) {
        await _deleteIfExists(target);
      }
      rethrow;
    }
  }

  Stream<List<int>> openRead(String relPath) async* {
    AppLogger.instance.logInfo('media.store.read.start', fields: {
      'relPath': relPath,
    });
    final file = await _resolveRelPath(relPath);
    if (!await file.exists()) {
      throw MediaNotFoundException('Media file not found: $relPath');
    }
    final key = await _loadDeviceMediaKey();
    try {
      yield* _codec.decrypt(cipher: file.openRead(), key: key);
    } on MediaCorruptedException {
      throw MediaCorruptedException(relPath);
    }
  }

  Future<void> softDelete(String mediaId) {
    return _mediaRepo.softDelete(mediaId);
  }

  Future<void> hardDelete(String mediaId) async {
    final relPath = mediaRelPathForId(mediaId);
    final file = await _resolveRelPath(relPath);
    if (await file.exists()) {
      await file.delete();
    }
    await _mediaRepo.hardDelete(mediaId);
  }

  Stream<List<int>> streamForBackup(String relPath) {
    AppLogger.instance.logInfo('media.store.backup_stream.start', fields: {
      'relPath': relPath,
    });
    return openRead(relPath);
  }

  Stream<List<int>> encryptForBackup(
    Stream<List<int>> plain,
    Uint8List backupKey,
  ) {
    AppLogger.instance.logInfo('media.store.backup_encrypt.start');
    return _codec.encrypt(plain: plain, key: backupKey);
  }

  static String mediaRelPathForId(String mediaId) {
    return '$mediaDirectoryName/$mediaId.bin';
  }

  Future<File> _resolveRelPath(String relPath) async {
    return resolveRelPath(
      relPath,
      documentsDir: await _documentsDirectoryProvider(),
    );
  }

  Future<Uint8List> _loadDeviceMediaKey() async {
    try {
      final key = await _deviceMediaKeyLoader();
      if (key.length != 32) {
        throw KeyMissingException();
      }
      return Uint8List.fromList(key);
    } on KeyMissingException {
      rethrow;
    } catch (_) {
      throw KeyMissingException();
    }
  }
}

Future<void> _deleteIfExists(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}
