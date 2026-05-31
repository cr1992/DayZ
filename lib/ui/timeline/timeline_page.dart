// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/shell/shell_state.dart';
import 'package:dayz/ui/util/dayz_motion.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';

import 'timeline_calendar_panel.dart';
import 'timeline_controller.dart';
import 'timeline_loader.dart';
import 'timeline_month_section.dart';

class TimelineShellPage extends StatefulWidget {
  const TimelineShellPage({
    super.key,
    required this.repo,
    required this.shellState,
  });

  final EntryRepo repo;
  final ShellState shellState;

  @override
  State<TimelineShellPage> createState() => _TimelineShellPageState();
}

class _TimelineShellPageState extends State<TimelineShellPage> {
  late final TimelineController _controller;
  String? _activeJournalId;

  @override
  void initState() {
    super.initState();
    _controller = TimelineController(repo: widget.repo);
    _activeJournalId = widget.shellState.currentJournalId;
    widget.shellState.addListener(_handleShellJournalChanged);
    unawaited(_controller.loadInitial(_activeJournalId));
  }

  @override
  void didUpdateWidget(covariant TimelineShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shellState != widget.shellState) {
      oldWidget.shellState.removeListener(_handleShellJournalChanged);
      _activeJournalId = widget.shellState.currentJournalId;
      widget.shellState.addListener(_handleShellJournalChanged);
      unawaited(_controller.switchJournal(_activeJournalId));
    }
  }

  @override
  void dispose() {
    widget.shellState.removeListener(_handleShellJournalChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TimelinePage(controller: _controller, showAppBar: false);
  }

  void _handleShellJournalChanged() {
    final nextJournalId = widget.shellState.currentJournalId;
    if (nextJournalId == _activeJournalId) {
      return;
    }
    _activeJournalId = nextJournalId;
    unawaited(_controller.switchJournal(nextJournalId));
  }
}

class TimelinePage extends StatefulWidget {
  const TimelinePage({
    super.key,
    required this.controller,
    this.showAppBar = true,
  });

