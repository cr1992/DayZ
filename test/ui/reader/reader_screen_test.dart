// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_repos.dart';

void main() {
  testWidgets('renders loaded reader sections in prototype order', (
    tester,
  ) async {
    await tester.pumpWidget(_readerApp(data: _defaultData()));
    await tester.pump();

    final sectionKeys = [
      ReaderScreen.heroKey,
      ReaderScreen.kickerKey,
      ReaderScreen.titleKey,
      ReaderScreen.metaKey,
      ReaderScreen.bodyKey,
      ReaderScreen.galleryKey,
      ReaderScreen.tagsKey,
    ];

    for (final key in sectionKeys) {
      expect(find.byKey(key), findsOneWidget);
    }

    final tops = [
      for (final key in sectionKeys) tester.getTopLeft(find.byKey(key)).dy,
    ];
    expect(tops, orderedEquals(tops.toList()..sort()));
  });

  testWidgets('folds optional media and metadata for text-only entries', (
    tester,
  ) async {
    await tester.pumpWidget(_readerApp(data: _textOnlyData()));
    await tester.pump();

    expect(find.byKey(ReaderScreen.heroKey), findsNothing);
    expect(find.byKey(ReaderScreen.metaKey), findsNothing);
    expect(find.byKey(ReaderScreen.galleryKey), findsNothing);
    expect(find.byKey(ReaderScreen.tagsKey), findsNothing);
    expect(find.byKey(ReaderScreen.bodyKey), findsOneWidget);
  });

  testWidgets('renders not-found state with localized empty copy', (
    tester,
  ) async {
    await tester.pumpWidget(_readerApp(data: null));
    await tester.pump();

    expect(find.text(testL10n.readerEmptyTitle), findsOneWidget);
    expect(find.text(testL10n.readerEmptyDescription), findsOneWidget);
  });

  testWidgets('favorite star toggles through controller and toast', (
    tester,
  ) async {
    final repo = FakeReaderRepository();

    await tester.pumpWidget(_readerApp(data: _textOnlyData(), repo: repo));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel(testL10n.favorite));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(repo.favoriteUpdates, [(id: 'entry-1', isFavorite: true)]);
    expect(find.text(testL10n.readerToastFavoriteAdded), findsOneWidget);
    expect(find.bySemanticsLabel(testL10n.unfavorite), findsOneWidget);
  });

  testWidgets('more button opens ordered reader action sheet', (tester) async {
    await tester.pumpWidget(_readerApp(data: _defaultData()));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel(testL10n.readerActionsSemantic));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.readerActionEdit), findsOneWidget);
    expect(find.text(testL10n.readerActionShare), findsOneWidget);
    expect(find.text(testL10n.readerActionMoveToJournal), findsOneWidget);
    expect(find.text(testL10n.readerActionFavorite), findsOneWidget);
    expect(find.text(testL10n.readerActionDelete), findsOneWidget);
  });

  testWidgets('gallery more tile expands in place', (tester) async {
    await tester.pumpWidget(_readerApp(data: _defaultData(imageCount: 10)));
    await tester.pump();

    expect(find.text(testL10n.galleryMoreCount(1)), findsOneWidget);

    await tester.ensureVisible(find.text(testL10n.galleryMoreCount(1)));
    await tester.pump();
    await tester.tap(find.text(testL10n.galleryMoreCount(1)));
    await tester.pump();

    expect(find.text(testL10n.galleryMoreCount(1)), findsNothing);
    expect(find.byKey(ReaderScreen.galleryKey), findsOneWidget);
  });
}

Widget _readerApp({required ReaderViewData? data, FakeReaderRepository? repo}) {
  final image = MemoryImage(Uint8List.fromList(_transparentPixelPng));
  return localizedMaterialApp(
    home: ReaderScreen(
      entryId: 'entry-1',
      repository: repo ?? FakeReaderRepository(),
      loadData: (_) async => data,
      imageProviderFor: (_) => image,
    ),
  );
}

ReaderViewData _defaultData({int imageCount = 4}) {
  return ReaderViewData(
    id: 'entry-1',
    dateTimeLocal: DateTime(2026, 5, 31, 21),
    title: '雨后',
    bodyParagraphs: const ['雨后', '院子里有桂花香。'],
    cover: const ReaderMediaViewData(id: 'cover', relPath: 'cover.bin'),
    weather: const ReaderWeatherViewData(
      code: 'sunny',
      label: '晴 23°C',
      temperatureCelsius: 23,
    ),
    place: '杭州',
    mood: '平静',
    tags: const [
      ReaderTagViewData(id: 'tag-1', name: '生活'),
      ReaderTagViewData(id: 'tag-2', name: '五月'),
    ],
    galleryImages: [
      for (var i = 0; i < imageCount; i += 1)
        ReaderMediaViewData(id: 'image-$i', relPath: 'image-$i.bin'),
    ],
    journalId: 'journal-1',
    favorite: false,
  );
}

ReaderViewData _textOnlyData() {
  return ReaderViewData(
    id: 'entry-1',
    dateTimeLocal: DateTime(2026, 6, 1, 9),
    title: '只写文字',
    bodyParagraphs: const ['只写文字', '今天没有拍照。'],
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
