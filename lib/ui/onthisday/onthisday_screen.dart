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
import 'onthisday_controller.dart';
import 'onthisday_view_model.dart';

/// 路由层宿主：持有 [OnThisDayController]，首帧取今天的往年今日，条目表变更
/// （阅读屏改收藏 / 删除等）即回刷；出数前只渲染顶栏骨架。
///
/// Author: @Ray
class OnThisDayPage extends StatefulWidget {
  const OnThisDayPage({
    super.key,
    required this.repository,
    this.thumbnails,
    this.clock,
  });

  final OnThisDayRepository repository;
  final OnThisDayThumbnails? thumbnails;
  final DateTime Function()? clock;

  @override
  State<OnThisDayPage> createState() => _OnThisDayPageState();
}

class _OnThisDayPageState extends State<OnThisDayPage> {
  late OnThisDayController _controller;
  late StreamSubscription<void> _changes;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant OnThisDayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.thumbnails != widget.thumbnails) {
      _detach();
      _attach();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _attach() {
    _controller = OnThisDayController(
      repository: widget.repository,
      thumbnails: widget.thumbnails,
      clock: widget.clock,
    );
    _changes = widget.repository.watchChanges().listen(
      (_) => unawaited(_controller.reload()),
    );
    unawaited(_controller.load());
  }

  void _detach() {
    unawaited(_changes.cancel());
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => OnThisDayScreen(data: _controller.data),
    );
  }
}

/// 往年今日屏：顶栏 + 屏头摘要 + 年份分隔（普通行，非吸顶）与日记卡片的扁平列表。
///
/// 只吃 [OnThisDayData]；取数 / 缩略图编排在屏外（`onthisday_controller.dart`）。
///
/// Author: @Ray
class OnThisDayScreen extends StatefulWidget {
  const OnThisDayScreen({
    super.key,
    required this.data,
    this.onOpenEntry,
    this.onOpenMemory,
    this.onBack,
  });

  static const Key backButtonKey = ValueKey<String>('onthisday-back');
  static const Key moreButtonKey = ValueKey<String>('onthisday-more');
  static const Key headerKey = ValueKey<String>('onthisday-header');
  static const Key kickerKey = ValueKey<String>('onthisday-kicker');
  static const Key headlineKey = ValueKey<String>('onthisday-headline');
  static const Key subtitleKey = ValueKey<String>('onthisday-subtitle');
  static const Key emptyStateKey = ValueKey<String>('onthisday-empty');
  static const Key emptyIllustrationKey = ValueKey<String>(
    'onthisday-empty-illustration',
  );

  static ValueKey<String> yearSeparatorKey(int year) =>
      ValueKey<String>('onthisday-year-$year');

  static ValueKey<String> entryCardKey(String entryId) =>
      ValueKey<String>('onthisday-entry-$entryId');

  /// 屏数据；null 表示加载中（只渲染顶栏骨架，更多钮不可用）。
  final OnThisDayData? data;

  /// 点卡片；缺省经 `go_router` 推 [Routes.reader]（携 entryId）。
  final ValueChanged<String>? onOpenEntry;

  /// ⋯ 菜单「生成回忆卡片」；缺省经 `go_router` 推 [Routes.memory]
  /// （extra 携 `{'month', 'day'}`）。
  final ValueChanged<DateTime>? onOpenMemory;

  /// 返回钮在路由栈无法出栈时的兜底；可出栈时一律先出栈。
  final VoidCallback? onBack;

  @override
  State<OnThisDayScreen> createState() => _OnThisDayScreenState();
}

