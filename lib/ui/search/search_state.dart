// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';

/// 搜索屏状态机（D1）：设计稿只画了 typing / results / empty 三种静态呈现，
/// 这里补齐 idle / querying / error，屏侧 `switch` 穷尽渲染。
///
/// Author: @Ray
sealed class SearchUiState {
  const SearchUiState();
}

/// 无输入：渲染最近搜索 + 标签建议（建议数据由控制器另持）。
final class SearchIdle extends SearchUiState {
  const SearchIdle();
}

/// 有输入、防抖等待中。
final class SearchTyping extends SearchUiState {
  const SearchTyping(this.query);

  final String query;
}

/// 查询执行中。
final class SearchQuerying extends SearchUiState {
  const SearchQuerying(this.query);

  final String query;
}

/// 有命中（按时间倒序）。
final class SearchResults extends SearchUiState {
  SearchResults(this.query, List<EntrySearchHit> hits)
    : hits = List<EntrySearchHit>.unmodifiable(hits);

  final String query;
  final List<EntrySearchHit> hits;
}

/// 零命中。
final class SearchEmpty extends SearchUiState {
  const SearchEmpty(this.query);

  final String query;
}

/// 查询抛错；[message] 只作诊断（异常类型名），不向用户展示原文。
final class SearchError extends SearchUiState {
  const SearchError(this.query, this.message);

  final String query;
  final String message;
}

/// 可单独去除的筛选维度。
///
/// Author: @Ray
enum SearchFilterKind { journal, year }

/// 日记本筛选：id 交给 Repo，name 用于 chip 文案。
///
/// Author: @Ray
@immutable
class SearchJournalFilter {
  const SearchJournalFilter({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is SearchJournalFilter && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// 已生效的筛选条件（v1 只有日记本与年份，D8）；作为查询入参交给 Repo。
///
/// Author: @Ray
@immutable
class SearchFilters {
  const SearchFilters({this.journal, this.year});

  static const SearchFilters none = SearchFilters();

  final SearchJournalFilter? journal;
  final int? year;

  bool get isEmpty => journal == null && year == null;

  /// 去掉 [kind] 维度后的新筛选。
  SearchFilters without(SearchFilterKind kind) {
    return switch (kind) {
      SearchFilterKind.journal => SearchFilters(year: year),
      SearchFilterKind.year => SearchFilters(journal: journal),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is SearchFilters && other.journal == journal && other.year == year;

  @override
  int get hashCode => Object.hash(journal, year);
}

/// 结果卡片渲染模型（不外泄 Drift 类型）。
///
/// Author: @Ray
@immutable
class EntrySearchHit {
  EntrySearchHit({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.date,
    this.place,
    List<String> tags = const [],
  }) : tags = List<String>.unmodifiable(tags);

  final String id;

  /// 正文首个非空行。
  final String title;

  /// 其余行以空格连接。
  final String excerpt;

  /// 条目本地日期（年/月/日）。
  final DateTime date;
  final String? place;

  /// v1 恒空（标签批量查询 spec 并行中）。
  final List<String> tags;
}

/// 「最近搜索」一行：词 + 可选命中篇数。
///
/// Author: @Ray
@immutable
class RecentSearch {
  const RecentSearch({required this.term, this.count});

  final String term;
  final int? count;
}

/// 「标签」建议 chip。
///
/// Author: @Ray
@immutable
class TagSuggestion {
  const TagSuggestion({required this.id, required this.name});

  final String id;
  final String name;
}
