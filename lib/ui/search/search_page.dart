// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import '../components.dart';
import '../shell/app_router.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import '../widgets/dayz_icon.dart';
import 'search_controller.dart';
import 'search_highlight.dart';
import 'search_source.dart';
import 'search_state.dart';

/// 搜索屏（`search.html`）：`.search-head` 搜索框 + 取消，主体按状态机六态渲染。
///
/// 宿主持有 [SearchScreenController]：首帧拉建议、有 [initialQuery] 则回填并
/// 直接查询；条目表变更时在 results / empty 态静默重查（R10）。
///
/// Author: @Ray
class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.source,
    this.initialQuery,
    this.initialFilters = SearchFilters.none,
    this.onOpenEntry,
    this.onBack,
    this.debounce = searchDebounce,
  });

  static const Key switcherKey = ValueKey<String>('search-switcher');
  static const Key suggestionsKey = ValueKey<String>('search-suggestions');
  static const Key queryingKey = ValueKey<String>('search-querying');
  static const Key resultsListKey = ValueKey<String>('search-results');
  static const Key resultStatKey = ValueKey<String>('search-stat');
  static const Key filtersKey = ValueKey<String>('search-filters');
  static const Key emptyStateKey = ValueKey<String>('search-empty');
  static const Key errorStateKey = ValueKey<String>('search-error');
  static const Key retryButtonKey = ValueKey<String>('search-retry');

  static ValueKey<String> suggestRowKey(String term) =>
      ValueKey<String>('search-suggest-$term');

  static ValueKey<String> tagChipKey(String tagId) =>
      ValueKey<String>('search-tag-$tagId');

  static ValueKey<String> filterChipKey(SearchFilterKind kind) =>
      ValueKey<String>('search-filter-${kind.name}');

  static ValueKey<String> hitCardKey(String entryId) =>
      ValueKey<String>('search-hit-$entryId');

  static ValueKey<String> hitTitleKey(String entryId) =>
      ValueKey<String>('search-hit-title-$entryId');

  static ValueKey<String> hitExcerptKey(String entryId) =>
      ValueKey<String>('search-hit-excerpt-$entryId');

  final SearchSource source;

  /// 路由 `extra` 带来的初始查询词；非空则首帧直接查询。
  final String? initialQuery;
  final SearchFilters initialFilters;

  /// 点结果卡片；缺省经 `go_router` 推 [Routes.reader]（携 entryId）。
  final ValueChanged<String>? onOpenEntry;

  /// 取消钮在路由栈无法出栈时的兜底；缺省回时间线。
  final VoidCallback? onBack;

  /// 防抖窗口（测试 / demo 可调）。
  final Duration debounce;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchScreenController _controller;
  late StreamSubscription<void> _changes;
  late final TextEditingController _text;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initialQuery?.trim() ?? '');
    _attach(initialQuery: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _detach();
      _attach(initialQuery: _text.text);
    }
  }

  @override
  void dispose() {
    _detach();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _attach({String? initialQuery}) {
    _controller = SearchScreenController(
      source: widget.source,
      initialFilters: widget.initialFilters,
      debounce: widget.debounce,
    );
    _changes = widget.source.changes().listen(
      (_) => unawaited(_controller.refresh()),
    );
    unawaited(_controller.start());
    final query = initialQuery?.trim() ?? '';
    if (query.isNotEmpty) {
      unawaited(_controller.submit(query));
    }
  }

  void _detach() {
    unawaited(_changes.cancel());
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // `.search-head`：`DayzSearchField` 自带 `.search-input` 与 `.search-cancel`。
            Semantics(
              container: true,
              label: l10n.searchInputLabel,
              child: DayzSearchField(
                controller: _text,
                focusNode: _focus,
                hintText: l10n.searchHint,
                autofocus: (widget.initialQuery?.trim() ?? '').isEmpty,
                onChanged: _controller.onQueryChanged,
                onSubmitted: (value) => unawaited(_controller.submit(value)),
                onCancel: _cancel,
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => AnimatedSwitcher(
                  key: SearchPage.switcherKey,
                  duration: dayzMotionDuration(context),
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<String>(_bodyKind(_controller.state)),
                    child: _buildBody(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// typing 与 idle 共用建议内容，同一 key 不触发切态过渡。
  String _bodyKind(SearchUiState state) => switch (state) {
    SearchIdle() || SearchTyping() => 'suggestions',
    SearchQuerying() => 'querying',
    SearchResults() => 'results',
    SearchEmpty() => 'empty',
    SearchError() => 'error',
  };

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;
    switch (state) {
      case SearchIdle() || SearchTyping():
        return _Suggestions(
          key: SearchPage.suggestionsKey,
          recent: _controller.recent,
          tags: _controller.tags,
          onPick: _pick,
        );
      case SearchQuerying():
        return const _Querying(key: SearchPage.queryingKey);
      case SearchResults(:final query, :final hits):
        return _Results(
          key: SearchPage.resultsListKey,
          query: query,
          hits: hits,
          filters: _controller.filters,
          onRemoveFilter: _removeFilter,
          onOpen: _openEntry,
        );
      case SearchEmpty(:final query):
        final empty = DayzEmptyState(
          key: SearchPage.emptyStateKey,
          title: l10n.searchEmptyTitle(query),
          description: l10n.searchEmptyDescription,
          illustration: const _SearchIllustration(),
        );
        if (_controller.filters.isEmpty) {
          return empty;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilterSection(
              filters: _controller.filters,
              onRemove: _removeFilter,
            ),
            Expanded(child: empty),
          ],
        );
      case SearchError():
        return DayzEmptyState(
          key: SearchPage.errorStateKey,
          title: l10n.searchErrorTitle,
          description: l10n.searchErrorDescription,
          illustration: const _SearchIllustration(),
          action: DayzButton(
            key: SearchPage.retryButtonKey,
            variant: DayzButtonVariant.soft,
            onPressed: () => unawaited(_controller.retry()),
            child: Text(l10n.searchRetry),
          ),
        );
    }
  }

  void _pick(String term) {
    _text.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    _focus.unfocus();
    unawaited(_controller.pickSuggestion(term));
  }

  void _removeFilter(SearchFilterKind kind) {
    unawaited(_controller.removeFilter(kind));
  }

  void _openEntry(String entryId) {
    _focus.unfocus();
    final open = widget.onOpenEntry;
    if (open != null) {
      open(entryId);
      return;
    }
    GoRouter.maybeOf(context)?.pushNamed(Routes.reader, extra: entryId);
  }

  void _cancel() {
    _focus.unfocus();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final back = widget.onBack;
    if (back != null) {
      back();
      return;
    }
    GoRouter.maybeOf(context)?.goNamed(Routes.timeline);
  }
}

/// idle / typing：「最近搜索」`.suggest-row` 列 + 「标签」chip 列。
class _Suggestions extends StatelessWidget {
  const _Suggestions({
    super.key,
    required this.recent,
    required this.tags,
    required this.onPick,
  });

  final List<RecentSearch> recent;
  final List<TagSuggestion> tags;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.only(
        bottom: DayzSpacing.s4 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (recent.isNotEmpty) ...[
          _SectionHeader(label: l10n.searchRecent),
          for (final item in recent)
            _SuggestRow(
              key: SearchPage.suggestRowKey(item.term),
              item: item,
              onTap: () => onPick(item.term),
            ),
        ],
        if (tags.isNotEmpty)
          _Section(
            // 屏源第二个 `.search-sec` 内联 `padding-top: var(--sp-4)`。
            top: recent.isNotEmpty ? DayzSpacing.s4 : DayzSpacing.s2,
            label: l10n.searchTags,
            child: Wrap(
              // `.chips { gap: 8px }`
              spacing: DayzSpacing.s2,
              runSpacing: DayzSpacing.s2,
              children: [
                for (final tag in tags)
                  DayzTag(
                    key: SearchPage.tagChipKey(tag.id),
                    onTap: () => onPick(tag.name),
                    child: Text(l10n.searchTagChip(tag.name)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// `.search-sec`（`padding: sp-2 sp-4 sp-4`）只含标题时的形态。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Section(label: label, child: null);
  }
}

/// `.search-sec` + `.h`（11px / 600 / 0.12em / 大写 / ink-3，`margin-bottom: sp-3`）。
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.child,
    this.top = DayzSpacing.s2,
  });

  final String label;
  final Widget? child;
  final double top;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        top,
        DayzSpacing.s4,
        DayzSpacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              label.toUpperCase(),
              style: text.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.12 * 11,
                color: colors.ink3,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: DayzSpacing.s3),
          ?child,
        ],
      ),
    );
  }
}

