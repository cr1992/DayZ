---
作者：@Ray
创建日期：2026-10-09
---

# 任务列表：app-composition-root

## 依赖速览
> 以各任务 inline「同 spec 依赖」字段为准；跨 spec 依赖以 README「依赖」列为准。
T1 → T2 → T3 → T4 → T5

-----

- [x] T1 · 数据层补时间线查询

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** `data-layer：EntryRepo / JournalRepo` ｜ **关联需求：** R3, R4 ｜ **依据设计：** D2 ｜ **可改文件：** `lib/data/repositories/entry_repo.dart`, `lib/data/repositories/journal_repo.dart` ｜ **验收基建：** `test/ui/timeline/fake_entry_repo.dart`（`implements EntryRepo`，须补新增方法以保持编译）

### 背景
`EntryRepo.timeline` 无 `journalId`，计数查询缺失。本任务只加纯数据查询，返回 Dart record / 基础类型，不引入任何 `lib/ui` 类型（D2）。

### 实施
1. `timeline({String? journalId, cursor, limit})`：`journalId != null` 时 `WHERE journal_id = ?`，游标与排序不变。
2. `countByMonth({String? journalId}) → Future<Map<(int, int), int>>`：按 `local_year, local_month` 分组计数，排除软删。
3. `entryDaysOfMonth({String? journalId, required int year, required int month}) → Future<Set<int>>`。（命名刻意避开 `TimelineMonthMetadataRepository.monthCounts / entryDaysInMonth`，否则适配器 / 假仓储无法同时实现两边的不同签名。）
4. `JournalRepo.entryCounts() → Future<Map<String, int>>`：按 `journal_id` 计未删条目数。

### 验收标准（做完即止）
- 跨两本日记本的数据下，`timeline(journalId: a)` 只返回 a 的条目且分页游标正确（自动）
- `countByMonth` / `entryDaysOfMonth` 排除软删、按日记本过滤结果正确（自动）
- `entryCounts` 与插入数据一致（自动）

### 验收方式
- 自动：
  ```bash
  flutter test test/data/entry_repo_timeline_query_test.dart test/data/journal_repo_test.dart
  ```

### 验收记录
```
日期：2026-10-09
自动：`flutter test test/data/entry_repo_timeline_query_test.dart test/data/journal_repo_test.dart` 通过；连带 `test/data` + `test/ui/timeline` 全量 47 项通过
人工：N/A
```

-----

- [x] T2 · 组合根 AppServices + 时间线适配器 + 单库启动

**同 spec 依赖：** T1 ｜ **跨 spec 依赖：** `timeline-screen：TimelineController / TimelinePage / TimelineJournalScopedRepository / TimelineMonthMetadataRepository`；`auto-save-draft：DraftCoordinator` ｜ **关联需求：** R1, R4 ｜ **依据设计：** D1, D2, D4 ｜ **可改文件：** `lib/app/app_services.dart`, `lib/app/timeline_repository_adapter.dart`, `lib/app/timeline_host.dart`, `lib/main.dart`, `lib/app.dart` ｜ **验收基建：** `test/app/app_test_db.dart`（内存库组合根 helper）

### 背景
`AppServices` 持唯一 `AppDatabase` 与各 Repo；`TimelineRepositoryAdapter` 把 T1 的查询转为 controller 探测的两个接口；`TimelineHost` 管 controller 生命周期（首载 + `journalId` 变化时 `switchJournal` + dispose）。`main` 打开失败不抛出 main（D4）。

### 实施
1. `AppServices.open()`：`AppDatabase.open(KeyProvider())` 成功返回实例，失败记日志返回 `null`；`AppServices.forDatabase(db)` 供测试。
2. `AppServicesScope` InheritedWidget + `maybeOf`。
3. `TimelineRepositoryAdapter extends EntryRepo implements TimelineJournalScopedRepository, TimelineMonthMetadataRepository`。
4. `TimelineHost(journalId)`：从 scope 取 services 建 controller，`initState` 首载，`didUpdateWidget` 切本。
5. `main.dart` 改用 `AppServices` 的库建草稿协调器；`DayZApp(services:)` 包 scope。

### 验收标准（做完即止）
- 适配器对内存库：按日记本过滤、月计数、有条目日与 T1 结果一致，且 `TimelineController` 经适配器走 SQL 分支（自动）
- `TimelineHost` 首次 pump 后 controller 已载入；改 `journalId` 后只展示新日记本条目（自动）
- `DayZApp(services: null)` 可正常 pump 不抛（自动，D4）

### 验收方式
- 自动：
  ```bash
  flutter test test/app/timeline_repository_adapter_test.dart test/app/timeline_host_test.dart
  ```

### 验收记录
```
日期：2026-10-09
自动：`flutter test test/app/timeline_repository_adapter_test.dart test/app/timeline_host_test.dart` 通过；连带 `test/ui/timeline` + `test/drafts` 共 58 项通过
人工：N/A
备注：切本用例暴露 timeline-screen 的月份头 GlobalKey 在淡入期间重复的断言崩溃，已在 timeline_page.dart 修复（归 timeline-screen T7，单独提交）
```

