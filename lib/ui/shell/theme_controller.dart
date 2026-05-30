// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';

/// Choice container representing the selected theme configuration.
///
/// Author: @Ray
class DayzThemeChoice {
  final String themeName;
  final ThemeMode mode;
  final bool paper;

  const DayzThemeChoice({
    required this.themeName,
    required this.mode,
    required this.paper,
  });

  DayzThemeChoice copyWith({
    String? themeName,
    ThemeMode? mode,
    bool? paper,
  }) {
    return DayzThemeChoice(
      themeName: themeName ?? this.themeName,
      mode: mode ?? this.mode,
      paper: paper ?? this.paper,
    );
  }
}

/// Controller managing the application theme and appearance settings.
///
/// Author: @Ray
class ThemeController extends ChangeNotifier {
  DayzThemeChoice _choice;

  ThemeController({
    DayzThemeChoice initialChoice = const DayzThemeChoice(
      themeName: 'purple',
      mode: ThemeMode.system,
      paper: false,
    ),
  }) : _choice = initialChoice;

  DayzThemeChoice get choice => _choice;

  ThemeMode get themeMode => _choice.mode;

  /// Returns light [ThemeData] mapped from current choice.
  ThemeData get materialTheme => dayzTheme(_themeTypeFromName(_choice.themeName), Brightness.light);

  /// Returns dark [ThemeData] mapped from current choice.
  ThemeData get materialDarkTheme => dayzTheme(_themeTypeFromName(_choice.themeName), Brightness.dark);

  /// Update active theme name and notify.
  void setTheme(String name) {
    if (_choice.themeName == name) return;
    _choice = _choice.copyWith(themeName: name);
    _savePreferences();
    notifyListeners();
  }

  /// Update active mode and notify.
  void setMode(ThemeMode mode) {
    if (_choice.mode == mode) return;
    _choice = _choice.copyWith(mode: mode);
    _savePreferences();
    notifyListeners();
  }

  /// Update active paper appearance and notify.
  void setPaper(bool value) {
    if (_choice.paper == value) return;
    _choice = _choice.copyWith(paper: value);
    _savePreferences();
    notifyListeners();
  }

  /// Helper to convert string themeName to [DayzThemeType].
  DayzThemeType _themeTypeFromName(String name) {
    switch (name.toLowerCase()) {
      case 'amber':
        return DayzThemeType.amber;
      case 'sage':
        return DayzThemeType.sage;
      case 'purple':
      default:
        return DayzThemeType.purple;
    }
  }

  /// Stubs for database preference persistence hook.
  void _savePreferences() {
    // TODO: Connect to data-layer setting/preference repository when ready.
  }
}
