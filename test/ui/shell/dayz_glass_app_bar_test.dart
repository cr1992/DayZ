// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for [DayzGlassAppBar].
///
/// Author: @Ray
void main() {
  testWidgets('uses solid bg and no BackdropFilter before scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(const _AppBarHost());

    expect(find.byType(DayzGlassAppBar), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);

    final decoration = _surfaceDecoration(tester);
    expect(decoration.color, DayzColors.purpleLight.bg);
    expect(decoration.border, isNull);
  });

  testWidgets('shows glass blur, glass surface, and hairline after threshold', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_AppBarHost(scrollController: controller));

    controller.jumpTo(DayzGlassAppBar.defaultScrolledUnderOffset + 16);
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);

    final backdrop = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(backdrop.filter.toString(), contains('ImageFilter.blur(20.0, 20.0'));

    final decoration = _surfaceDecoration(tester);
    expect(decoration.color, DayzColors.purpleLight.glassSurface);

    final border = decoration.border as Border?;
    expect(border, isNotNull);
    expect(border!.bottom.color, DayzColors.purpleLight.hairline);
    expect(border.bottom.width, 0.5);
  });

  testWidgets('scrolledUnder override forces the glass state', (tester) async {
    await tester.pumpWidget(const _AppBarHost(scrolledUnder: true));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      _surfaceDecoration(tester).color,
      DayzColors.purpleLight.glassSurface,
    );
  });

  testWidgets('disableAnimations makes the state switch instantaneous', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _AppBarHost(scrolledUnder: false, disableAnimations: true),
    );

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );

    await tester.pumpWidget(
      const _AppBarHost(scrolledUnder: true, disableAnimations: true),
    );
    await tester.pump();

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}

BoxDecoration _surfaceDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.byKey(DayzGlassAppBar.surfaceKey),
  );
  return box.decoration as BoxDecoration;
}

class _AppBarHost extends StatelessWidget {
  const _AppBarHost({
    this.scrollController,
    this.scrolledUnder,
    this.disableAnimations = false,
  });

  final ScrollController? scrollController;
  final bool? scrolledUnder;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: DayzThemes.purpleLight,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: CustomScrollView(
            controller: scrollController,
            slivers: [
              DayzGlassAppBar(
                title: const Text('DayZ'),
                leading: const BackButton(),
                actions: const [
                  IconButton(onPressed: null, icon: Icon(Icons.add)),
                ],
                scrollController: scrollController,
                scrolledUnder: scrolledUnder,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1200)),
            ],
          ),
        ),
      ),
    );
  }
}
