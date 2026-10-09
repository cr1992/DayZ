// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';

/// 让 [TimelineController] 走 SQL 层的按日记本过滤与月度计数。
///
/// 数据层只返回基础类型，这里转成时间线屏的接口类型，避免 data → ui 反向依赖。
///
/// Author: @Ray
class TimelineRepositoryAdapter extends EntryRepo
    implements TimelineJournalScopedRepository, TimelineMonthMetadataRepository {
  TimelineRepositoryAdapter(super.db);

  @override
  Future<Map<TimelineMonthKey, int>> monthCounts(String? journalId) async {
    final counts = await countByMonth(journalId: journalId);
    return {
      for (final entry in counts.entries)
        TimelineMonthKey(entry.key.$1, entry.key.$2): entry.value,
    };
  }

  @override
  Future<Set<int>> entryDaysInMonth(String? journalId, int year, int month) {
    return entryDaysOfMonth(journalId: journalId, year: year, month: month);
  }
}
