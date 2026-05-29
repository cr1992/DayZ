---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 设计：calendar-screen

> 视觉与映射依据：屏源真源 [`ui-design/current/pages/screens/calendar.html`](../../../ui-design/current/pages/screens/calendar.html)（`.cm-*` 月视图 + `.cm-detail` 选中日列表，含其 `?state=` 默认态）；方法论 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §1（三层还原）/§3（逐屏映射立场 + 网页取巧降级）/§4（验证四闸）/§9（页面级 spec 依赖波次 W2）/§10（动 lib/ui 红线）/§11（验收口径）；组件类名与最小 HTML [`ui-design/current/docs/DESIGN-REF.md`](../../../ui-design/current/docs/DESIGN-REF.md) §3（`.entry` 条目卡 / 收藏星 §5）/§3c（`.cm-*` 一次性屏内件归各屏 / `.cal-*` 时间线面板）；HTML→Flutter 机制映射 [`ui-design/current/docs/PROTOTYPE-ARCH.md`](../../../ui-design/current/docs/PROTOTYPE-ARCH.md) §6（`calendar.html` → `table_calendar`/自绘 `GridView`、按月计数 = Drift `GROUP BY ym`、当日条目查询）。token/`context.dayz.*`/`AppStrings`/`intl` 约定来自 `design-tokens-theme`（D1/D4/D6）；复用组件来自 `ui-kit-components`（`DayzEntryCard`/`DayzEmptyState`/`DayzFavoriteStar`/`dayzMotionDuration`）；路由/外壳来自 `ui-shell-navigation`（`Routes.calendar`/`Routes.reader`/毛玻璃顶栏壳）。

## 技术决策

### D1 · 月视图日历网格：自绘 `GridView`，不引 `table_calendar`
- **状态：** 采纳
- **背景：** PROTOTYPE-ARCH §6 给出两条等价路径「`table_calendar` 或自绘 `GridView`」。日格三态（accent 圆点 / 今日 inset 环 / 选中实底）、周一起始、`aspect-ratio:1/1`、字体走衬线 token，均与 `table_calendar` 默认样式差异大；且 DESIGN-REF §3c 明确 `.cm-*` 是「一次性屏内件、不进设计系统」，对应 Flutter 也应是本屏私有 widget。
- **选项：** (A) 引 `table_calendar` 包 + 大量 `calendarBuilders` 覆写每个日格；(B) 自绘 `GridView.count(crossAxisCount: 7)` + 自绘日格 widget；(C) 用 Material `CalendarDatePicker`。
- **选择：** B。`DayzCalendarMonth`（`calendar_month_grid.dart`）自绘：`GridView.count(7)` + 周一起始的前导占位 + 每格 `_CalendarDayCell`（三态由 token 装饰：`has`→accent 圆点、`today`→`BoxShadow`/`Border` 模拟 inset 环、`sel`→accent 实底）。数据入参 = `Map<int,int>`（日→篇数，来自 `EntryRepo` 月聚合）。
- **理由：** 自绘对三态/周起始/命中区（NF3）/Semantics（NF4）有完全控制，无需与第三方包样式系统较劲；避免为一屏私有件引依赖（`table_calendar` 的能力大半用不上）。`C` 的 `CalendarDatePicker` 无「有条目圆点」概念、改造成本不低于自绘。
- **代价：** 自绘需自管「某月天数 / 首日星期（周一起始换算）/ 占位格」的日期数学（用 `DateTime` 计算，对应原型 `dim`/`firstWD`）；逻辑集中在一个纯函数里、可单测，可接受。

