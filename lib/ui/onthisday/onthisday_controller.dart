// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show ImageProvider;

import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'onthisday_view_model.dart';

/// 往年今日只读数据端口（屏私有，测试可注入假实现）。
///
/// Author: @Ray
abstract interface class OnThisDayRepository {
  /// 同月同日、未删除的条目，按年份从新到旧。
  Future<List<OnThisDayEntryRecord>> onThisDay(int month, int day);

  /// 条目封面（首张图片）的媒体 id；无图返回 null。
  Future<String?> coverMediaId(String entryId);

  /// 条目表任意写入时发事件，供屏回刷。
  Stream<void> watchChanges();
}

/// 往年今日缩略图端口：只有异步入队 + 异步 [ImageProvider]，**没有**任何同步
/// 重建入口（NF5 红线）。
///
/// Author: @Ray
abstract interface class OnThisDayThumbnails {
  /// 异步入队预热，不阻塞调用方。
  void warmup(List<String> mediaIds);

  /// 该媒体缩略图的异步图源（解码在 ImageStream 里异步完成）。
  ImageProvider providerFor(String mediaId);
}

/// 端口层的条目记录（只含本屏用到的字段，不外泄 Drift 类型）。
///
/// Author: @Ray
@immutable
class OnThisDayEntryRecord {
  const OnThisDayEntryRecord({
    required this.id,
    required this.contentPlain,
    required this.localYear,
    required this.localMonth,
    required this.localDay,
    required this.isFavorite,
    this.placeName,
    this.tags = const <String>[],
  });

  final String id;
  final String contentPlain;
  final int localYear;
  final int localMonth;
  final int localDay;
  final bool isFavorite;
  final String? placeName;

  /// 未删除标签名，按名称升序；数据端口未接标签仓时为空。
  final List<String> tags;
}

/// 把数据层 Repo 适配成 [OnThisDayRepository]（只调 Repo 公共方法，不碰 SQL）。
///
/// Author: @Ray
class DataLayerOnThisDayRepository implements OnThisDayRepository {
  DataLayerOnThisDayRepository({
    required EntryRepo entryRepo,
    required MediaRepo mediaRepo,
    TagRepo? tagRepo,
  }) : _entryRepo = entryRepo,
       _mediaRepo = mediaRepo,
       _tagRepo = tagRepo;

  final EntryRepo _entryRepo;
  final MediaRepo _mediaRepo;
  final TagRepo? _tagRepo;

  @override
  Future<List<OnThisDayEntryRecord>> onThisDay(int month, int day) async {
    final entries = await _entryRepo.onThisDay(month, day);
    final tagRepo = _tagRepo;
    // 整次加载只发一次批量标签查询（空列表时不查库）。
    final tagNames = <String, List<String>>{};
    if (tagRepo != null) {
      final tags = await tagRepo.tagsByEntryIds([
        for (final entry in entries) entry.id,
      ]);
      tags.forEach((id, rows) {
        tagNames[id] = [for (final tag in rows) tag.name];
      });
    }
    return [
      for (final entry in entries)
        OnThisDayEntryRecord(
          id: entry.id,
          contentPlain: entry.contentPlain,
          localYear: entry.localYear,
          localMonth: entry.localMonth,
          localDay: entry.localDay,
          isFavorite: entry.isFavorite,
          placeName: entry.placeName,
          tags: tagNames[entry.id] ?? const <String>[],
        ),
    ];
  }

  @override
  Future<String?> coverMediaId(String entryId) async {
    final media = await _mediaRepo.listByEntry(entryId);
    for (final item in media) {
      if (item.kind == 'image') {
        return item.id;
      }
    }
    return null;
  }

  @override
  Stream<void> watchChanges() => _entryRepo.watchChanges();
}

OnThisDayRepository? _repositoryPort;
OnThisDayThumbnails? _thumbnailsPort;

/// 路由层读取的数据端口；未注册时 [Routes.onthisday] 保持占位屏。
OnThisDayRepository? get onThisDayRepositoryPort => _repositoryPort;

