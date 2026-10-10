// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/onthisday/onthisday_controller.dart';

import 'onthisday_test_data.dart';

class _FakeRepository implements OnThisDayRepository {
  _FakeRepository(this.records, {this.covers = const {}});

  final List<OnThisDayEntryRecord> records;
  final Map<String, String> covers;
  final List<(int, int)> queries = [];
  final List<String> coverLookups = [];
  final StreamController<void> changes = StreamController<void>.broadcast();

  @override
  Future<List<OnThisDayEntryRecord>> onThisDay(int month, int day) async {
    queries.add((month, day));
    return records;
  }

  @override
  Future<String?> coverMediaId(String entryId) async {
    coverLookups.add(entryId);
    return covers[entryId];
  }

  @override
  Stream<void> watchChanges() => changes.stream;
}

/// 只实现端口的 warmup + providerFor：若 controller 想同步重建，端口里根本
/// 没有这样的方法可调（编译期即挡住）。
class _FakeThumbnails implements OnThisDayThumbnails {
  final List<List<String>> warmups = [];
  final List<String> providerRequests = [];

  @override
  void warmup(List<String> mediaIds) => warmups.add(List.of(mediaIds));

  @override
  ImageProvider providerFor(String mediaId) {
    providerRequests.add(mediaId);
    return otdCoverImage;
  }
}

OnThisDayEntryRecord _record(
  String id,
  int year, {
  String text = 'Title\nBody line',
  bool favorite = false,
  String? place,
}) {
  return OnThisDayEntryRecord(
    id: id,
    contentPlain: text,
    localYear: year,
    localMonth: 5,
    localDay: 29,
    isFavorite: favorite,
    placeName: place,
  );
}

void main() {
  final today = DateTime(2026, 5, 29);

  test('groups entries by year, newest first, with yearsAgo', () async {
    final repo = _FakeRepository([
      _record('a', 2024, text: '搬家第一夜\n纸箱还没拆完\n先找台灯', place: '上海'),
      _record('b', 2021, favorite: true),
      _record('c', 2021),
      _record('d', 2019, text: 'only title'),
    ]);
    final controller = OnThisDayController(repository: repo, clock: () => today);
    addTearDown(controller.dispose);

    await controller.load();

    final data = controller.data!;
    expect(repo.queries, [(5, 29)]);
    expect(data.date, today);
    expect(data.totalCount, 4);
    expect(data.groups.map((g) => (g.year, g.yearsAgo)), [
      (2024, 2),
      (2021, 5),
      (2019, 7),
    ]);
    expect(data.groups[1].entries.map((e) => e.entryId), ['b', 'c']);

    final a = data.groups.first.entries.single;
    expect(a.title, '搬家第一夜');
    expect(a.excerpt, '纸箱还没拆完 先找台灯');
    expect(a.place, '上海');
    expect(a.date, DateTime(2024, 5, 29));
    expect(a.tags, isEmpty);
    expect(data.groups[1].entries.first.favorite, isTrue);
    expect(data.groups[2].entries.single.excerpt, '');
  });

  test('skips entries from the current year', () async {
    final repo = _FakeRepository([_record('now', 2026), _record('old', 2025)]);
    final controller = OnThisDayController(repository: repo, clock: () => today);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.data!.totalCount, 1);
    expect(controller.data!.groups.single.year, 2025);
    expect(controller.data!.groups.single.yearsAgo, 1);
  });

  test('covers are warmed up asynchronously and exposed as providers', () async {
    final repo = _FakeRepository(
      [_record('a', 2024), _record('b', 2021), _record('c', 2020)],
      covers: {'a': 'm-a', 'c': 'm-c'},
    );
    final thumbnails = _FakeThumbnails();
    final controller = OnThisDayController(
      repository: repo,
      thumbnails: thumbnails,
      clock: () => today,
    );
    addTearDown(controller.dispose);

    await controller.load();

    final entries = [
      for (final group in controller.data!.groups) ...group.entries,
    ];
    expect(thumbnails.warmups, [
      ['m-a', 'm-c'],
    ]);
    expect(thumbnails.providerRequests, ['m-a', 'm-c']);
    expect(entries[0].coverImage, same(otdCoverImage));
    expect(entries[1].coverImage, isNull);
    expect(entries[2].coverImage, same(otdCoverImage));
  });

  test('without a thumbnails port no cover lookup happens', () async {
    final repo = _FakeRepository([_record('a', 2024)], covers: {'a': 'm-a'});
    final controller = OnThisDayController(repository: repo, clock: () => today);
    addTearDown(controller.dispose);

    await controller.load();

    expect(repo.coverLookups, isEmpty);
    expect(controller.data!.groups.single.entries.single.coverImage, isNull);
  });

  test('empty repository yields empty groups', () async {
    final repo = _FakeRepository(const []);
    final controller = OnThisDayController(repository: repo, clock: () => today);
    addTearDown(controller.dispose);
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.load();

    expect(controller.data!.groups, isEmpty);
    expect(controller.data!.isEmpty, isTrue);
    expect(controller.data!.totalCount, 0);
    expect(notified, 1);
  });

  test('reload re-queries the same day', () async {
    final repo = _FakeRepository(const []);
    final controller = OnThisDayController(repository: repo, clock: () => today);
    addTearDown(controller.dispose);

    await controller.load(DateTime(2026, 2, 3));
    await controller.reload();

    expect(repo.queries, [(2, 3), (2, 3)]);
  });

  test('registerOnThisDayRepository sets and clears the route port', () {
    final repo = _FakeRepository(const []);
    final thumbnails = _FakeThumbnails();
    registerOnThisDayRepository(repo, thumbnails: thumbnails);
    expect(onThisDayRepositoryPort, same(repo));
    expect(onThisDayThumbnailsPort, same(thumbnails));

    registerOnThisDayRepository(null);
    expect(onThisDayRepositoryPort, isNull);
    expect(onThisDayThumbnailsPort, isNull);
  });

  group('DataLayerOnThisDayRepository', () {
    late AppDatabase db;
    late EntryRepo entries;
    late MediaRepo media;

    setUpAll(initTimezoneData);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      entries = EntryRepo(db);
      media = MediaRepo(db);
    });

    tearDown(() => db.close());

    Future<String> add(DateTime utc, String text) async {
      final entry = await entries.create(
        contentJson: '{}',
        contentPlain: text,
        entryDtUtc: utc,
        entryTz: 'Etc/UTC',
      );
      return entry.id;
    }

    test('maps same-day entries and finds the first image cover', () async {
      final older = await add(DateTime.utc(2021, 5, 29, 9), 'older');
      final newer = await add(DateTime.utc(2024, 5, 29, 9), 'newer');
      await add(DateTime.utc(2024, 5, 28, 9), 'other day');
      await media.addMeta('m-audio', older, 'audio', 'media/a.bin');
      await media.addMeta('m-img', older, 'image', 'media/b.bin');

      final repo = DataLayerOnThisDayRepository(
        entryRepo: entries,
        mediaRepo: media,
      );
      final records = await repo.onThisDay(5, 29);

      expect(records.map((r) => (r.id, r.localYear)), [
        (newer, 2024),
        (older, 2021),
      ]);
      expect(records.last.contentPlain, 'older');
      expect(await repo.coverMediaId(older), 'm-img');
      expect(await repo.coverMediaId(newer), isNull);
    });
  });
}
