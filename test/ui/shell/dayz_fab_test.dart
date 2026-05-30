// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/shell/dayz_fab.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for [DayzFab].
///
/// Author: @Ray
void main() {
  testWidgets('tap triggers main callback without opening actions', (
    tester,
  ) async {
    var mainTaps = 0;
    var cameraTaps = 0;

    await tester.pumpWidget(
      _FabTestApp(
        onTap: () => mainTaps += 1,
        actions: [
          DayzFabAction(
            label: AppStrings.camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onTap: () => cameraTaps += 1,
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const ValueKey('dayz-fab-main')));
    await tester.pump();

    expect(mainTaps, 1);
    expect(cameraTaps, 0);
    expect(find.text(AppStrings.camera), findsNothing);
    expect(find.byKey(const ValueKey('dayz-fab-scrim')), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('dayz-fab-scrim-opacity')),
          )
          .opacity,
      0,
    );
  });

  testWidgets('long press opens actions and scrim', (tester) async {
    await tester.pumpWidget(
      _FabTestApp(
        actions: [
          DayzFabAction(
            label: AppStrings.camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onTap: () {},
          ),
          DayzFabAction(
            label: AppStrings.voice,
            icon: const Icon(Icons.mic_none_outlined),
            onTap: () {},
          ),
        ],
      ),
    );

    await tester.longPress(find.byKey(const ValueKey('dayz-fab-main')));
    await tester.pump();

    expect(find.text(AppStrings.camera), findsOneWidget);
    expect(find.text(AppStrings.voice), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.camera), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('dayz-fab-scrim-opacity')),
          )
          .opacity,
      1,
    );
  });

  testWidgets('action tap closes dial and invokes action callback', (
    tester,
  ) async {
    var cameraTaps = 0;
    var voiceTaps = 0;

    await tester.pumpWidget(
      _FabTestApp(
        actions: [
          DayzFabAction(
            label: AppStrings.camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onTap: () => cameraTaps += 1,
          ),
          DayzFabAction(
            label: AppStrings.voice,
            icon: const Icon(Icons.mic_none_outlined),
            onTap: () => voiceTaps += 1,
          ),
        ],
      ),
    );

    await tester.longPress(find.byKey(const ValueKey('dayz-fab-main')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(AppStrings.camera));
    await tester.pumpAndSettle();

    expect(cameraTaps, 1);
    expect(voiceTaps, 0);
    expect(find.text(AppStrings.camera), findsNothing);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('dayz-fab-scrim-opacity')),
          )
          .opacity,
      0,
    );
  });

  testWidgets('scrim tap closes dial without invoking actions', (tester) async {
    var cameraTaps = 0;

    await tester.pumpWidget(
      _FabTestApp(
        actions: [
          DayzFabAction(
            label: AppStrings.camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onTap: () => cameraTaps += 1,
          ),
        ],
      ),
    );

    await tester.longPress(find.byKey(const ValueKey('dayz-fab-main')));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(cameraTaps, 0);
    expect(find.text(AppStrings.camera), findsNothing);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('dayz-fab-scrim-opacity')),
          )
          .opacity,
      0,
    );
  });

  testWidgets('main button and actions meet minimum hit target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _FabTestApp(
        actions: [
          DayzFabAction(
            label: AppStrings.camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onTap: () {},
          ),
        ],
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('dayz-fab-main'))),
      const Size.square(58),
    );

    await tester.longPress(find.byKey(const ValueKey('dayz-fab-main')));
    await tester.pumpAndSettle();

    final actionSize = tester.getSize(
      find.byKey(ValueKey('dayz-fab-action-${AppStrings.camera}')),
    );

    expect(actionSize.width, greaterThanOrEqualTo(44));
    expect(actionSize.height, greaterThanOrEqualTo(44));
  });

  testWidgets('main button uses fab gradient and three shadows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _FabTestApp(
        actions: [
          DayzFabAction(
            label: AppStrings.camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onTap: () {},
          ),
        ],
      ),
    );

    final decoratedBox = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('dayz-fab-main')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;

    expect(decoration.shape, BoxShape.circle);
    expect(decoration.gradient, DayzColors.purpleLight.fabGradient);
    expect(decoration.boxShadow, hasLength(3));
  });

  testWidgets('disableAnimations makes scrim and actions instant', (
    tester,
  ) async {
    await tester.pumpWidget(
      _FabTestApp(
        disableAnimations: true,
        actions: [
          DayzFabAction(
            label: AppStrings.camera,
            icon: const Icon(Icons.photo_camera_outlined),
            onTap: () {},
          ),
        ],
      ),
    );

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('dayz-fab-scrim-opacity')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );

    await tester.longPress(find.byKey(const ValueKey('dayz-fab-main')));
    await tester.pump();

    expect(find.text(AppStrings.camera), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('dayz-fab-scrim-opacity')),
          )
          .opacity,
      1,
    );
  });
}

class _FabTestApp extends StatelessWidget {
  const _FabTestApp({
    this.onTap,
    this.actions = const [],
    this.disableAnimations = false,
  });

  final VoidCallback? onTap;
  final List<DayzFabAction> actions;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: DayzThemes.purpleLight,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: DayzFab(onTap: onTap ?? () {}, actions: actions),
        ),
      ),
    );
  }
}
