// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'search_source.dart';
import 'search_state.dart';

/// 键入防抖窗口（D2）：窗口内只发最后一次查询。
const Duration searchDebounce = Duration(milliseconds: 300);

/// 搜索屏状态机持有者（D1/D2）：防抖 + 自增 seq 丢弃过期结果 + 按命中计数
/// 切态 + 异常兜底。只依赖 [SearchSource] 接口，不碰数据层（NF2）。
///
/// 类名避开 Material 的同名 `SearchController`。
///
/// Author: @Ray
class SearchScreenController extends ChangeNotifier {
  SearchScreenController({
    required SearchSource source,
    SearchFilters initialFilters = SearchFilters.none,
    Duration debounce = searchDebounce,
  }) : _source = source,
       _filters = initialFilters,
       _debounce = debounce;

  final SearchSource _source;
  final Duration _debounce;

  SearchUiState _state = const SearchIdle();
  SearchFilters _filters;
  String _query = '';
  List<RecentSearch> _recent = const [];
  List<TagSuggestion> _tags = const [];
  Timer? _timer;
  int _seq = 0;
  bool _disposed = false;

  SearchUiState get state => _state;

  /// 当前（已 trim 的）查询词；空串表示无输入。
  String get query => _query;

  SearchFilters get filters => _filters;

  /// idle / typing 态共用的「最近搜索」。
  List<RecentSearch> get recent => _recent;

  /// idle / typing 态共用的「标签」建议。
  List<TagSuggestion> get tags => _tags;

  /// 拉取建议数据；失败按空列表降级。
  Future<void> start() async {
    await Future.wait([_loadRecent(), _loadTags()]);
  }

  /// 输入框文字变化：空 → idle（作废在途查询）；非空 → typing + 重置防抖。
  void onQueryChanged(String text) {
    final query = text.trim();
    _timer?.cancel();
    _timer = null;
    _query = query;
    if (query.isEmpty) {
      _seq++;
      _setState(const SearchIdle());
      return;
    }
    _setState(SearchTyping(query));
    _timer = Timer(_debounce, () {
      _timer = null;
      unawaited(_run(query));
    });
  }

  /// 键盘「搜索」键：跳过防抖立即查。
  Future<void> submit(String text) async {
    final query = text.trim();
    _timer?.cancel();
    _timer = null;
    _query = query;
    if (query.isEmpty) {
      _seq++;
      _setState(const SearchIdle());
      return;
    }
    await _run(query);
  }

  /// 点最近搜索 / 标签建议：回填并立即查。
  Future<void> pickSuggestion(String term) => submit(term);

  /// 去掉一个筛选维度；有当前词则立即重查。
  Future<void> removeFilter(SearchFilterKind kind) async {
    _filters = _filters.without(kind);
    if (_query.isEmpty) {
      _notify();
      return;
    }
    _timer?.cancel();
    _timer = null;
    await _run(_query);
  }

  /// error 态重试：以相同词重发。
  Future<void> retry() async {
    if (_query.isEmpty) {
      return;
    }
    await _run(_query);
  }

  /// 条目变更回刷：仅 results / empty 态以当前词静默重查（不经 querying）。
  Future<void> refresh() async {
    final current = _state;
    if (current is! SearchResults && current is! SearchEmpty) {
      return;
    }
    await _run(_query, silent: true);
  }

  Future<void> _run(String query, {bool silent = false}) async {
    final seq = ++_seq;
    if (!silent) {
      _setState(SearchQuerying(query));
    }
    final SearchUiState next;
    try {
      final hits = await _source.search(query, _filters);
      next = hits.isEmpty ? SearchEmpty(query) : SearchResults(query, hits);
    } catch (error) {
      if (_disposed || seq != _seq) {
        return;
      }
      _setState(SearchError(query, error.runtimeType.toString()));
      return;
    }
    if (_disposed || seq != _seq) {
      return;
    }
    _setState(next);
    // 适配层可能把本次查询记入最近搜索，回到 idle 时要看得到。
    unawaited(_loadRecent());
  }

  Future<void> _loadRecent() async {
    try {
      final recent = await _source.recent();
      if (_disposed) {
        return;
      }
      _recent = List<RecentSearch>.unmodifiable(recent);
    } catch (_) {
      if (_disposed) {
        return;
      }
      _recent = const [];
    }
    _notify();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _source.tags();
      if (_disposed) {
        return;
      }
      _tags = List<TagSuggestion>.unmodifiable(tags);
    } catch (_) {
      if (_disposed) {
        return;
      }
      _tags = const [];
    }
    _notify();
  }

  void _setState(SearchUiState next) {
    _state = next;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
