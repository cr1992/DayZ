---
作者：@Ray
创建日期：2026-10-09
---

# 设计：app-composition-root

## 技术决策

### D1 · 组合根 = `AppServices` + `AppServicesScope`（InheritedWidget）
- **背景：** `appRouter` 是全局 `final`，路由 builder 拿不到构造期注入的依赖；现有测试大量直接操作全局 `appRouter`。
- **选择：** 新建 `AppServices`（持有唯一 `AppDatabase` + `EntryRepo`/`JournalRepo`/`EditingSessionRepo` + 日记本刷新/新建方法），由 `main.dart` 构造，经 `DayZApp(services:)` 包一层 `AppServicesScope` 置于 `MaterialApp.router` 之上；路由 builder 用 `AppServicesScope.maybeOf(context)` 取。全局 `appRouter` 保持不变。
- **理由：** 不改路由表形态，现有路由测试不需重写；依赖只经 UI 树向下流，页面仍只拿 Repo，不碰 Drift。
- **代价：** 未注入 scope 时（旧测试 / 无库环境）路由降级回 `PlaceholderScreen`，误配置不会报错而是静默占位——由 R2 的装配测试与真机集成测试兜住生产路径。

### D2 · 时间线仓储适配器放组合层，数据层不反向依赖 UI
- **背景：** `TimelineController` 通过 `is TimelineJournalScopedRepository` / `is TimelineMonthMetadataRepository` 探测增强能力，这两个接口和 `TimelineMonthKey` 定义在 `lib/ui/timeline/`；数据层 import UI 类型会造成反向依赖。
- **选择：** 数据层 `EntryRepo` 只加纯数据查询（`timeline({journalId})`、`countByMonth(journalId) → Map<(int,int),int>` 用 record、`entryDaysOfMonth`；命名避开 UI 接口同名方法，以免签名冲突）；组合层 `TimelineRepositoryAdapter extends EntryRepo implements` 两个 UI 接口，只做类型转换。
- **理由：** 依赖方向保持 UI → data；过滤 / 计数下沉到 SQL（R4），controller 的「逐页拉全量再筛」降级分支在生产不再走。
- **代价：** 多一层薄适配；`EntryRepo.timeline` 新增可选参数，旧调用不受影响。

### D3 · 顶栏归属按路由声明，`AppShell.ownsAppBar`
- **背景：** `AppShell` 用 `NestedScrollView` 自带毛玻璃顶栏；`TimelinePage` 的吸顶月份头与日历面板定位依赖自身 `CustomScrollView` 里的 `DayzGlassAppBar`，两者叠加出现双顶栏。且各屏顶栏按钮不同（时间线有「往年今日」钮），外壳无法通用。
- **选择：** `AppShell` 增 `pageOwnsAppBar`（默认 false）；为 true 时 body 直接放 `SafeArea(top:false)`，不建 `NestedScrollView` 与外壳顶栏；drawer / FAB 照旧由外壳提供（页面内用 `Scaffold.of(context).openDrawer()`）。路由表以集合 `_routesWithOwnAppBar = {Routes.timeline}` 声明。
- **理由：** 外壳仍唯一负责 drawer/FAB/让位（守 ui-shell D9 的「外壳组合」），顶栏内容让渡给已实现自有顶栏的页面；占位路由行为不变。
- **代价：** 页面自带顶栏时，菜单 / 搜索钮接线由页面负责（时间线归 timeline-screen T7）；在 T7 完成前时间线顶栏暂无菜单钮，抽屉只能边缘右滑打开。

### D4 · 启动失败不黑屏，主密码模式记已知风险
- **背景：** `main.dart` 在 `runApp` 前 `await AppDatabase.open`，主密码模式下 `getAppDbKey()` 抛 `KeyProviderLocked`，异常直接冒出 main → 白屏。
- **选择：** 组合根 `AppServices.open()` 捕获打开失败，`main` 仍 `runApp`，`services == null` 时路由按 D1 降级占位并记录日志；不在本 spec 做解锁 UI。
- **理由：** 当前无 UI 可开启主密码模式，问题不可触达；先保证「不崩」，解锁流归后续 spec。
- **代价：** 主密码模式下应用可启动但只有占位，属已知风险。

### D5 · 内容变更信号 = `AppServices.contentRevision`（`ValueNotifier<int>`）
- **背景：** 时间线只在首载 / 切本时取数；写入方（示例数据、后续编辑器）落库后，已挂载的时间线不会刷新（R7）。
- **选择：** 组合根持一个代次计数器，写入方调 `notifyContentChanged()`；`TimelineHost` 监听后 `loadInitial(当前日记本)`。
- **理由：** 最小机制，无需引入 Drift `watch` 流改造游标分页；写入点有限且都经组合根。
- **代价：** 整页重载（滚动位置回顶）；写入方漏调则不刷新——编辑器接入时须在保存路径调用。

## 文件变更
- `lib/data/repositories/entry_repo.dart`  修改（`timeline` 增 `journalId`；新增 `countByMonth` / `entryDaysOfMonth`，D2）
- `lib/data/repositories/journal_repo.dart`  修改（新增 `entryCounts()`，R3）
- `lib/app/app_services.dart`  新建（`AppServices` + `AppServicesScope`，D1/D4）
- `lib/app/timeline_repository_adapter.dart`  新建（D2）
- `lib/app/timeline_host.dart`  新建（持有 `TimelineController` 生命周期：建、首载、随 journalId 切本、dispose）
- `lib/main.dart`  修改（单库装配，D1/D4）
- `lib/app.dart`  修改（`DayZApp(services:)` + 包 `AppServicesScope`）
- `lib/ui/shell/app_router.dart`  修改（timeline 路由挂 `TimelineHost`；ShellRoute 读 scope 注入日记本 / 新建落库；`_routesWithOwnAppBar`，D1/D3）
- `lib/ui/shell/app_shell.dart`  修改（`pageOwnsAppBar`，D3）
- `lib/demo/dev_seed_demo.dart`  新建（R6）
- `lib/demo/demo_entry.dart`  修改（仅末尾追加一行）
- `test/ui/timeline/fake_entry_repo.dart`  修改（验收基建：补 `EntryRepo` 新增方法）
- `test/app/app_test_db.dart`  新建（验收基建：内存库组合根 helper）
- `test/data/`、`test/app/`、`test/ui/shell/`、`test/demo/`  新建 / 修改 `*_test.dart`
- `integration_test/app_cold_start_test.dart`  新建（真机冷启动集成测试）

## 已知风险
- 主密码模式启动只得占位（D4）；解锁 UI 待后续 spec。
- timeline-screen T7 完成前，时间线顶栏无菜单 / 搜索钮（D3 代价）。
- 依赖 timeline-screen 的已交付件 `TimelinePage` / `TimelineController`（T1–T4、T6 已完成）；该 spec 未整体完成不阻塞本 spec。
