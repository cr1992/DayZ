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
import 'package:dayz/ui/widgets/dayz_search_field.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

/// The layout shell for DayZ pages containing shared drawer, glass app bar, and FAB.
///
/// Author: @Ray
class AppShell extends StatefulWidget {
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
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isSearching = false;
  bool _renderSearch = false;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final route = widget.currentRoute ?? _getRouteName(context);

    return Scaffold(
      backgroundColor: colors.bg,
      drawer: ShellDrawer(
        journals: widget.journals,
        currentJournalId: widget.currentJournalId,
        allJournalCount: widget.allJournalCount,
        favoriteCount: widget.favoriteCount,
        onSelectJournal: widget.onSelectJournal,
        onNavigate: widget.onNavigate,
        onNewJournal: widget.onNewJournal,
      ),
      floatingActionButton: const FabSpeedDial(),
      drawerEnableOpenDragGesture: !disableAnimations,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            DayzGlassAppBar(
              isSearching: _isSearching,
              searchWidget: _renderSearch
                  ? DayzSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hintText: l10n.searchHint,
                      onCancel: () {
                        setState(() {
                          _isSearching = false;
                        });
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted && !_isSearching) {
                            setState(() {
                              _renderSearch = false;
                            });
                          }
                        });
                      },
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          widget.onNavigate(Routes.search);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              setState(() {
                                _isSearching = false;
                              });
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (mounted && !_isSearching) {
                                  setState(() {
                                    _renderSearch = false;
                                  });
                                }
                              });
                            }
                          });
                        }
                      },
                    )
                  : null,
              title: Text(_getTitle(route, l10n)),
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
                _buildActionButton(
                  label: l10n.search,
                  path: DayzIcons.searchPath,
                  colors: colors,
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                      _renderSearch = true;
                    });
                    _searchFocusNode.requestFocus();
                  },
                ),
                if (route == Routes.timeline) ...[
                  const SizedBox(width: 6.0),
                  _buildActionButton(
                    label: l10n.onThisDay,
                    path: DayzIcons.historyClockPath,
                    colors: colors,
                    onPressed: () => widget.onNavigate(Routes.onthisday),
                  ),
                ],
              ],
            ),
          ];
        },
        body: SafeArea(
          top: false, // NestedScrollView handles top padding
          bottom: true,
          child: widget.body,
        ),
      ),
    );
  }

  String _getTitle(String? route, AppLocalizations l10n) {
    switch (route) {
      case Routes.timeline:
        return '';
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

  Widget _buildActionButton({
    required String label,
    required String path,
    required DayzColors colors,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          tooltip: label,
          icon: SvgPicture.string(
            _svg(path),
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.ink, BlendMode.srcIn),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  String? _getRouteName(BuildContext context) {
    try {
      return GoRouterState.of(context).topRoute?.name ??
          GoRouterState.of(context).name;
    } catch (_) {
      return null;
    }
  }

  String _svg(String path) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
  }
}
