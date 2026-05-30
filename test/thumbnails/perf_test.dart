@Timeout(Duration(seconds: 120))
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/thumbnails/generator.dart';
import 'package:dayz/thumbnails/thumbnail_cache.dart';

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
    tempDir = await Directory.systemTemp.createTemp('dayz_perf_test');

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

  test('Benchmark - generate 10 thumbnails consecutively', () async {
    // 1. 生成 3 张原图
    final count = 3;
    final entry = await entryRepo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30),
      entryTz: 'UTC',
    );

    // 预先构造一张 300x200 的图片字节
    final srcImage = img.Image(width: 300, height: 200);
    for (var pixel in srcImage) {
      pixel.r = 180;
      pixel.g = 180;
      pixel.b = 180;
    }
    final rawSrcJpg = Uint8List.fromList(img.encodeJpg(srcImage));
    final encryptedSrcBytes = await encryptBytes(rawSrcJpg, deviceMediaKey);

    for (var i = 0; i < count; i++) {
      final mediaId = 'perf_media_$i';
      await mediaRepo.addMeta(
        mediaId,
        entry.id,
        'image',
        'media/$mediaId.bin',
        width: 300,
        height: 200,
      );

      final file = File('${tempDir.path}/media/$mediaId.bin');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(encryptedSrcBytes);
    }

    // 2. 开始测试耗时
    final stopwatch = Stopwatch()..start();

    final handles = List.generate(count, (i) => cache.request('perf_media_$i'));
    await Future.wait(handles.map((h) => h.future));

    stopwatch.stop();

    final totalMs = stopwatch.elapsedMilliseconds;
    final averageMs = totalMs / count;

    debugPrint('================== BENCHMARK ==================');
    debugPrint('Total time for $count images: ${totalMs}ms');
    debugPrint('Average time per image: ${averageMs}ms');
    debugPrint('===============================================');

    // 性能基线测试：平均生成时间必须小于 200ms
    // 在中端真机及单元测试的 CI 机器上都应快速通过
    expect(averageMs, lessThan(200));
  });
}
