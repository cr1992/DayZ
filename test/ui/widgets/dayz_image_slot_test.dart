// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

/// 可控图源：测试决定何时出帧 / 失败；按实例同一性做缓存 key。
class _ControlledImage extends ImageProvider<_ControlledImage> {
  final Completer<ImageInfo> completer = Completer<ImageInfo>();

  @override
  Future<_ControlledImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_ControlledImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ControlledImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(completer.future);
  }
}

/// ui-kit-patch T2：图位占位 / 淡入 / 失败兜底。
///
/// Author: @Ray
void main() {
  Future<ui.Image> testImage(WidgetTester tester) async {
    return (await tester.runAsync(() => createTestImage(width: 4, height: 3)))!;
  }

  Widget slotApp(ImageProvider image, {bool disableAnimations = false}) {
    return localizedTestApp(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Center(
          child: SizedBox(
            width: 120,
            height: 90,
            child: DayzImageSlot(image: image),
          ),
        ),
      ),
    );
  }

  AnimatedOpacity fade(WidgetTester tester) {
    return tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(DayzImageSlot),
        matching: find.byType(AnimatedOpacity),
      ),
    );
  }

  testWidgets('no frame yet: image hidden over the accentSoft2 placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(slotApp(_ControlledImage()));

    expect(fade(tester).opacity, 0);
    final base = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(DayzImageSlot),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(base.color, DayzColors.purpleLight.accentSoft2);
  });

  testWidgets('first frame fades in over DayzMotion.dur', (tester) async {
    final image = _ControlledImage();
    final frame = await testImage(tester);
    await tester.pumpWidget(slotApp(image));

    image.completer.complete(ImageInfo(image: frame));
    await tester.pump();

    expect(fade(tester).opacity, 1);
    expect(fade(tester).duration, DayzMotion.dur);
    await tester.pumpAndSettle();
    expect(find.byKey(DayzImageSlot.placeholderKey), findsNothing);
  });

  testWidgets('reduce motion makes the fade instant', (tester) async {
    final image = _ControlledImage();
    final frame = await testImage(tester);
    await tester.pumpWidget(slotApp(image, disableAnimations: true));

    image.completer.complete(ImageInfo(image: frame));
    await tester.pump();

    expect(fade(tester).opacity, 1);
    expect(fade(tester).duration, Duration.zero);
  });

  testWidgets('load failure shows the placeholder without throwing', (
    tester,
  ) async {
    final image = _ControlledImage();
    await tester.pumpWidget(slotApp(image));

    image.completer.completeError(StateError('decrypt failed'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(DayzImageSlot.placeholderKey), findsOneWidget);
    expect(
      tester
          .widget<ColoredBox>(find.byKey(DayzImageSlot.placeholderKey))
          .color,
      DayzColors.purpleLight.accentSoft2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('entry card cover and gallery tiles render through the slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DayzEntryCard(
                key: const ValueKey('card'),
                title: 'Title',
                summary: 'Summary',
                date: DateTime(2026, 10, 10),
                cover: _ControlledImage(),
              ),
              SizedBox(
                width: 300,
                child: DayzGallery(
                  key: const ValueKey('gallery'),
                  images: [_ControlledImage(), _ControlledImage()],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('card')),
        matching: find.byType(DayzImageSlot),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gallery')),
        matching: find.byType(DayzImageSlot),
      ),
      findsNWidgets(2),
    );
  });
}
