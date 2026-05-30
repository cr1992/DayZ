// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/thumbnails/generator.dart';
import 'package:dayz/thumbnails/thumbnail_cache.dart';
import 'package:dayz/thumbnails/thumbnail_handle.dart';

class MockKeyProvider extends KeyProvider {
  final Uint8List _key;
  MockKeyProvider(this._key);

  @override
  Future<Uint8List> getDeviceMediaKey() async {
    return _key;
  }
}

void main() {
  late AppDatabase db;
  late EntryRepo entryRepo;
  late MediaRepo mediaRepo;
  late MockKeyProvider keyProvider;
  late Directory tempDir;
  late ThumbnailCache cache;

  final deviceMediaKey = Uint8List.fromList(List.generate(32, (i) => i));

  setUpAll(() async {
    initTimezoneData();
    disableIsolateForTesting = true;
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    entryRepo = EntryRepo(db);
    mediaRepo = MediaRepo(db);
    keyProvider = MockKeyProvider(deviceMediaKey);
    tempDir = await Directory.systemTemp.createTemp('dayz_cache_test');

    cache = ThumbnailCache(
      mediaRepo: mediaRepo,
      keyProvider: keyProvider,
      db: db,
      documentsDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // 辅助方法：生成一张加密的原图文件
  Future<MediaData> createMockMedia(String mediaId) async {
    final entry = await entryRepo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30),
      entryTz: 'UTC',
    );

    final media = await mediaRepo.addMeta(
      mediaId,
      entry.id,
      'image',
      'media/$mediaId.bin',
      width: 15,
      height: 10,
    );

    // 构造原图并加密
    final srcImage = img.Image(width: 15, height: 10);
    for (var pixel in srcImage) {
      pixel.r = 200;
      pixel.g = 200;
      pixel.b = 200;
    }
    final rawSrcJpg = Uint8List.fromList(img.encodeJpg(srcImage));
    final encryptedSrcBytes = await encryptBytes(rawSrcJpg, deviceMediaKey);

    final file = File('${tempDir.path}/media/$mediaId.bin');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(encryptedSrcBytes);

    return media;
  }

  test(
    'ThumbnailCache - cache hit and rebuild on out-of-sync timestamp',
    () async {
      await createMockMedia('media_hit_test');

      // 1. 首次生成
      final handle1 = cache.request('media_hit_test');
      expect(handle1.state, equals(ThumbnailState.pending));

      final result1 = await handle1.future;
      expect(result1.relPath, equals('thumbs/media_hit_test.bin'));
      expect(handle1.state, equals(ThumbnailState.ready));

      // 验证 db 写入且一致
      var dbMedia = await db.mediaDao.byId('media_hit_test');
      expect(dbMedia!.thumbPath, isNotNull);
      expect(dbMedia.thumbSrcUpdatedAt, equals(dbMedia.updatedAt));

      // 2. 第二次请求 - 缓存命中 (删除物理原图文件以验证没有重新生成)
      final srcFile = File('${tempDir.path}/media/media_hit_test.bin');
      await srcFile.delete();

      final handle2 = cache.request('media_hit_test');
      final result2 = await handle2.future;
      expect(handle2.state, equals(ThumbnailState.ready));
      expect(result2.relPath, equals('thumbs/media_hit_test.bin'));

      // 3. 时间戳不一致 -> 触发重建 (先把原图恢复)
      await srcFile.writeAsBytes(
        await encryptBytes(Uint8List(100), deviceMediaKey),
      ); // 这里写个假原图，只是用于脏重建
      // 手动 bump db 里的 updatedAt 使之不一致
      final originalUpdatedAt = dbMedia.updatedAt;
      final bumpedMedia = dbMedia.copyWith(
        updatedAt: originalUpdatedAt.add(const Duration(seconds: 5)),
      );
      await db.mediaDao.updateMedia(bumpedMedia.toCompanion(false));

      // 再次 request，应该判定为脏并重建（由于我们写了假原图，重建会因为解码失败报错）
      final handle3 = cache.request('media_hit_test');
      expect(
        () => handle3.future,
        throwsA(isA<ThumbnailGenerationException>()),
      );
    },
  );

  test('ThumbnailCache - duplicate request reuses handle', () async {
    await createMockMedia('media_dup_test');

    final handle1 = cache.request('media_dup_test');
    final handle2 = cache.request('media_dup_test');

    // 两个 handle 应当是同一个实例
    expect(handle1, equals(handle2));

    await handle1.future;
    expect(handle1.state, equals(ThumbnailState.ready));
    expect(handle2.state, equals(ThumbnailState.ready));
  });

  test('ThumbnailCache - cancel pending task and time limit < 100ms', () async {
    // 插入 5 个原图，但不创建物理文件。
    // 这样当 WorkerPool 开始运行时它们都会快速报错或卡在等待，
    // 我们排队后面几个任务并取消，测试取消响应。
    final mediaIds = ['c1', 'c2', 'c3', 'c4'];
    for (final id in mediaIds) {
      await createMockMedia(id);
    }

    // 先启动两个任务占满 slot
    final h1 = cache.request('c1');
    final h2 = cache.request('c2');

    // 提交第三个，进入排队
    final h3 = cache.request('c3');
    expect(h3.state, equals(ThumbnailState.pending));

    // 立即取消 h3
    final stopwatch = Stopwatch()..start();
    h3.cancel();

    expect(h3.state, equals(ThumbnailState.cancelled));
    expect(() => h3.future, throwsA(isA<Exception>()));

    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(100));

    // 等待 h1 和 h2 完成
    await h1.future.catchError((_) => ThumbnailResult(relPath: '', w: 0, h: 0));
    await h2.future.catchError((_) => ThumbnailResult(relPath: '', w: 0, h: 0));
  });

  test(
    'ThumbnailCache - warmup returns immediately and completes in background',
    () async {
      final mediaIds = ['w1', 'w2', 'w3'];
      for (final id in mediaIds) {
        await createMockMedia(id);
      }

      final stopwatch = Stopwatch()..start();
      // warmup 应该同步返回，不阻塞
      cache.warmup(mediaIds);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));

      // 获取对应的 handles 并等待其完成，从而暴露任何后台错误
      final h1 = cache.request('w1');
      final h2 = cache.request('w2');
      final h3 = cache.request('w3');

      await h1.future;
      await h2.future;
      await h3.future;

      // 检查所有缩略图都成功生成了
      for (final id in mediaIds) {
        final dbMedia = await db.mediaDao.byId(id);
        expect(dbMedia!.thumbPath, isNotNull);
      }
    },
  );

  test('ThumbnailCache - API interface strict rule check (R7)', () {
    // 自动扫描守卫：确认 ThumbnailCache 未暴露 rebuildAll / regenerateAllSync / buildAllNow 等接口
    final file = File('lib/thumbnails/thumbnail_cache.dart');
    final content = file.readAsStringSync();
    expect(content.contains('rebuildAll'), isFalse);
    expect(content.contains('regenerateAllSync'), isFalse);
    expect(content.contains('buildAllNow'), isFalse);
  });
}
