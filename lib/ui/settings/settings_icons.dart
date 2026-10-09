// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import '../widgets/dayz_icons.dart';

/// SVG path data owned by the settings screen.
///
/// Author: @Ray
abstract final class SettingsIcons {
  static const String appLockPath =
      'M7 10V7a5 5 0 0 1 10 0v3M6.5 10h11a1.5 1.5 0 0 1 1.5 1.5v7A1.5 1.5 0 0 1 17.5 20h-11A1.5 1.5 0 0 1 5 18.5v-7A1.5 1.5 0 0 1 6.5 10ZM12 14v2';
  static const String databaseEncryptedPath =
      'M5 6c0-1.7 3.1-3 7-3s7 1.3 7 3-3.1 3-7 3-7-1.3-7-3Zm0 0v6c0 1.7 3.1 3 7 3s7-1.3 7-3V6M5 12v6c0 1.7 3.1 3 7 3s7-1.3 7-3v-6M9 17l2 2 4-4';
  static const String backupPath =
      'M7 18.5H6a4 4 0 0 1-.6-8A6.5 6.5 0 0 1 18 8.5a4.5 4.5 0 0 1 0 9h-1M12 12v8M8.5 15.5 12 12l3.5 3.5';
  static const String exportPath =
      'M12 3v11M8.5 6.5 12 3l3.5 3.5M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6';
  static const String themePath =
      'M12 3a9 9 0 1 0 0 18h1.5a2 2 0 0 0 1.4-3.4l-.8-.8a2 2 0 0 1 1.4-3.4H17a4 4 0 0 0 0-8h-5ZM7.5 10h.01M9.5 6.8h.01M14 6.5h.01';
  static const String appearancePath = 'M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9Z';
  static const String draftRecoveryPath =
      'M7 3.5h7l4 4v13H7a2 2 0 0 1-2-2v-13a2 2 0 0 1 2-2ZM14 3.5V8h4M8.5 13h7M8.5 16.5h5';

  static const List<String> allPaths = [
    appLockPath,
    databaseEncryptedPath,
    backupPath,
    exportPath,
    themePath,
    appearancePath,
    draftRecoveryPath,
    DayzIcons.settingsPath,
  ];
}
