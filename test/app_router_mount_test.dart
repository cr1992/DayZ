// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/app.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/theme_controller.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

void main() {
  setUp(() {
    appRouter.go('/timeline');
  });

  testWidgets('App cold start goes to timeline screen not DebugHome directly', (tester) async {
    await tester.pumpWidget(const DayZApp());
    await tester.pumpAndSettle();

    // Verify it landed on Timeline placeholder screen (our initialLocation)
    expect(find.text(AppStrings.timeline), findsOneWidget);
    expect(find.text(AppStrings.shellPlaceholderSuffix), findsOneWidget);

    // Verify DebugHome is NOT the immediate child (since we use GoRouter)
    expect(find.byType(DebugHome), findsNothing);
  });

  testWidgets('Routes.debugHome can navigate to DebugHome', (tester) async {
    await tester.pumpWidget(const DayZApp());
    await tester.pumpAndSettle();

    appRouter.goNamed(Routes.debugHome);
    await tester.pumpAndSettle();

    // Verify DebugHome is now visible
    expect(find.byType(DebugHome), findsOneWidget);
  });

  testWidgets('theme controller updates rebuilds DayZApp tree with correct colors', (tester) async {
    final controller = ThemeController();

    await tester.pumpWidget(DayZApp(themeController: controller));
    await tester.pumpAndSettle();

    final BuildContext contextBefore = tester.element(find.text(AppStrings.timeline));
    expect(contextBefore.dayz.accent, DayzColors.purpleLight.accent);

    // Switch to amber theme
    controller.setTheme('amber');
    await tester.pumpAndSettle();

    final BuildContext contextAfter = tester.element(find.text(AppStrings.timeline));
    expect(contextAfter.dayz.accent, DayzColors.amberLight.accent);
  });
}
