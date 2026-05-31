// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/app.dart';
import 'package:dayz/ui/settings/settings_screen.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/placeholder_screen.dart';
import 'package:dayz/ui/shell/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/localized_test_app.dart';

void main() {
  late ThemeController themeController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appRouter.go(Routes.timelinePath);
    themeController = ThemeController();
  });

  tearDown(() {
    themeController.dispose();
  });

  testWidgets('Routes.settings renders real settings screen', (tester) async {
    await tester.pumpWidget(DayZApp(themeController: themeController));
    await _pumpApp(tester);

    appRouter.goNamed(Routes.settings);
    await _pumpApp(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text(testL10n.settingsTitle), findsOneWidget);
    expect(find.text(testL10n.shellPlaceholderSuffix), findsNothing);
  });

  testWidgets('settings back pops when pushed and falls back to timeline at stack root', (
    tester,
  ) async {
    await tester.pumpWidget(DayZApp(themeController: themeController));
    await _pumpApp(tester);

    appRouter.pushNamed(Routes.settings);
    await _pumpApp(tester);
    await tester.tap(find.byKey(SettingsScreen.backButtonKey));
    await _pumpApp(tester);

    expect(find.text(testL10n.timeline), findsOneWidget);

    appRouter.goNamed(Routes.settings);
    await _pumpApp(tester);
    await tester.tap(find.byKey(SettingsScreen.backButtonKey));
    await _pumpApp(tester);

    expect(find.text(testL10n.timeline), findsOneWidget);
  });

  testWidgets('settings route uses ThemeControllerScope for picker updates', (
    tester,
  ) async {
    await tester.pumpWidget(DayZApp(themeController: themeController));
    await _pumpApp(tester);

    appRouter.goNamed(Routes.settings);
    await _pumpApp(tester);

    await tester.tap(find.byKey(SettingsScreen.themeRowKey));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(testL10n.settingsThemeAmber));
    await _pumpApp(tester);

    expect(themeController.choice.themeName, 'amber');
  });

  testWidgets('other placeholder routes stay placeholders', (tester) async {
    await tester.pumpWidget(DayZApp(themeController: themeController));
    await _pumpApp(tester);

    appRouter.goNamed(Routes.calendar);
    await _pumpApp(tester);

    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text(testL10n.shellPlaceholderSuffix), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}
