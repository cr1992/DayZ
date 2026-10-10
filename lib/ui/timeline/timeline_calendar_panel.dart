// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';

import 'timeline_month_section.dart';

/// 日历面板的两种视图：月视图（星期 + 日格）/ 年视图（12 个月格）。
enum TimelineCalendarMode { month, year }

/// 命中区下限（NF3；设计稿 CLAUDE.md「移动端点击目标 ≥ 44px」）。
const double _kMinHitExtent = 44;

/// 时间线「跳转到日期」日历面板（设计稿 `timeline.css` `.cal-panel` 及
/// `timeline.js` 的 renderMonthView / renderYearView）。
///
/// 只负责面板本体：月/年视图切换、翻月/翻年、各态日格/月格与「回到今天」。
/// 落下/收起动效与 scrim 由 [TimelinePage] 的 overlay 承担；选中后的月级
/// 定位（D6）经 [onMonthSelected] 交给页面。
class TimelineCalendarPanel extends StatefulWidget {
  const TimelineCalendarPanel({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.today,
    required this.monthCountFor,
    required this.entryDaysFor,
    required this.onMonthSelected,
    required this.onToday,
  });

  static const Key panelKey = ValueKey<String>('timeline-calendar-panel');
  static const Key titleKey = ValueKey<String>('timeline-calendar-title');
  static const Key previousKey = ValueKey<String>('timeline-calendar-prev');
  static const Key nextKey = ValueKey<String>('timeline-calendar-next');
  static const Key todayKey = ValueKey<String>('timeline-calendar-today');

  /// 有条目的月份（D4：优先 `monthCounts`，降级为已加载分页）。
  final List<TimelineMonthKey> months;

  /// 打开面板时所在的月份（被点的月份头）；面板以它的月视图起手。
  final TimelineMonthKey selectedMonth;

  /// 「今天」，决定 `.cal-day.today` / `.cal-mo.cur`。
  final DateTime today;

  final int? Function(TimelineMonthKey key) monthCountFor;

  /// 某月「有条目的日」集合（D4：`entryDaysInMonth`，降级为已加载分页）。
  final Future<Set<int>> Function(TimelineMonthKey key) entryDaysFor;

  /// 选中有条目的日或月。定位是月级的（D6），日格也只回传所在月份。
  final ValueChanged<TimelineMonthKey> onMonthSelected;

  final VoidCallback onToday;

  @override
  State<TimelineCalendarPanel> createState() => _TimelineCalendarPanelState();
}

class _TimelineCalendarPanelState extends State<TimelineCalendarPanel> {
  late TimelineMonthKey _view;
  TimelineCalendarMode _mode = TimelineCalendarMode.month;
  final Map<TimelineMonthKey, Set<int>> _entryDays =
      <TimelineMonthKey, Set<int>>{};

  @override
  void initState() {
    super.initState();
    _view = widget.selectedMonth;
    _loadEntryDays(_view);
  }

