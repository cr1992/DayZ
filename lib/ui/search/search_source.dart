// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
