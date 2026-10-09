// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/settings/settings_screen.dart';

import '../../l10n/localized_test_app.dart';

void main() {
  testWidgets('settings screen renders account card, groups, and rows', (
    tester,
  ) async {
    await tester.pumpWidget(localizedMaterialApp(home: _screen()));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text(testL10n.settingsTitle), findsOneWidget);
    expect(find.text('Lin Wan'), findsOneWidget);
    expect(find.text(testL10n.settingsAccountStats(218, '41.2 MB')), findsOneWidget);

    for (final label in [
      testL10n.settingsGroupPrivacy,
      testL10n.settingsGroupBackup,
      testL10n.settingsGroupAppearance,
      testL10n.settingsGroupWriting,
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    for (final title in [
      testL10n.settingsAppLockTitle,
      testL10n.settingsDbEncryptionTitle,
      testL10n.settingsBackupTitle,
      testL10n.settingsExportTitle,
      testL10n.settingsThemeTitle,
      testL10n.settingsAppearanceModeTitle,
      testL10n.settingsDraftRecoveryTitle,
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('account stats are driven by constructor input', (tester) async {
    await tester.pumpWidget(
      localizedMaterialApp(
        home: _screen(
          stats: const SettingsAccountStats(
            displayName: 'Aki',
            initials: 'A',
            entryCount: 7,
            localLibraryBytes: 1572864,
          ),
        ),
      ),
    );

    expect(find.text('Aki'), findsOneWidget);
    expect(find.text(testL10n.settingsAccountStats(7, '1.5 MB')), findsOneWidget);
    expect(find.text(testL10n.settingsAccountStats(218, '41.2 MB')), findsNothing);
  });
}

SettingsScreen _screen({SettingsAccountStats? stats}) {
  return SettingsScreen(
    accountStats:
        stats ??
        const SettingsAccountStats(
          displayName: 'Lin Wan',
          initials: 'L',
          entryCount: 218,
          localLibraryBytes: 43201331,
        ),
    currentThemeName: 'purple',
    currentMode: ThemeMode.system,
    appLockEnabled: true,
    draftRecoveryEnabled: true,
    onPickTheme: (_) {},
    onPickMode: (_) {},
    onAppLockChanged: (_) {},
    onDraftRecoveryChanged: (_) {},
    onTapBackup: () {},
    onTapExport: () {},
    onBack: () {},
  );
}