  @override
  void didUpdateWidget(covariant TimelineCalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 面板开着时点了另一个月份头：同 timeline.js openCal，回到该月的月视图。
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _view = widget.selectedMonth;
      _mode = TimelineCalendarMode.month;
      _loadEntryDays(_view);
    } else {
      // 页面随 controller 重建（如补载了更多分页）→ 降级口径下有条目日可能
      // 变多，刷新当前视图月；旧值保留到新值回来，避免圆点闪烁。
      _loadEntryDays(_view, force: true);
    }
  }

  void _loadEntryDays(TimelineMonthKey key, {bool force = false}) {
    if (!force && _entryDays.containsKey(key)) {
      return;
    }
    unawaited(
      widget.entryDaysFor(key).then((days) {
        if (!mounted) {
          return;
        }
        setState(() {
          _entryDays[key] = days;
        });
      }),
    );
  }

  void _shiftView(int months) {
    setState(() {
      final shifted = DateTime(_view.year, _view.month + months);
      _view = TimelineMonthKey(shifted.year, shifted.month);
    });
    _loadEntryDays(_view);
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == TimelineCalendarMode.month
          ? TimelineCalendarMode.year
          : TimelineCalendarMode.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isMonth = _mode == TimelineCalendarMode.month;

    return Semantics(
      key: TimelineCalendarPanel.panelKey,
      // `.cal-panel[role=dialog][aria-label=跳转到日期]`（NF5）。
      role: SemanticsRole.dialog,
      label: l10n.jumpToDate,
      container: true,
      explicitChildNodes: true,
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          // `.cal-panel`：surface / 1px hairline / r-lg / shadow-lg。
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(DayzRadii.lg),
            border: Border.all(color: colors.hairline),
            boxShadow: colors.shadowLg,
          ),
          child: Padding(
            // `.cal-panel { padding: var(--sp-4) var(--sp-4) var(--sp-3) }`
            padding: const EdgeInsets.fromLTRB(
              DayzSpacing.s4,
              DayzSpacing.s4,
              DayzSpacing.s4,
              DayzSpacing.s3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHead(context, l10n, locale, isMonth),
                // `.cal-head { margin-bottom: var(--sp-3) }`
                const SizedBox(height: DayzSpacing.s3),
                if (isMonth) ...[
                  _buildWeekdays(context, locale),
                  // `.cal-wd { margin-bottom: 4px }`
                  const SizedBox(height: DayzSpacing.s1),
                  _buildDayGrid(context, locale),
                  // `.cal-foot { margin-top: var(--sp-3) }`
                  const SizedBox(height: DayzSpacing.s3),
                  Center(child: _buildTodayButton(context, l10n)),
                ] else
                  _buildMonthGrid(context, l10n, locale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHead(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    bool isMonth,
  ) {
    final colors = context.dayz;
    final text = context.dayzText;
    final title = isMonth
        ? DateFormat.yMMMM(locale).format(_view.date)
        : DateFormat.y(locale).format(_view.date);

    return Row(
      children: [
        _CalendarNavButton(
          key: TimelineCalendarPanel.previousKey,
          label: isMonth
              ? l10n.calendarPreviousMonth
              : l10n.calendarPreviousYear,
          flip: true,
          onTap: () => _shiftView(isMonth ? -1 : -12),
        ),
        Expanded(
          child: Center(
            child: Semantics(
              button: true,
              label: title,
              excludeSemantics: true,
              child: InkWell(
                key: TimelineCalendarPanel.titleKey,
                onTap: _toggleMode,
                borderRadius: BorderRadius.circular(DayzRadii.sm),
                hoverColor: colors.bg2,
                highlightColor: colors.bg2,
                splashColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _kMinHitExtent),
                  child: Padding(
                    // `.cal-title { padding: 6px 8px; gap: 6px }`
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // `.cal-title`: serif 17px / 600 / ink。
                            style: text.diary.copyWith(
                              fontSize: 17,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: colors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // `.cal-title svg`：14px ink-3 下拉 caret（chevron 转 90°）。
                        RotatedBox(
                          quarterTurns: 1,
                          child: DayzIcon.path(
                            DayzIcons.chevronRightPath,
                            size: 14,
                            color: colors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _CalendarNavButton(
          key: TimelineCalendarPanel.nextKey,
          label: isMonth ? l10n.calendarNextMonth : l10n.calendarNextYear,
          flip: false,
          onTap: () => _shiftView(isMonth ? 1 : 12),
        ),
      ],
    );
  }

  Widget _buildWeekdays(BuildContext context, String locale) {
    final colors = context.dayz;
    final text = context.dayzText;
    // 周一起始（timeline.js `WD` / `firstWD`）。2024-01-01 是周一。
    final narrow = DateFormat('EEEEE', locale);

    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < DateTime.daysPerWeek; i++)
            Expanded(
              child: Padding(
                // `.cal-wd span { padding: 2px 0 }`
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  narrow.format(DateTime(2024, 1, 1 + i)),
                  textAlign: TextAlign.center,
                  // `.cal-wd span`: 11px ink-3。
                  style: text.caption.copyWith(
                    fontSize: 11,
                    color: colors.ink3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayGrid(BuildContext context, String locale) {
    final firstWeekday = DateTime(_view.year, _view.month).weekday; // 1 = 周一
    final pad = firstWeekday - DateTime.monday;
    final daysInMonth = DateUtils.getDaysInMonth(_view.year, _view.month);
    final entryDays = _entryDays[_view] ?? const <int>{};
    final isTodayMonth =
        widget.today.year == _view.year && widget.today.month == _view.month;
    final dateLabel = DateFormat.yMMMd(locale);

    return LayoutBuilder(
      builder: (context, constraints) {
        // `.cal-grid { gap: 1px }`；`.cal-day { aspect-ratio: 1; min-height: 38px }`，
        // 高度下限抬到 44 满足 NF3。
        const gap = 1.0;
        final cellWidth =
            (constraints.maxWidth - gap * (DateTime.daysPerWeek - 1)) /
            DateTime.daysPerWeek;
        final cellHeight = math.max(cellWidth, _kMinHitExtent);

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DateTime.daysPerWeek,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: cellHeight,
          ),
          itemCount: pad + daysInMonth,
          itemBuilder: (context, index) {
            if (index < pad) {
              // `.cal-day.pad { visibility: hidden }`
              return const SizedBox.shrink();
            }
            final day = index - pad + 1;
            final has = entryDays.contains(day);
            return _CalendarDayCell(
              key: timelineCalendarDayTestKey(_view.year, _view.month, day),
              day: day,
              semanticLabel: dateLabel.format(
                DateTime(_view.year, _view.month, day),
              ),
              has: has,
              isToday: isTodayMonth && widget.today.day == day,
              onTap: has ? () => widget.onMonthSelected(_view) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final available = widget.months.toSet();

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      // `.cal-months { grid-template-columns: repeat(3, 1fr); gap: var(--sp-2) }`
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: DayzSpacing.s2,
        crossAxisSpacing: DayzSpacing.s2,
        mainAxisExtent: _CalendarMonthCell.extent,
      ),
      itemCount: DateTime.monthsPerYear,
      itemBuilder: (context, index) {
        final key = TimelineMonthKey(_view.year, index + 1);
        final has = available.contains(key);
        final count = widget.monthCountFor(key);
        return _CalendarMonthCell(
          key: timelineCalendarMonthButtonTestKey(key.year, key.month),
          label: DateFormat.MMM(locale).format(key.date),
          countLabel: has && count != null
              ? l10n.entryCount(count)
              : l10n.calendarMonthNoEntries,
          has: has,
          isCurrent:
              widget.today.year == key.year && widget.today.month == key.month,
          onTap: has ? () => widget.onMonthSelected(key) : null,
        );
      },
    );
  }

  Widget _buildTodayButton(BuildContext context, AppLocalizations l10n) {
    final colors = context.dayz;
    final text = context.dayzText;

    return TextButton(
      key: TimelineCalendarPanel.todayKey,
      onPressed: widget.onToday,
      style: TextButton.styleFrom(
        // `.cal-today-btn`: sans 13px / 600 / accent-ink，padding 7px 14px，
        // r-full；hover 底 accent-soft。最小高 44 满足 NF3。
        foregroundColor: colors.accentInk,
        overlayColor: colors.accentSoft,
        minimumSize: const Size(_kMinHitExtent, _kMinHitExtent),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        shape: const StadiumBorder(),
        textStyle: text.caption.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(l10n.backToToday),
    );
  }
}

/// `.cal-nav`：34px 圆形视觉、18px chevron（ink-2），命中区 44。
class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({
    super.key,
    required this.label,
    required this.flip,
    required this.onTap,
  });

  final String label;
  final bool flip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final icon = DayzIcon.path(
      DayzIcons.chevronRightPath,
      size: 18,
      color: colors.ink2,
    );

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 17,
        highlightShape: BoxShape.circle,
        highlightColor: colors.bg2,
        hoverColor: colors.bg2,
        splashColor: Colors.transparent,
        child: SizedBox.square(
          dimension: _kMinHitExtent,
          child: Center(
            child: flip ? Transform.flip(flipX: true, child: icon) : icon,
          ),
        ),
      ),
    );
  }
}

/// `.cal-day`（含 `.has` 圆点 / `.today` 内描边）。
class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    super.key,
    required this.day,
    required this.semanticLabel,
    required this.has,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final String semanticLabel;
  final bool has;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final radius = BorderRadius.circular(DayzRadii.sm);
    // `.cal-day` ink-4 → `.has` ink → `.today` accent-ink / 600。
    final color = isToday ? colors.accentInk : (has ? colors.ink : colors.ink4);

    return Semantics(
      button: has,
      enabled: has,
      selected: isToday,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        // `.cal-day.has:hover { background: var(--accent-soft) }`
        hoverColor: colors.accentSoft,
        highlightColor: colors.accentSoft,
        splashColor: Colors.transparent,
        child: DecoratedBox(
          // `.cal-day.today { box-shadow: inset 0 0 0 1.5px var(--accent-ring) }`
          decoration: BoxDecoration(
            borderRadius: radius,
            border: isToday
                ? Border.all(color: colors.accentRing, width: 1.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                // `.cal-day`: serif 14px。
                style: text.diary.copyWith(
                  fontSize: 14,
                  height: 1.2,
                  color: color,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (has)
                Positioned(
                  // `.cal-day.has::after`：底 6px、4×4 accent 圆点；
                  // 今天 + 有条目时为 accent-strong。
                  bottom: 6,
                  child: Container(
                    key: const ValueKey<String>('timeline-calendar-day-dot'),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? colors.accentStrong : colors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.cal-mo`（含 `.has` / `.cur` 与篇数 `.n`）。
class _CalendarMonthCell extends StatelessWidget {
  const _CalendarMonthCell({
    super.key,
    required this.label,
    required this.countLabel,
    required this.has,
    required this.isCurrent,
    required this.onTap,
  });

  /// padding 10 + 月名 serif 14（≈20）+ gap 2 + `.n` 11（≈15）+ padding 9。
  static const double extent = 56;

  final String label;
  final String countLabel;
  final bool has;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final radius = BorderRadius.circular(DayzRadii.md);

    return Semantics(
      button: has,
      enabled: has,
      selected: isCurrent,
      label: '$label $countLabel',
      excludeSemantics: true,
      child: Material(
        // `.cal-mo { background: var(--bg-2); border: 1px solid transparent }`，
        // `.cal-mo.cur { border-color: var(--accent) }`。
        color: colors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isCurrent ? colors.accent : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          // `.cal-mo.has:hover { background: var(--accent-soft) }`
          hoverColor: colors.accentSoft,
          highlightColor: colors.accentSoft,
          splashColor: Colors.transparent,
          child: Padding(
            // `.cal-mo { padding: 10px 4px 9px; gap: 2px }`
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // `.cal-mo`: serif 14px，ink-4 → `.has` ink。
                  style: text.diary.copyWith(
                    fontSize: 14,
                    height: 1.3,
                    color: has ? colors.ink : colors.ink4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // `.cal-mo .n`: sans 11px，ink-4 → `.has .n` accent-ink。
                  style: text.caption.copyWith(
                    fontSize: 11,
                    height: 1.3,
                    color: has ? colors.accentInk : colors.ink4,
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

ValueKey<String> timelineCalendarMonthButtonTestKey(int year, int month) {
  return ValueKey<String>('timeline-calendar-month-$year-$month');
}

ValueKey<String> timelineCalendarDayTestKey(int year, int month, int day) {
  return ValueKey<String>('timeline-calendar-day-$year-$month-$day');
}
