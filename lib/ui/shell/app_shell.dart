// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/shell/fab_speed_dial.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

/// The layout shell for DayZ pages containing shared drawer, glass app bar, and FAB.
///
/// Author: @Ray
class AppShell extends StatelessWidget {
  final Widget body;
  final List<JournalSummary> journals;
  final String? currentJournalId;
  final int? allJournalCount;
  final int? favoriteCount;
  final String? currentRoute;
  final ValueChanged<String?> onSelectJournal;
  final ValueChanged<String> onNavigate;
  final VoidCallback onNewJournal;

  const AppShell({
    required this.body,
    this.journals = const [],
    this.currentJournalId,
    this.allJournalCount,
    this.favoriteCount,
    this.currentRoute,
    required this.onSelectJournal,
    required this.onNavigate,
    required this.onNewJournal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: colors.bg,
      drawer: ShellDrawer(
        journals: journals,
        currentJournalId: currentJournalId,
        allJournalCount: allJournalCount,
        favoriteCount: favoriteCount,
        onSelectJournal: onSelectJournal,
        onNavigate: onNavigate,
        onNewJournal: onNewJournal,
      ),
      floatingActionButton: const FabSpeedDial(),
      drawerEnableOpenDragGesture: !disableAnimations,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            DayzGlassAppBar(
              title: Text(_getTitle(context, l10n)),
              leading: Builder(
                builder: (context) {
                  return Semantics(
                    button: true,
                    label: l10n.menu,
                    child: SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        tooltip: l10n.menu,
                        icon: SvgPicture.string(
                          _svg(DayzIcons.menuPath),
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            colors.ink,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                  );
                },
              ),
              actions: [
                Semantics(
                  button: true,
                  label: l10n.search,
                  child: SizedBox.square(
                    dimension: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      tooltip: l10n.search,
                      icon: SvgPicture.string(
                        _svg(DayzIcons.searchPath),
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          colors.ink,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {
                        context.pushNamed(Routes.search);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
        body: SafeArea(
          top: false, // NestedScrollView handles top padding
          bottom: true,
          child: body,
        ),
      ),
    );
  }

  String _getTitle(BuildContext context, AppLocalizations l10n) {
    final route = currentRoute ?? _getRouteName(context);
    switch (route) {
      case Routes.timeline:
        return l10n.timeline;
      case Routes.reader:
        return l10n.reader;
      case Routes.editor:
        return l10n.editor;
      case Routes.onthisday:
        return l10n.onThisDay;
      case Routes.search:
        return l10n.search;
      case Routes.settings:
        return l10n.settings;
      case Routes.calendar:
        return l10n.calendar;
      case Routes.favorites:
        return l10n.favorites;
      case Routes.trash:
        return l10n.trash;
      case Routes.memory:
        return l10n.memoryCardExport;
      case Routes.debugHome:
        return l10n.debugHome;
      default:
        return '';
    }
  }

  String? _getRouteName(BuildContext context) {
    try {
      return GoRouterState.of(context).name;
    } catch (_) {
      return null;
    }
  }

  String _svg(String path) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
  }
}
