// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/ui/shell/app_shell.dart';
import 'package:dayz/ui/shell/new_journal_sheet.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/shell/shell_state.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';
import 'placeholder_screen.dart';
import 'package:dayz/ui/editor/editor_screen.dart';

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

// Global shared state container for the shell.
final ShellState shellState = ShellState();
dynamic _timelineEntryRepo;
dynamic _draftCoordinator;
dynamic _mediaStore;
dynamic _mediaRepo;

void registerTimelineEntryRepo(dynamic repo) {
  _timelineEntryRepo = repo;
}

void registerEditorServices({
  dynamic draftCoordinator,
  dynamic mediaStore,
  dynamic mediaRepo,
}) {
  _draftCoordinator = draftCoordinator;
  _mediaStore = mediaStore;
  _mediaRepo = mediaRepo;
}

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
        return ListenableBuilder(
          listenable: shellState,
          builder: (context, _) {
            return AppShell(
              body: child,
              journals: shellState.journals,
              currentJournalId: shellState.currentJournalId,
              currentRoute: state.topRoute?.name ?? state.name,
              onSelectJournal: (id) => shellState.selectJournal(id),
              onNavigate: (route) => context.pushNamed(route),
              onNewJournal: () {
                showNewJournalSheet(
                  context,
                  onSubmit: (name, color) {
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
        );
      },
      routes: [
        GoRoute(
          name: Routes.timeline,
          path: Routes.timelinePath,
          builder: (context, state) {
            final repo = _timelineEntryRepo;
            if (repo == null) {
              return PlaceholderScreen(titleBuilder: (l10n) => l10n.timeline);
            }
            return TimelineShellPage(repo: repo, shellState: shellState);
          },
        ),
      ],
    ),
    // Bounded-free standalone routes
    GoRoute(
      name: Routes.reader,
      path: Routes.readerPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.reader,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.onthisday,
      path: Routes.onthisdayPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.onThisDay,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.settings,
      path: Routes.settingsPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.settings,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.calendar,
      path: Routes.calendarPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.calendar,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.favorites,
      path: Routes.favoritesPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.favorites,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.trash,
      path: Routes.trashPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.trash,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.memory,
      path: Routes.memoryPath,
      builder: (context, state) => PlaceholderScreen(
        titleBuilder: (l10n) => l10n.memoryCardExport,
        showAppBar: true,
      ),
    ),
    GoRoute(
      name: Routes.editor,
      path: Routes.editorPath,
      builder: (context, state) {
        final rawExtra = state.extra;
        // Tolerate any extra shape: a Map (the structured contract), a bare
        // String (e.g. an entryId from a caller that predates the Map
        // contract), or null. A blind `as Map` cast throws _TypeError on a
        // String and drops the user on an error screen, so normalize instead.
        final extra = rawExtra is Map
            ? Map<String, dynamic>.from(rawExtra)
            : <String, dynamic>{};
        if (rawExtra is String && rawExtra.isNotEmpty) {
          extra['entryId'] ??= rawExtra;
          extra['mode'] ??= EditorScreenMode.writing;
        }
        final mode = extra['mode'] as EditorScreenMode? ?? EditorScreenMode.empty;
        final entryDate = extra['entryDate'] as DateTime? ?? DateTime.now();
        final title = extra['title'] as String?;
        final bodyPreview = extra['bodyPreview'] as String?;
        final entryId = extra['entryId'] as String? ??
            (mode == EditorScreenMode.empty ? 'new_${DateTime.now().millisecondsSinceEpoch}' : null);
        final initialContentJson = extra['initialContentJson'] as String?;
        final draftCoordinator = extra['draftCoordinator'] ?? _draftCoordinator;
        final entryRepo = extra['entryRepo'] ?? _timelineEntryRepo;
        final mediaStore = extra['mediaStore'] ?? _mediaStore;
        final mediaRepo = extra['mediaRepo'] ?? _mediaRepo;
        
        return EditorScreen(
          mode: mode,
          entryDate: entryDate,
          title: title,
          bodyPreview: bodyPreview,
          entryId: entryId,
          initialContentJson: initialContentJson,
          draftCoordinator: draftCoordinator,
          entryRepo: entryRepo,
          mediaStore: mediaStore,
          mediaRepo: mediaRepo,
        );
      },
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
