// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/onthisday/onthisday_controller.dart';
import 'package:dayz/ui/onthisday/onthisday_screen.dart';
import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:dayz/ui/settings/settings_screen.dart';
import 'package:dayz/ui/shell/app_shell.dart';
import 'package:dayz/ui/shell/new_journal_sheet.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/shell/shell_state.dart';
import 'package:dayz/ui/shell/theme_controller.dart';
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
ReaderRepository? _readerRepository;
ReaderDataLoader? _readerLoadData;

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

/// Registers the data port behind [Routes.reader]. Until registered the route
/// stays a placeholder (widget tests that pump the bare router rely on this).
void registerReaderRepository(ReaderRepository? repository) {
  _readerRepository = repository;
  // Built once here, not per route build: ReaderScreen reloads whenever the
  // loader's identity changes, and go_router rebuilds this route on every
  // push/pop above it.
  _readerLoadData = repository == null
      ? null
      : (id) => buildReaderViewData(id, repository);
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
        // 组合根（lib/app）就绪时，抽屉日记本来自库、新建日记本落库；
        // 未就绪（库打不开 / 裸路由测试）退回内存列表。
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
                currentRoute: state.topRoute?.name ?? state.name,
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
      builder: (context, state) {
        final repository = _readerRepository;
        final loadData = _readerLoadData;
        final entryId = state.extra;
        if (repository == null ||
            loadData == null ||
            entryId is! String ||
            entryId.isEmpty) {
          return PlaceholderScreen(
            titleBuilder: (l10n) => l10n.reader,
            showAppBar: true,
          );
        }
        return ReaderScreen(
          key: ValueKey<String>('reader-route-$entryId'),
          entryId: entryId,
          repository: repository,
          loadData: loadData,
          onBack: () => context.goNamed(Routes.timeline),
        );
      },
    ),
    GoRoute(
      name: Routes.onthisday,
      path: Routes.onthisdayPath,
      builder: (context, state) {
        final repository = onThisDayRepositoryPort;
        if (repository == null) {
          return PlaceholderScreen(
            titleBuilder: (l10n) => l10n.onThisDay,
            showAppBar: true,
          );
        }
        return OnThisDayPage(
          repository: repository,
          thumbnails: onThisDayThumbnailsPort,
        );
      },
    ),
    GoRoute(
      name: Routes.settings,
      path: Routes.settingsPath,
      builder: (context, state) {
        final themeController = ThemeControllerScope.of(context);
        return SettingsScreen(
          accountStats: const SettingsAccountStats(
            displayName: 'DayZ',
            initials: 'D',
            entryCount: 0,
            localLibraryBytes: 0,
          ),
          currentThemeName: themeController.choice.themeName,
          currentMode: themeController.choice.mode,
          appLockEnabled: false,
          draftRecoveryEnabled: true,
          onPickTheme: themeController.setTheme,
          onPickMode: themeController.setMode,
          onAppLockChanged: (_) => _showSettingsUnavailable(context),
          onDraftRecoveryChanged: (_) => _showSettingsUnavailable(context),
          onTapBackup: () => _showSettingsUnavailable(context),
          onTapExport: () => _showSettingsUnavailable(context),
          onBack: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.goNamed(Routes.timeline);
          },
        );
      },
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

void _showSettingsUnavailable(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).settingsActionUnavailableToast,
        ),
      ),
    );
}

/// 组合根就绪后，从库水合一次抽屉日记本列表（含每本篇数）。
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