### D2 · 选中日条目列表：复用 `DayzEntryCard`，不复刻原型简版 `.cm-entry`
- **状态：** 采纳
- **背景：** 任务范围明确「下方选中日条目列表（复用 `DayzEntryCard` → reader）」。但屏源 `calendar.html` 下方用的是**简版** `.cm-entry`（左侧 3px accent 竖条 + 标题 + 1 行摘要 + 收藏星），并非时间线那张完整 `.entry`（带日期列 / 封面 / tag / meta）。
- **选项：** (A) 严格照屏源新建一个本屏私有简版列表项 `_CalendarEntryRow`；(B) 复用 ui-kit 的 `DayzEntryCard`（任务范围与方法论「复用前读设计参考、不凭空造同义物」）；(C) 给 `DayzEntryCard` 加一个「紧凑/无日期列」变体。
- **选择：** B 为主（满足任务范围与「不另造同义物」），把「简版 `.cm-entry` vs 完整 `.entry` 的视觉差」作为**已知风险**显式登记：本屏在同一自然日内展示，日期列冗余，故传入 `DayzEntryCard` 时（若其支持）以「隐藏日期列 / 紧凑」入参呈现；`DayzEntryCard` 是否暴露此变体属 `ui-kit-components` 交付物，**标为待确认**——若不支持紧凑变体，退路是 A（本屏私有简版行，仍走 token + 复用 `DayzFavoriteStar`），退路只动本屏文件。
- **理由：** 任务硬性要求复用 `DayzEntryCard`；以「待确认 + 退路」承接 ui-kit 交付物的不确定性，不在本 spec 重造卡片本体。
- **代价：** 与屏源简版有视觉差（条目项更"重"）；进 golden/SSIM advisory（`design-sync-automation`），不阻塞确定性闸。**MUST NOT 为追像素一致在本 spec 改 ui-kit 的 `DayzEntryCard`**（越界，归 ui-kit）。

### D3 · 数据接缝：`EntryRepo` 注入 + 两个查询交付物（不写 SQL）
- **状态：** 采纳
- **背景：** R1/R4 需两类查询：① 某月「日→篇数」聚合（PROTOTYPE-ARCH §6 = Drift `GROUP BY ym`/按 `local_year/month`）；② 某自然日条目列表。`data-layer` D6 定 Repository 边界硬红线、D5 定时区三冗余字段在 `EntryRepo` 入口封装；data-layer design 列了 `EntryRepo` 但**未冻结这两个方法的精确签名**（仅示例 `onThisDay(5,23)`）。
- **选项：** (A) 屏直接查 Drift（违 NF5，否决）；(B) 屏经注入的 `EntryRepo` 抽象调两个方法，方法名按约定命名、在 README 依赖列登记对 data-layer 的依赖，签名以 data-layer 交付为准；(C) 本 spec 自定义一个中间 ViewModel 直接持 Drift（违 NF5，否决）。
- **选择：** B。屏经构造注入 `EntryRepo`（或其只读子接口），调用约定名 **`EntryRepo.monthEntryCounts(year, month)` → `Future<Map<int,int>>`（日→篇数）** 与 **`EntryRepo.entriesForLocalDay(year, month, day)` → `Future<List<EntrySummary>>`**（`EntrySummary` = data-layer 暴露的条目摘要类型，至少含 id/标题/摘要/favorite）。**这两个方法名/类型属跨 spec 契约，最终以 `data-layer` 交付为准**；若 data-layer 实际命名不同，按其名接线（记已知风险 + README 依赖）。本屏一个轻量状态持有者（`calendar_controller.dart`，`ChangeNotifier`，与 shell `theme_controller` 同构）持 `view{y,m}`/`sel{y,m,d}`/月计数/当日条目/加载态，调 `EntryRepo`、暴露给屏 widget。
- **理由：** 把取数收敛到一个控制器经 `EntryRepo`，屏 widget 纯展示 + 发事件，守 NF5 且可用假 `EntryRepo` 独立 widget test（注入 stub）。
- **代价：** data-layer 未就绪期间用内存 fake `EntryRepo`（demo/test 注入），与原型 `monthData` 同形；落库接线在 data-layer 就绪后只换注入实现、屏不返工。**MUST NOT 为赶进度在屏内直连 Drift**（NF5）。

### D4 · 加载 / 失败态（R6）的可观测呈现
- **状态：** 采纳
- **背景：** `EntryRepo` 查询异步，R6 要求 pending 非阻塞、失败可重试、不崩。原型是同步内存数据无此态。
- **选项：** (A) 全屏 spinner 遮挡（阻塞导航，差）；(B) 区域化占位——月视图区 pending 时网格用骨架/半透、列表区 pending 时占位行；失败时该区显错误条 + 重试钮；(C) 不处理（违 R6）。
- **选择：** B。控制器暴露 `AsyncValue`-风格状态（`loading/data/error`，本 spec 用最小 sealed/枚举实现，不预设 Riverpod）；月视图与列表区各自按状态渲染：pending → 占位（导航钮仍可点）、error → `AppStrings` 错误文案 + 重试钮（再次调 `EntryRepo`）。错误态文案集中 `AppStrings`。
- **理由：** 区域化占位满足「非阻塞 + 可重试 + 不崩」，可注入两态做 widget test 断言可观测元素存在。
- **代价：** 多两个分支渲染 + 两态测试；必要。

