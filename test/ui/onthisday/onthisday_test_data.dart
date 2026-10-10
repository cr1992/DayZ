// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'package:dayz/ui/onthisday/onthisday_view_model.dart';

/// 往年今日测试共享假数据（多年份段、含收藏 / 封面 / 地点 / 无封面项）。
final DateTime otdToday = DateTime(2026, 5, 29);

/// 1×1 透明 PNG，测试里当封面图源（不依赖资源打包）。
final ImageProvider otdCoverImage = MemoryImage(
  Uint8List.fromList(const <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

EntryCardVM otdEntry(
  String id, {
  required int year,
  bool favorite = false,
  String? place,
  ImageProvider? cover,
}) {
  return EntryCardVM(
    entryId: id,
    title: 'Title $id',
    excerpt: 'Excerpt for $id.',
    date: DateTime(year, 5, 29),
    place: place,
    favorite: favorite,
    coverImage: cover,
  );
}

/// 三个年份段：2024（1 篇、带地点）、2021（1 篇、收藏 + 封面）、2019（3 篇）。
OnThisDayData otdSampleData() {
  final groups = <YearGroup>[
    YearGroup(
      year: 2024,
      yearsAgo: 2,
      entries: [otdEntry('a-2024', year: 2024, place: 'Shanghai')],
    ),
    YearGroup(
      year: 2021,
      yearsAgo: 5,
      entries: [
        otdEntry('b-2021', year: 2021, favorite: true, cover: otdCoverImage),
      ],
    ),
    YearGroup(
      year: 2019,
      yearsAgo: 7,
      entries: [
        otdEntry('c-2019', year: 2019),
        otdEntry('d-2019', year: 2019),
        otdEntry('e-2019', year: 2019),
      ],
    ),
  ];
  return OnThisDayData(date: otdToday, totalCount: 5, groups: groups);
}

OnThisDayData otdEmptyData() {
  return OnThisDayData(date: otdToday, totalCount: 0, groups: const []);
}
