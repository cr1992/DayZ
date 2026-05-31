// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/util/dayz_motion.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';

import 'timeline_calendar_panel.dart';
import 'timeline_controller.dart';
import 'timeline_loader.dart';
import 'timeline_month_section.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key, required this.controller});

  final TimelineController controller;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  late final ScrollController _scrollController;
  final Map<TimelineMonthKey, GlobalKey> _headerKeys =
      <TimelineMonthKey, GlobalKey>{};
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
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
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
                    DayzGlassAppBar(
                      scrollController: _scrollController,
                      title: const Text(
                        AppStrings.timeline,
                        key: ValueKey<String>('timeline-page-title'),
                      ),
                    ),
                    ..._buildBodySlivers(context),
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

  List<Widget> _buildBodySlivers(BuildContext context) {
    if (widget.controller.sections.isEmpty && widget.controller.reachedEnd) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(top: DayzSpacing.s16),
            child: DayzEmptyState(
              title: AppStrings.timelineEmptyTitle,
              description: AppStrings.timelineEmptyDescription,
            ),
          ),
        ),
      ];
    }

    return [
      for (final section in widget.controller.sections)
        ...buildTimelineMonthSlivers(
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
    final pinnedAdjustment =
        widget.controller.sections.isNotEmpty &&
            widget.controller.sections.first.key != key
        ? TimelineMonthHeaderDelegate.extent
        : 0.0;
    final targetOffset = (_scrollController.offset + delta + pinnedAdjustment)
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