/// `.suggest-row`：18px 时钟图标 + 词（15px ink）+ 可选「N 篇」（12px ink-3）。
class _SuggestRow extends StatelessWidget {
  const _SuggestRow({super.key, required this.item, required this.onTap});

  final RecentSearch item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final l10n = AppLocalizations.of(context);
    final count = item.count;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            // `.suggest-row { padding: 12px var(--sp-4); gap: var(--sp-3) }`
            padding: const EdgeInsets.symmetric(
              horizontal: DayzSpacing.s4,
              vertical: 12,
            ),
            child: Row(
              children: [
                DayzIcon.path(
                  DayzIcons.clockPath,
                  size: 18,
                  color: colors.ink3,
                ),
                const SizedBox(width: DayzSpacing.s3),
                Expanded(
                  child: Text(
                    item.term,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.body.copyWith(
                      fontSize: 15,
                      color: colors.ink,
                      height: 1.3,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    l10n.searchRecentCount(count),
                    style: text.caption.copyWith(
                      fontSize: 12,
                      color: colors.ink3,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// querying：静态一行「正在搜索…」（无转圈动画，免 reduce-motion 分支）。
class _Querying extends StatelessWidget {
  const _Querying({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(DayzSpacing.s6),
        child: Semantics(
          liveRegion: true,
          child: Text(
            AppLocalizations.of(context).searchQuerying,
            style: text.caption.copyWith(fontSize: 13, color: colors.ink3),
          ),
        ),
      ),
    );
  }
}

/// results：筛选区（有才渲）+ `.search-stat` + 朴素列表（D3，不吸顶不分页）。
class _Results extends StatelessWidget {
  const _Results({
    super.key,
    required this.query,
    required this.hits,
    required this.filters,
    required this.onRemoveFilter,
    required this.onOpen,
  });

  final String query;
  final List<EntrySearchHit> hits;
  final SearchFilters filters;
  final ValueChanged<SearchFilterKind> onRemoveFilter;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final header = <Widget>[
      if (!filters.isEmpty)
        _FilterSection(filters: filters, onRemove: onRemoveFilter),
      _ResultStat(count: hits.length),
    ];
    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: DayzSpacing.s4 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: header.length + hits.length,
      itemBuilder: (context, index) {
        if (index < header.length) {
          return header[index];
        }
        final position = index - header.length;
        final hit = hits[position];
        // `.timeline { padding: sp-2 sp-4 sp-4; gap: sp-4 }`
        return Padding(
          padding: EdgeInsets.fromLTRB(
            DayzSpacing.s4,
            position == 0 ? DayzSpacing.s2 : 0,
            DayzSpacing.s4,
            DayzSpacing.s4,
          ),
          child: _SearchHitCard(
            key: SearchPage.hitCardKey(hit.id),
            hit: hit,
            query: query,
            onTap: () => onOpen(hit.id),
          ),
        );
      },
    );
  }
}

/// `.search-stat`：13px ink-3，计数 `<b>` 段 ink-2 / 600。
class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final label = AppLocalizations.of(context).searchResultStat(count);
    final number = '$count';
    final at = label.indexOf(number);
    final base = text.caption.copyWith(fontSize: 13, color: colors.ink3);
    final bold = TextStyle(color: colors.ink2, fontWeight: FontWeight.w600);
    return Padding(
      // `.search-stat { padding: 0 var(--sp-4) var(--sp-3) }`
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        0,
        DayzSpacing.s4,
        DayzSpacing.s3,
      ),
      child: Text.rich(
        key: SearchPage.resultStatKey,
        TextSpan(
          style: base,
          children: at < 0
              ? [TextSpan(text: label)]
              : [
                  TextSpan(text: label.substring(0, at)),
                  TextSpan(text: number, style: bold),
                  TextSpan(text: label.substring(at + number.length)),
                ],
        ),
      ),
    );
  }
}

/// 已生效筛选（D8）：每个条件一枚实底 chip + 去除叉。
class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.filters, required this.onRemove});

  final SearchFilters filters;
  final ValueChanged<SearchFilterKind> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final journal = filters.journal;
    final year = filters.year;
    final chips = <(SearchFilterKind, String)>[
      if (journal != null) (SearchFilterKind.journal, journal.name),
      if (year != null)
        (SearchFilterKind.year, DateFormat.y(locale).format(DateTime(year))),
    ];
    return KeyedSubtree(
      key: SearchPage.filtersKey,
      child: _Section(
        label: l10n.searchFilters,
        child: Wrap(
          spacing: DayzSpacing.s2,
          runSpacing: DayzSpacing.s2,
          children: [
            for (final (kind, label) in chips)
              DayzTag(
                key: SearchPage.filterChipKey(kind),
                onRemove: () => onRemove(kind),
                removeSemanticLabel: l10n.searchRemoveFilter(label),
                child: Text(label),
              ),
          ],
        ),
      ),
    );
  }
}