### D5 · 路由与外壳装配（复用 shell，不自建）
- **状态：** 采纳
- **背景：** `ui-shell-navigation` D1/D2 定 `GoRouter` 路由表 + `Routes.*` 常量为跨 spec 契约，毛玻璃顶栏壳归 ui-kit、由 shell 脚手架装配；本屏需「返回钮 + 标题 + 回到今天」顶栏，落在 `Routes.calendar` 下、抽屉「浏览 → 日历」入口可达。
- **选项：** (A) 本 spec 自建路由 + 自画顶栏（违 shell 契约、重复造外壳）；(B) 本 spec 只交付屏 widget `CalendarScreen`，由 shell 的 `app_router.dart` 把 `Routes.calendar` 的 builder 指向它；顶栏复用 ui-kit 毛玻璃顶栏壳（或 shell 占位顶栏）+ 顶栏 actions 放「回到今天」钮、leading 放返回（`Navigator.pop`）。
- **选择：** B。本 spec 新建 `calendar_screen.dart`（屏 widget，组合顶栏 + `DayzCalendarMonth` + 选中日区）。**`Routes.calendar` 的 builder 接线**：优先由 shell `app_router.dart` 在其文件变更里把对应行 builder 换成 `CalendarScreen`（归属在 README/shell 协调）；本 spec 的 `## 文件变更` **不**列入 `app_router.dart`（属 shell 白名单），仅在 Debug Home demo 内直接构造 `CalendarScreen` 验证（demo 不经路由表也能 pump）。**标为待确认**：若 shell 约定「各屏 spec 自行改 `app_router.dart` 对应 builder 行」，则需在 README/shell 拍板归属后，把该行作为 shell 文件由 shell spec 任务改，仍不进本 spec 白名单。
- **理由：** 守 shell「路由名常量单一来源、屏内禁裸路径」；本屏只引 `Routes.reader`（条目点击导航）与 `Routes.calendar`（自身标识），不持路由表。
- **代价：** 路由接线归属需与 shell 协调（已记待确认）；条目点击导航依赖 `Routes.reader` 携 entry id 的入参约定（shell/reader spec 定，本 spec 调用其约定）。

### D6 · 文案集中 `AppStrings` + 日期/数字走 `intl`
- **状态：** 采纳
- **背景：** tokens-theme D4 / ui-kit D10 拍板「文案集中 `AppStrings`、日期/数字走 `intl`、屏内禁裸中文、widget 测试用 `find.text(AppStrings.xxx)`」。本屏有月标题、日期头、篇数、空态、错误态、各 Semantics 标签等文案。
- **选项：** (A) 屏内裸中文（违约定）；(B) 复用 ui-kit 已建的 `lib/ui/strings/app_strings.dart` 单类，向其**追加**本屏条目（静态文案 + 语义标签），日期/篇数走 `package:intl`（`DateFormat`/`NumberFormat`，SDK 传递依赖无需新增 pubspec）。
- **选择：** B。本屏所有用户可见中文与 Semantics 标签引 `AppStrings.calendar*` 常量；月标题「YYYY 年 M 月」、日期头「M 月 D 日」、「周X」、「N 篇」一律经 `intl`，MUST NOT 自拼。`AppStrings` 单类归属 ui-kit（D10 已拍板「ui-kit 首建、各屏增补」），本 spec 向其追加 → `lib/ui/strings/app_strings.dart` 列入本 spec `## 文件变更`（追加条目，不重建文件）。
- **理由：** 与全线约定一致；测试引常量自带「只引常量」回归护栏。
- **代价：** `app_strings.dart` 是跨 spec 共享文件（ui-kit 建、各屏追加），本 spec 仅追加自己的条目；归属已在 D10/README 拍板，不重复创建。

