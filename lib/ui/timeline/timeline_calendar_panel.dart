// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

import 'timeline_month_section.dart';

class TimelineCalendarPanel extends StatelessWidget {
  const TimelineCalendarPanel({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.monthCountFor,
    required this.onMonthSelected,
    required this.onToday,
  });

  static const Key panelKey = ValueKey<String>('timeline-calendar-panel');

  final List<TimelineMonthKey> months;
  final TimelineMonthKey? selectedMonth;
  final int? Function(TimelineMonthKey key) monthCountFor;
  final ValueChanged<TimelineMonthKey> onMonthSelected;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final groupedMonths = _groupMonthsByYear(months);
    final colors = context.dayz;
    final text = context.dayzText;

    return Semantics(
      key: panelKey,
      label: AppStrings.jumpToDate,
      container: true,
      explicitChildNodes: true,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(DayzRadii.lg),
            border: Border.all(color: colors.hairline),
            boxShadow: colors.shadowLg,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DayzSpacing.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          AppStrings.jumpToDate,
                          style: text.h2.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onToday,
                      child: const Text(AppStrings.backToToday),
                    ),
                  ],
                ),
                const SizedBox(height: DayzSpacing.s2),
                for (final entry in groupedMonths.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: DayzSpacing.s2,
                      bottom: DayzSpacing.s2,
                    ),
                    child: Text(
                      entry.key.toString(),
                      style: text.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.ink3,
                      ),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: DayzSpacing.s2,
                    crossAxisSpacing: DayzSpacing.s2,
                    childAspectRatio: 1.6,
                    children: [
                      for (final month in entry.value)
                        _TimelineCalendarMonthButton(
                          key: timelineCalendarMonthButtonTestKey(
                            month.year,
                            month.month,
                          ),
                          month: month,
                          locale: locale,
                          count: monthCountFor(month),
                          selected: month == selectedMonth,
                          onTap: () => onMonthSelected(month),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineCalendarMonthButton extends StatelessWidget {
  const _TimelineCalendarMonthButton({
    super.key,
    required this.month,
    required this.locale,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final TimelineMonthKey month;
  final String locale;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final label = DateFormat.MMM(locale).format(month.date);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? colors.accentSoft : colors.surface,
          foregroundColor: selected ? colors.accentInk : colors.ink,
          side: BorderSide(color: selected ? colors.accent : colors.hairline),
          padding: const EdgeInsets.symmetric(
            horizontal: DayzSpacing.s2,
            vertical: DayzSpacing.s2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DayzRadii.md),
          ),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: text.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count != null)
              Text(
                AppStrings.entryCount(count!),
                style: text.caption.copyWith(
                  fontSize: 11,
                  color: selected ? colors.accentInk : colors.ink3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

ValueKey<String> timelineCalendarMonthButtonTestKey(int year, int month) {
  return ValueKey<String>('timeline-calendar-month-$year-$month');
}

Map<int, List<TimelineMonthKey>> _groupMonthsByYear(
  List<TimelineMonthKey> months,
) {
  final grouped = <int, List<TimelineMonthKey>>{};

  for (final month in months) {
    (grouped[month.year] ??= <TimelineMonthKey>[]).add(month);
  }

  return grouped;
}
