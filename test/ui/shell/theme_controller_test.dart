// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/shell/theme_controller.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

void main() {
  group('ThemeController Unit Tests', () {
    test('default properties', () {
      final controller = ThemeController();
      expect(controller.choice.themeName, 'purple');
      expect(controller.choice.mode, ThemeMode.system);
      expect(controller.choice.paper, false);
      expect(controller.themeMode, ThemeMode.system);
    });

    test('setTheme triggers notifyListeners and updates themeName', () {
      final controller = ThemeController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setTheme('amber');
      expect(notifyCount, 1);
      expect(controller.choice.themeName, 'amber');

      // Setting same theme should not notify
      controller.setTheme('amber');
      expect(notifyCount, 1);
    });

    test('setMode triggers notifyListeners and updates mode', () {
      final controller = ThemeController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setMode(ThemeMode.dark);
      expect(notifyCount, 1);
      expect(controller.choice.mode, ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);

      // Setting same mode should not notify
      controller.setMode(ThemeMode.dark);
      expect(notifyCount, 1);
    });

    test('setPaper triggers notifyListeners and updates paper', () {
      final controller = ThemeController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setPaper(true);
      expect(notifyCount, 1);
      expect(controller.choice.paper, true);

      // Setting same paper should not notify
      controller.setPaper(true);
      expect(notifyCount, 1);
    });
  });

  group('ThemeController Widget Tests', () {
    testWidgets('setTheme changes materialTheme colors', (tester) async {
      final controller = ThemeController();

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return MaterialApp(
              theme: controller.materialTheme,
              darkTheme: controller.materialDarkTheme,
              themeMode: controller.themeMode,
              home: const SizedBox(),
            );
          },
        ),
      );

      // Default is purple light theme accent color
      {
        final BuildContext context = tester.element(find.byType(SizedBox));
        expect(context.dayz.accent, DayzColors.purpleLight.accent);
      }

      controller.setTheme('amber');
      await tester.pumpAndSettle();

      // Should now be amber light theme accent color
      {
        final BuildContext context = tester.element(find.byType(SizedBox));
        expect(context.dayz.accent, DayzColors.amberLight.accent);
      }
    });

    testWidgets('setMode system responds to platformBrightness changes', (tester) async {
      final controller = ThemeController();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return MaterialApp(
                theme: controller.materialTheme,
                darkTheme: controller.materialDarkTheme,
                themeMode: controller.themeMode,
                home: const SizedBox(),
              );
            },
          ),
        ),
      );

      // Under system mode and dark platform brightness, should render dark theme
      {
        final BuildContext context = tester.element(find.byType(SizedBox));
        expect(context.dayz.accent, DayzColors.purpleDark.accent);
      }

      // Explicitly set light mode
      controller.setMode(ThemeMode.light);
      await tester.pumpAndSettle();

      // Even if platform is dark, theme should remain light
      {
        final BuildContext context = tester.element(find.byType(SizedBox));
        expect(context.dayz.accent, DayzColors.purpleLight.accent);
      }
    });
  });
}
