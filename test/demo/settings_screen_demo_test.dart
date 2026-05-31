// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/settings_screen_demo.dart';
import 'package:dayz/ui/settings/settings_screen.dart';
import 'package:dayz/ui/widgets/dayz_switch.dart';

import '../l10n/localized_test_app.dart';

void main() {
  testWidgets('settings demo is appended and renders redline copy', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));

    expect(find.text('设置屏 demo'), findsOneWidget);
    await tester.tap(find.text('设置屏 demo'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreenDemo), findsOneWidget);
    expect(find.text(testL10n.settingsDbEncryptedValue), findsOneWidget);
    expect(find.text(testL10n.settingsMediaNotLockedByPassword), findsOneWidget);
  });

  testWidgets('settings demo keeps switch visual state locally', (tester) async {
    await tester.pumpWidget(localizedTestApp(child: const SettingsScreenDemo()));

    DayzSwitch appLockSwitch() {
      return tester.widget<DayzSwitch>(
        find.descendant(
          of: find.byKey(SettingsScreen.appLockRowKey),
          matching: find.byType(DayzSwitch),
        ),
      );
    }

    expect(appLockSwitch().value, isTrue);

    await tester.tap(
      find.descendant(
        of: find.byKey(SettingsScreen.appLockRowKey),
        matching: find.byType(DayzSwitch),
      ),
    );
    await tester.pump();

    expect(appLockSwitch().value, isFalse);
  });
}