/// 结果卡片（D3）：几何与样式照 `DayzEntryCard` / `.entry`，标题与摘要换成
/// 命中高亮的 `Text.rich`（`DayzEntryCard` 尚无富文本槽，补齐后换回组件）。
class _SearchHitCard extends StatelessWidget {
  const _SearchHitCard({
    super.key,
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final EntrySearchHit hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(DayzRadii.md);
    // `.hl { background: var(--accent-soft-2); color: var(--accent-ink) }`
    final hitStyle = TextStyle(
      backgroundColor: colors.accentSoft2,
      color: colors.accentInk,
    );
    // `.card h4`：17px / 600 / 1.25
    final titleStyle = text.h2.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: colors.ink,
    );
    // `.card .excerpt`：diary 14px / 1.7 / ink-2
    final excerptStyle = text.diary.copyWith(
      fontSize: 14,
      height: 1.7,
      color: colors.ink2,
    );
    final excerpt = snippetAround(hit.excerpt, query);
    final place = hit.place;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: l10n.searchOpenEntry(hit.title),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 52, child: _DateRail(date: hit.date)),
          const SizedBox(width: DayzSpacing.s3),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                excludeFromSemantics: true,
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.hairline),
                    borderRadius: radius,
                    boxShadow: colors.shadowSm,
                  ),
                  child: Padding(
                    // `.card .body`
                    padding: const EdgeInsets.fromLTRB(
                      DayzSpacing.s4,
                      DayzSpacing.s3,
                      DayzSpacing.s4,
                      DayzSpacing.s4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          key: SearchPage.hitTitleKey(hit.id),
                          TextSpan(
                            style: titleStyle,
                            children: buildHighlightedSpans(
                              hit.title,
                              query,
                              titleStyle,
                              hitStyle,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (excerpt.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text.rich(
                            key: SearchPage.hitExcerptKey(hit.id),
                            TextSpan(
                              style: excerptStyle,
                              children: buildHighlightedSpans(
                                excerpt,
                                query,
                                excerptStyle,
                                hitStyle,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (place != null && place.isNotEmpty) ...[
                          const SizedBox(height: DayzSpacing.s3),
                          // `.card .foot .meta`：12px 定位针 + 11px ink-3
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DayzIcon.path(
                                DayzIcons.locationPinPath,
                                size: 12,
                                color: colors.ink3,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  place,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.caption.copyWith(
                                    fontSize: 11,
                                    color: colors.ink3,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.entry .date`：日（26px）/ 月缩写（11px 大写）/ 星期（11px accent-ink）。
class _DateRail extends StatelessWidget {
  const _DateRail({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: text.h2.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat.MMM(locale).format(date).toUpperCase(),
            style: text.caption.copyWith(
              fontSize: 11,
              color: colors.ink3,
              // `.entry .date .m { letter-spacing: 0.06em }`
              letterSpacing: 0.06 * 11,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat.E(locale).format(date),
            style: text.caption.copyWith(
              fontSize: 11,
              color: colors.accentInk,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.empty .ill`：放大镜 + 减号线性图（1.8 描边、ink-2）。
class _SearchIllustration extends StatelessWidget {
  const _SearchIllustration();

  /// 照抄屏源 `<circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2M8.5 11h5"/>`。
  static const String _markup =
      '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2M8.5 11h5"/>';

  @override
  Widget build(BuildContext context) {
    return DayzIcon(
      _markup,
      size: 30,
      color: context.dayz.ink2,
      strokeWidth: 1.8,
    );
  }
}
