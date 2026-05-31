// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:dayz/ui/reader/reader_image.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_thumbnail_cache.dart';

/// Reader image async thumbnail behavior tests.
///
/// Author: @Ray
void main() {
  testWidgets(
    'renders placeholder and enqueues warmup while thumbnail is not ready',
    (tester) async {
      final cache = FakeReaderThumbnailCache();

      await tester.pumpWidget(_app(cache: cache));

      final placeholder = tester.widget<ColoredBox>(
        find.byKey(const ValueKey('reader-image-placeholder')),
      );
      expect(placeholder.color, DayzColors.purpleLight.accentSoft2);
      expect(cache.warmupCalls, [
        ['media-1'],
      ]);
      expect(cache.synchronousRebuildCalls, 0);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets('renders the ready handle provider', (tester) async {
    final cache = FakeReaderThumbnailCache();
    final provider = MemoryImage(Uint8List.fromList(_transparentPixelPng));
    cache.handles['media-1'] = FakeReaderThumbnailHandle.ready(provider);

    await tester.pumpWidget(_app(cache: cache));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, same(provider));
    expect(
      find.byKey(const ValueKey('reader-image-placeholder')),
      findsNothing,
    );
  });

  testWidgets('uses zero fade duration when animations are disabled', (
    tester,
  ) async {
    final cache = FakeReaderThumbnailCache();
    final provider = MemoryImage(Uint8List.fromList(_transparentPixelPng));
    cache.handles['media-1'] = FakeReaderThumbnailHandle.ready(provider);

    await tester.pumpWidget(
      _app(
        cache: cache,
        mediaQueryData: const MediaQueryData(disableAnimations: true),
      ),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('reader-image-switcher')),
    );
    expect(switcher.duration, Duration.zero);
  });
}

Widget _app({
  required ReaderThumbnailCache cache,
  MediaQueryData mediaQueryData = const MediaQueryData(),
}) {
  return MaterialApp(
    theme: DayzThemes.purpleLight,
    home: MediaQuery(
      data: mediaQueryData,
      child: Scaffold(
        body: ReaderImage(
          mediaId: 'media-1',
          thumbnailCache: cache,
          fit: BoxFit.cover,
        ),
      ),
    ),
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
