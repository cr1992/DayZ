---
作者：@Ray
创建日期：2026-10-10
最后更新：2026-10-10
文档状态：定稿
---

# 任务列表：entry-tags-query（条目标签批量查询）

## 依赖速览
> 以各任务 inline「同 spec 依赖」字段为准；跨 spec 依赖以 README「依赖」列为准。
T1 → T2, T3（T2 / T3 可并行）

-----

- [x] T1 · 数据层：`TagRepo.tagsByEntryIds` 一次 JOIN 批量取标签

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** data-layer：`TagRepo` / `entry_tags` 表 ｜ **关联需求：** R1, R2 ｜ **依据设计：** D1 ｜ **可改文件：** `lib/data/repositories/tag_repo.dart`、`test/data/tag_repo_tags_by_entry_ids_test.dart`

### 背景
数据层只有逐条 `listForEntry`。本任务只交付批量查询方法与其测试，不接任何屏。

### 实施
1. `TagRepo` 增 `tagsByEntryIds(Iterable<String> entryIds)` 与公开常量 `tagsByEntryIdsChunkSize = 500`，按 D1 用类型化 JOIN 实现（去重、空输入不查库、全键返回、按名升序、过滤软删标签、超块分块）。
2. 新建测试：内存库 + Drift `QueryInterceptor` 计 SELECT 次数。

### 验收标准（做完即止）
- 多条目、含软删标签、含无标签 / 不存在 id、含重复 id 时：映射键 = 去重后的请求 id 全集；值只含未删标签且按名升序；无标签 / 不存在 → 空列表（自动，断言 R1 结果行）。
- 空输入返回 `{}` 且 SELECT 计数为 0（自动）。
- N ≤ 块上限时 SELECT 计数恰为 1；N = 块上限 + 1 时恰为 2 且结果与逐条 `listForEntry` 一致（自动，断言 R2）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub test/data/tag_repo_tags_by_entry_ids_test.dart
  ```
  （断言映射内容与拦截器统计的 SELECT 次数，不检查源码文本）

### 验收记录
```
日期：2026-10-10
自动：`flutter test --no-pub test/data/tag_repo_tags_by_entry_ids_test.dart` 通过（4 tests：R1 映射内容 / 软删过滤 / 按名升序 / 与 listForEntry 一致；R2 空输入 0 次、28 条 1 次、501 条 2 次 SELECT）；回归 `flutter test --no-pub test/data` 37 tests 全绿；`flutter analyze --no-pub` 触及文件无 issue。
人工：N/A
```

-----

- [ ] T2 · 时间线接线：按页批量填 `TimelineEntry.tags`

**同 spec 依赖：** T1 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R3, R4 ｜ **依据设计：** D2 ｜ **可改文件：** `lib/ui/timeline/timeline_controller.dart`、`lib/app/timeline_repository_adapter.dart`、`test/ui/timeline/timeline_controller_tags_test.dart`、`test/app/timeline_repository_adapter_tags_test.dart`

### 背景
`TimelineController` 映射条目时从不填 `tags`。本任务新增可选能力接口并由生产适配器实现；控制器只在页加载时批量取一次。卡片渲染（`timeline_month_section.dart`）已把 `entry.tags` 传给 `DayzEntryCard`，不改。

### 实施
1. `timeline_controller.dart` 增 `TimelineEntryTagsRepository`；`loadMore` / `refresh` 拿到页后对整页 id 调一次 `tagNamesByEntryIds`，映射时填入 `TimelineEntry.tags`；仓不实现接口则跳过。
2. `TimelineRepositoryAdapter` 实现接口（持 `TagRepo`，`Tag` → `name`）。

### 验收标准（做完即止）
- 假仓实现标签接口时：首屏 / 翻页 / 刷新每次页加载恰好 1 次标签请求，请求 id 集合 = 该页条目 id；`TimelineEntry.tags` 等于假仓给的名字（自动，断言 R3）。
- 假仓不实现标签接口时：分页正常、`tags` 为空（自动，断言 R4）。
- 真内存库经 `AppServices.timelineRepo`：挂标签的条目在控制器 `sections` 里带按名升序、不含软删标签的名字（自动，断言 R3 生产路径）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub test/ui/timeline/timeline_controller_tags_test.dart test/app/timeline_repository_adapter_tags_test.dart
  flutter test --no-pub test/ui/timeline test/app
  ```
  （第二条为回归：既有时间线 / 装配测试保持全绿）

### 验收记录
```
日期：—
自动：—
人工：N/A
```

-----

- [ ] T3 · 往年今日接线：数据端口批量取标签并填入 `EntryCardVM.tags`

**同 spec 依赖：** T1 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R5 ｜ **依据设计：** D3 ｜ **可改文件：** `lib/ui/onthisday/onthisday_controller.dart`、`lib/app/router_ports.dart`、`test/ui/onthisday/onthisday_controller_tags_test.dart`

### 背景
往年今日 VM 已有 `tags` 但恒空。本任务让生产数据端口带标签、控制器透传；端口方法集不变，假实现 / demo 不改。

### 实施
1. `OnThisDayEntryRecord` 增 `tags`（默认空）；`DataLayerOnThisDayRepository` 增可选 `tagRepo`，`onThisDay` 后对全部 id 调一次 `tagsByEntryIds`。
2. `OnThisDayController._assemble` 把 `record.tags` 传入 `EntryCardVM.tags`。
3. `bindRouterPorts` 复用同一 `TagRepo` 注入阅读屏与往年今日端口。

### 验收标准（做完即止）
- 真内存库 + 注入 `tagRepo` 的数据端口：控制器产出的 `EntryCardVM.tags` 为按名升序、不含软删标签的名字；整次加载标签 SELECT（命中 `entry_tags` 的查询）恰 1 次（自动，断言 R5）。
- 未注入 `tagRepo` 的数据端口：`tags` 为空、其余字段不变（自动，断言 R5 降级）。
- 经 `bindRouterPorts` 注册的往年今日端口取到的记录带标签（自动，断言组合根已注入）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub test/ui/onthisday/onthisday_controller_tags_test.dart
  flutter test --no-pub test/ui/onthisday test/app test/demo
  ```
  （第二条为回归：既有往年今日 / 装配 / demo 测试保持全绿）

### 验收记录
```
日期：—
自动：—
人工：N/A
```
