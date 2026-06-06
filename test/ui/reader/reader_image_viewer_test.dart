// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_repos.dart';
import 'fakes/fake_thumbnail_cache.dart';

/// Reader content-image viewer wiring tests.
///
/// Author: @Ray
void main() {
  testWidgets('cover opens DayzImageViewer at the cover index', (tester) async {
    final data = _readerData();
    final providers = _imageProvidersFor(data);
    final thumbnailCache = FakeReaderThumbnailCache();
    final loadCalls = <String>[];

    await tester.pumpWidget(
      _readerApp(
        data: data,
        providers: providers,
        loadCalls: loadCalls,
        thumbnailCache: thumbnailCache,
      ),
    );
    await tester.pump();
    final warmupCallsBeforeViewer = List<List<String>>.from(
      thumbnailCache.warmupCalls,
    );

    await tester.tap(find.byKey(ReaderScreen.heroKey));
    await tester.pumpAndSettle();

    final viewerFinder = find.byType(DayzImageViewer);
    expect(viewerFinder, findsOneWidget);
    final viewer = tester.widget<DayzImageViewer>(viewerFinder);
    expect(viewer.initialIndex, 0);
    expect(viewer.images, hasLength(3));
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dayz-image-viewer-close')));
    await tester.pumpAndSettle();

    expect(find.byType(DayzImageViewer), findsNothing);
    expect(find.byKey(ReaderScreen.titleKey), findsOneWidget);
    expect(loadCalls, <String>['entry-1']);
    expect(thumbnailCache.warmupCalls, warmupCallsBeforeViewer);
    expect(thumbnailCache.synchronousRebuildCalls, 0);
  });

  testWidgets('gallery image opens with the cover offset in the viewer group', (
    tester,
  ) async {
    final data = _readerData();
    final providers = _imageProvidersFor(data);
    final loadCalls = <String>[];

    await tester.pumpWidget(
      _readerApp(data: data, providers: providers, loadCalls: loadCalls),
    );
    await tester.pump();

    final secondGalleryImage = _imageFor(providers['gallery-2']!);
    await tester.ensureVisible(secondGalleryImage);
    await tester.pump();
    await tester.tap(secondGalleryImage);
    await tester.pumpAndSettle();

    final viewerFinder = find.byType(DayzImageViewer);
    expect(viewerFinder, findsOneWidget);
    final viewer = tester.widget<DayzImageViewer>(viewerFinder);
    expect(viewer.initialIndex, 2);
    expect(viewer.images, hasLength(3));
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dayz-image-viewer-close')));
    await tester.pumpAndSettle();

    expect(find.byType(DayzImageViewer), findsNothing);
    expect(find.byKey(ReaderScreen.titleKey), findsOneWidget);
    expect(loadCalls, <String>['entry-1']);
  });

  testWidgets('reader screen does not render source card image entries', (
    tester,
  ) async {
    final data = _readerData();
    final providers = _imageProvidersFor(data);

    await tester.pumpWidget(_readerApp(data: data, providers: providers));
    await tester.pump();

    expect(find.byType(DayzEntryCard), findsNothing);
  });
}

Widget _readerApp({
  required ReaderViewData data,
  required Map<String, ImageProvider> providers,
  List<String>? loadCalls,
  FakeReaderThumbnailCache? thumbnailCache,
}) {
  return localizedMaterialApp(
    home: ReaderScreen(
      entryId: data.id,
      repository: FakeReaderRepository(),
      loadData: (entryId) async {
        loadCalls?.add(entryId);
        return data;
      },
      imageProviderFor: (media) => providers[media.id]!,
      thumbnailCache: thumbnailCache,
    ),
  );
}

Finder _imageFor(ImageProvider provider) {
  return find.byWidgetPredicate(
    (widget) => widget is Image && identical(widget.image, provider),
  );
}

Map<String, ImageProvider> _imageProvidersFor(ReaderViewData data) {
  final providers = <String, ImageProvider>{};
  final cover = data.cover;
  if (cover != null) {
    providers[cover.id] = MemoryImage(Uint8List.fromList(_transparentPixelPng));
  }
  for (final image in data.galleryImages) {
    providers[image.id] = MemoryImage(Uint8List.fromList(_transparentPixelPng));
  }
  return providers;
}

ReaderViewData _readerData() {
  return ReaderViewData(
    id: 'entry-1',
    dateTimeLocal: DateTime(2026, 6, 6, 21),
    title: '夜读',
    bodyParagraphs: const ['灯下看完了最后一页。'],
    cover: const ReaderMediaViewData(id: 'cover', relPath: 'cover.bin'),
    galleryImages: const [
      ReaderMediaViewData(id: 'gallery-1', relPath: 'gallery-1.bin'),
      ReaderMediaViewData(id: 'gallery-2', relPath: 'gallery-2.bin'),
    ],
    journalId: 'journal-1',
    favorite: false,
  );
}

const _transparentPixelPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
