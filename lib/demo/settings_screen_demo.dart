// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/theme/dayz_theme.dart';

/// Debug Home demo for the settings screen.
///
/// Author: @Ray
class SettingsScreenDemo extends StatefulWidget {
  const SettingsScreenDemo({super.key});

  @override
  State<SettingsScreenDemo> createState() => _SettingsScreenDemoState();
}

class _SettingsScreenDemoState extends State<SettingsScreenDemo> {
  String _themeName = 'purple';
  ThemeMode _mode = ThemeMode.system;
  bool _appLockEnabled = true;
  bool _draftRecoveryEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: dayzTheme(_themeType, _brightness),
      child: Builder(
        builder: (context) {
          return SettingsScreen(
            accountStats: const SettingsAccountStats(
              displayName: 'Lin Wan',
              initials: 'L',
              entryCount: 218,
              localLibraryBytes: 43201331,
            ),
            currentThemeName: _themeName,
            currentMode: _mode,
            appLockEnabled: _appLockEnabled,
            draftRecoveryEnabled: _draftRecoveryEnabled,
            onPickTheme: (value) {
              setState(() {
                _themeName = value;
              });
            },
            onPickMode: (value) {
              setState(() {
                _mode = value;
              });
            },
            onAppLockChanged: (value) {
              setState(() {
                _appLockEnabled = value;
              });
            },
            onDraftRecoveryChanged: (value) {
              setState(() {
                _draftRecoveryEnabled = value;
              });
            },
            onTapBackup: () => _showUnavailable(context),
            onTapExport: () => _showUnavailable(context),
            onBack: () => Navigator.maybePop(context),
          );
        },
      ),
    );
  }

  DayzThemeType get _themeType {
    return switch (_themeName) {
      'amber' => DayzThemeType.amber,
      'sage' => DayzThemeType.sage,
      _ => DayzThemeType.purple,
    };
  }

  Brightness get _brightness {
    return switch (_mode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
  }

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).settingsActionUnavailableToast,
          ),
        ),
      );
  }
}