### D7 · Debug Home 入口（本屏 demo）
- **状态：** 采纳
- **背景：** 每个 UI spec 末尾挂一个 Debug Home 入口、真机调试走 demo 页（方法论 §10 第 5 条、CLAUDE.md「Debug Home demo 入口模式」）。
- **选择：** 新建 `lib/demo/calendar_demo.dart`：在模拟设备框内用**内存 fake `EntryRepo`**（与原型 `monthData`/`entriesFor` 同形的假数据，覆盖「有条目月 / 空月 / 选中无条目日 / pending / error」）渲染 `CalendarScreen`，真机可走查月切换/选日/回到今天/六套主题；在 `lib/demo/demo_entry.dart` 的 `demos` 列表**末尾追加一行**（不插中间、不改 `DemoEntry` 字段）。
- **理由：** 真外壳/data-layer 就绪前，这是日历屏在真机被看见、被 widget test 独立 pump 的入口。
- **代价：** demo 用假数据，与真实库有差；这是分层必然，可接受。

## 架构

```mermaid
graph TD
  TOK[design-tokens-theme: context.dayz / DayzSpacing/Radii/Motion / AppStrings 约定 / intl] --> SCR
  KIT[ui-kit-components: DayzEntryCard / DayzEmptyState / DayzFavoriteStar / dayzMotionDuration / DayzGlassAppBar] --> SCR
  SHELL[ui-shell-navigation: Routes.calendar / Routes.reader / 顶栏壳装配] --> SCR
  subgraph SCR[calendar-screen]
    SC[calendar_screen.dart · 屏: 顶栏(返回/标题/回到今天) + 月视图 + 选中日区]
    CG[calendar_month_grid.dart · DayzCalendarMonth 自绘 GridView 7 列 + 三态日格]
    CC[calendar_controller.dart · ChangeNotifier: view/sel/月计数/当日条目/加载态]
    DM[calendar_date_math.dart · 纯函数: 某月天数/周一起始首日/占位/跨年进退位]
  end
  CC -->|monthEntryCounts / entriesForLocalDay| ER[EntryRepo · data-layer 注入, NF5 禁直连 Drift]
  SC --> CG
  SC --> CC
  CG --> DM
  SC -->|条目点击 Routes.reader + entryId| SHELL
  DEMO[lib/demo/calendar_demo.dart · 内存 fake EntryRepo] --> SC
  DEMO --> DH[lib/demo/demo_entry.dart · demos 末尾追加一行]
```

## 文件变更

> 这是本 spec 任务「可改文件」的**唯一来源与上界**；任一任务可改文件 MUST ⊆ 本清单。新建 Dart 文件 MUST 加 MPL-2.0 头注（模板见 README「License」/ AGENTS.md）。**不列入** `lib/ui/widgets/`（组件归 ui-kit）、`lib/ui/theme/`（token 归 tokens-theme）、`lib/ui/shell/app_router.dart`（路由表归 shell；本屏路由 builder 接线归属在 README/shell 协调，不进本 spec 白名单）、`lib/data/`（Repo 实现归 data-layer，本屏只调注入抽象）。

**屏与屏内私有件 `lib/ui/calendar/`**
- `lib/ui/calendar/calendar_screen.dart`        新建（屏 widget：顶栏返回/标题/回到今天 + 月视图 + 选中日区 + pending/error 态）
- `lib/ui/calendar/calendar_month_grid.dart`     新建（`DayzCalendarMonth` 自绘 `GridView.count(7)` + `_CalendarDayCell` 三态：accent 圆点 / 今日环 / 选中实底，周一起始 + 占位格，命中区 ≥44 + Semantics）
- `lib/ui/calendar/calendar_controller.dart`     新建（`ChangeNotifier`：`view{y,m}` / `sel{y,m,d}` / 月计数 / 当日条目 / loading-error 态；经注入 `EntryRepo` 取数，**不持 Drift**）
- `lib/ui/calendar/calendar_date_math.dart`      新建（纯函数：`daysInMonth` / `firstWeekdayMondayStart` / `leadingPadCount` / 月份 ±1 跨年进退位；可单测）

**共享文案（ui-kit 建、本屏追加）`lib/ui/strings/`**
- `lib/ui/strings/app_strings.dart`              修改（**仅追加** `AppStrings.calendar*` 静态文案 + Semantics 标签条目；不改既有条目、不重建文件；归属见 D6/ui-kit D10）

