// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';

import 'package:dayz/app/timeline_repository_adapter.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/editing_session_repo.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/journal_repo.dart';
import 'package:dayz/observability/observability.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/shell/shell_state.dart';

/// 生产装配的组合根：进程内唯一的 [AppDatabase] 与基于它的全部 Repo。
///
/// Author: @Ray
class AppServices {
  AppServices.forDatabase(this.database)
    : entries = EntryRepo(database),
      timelineRepo = TimelineRepositoryAdapter(database),
      journals = JournalRepo(database),
      editingSessions = EditingSessionRepo(database);

  final AppDatabase database;
  final EntryRepo entries;
  final TimelineRepositoryAdapter timelineRepo;
  final JournalRepo journals;
  final EditingSessionRepo editingSessions;

  /// 打开设备上的加密库；失败（如主密码模式未解锁）记日志并返回 null，不抛出到 main。
  static Future<AppServices?> open({KeyProvider? keyProvider}) async {
    try {
      final database = await AppDatabase.open(keyProvider ?? KeyProvider());
      return AppServices.forDatabase(database);
    } catch (error) {
      AppLogger.instance.logSevere(
        'app.services.open_failed',
        fields: {'error': error.runtimeType.toString()},
      );
      return null;
    }
  }

  /// 从库重载日记本列表（含篇数）写入 [shell]。
  Future<void> refreshJournals(ShellState shell) async {
    final rows = await journals.list();
    final counts = await journals.entryCounts();
    shell.setJournals([
      for (final row in rows)
        JournalSummary(
          id: row.id,
          name: row.name,
          color: row.color,
          count: counts[row.id] ?? 0,
        ),
    ]);
  }

  /// 新建日记本落库并刷新 [shell]，排在现有日记本之后。
  Future<void> createJournal(
    ShellState shell, {
    required String name,
    required String color,
  }) async {
    final existing = await journals.list();
    final nextOrder = existing.isEmpty
        ? 0
        : existing.map((row) => row.sortOrder).reduce((a, b) => a > b ? a : b) +
              1;
    await journals.create(name, color: color, sortOrder: nextOrder);
    await refreshJournals(shell);
  }

  Future<void> close() => database.close();
}

/// 把 [AppServices] 经 UI 树向下提供；路由 builder 用 [maybeOf] 取。
class AppServicesScope extends InheritedWidget {
  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppServicesScope>()
        ?.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) {
    return services != oldWidget.services;
  }
}
