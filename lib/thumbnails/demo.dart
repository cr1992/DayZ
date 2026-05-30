// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/repositories/entry_repo.dart';
import '../data/repositories/media_repo.dart';
import '../media/media_store.dart';
import '../media/paths.dart';
import '../security/key_provider.dart';
import 'generator.dart';
import 'thumbnail_cache.dart';
import 'thumbnail_handle.dart';

class ThumbnailsDemo extends StatefulWidget {
  final AppDatabase? database;
  final KeyProvider? keyProvider;

  const ThumbnailsDemo({super.key, this.database, this.keyProvider});

  @override
  State<ThumbnailsDemo> createState() => _ThumbnailsDemoState();
}

class _ThumbnailsDemoState extends State<ThumbnailsDemo> {
  late final AppDatabase _db;
  late final KeyProvider _keyProvider;
  late final MediaRepo _mediaRepo;
  late final EntryRepo _entryRepo;
  late final MediaStore _mediaStore;
  late final ThumbnailCache _thumbnailCache;
  late final bool _ownsDatabase;

  String? _mediaId;
  String _statusText = '未开始';
  ThumbnailHandle? _currentHandle;
  Uint8List? _thumbImageBytes;

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase(NativeDatabase.memory());
    _ownsDatabase = widget.database == null;
    _keyProvider = widget.keyProvider ?? KeyProvider();
    _mediaRepo = MediaRepo(_db);
    _entryRepo = EntryRepo(_db);
    _mediaStore = MediaStore(keyProvider: _keyProvider, mediaRepo: _mediaRepo);
    _thumbnailCache = ThumbnailCache(
      mediaRepo: _mediaRepo,
      keyProvider: _keyProvider,
      db: _db,
    );
  }

  @override
  void dispose() {
    if (_ownsDatabase) {
      _db.close();
    }
    super.dispose();
  }

  Future<void> _insertDemoMedia() async {
    setState(() {
      _statusText = '正在加载并插入大图...';
    });
    try {
      final entry = await _entryRepo.create(
        contentJson: '{"insert":"demo"}',
        contentPlain: 'demo',
        entryDtUtc: DateTime.now().toUtc(),
        entryTz: 'Etc/UTC',
      );
      final data = await rootBundle.load('assets/editor/demo_image.png');
      final bytes = data.buffer.asUint8List();

      final mediaId = await _mediaStore.put(
        bytes: Stream.value(bytes),
        entryId: entry.id,
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: bytes.length,
      );

      setState(() {
        _mediaId = mediaId;
        _statusText = '大图插入成功，ID: $mediaId';
      });
    } catch (e) {
      setState(() {
        _statusText = '大图插入失败: $e';
      });
    }
  }

  void _requestThumbnail() {
    final id = _mediaId;
    if (id == null) {
      setState(() {
        _statusText = '错误：请先插入 demo 大图';
      });
      return;
    }

    setState(() {
      _statusText = '正在请求缩略图...';
      _thumbImageBytes = null;
    });

    final handle = _thumbnailCache.request(id);
    _currentHandle = handle;

    void checkState() {
      if (mounted && _currentHandle == handle) {
        setState(() {
          _statusText = '缩略图状态: ${handle.state.name}';
        });
      }
    }

    checkState();

    handle.future
        .then((result) {
          checkState();
          setState(() {
            _statusText = '生成成功！宽高: ${result.w}x${result.h}';
          });
        })
        .catchError((err) {
          checkState();
          setState(() {
            _statusText = '生成失败: $err';
          });
        });
  }

  Future<void> _showThumbnail() async {
    final id = _mediaId;
    if (id == null) {
      setState(() {
        _statusText = '错误：无可用 mediaId';
      });
      return;
    }

    setState(() {
      _statusText = '正在读取并解密缩略图...';
    });

    try {
      final media = await _db.mediaDao.byId(id);
      if (media == null || media.thumbPath == null) {
        throw Exception('媒体记录或缩略图字段为空');
      }

      final docsDir = await applicationDocumentsDir();
      final thumbFile = resolveRelPathWithDocumentsDir(
        media.thumbPath!,
        documentsPath: docsDir.path,
      );

      if (!await thumbFile.exists()) {
        throw Exception('缩略图物理文件不存在');
      }

      final encryptedBytes = await thumbFile.readAsBytes();
      final key = await _keyProvider.getDeviceMediaKey();
      final plainBytes = await decryptBytes(encryptedBytes, key);

      setState(() {
        _thumbImageBytes = plainBytes;
        _statusText = '缩略图解密成功，正在渲染';
      });
    } catch (e) {
      setState(() {
        _statusText = '显示缩略图失败: $e';
      });
    }
  }

  Future<void> _bumpUpdatedAt() async {
    final id = _mediaId;
    if (id == null) {
      setState(() {
        _statusText = '错误：无可用 mediaId';
      });
      return;
    }

    try {
      final media = await _db.mediaDao.byId(id);
      if (media == null) {
        throw Exception('媒体记录不存在');
      }

      final bumped = media.copyWith(
        updatedAt: media.updatedAt.add(const Duration(seconds: 5)),
      );
      await _db.mediaDao.updateMedia(bumped.toCompanion(false));

      setState(() {
        _statusText = '原图 updatedAt 已被篡改，现与缩略图不一致';
      });
    } catch (e) {
      setState(() {
        _statusText = '篡改失败: $e';
      });
    }
  }

  void _cancelGeneration() {
    final handle = _currentHandle;
    if (handle == null) {
      setState(() {
        _statusText = '错误：当前无正在进行的任务';
      });
      return;
    }

    handle.cancel();
    setState(() {
      _statusText = '已调用 cancel()，当前状态: ${handle.state.name}';
    });
  }

  Future<void> _warmupTenImages() async {
    setState(() {
      _statusText = '正在预热 10 张大图...';
    });

    try {
      final entry = await _entryRepo.create(
        contentJson: '{"insert":"warmup"}',
        contentPlain: 'warmup',
        entryDtUtc: DateTime.now().toUtc(),
        entryTz: 'Etc/UTC',
      );

      final data = await rootBundle.load('assets/editor/demo_image.png');
      final bytes = data.buffer.asUint8List();

      final ids = <String>[];
      for (var i = 0; i < 10; i++) {
        final mediaId = await _mediaStore.put(
          bytes: Stream.value(bytes),
          entryId: entry.id,
          kind: MediaKind.image,
          mime: 'image/png',
          fileSize: bytes.length,
        );
        ids.add(mediaId);
      }

      _thumbnailCache.warmup(ids);

      setState(() {
        _statusText = '已发起 warmup(10 张)';
      });
    } catch (e) {
      setState(() {
        _statusText = '预热失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thumbnails Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '状态板',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('当前 mediaId: ${_mediaId ?? "无"}'),
                    const SizedBox(height: 4),
                    Text(
                      '系统消息: $_statusText',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _insertDemoMedia,
              child: const Text('插入 demo 大图'),
            ),
            ElevatedButton(
              onPressed: _requestThumbnail,
              child: const Text('生成缩略图 (request)'),
            ),
            ElevatedButton(
              onPressed: _showThumbnail,
              child: const Text('显示缩略图 (解密渲染)'),
            ),
            ElevatedButton(
              onPressed: _bumpUpdatedAt,
              child: const Text('篡改原图 updated_at'),
            ),
            ElevatedButton(
              onPressed: _cancelGeneration,
              child: const Text('取消生成 (cancel)'),
            ),
            ElevatedButton(
              onPressed: _warmupTenImages,
              child: const Text('批量预热 10 张 (warmup)'),
            ),
            const SizedBox(height: 16),
            const Text('缩略图预览:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: _thumbImageBytes != null
                  ? Image.memory(_thumbImageBytes!)
                  : const Center(child: Text('无图片')),
            ),
          ],
        ),
      ),
    );
  }
}
