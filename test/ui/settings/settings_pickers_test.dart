// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/settings/settings_screen.dart';

import '../../l10n/localized_test_app.dart';

void main() {
  testWidgets('theme picker shows choices and reports selected theme', (
    tester,
  ) async {
    String? pickedTheme;

    await tester.pumpWidget(
      localizedMaterialApp(
        home: _screen(onPickTheme: (value) => pickedTheme = value),
      ),
    );

    await tester.tap(find.byKey(SettingsScreen.themeRowKey));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.settingsThemePurple), findsWidgets);
    expect(find.text(testL10n.settingsThemeAmber), findsOneWidget);
    expect(
      find.byKey(ValueKey('dayz-sheet-selected-${testL10n.settingsThemePurple}')),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel(testL10n.settingsThemeAmber));
    await tester.pumpAndSettle();

    expect(pickedTheme, 'amber');
    expect(find.text(testL10n.settingsThemeAmber), findsOneWidget);
  });

  testWidgets('appearance picker reports selected mode', (tester) async {
    ThemeMode? pickedMode;

    await tester.pumpWidget(
      localizedMaterialApp(home: _screen(onPickMode: (value) => pickedMode = value)),
    );

    await tester.tap(find.byKey(SettingsScreen.modeRowKey));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.settingsModeSystem), findsWidgets);
    expect(find.text(testL10n.settingsModeDark), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(testL10n.settingsModeDark));
    await tester.pumpAndSettle();

    expect(pickedMode, ThemeMode.dark);
  });
}

SettingsScreen _screen({
  ValueChanged<String>? onPickTheme,
  ValueChanged<ThemeMode>? onPickMode,
}) {
  return SettingsScreen(
    accountStats: const SettingsAccountStats(
      displayName: 'Lin Wan',
      initials: 'L',
      entryCount: 218,
      localLibraryBytes: 43201331,
    ),
    currentThemeName: 'purple',
    currentMode: ThemeMode.system,
    appLockEnabled: true,
    draftRecoveryEnabled: true,
    onPickTheme: onPickTheme ?? (_) {},
    onPickMode: onPickMode ?? (_) {},
    onAppLockChanged: (_) {},
    onDraftRecoveryChanged: (_) {},
    onTapBackup: () {},
    onTapExport: () {},
    onBack: () {},
  );
}
