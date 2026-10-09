// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';

@immutable
class OnThisDayData {
  const OnThisDayData({required this.totalCount, required this.groups});

  final int totalCount;
  final List<YearGroup> groups;
}

@immutable
class YearGroup {
  const YearGroup({
    required this.year,
    required this.yearsAgo,
    required this.entries,
  });

  final int year;
  final int yearsAgo;
  final List<EntryCardVM> entries;
}

@immutable
class EntryCardVM {
  const EntryCardVM({
    required this.entryId,
    required this.title,
    required this.excerpt,
    required this.dayNum,
    required this.monthAbbr,
    required this.weekday,
    this.tag,
    this.place,
    this.mood,
    this.favorite = false,
    this.coverImage,
  });

  final String entryId;
  final String title;
  final String excerpt;
  final String dayNum;
  final String monthAbbr;
  final String weekday;
  final String? tag;
  final String? place;
  final String? mood;
  final bool favorite;
  final ImageProvider? coverImage;
}

sealed class OnThisDayRow {
  const OnThisDayRow();
}

@immutable
final class YearSeparatorRow extends OnThisDayRow {
  const YearSeparatorRow({required this.year, required this.yearsAgo});

  final int year;
  final int yearsAgo;
}

@immutable
final class EntryCardRow extends OnThisDayRow {
  const EntryCardRow(this.entry);

  final EntryCardVM entry;
}

List<OnThisDayRow> flatten(OnThisDayData data) {
  if (data.groups.isEmpty) {
    return const <OnThisDayRow>[];
  }

  final sortedGroups = List<YearGroup>.of(data.groups)
    ..sort((a, b) => b.year.compareTo(a.year));
  final rows = <OnThisDayRow>[];

  for (final group in sortedGroups) {
    rows.add(YearSeparatorRow(year: group.year, yearsAgo: group.yearsAgo));
    for (final entry in group.entries) {
      rows.add(EntryCardRow(entry));
    }
  }

  return List<OnThisDayRow>.unmodifiable(rows);
}