-----

- [x] T3 · 路由与外壳接线

**同 spec 依赖：** T2 ｜ **跨 spec 依赖：** `ui-shell-navigation：appRouter / AppShell / ShellState / showNewJournalSheet` ｜ **关联需求：** R2, R3, R5 ｜ **依据设计：** D1, D3 ｜ **可改文件：** `lib/ui/shell/app_router.dart`, `lib/ui/shell/app_shell.dart`

### 背景
有 scope 时 timeline 路由挂 `TimelineHost(journalId: shellState.currentJournalId)`，否则占位；ShellRoute 首次拿到 scope 时从库水合日记本列表，新建表单经 `AppServices.createJournal` 落库后刷新；timeline 在 `_routesWithOwnAppBar` 中，外壳不叠顶栏。

### 实施
1. `AppShell.pageOwnsAppBar`：true 时不建 `NestedScrollView` / 外壳顶栏。
2. 路由表：`_routesWithOwnAppBar = {Routes.timelinePath}`；timeline builder 读 scope。
3. ShellRoute：scope 存在时触发一次 `services.refreshJournals(shellState)`；`onNewJournal` 提交走 `services.createJournal`。

### 验收标准（做完即止）
- 注入内存库 services 冷启动：时间线渲染库内条目的月份头，且不出现占位文案（自动，R2）
- 空库冷启动渲染时间线空态（自动，R2）
- 时间线页只有一个 `DayzGlassAppBar`；占位路由仍有外壳顶栏（自动，R5）
- 抽屉列出库内日记本及篇数；新建日记本后库内多一行且抽屉刷新（自动，R3）
- 无 scope 时既有路由测试保持通过（自动）

### 验收方式
- 自动：
  ```bash
  flutter test test/app/app_wiring_test.dart test/ui/shell test/app_router_mount_test.dart
  ```

### 验收记录
```
日期：2026-10-09
自动：`flutter test test/app/app_wiring_test.dart test/ui/shell test/app_router_mount_test.dart` 通过；全量 `flutter test -j 1` 除 `test/security` 11 项（宿主机缺 argon2id_ffi 原生资产，改动前即失败，与本任务无关）外全部通过
人工：N/A
```

-----

- [x] T4 · Debug Home 示例数据入口

**同 spec 依赖：** T2 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R6, R7 ｜ **依据设计：** D1, D5 ｜ **可改文件：** `lib/demo/dev_seed_demo.dart`, `lib/demo/demo_entry.dart`, `lib/app/app_services.dart`, `lib/app/timeline_host.dart`, `lib/ui/shell/app_router.dart`

### 背景
编辑器交付前，真机上时间线只能看到空态。提供 debug 入口向真实加密库写入跨 6 个月、两本日记本的示例条目（正文带标记前缀便于清理），以及一键清空示例条目。

### 实施
1. `DevSeed.seed(services)` / `DevSeed.clear(services)`：示例条目以 `serverRev` 标记（同步字段未启用，不污染正文标题），示例日记本以名称前缀标记，清空时只硬删带标记的数据。
2. `AppServices.contentRevision` + `notifyContentChanged()`；`TimelineHost` 监听后重载；路由把信号传给 host（D5）。
3. `DevSeedDemo` 页：两个按钮 + 当前条目数；`demos` 末尾追加一行。

### 验收标准（做完即止）
- 对内存库 `seed` 后条目跨 ≥6 个月、分属 2 本日记本；`clear` 后示例条目与示例日记本归零，非示例条目保留（自动）
- `demos.last` 指向 `DevSeedDemo`，其余顺序不变（自动）
- 时间线已挂载时写入示例数据，时间线从空态刷新出条目（自动，R7）

### 验收方式
- 自动：
  ```bash
  flutter test test/demo/dev_seed_demo_test.dart
  ```

### 验收记录
```
日期：2026-10-09
自动：`flutter test test/demo/dev_seed_demo_test.dart` 4 项通过
人工：N/A
```

-----

- [ ] T5 · 真机冷启动集成测试

**同 spec 依赖：** T3, T4 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R1, R2 ｜ **依据设计：** D1, D4 ｜ **可改文件：** `integration_test/app_cold_start_test.dart`

### 背景
单元 / widget 测试用内存库；本任务在 Android 真机上走真实 SQLCipher 文件库 + 真 `KeyProvider`，验证生产装配路径。

### 实施
1. 集成测试：`AppServices.open()` 打开设备上真实库 → 清理并写入示例数据 → `DayZApp(services:)` → 断言时间线月份头与卡片可见、无占位文案 → 收尾清理示例数据。

### 验收标准（做完即止）
- 真机上集成测试通过（自动，`-d <android 设备>`）

### 验收方式
- 自动：
  ```bash
  flutter test integration_test/app_cold_start_test.dart -d Y9XSLVVO6TJR55PN
  ```

### 验收记录
```
日期：—
自动：—
人工：N/A
```
