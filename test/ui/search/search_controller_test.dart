// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// flutter_test 的传递依赖；不为测试单独改 pubspec（design：不触 pubspec）。
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/search/search_controller.dart';
import 'package:dayz/ui/search/search_state.dart';

import 'fake_search_source.dart';

String kind(SearchUiState state) => switch (state) {
  SearchIdle() => 'idle',
  SearchTyping() => 'typing',
  SearchQuerying() => 'querying',
  SearchResults() => 'results',
  SearchEmpty() => 'empty',
  SearchError() => 'error',
};

void main() {
  late FakeSearchSource source;
  late SearchScreenController controller;
  late List<String> transitions;

  void build({SearchFilters filters = SearchFilters.none}) {
    controller = SearchScreenController(
      source: source,
      initialFilters: filters,
    );
    transitions = [];
    controller.addListener(() {
      final label = kind(controller.state);
      if (transitions.isEmpty || transitions.last != label) {
        transitions.add(label);
      }
    });
  }

  setUp(() {
    source = FakeSearchSource(
      hits: {
        '梅子': [fakeHit('a'), fakeHit('b')],
        '梅子酱': [fakeHit('c')],
        '梅': [fakeHit('old')],
      },
      failing: {'坏'},
      recentSearches: const [RecentSearch(term: '梅雨', count: 5)],
      tagSuggestions: const [TagSuggestion(id: 't1', name: '生活')],
    );
  });

  test('debounce: only the final word is queried once (R2)', () {
    fakeAsync((async) {
      build();
      controller.onQueryChanged('梅');
      async.elapse(const Duration(milliseconds: 100));
      controller.onQueryChanged('梅子');
      async.elapse(const Duration(milliseconds: 100));
      controller.onQueryChanged('梅子酱');
      expect(controller.state, isA<SearchTyping>());
      async.elapse(searchDebounce - const Duration(milliseconds: 1));
      expect(source.calls, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();

      expect(source.calls.map((call) => call.query), ['梅子酱']);
      final state = controller.state as SearchResults;
      expect(state.query, '梅子酱');
      expect(state.hits.single.id, 'c');
      expect(transitions, ['typing', 'querying', 'results']);
    });
  });

  test('late result of an older query never overwrites the newer one (R2)', () {
    fakeAsync((async) {
      source.delays['梅'] = const Duration(seconds: 2);
      source.delays['梅子酱'] = const Duration(milliseconds: 100);
      build();

      controller.onQueryChanged('梅');
      async.elapse(searchDebounce); // 「梅」已发出、在途 2s
      controller.onQueryChanged('梅子酱');
      async.elapse(searchDebounce + const Duration(milliseconds: 100));
      expect((controller.state as SearchResults).hits.single.id, 'c');

      async.elapse(const Duration(seconds: 3)); // 旧查询迟到
      expect(source.calls.map((call) => call.query), ['梅', '梅子酱']);
      final state = controller.state as SearchResults;
      expect(state.query, '梅子酱');
      expect(state.hits.single.id, 'c');
    });
  });

  test('count > 0 → results with all hits; count == 0 → empty (R4)', () async {
    build();
    await controller.submit('梅子');
    final results = controller.state as SearchResults;
    expect(results.hits.map((hit) => hit.id), ['a', 'b']);

    await controller.submit('梅子果冻');
    expect(controller.state, isA<SearchEmpty>());
    expect((controller.state as SearchEmpty).query, '梅子果冻');
  });

  test('error → SearchError, retry re-queries the same word (R8)', () async {
    build();
    await controller.submit('坏');
    final error = controller.state as SearchError;
    expect(error.query, '坏');
    expect(error.message, 'StateError');

    source.failing.clear();
    source.hits['坏'] = [fakeHit('fixed')];
    transitions.clear();
    await controller.retry();
    expect(source.calls.map((call) => call.query), ['坏', '坏']);
    expect(transitions, ['querying', 'results']);
  });

  test('clearing input → idle and drops the in-flight query (R5)', () {
    fakeAsync((async) {
      source.delay = const Duration(seconds: 1);
      build();
      controller.onQueryChanged('梅子');
      async.elapse(searchDebounce);
      expect(controller.state, isA<SearchQuerying>());
      controller.onQueryChanged('  ');
      expect(controller.state, isA<SearchIdle>());
      expect(controller.query, '');
      async.elapse(const Duration(seconds: 2));
      expect(controller.state, isA<SearchIdle>());
    });
  });

  test('start() loads recent searches and tag suggestions (R5)', () async {
    build();
    await controller.start();
    expect(controller.recent.single.term, '梅雨');
    expect(controller.tags.single.name, '生活');
  });

  test('pickSuggestion queries immediately without debounce (R5)', () async {
    build();
    await controller.pickSuggestion('梅子');
    expect(source.calls.single.query, '梅子');
    expect(controller.query, '梅子');
    expect(controller.state, isA<SearchResults>());
  });

  test('removeFilter re-queries with the narrowed filters (D8)', () async {
    const filters = SearchFilters(
      journal: SearchJournalFilter(id: 'j1', name: '家'),
      year: 2026,
    );
    build(filters: filters);
    await controller.submit('梅子');
    expect(source.calls.last.filters, filters);

    await controller.removeFilter(SearchFilterKind.journal);
    expect(source.calls, hasLength(2));
    expect(source.calls.last.query, '梅子');
    expect(source.calls.last.filters, const SearchFilters(year: 2026));
    expect(controller.filters, const SearchFilters(year: 2026));
  });

  test('removeFilter without a query only updates filters', () async {
    build(filters: const SearchFilters(year: 2026));
    await controller.removeFilter(SearchFilterKind.year);
    expect(source.calls, isEmpty);
    expect(controller.filters.isEmpty, isTrue);
    expect(controller.state, isA<SearchIdle>());
  });

  test(
    'refresh() silently re-queries in results; no-op in idle (R10)',
    () async {
      build();
      await controller.refresh();
      expect(source.calls, isEmpty);

      await controller.submit('梅子');
      source.hits['梅子'] = [fakeHit('a')];
      transitions.clear();
      await controller.refresh();
      expect(source.calls.map((call) => call.query), ['梅子', '梅子']);
      expect(transitions, ['results']); // 不经 querying
      expect((controller.state as SearchResults).hits.single.id, 'a');

      source.hits['梅子'] = const [];
      await controller.refresh();
      expect(controller.state, isA<SearchEmpty>());
    },
  );

  test('pending debounce is cancelled on dispose', () {
    fakeAsync((async) {
      build();
      controller.onQueryChanged('梅子');
      controller.dispose();
      async.elapse(const Duration(seconds: 1));
      expect(source.calls, isEmpty);
    });
  });
}
