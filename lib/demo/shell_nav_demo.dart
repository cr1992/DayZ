// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/ui/shell/app_shell.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/shell/new_journal_sheet.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

/// Interactive Demo for testing AppShell and navigation interactions.
///
/// Author: @Ray
class ShellNavDemo extends StatefulWidget {
  const ShellNavDemo({super.key});

  @override
  State<ShellNavDemo> createState() => _ShellNavDemoState();
}

class _ShellNavDemoState extends State<ShellNavDemo> {
  final List<JournalSummary> _journals = [
    const JournalSummary(id: '1', name: '工作日志', color: '#786CAD', count: 18),
    const JournalSummary(id: '2', name: '生活随笔', color: '#C67D33', count: 32),
    const JournalSummary(id: '3', name: '灵感便签', color: '#5A8E72', count: 5),
  ];

  String? _selectedJournalId;
  String _currentRoute = 'timeline';

  void _handleSelectJournal(String? id) {
    setState(() {
      _selectedJournalId = id;
      _currentRoute = 'timeline';
    });
  }

  void _handleNewJournal() {
    showNewJournalSheet(
      context,
      onSubmit: (name, color) {
        setState(() {
          _journals.add(
            JournalSummary(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              color: color,
              count: 0,
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppShell(
        journals: _journals,
        currentJournalId: _selectedJournalId,
        allJournalCount: 218,
        favoriteCount: 19,
        currentRoute: _currentRoute,
        onSelectJournal: _handleSelectJournal,
        onNavigate: (route) {
          setState(() {
            _currentRoute = route;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigating to: $route'),
              duration: const Duration(milliseconds: 500),
            ),
          );
        },
        onNewJournal: _handleNewJournal,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.dayz;
    final textTheme = context.dayzText;

    if (_currentRoute == 'timeline' || _currentRoute == '/timeline') {
      return Container(
        color: colors.bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DayzSpacing.s4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedJournalId == null
                      ? AppStrings.allJournals
                      : _journals
                            .firstWhere((j) => j.id == _selectedJournalId)
                            .name,
                  style: textTheme.h1.copyWith(color: colors.ink),
                ),
                const SizedBox(height: DayzSpacing.s2),
                Text(
                  '长按右下角 FAB 速拨菜单，或左滑/点击左上角 Menu 开启导航抽屉。',
                  style: textTheme.body.copyWith(color: colors.ink2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String title = _getRouteTitle(_currentRoute);
    return Container(
      color: colors.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(DayzSpacing.s4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: textTheme.h1.copyWith(color: colors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DayzSpacing.s2),
              Text(
                '这是一个独立的子页面 ($_currentRoute)。在真实应用中，此页面已与 GoRouter 路由完全绑定独立加载。',
                style: textTheme.body.copyWith(color: colors.ink2),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRouteTitle(String route) {
    switch (route) {
      case 'reader':
        return AppStrings.reader;
      case 'onthisday':
        return AppStrings.onThisDay;
      case 'favorites':
        return AppStrings.favorites;
      case 'calendar':
        return AppStrings.calendar;
      case 'trash':
        return AppStrings.trash;
      case 'settings':
        return AppStrings.settings;
      case 'memory':
        return AppStrings.memoryCardExport;
      case 'search':
        return AppStrings.search;
      case 'editor':
        return AppStrings.editor;
      default:
        return route;
    }
  }
}
