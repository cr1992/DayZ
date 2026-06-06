// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

const _viewerBoundaryKey = ValueKey<String>(
  'dayz-image-viewer-visual-boundary',
);

void main() {
  patrolTest('DayzImageViewer 视觉：全屏媒体层与横滑翻页', ($) async {
    final images = await _demoImages();

    await $.pumpWidget(
      _ViewerHost(images: images, captions: const ['夜色里的书桌', '海边日记', '午后窗光']),
    );
    await $.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    final first = await _writeScreenshot($.tester, 'dayz_image_viewer_page_1');
    $.log('DayzImageViewer screenshot: ${first.path}');

    await _swipeToNextPage($.tester);

    expect(find.text('2 / 3'), findsOneWidget);
    final second = await _writeScreenshot($.tester, 'dayz_image_viewer_page_2');
    $.log('DayzImageViewer screenshot: ${second.path}');

    expect(first.lengthSync(), greaterThan(0));
    expect(second.lengthSync(), greaterThan(0));
  });
}

class _ViewerHost extends StatelessWidget {
  const _ViewerHost({required this.images, required this.captions});

  final List<ImageProvider> images;
  final List<String?> captions;

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
      home: RepaintBoundary(
        key: _viewerBoundaryKey,
        child: DayzImageViewer(images: images, captions: captions),
      ),
    );
  }
}

Future<List<ImageProvider>> _demoImages() async {
  return [
    MemoryImage(await _pngForColor(const Color(0xFF786CAD))),
    MemoryImage(await _pngForColor(const Color(0xFF3D6F76))),
    MemoryImage(await _pngForColor(const Color(0xFFD6A23A))),
  ];
}

Future<Uint8List> _pngForColor(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 640, 420), paint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(640, 420);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();

  return bytes!.buffer.asUint8List();
}

Future<File> _writeScreenshot(WidgetTester tester, String name) async {
  await tester.pump();

  final boundary =
      tester.renderObject(find.byKey(_viewerBoundaryKey))
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

Future<void> _swipeToNextPage(WidgetTester tester) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.dragFrom(
    Offset(size.width * 0.84, size.height * 0.52),
    Offset(-size.width * 0.72, 0),
  );
  await tester.pumpAndSettle();
}
