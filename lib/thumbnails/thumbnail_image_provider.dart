// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../media/paths.dart';
import 'generator.dart' show decryptBytes;
import 'thumbnail_cache.dart' show DocumentsDirectoryProvider;
import 'thumbnail_handle.dart';

/// 向缩略图缓存请求一张缩略图（签名与 `ThumbnailCache.request` 一致，可直接传 tear-off）。
typedef ThumbnailRequester =
    ThumbnailHandle Function(String mediaId, {ThumbnailPriority priority});

/// 读取设备媒体密钥（设备密钥派生，不经主密码）。
typedef ThumbnailKeyLoader = Future<Uint8List> Function();

/// 解密一份 `MediaCodec` 密文；默认在后台 isolate 里跑。
typedef ThumbnailDecryptor =
    Future<Uint8List> Function(Uint8List cipher, Uint8List key);

Future<Uint8List> _decryptInIsolate(Uint8List cipher, Uint8List key) {
  return Isolate.run(() => decryptBytes(cipher, key));
}

/// 把 `ThumbnailCache` 产出的加密缩略图（`thumbs/<id>.bin`）解密成可渲染的
/// JPEG 字节，并以条数 + 字节双上限的 LRU 缓存在内存里。
///
/// - 只有异步入口（[load] / [providerFor] / [warmup]），没有任何同步解码或
///   同步重建入口：构造 provider 不触发 IO，解码发生在 [ImageStream] 里。
/// - 明文只驻留内存，不落盘；失败结果不缓存，下次请求会重试。
///
/// Author: @Ray
class ThumbnailImageLoader {
  ThumbnailImageLoader({
    required ThumbnailRequester request,
    required ThumbnailKeyLoader loadDeviceMediaKey,
    DocumentsDirectoryProvider? documentsDirectoryProvider,
    ThumbnailDecryptor? decrypt,
    this.maxEntries = defaultMaxEntries,
    this.maxBytes = defaultMaxBytes,
  }) : assert(maxEntries > 0),
       assert(maxBytes > 0),
       _request = request,
       _loadDeviceMediaKey = loadDeviceMediaKey,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? applicationDocumentsDir,
       _decrypt = decrypt ?? _decryptInIsolate;

  /// 默认最多缓存的缩略图张数。
  static const int defaultMaxEntries = 64;

  /// 默认明文字节上限（8 MiB；单张缩略图 < 80 KB）。
  static const int defaultMaxBytes = 8 * 1024 * 1024;

  final int maxEntries;
  final int maxBytes;

  final ThumbnailRequester _request;
  final ThumbnailKeyLoader _loadDeviceMediaKey;
  final DocumentsDirectoryProvider _documentsDirectoryProvider;
  final ThumbnailDecryptor _decrypt;

  // LinkedHashMap 保持插入序：头部最久未用，尾部最近使用。
  final LinkedHashMap<String, Uint8List> _lru =
      LinkedHashMap<String, Uint8List>();
  final Map<String, Future<Uint8List>> _inFlight = {};
  int _bytes = 0;

  /// 当前缓存张数。
  int get cachedCount => _lru.length;

  /// 当前缓存明文字节数。
  int get cachedBytes => _bytes;

  /// 是否已缓存该媒体的解密字节（不改变 LRU 顺序）。
  bool isCached(String mediaId) => _lru.containsKey(mediaId);

  /// 以 low 优先级异步预热，不阻塞调用方；失败被吞掉（取图时再报）。
  void warmup(List<String> mediaIds) {
    for (final id in mediaIds) {
      _request(id, priority: ThumbnailPriority.low).future.ignore();
    }
  }

  /// 该媒体缩略图的异步图源；构造本身不做任何 IO。
  ThumbnailImageProvider providerFor(String mediaId) {
    return ThumbnailImageProvider(mediaId: mediaId, loader: this);
  }

  /// 取解密后的 JPEG 字节：命中 LRU 直接返回；否则等缩略图就绪 → 读密文 →
  /// 设备媒体密钥解密 → 入 LRU。同一 id 并发请求只跑一次。
  Future<Uint8List> load(String mediaId) {
    final cached = _lru.remove(mediaId);
    if (cached != null) {
      _lru[mediaId] = cached;
      return SynchronousFuture<Uint8List>(cached);
    }
    final pending = _inFlight[mediaId];
    if (pending != null) {
      return pending;
    }
    final future = _loadUncached(mediaId);
    _inFlight[mediaId] = future;
    future.then(
      (bytes) {
        _inFlight.remove(mediaId);
        _put(mediaId, bytes);
      },
      onError: (Object _) {
        _inFlight.remove(mediaId);
      },
    );
    return future;
  }

  /// 丢掉某张的解密缓存（原图被替换后由调用方触发）。
  void evict(String mediaId) {
    final removed = _lru.remove(mediaId);
    if (removed != null) {
      _bytes -= removed.length;
    }
  }

  /// 清空解密缓存（组合根关闭时调用）。
  void clear() {
    _lru.clear();
    _bytes = 0;
  }

  Future<Uint8List> _loadUncached(String mediaId) async {
    final result = await _request(mediaId).future;
    final documentsDir = await _documentsDirectoryProvider();
    final file = resolveRelPathWithDocumentsDir(
      result.relPath,
      documentsPath: documentsDir.path,
    );
    final cipher = await file.readAsBytes();
    final key = await _loadDeviceMediaKey();
    try {
      return await _decrypt(cipher, key);
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  void _put(String mediaId, Uint8List bytes) {
    if (bytes.length > maxBytes) {
      return;
    }
    evict(mediaId);
    _lru[mediaId] = bytes;
    _bytes += bytes.length;
    while (_lru.length > maxEntries || _bytes > maxBytes) {
      final oldest = _lru.keys.first;
      evict(oldest);
    }
  }
}

/// 解密缩略图的 [ImageProvider]：key 为 (mediaId, loader)，字节经
/// [ThumbnailImageLoader.load] 异步取得后交给引擎异步解码。
///
/// Author: @Ray
@immutable
class ThumbnailImageProvider extends ImageProvider<ThumbnailImageProvider> {
  const ThumbnailImageProvider({required this.mediaId, required this.loader});

  final String mediaId;
  final ThumbnailImageLoader loader;

  @override
  Future<ThumbnailImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ThumbnailImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    ThumbnailImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: 1.0,
      debugLabel: 'ThumbnailImageProvider(${key.mediaId})',
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<String>('Thumbnail media id', key.mediaId),
      ],
    );
  }

  Future<ui.Codec> _loadCodec(
    ThumbnailImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.loader.load(key.mediaId);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is ThumbnailImageProvider &&
        other.mediaId == mediaId &&
        identical(other.loader, loader);
  }

  @override
  int get hashCode => Object.hash(mediaId, identityHashCode(loader));

  @override
  String toString() => '${objectRuntimeType(this, 'ThumbnailImageProvider')}'
      '("$mediaId")';
}
