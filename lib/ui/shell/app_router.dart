// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/timeline_host.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/ui/shell/app_shell.dart';
import 'package:dayz/ui/shell/new_journal_sheet.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/shell/shell_state.dart';
import 'placeholder_screen.dart';

/// Route identifiers alignment with pages.
///
/// Author: @Ray
abstract final class Routes {
  static const String timeline = 'timeline';
  static const String reader = 'reader';
  static const String editor = 'editor';
  static const String onthisday = 'onthisday';
  static const String search = 'search';
  static const String settings = 'settings';
  static const String calendar = 'calendar';
  static const String favorites = 'favorites';
  static const String trash = 'trash';
  static const String memory = 'memory';
  static const String debugHome = 'debugHome';

  static const String timelinePath = '/timeline';
  static const String readerPath = '/reader';
  static const String editorPath = '/editor';
  static const String onthisdayPath = '/onthisday';
  static const String searchPath = '/search';
  static const String settingsPath = '/settings';
  static const String calendarPath = '/calendar';
  static const String favoritesPath = '/favorites';
  static const String trashPath = '/trash';
  static const String memoryPath = '/memory';
  static const String debugHomePath = '/debugHome';
}

/// Global shared state container for the shell.
final ShellState shellState = ShellState();

/// 自带 sliver 顶栏的页面路径；装配了真实页面时外壳不再叠加顶栏。
const Set<String> _routesWithOwnAppBar = {Routes.timelinePath};

/// The global routing configuration for the DayZ application.
///
/// Author: @Ray
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.timelinePath,
  errorBuilder: (context, state) =>
      PlaceholderScreen(titleBuilder: (l10n) => l10n.notFound),
  routes: [
    // Shell bounded routes
    ShellRoute(
      builder: (context, state, child) {
        final services = AppServicesScope.maybeOf(context);
        return _ShellJournalsHydrator(
          services: services,
          child: ListenableBuilder(
            listenable: shellState,
            builder: (context, _) {
              return AppShell(
                body: child,
                journals: shellState.journals,
                currentJournalId: shellState.currentJournalId,
                pageOwnsAppBar:
                    services != null &&
                    _routesWithOwnAppBar.contains(state.uri.path),
                onSelectJournal: (id) => shellState.selectJournal(id),
                onNavigate: (route) => context.pushNamed(route),
                onNewJournal: () {
                  showNewJournalSheet(
                    context,
                    onSubmit: (name, color) {
                      if (services != null) {
                        services.createJournal(
                          shellState,
                          name: name,
                          color: color,
                        );
                        return;
                      }
                      shellState.addJournal(
                        JournalSummary(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          color: color,
                          count: 0,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
      routes: [
        GoRoute(
          name: Routes.timeline,
          path: Routes.timelinePath,
          builder: (context, state) {
            final services = AppServicesScope.maybeOf(context);
            if (services == null) {
              return PlaceholderScreen(titleBuilder: (l10n) => l10n.timeline);
            }
            return ListenableBuilder(
              listenable: shellState,
              builder: (context, _) => TimelineHost(
                repo: services.timelineRepo,
                journalId: shellState.currentJournalId,
                contentRevision: services.contentRevision,
              ),
            );
          },
        ),
        GoRoute(
          name: Routes.reader,
          path: Routes.readerPath,
          builder: (context, state) =>
              PlaceholderScreen(titleBuilder: (l10n) => l10n.reader),
        ),
        GoRoute(
          name: Routes.onthisday,
          path: Routes.onthisdayPath,
          builder: (context, state) =>
              PlaceholderScreen(titleBuilder: (l10n) => l10n.onThisDay),
        ),
        GoRoute(
          name: Routes.settings,
          path: Routes.settingsPath,
          builder: (context, state) =>
              PlaceholderScreen(titleBuilder: (l10n) => l10n.settings),
        ),
        GoRoute(
          name: Routes.calendar,
          path: Routes.calendarPath,
          builder: (context, state) =>
              PlaceholderScreen(titleBuilder: (l10n) => l10n.calendar),
        ),
        GoRoute(
          name: Routes.favorites,
          path: Routes.favoritesPath,
          builder: (context, state) =>
              PlaceholderScreen(titleBuilder: (l10n) => l10n.favorites),
        ),
        GoRoute(
          name: Routes.trash,
          path: Routes.trashPath,
          builder: (context, state) =>
              PlaceholderScreen(titleBuilder: (l10n) => l10n.trash),
        ),
        GoRoute(
          name: Routes.memory,
          path: Routes.memoryPath,
          builder: (context, state) =>
              PlaceholderScreen(titleBuilder: (l10n) => l10n.memoryCardExport),
        ),
      ],
    ),
    // Bounded-free standalone routes
    GoRoute(
      name: Routes.editor,
      path: Routes.editorPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.editor,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.search,
      path: Routes.searchPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.search,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.debugHome,
      path: Routes.debugHomePath,
      builder: (context, state) => const DebugHome(),
    ),
  ],
);

/// 组合根就绪后，从库水合一次抽屉日记本列表。
class _ShellJournalsHydrator extends StatefulWidget {
  const _ShellJournalsHydrator({required this.services, required this.child});

  final AppServices? services;
  final Widget child;

  @override
  State<_ShellJournalsHydrator> createState() => _ShellJournalsHydratorState();
}

class _ShellJournalsHydratorState extends State<_ShellJournalsHydrator> {
  @override
  void initState() {
    super.initState();
    widget.services?.refreshJournals(shellState);
  }

  @override
  void didUpdateWidget(_ShellJournalsHydrator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.services, widget.services)) {
      widget.services?.refreshJournals(shellState);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
