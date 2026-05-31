// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/shell/app_router.dart';
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
    final l10n = AppLocalizations.of(context);
    final totalCount =
        allJournalCount ??
        journals.fold<int>(0, (sum, journal) => sum + journal.count);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottom = bottomPadding > 0
        ? bottomPadding * 0.6
        : DayzSpacing.s3;

    return Drawer(
      backgroundColor: colors.bg,
      width: (MediaQuery.sizeOf(context).width * 0.85).clamp(0.0, 320.0),
      child: SafeArea(
        bottom: false,
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
                    _buildSectionHeader(context, l10n.newJournal, onNewJournal),

                    // "All Journals" sentinel row
                    _buildDrawerItem(
                      context: context,
                      label: l10n.allJournals,
                      isSelected: currentJournalId == null,
                      onTap: () => onSelectJournal(null),
                      iconPath: DayzIcons.notebookPath,
                      count: totalCount,
                    ),

                    // Active journals
                    ...journals.map((journal) {
                      return _buildDrawerItem(
                        context: context,
                        label: journal.name,
                        isSelected: currentJournalId == journal.id,
                        onTap: () => onSelectJournal(journal.id),
                        count: journal.count,
                        leading: _buildColorDot(journal.color),
                      );
                    }),

                    const SizedBox(height: DayzSpacing.s2),
                    Divider(height: 1, thickness: 1, color: colors.hairline),

                    // --- Group 2: Browse ---
                    const SizedBox(height: DayzSpacing.s2),
                    _buildSectionLabel(context, l10n.browseSectionHeader),
                    _buildDrawerItem(
                      context: context,
                      label: l10n.onThisDay,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.onthisday),
                      iconPath: DayzIcons.historyClockPath,
                    ),
                    _buildDrawerItem(
                      context: context,
                      label: l10n.favorites,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.favorites),
                      iconPath: DayzIcons.favoriteStarPath,
                      count: favoriteCount,
                    ),
                    _buildDrawerItem(
                      context: context,
                      label: l10n.calendar,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.calendar),
                      iconPath: DayzIcons.calendarPath,
                    ),
                    _buildDrawerItem(
                      context: context,
                      label: l10n.trash,
                      isSelected: false,
                      onTap: () => onNavigate(Routes.trash),
                      iconPath: DayzIcons.trashPath,
                    ),
                  ],
                ),
              ),
            ),

            // --- Group 3: Settings ---
            Divider(height: 1, thickness: 1, color: colors.hairline),
            Padding(
              padding: EdgeInsets.fromLTRB(
                DayzSpacing.s3,
                DayzSpacing.s2,
                DayzSpacing.s3,
                computedBottom,
              ),
              child: _buildDrawerItem(
                context: context,
                label: l10n.settings,
                isSelected: false,
                onTap: () => onNavigate(Routes.settings),
                iconPath: DayzIcons.settingsPath,
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
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s5,
        DayzSpacing.s5,
        DayzSpacing.s5,
        DayzSpacing.s4,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(DayzRadii.full),
            ),
            child: Text(
              l10n.drawerProfileInitial,
              style: textTheme.h3.copyWith(
                color: colors.accentInk,
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: DayzSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.drawerProfileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.body.copyWith(
                    color: colors.ink,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.drawerProfileStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.caption.copyWith(
                    color: colors.ink3,
                    fontSize: 12.0,
                  ),
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
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s5,
        DayzSpacing.s2,
        DayzSpacing.s3,
        DayzSpacing.s2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildSectionLabel(
              context,
              l10n.journalSectionHeader,
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
                    width: 15,
                    height: 15,
                    colorFilter: ColorFilter.mode(
                      colors.ink3,
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
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(
      DayzSpacing.s5,
      DayzSpacing.s4,
      DayzSpacing.s5,
      DayzSpacing.s2,
    ),
  }) {
    final colors = context.dayz;
    final textTheme = context.dayzText;

    return Padding(
      padding: padding,
      child: Text(
        label,
        style: textTheme.caption.copyWith(
          color: colors.ink3,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.32,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? iconPath,
    Widget? leading,
    int? count,
  }) {
    final colors = context.dayz;
    final textTheme = context.dayzText;
    final l10n = AppLocalizations.of(context);

    Widget? actualLeading = leading;
    if (iconPath != null) {
      actualLeading = _buildSvgIcon(
        iconPath,
        isSelected ? colors.accentInk : colors.ink2,
      );
    }

    if (actualLeading != null) {
      actualLeading = SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: actualLeading,
        ),
      );
    }

    Widget? trailing;
    if (count != null) {
      trailing = Text(
        l10n.entryCount(count),
        style: textTheme.caption.copyWith(
          color: isSelected ? colors.accentInk : colors.ink3,
          fontSize: 12.0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DayzSpacing.s3,
        vertical: 2.0,
      ),
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: SizedBox(
            height: 44,
            child: Material(
              color: isSelected ? colors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(DayzRadii.sm),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  if (isSelected)
                    PositionedDirectional(
                      start: -3,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (actualLeading != null) ...[
                            actualLeading,
                            const SizedBox(width: DayzSpacing.s3),
                          ],
                          Expanded(
                            child: Text(
                              label,
                              style: textTheme.body.copyWith(
                                fontSize: 15.0,
                                color: isSelected
                                    ? colors.accentInk
                                    : colors.ink,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (trailing != null) trailing,
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
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
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
