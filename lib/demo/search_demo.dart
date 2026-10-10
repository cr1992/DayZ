// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/components.dart';
import '../ui/search/search_page.dart';
import '../ui/search/search_source.dart';
import '../ui/search/search_state.dart';
import '../ui/theme/dayz_tokens.g.dart';

/// Debug Home demo：搜索屏六态走查（内存假数据，不连真实库）。
///
/// 切换「命中 / 无结果 / 出错 / 慢查询」后重建搜索屏：进屏即 idle（最近搜索 +
/// 标签），键入进 typing，防抖到期进 querying（慢查询模式停留 3 秒），随后按
/// 模式落到 results / empty / error。命中模式预置日记本 + 年份筛选以展示筛选区。
///
/// Author: @Ray
class SearchDemo extends StatefulWidget {
  const SearchDemo({super.key});

  static ValueKey<String> modeKey(SearchDemoMode mode) =>
      ValueKey<String>('search-demo-${mode.name}');

  @override
  State<SearchDemo> createState() => _SearchDemoState();
}

/// demo 假数据源的行为模式。
enum SearchDemoMode { hits, empty, error, slow }

class _SearchDemoState extends State<SearchDemo> {
  SearchDemoMode _mode = SearchDemoMode.hits;
  late _DemoSearchSource _source = _DemoSearchSource(_mode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DayzSpacing.s4,
                DayzSpacing.s4,
                DayzSpacing.s4,
                0,
              ),
              child: DayzSegmented<SearchDemoMode>(
                value: _mode,
                onChanged: _switchMode,
                segments: [
                  for (final (mode, label) in const [
                    (SearchDemoMode.hits, '命中'),
                    (SearchDemoMode.empty, '无结果'),
                    (SearchDemoMode.error, '出错'),
                    (SearchDemoMode.slow, '慢查询'),
                  ])
                    DayzSegment(
                      value: mode,
                      child: Text(label, key: SearchDemo.modeKey(mode)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SearchPage(
                key: ValueKey(_mode),
                source: _source,
                initialFilters: _mode == SearchDemoMode.hits
                    ? const SearchFilters(
                        journal: SearchJournalFilter(id: 'demo-home', name: '家'),
                        year: 2026,
                      )
                    : SearchFilters.none,
                onOpenEntry: (id) => DayzToast.show(
                  context,
                  '打开 $id（demo 不跳阅读页）',
                  DayzToastTone.info,
                ),
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchMode(SearchDemoMode mode) {
    setState(() {
      _mode = mode;
      _source = _DemoSearchSource(mode);
    });
  }
}

class _DemoSearchSource implements SearchSource {
  _DemoSearchSource(this.mode);

  final SearchDemoMode mode;

  @override
  Future<List<EntrySearchHit>> search(
    String query,
    SearchFilters filters,
  ) async {
    switch (mode) {
      case SearchDemoMode.empty:
        return const [];
      case SearchDemoMode.error:
        throw StateError('demo search failure');
      case SearchDemoMode.slow:
        await Future<void>.delayed(const Duration(seconds: 3));
        return _sampleHits;
      case SearchDemoMode.hits:
        return _sampleHits;
    }
  }

  @override
  Future<List<RecentSearch>> recent() async => const [
    RecentSearch(term: '梅子', count: 2),
    RecentSearch(term: '梅雨', count: 5),
    RecentSearch(term: '没事别熬夜'),
  ];

  @override
  Future<List<TagSuggestion>> tags() async => const [
    TagSuggestion(id: 'demo-life', name: '生活'),
    TagSuggestion(id: 'demo-home', name: '家'),
    TagSuggestion(id: 'demo-thought', name: '随想'),
    TagSuggestion(id: 'demo-travel', name: '旅行'),
    TagSuggestion(id: 'demo-food', name: '食物'),
  ];

  @override
  Stream<void> changes() => const Stream<void>.empty();
}

final List<EntrySearchHit> _sampleHits = [
  EntrySearchHit(
    id: 'demo-plum-1',
    title: '外婆教我腌的梅子',
    excerpt: '玻璃罐要先用开水烫过，梅子和冰糖一层一层码好。她说急不得，要等一整个夏天。',
    date: DateTime(2026, 5, 27),
    place: '杭州',
  ),
  EntrySearchHit(
    id: 'demo-plum-2',
    title: '开了去年的那罐',
    excerpt: '放了一整年，梅子的颜色变得很深。配白粥刚刚好，酸里带一点回甘。',
    date: DateTime(2026, 6, 12),
  ),
];
