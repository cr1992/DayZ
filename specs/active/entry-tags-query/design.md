---
作者：@Ray
创建日期：2026-10-10
最后更新：2026-10-10
文档状态：定稿
---

# 设计：entry-tags-query（条目标签批量查询）

## 技术决策

### D1 · 数据层 API：`TagRepo.tagsByEntryIds`
- **背景：** 现有 `TagRepo.listForEntry` 先查 `entry_tags` 再逐个 `tagsDao.byId`，一条目即 1+K 次查询；列表屏要的是「一批条目各自的标签」。
- **选择：** 在 `TagRepo` 增
  ```dart
  Future<Map<String, List<Tag>>> tagsByEntryIds(Iterable<String> entryIds)
  ```
  - 输入去重；空输入直接返回 `{}`，不碰库。
  - 用 Drift 类型化 JOIN：`select(entryTags).join([innerJoin(tags, tags.id.equalsExp(entryTags.tagId))])`，`where entryTags.entryId.isIn(chunk) & tags.deletedAt.isNull()`，`orderBy tags.name ASC`——一块 id 只发 1 条 SELECT。
  - 块大小常量 `tagsByEntryIdsChunkSize = 500`（远低于 SQLite 旧版 999 绑定变量上限），超出按块循环，每块 1 条查询。
  - 返回值：每个请求 id 都有键（无标签 → 空列表），列表不可变、按标签名升序（与 `listForEntry` / 阅读屏 `_sortedTags` 同序）。
- **理由：** 一条 JOIN 走 `entry_tags` 主键 `(entry_id, tag_id)` 前缀即可，无需新索引；全键返回让调用方无需判空；Repo 边界不变（UI 仍只经 `*Repo`）。
- **代价：** 返回 Drift `Tag` 行（与 `listForEntry` 一致），UI 侧需各自映射成名字；分块后极大批量是 ⌈N/500⌉ 次查询而非严格 1 次——时间线单页 30、刷新最多为已加载条数，可接受。

### D2 · 时间线接线：可选能力接口 + 按页批量
- **背景：** `TimelineController` 只依赖 `EntryRepo`，并以 `is TimelineJournalScopedRepository` / `is TimelineMonthMetadataRepository` 探测可选能力；`lib/ui/**` 不能直接持库句柄，也不该反向依赖 `lib/app`。
- **选择：** 在 `timeline_controller.dart` 增可选能力接口
  ```dart
  abstract interface class TimelineEntryTagsRepository {
    Future<Map<String, List<String>>> tagNamesByEntryIds(List<String> entryIds);
  }
  ```
  `TimelineRepositoryAdapter` 实现它（内部持 `TagRepo(db)`，把 `Tag` 映射为 `name`）。控制器在 `loadMore` 与 `refresh` 拿到一页 `EntryTimelinePage` 后、映射 `TimelineEntry` 之前，**对整页 id 调一次** `tagNamesByEntryIds`，映射时按 id 取用；仓不实现该接口时跳过、标签为空（R4）。
- **理由：** 与现有两种可选能力同一套探测模式，测试假仓零改动；查询发生在页加载（滚动触底触发的 `loadMore` 每页一次），卡片 build 只读内存里的 `TimelineEntry.tags`，滚动构建路径不查库。
- **代价：** 每页多一次异步往返；标签查询失败会让该页加载与条目查询失败同样上抛（与现状错误语义一致，不单独兜底）。

### D3 · 往年今日接线：记录带标签、端口签名不变
- **背景：** `OnThisDayRepository` 是屏私有端口，测试里有假实现；往年今日 VM 已有 `tags` 字段但控制器从未填。
- **选择：** `OnThisDayEntryRecord` 增 `tags: List<String>`（默认空）；`DataLayerOnThisDayRepository` 构造增可选 `TagRepo? tagRepo`，`onThisDay` 取完条目后对全部 id 调一次 `tagsByEntryIds` 填入记录；`OnThisDayController._assemble` 把 `record.tags` 透传进 `EntryCardVM.tags`。组合根 `bindRouterPorts` 复用同一个 `TagRepo` 实例同时注入阅读屏与往年今日端口。
- **理由：** 不改端口方法集 → 现有假实现与 demo 不受影响；一次加载一次批量查询。
- **代价：** 端口层记录多一个字段；未注入 `tagRepo` 的调用方静默无标签（R5 允许的降级）。

## 文件变更
- `lib/data/repositories/tag_repo.dart`  修改（T1：`tagsByEntryIds` + 块大小常量）
- `test/data/tag_repo_tags_by_entry_ids_test.dart`  新建（T1）
- `lib/ui/timeline/timeline_controller.dart`  修改（T2：`TimelineEntryTagsRepository` + 按页批量填标签）
- `lib/app/timeline_repository_adapter.dart`  修改（T2：实现 `TimelineEntryTagsRepository`）
- `test/ui/timeline/timeline_controller_tags_test.dart`  新建（T2）
- `test/app/timeline_repository_adapter_tags_test.dart`  新建（T2）
- `lib/ui/onthisday/onthisday_controller.dart`  修改（T3：记录 `tags` + 数据端口批量取 + 控制器透传）
- `lib/app/router_ports.dart`  修改（T3：注入 `TagRepo`）
- `test/ui/onthisday/onthisday_controller_tags_test.dart`  新建（T3）
- `specs/active/entry-tags-query/requirement.md` / `design.md` / `tasks.md`  新建
- `specs/README.md`  修改（进行中表加一行；删「待立 spec」对应条目）

## 已知风险
- 搜索屏 / 收藏屏等落地时需自行接 `tagsByEntryIds`，本 spec 不预埋。
- 时间线 `refresh` 会对已加载的全部条目重取标签（与重取条目同规模），极长滚动后刷新是 ⌈N/500⌉ 次标签查询；若日后成为瓶颈再做增量。
- 标签被软删除 / 挂载变化不会单独触发时间线回刷（时间线只监听 `entries` 表写入）；下一次条目写入或重进屏时才反映。标签编辑 UI 落地时再评估是否监听 `entry_tags` / `tags`。