  final TimelineController controller;
  final bool showAppBar;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  late final ScrollController _scrollController;
  final Map<TimelineMonthKey, GlobalKey> _headerKeys =
      <TimelineMonthKey, GlobalKey>{};
  int _headerKeyEpoch = 0;
  TimelineMonthKey? _expandedCalendarMonth;
  TimelineMonthKey? _pendingScrollMonth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        _syncHeaderKeysEpoch();
        final contentKey = ValueKey<String>(
          'timeline-content-${widget.controller.contentEpoch}-${widget.controller.journalId ?? 'all'}',
        );
        return AnimatedSwitcher(
          key: const ValueKey<String>('timeline-content-switcher'),
          duration: dayzMotionDuration(context),
          child: KeyedSubtree(
            key: contentKey,
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    if (widget.showAppBar)
                      DayzGlassAppBar(
                        scrollController: _scrollController,
                        title: Text(
                          l10n.timeline,
                          key: const ValueKey<String>('timeline-page-title'),
                        ),
                      ),
                    ..._buildBodySlivers(context, l10n),
                  ],
                ),
                _buildCalendarOverlay(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarOverlay(BuildContext context) {
    final isOpen = _expandedCalendarMonth != null;
    if (!isOpen) {
      return const SizedBox.shrink();
    }

    final duration = dayzMotionDuration(context);
    final panelTop =
        MediaQuery.paddingOf(context).top +
        kToolbarHeight +
        TimelineMonthHeaderDelegate.extent;

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            top: panelTop,
            child: GestureDetector(
              key: const ValueKey<String>('timeline-calendar-scrim'),
              behavior: HitTestBehavior.opaque,
              onTap: _closeCalendar,
              child: ColoredBox(color: context.dayz.overlay),
            ),
          ),
          Positioned(
            top: panelTop,
            left: DayzSpacing.s4,
            right: DayzSpacing.s4,
            child: AnimatedSlide(
              key: const ValueKey<String>('timeline-calendar-slide'),
              duration: duration,
              curve: Curves.easeOutCubic,
              offset: Offset.zero,
              child: TimelineCalendarPanel(
                months: widget.controller.availableMonths,
                selectedMonth: _expandedCalendarMonth,
                monthCountFor: (key) =>
                    widget.controller.monthCountFor(key.year, key.month),
                onMonthSelected: (key) =>
                    _handleCalendarMonthSelected(context, key),
                onToday: () => _jumpToCurrentMonth(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers(BuildContext context, AppLocalizations l10n) {
    if (widget.controller.sections.isEmpty && widget.controller.reachedEnd) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.only(top: DayzSpacing.s16),
            child: DayzEmptyState(
              title: l10n.timelineEmptyTitle,
              description: l10n.timelineEmptyDescription,
            ),
          ),
        ),
      ];
    }

    return [
      for (final section in widget.controller.sections)
        buildTimelineMonthSliverGroup(
          section: section,
          headerKey: _headerKeyFor(section.key),
          headerOnTap: () => _toggleCalendar(section.key),
          headerExpanded: section.key == _expandedCalendarMonth,
          cardBuilder: (entry) => buildTimelineEntryCard(
            entry,
            onTap: () => _openEntry(context, entry.id),
          ),
        ),
      SliverToBoxAdapter(
        child: TimelineLoader(
          isLoading: widget.controller.isLoading,
          reachedEnd: widget.controller.reachedEnd,
        ),
      ),
    ];
  }

  GlobalKey _headerKeyFor(TimelineMonthKey key) {
    return _headerKeys.putIfAbsent(
      key,
      () => GlobalKey(debugLabel: 'timeline-header-${key.year}-${key.month}'),
    );
  }

  void _syncHeaderKeysEpoch() {
    final currentEpoch = widget.controller.contentEpoch;
    if (_headerKeyEpoch == currentEpoch) {
      return;
    }

    _headerKeyEpoch = currentEpoch;
    _headerKeys.clear();
  }

  void _openEntry(BuildContext context, String entryId) {
    context.goNamed(Routes.reader, extra: entryId);
  }

  void _toggleCalendar(TimelineMonthKey key) {
    setState(() {
      if (_expandedCalendarMonth == key) {
        _expandedCalendarMonth = null;
        return;
      }
      _expandedCalendarMonth = key;
    });
  }

  void _closeCalendar() {
    if (_expandedCalendarMonth == null) {
      return;
    }
    setState(() {
      _expandedCalendarMonth = null;
    });
  }

  Future<void> _handleCalendarMonthSelected(
    BuildContext context,
    TimelineMonthKey key,
  ) async {
    _closeCalendar();
    await widget.controller.jumpToMonth(key.year, key.month);
    while (!widget.controller.reachedEnd &&
        widget.controller.sections.isNotEmpty &&
        widget.controller.sections.last.key == key) {
      await widget.controller.loadMore();
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingScrollMonth = key;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingScrollMonth != key) {
        return;
      }
      _alignMonthHeaderToTop(context, key, remainingAttempts: 2);
    });
  }

  Future<void> _jumpToCurrentMonth(BuildContext context) async {
    final now = DateTime.now();
    final todayKey = TimelineMonthKey(now.year, now.month);
    final target = widget.controller.availableMonths.contains(todayKey)
        ? todayKey
        : (widget.controller.availableMonths.isNotEmpty
              ? widget.controller.availableMonths.first
              : null);
    if (target == null) {
      _closeCalendar();
      return;
    }

    await _handleCalendarMonthSelected(context, target);
  }

  void _alignMonthHeaderToTop(
    BuildContext context,
    TimelineMonthKey key, {
    required int remainingAttempts,
  }) {
    final targetContext = _headerKeyFor(key).currentContext;
    if (targetContext == null) {
      _pendingScrollMonth = null;
      return;
    }

    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !_scrollController.hasClients) {
      _pendingScrollMonth = null;
      return;
    }

    final desiredTop = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final currentTop = renderObject.localToGlobal(Offset.zero).dy;
    final delta = currentTop - desiredTop;
    final targetOffset = (_scrollController.offset + delta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    final duration = dayzMotionDuration(context);

    if ((targetOffset - _scrollController.offset).abs() < 1 ||
        remainingAttempts <= 0) {
      _pendingScrollMonth = null;
      return;
    }

    if (duration == Duration.zero) {
      _scrollController.jumpTo(targetOffset);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pendingScrollMonth != key) {
          return;
        }
        _alignMonthHeaderToTop(
          context,
          key,
          remainingAttempts: remainingAttempts - 1,
        );
      });
      return;
    }

    _scrollController
        .animateTo(targetOffset, duration: duration, curve: Curves.easeOutCubic)
        .whenComplete(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _pendingScrollMonth != key) {
              return;
            }
            _alignMonthHeaderToTop(
              context,
              key,
              remainingAttempts: remainingAttempts - 1,
            );
          });
        });
  }
}
