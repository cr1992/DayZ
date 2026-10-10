// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart' show ImageProvider;

import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/repositories/tag_repo.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/thumbnails/thumbnail_image_provider.dart';
import 'package:dayz/ui/onthisday/onthisday_controller.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:dayz/ui/search/search_source.dart';
import 'package:dayz/ui/shell/app_router.dart';

/// 把组合根里的 Repo 注入路由层的数据端口（时间线 / 阅读 / 编辑）。
///
/// 时间线端口用 journal 过滤 + 月计数走 SQL 的 [AppServices.timelineRepo]；
/// 阅读 / 编辑端口沿用各屏 spec 交付时的注册函数，这里只负责装配。
/// 生产入口（`main.dart`）与装配测试共用，避免两边各装一套。
///
/// Author: @Ray
void bindRouterPorts(
  AppServices services, {
  DraftCoordinator? draftCoordinator,
  KeyProvider? keyProvider,
}) {
  final database = services.database;
  final mediaRepo = MediaRepo(database);
  final mediaStore = MediaStore(
    keyProvider: keyProvider ?? services.keyProvider,
    mediaRepo: mediaRepo,
  );

  final tagRepo = TagRepo(database);

  registerTimelineEntryRepo(services.timelineRepo);
  registerReaderRepository(
    DataLayerReaderRepository(
      entryRepo: services.entries,
      mediaRepo: mediaRepo,
      tagRepo: tagRepo,
      journalRepo: services.journals,
      restoreEntry: services.entries.restore,
    ),
  );
  registerOnThisDayRepository(
    DataLayerOnThisDayRepository(
      entryRepo: services.entries,
      mediaRepo: mediaRepo,
      tagRepo: tagRepo,
    ),
    thumbnails: _OnThisDayThumbnailsAdapter(services.thumbnailImages),
  );
  registerSearchSource(
    RepoSearchSource(entryRepo: services.entries, tagRepo: TagRepo(database)),
  );
  registerEditorServices(
    draftCoordinator: draftCoordinator,
    mediaStore: mediaStore,
    mediaRepo: mediaRepo,
  );
}

/// 清空路由端口（测试 tearDown 用，避免跨用例串库）。
void unbindRouterPorts() {
  registerTimelineEntryRepo(null);
  registerReaderRepository(null);
  registerOnThisDayRepository(null);
  registerSearchSource(null);
  registerEditorServices();
}

/// 往年今日缩略图端口 → 组合根的解密图源加载器（只有异步入队 + 异步 provider）。
class _OnThisDayThumbnailsAdapter implements OnThisDayThumbnails {
  const _OnThisDayThumbnailsAdapter(this._images);

  final ThumbnailImageLoader _images;

  @override
  void warmup(List<String> mediaIds) => _images.warmup(mediaIds);

  @override
  ImageProvider providerFor(String mediaId) => _images.providerFor(mediaId);
}
