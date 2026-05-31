// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/app.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/l10n/locale_controller.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/theme_controller.dart';
import 'l10n/localized_test_app.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocaleController localeController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    localeController = LocaleController();
    appRouter.go('/timeline');
  });

  tearDown(() {
    localeController.dispose();
  });

  Future<void> pumpAppFrame(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('App cold start goes to timeline screen not DebugHome directly', (
    tester,
  ) async {
    await localeController.setLocale(const Locale('zh'));

    await tester.pumpWidget(DayZApp(localeController: localeController));
    await pumpAppFrame(tester);

    // Verify it landed on Timeline placeholder screen (our initialLocation)
    expect(find.text(testL10n.timeline), findsOneWidget);
    expect(find.text(testL10n.shellPlaceholderSuffix), findsOneWidget);

    // Verify DebugHome is NOT the immediate child (since we use GoRouter)
    expect(find.byType(DebugHome), findsNothing);
  });

  testWidgets('Routes.debugHome can navigate to DebugHome', (tester) async {
    await localeController.setLocale(const Locale('zh'));

    await tester.pumpWidget(DayZApp(localeController: localeController));
    await pumpAppFrame(tester);

    appRouter.goNamed(Routes.debugHome);
    await pumpAppFrame(tester);

    // Verify DebugHome is now visible
    expect(find.byType(DebugHome), findsOneWidget);
  });

  testWidgets(
    'theme controller updates rebuilds DayZApp tree with correct colors',
    (tester) async {
      final controller = ThemeController();
      await localeController.setLocale(const Locale('zh'));

      await tester.pumpWidget(
        DayZApp(
          localeController: localeController,
          themeController: controller,
        ),
      );
      await pumpAppFrame(tester);

      final BuildContext contextBefore = tester.element(
        find.text(testL10n.timeline),
      );
      expect(contextBefore.dayz.accent, DayzColors.purpleLight.accent);

      // Switch to amber theme
      controller.setTheme('amber');
      await pumpAppFrame(tester);

      final BuildContext contextAfter = tester.element(
        find.text(testL10n.timeline),
      );
      expect(contextAfter.dayz.accent, DayzColors.amberLight.accent);
    },
  );
}
