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
import 'package:dayz/thumbnails/generator.dart';

class FailureMediaRepo extends MediaRepo {
  FailureMediaRepo(super.db);

  @override
  Future<MediaData> updateThumb(
    String id, {
    String? thumbPath,
    int? w,
    int? h,
    DateTime? srcUpdatedAt,
  }) async {
    throw Exception('Database transaction failed on purpose');
  }
}

void main() {
  late AppDatabase db;
  late EntryRepo entryRepo;
  late MediaRepo mediaRepo;
  late Directory tempDir;
  final deviceMediaKey = Uint8List.fromList(List.generate(32, (i) => i));

  setUpAll(() async {
    initTimezoneData();
    disableIsolateForTesting = true;
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    entryRepo = EntryRepo(db);
    mediaRepo = MediaRepo(db);
    tempDir = await Directory.systemTemp.createTemp('dayz_thumb_test');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Generator - successfully decode, resize, encode, encrypt and save', () async {
    // 1. 模拟 Entry 和 Media
    final entry = await entryRepo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30),
      entryTz: 'UTC',
    );

    final media = await mediaRepo.addMeta(
      'media_1',
      entry.id,
      'image',
      'media/media_1.bin',
      width: 1500,
      height: 1000,
    );

    // 2. 构造 1500x1000 原图并用 deviceMediaKey 加密
    final srcImage = img.Image(width: 1500, height: 1000);
    // 给图像涂些颜色，确保能解码
    for (var pixel in srcImage) {
      pixel.r = 100;
      pixel.g = 150;
      pixel.b = 200;
    }
    final rawSrcJpg = Uint8List.fromList(img.encodeJpg(srcImage));
    final encryptedSrcBytes = await encryptBytes(rawSrcJpg, deviceMediaKey);

    final targetFile = File('${tempDir.path}/thumbs/media_1.bin');

    // 3. 运行生成器
    final result = await generateThumbnail(
      mediaId: media.id,
      encryptedSrcBytes: encryptedSrcBytes,
      deviceMediaKey: deviceMediaKey,
      targetFile: targetFile,
      mediaRepo: mediaRepo,
      originalMedia: media,
      db: db,
    );

    // 4. 断言结果
    expect(result.relPath, equals('thumbs/media_1.bin'));
    expect(result.w, equals(384));
    expect(result.h, equals(256)); // 1500x1000 => 384x256

    // 5. 验证物理文件确实落盘且可解密解码
    expect(await targetFile.exists(), isTrue);
    final encryptedThumbBytes = await targetFile.readAsBytes();
    final decryptedThumbBytes = await decryptBytes(encryptedThumbBytes, deviceMediaKey);
    final decodedThumbImage = img.decodeJpg(decryptedThumbBytes);
    expect(decodedThumbImage, isNotNull);
    expect(decodedThumbImage!.width, equals(384));
    expect(decodedThumbImage.height, equals(256));

    // 6. 验证 db 写入
    final updatedMedia = await db.mediaDao.byId(media.id);
    expect(updatedMedia, isNotNull);
    expect(updatedMedia!.thumbPath, equals('thumbs/media_1.bin'));
    expect(updatedMedia.thumbW, equals(384));
    expect(updatedMedia.thumbH, equals(256));
    // 验证 R3/R4 缓存命中条件：thumbSrcUpdatedAt == updatedAt
    expect(updatedMedia.thumbSrcUpdatedAt, equals(updatedMedia.updatedAt));
  });

  test('Generator - throws ThumbnailGenerationException on corrupt data', () async {
    final entry = await entryRepo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30),
      entryTz: 'UTC',
    );

    final media = await mediaRepo.addMeta(
      'media_2',
      entry.id,
      'image',
      'media/media_2.bin',
    );

    // 提供一些损坏的随机加密字节，无法解密/解码
    final corruptBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final targetFile = File('${tempDir.path}/thumbs/media_2.bin');

    expect(
      () => generateThumbnail(
        mediaId: media.id,
        encryptedSrcBytes: corruptBytes,
        deviceMediaKey: deviceMediaKey,
        targetFile: targetFile,
        mediaRepo: mediaRepo,
        originalMedia: media,
        db: db,
      ),
      throwsA(isA<ThumbnailGenerationException>()),
    );

    expect(await targetFile.exists(), isFalse);
  });

  test('Generator - db transaction failure deletes written file', () async {
    final entry = await entryRepo.create(
      contentJson: '{"insert":"hello"}',
      contentPlain: 'hello',
      entryDtUtc: DateTime.utc(2026, 5, 30),
      entryTz: 'UTC',
    );

    final media = await mediaRepo.addMeta(
      'media_3',
      entry.id,
      'image',
      'media/media_3.bin',
      width: 1500,
      height: 1000,
    );

    final srcImage = img.Image(width: 1500, height: 1000);
    final rawSrcJpg = Uint8List.fromList(img.encodeJpg(srcImage));
    final encryptedSrcBytes = await encryptBytes(rawSrcJpg, deviceMediaKey);

    final targetFile = File('${tempDir.path}/thumbs/media_3.bin');
    final failureMediaRepo = FailureMediaRepo(db);

    expect(
      () => generateThumbnail(
        mediaId: media.id,
        encryptedSrcBytes: encryptedSrcBytes,
        deviceMediaKey: deviceMediaKey,
        targetFile: targetFile,
        mediaRepo: failureMediaRepo,
        originalMedia: media,
        db: db,
      ),
      throwsA(isA<ThumbnailGenerationException>()),
    );

    // 补偿机制：即使物理文件已经 rename 为 targetFile.path，但由于 db 写入失败，它也应该被删除
    expect(await targetFile.exists(), isFalse);

    // 验证 db 未被更新
    final dbMedia = await db.mediaDao.byId(media.id);
    expect(dbMedia, isNotNull);
    expect(dbMedia!.thumbPath, isNull);
  });
}
