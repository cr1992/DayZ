// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:io';

import '../data/database.dart';
import '../data/repositories/media_repo.dart';
import '../media/paths.dart';
import '../security/key_provider.dart';
import 'cancel_token.dart';
import 'generator.dart';
import 'priority_queue.dart';
import 'thumbnail_handle.dart';
import 'worker_pool.dart';

typedef DocumentsDirectoryProvider = Future<Directory> Function();

class ThumbnailCache {
  final MediaRepo _mediaRepo;
  final KeyProvider _keyProvider;
  final AppDatabase _db;
  final DocumentsDirectoryProvider? _documentsDirectoryProvider;

  final WorkerPool _workerPool = WorkerPool(maxConcurrency: 2);
  final PriorityQueue<String> _queue = PriorityQueue<String>();
  final Map<String, ThumbnailHandle> _pendingHandles = {};

  ThumbnailCache({
    required MediaRepo mediaRepo,
    required KeyProvider keyProvider,
    required AppDatabase db,
    DocumentsDirectoryProvider? documentsDirectoryProvider,
  })  : _mediaRepo = mediaRepo,
        _keyProvider = keyProvider,
        _db = db,
        _documentsDirectoryProvider = documentsDirectoryProvider;

  ThumbnailHandle request(
    String mediaId, {
    ThumbnailPriority priority = ThumbnailPriority.normal,
  }) {
    if (_pendingHandles.containsKey(mediaId)) {
      final existingHandle = _pendingHandles[mediaId]!;
      if (priority == ThumbnailPriority.normal) {
        _queue.add(mediaId, priority);
      }
      return existingHandle;
    }

    final cancelToken = CancelToken();
    final handle = ThumbnailHandle(cancelToken: cancelToken);

    _pendingHandles[mediaId] = handle;

    _checkCacheAndRun(mediaId, handle, priority);

    return handle;
  }

  void warmup(List<String> mediaIds) {
    for (final id in mediaIds) {
      request(id, priority: ThumbnailPriority.low);
    }
  }

  void _checkCacheAndRun(
    String mediaId,
    ThumbnailHandle handle,
    ThumbnailPriority priority,
  ) async {
    try {
      final media = await _db.mediaDao.byId(mediaId);
      if (media == null) {
        _pendingHandles.remove(mediaId);
        handle.completeError(ThumbnailGenerationException('Media row not found: $mediaId'));
        return;
      }

      if (media.thumbPath != null &&
          media.thumbSrcUpdatedAt != null &&
          media.thumbSrcUpdatedAt == media.updatedAt) {
        _pendingHandles.remove(mediaId);
        handle.complete(ThumbnailResult(
          relPath: media.thumbPath!,
          w: media.thumbW ?? 0,
          h: media.thumbH ?? 0,
        ));
        return;
      }

      _queue.add(mediaId, priority);

      handle.cancelToken.whenCancelled.then((_) {
        _queue.remove(mediaId);
        _pendingHandles.remove(mediaId);
      });

      _scheduleNext();
    } catch (e, st) {
      _pendingHandles.remove(mediaId);
      handle.completeError(e, st);
    }
  }

  void _scheduleNext() async {
    if (_workerPool.activeCount >= _workerPool.maxConcurrency) {
      return;
    }

    final mediaId = _queue.pop();
    if (mediaId == null) {
      return;
    }

    final handle = _pendingHandles[mediaId];
    if (handle == null || handle.state == ThumbnailState.cancelled) {
      _scheduleNext();
      return;
    }

    _workerPool.submit(() async {
      try {
        final media = await _db.mediaDao.byId(mediaId);
        if (media == null) {
          throw ThumbnailGenerationException('Media row not found: $mediaId');
        }

        final documentsDir = _documentsDirectoryProvider != null
            ? await _documentsDirectoryProvider!()
            : await applicationDocumentsDir();
        final srcFile = resolveRelPathWithDocumentsDir(
          media.relPath,
          documentsPath: documentsDir.path,
        );

        if (!await srcFile.exists()) {
          throw ThumbnailGenerationException('Source media file not found: ${srcFile.path}');
        }

        final encryptedSrcBytes = await srcFile.readAsBytes();
        final deviceMediaKey = await _keyProvider.getDeviceMediaKey();

        final targetFile = resolveRelPathWithDocumentsDir(
          'thumbs/$mediaId.bin',
          documentsPath: documentsDir.path,
        );

        final result = await generateThumbnail(
          mediaId: mediaId,
          encryptedSrcBytes: encryptedSrcBytes,
          deviceMediaKey: deviceMediaKey,
          targetFile: targetFile,
          mediaRepo: _mediaRepo,
          originalMedia: media,
          db: _db,
        );

        handle.complete(result);
      } catch (e, st) {
        if (e is CancelledException) {
          handle.markCancelled();
        } else {
          handle.completeError(e, st);
        }
      } finally {
        _pendingHandles.remove(mediaId);
      }
    }, handle.cancelToken).catchError((e) {
      if (e is CancelledException) {
        handle.markCancelled();
      } else {
        handle.completeError(e);
      }
      _pendingHandles.remove(mediaId);
    }).whenComplete(() {
      _scheduleNext();
    });

    _scheduleNext();
  }
}

