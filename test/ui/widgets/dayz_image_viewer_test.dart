// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

/// Widget tests for [DayzImageViewer].
///
/// Author: @Ray
void main() {
  testWidgets('starts from initial index and updates count after paging', (
    tester,
  ) async {
    await tester.pumpWidget(
      _viewerApp(
        images: _images(3),
        captions: const ['Cover', 'Second', 'Third'],
      ),
    );

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dayz-image-viewer-page-0')),
      findsOneWidget,
    );

    await tester.fling(find.byType(PageView), const Offset(-520, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('hides count for a single image', (tester) async {
    await tester.pumpWidget(_viewerApp(images: _images(1)));

    expect(find.text('1 / 1'), findsNothing);
  });

  testWidgets('tapping image keeps viewer open but tapping background closes', (
    tester,
  ) async {
    var closes = 0;

    await tester.pumpWidget(
      _viewerApp(images: _images(1), onClose: () => closes += 1),
    );

    await tester.tapAt(tester.getCenter(find.byType(Image)));
    await tester.pump(const Duration(milliseconds: 50));

    expect(closes, 0);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 50));

    expect(closes, 1);
  });

  testWidgets('close button exposes localized semantics and 44px hit target', (
    tester,
  ) async {
    var closes = 0;

    await tester.pumpWidget(
      _viewerApp(images: _images(1), onClose: () => closes += 1),
    );

    final closeFinder = find.bySemanticsLabel(testL10n.close);
    expect(closeFinder, findsOneWidget);
    expect(tester.getSize(closeFinder), const Size.square(44));

    await tester.tap(closeFinder);
    await tester.pump();

    expect(closes, 1);
  });

  testWidgets('counter clears inherited debug underline text decoration', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        child: DefaultTextStyle(
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.yellow,
          ),
          child: DayzImageViewer(images: _images(3)),
        ),
      ),
    );

    final counterText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == '1 / 3',
      ),
    );

    expect(
      (counterText.text as TextSpan).style?.decoration,
      TextDecoration.none,
    );
  });

  testWidgets('media layer background is derived from DayZ theme colors', (
    tester,
  ) async {
    await tester.pumpWidget(_viewerApp(images: _images(1)));

    final background = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('dayz-image-viewer-background')),
    );

    expect(
      background.color,
      DayzImageViewer.mediaBackgroundColor(DayzColors.purpleLight),
    );
  });
}

Widget _viewerApp({
  required List<ImageProvider> images,
  int initialIndex = 0,
  List<String?>? captions,
  VoidCallback? onClose,
}) {
  return localizedTestApp(
    child: DayzImageViewer(
      images: images,
      initialIndex: initialIndex,
      captions: captions,
      onClose: onClose,
    ),
  );
}

List<ImageProvider> _images(int count) {
  return [for (var i = 0; i < count; i++) MemoryImage(_onePixelPng)];
}

final Uint8List _onePixelPng = Uint8List.fromList(const [
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
]);
