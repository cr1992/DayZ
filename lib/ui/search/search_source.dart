// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ignore_for_file: prefer_initializing_formals

import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'search_state.dart';

/// 搜索屏取数端口（屏私有，D5）：屏与控制器只依赖它，测试 / demo 注入假实现。
///
/// Author: @Ray
abstract interface class SearchSource {
  /// 按 [query] 子串检索未删除条目（按时间倒序），[filters] 原样交给 Repo。
  Future<List<EntrySearchHit>> search(String query, SearchFilters filters);

  /// idle 态「最近搜索」。
  Future<List<RecentSearch>> recent();

  /// idle 态「标签」建议。
  Future<List<TagSuggestion>> tags();

  /// 条目表任意写入时发事件，供屏静默重查。
  Stream<void> changes();
}

/// [SearchSource] 的唯一生产实现：把 `EntryRepo` / `TagRepo` 适配成搜索端口，
/// 是本屏唯一接触 Repository 的地方（只调公开方法，不碰 Drift / SQL，NF2）。
///
/// 「最近搜索」是进程内会话级记录（不落库）：成功查询后按词去重置顶，
/// 最多保留 [maxRecent] 条。
///
/// Author: @Ray
class RepoSearchSource implements SearchSource {
  RepoSearchSource({required EntryRepo entryRepo, TagRepo? tagRepo})
    : _entryRepo = entryRepo,
      _tagRepo = tagRepo;

  static const int maxRecent = 5;

  final EntryRepo _entryRepo;
  final TagRepo? _tagRepo;
  final List<RecentSearch> _recent = [];

  @override
  Future<List<EntrySearchHit>> search(
    String query,
    SearchFilters filters,
  ) async {
    final term = query.trim();
    final entries = await _entryRepo.search(
      term,
      journalId: filters.journal?.id,
      year: filters.year,
    );
    final hits = [
      for (final entry in entries)
        EntrySearchHit(
          id: entry.id,
          title: _title(entry.contentPlain),
          excerpt: _excerpt(entry.contentPlain),
          date: DateTime(entry.localYear, entry.localMonth, entry.localDay),
          place: _blankToNull(entry.placeName),
        ),
    ];
    if (term.isNotEmpty) {
      _remember(term, hits.length);
    }
    return hits;
  }

  @override
  Future<List<RecentSearch>> recent() async =>
      List<RecentSearch>.unmodifiable(_recent);

  @override
  Future<List<TagSuggestion>> tags() async {
    final repo = _tagRepo;
    if (repo == null) {
      return const [];
    }
    final tags = await repo.list();
    return [for (final tag in tags) TagSuggestion(id: tag.id, name: tag.name)];
  }

  @override
  Stream<void> changes() => _entryRepo.watchChanges();

  void _remember(String term, int count) {
    _recent
      ..removeWhere((item) => item.term == term)
      ..insert(0, RecentSearch(term: term, count: count));
    if (_recent.length > maxRecent) {
      _recent.removeRange(maxRecent, _recent.length);
    }
  }
}

SearchSource? _sourcePort;

/// 路由层读取的搜索端口；未注册时 `Routes.search` 保持占位屏。
SearchSource? get searchSourcePort => _sourcePort;

/// 由组合根（`bindRouterPorts`）注册搜索端口；传 null 清空。
void registerSearchSource(SearchSource? source) {
  _sourcePort = source;
}

List<String> _lines(String plain) {
  return plain
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

/// 条目无标题列：标题 = 正文首个非空行（与时间线 / 往年今日同口径）。
String _title(String plain) {
  final lines = _lines(plain);
  return lines.isEmpty ? '' : lines.first;
}

String _excerpt(String plain) {
  final lines = _lines(plain);
  return lines.length <= 1 ? '' : lines.skip(1).join(' ');
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