class _OnThisDayScreenState extends State<OnThisDayScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;
    final data = widget.data;
    final rows = data == null ? const <OnThisDayRow>[] : flatten(data);

    return Scaffold(
      backgroundColor: colors.bg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          DayzGlassAppBar(
            scrollController: _scrollController,
            centerTitle: false,
            leading: _TopIconButton(
              key: OnThisDayScreen.backButtonKey,
              label: l10n.onThisDayBack,
              path: DayzIcons.chevronLeftPath,
              onPressed: _goBack,
            ),
            title: Text(l10n.onThisDay),
            actions: [
              _TopIconButton(
                key: OnThisDayScreen.moreButtonKey,
                label: l10n.more,
                path: DayzIcons.morePath,
                filled: true,
                onPressed: data == null ? null : _openMenu,
              ),
            ],
          ),
          // `data-when="empty"`：整屏换空态，不渲染屏头与年份段。
          if (data == null)
            const SliverToBoxAdapter(child: SizedBox.shrink())
          else if (data.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DayzEmptyState(
                key: OnThisDayScreen.emptyStateKey,
                title: l10n.onThisDayEmptyTitle,
                description: l10n.onThisDayEmptyDescription,
                // `.empty .ill`：时钟回拨线性图，1.7 描边、ink-2。
                illustration: DayzIcon.path(
                  DayzIcons.historyClockPath,
                  key: OnThisDayScreen.emptyIllustrationKey,
                  size: 30,
                  color: colors.ink2,
                  strokeWidth: 1.7,
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _OnThisDayHeader(data: data)),
            SliverPadding(
              // `.app-scroll > :last-child { margin-bottom: 92px }`
              padding: const EdgeInsets.only(bottom: 92),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRow(rows, index),
                  childCount: rows.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(List<OnThisDayRow> rows, int index) {
    final row = rows[index];
    switch (row) {
      case YearSeparatorRow(:final year, :final yearsAgo):
        // 普通列表项、随内容滚走：MUST NOT 包进 SliverPersistentHeader（D2）。
        return DayzYearSeparator(
          key: OnThisDayScreen.yearSeparatorKey(year),
          year: year,
          referenceDate: DateTime(year + yearsAgo),
        );
      case EntryCardRow(:final entry):
        final firstInYear = index > 0 && rows[index - 1] is YearSeparatorRow;
        // `.timeline { padding: sp-2 sp-4 sp-4; gap: sp-4 }`
        return Padding(
          padding: EdgeInsets.fromLTRB(
            DayzSpacing.s4,
            firstInYear ? DayzSpacing.s2 : 0,
            DayzSpacing.s4,
            DayzSpacing.s4,
          ),
          child: _OnThisDayEntryCard(
            key: OnThisDayScreen.entryCardKey(entry.entryId),
            entry: entry,
            onTap: () => _openEntry(entry.entryId),
          ),
        );
    }
  }

  void _openEntry(String entryId) {
    final open = widget.onOpenEntry;
    if (open != null) {
      open(entryId);
      return;
    }
    GoRouter.maybeOf(context)?.pushNamed(Routes.reader, extra: entryId);
  }

  void _openMenu() {
    final l10n = AppLocalizations.of(context);
    DayzSheet.actions<void>(
      context,
      items: [
        DayzSheetItem(
          label: l10n.onThisDayMenuMemoryCard,
          desc: l10n.onThisDayMenuMemoryCardDesc,
          onTap: _openMemory,
        ),
        DayzSheetItem(
          label: l10n.onThisDayMenuShare,
          onTap: () => DayzToast.show(
            context,
            l10n.onThisDayShareDone,
            DayzToastTone.ok,
          ),
        ),
      ],
    );
  }

  void _openMemory() {
    final date = widget.data!.date;
    final open = widget.onOpenMemory;
    if (open != null) {
      open(date);
      return;
    }
    GoRouter.maybeOf(context)?.pushNamed(
      Routes.memory,
      extra: <String, int>{'month': date.month, 'day': date.day},
    );
  }

  void _goBack() {
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

/// 屏头摘要：日期 kicker + 衬线标题（篇数）+ 副文案。
class _OnThisDayHeader extends StatelessWidget {
  const _OnThisDayHeader({required this.data});

  final OnThisDayData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;
    final text = context.dayzText;
    final locale = Localizations.localeOf(context).toLanguageTag();

    // `padding: var(--sp-2) var(--sp-5) var(--sp-4)`
    return Padding(
      key: OnThisDayScreen.headerKey,
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s5,
        DayzSpacing.s2,
        DayzSpacing.s5,
        DayzSpacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `.t-overline` + `color: var(--accent-ink)`（overline 大写）
          Text(
            DateFormat.MMMd(locale).format(data.date).toUpperCase(),
            key: OnThisDayScreen.kickerKey,
            style: text.overline.copyWith(color: colors.accentInk),
          ),
          const SizedBox(height: 6),
          // serif 25px / 600 / letter-spacing -0.01em（body line-height 1.6）
          Text(
            l10n.onThisDayHeadline(data.totalCount),
            key: OnThisDayScreen.headlineKey,
            style: text.h2.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.01 * 25,
              height: 1.6,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: DayzSpacing.s2),
          // `font-size: 13px; color: var(--ink-2); line-height: 1.7`
          Text(
            l10n.onThisDaySubtitle,
            key: OnThisDayScreen.subtitleKey,
            style: text.caption.copyWith(
              fontSize: 13,
              height: 1.7,
              color: colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnThisDayEntryCard extends StatelessWidget {
  const _OnThisDayEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final EntryCardVM entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = entry.place;
    // 卡片 InkWell 自身不进语义树（excludeFromSemantics），由这里补「可点 +
    // 打开某篇」语义，读屏可直接激活。
    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: AppLocalizations.of(context).onThisDayOpenEntry(entry.title),
      onTap: onTap,
      child: DayzEntryCard(
        title: entry.title,
        summary: entry.excerpt,
        date: entry.date,
        tags: entry.tags,
        meta: [
          if (place != null && place.isNotEmpty)
            DayzEntryMeta(label: place, icon: const _MetaIcon()),
        ],
        favorite: entry.favorite,
        showFavorite: entry.favorite,
        cover: entry.coverImage,
        onTap: onTap,
      ),
    );
  }
}

/// `.card .foot .meta svg`：12px 定位针，颜色/尺寸取卡片设的 [IconTheme]。
class _MetaIcon extends StatelessWidget {
  const _MetaIcon();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return DayzIcon.path(
      DayzIcons.locationPinPath,
      size: iconTheme.size ?? 12,
      color: iconTheme.color ?? context.dayz.ink3,
    );
  }
}

/// `.app-top .ico`：20px 图标、ink-2，命中区 44×44。
class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    super.key,
    required this.label,
    required this.path,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final String path;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: IconButton(
          tooltip: label,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          onPressed: onPressed,
          icon: DayzIcon.path(
            path,
            size: 20,
            color: context.dayz.ink2,
            filled: filled,
          ),
        ),
      ),
    );
  }
}
