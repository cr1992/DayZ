// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/settings/settings_icons.dart';

import '../../l10n/localized_test_app.dart';

void main() {
  test('settings localization entries and icon paths are available', () {
    expect(testL10n.settingsTitle, isNotEmpty);
    expect(testL10n.settingsGroupPrivacy, isNotEmpty);
    expect(testL10n.settingsDbEncryptedValue, isNotEmpty);
    expect(testL10n.settingsMediaNotLockedByPassword, isNotEmpty);
    expect(testL10n.settingsThemeAmber, isNotEmpty);
    expect(testL10n.settingsModeDark, isNotEmpty);

    for (final path in SettingsIcons.allPaths) {
      expect(path, isNotEmpty);
      expect(path, isNot(contains('#')));
      expect(path, isNot(contains('fill=')));
      expect(path, isNot(contains('stroke=')));
    }
  });
}