**Debug Home 入口 `lib/demo/`**
- `lib/demo/calendar_demo.dart`                  新建（内存 fake `EntryRepo` 渲染 `CalendarScreen`，覆盖有条目/空月/选中无条目/pending/error 与六套主题走查）
- `lib/demo/demo_entry.dart`                     修改（**仅末尾追加一行**，不插中间、不改 `DemoEntry` 字段）

**测试目录（白名单 hook 对 `test/**/*_test.dart` 自动放行；非 `_test.dart` 的共享基建由任务 `验收基建` 字段预批）**
- `test/ui/calendar/`                            新建（屏 / 月视图 / 控制器 / 日期数学 widget+unit test，含 golden 基线）
- `test/demo/calendar_demo_test.dart`            新建（demo + Debug Home 入口测试）

## 已知风险

- **`EntryRepo` 两个查询的方法名/类型是跨 spec 契约、以 data-layer 交付为准（待确认）**：本 spec 按约定名 `monthEntryCounts(year,month)→Map<int,int>` 与 `entriesForLocalDay(y,m,d)→List<EntrySummary>` 编写；`data-layer` design 列了 `EntryRepo` 但未冻结这两个签名（仅示例 `onThisDay`）。若 data-layer 实际命名/返回类型不同 → 按其交付接线（改注入处与控制器调用），README「依赖」列已登记对 `data-layer` 的依赖。**MUST NOT 因签名未定就在屏内直连 Drift**（NF5）。
- **`DayzEntryCard` 紧凑变体（D2，待确认）**：本屏在同一日内展示、日期列冗余，期望以「隐藏日期列 / 紧凑」呈现；该变体是否由 `ui-kit-components` 的 `DayzEntryCard` 暴露未定。退路 = 本屏私有简版条目行（走 token + 复用 `DayzFavoriteStar`），只动 `calendar_screen.dart`。**MUST NOT 为对齐改 ui-kit 的 `DayzEntryCard`**（越界）。
- **屏源用简版 `.cm-entry`、本 spec 用 `DayzEntryCard`（D2）**：与屏源存在视觉差（条目项更重 / 无 3px accent 竖条样式），进 golden/SSIM advisory（`design-sync-automation`），不阻塞确定性闸；如设计侧要求严格简版，升 `design-sync-automation` 三档分流（方法论 §8）评估。
- **本独立日历屏 vs 时间线吸顶面板同数据源（背景声明）**：本屏 `DayzCalendarMonth` 与时间线 `.cal-*` 面板共享 `EntryRepo.monthEntryCounts` 数据契约但**载体不同**（独立屏 vs 吸顶下拉）；二者 widget 不复用（一个全屏月视图 + 当日列表，一个吸顶月/年跳转）。若日后抽公共日历网格件，归 ui-kit 评估，不在本 spec 预抽（避免过早抽象）。
- **路由 builder 接线归属（D5，待确认）**：`Routes.calendar` 指向 `CalendarScreen` 的接线落在 shell `app_router.dart`（shell 白名单），不进本 spec；条目点击导航依赖 shell/reader 约定的「`Routes.reader` 携 entryId 入参」。归属在 README/shell 协调；本 spec demo 内直接构造 `CalendarScreen` 不经路由表也可验证屏本体。
- **`saturate` 毛玻璃顶栏像素差**：顶栏复用 ui-kit `DayzGlassAppBar`（其 `saturate` 降级 + 玻璃系数标定见 ui-kit D5/D6），本屏不重造；该像素差归 ui-kit 的 advisory，本屏只装配。顶栏壳未就绪时用 shell 占位顶栏（走 token），记此。
- **参数/几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec，非 README 依赖）**：本 spec 的样式参数闸 / 布局几何闸用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验，**不依赖 harness 就绪**；「对设计稿源屏比框 / SSIM」的部分留给 `design-sync-automation` 期二，不在本 spec 重造（见 verification）。
- **新文件加 MPL-2.0 头注**：`lib/ui/calendar/*.dart`、`lib/demo/calendar_demo.dart` 等全部新建 Dart 文件 MUST 在文件顶部加 MPL-2.0 头注。
- **无持久化 schema 变更**：本屏只读取数据、不新增/改 DB schema（schema 归 data-layer），→ 无数据迁移/回滚要素。
