// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/router_ports.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/thumbnails/generator.dart';
import 'package:dayz/thumbnails/thumbnail_image_provider.dart';
import 'package:dayz/ui/onthisday/onthisday_controller.dart';

final Uint8List _deviceKey = Uint8List.fromList(List.generate(32, (i) => i));

class _StaticKeyProvider extends KeyProvider {
  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(_deviceKey);
}

void main() {
  late Directory docs;
  late AppServices services;

  setUpAll(initTimezoneData);

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('dayz_thumb_wiring_test');
    services = AppServices.forDatabase(
      AppDatabase(NativeDatabase.memory()),
      keyProvider: _StaticKeyProvider(),
      documentsDirectoryProvider: () async => docs,
    );
    bindRouterPorts(services);
  });

  tearDown(() async {
    unbindRouterPorts();
    await services.close();
    if (await docs.exists()) {
      await docs.delete(recursive: true);
    }
  });

  /// 写一条两年前今天的条目；[withImage] 时再挂一张设备密钥加密的 800×600 原图。
  Future<(String entryId, String? mediaId)> addPastEntry(
    String text, {
    required bool withImage,
  }) async {
    final entry = await services.entries.create(
      contentJson: '{}',
      contentPlain: text,
      entryDtUtc: DateTime.utc(2024, 10, 10, 12),
      entryTz: 'Etc/UTC',
    );
    if (!withImage) {
      return (entry.id, null);
    }
    final mediaId = 'media-${entry.id}';
    await MediaRepo(
      services.database,
    ).addMeta(mediaId, entry.id, 'image', 'media/$mediaId.bin');
    final image = img.Image(width: 800, height: 600);
    final src = File('${docs.path}/media/$mediaId.bin');
    await src.parent.create(recursive: true);
    await src.writeAsBytes(
      await encryptBytes(Uint8List.fromList(img.encodeJpg(image)), _deviceKey),
    );
    return (entry.id, mediaId);
  }

  test('bind 注册往年今日缩略图端口，unbind 一并清空', () {
    expect(onThisDayRepositoryPort, isNotNull);
    expect(onThisDayThumbnailsPort, isNotNull);

    unbindRouterPorts();

    expect(onThisDayRepositoryPort, isNull);
    expect(onThisDayThumbnailsPort, isNull);
  });

  test('端口图源能解出该媒体的缩略图（设备媒体密钥）', () async {
    final (_, mediaId) = await addPastEntry('有图', withImage: true);

    final provider = onThisDayThumbnailsPort!.providerFor(mediaId!);

    expect(provider, isA<ThumbnailImageProvider>());
    final thumb = provider as ThumbnailImageProvider;
    expect(identical(thumb.loader, services.thumbnailImages), isTrue);
    final decoded = img.decodeJpg(await thumb.loader.load(thumb.mediaId));
    expect((decoded!.width, decoded.height), (384, 288));
  });

  test('端口 warmup 经组合根缩略图缓存落库 thumb_path', () async {
    final (_, mediaId) = await addPastEntry('预热', withImage: true);

    onThisDayThumbnailsPort!.warmup([mediaId!]);

    String? thumbPath;
    for (var i = 0; i < 200 && thumbPath == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      thumbPath = (await services.database.mediaDao.byId(mediaId))?.thumbPath;
    }
    expect(thumbPath, 'thumbs/$mediaId.bin');
    expect(File('${docs.path}/$thumbPath').existsSync(), isTrue);
  });

  test('controller 走真实端口：带图条目有解密图源，无图条目为 null', () async {
    final (withImageId, mediaId) = await addPastEntry('有图', withImage: true);
    final (plainId, _) = await addPastEntry('无图', withImage: false);

    final controller = OnThisDayController(
      repository: onThisDayRepositoryPort!,
      thumbnails: onThisDayThumbnailsPort,
      clock: () => DateTime(2026, 10, 10),
    );
    addTearDown(controller.dispose);
    await controller.load();

    final cards = {
      for (final group in controller.data!.groups)
        for (final card in group.entries) card.entryId: card,
    };
    final cover = cards[withImageId]!.coverImage;
    expect(cover, isA<ThumbnailImageProvider>());
    expect((cover! as ThumbnailImageProvider).mediaId, mediaId);
    expect(cards[plainId]!.coverImage, isNull);

    // 等预热 + 解密完成，避免后台任务越过 tearDown 关库。
    await services.thumbnailImages.load(mediaId!);
    expect(services.thumbnailImages.isCached(mediaId), isTrue);
  });
}
