// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../components.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'settings_icons.dart';

/// Account summary injected into the settings screen.
///
/// Author: @Ray
class SettingsAccountStats {
  const SettingsAccountStats({
    required this.displayName,
    required this.initials,
    required this.entryCount,
    required this.localLibraryBytes,
  });

  final String displayName;
  final String initials;
  final int entryCount;
  final int localLibraryBytes;
}

/// Token-driven settings screen assembled from ui-kit components.
///
/// Author: @Ray
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.accountStats,
    required this.currentThemeName,
    required this.currentMode,
    required this.appLockEnabled,
    required this.draftRecoveryEnabled,
    required this.onPickTheme,
    required this.onPickMode,
    required this.onAppLockChanged,
    required this.onDraftRecoveryChanged,
    required this.onTapBackup,
    required this.onTapExport,
    this.onBack,
  });

  static const Key backButtonKey = ValueKey<String>('settings-back-button');
  static const Key appLockRowKey = ValueKey<String>('settings-app-lock-row');
  static const Key databaseEncryptionRowKey = ValueKey<String>(
    'settings-database-encryption-row',
  );
  static const Key backupRowKey = ValueKey<String>('settings-backup-row');
  static const Key exportRowKey = ValueKey<String>('settings-export-row');
  static const Key themeRowKey = ValueKey<String>('settings-theme-row');
  static const Key modeRowKey = ValueKey<String>('settings-mode-row');
  static const Key draftRecoveryRowKey = ValueKey<String>(
    'settings-draft-recovery-row',
  );

  final SettingsAccountStats accountStats;
  final String currentThemeName;
  final ThemeMode currentMode;
  final bool appLockEnabled;
  final bool draftRecoveryEnabled;
  final ValueChanged<String> onPickTheme;
  final ValueChanged<ThemeMode> onPickMode;
  final ValueChanged<bool> onAppLockChanged;
  final ValueChanged<bool> onDraftRecoveryChanged;
  final VoidCallback onTapBackup;
  final VoidCallback onTapExport;
  final VoidCallback? onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _themeName = widget.currentThemeName;
  late ThemeMode _mode = widget.currentMode;

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeName != widget.currentThemeName) {
      _themeName = widget.currentThemeName;
    }
    if (oldWidget.currentMode != widget.currentMode) {
      _mode = widget.currentMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;

    return Scaffold(
      backgroundColor: colors.bg,
      body: CustomScrollView(
        slivers: [
          DayzGlassAppBar(
            leading: _BackButton(
              key: SettingsScreen.backButtonKey,
              label: l10n.settingsBackSemanticLabel,
              onPressed: widget.onBack ?? () => _defaultBack(context),
            ),
            title: Text(l10n.settingsTitle),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DayzSpacing.s4,
                DayzSpacing.s3,
                DayzSpacing.s4,
                DayzSpacing.s8,
              ),
              child: _SettingsBody(
                accountCard: DayzSetAccountCard(
                  title: widget.accountStats.displayName,
                  initials: widget.accountStats.initials,
                  subtitle: l10n.settingsAccountStats(
                    widget.accountStats.entryCount,
                    _formatLibrarySize(widget.accountStats.localLibraryBytes),
                  ),
                ),
                groups: [
                  DayzSetGroup(
                    label: l10n.settingsGroupPrivacy,
                    children: [
                      DayzSetRow(
                        key: SettingsScreen.appLockRowKey,
                        icon: const _SettingsIcon(SettingsIcons.appLockPath),
                        title: l10n.settingsAppLockTitle,
                        subtitle: l10n.settingsAppLockSubtitle,
                        trailing: DayzSwitch(
                          value: widget.appLockEnabled,
                          semanticLabel: l10n.settingsAppLockSemanticLabel,
                          onChanged: widget.onAppLockChanged,
                        ),
                        onTap: () =>
                            widget.onAppLockChanged(!widget.appLockEnabled),
                      ),
                      DayzSetRow(
                        key: SettingsScreen.databaseEncryptionRowKey,
                        icon: const _SettingsIcon(
                          SettingsIcons.databaseEncryptedPath,
                        ),
                        title: l10n.settingsDbEncryptionTitle,
                        subtitle: l10n.settingsDbEncryptionSubtitle,
                        value: l10n.settingsDbEncryptedValue,
                      ),
                      _MediaRedlineRow(
                        text: l10n.settingsMediaNotLockedByPassword,
                      ),
                    ],
                  ),
                  DayzSetGroup(
                    label: l10n.settingsGroupBackup,
                    children: [
                      DayzSetRow(
                        key: SettingsScreen.backupRowKey,
                        icon: const _SettingsIcon(SettingsIcons.backupPath),
                        title: l10n.settingsBackupTitle,
                        subtitle: l10n.settingsBackupSubtitle,
                        showChevron: true,
                        onTap: widget.onTapBackup,
                      ),
                      DayzSetRow(
                        key: SettingsScreen.exportRowKey,
                        icon: const _SettingsIcon(SettingsIcons.exportPath),
                        title: l10n.settingsExportTitle,
                        subtitle: l10n.settingsExportSubtitle,
                        showChevron: true,
                        onTap: widget.onTapExport,
                      ),
                    ],
                  ),
                  DayzSetGroup(
                    label: l10n.settingsGroupAppearance,
                    children: [
                      DayzSetRow(
                        key: SettingsScreen.themeRowKey,
                        icon: const _SettingsIcon(SettingsIcons.themePath),
                        title: l10n.settingsThemeTitle,
                        subtitle: l10n.settingsThemeSubtitle,
                        value: _themeLabel(l10n, _themeName),
                        trailing: _ThemeDot(themeName: _themeName),
                        showChevron: true,
                        onTap: () => _showThemePicker(context),
                      ),
                      DayzSetRow(
                        key: SettingsScreen.modeRowKey,
                        icon: const _SettingsIcon(SettingsIcons.appearancePath),
                        title: l10n.settingsAppearanceModeTitle,
                        subtitle: l10n.settingsAppearanceModeSubtitle,
                        value: _modeLabel(l10n, _mode),
                        showChevron: true,
                        onTap: () => _showModePicker(context),
                      ),
                    ],
                  ),
                  DayzSetGroup(
                    label: l10n.settingsGroupWriting,
                    children: [
                      DayzSetRow(
                        key: SettingsScreen.draftRecoveryRowKey,
                        icon: const _SettingsIcon(
                          SettingsIcons.draftRecoveryPath,
                        ),
                        title: l10n.settingsDraftRecoveryTitle,
                        subtitle: l10n.settingsDraftRecoverySubtitle,
                        trailing: DayzSwitch(
                          value: widget.draftRecoveryEnabled,
                          semanticLabel:
                              l10n.settingsDraftRecoverySemanticLabel,
                          onChanged: widget.onDraftRecoveryChanged,
                        ),
                        onTap: () => widget.onDraftRecoveryChanged(
                          !widget.draftRecoveryEnabled,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    DayzSheet.picker<void>(
      context,
      items: [
        _themeItem(l10n.settingsThemePurple, 'purple'),
        _themeItem(l10n.settingsThemeAmber, 'amber'),
        _themeItem(l10n.settingsThemeSage, 'sage'),
      ],
    );
  }

  DayzSheetItem _themeItem(String label, String themeName) {
    return DayzSheetItem(
      label: label,
      swatch: _themeSwatch(themeName),
      selected: _themeName == themeName,
      onTap: () {
        setState(() {
          _themeName = themeName;
        });
        widget.onPickTheme(themeName);
      },
    );
  }

  void _showModePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    DayzSheet.picker<void>(
      context,
      items: [
        _modeItem(l10n.settingsModeSystem, ThemeMode.system),
        _modeItem(l10n.settingsModeLight, ThemeMode.light),
        _modeItem(l10n.settingsModeDark, ThemeMode.dark),
      ],
    );
  }

  DayzSheetItem _modeItem(String label, ThemeMode mode) {
    return DayzSheetItem(
      label: label,
      selected: _mode == mode,
      onTap: () {
        setState(() {
          _mode = mode;
        });
        widget.onPickMode(mode);
      },
    );
  }

  void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.accountCard, required this.groups});

  final Widget accountCard;
  final List<Widget> groups;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              accountCard,
              const SizedBox(height: DayzSpacing.s4),
              for (var index = 0; index < groups.length; index += 1) ...[
                if (index > 0) const SizedBox(height: DayzSpacing.s4),
                groups[index],
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            accountCard,
            const SizedBox(height: DayzSpacing.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      groups[0],
                      const SizedBox(height: DayzSpacing.s4),
                      groups[2],
                    ],
                  ),
                ),
                const SizedBox(width: DayzSpacing.s4),
                Expanded(
                  child: Column(
                    children: [
                      groups[1],
                      const SizedBox(height: DayzSpacing.s4),
                      groups[3],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(Icons.chevron_left_rounded, color: colors.ink),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.path);

  final String path;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg(path),
      width: 18,
      height: 18,
      colorFilter: ColorFilter.mode(context.dayz.accentInk, BlendMode.srcIn),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({required this.themeName});

  final String themeName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _themeSwatch(themeName),
        shape: BoxShape.circle,
        border: Border.all(color: context.dayz.hairline2),
      ),
      child: const SizedBox.square(dimension: 12),
    );
  }
}

class _MediaRedlineRow extends StatelessWidget {
  const _MediaRedlineRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final typography = context.dayzText;

    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DayzSpacing.s4,
            vertical: DayzSpacing.s3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SmallInfoMark(),
              const SizedBox(width: DayzSpacing.s3),
              Expanded(
                child: Text(
                  text,
                  style: typography.caption.copyWith(
                    color: colors.ink3,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallInfoMark extends StatelessWidget {
  const _SmallInfoMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    return SizedBox.square(
      dimension: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.accentSoft,
          borderRadius: BorderRadius.circular(DayzRadii.sm),
        ),
        child: Icon(
          Icons.info_outline_rounded,
          size: 17,
          color: colors.accentInk,
        ),
      ),
    );
  }
}

String _formatLibrarySize(int bytes) {
  final megabytes = bytes / 1024 / 1024;
  return '${NumberFormat('0.0').format(megabytes)} MB';
}

String _themeLabel(AppLocalizations l10n, String themeName) {
  return switch (themeName) {
    'amber' => l10n.settingsThemeAmber,
    'sage' => l10n.settingsThemeSage,
    _ => l10n.settingsThemePurple,
  };
}

String _modeLabel(AppLocalizations l10n, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => l10n.settingsModeLight,
    ThemeMode.dark => l10n.settingsModeDark,
    ThemeMode.system => l10n.settingsModeSystem,
  };
}

Color _themeSwatch(String themeName) {
  return switch (themeName) {
    'amber' => DayzTokens.amberLightAccent,
    'sage' => DayzTokens.sageLightAccent,
    _ => DayzTokens.purpleLightAccent,
  };
}

String _svg(String path) {
  return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
      'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" '
      'xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
}
