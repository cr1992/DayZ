// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/thumbnails/cancel_token.dart';
import 'package:dayz/thumbnails/thumbnail_handle.dart';
import 'package:dayz/thumbnails/thumbnail_image_provider.dart';
import 'package:dayz/ui/reader/reader_image.dart';
import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/theme_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_repos.dart';

/// 可控缩略图请求方：handle 由测试决定何时就绪。
class _FakeRequester {
  final Map<String, ThumbnailHandle> handles = {};

  ThumbnailHandle request(
    String mediaId, {
    ThumbnailPriority priority = ThumbnailPriority.normal,
  }) {
    return handles.putIfAbsent(
      mediaId,
      () => ThumbnailHandle(cancelToken: CancelToken()),
    );
  }

  void complete(String mediaId) {
    handles[mediaId]!.complete(
      ThumbnailResult(relPath: 'thumbs/$mediaId.bin', w: 4, h: 3),
    );
  }
}

/// reader-screen S1：阅读屏封面 / 相册接解密图源。
///
/// Author: @Ray
void main() {
  group('ThumbnailCacheReaderAdapter', () {
    late Directory docs;

    setUp(() async {
      docs = await Directory.systemTemp.createTemp('dayz_reader_thumb_test');
    });

    tearDown(() async {
      imageCache.clear();
      if (await docs.exists()) {
        await docs.delete(recursive: true);
      }
    });

    ThumbnailImageLoader loaderFor(_FakeRequester requester) {
      return ThumbnailImageLoader(
        request: requester.request,
        loadDeviceMediaKey: () async => Uint8List(32),
        documentsDirectoryProvider: () async => docs,
        // 假图源：落盘即明文 PNG，「解密」原样返回（同 isolate，避开真 isolate）。
        decrypt: (cipher, key) async => cipher,
      );
    }

    testWidgets('ready thumbnail renders a decoded frame via providerFor', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final file = File('${docs.path}/thumbs/m1.bin');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
          img.encodePng(img.Image(width: 4, height: 3)),
        );
      });
      final requester = _FakeRequester();
      final loader = loaderFor(requester);
      final adapter = ThumbnailCacheReaderAdapter(
        request: requester.request,
        images: loader,
      );

      await tester.pumpWidget(
        localizedTestApp(
          child: Center(
            child: SizedBox(
              width: 120,
              height: 90,
              child: ReaderImage(mediaId: 'm1', thumbnailCache: adapter),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('reader-image-placeholder')),
        findsOneWidget,
      );

      requester.complete('m1');
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ThumbnailImageProvider>());
      final provider = image.image as ThumbnailImageProvider;
      expect(provider.mediaId, 'm1');
      expect(identical(provider.loader, loader), isTrue);

      final raw = tester.widget<RawImage>(find.byType(RawImage));
      expect(raw.image, isNotNull);
      expect((raw.image!.width, raw.image!.height), (4, 3));
      expect(tester.takeException(), isNull);
    });

    test('adapters over the same requester and loader are equal', () {
      final requester = _FakeRequester();
      final loader = loaderFor(requester);
      final a = ThumbnailCacheReaderAdapter(
        request: requester.request,
        images: loader,
      );
      final b = ThumbnailCacheReaderAdapter(
        request: requester.request,
        images: loader,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          equals(
            ThumbnailCacheReaderAdapter(
              request: requester.request,
              images: loaderFor(requester),
            ),
          ),
        ),
      );
    });
  });

  group('reader route', () {
    late ThemeController themeController;

    setUp(() {
      themeController = ThemeController();
      registerReaderRepository(
        FakeReaderRepository(
          entries: {
            'entry-1': ReaderEntryRecord(
              id: 'entry-1',
              journalId: null,
              contentPlain: '雨后的院子\n木桌上还留着水印。',
              contentJson: '{}',
              entryDtUtc: DateTime.utc(2026, 5, 31, 13, 18),
              entryTz: 'Asia/Shanghai',
              isFavorite: false,
            ),
          },
        ),
      );
    });

    tearDown(() {
      registerReaderRepository(null);
      themeController.dispose();
      appRouter.go(Routes.timelinePath);
    });

    Widget routerApp() => localizedRouterTestApp(
      routerConfig: appRouter,
      builder: (context, child) => ThemeControllerScope(
        controller: themeController,
        child: child ?? const SizedBox.shrink(),
      ),
    );

    testWidgets('injects the composition-root decrypting image source', (
      tester,
    ) async {
      final services = AppServices.forDatabase(
        AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(() => tester.runAsync(services.close));

      appRouter.go(Routes.readerPath, extra: 'entry-1');
      await tester.pumpWidget(
        AppServicesScope(services: services, child: routerApp()),
      );
      await tester.pumpAndSettle();

      final screen = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
      expect(
        screen.thumbnailCache,
        ThumbnailCacheReaderAdapter(
          request: services.thumbnailCache.request,
          images: services.thumbnailImages,
        ),
      );
      final provider = screen.imageProviderFor!(
        const ReaderMediaViewData(id: 'm9', relPath: 'media/m9.bin'),
      );
      expect(provider, isA<ThumbnailImageProvider>());
      expect((provider as ThumbnailImageProvider).mediaId, 'm9');
      expect(identical(provider.loader, services.thumbnailImages), isTrue);
    });

    testWidgets('without a composition root the reader keeps placeholders', (
      tester,
    ) async {
      appRouter.go(Routes.readerPath, extra: 'entry-1');
      await tester.pumpWidget(routerApp());
      await tester.pumpAndSettle();

      final screen = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
      expect(screen.thumbnailCache, isNull);
      expect(screen.imageProviderFor, isNull);
    });
  });
}
