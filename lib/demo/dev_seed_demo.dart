// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart' show BaseAggregate, StringExpressionOperators;
import 'package:flutter/material.dart';

import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/ui/shell/app_router.dart';

/// 编辑器交付前的真机走查工具：向真实加密库写入 / 清空示例条目。
///
/// 示例条目以 `serverRev` 标记（同步字段尚未启用），示例日记本以名称前缀标记，
/// 清空时只动带标记的数据。
///
/// Author: @Ray
abstract final class DevSeed {
  static const String entryMarker = 'dayz-dev-seed';
  static const String journalPrefix = '示例·';
  static const String _tz = 'Asia/Shanghai';

  static const List<String> _dailyTexts = [
    '早起去江边散步\n雾很大，对岸的楼只剩轮廓。买了一杯豆浆，边走边喝。',
    '读完了一本小说\n结尾比想象中安静，合上书坐了很久。',
    '和老朋友吃饭\n聊到十年前的事，发现彼此记得的细节完全不同。',
    '下雨天\n窗外一直在下，泡了茶，什么也没做。',
    '整理书架\n翻出一张旧车票，日期已经看不清了。',
    '第一次自己做红烧肉\n糖色炒过了头，不过还是吃光了。',
  ];

  static const List<String> _travelTexts = [
    '到达大理\n傍晚的洱海风很大，云压得很低。',
    '苍山徒步\n走到一半开始下小雨，雾里全是松针的味道。',
    '古城夜市\n买了一串烤乳扇，甜得有点腻。',
  ];

  /// 写入跨 6 个自然月、分属 2 本示例日记本的条目，返回写入条数。
  static Future<int> seed(AppServices services, {DateTime? now}) async {
    final base = (now ?? DateTime.now()).toUtc();
    final daily = await services.journals.create(
      '$journalPrefix日常',
      color: '#786CAD',
    );
    final travel = await services.journals.create(
      '$journalPrefix旅行',
      color: '#5C8A68',
      sortOrder: 1,
    );

    var written = 0;
    for (var monthOffset = 0; monthOffset < 6; monthOffset++) {
      for (var i = 0; i < 3; i++) {
        final isTravel = (monthOffset + i) % 4 == 0;
        final texts = isTravel ? _travelTexts : _dailyTexts;
        final day = 3 + i * 9;
        final at = DateTime.utc(
          base.year,
          base.month - monthOffset,
          day,
          1 + i * 4,
        );
        if (at.isAfter(base)) {
          continue;
        }
        await services.entries.create(
          journalId: isTravel ? travel.id : daily.id,
          contentJson: '{}',
          contentPlain: texts[(monthOffset * 3 + i) % texts.length],
          entryDtUtc: at,
          entryTz: _tz,
          placeName: isTravel ? '大理' : null,
          isFavorite: i == 1 && monthOffset.isEven,
          serverRev: entryMarker,
        );
        written += 1;
      }
    }

    services.notifyContentChanged();
    return written;
  }

  /// 硬删全部示例条目与示例日记本，保留其他数据；返回删除的条目数。
  static Future<int> clear(AppServices services) async {
    final db = services.database;
    final removed = await (db.delete(
      db.entries,
    )..where((t) => t.serverRev.equals(entryMarker))).go();
    await (db.delete(
      db.journals,
    )..where((t) => t.name.like('$journalPrefix%'))).go();
    services.notifyContentChanged();
    return removed;
  }

  /// 库内未删除条目总数（含非示例）。
  static Future<int> countEntries(AppDatabase db) async {
    final count = db.entries.id.count();
    final row =
        await (db.selectOnly(db.entries)
              ..addColumns([count])
              ..where(db.entries.deletedAt.isNull()))
            .getSingle();
    return row.read(count) ?? 0;
  }
}

class DevSeedDemo extends StatefulWidget {
  const DevSeedDemo({super.key});

  @override
  State<DevSeedDemo> createState() => _DevSeedDemoState();
}

class _DevSeedDemoState extends State<DevSeedDemo> {
  int? _count;
  bool _busy = false;
  String _status = '';

  AppServices? get _services => AppServicesScope.maybeOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final services = _services;
    if (services == null) {
      return;
    }
    final count = await DevSeed.countEntries(services.database);
    if (mounted) {
      setState(() => _count = count);
    }
  }

  Future<void> _run(Future<String> Function(AppServices) action) async {
    final services = _services;
    if (services == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final status = await action(services);
      await services.refreshJournals(shellState);
      if (mounted) {
        setState(() => _status = status);
      }
    } finally {
      await _refreshCount();
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    return Scaffold(
      appBar: AppBar(title: const Text('示例数据')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: services == null
            ? const Text('数据库未打开（主密码模式或打开失败），无法写入示例数据。')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '库内条目：${_count ?? '…'}',
                    key: const ValueKey<String>('dev-seed-count'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey<String>('dev-seed-write'),
                    onPressed: _busy
                        ? null
                        : () => _run((s) async {
                            final n = await DevSeed.seed(s);
                            return '已写入 $n 条示例条目';
                          }),
                    child: const Text('写入示例条目（6 个月 · 2 本日记本）'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey<String>('dev-seed-clear'),
                    onPressed: _busy
                        ? null
                        : () => _run((s) async {
                            final n = await DevSeed.clear(s);
                            return '已清空 $n 条示例条目';
                          }),
                    child: const Text('清空示例条目'),
                  ),
                  const SizedBox(height: 16),
                  Text(_status),
                ],
              ),
      ),
    );
  }
}
