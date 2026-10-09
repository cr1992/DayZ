// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/settings/settings_screen.dart';
import 'package:dayz/ui/widgets/dayz_switch.dart';

import '../../l10n/localized_test_app.dart';

void main() {
  testWidgets('database encryption row is read-only and media redline is visible', (
    tester,
  ) async {
    var appLockCalls = 0;

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
          onAppLockChanged: (_) => appLockCalls += 1,
          onDraftRecoveryChanged: (_) {},
          onTapBackup: () {},
          onTapExport: () {},
          onBack: () {},
        ),
      ),
    );

    final encryptionRow = find.byKey(SettingsScreen.databaseEncryptionRowKey);
    expect(encryptionRow, findsOneWidget);
    expect(
      find.descendant(of: encryptionRow, matching: find.text(testL10n.settingsDbEncryptedValue)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: encryptionRow, matching: find.byType(DayzSwitch)),
      findsNothing,
    );

    await tester.tap(encryptionRow);
    await tester.pump();
    expect(appLockCalls, 0);

    expect(find.text(testL10n.settingsMediaNotLockedByPassword), findsOneWidget);
    expect(
      find.bySemanticsLabel(testL10n.settingsMediaNotLockedByPassword),
      findsOneWidget,
    );
  });
}
