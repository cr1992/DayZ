// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

const _readerBoundaryKey = ValueKey<String>(
  'reader-image-viewer-visual-boundary',
);

void main() {
  patrolTest('reader 内容图打开 DayzImageViewer 并横滑翻页', ($) async {
    final data = _readerData();
    final providers = await _imageProvidersFor(data);

    await $.pumpWidget(_ReaderVisualHost(data: data, providers: providers));
    await $.pumpAndSettle();

    final galleryImage = _imageFor(providers['gallery-1']!);
    await $.tester.ensureVisible(galleryImage);
    await $.pumpAndSettle();
    await $.tester.tap(galleryImage);
    await $.pumpAndSettle();

    expect(find.byType(DayzImageViewer), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
    final first = await _writeScreenshot(
      $.tester,
      'reader_image_viewer_page_2',
    );
    $.log('Reader image viewer screenshot: ${first.path}');

    final viewerSize = $.tester.getSize(find.byType(DayzImageViewer));
    await $.tester.dragFrom(
      Offset(viewerSize.width * 0.84, viewerSize.height * 0.52),
      Offset(-viewerSize.width * 0.72, 0),
    );
    await $.pumpAndSettle();

    expect(find.text('3 / 4'), findsOneWidget);
    final second = await _writeScreenshot(
      $.tester,
      'reader_image_viewer_page_3',
    );
    $.log('Reader image viewer screenshot: ${second.path}');

    await $.tester.tap(find.byKey(const ValueKey('dayz-image-viewer-close')));
    await $.pumpAndSettle();

    expect(find.byType(DayzImageViewer), findsNothing);
    expect(find.byKey(ReaderScreen.titleKey), findsOneWidget);
    expect(first.lengthSync(), greaterThan(0));
    expect(second.lengthSync(), greaterThan(0));
  });
}

class _ReaderVisualHost extends StatelessWidget {
  const _ReaderVisualHost({required this.data, required this.providers});

  final ReaderViewData data;
  final Map<String, ImageProvider> providers;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DayzThemes.purpleLight,
      builder: (context, child) {
        return RepaintBoundary(key: _readerBoundaryKey, child: child);
      },
      home: ReaderScreen(
        entryId: data.id,
        repository: _VisualReaderRepository(),
        loadData: (_) async => data,
        imageProviderFor: (media) => providers[media.id]!,
      ),
    );
  }
}

class _VisualReaderRepository implements ReaderRepository {
  @override
  Future<ReaderEntryRecord?> byId(String id) async {
    return null;
  }

  @override
  Future<List<ReaderJournalRecord>> listJournals() async {
    return const <ReaderJournalRecord>[];
  }

  @override
  Future<List<ReaderMediaRecord>> listMedia(String entryId) async {
    return const <ReaderMediaRecord>[];
  }

  @override
  Future<List<ReaderTagRecord>> listTags(String entryId) async {
    return const <ReaderTagRecord>[];
  }

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> updateFavorite(String id, bool isFavorite) async {}

  @override
  Future<void> updateJournal(String id, String? journalId) async {}
}

Finder _imageFor(ImageProvider provider) {
  return find.byWidgetPredicate(
    (widget) => widget is Image && identical(widget.image, provider),
  );
}

Future<Map<String, ImageProvider>> _imageProvidersFor(
  ReaderViewData data,
) async {
  final providers = <String, ImageProvider>{};
  final cover = data.cover;
  if (cover != null) {
    providers[cover.id] = MemoryImage(
      await _pngForColor(const Color(0xFF786CAD)),
    );
  }

  final colors = <Color>[
    const Color(0xFF3D6F76),
    const Color(0xFFD6A23A),
    const Color(0xFF9B6B52),
  ];
  for (var i = 0; i < data.galleryImages.length; i += 1) {
    providers[data.galleryImages[i].id] = MemoryImage(
      await _pngForColor(colors[i % colors.length]),
    );
  }
  return providers;
}

ReaderViewData _readerData() {
  return ReaderViewData(
    id: 'entry-visual',
    dateTimeLocal: DateTime(2026, 6, 6, 20),
    title: '照片里的黄昏',
    bodyParagraphs: const ['在回家的路上停了很久，等光一点点落下来。'],
    cover: const ReaderMediaViewData(id: 'cover', relPath: 'cover.bin'),
    galleryImages: const [
      ReaderMediaViewData(id: 'gallery-1', relPath: 'gallery-1.bin'),
      ReaderMediaViewData(id: 'gallery-2', relPath: 'gallery-2.bin'),
      ReaderMediaViewData(id: 'gallery-3', relPath: 'gallery-3.bin'),
    ],
    journalId: 'journal-visual',
    favorite: false,
  );
}

Future<Uint8List> _pngForColor(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 720, 520), paint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(720, 520);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();

  return bytes!.buffer.asUint8List();
}

Future<File> _writeScreenshot(WidgetTester tester, String name) async {
  await tester.pump();

  final boundary =
      tester.renderObject(find.byKey(_readerBoundaryKey))
          as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  final dir = Directory('${Directory.systemTemp.path}/dayz-patrol-screenshots')
    ..createSync(recursive: true);
  final file = File('${dir.path}/$name.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file;
}
