// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_entry_card.dart';
import 'package:dayz/ui/widgets/dayz_month_header.dart';

@immutable
class TimelineMonthKey {
  const TimelineMonthKey(this.year, this.month)
    : assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  DateTime get date => DateTime(year, month);

  @override
  bool operator ==(Object other) {
    return other is TimelineMonthKey &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'TimelineMonthKey($year, $month)';
}

@immutable
class TimelineEntry {
  TimelineEntry({
    required this.id,
    required this.title,
    required this.summary,
    required this.localDate,
    required this.sortDateUtc,
    this.journalId,
    List<String> tags = const <String>[],
    this.placeName,
    this.weatherCode,
    this.weatherTemp,
    this.isFavorite = false,
  }) : tags = List.unmodifiable(tags);

  final String id;
  final String? journalId;
  final String title;
  final String summary;
  final DateTime localDate;
  final DateTime sortDateUtc;
  final List<String> tags;
  final String? placeName;
  final String? weatherCode;
  final double? weatherTemp;
  final bool isFavorite;

  TimelineMonthKey get monthKey =>
      TimelineMonthKey(localDate.year, localDate.month);
}

@immutable
class MonthSection {
  MonthSection({
    required this.year,
    required this.month,
    required List<TimelineEntry> entries,
    this.count,
  }) : assert(month >= 1 && month <= 12),
       entries = List.unmodifiable(entries);

  final int year;
  final int month;
  final int? count;
  final List<TimelineEntry> entries;

  TimelineMonthKey get key => TimelineMonthKey(year, month);

  MonthSection copyWith({
    int? year,
    int? month,
    Object? count = _unsetValue,
    List<TimelineEntry>? entries,
  }) {
    return MonthSection(
      year: year ?? this.year,
      month: month ?? this.month,
      count: identical(count, _unsetValue) ? this.count : count as int?,
      entries: entries ?? this.entries,
    );
  }
}

List<MonthSection> mergeMonthSections({
  required List<MonthSection> current,
  required Iterable<TimelineEntry> incomingEntries,
  Map<TimelineMonthKey, int>? monthCounts,
}) {
  final merged = List<MonthSection>.from(current);

  for (final entry in incomingEntries) {
    final key = entry.monthKey;
    final sectionIndex = merged.indexWhere(
      (section) => section.year == key.year && section.month == key.month,
    );

    if (sectionIndex == -1) {
      merged.add(
        MonthSection(
          year: key.year,
          month: key.month,
          count: monthCounts?[key] ?? 1,
          entries: [entry],
        ),
      );
      continue;
    }

    final section = merged[sectionIndex];
    final entries = List<TimelineEntry>.from(section.entries)..add(entry);
    merged[sectionIndex] = section.copyWith(
      count: monthCounts?[key] ?? entries.length,
      entries: entries,
    );
  }

  if (monthCounts == null) {
    return merged;
  }

  for (var i = 0; i < merged.length; i++) {
    final section = merged[i];
    final count = monthCounts[section.key];
    if (count != null && count != section.count) {
      merged[i] = section.copyWith(count: count);
    }
  }

  return List.unmodifiable(merged);
}

const Object _unsetValue = Object();

ValueKey<String> timelineMonthHeaderTestKey(int year, int month) {
  return ValueKey<String>('timeline-month-header-$year-$month');
}

ValueKey<String> timelineEntryCardTestKey(String id) {
  return ValueKey<String>('timeline-entry-card-$id');
}

List<Widget> buildTimelineMonthSlivers({
  required MonthSection section,
  required GlobalKey headerKey,
  Widget Function(TimelineEntry entry)? cardBuilder,
  VoidCallback? headerOnTap,
  bool headerExpanded = false,
}) {
  return [
    SliverPersistentHeader(
      pinned: true,
      delegate: TimelineMonthHeaderDelegate(
        section: section,
        headerKey: headerKey,
        onTap: headerOnTap,
        expanded: headerExpanded,
      ),
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = section.entries[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            DayzSpacing.s4,
            index == 0 ? DayzSpacing.s2 : 0,
            DayzSpacing.s4,
            DayzSpacing.s4,
          ),
          child: KeyedSubtree(
            key: timelineEntryCardTestKey(entry.id),
            child: cardBuilder?.call(entry) ?? buildTimelineEntryCard(entry),
          ),
        );
      }, childCount: section.entries.length),
    ),
  ];
}

Widget buildTimelineEntryCard(TimelineEntry entry, {VoidCallback? onTap}) {
  return DayzEntryCard(
    title: entry.title,
    summary: entry.summary,
    date: entry.localDate,
    tags: entry.tags,
    meta: _buildEntryMeta(entry),
    favorite: entry.isFavorite,
    showFavorite: entry.isFavorite,
    onTap: onTap,
  );
}

List<DayzEntryMeta> _buildEntryMeta(TimelineEntry entry) {
  final meta = <DayzEntryMeta>[];

  if (entry.placeName != null && entry.placeName!.isNotEmpty) {
    meta.add(DayzEntryMeta(label: entry.placeName!));
  }

  return List<DayzEntryMeta>.unmodifiable(meta);
}

class TimelineMonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  TimelineMonthHeaderDelegate({
    required this.section,
    required this.headerKey,
    this.onTap,
    this.expanded = false,
  });

  static const double extent = 52;

  final MonthSection section;
  final GlobalKey headerKey;
  final VoidCallback? onTap;
  final bool expanded;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: overlapsContent
            ? context.dayz.shadowSm
            : const <BoxShadow>[],
      ),
      child: KeyedSubtree(
        key: headerKey,
        child: KeyedSubtree(
          key: timelineMonthHeaderTestKey(section.year, section.month),
          child: DayzMonthHeader(
            month: DateTime(section.year, section.month),
            entryCount: section.count ?? section.entries.length,
            onTap: onTap,
            expanded: expanded,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant TimelineMonthHeaderDelegate oldDelegate) {
    return oldDelegate.section != section ||
        oldDelegate.expanded != expanded ||
        oldDelegate.onTap != onTap;
  }
}
