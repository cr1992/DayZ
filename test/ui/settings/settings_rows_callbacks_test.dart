// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/settings/settings_screen.dart';
import 'package:dayz/ui/widgets/dayz_switch.dart';

import '../../l10n/localized_test_app.dart';

void main() {
  testWidgets('switch and navigation rows lift callbacks without persistence', (
    tester,
  ) async {
    bool? appLock;
    bool? draftRecovery;
    var backupTaps = 0;
    var exportTaps = 0;

    await tester.pumpWidget(
      localizedMaterialApp(
        home: SettingsScreen(
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
          onPickTheme: (_) {},
          onPickMode: (_) {},
          onAppLockChanged: (value) => appLock = value,
          onDraftRecoveryChanged: (value) => draftRecovery = value,
          onTapBackup: () => backupTaps += 1,
          onTapExport: () => exportTaps += 1,
          onBack: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel(testL10n.settingsAppLockSemanticLabel), findsOneWidget);
    expect(
      find.bySemanticsLabel(testL10n.settingsDraftRecoverySemanticLabel),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(SettingsScreen.appLockRowKey),
        matching: find.byType(DayzSwitch),
      ),
    );
    await tester.pump();
    expect(appLock, false);

    await tester.tap(
      find.descendant(
        of: find.byKey(SettingsScreen.draftRecoveryRowKey),
        matching: find.byType(DayzSwitch),
      ),
    );
    await tester.pump();
    expect(draftRecovery, false);

    await tester.tap(find.byKey(SettingsScreen.backupRowKey));
    await tester.pump();
    await tester.tap(find.byKey(SettingsScreen.exportRowKey));
    await tester.pump();

    expect(backupTaps, 1);
    expect(exportTaps, 1);
    expect(tester.getSize(find.byKey(SettingsScreen.backupRowKey)).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.byKey(SettingsScreen.exportRowKey)).height, greaterThanOrEqualTo(44));
  });
}
