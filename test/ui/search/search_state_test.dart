// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/search/search_state.dart';

import 'fake_search_source.dart';

String describe(SearchUiState state) {
  // 穷尽 switch：新增变体而漏处理会编译失败（R1 结构护栏）。
  return switch (state) {
    SearchIdle() => 'idle',
    SearchTyping(:final query) => 'typing:$query',
    SearchQuerying(:final query) => 'querying:$query',
    SearchResults(:final query, :final hits) => 'results:$query:${hits.length}',
    SearchEmpty(:final query) => 'empty:$query',
    SearchError(:final query, :final message) => 'error:$query:$message',
  };
}

void main() {
  test('six states are constructible and switch exhaustively', () {
    final states = <SearchUiState>[
      const SearchIdle(),
      const SearchTyping('梅'),
      const SearchQuerying('梅子'),
      SearchResults('梅子', [fakeHit('a'), fakeHit('b')]),
      const SearchEmpty('梅子酱'),
      const SearchError('梅子', 'StateError'),
    ];
    expect(states.map(describe).toList(), [
      'idle',
      'typing:梅',
      'querying:梅子',
      'results:梅子:2',
      'empty:梅子酱',
      'error:梅子:StateError',
    ]);
  });

  test('results hits are unmodifiable', () {
    final state = SearchResults('q', [fakeHit('a')]);
    expect(() => state.hits.add(fakeHit('b')), throwsUnsupportedError);
  });

  test('SearchFilters: isEmpty / without / value equality', () {
    const journal = SearchJournalFilter(id: 'j1', name: '家');
    const filters = SearchFilters(journal: journal, year: 2026);

    expect(SearchFilters.none.isEmpty, isTrue);
    expect(filters.isEmpty, isFalse);
    expect(
      filters.without(SearchFilterKind.journal),
      const SearchFilters(year: 2026),
    );
    expect(
      filters.without(SearchFilterKind.year),
      const SearchFilters(journal: journal),
    );
    expect(
      filters
          .without(SearchFilterKind.year)
          .without(SearchFilterKind.journal)
          .isEmpty,
      isTrue,
    );
    expect(
      const SearchFilters(
        journal: SearchJournalFilter(id: 'j1', name: '家'),
        year: 2026,
      ),
      filters,
    );
    expect(filters == const SearchFilters(year: 2026), isFalse);
  });

  test('models carry typed fields', () {
    final hit = EntrySearchHit(
      id: 'e1',
      title: '外婆教我腌的梅子',
      excerpt: '玻璃罐要先用开水烫过',
      date: DateTime(2026, 5, 27),
      place: '杭州',
      tags: const ['家'],
    );
    expect(hit.id, 'e1');
    expect(hit.date, DateTime(2026, 5, 27));
    expect(hit.place, '杭州');
    expect(hit.tags, ['家']);
    expect(() => hit.tags.add('x'), throwsUnsupportedError);

    const recent = RecentSearch(term: '梅子', count: 2);
    expect(recent.count, 2);
    expect(const RecentSearch(term: '没事别熬夜').count, isNull);
    const tag = TagSuggestion(id: 't1', name: '生活');
    expect(tag.name, '生活');
  });

  group('FakeSearchSource', () {
    test('returns configured hits, empty and errors; records calls', () async {
      final source = FakeSearchSource(
        hits: {
          '梅子': [fakeHit('a')],
        },
        failing: {'坏'},
        recentSearches: const [RecentSearch(term: '梅子', count: 1)],
        tagSuggestions: const [TagSuggestion(id: 't', name: '家')],
      );

      expect((await source.search('梅子', SearchFilters.none)).single.id, 'a');
      expect(await source.search('梅子酱', SearchFilters.none), isEmpty);
      await expectLater(
        source.search('坏', const SearchFilters(year: 2026)),
        throwsStateError,
      );
      expect(source.calls.map((call) => call.query), ['梅子', '梅子酱', '坏']);
      expect(source.calls.last.filters, const SearchFilters(year: 2026));
      expect((await source.recent()).single.term, '梅子');
      expect((await source.tags()).single.name, '家');

      final events = <void>[];
      final sub = source.changes().listen(events.add);
      source.emitChange();
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      await sub.cancel();
      await source.close();
    });
  });
}
