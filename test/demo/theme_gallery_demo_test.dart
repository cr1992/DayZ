// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/theme_gallery_demo.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

/// Widget tests for [ThemeGalleryDemo] and its entry in [DebugHome].
///
/// Author: @Ray
void main() {
  group('ThemeGalleryDemo Widget Tests', () {
    test('demos list has theme_gallery_demo at the end', () {
      expect(demos.last.title, '主题画廊 demo');
      expect(demos.last.subtitle, '设计 Token 与六套主题画廊');
    });

    testWidgets('Can navigate to ThemeGalleryDemo from DebugHome and switch themes', (WidgetTester tester) async {
      // 1. Pump DebugHome inside a Navigator
      await tester.pumpWidget(
        const MaterialApp(
          home: DebugHome(),
        ),
      );

      // Verify the list tile exists
      final tileFinder = find.text('主题画廊 demo');
      expect(tileFinder, findsOneWidget);

      // 2. Click to open gallery
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      // Verify ThemeGalleryDemo is now visible
      expect(find.byType(ThemeGalleryDemo), findsOneWidget);
      expect(find.text('选择主题'), findsOneWidget);

      // Helper to find the current active theme colors under the ThemeGalleryDemo subtree
      DayzColors getCurrentColors() {
        final BuildContext context = tester.element(find.byType(CustomScrollView));
        return context.dayz;
      }

      // Default theme is purpleLight
      expect(getCurrentColors().bg, DayzColors.purpleLight.bg);
      expect(getCurrentColors().accent, DayzColors.purpleLight.accent);

      // 3. Switch theme to purpleDark
      final purpleDarkChip = find.widgetWithText(ChoiceChip, 'purpleDark');
      expect(purpleDarkChip, findsOneWidget);
      await tester.ensureVisible(purpleDarkChip);
      await tester.tap(purpleDarkChip);
      await tester.pumpAndSettle();

      expect(getCurrentColors().bg, DayzColors.purpleDark.bg);
      expect(getCurrentColors().accent, DayzColors.purpleDark.accent);

      // 4. Switch theme to amberLight
      final amberLightChip = find.widgetWithText(ChoiceChip, 'amberLight');
      expect(amberLightChip, findsOneWidget);
      await tester.ensureVisible(amberLightChip);
      await tester.tap(amberLightChip);
      await tester.pumpAndSettle();

      expect(getCurrentColors().bg, DayzColors.amberLight.bg);
      expect(getCurrentColors().accent, DayzColors.amberLight.accent);

      // 5. Switch theme to sageDark
      final sageDarkChip = find.widgetWithText(ChoiceChip, 'sageDark');
      expect(sageDarkChip, findsOneWidget);
      await tester.ensureVisible(sageDarkChip);
      await tester.tap(sageDarkChip);
      await tester.pumpAndSettle();

      expect(getCurrentColors().bg, DayzColors.sageDark.bg);
      expect(getCurrentColors().accent, DayzColors.sageDark.accent);
    });
  });
}
