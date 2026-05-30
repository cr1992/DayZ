// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

/// Representation of a journal summary in the shell drawer.
class JournalSummary {
  final String id;
  final String name;
  final String? color;
  final int count;

  const JournalSummary({
    required this.id,
    required this.name,
    this.color,
    required this.count,
  });
}

/// Navigation drawer.
///
/// Author: @Ray
class ShellDrawer extends StatelessWidget {
  final List<JournalSummary> journals;
  final String? currentJournalId;
  final int? allJournalCount;
  final int? favoriteCount;
  final ValueChanged<String?> onSelectJournal;
  final ValueChanged<String> onNavigate;
  final VoidCallback onNewJournal;

  const ShellDrawer({
    required this.journals,
    required this.currentJournalId,
    this.allJournalCount,
    this.favoriteCount,
    required this.onSelectJournal,
    required this.onNavigate,
    required this.onNewJournal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textTheme = context.dayzText;
    final totalCount =
        allJournalCount ??
        journals.fold<int>(0, (sum, journal) => sum + journal.count);

    return Drawer(
      backgroundColor: colors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Group 1: Journals ---
                    _buildSectionHeader(
                      context,
                      AppStrings.newJournal,
                      onNewJournal,
                    ),

                    // "All Journals" sentinel row
                    _buildDrawerItem(
                      context: context,
                      label: AppStrings.allJournals,
                      isSelected: currentJournalId == null,
                      onTap: () => onSelectJournal(null),
                      leading: _buildSvgIcon(
                        DayzIcons.notebookPath,
                        colors.ink,
                      ),
                      trailing: Text(
                        AppStrings.entryCount(totalCount),
                        style: textTheme.caption.copyWith(color: colors.ink3),
                      ),
                    ),

                    // Active journals
                    ...journals.map((journal) {
                      return _buildDrawerItem(
                        context: context,
                        label: journal.name,
                        isSelected: currentJournalId == journal.id,
                        onTap: () => onSelectJournal(journal.id),
                        trailing: Text(
                          AppStrings.entryCount(journal.count),
                          style: textTheme.caption.copyWith(color: colors.ink3),
                        ),
                        leading: _buildColorDot(journal.color),
                      );
                    }),

                    const SizedBox(height: DayzSpacing.s2),
                    const Divider(height: 1, thickness: 0.5),

                    // --- Group 2: Browse ---
                    const SizedBox(height: DayzSpacing.s2),
                    _buildSectionLabel(context, AppStrings.browseSectionHeader),
                    _buildDrawerItem(
                      context: context,
                      label: AppStrings.onThisDay,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.onthisday),
                      leading: _buildSvgIcon(
                        DayzIcons.historyClockPath,
                        colors.ink,
                      ),
                    ),
                    _buildDrawerItem(
                      context: context,
                      label: AppStrings.favorites,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.favorites),
                      leading: _buildSvgIcon(
                        DayzIcons.favoriteStarPath,
                        colors.ink,
                      ),
                      trailing: favoriteCount == null
                          ? null
                          : Text(
                              AppStrings.entryCount(favoriteCount!),
                              style: textTheme.caption.copyWith(
                                color: colors.ink3,
                              ),
                            ),
                    ),
                    _buildDrawerItem(
                      context: context,
                      label: AppStrings.calendar,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.calendar),
                      leading: _buildSvgIcon(
                        DayzIcons.calendarPath,
                        colors.ink,
                      ),
                    ),
                    _buildDrawerItem(
                      context: context,
                      label: AppStrings.trash,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.trash),
                      leading: _buildSvgIcon(DayzIcons.trashPath, colors.ink),
                    ),
                  ],
                ),
              ),
            ),

            // --- Group 3: Settings ---
            const Divider(height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DayzSpacing.s2),
              child: _buildDrawerItem(
                context: context,
                label: AppStrings.settings,
                isSelected: false,
                onTap: () => onNavigate(Routes.settings),
                leading: _buildSvgIcon(DayzIcons.settingsPath, colors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final colors = context.dayz;
    final textTheme = context.dayzText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s5,
        DayzSpacing.s4,
        DayzSpacing.s5,
        DayzSpacing.s5,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(DayzRadii.full),
              boxShadow: colors.shadowSm,
            ),
            child: Text(
              AppStrings.drawerProfileInitial,
              style: textTheme.h3.copyWith(color: colors.onAccent),
            ),
          ),
          const SizedBox(width: DayzSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.drawerProfileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.body.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppStrings.drawerProfileStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.caption.copyWith(color: colors.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String actionText,
    VoidCallback onAction,
  ) {
    final colors = context.dayz;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DayzSpacing.s4,
        vertical: DayzSpacing.s2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildSectionLabel(
              context,
              AppStrings.journalSectionHeader,
              padding: EdgeInsets.zero,
            ),
          ),
          Semantics(
            button: true,
            label: actionText,
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  icon: SvgPicture.string(
                    _svg(DayzIcons.plusPath),
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      colors.accent,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAction();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String label, {
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: DayzSpacing.s4,
      vertical: DayzSpacing.s1,
    ),
  }) {
    final colors = context.dayz;
    final textTheme = context.dayzText;

    return Padding(
      padding: padding,
      child: Text(
        label,
        style: textTheme.caption.copyWith(
          color: colors.ink2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? leading,
    Widget? trailing,
  }) {
    final colors = context.dayz;
    final textTheme = context.dayzText;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DayzSpacing.s2,
        vertical: 2.0,
      ),
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: SizedBox(
            height: 48,
            child: Material(
              color: isSelected ? colors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(DayzRadii.sm),
              child: Stack(
                children: [
                  if (isSelected)
                    PositionedDirectional(
                      start: 0,
                      top: 9,
                      bottom: 9,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(DayzRadii.full),
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onTap();
                    },
                    borderRadius: BorderRadius.circular(DayzRadii.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DayzSpacing.s3,
                      ),
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            leading,
                            const SizedBox(width: DayzSpacing.s3),
                          ],
                          Expanded(
                            child: Text(
                              label,
                              style: textTheme.body.copyWith(
                                color: isSelected
                                    ? colors.accentStrong
                                    : colors.ink,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(String? colorStr) {
    final color = _parseColor(colorStr) ?? Colors.transparent;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: colorStr == null
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
    );
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    final hex = colorStr.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return null;
  }

  Widget _buildSvgIcon(String path, Color color) {
    return SvgPicture.string(
      _svg(path),
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  String _svg(String path) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
  }
}
