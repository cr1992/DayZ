// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/media/exceptions.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/thumbnails/cancel_token.dart';
import 'package:dayz/thumbnails/generator.dart';
import 'package:dayz/thumbnails/thumbnail_cache.dart';
import 'package:dayz/thumbnails/thumbnail_handle.dart';
import 'package:dayz/thumbnails/thumbnail_image_provider.dart';

final Uint8List _deviceKey = Uint8List.fromList(List.generate(32, (i) => i));
final Uint8List _wrongKey = Uint8List.fromList(
  List.generate(32, (i) => 255 - i),
);

class _StaticKeyProvider extends KeyProvider {
  _StaticKeyProvider(this._key);

  final Uint8List _key;

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(_key);
}

/// 可控的缩略图请求方：记录每次调用，按需立即或稍后完成 handle。
class _FakeThumbnails {
  _FakeThumbnails({this.autoComplete = true});

  final bool autoComplete;
  final List<(String, ThumbnailPriority)> calls = [];
  final Map<String, ThumbnailHandle> handles = {};
  final Set<String> failing = {};

  ThumbnailHandle request(
    String mediaId, {
    ThumbnailPriority priority = ThumbnailPriority.normal,
  }) {
    calls.add((mediaId, priority));
    final handle = ThumbnailHandle(cancelToken: CancelToken());
    handles[mediaId] = handle;
    if (failing.contains(mediaId)) {
      handle.completeError(ThumbnailGenerationException('boom'));
    } else if (autoComplete) {
      complete(mediaId);
    }
    return handle;
  }

  void complete(String mediaId) {
    handles[mediaId]!.complete(
      ThumbnailResult(relPath: 'thumbs/$mediaId.bin', w: 4, h: 3),
    );
  }

  int normalCalls(String mediaId) => calls
      .where((c) => c.$1 == mediaId && c.$2 == ThumbnailPriority.normal)
      .length;
}

