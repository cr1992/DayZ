// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dayz/ui/search/search_source.dart';
import 'package:dayz/ui/search/search_state.dart';

/// 一次 [FakeSearchSource.search] 调用的记录。
class FakeSearchCall {
  const FakeSearchCall(this.query, this.filters);

  final String query;
  final SearchFilters filters;
}

/// 受控假 [SearchSource]：按查询词配置命中 / 空 / 抛错，可注入延迟。
class FakeSearchSource implements SearchSource {
  FakeSearchSource({
    Map<String, List<EntrySearchHit>>? hits,
    Set<String>? failing,
    this.recentSearches = const [],
    this.tagSuggestions = const [],
    this.delay = Duration.zero,
    Map<String, Duration>? delays,
  }) : hits = hits ?? <String, List<EntrySearchHit>>{},
       failing = failing ?? <String>{},
       delays = delays ?? <String, Duration>{};

  /// 词 → 命中；未配置的词返回空列表。
  final Map<String, List<EntrySearchHit>> hits;

  /// 这些词的查询抛 [StateError]。
  final Set<String> failing;

  /// 默认查询延迟；[delays] 可按词覆盖。
  Duration delay;
  final Map<String, Duration> delays;

  List<RecentSearch> recentSearches;
  List<TagSuggestion> tagSuggestions;

  final List<FakeSearchCall> calls = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Future<List<EntrySearchHit>> search(
    String query,
    SearchFilters filters,
  ) async {
    calls.add(FakeSearchCall(query, filters));
    final wait = delays[query] ?? delay;
    if (wait > Duration.zero) {
      await Future<void>.delayed(wait);
    }
    if (failing.contains(query)) {
      throw StateError('fake search failure: $query');
    }
    return hits[query] ?? const [];
  }

  @override
  Future<List<RecentSearch>> recent() async => recentSearches;

  @override
  Future<List<TagSuggestion>> tags() async => tagSuggestions;

  @override
  Stream<void> changes() => _changes.stream;

  /// 模拟条目表写入。
  void emitChange() => _changes.add(null);

  Future<void> close() => _changes.close();
}

/// 造一个命中。
EntrySearchHit fakeHit(
  String id, {
  String title = '标题',
  String excerpt = '',
  DateTime? date,
  String? place,
}) {
  return EntrySearchHit(
    id: id,
    title: title,
    excerpt: excerpt,
    date: date ?? DateTime(2026, 5, 27),
    place: place,
  );
}