/// 路由层读取的缩略图端口；未注册时不产出封面（卡片不渲染图位）。
OnThisDayThumbnails? get onThisDayThumbnailsPort => _thumbnailsPort;

/// 由组合根（`bindRouterPorts`）注册往年今日端口；传 null 清空。
void registerOnThisDayRepository(
  OnThisDayRepository? repository, {
  OnThisDayThumbnails? thumbnails,
}) {
  _repositoryPort = repository;
  _thumbnailsPort = repository == null ? null : thumbnails;
}

/// 往年今日取数 + 缩略图编排：经端口取条目、按年份分组、对带封面项异步预热，
/// 组装成 [OnThisDayData]。屏只吃它产出的 VM。
///
/// Author: @Ray
class OnThisDayController extends ChangeNotifier {
  OnThisDayController({
    required OnThisDayRepository repository,
    OnThisDayThumbnails? thumbnails,
    DateTime Function()? clock,
  }) : _repository = repository,
       _thumbnails = thumbnails,
       _clock = clock ?? DateTime.now;

  final OnThisDayRepository _repository;
  final OnThisDayThumbnails? _thumbnails;
  final DateTime Function() _clock;

  OnThisDayData? _data;
  Object? _error;
  DateTime? _date;
  int _generation = 0;
  bool _disposed = false;

  /// 最近一次成功组装的数据；首次加载完成前为 null。
  OnThisDayData? get data => _data;

  /// 最近一次加载失败的错误（成功后清空）。
  Object? get error => _error;

  /// 按 [date]（缺省今天）的月/日取往年今日。
  Future<void> load([DateTime? date]) async {
    final target = date ?? _date ?? _clock();
    _date = target;
    final generation = ++_generation;
    try {
      // 「往年」今日：只取早于今年的条目（今年今天写的不算往事）。
      final records = (await _repository.onThisDay(
        target.month,
        target.day,
      )).where((record) => record.localYear < target.year).toList();
      final data = await _assemble(target, records);
      if (_disposed || generation != _generation) {
        return;
      }
      _data = data;
      _error = null;
    } catch (error) {
      if (_disposed || generation != _generation) {
        return;
      }
      _error = error;
    }
    notifyListeners();
  }

  /// 以上次的日期重新取数（条目变更后回刷）。
  Future<void> reload() => load(_date);

  Future<OnThisDayData> _assemble(
    DateTime date,
    List<OnThisDayEntryRecord> records,
  ) async {
    final thumbnails = _thumbnails;
    final covers = <String, String>{};
    if (thumbnails != null) {
      for (final record in records) {
        final mediaId = await _repository.coverMediaId(record.id);
        if (mediaId != null) {
          covers[record.id] = mediaId;
        }
      }
      if (covers.isNotEmpty) {
        // 只异步入队，绝不同步生成 / 解码。
        thumbnails.warmup(covers.values.toList(growable: false));
      }
    }

    final byYear = <int, List<EntryCardVM>>{};
    for (final record in records) {
      final mediaId = covers[record.id];
      byYear
          .putIfAbsent(record.localYear, () => <EntryCardVM>[])
          .add(
            EntryCardVM(
              entryId: record.id,
              title: _extractTitle(record.contentPlain),
              excerpt: _extractExcerpt(record.contentPlain),
              date: DateTime(
                record.localYear,
                record.localMonth,
                record.localDay,
              ),
              tags: record.tags,
              place: _blankToNull(record.placeName),
              favorite: record.isFavorite,
              coverImage: mediaId == null
                  ? null
                  : thumbnails!.providerFor(mediaId),
            ),
          );
    }

    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return OnThisDayData(
      date: date,
      totalCount: records.length,
      groups: [
        for (final year in years)
          YearGroup(
            year: year,
            yearsAgo: date.year - year,
            entries: List<EntryCardVM>.unmodifiable(byYear[year]!),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

List<String> _lines(String plain) {
  return plain
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _extractTitle(String plain) {
  final lines = _lines(plain);
  return lines.isEmpty ? '' : lines.first;
}

String _extractExcerpt(String plain) {
  final lines = _lines(plain);
  return lines.length <= 1 ? '' : lines.skip(1).join(' ');
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