Uint8List _jpeg({int width = 4, int height = 3, bool noisy = false}) {
  final image = img.Image(width: width, height: height);
  var seed = 7;
  for (final pixel in image) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    pixel
      ..r = noisy ? seed & 0xff : 120
      ..g = noisy ? (seed >> 8) & 0xff : 160
      ..b = noisy ? (seed >> 16) & 0xff : 200;
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

Future<void> _writeEncryptedThumb(
  Directory docs,
  String mediaId,
  Uint8List plain,
) async {
  final file = File('${docs.path}/thumbs/$mediaId.bin');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(await encryptBytes(plain, _deviceKey));
}

/// 同 isolate 解密并统计次数（widget test 里避开真 isolate）。
class _CountingDecryptor {
  int calls = 0;

  Future<Uint8List> call(Uint8List cipher, Uint8List key) {
    calls++;
    return decryptBytes(cipher, key);
  }
}

void main() {
  late Directory docs;

  setUpAll(initTimezoneData);

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('dayz_thumb_provider_test');
  });

  tearDown(() async {
    if (await docs.exists()) {
      await docs.delete(recursive: true);
    }
  });

  ThumbnailImageLoader loaderFor(
    _FakeThumbnails fake, {
    Uint8List? key,
    ThumbnailDecryptor? decrypt,
    int maxEntries = ThumbnailImageLoader.defaultMaxEntries,
    int maxBytes = ThumbnailImageLoader.defaultMaxBytes,
  }) {
    return ThumbnailImageLoader(
      request: fake.request,
      loadDeviceMediaKey: () async => Uint8List.fromList(key ?? _deviceKey),
      documentsDirectoryProvider: () async => docs,
      decrypt: decrypt,
      maxEntries: maxEntries,
      maxBytes: maxBytes,
    );
  }

  group('R1 解密取图（端到端，真 ThumbnailCache + 默认 isolate 解密）', () {
    test('load 返回可解码的明文 JPEG，尺寸等于缩略图尺寸', () async {
      disableIsolateForTesting = true;
      addTearDown(() => disableIsolateForTesting = false);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final entryRepo = EntryRepo(db);
      final mediaRepo = MediaRepo(db);
      final entry = await entryRepo.create(
        contentJson: '{}',
        contentPlain: 'x',
        entryDtUtc: DateTime.utc(2026, 5, 30),
        entryTz: 'Etc/UTC',
      );
      await mediaRepo.addMeta('m1', entry.id, 'image', 'media/m1.bin');
      final src = File('${docs.path}/media/m1.bin');
      await src.parent.create(recursive: true);
      await src.writeAsBytes(
        await encryptBytes(_jpeg(width: 800, height: 400), _deviceKey),
      );

      final keyProvider = _StaticKeyProvider(_deviceKey);
      final cache = ThumbnailCache(
        mediaRepo: mediaRepo,
        keyProvider: keyProvider,
        db: db,
        documentsDirectoryProvider: () async => docs,
      );
      final loader = ThumbnailImageLoader(
        request: cache.request,
        loadDeviceMediaKey: keyProvider.getDeviceMediaKey,
        documentsDirectoryProvider: () async => docs,
      );

      final bytes = await loader.load('m1');
      final decoded = img.decodeJpg(bytes);
      expect(decoded, isNotNull);
      expect((decoded!.width, decoded.height), (384, 192));
      // 磁盘上仍是密文：不以 JPEG SOI 开头。
      final onDisk = await File('${docs.path}/thumbs/m1.bin').readAsBytes();
      expect(onDisk.take(2).toList(), isNot([0xFF, 0xD8]));
      expect(loader.isCached('m1'), isTrue);
    });
  });

  group('R2 未就绪占位 / 不同步解码', () {
    test('providerFor 只构造图源，不触发请求或 IO', () {
      final fake = _FakeThumbnails();
      final loader = loaderFor(fake);

      final a = loader.providerFor('m1');
      final b = loader.providerFor('m1');

      expect(fake.calls, isEmpty);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(loader.providerFor('m2'))));
      expect(a, isNot(equals(loaderFor(fake).providerFor('m1'))));
    });

    testWidgets('缩略图就绪前 Image 无帧（占位），就绪后异步出帧', (tester) async {
      final plain = _jpeg();
      await tester.runAsync(() => _writeEncryptedThumb(docs, 'm1', plain));
      final fake = _FakeThumbnails(autoComplete: false);
      final decrypt = _CountingDecryptor();
      final loader = loaderFor(fake, decrypt: decrypt.call);
      final provider = loader.providerFor('m1');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Image(
            image: provider,
            frameBuilder: (context, child, frame, _) => frame == null
                ? const SizedBox(key: ValueKey('placeholder'))
                : child,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);
      expect(fake.normalCalls('m1'), 1);
      expect(decrypt.calls, 0);

      fake.complete('m1');
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }

      expect(find.byKey(const ValueKey('placeholder')), findsNothing);
      expect(decrypt.calls, 1);
      final element = tester.element(find.byType(RawImage));
      final raw = element.widget as RawImage;
      expect((raw.image!.width, raw.image!.height), (4, 3));
      imageCache.clear();
    });
  });

  group('R3 LRU 上限', () {
    test('超过条数上限淘汰最久未用；命中会刷新新近度', () async {
      final fake = _FakeThumbnails();
      for (final id in ['a', 'b', 'c']) {
        await _writeEncryptedThumb(docs, id, _jpeg());
      }
      final decrypt = _CountingDecryptor();
      final loader = loaderFor(fake, decrypt: decrypt.call, maxEntries: 2);

      await loader.load('a');
      await loader.load('b');
      await loader.load('a'); // 命中，a 变为最近使用
      await loader.load('c'); // 淘汰 b

      expect(loader.cachedCount, 2);
      expect(loader.isCached('a'), isTrue);
      expect(loader.isCached('b'), isFalse);
      expect(loader.isCached('c'), isTrue);
      expect(fake.normalCalls('a'), 1);
      expect(decrypt.calls, 3);

      await loader.load('b');
      expect(fake.normalCalls('b'), 2);
      expect(loader.isCached('a'), isFalse);
    });

    test('超过字节上限按 LRU 淘汰；单张超上限不入缓存', () async {
      final fake = _FakeThumbnails();
      final small = _jpeg();
      final big = _jpeg(width: 64, height: 64, noisy: true);
      await _writeEncryptedThumb(docs, 's1', small);
      await _writeEncryptedThumb(docs, 's2', small);
      await _writeEncryptedThumb(docs, 'big', big);
      final cap = small.length * 2;
      expect(big.length, greaterThan(cap));
      final loader = loaderFor(fake, maxBytes: cap + small.length ~/ 2);

      await loader.load('s1');
      await loader.load('s2');
      expect(loader.cachedBytes, small.length * 2);
      expect(loader.cachedBytes, lessThanOrEqualTo(loader.maxBytes));

      final bigBytes = await loader.load('big');
      expect(bigBytes, big);
      expect(loader.isCached('big'), isFalse);
      expect(loader.cachedCount, 2);

      loader.evict('s1');
      expect(loader.cachedBytes, small.length);
      loader.clear();
      expect((loader.cachedCount, loader.cachedBytes), (0, 0));
    });

    test('同一 id 并发请求只请求、解密一次', () async {
      final fake = _FakeThumbnails(autoComplete: false);
      await _writeEncryptedThumb(docs, 'm1', _jpeg());
      final decrypt = _CountingDecryptor();
      final loader = loaderFor(fake, decrypt: decrypt.call);

      final first = loader.load('m1');
      final second = loader.load('m1');
      await Future<void>.delayed(Duration.zero);
      fake.complete('m1');
      final results = await Future.wait([first, second]);

      expect(results[0], results[1]);
      expect(fake.normalCalls('m1'), 1);
      expect(decrypt.calls, 1);
    });
  });

  group('R4 失败路径', () {
    test('错密钥解密失败抛 MediaCorruptedException，不缓存，可重试', () async {
      final fake = _FakeThumbnails();
      await _writeEncryptedThumb(docs, 'm1', _jpeg());
      final loader = loaderFor(fake, key: _wrongKey);

      await expectLater(
        loader.load('m1'),
        throwsA(isA<MediaCorruptedException>()),
      );
      expect(loader.isCached('m1'), isFalse);

      await expectLater(
        loader.load('m1'),
        throwsA(isA<MediaCorruptedException>()),
      );
      expect(fake.normalCalls('m1'), 2);
    });

    test('缩略图生成失败原样透出，不缓存', () async {
      final fake = _FakeThumbnails()..failing.add('m1');
      final loader = loaderFor(fake);

      await expectLater(
        loader.load('m1'),
        throwsA(isA<ThumbnailGenerationException>()),
      );
      expect(loader.isCached('m1'), isFalse);
    });

    testWidgets('错密钥时 Image 走 errorBuilder 兜底', (tester) async {
      await tester.runAsync(() => _writeEncryptedThumb(docs, 'm1', _jpeg()));
      final fake = _FakeThumbnails();
      final loader = loaderFor(
        fake,
        key: _wrongKey,
        decrypt: _CountingDecryptor().call,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Image(
            image: loader.providerFor('m1'),
            errorBuilder: (context, error, _) => Text(
              error.runtimeType.toString(),
              key: const ValueKey('error'),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }

      expect(find.byKey(const ValueKey('error')), findsOneWidget);
      expect(find.text('MediaCorruptedException'), findsOneWidget);
      imageCache.clear();
    });

    test('warmup 走 low 优先级且吞掉失败，不抛到调用方', () async {
      final fake = _FakeThumbnails()..failing.add('bad');

      loaderFor(fake).warmup(['ok', 'bad']);
      await Future<void>.delayed(Duration.zero);

      expect(fake.calls, [
        ('ok', ThumbnailPriority.low),
        ('bad', ThumbnailPriority.low),
      ]);
    });
  });
}
