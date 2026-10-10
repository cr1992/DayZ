---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-10-10
文档状态：定稿
---

# 设计：onthisday-screen

> 视觉与映射依据：屏源 [`ui-design/current/pages/screens/onthisday.html`](../../../ui-design/current/pages/screens/onthisday.html)（结构 + `data-when` 两态真源）；[`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §1（分层）/§3（屏只装配、不重造外壳；重活/缩略图红线）/§4（四闸：样式参数 + 布局几何 + golden）/§9（W2 页面级）/§10（动 lib/ui 前红线）/§11（验收口径）；组件类名与最小 HTML [`ui-design/current/docs/DESIGN-REF.md`](../../../ui-design/current/docs/DESIGN-REF.md) §3「`.entry`」/§3b「`.year-sep`」/§3c「`.empty`」/§3「`.sheet`」/§5（图标/收藏星）；HTML→Flutter 机制映射 [`ui-design/current/docs/PROTOTYPE-ARCH.md`](../../../ui-design/current/docs/PROTOTYPE-ARCH.md) §6（`go_router`、`CupertinoPageRoute`、`SliverList`、`SnackBar`/`showModalBottomSheet`、缩略图异步、收藏星）。token/`context.dayz.*`/`AppLocalizations`/`intl` 约定来自 `design-tokens-theme`（D1/D4）；组件/外壳交付物名来自 `ui-kit-components` / `ui-shell-navigation`；取数/媒体/缩略图交付物名来自 `data-layer`/`media-storage`/`thumbnail-cache`。

## 技术决策

### D1 · 屏装配策略：CustomScrollView + SliverList，纯组装不造新组件
- **状态：** 采纳
- **背景：** 本屏是「年份段 × 卡片」的纵向列表 + 屏头 + 顶栏，所有可见元素在 `ui-kit-components` 已有对应组件（`DayzEntryCard`/`DayzYearSeparator`/`DayzEmptyState`/`DayzFavoriteStar`/`DayzGlassAppBar`/`DayzToast`/`DayzSheet`），外壳路由在 `ui-shell-navigation`（`Routes`）。方法论 §3：屏只装配，跨屏件不在屏里各写一份。
- **选项：** (A) 屏内自绘卡片/年份分隔/空态（重复 ui-kit）；(B) `CustomScrollView` + `DayzGlassAppBar`(sliver) + 一个 `SliverList`，列表项交错「年份分隔行 + 卡片行」，复用全部 ui-kit 组件；(C) `ListView` + 顶栏用普通 `AppBar`（放弃覆盖式毛玻璃）。
- **选择：** B。`OnThisDayScreen` 用 `CustomScrollView`：sliver[0] = `DayzGlassAppBar`（标题 + 返回 + 更多），sliver[1] = 屏头摘要（`SliverToBoxAdapter`），其后是一个 `SliverList`，其 `delegate` 把「年份段列表」展平为 `[YearSeparator, Card, Card, YearSeparator, Card, ...]` 的扁平项序列（年份分隔是普通列表项，**非** `SliverPersistentHeader`，落实 R2「非吸顶」）。空态 = `default`/`empty` 整屏二选一（`empty` 时 body 换成 `DayzEmptyState`，不进列表）。
- **理由：** 复用 ui-kit、零新增可复用组件；扁平 `SliverList` 让年份分隔随内容滚走（普通行）、与时间线的吸顶机制天然区隔；`DayzGlassAppBar` 作 sliver 与 ui-shell 装配方式一致。
- **代价：** 把「分组数据」展平为「扁平项 + 类型标记」需一个轻量映射（年份段 → `[sep]+cards`）；逻辑简单、可单测，可接受。

### D2 · 年份分隔「非吸顶」是硬约束，显式禁用吸顶 sliver
- **状态：** 采纳
- **背景：** 时间线屏的月份头是 `SliverPersistentHeader(pinned)` 吸顶（PROTOTYPE-ARCH §6）；往年今日的年份分隔在屏源是**普通块**（`.year-sep` 无 `position:sticky`），随列表滚动离开。requirement R2 / 范围外已明确禁止引入吸顶。
- **选项：** (A) 复用时间线吸顶头机制（错误，与设计不符）；(B) 年份分隔作 `SliverList` 内普通项（`DayzYearSeparator` widget 直接入列表）。
- **选择：** B。`DayzYearSeparator` 作为列表普通项渲染，MUST NOT 包进 `SliverPersistentHeader`/`pinned`。
- **理由：** 忠实屏源；避免误把往年今日做成时间线。
- **代价：** 无。这是防跑偏的显式记号。

### D3 · 数据视图模型：屏只吃 ViewModel，取数/解密在屏外（守 Repository 边界 + 缩略图红线）
- **状态：** 采纳
- **背景：** NF5 硬红线：屏 MUST NOT 持 Drift 句柄/写 SQL，缩略图 MUST 只经异步 `warmup` + `ImageProvider`。`EntryRepo.onThisDay(month, day)`（data-layer）、`MediaRepo`（封面元数据/解密读）、`ThumbnailCache.warmup`（thumbnail-cache）此刻可能尚未实现。
- **选项：** (A) 屏直接调 Repo + 解密 + 同步生成缩略图（违红线）；(B) 定义屏私有不可变 ViewModel（`OnThisDayData{ totalCount, List<YearGroup> groups }`、`YearGroup{ year, yearsAgo, List<EntryCardVM> }`、`EntryCardVM{ entryId, title, excerpt, dayNum, monthAbbr, weekday, tag?, place?, mood?, favorite, coverImage: ImageProvider? }`），由一个 `OnThisDayController`（屏外、可注入）经 `EntryRepo`/`MediaRepo` 组装、并对带封面项调 `ThumbnailCache.warmup` 入队后给出异步 `ImageProvider`；屏只渲染 ViewModel + 把滚动可见项告知 controller 以触发 `warmup`。
- **选择：** B。`onthisday_view_model.dart` 持纯数据 VM（无 Drift 类型）；`onthisday_controller.dart` 是取数/缩略图编排层（`ChangeNotifier` 或等价），**它**经 `EntryRepo.onThisDay`/`MediaRepo`/`ThumbnailCache.warmup`，屏 widget 只依赖 VM 与回调。封面 `ImageProvider` 由 controller 提供（解密在 media 层、异步），屏内绝不解密、绝不同步 decode。
- **2026-10-10 对齐现状 API（执行前修正）：**
  - VM 形状对齐 ui-kit `DayzEntryCard`（它吃 `date: DateTime`、`tags: List<String>`，日期/星期由卡片经 `intl` 格式化）：`EntryCardVM{ entryId, title, excerpt, date: DateTime, tags: List<String>（可空，默认空）, place?, favorite, coverImage: ImageProvider? }`，删去预格式化字符串 `dayNum/monthAbbr/weekday` 与 `mood`（**v1 不做心情**）；`OnThisDayData` 增 `date`（被查询的那一天，供屏头 kicker 与回忆卡片入参）。`YearGroup.yearsAgo` 保留，屏把它折算成 `DayzYearSeparator(referenceDate: DateTime(year + yearsAgo))`，分隔行文案与 VM 一致。T1 已交付文件随 T2 一并调整（T2 可改文件已列入）。
  - **标签**：条目标签批量查询 spec 待立，v1 controller 不逐条查 `TagRepo`，`tags` 恒为空；卡片标签入参可空，待批量查询能力就绪后接线。
  - **数据端口**：controller 不直接持 `EntryRepo`，而吃屏私有只读端口 `OnThisDayRepository{ onThisDay(month, day), coverMediaId(entryId), watchChanges() }`，由同文件 `DataLayerOnThisDayRepository` 适配 `EntryRepo.onThisDay` + `MediaRepo.listByEntry`（首个 `kind == 'image'` 为封面）+ `EntryRepo.watchChanges`，与阅读屏 `ReaderRepository`/`DataLayerReaderRepository` 同构。缩略图端口 `OnThisDayThumbnails{ warmup(mediaIds), providerFor(mediaId) }`：只有异步入队 + 异步 provider，**没有任何同步重建入口**。
  - **缩略图现状**：`ThumbnailCache` 的 handle 只给出 `ThumbnailResult(relPath)`，不提供解密后的 `ImageProvider`，且生产组合根尚未构造 `ThumbnailCache`。故真路由下 `OnThisDayThumbnails` 未注入 → controller 不产出 `coverImage`（卡片不渲染图位、不留空洞）；待 thumbnail-cache 补「解密 provider」能力后由组合根注入，屏与 controller 零返工（记已知风险）。
- **理由：** 屏可用假 VM 独立 widget test（NF5 可静态核验 + 行为核验）；取数/缩略图就绪后只接线 controller、屏体零返工；缩略图红线收敛到 controller 一处「只 `warmup` + 异步 provider」。
- **代价：** 多一层 VM/controller；换来红线可验证 + 屏可独立测试，值。data-layer/media/thumbnail 未就绪期间 controller 用内存 stub（记已知风险）。

### D4 · 卡片配图占位与异步呈现（缩略图就绪前/失败）
- **状态：** 采纳
- **背景：** R4：封面缩略图就绪前显示占位、就绪后平滑呈现；缩略图未就绪占位（灰块/blurhash）是设计稿既有意图（README「缩略图未就绪占位」）。`DayzEntryCard` 的 `.photo` 接 `ImageProvider`（ui-kit 交付）。
- **选项：** (A) 同步等缩略图（违红线）；(B) `Image(image: provider)` + `frameBuilder`/`loadingBuilder` 占位（中性 `--surface-2`/`accent-soft-2` 灰块，对应屏源 `.photo` 占位底），失败 `errorBuilder` 兜底灰块；淡入用 `dayzMotionDuration` 门（reduce-motion 降级）。
- **选择：** B。封面渲染走 `DayzEntryCard` 既有图位 API（传 `ImageProvider?` + 占位/失败由 card 或屏统一），淡入时长经 `dayzMotionDuration`。`coverImage == null` 不渲染图位。
- **2026-10-10 对齐现状 API：** 现行 `DayzEntryCard` 的 `cover` 图位是「`accentSoft2` 底色 `ColoredBox` + `Image(image: cover)`」，未暴露 `frameBuilder`/`errorBuilder` 钩子；本屏不碰 `lib/ui/widgets`、也不自绘图位，故 v1 **占位 = 卡片自带的 `accentSoft2` 底**（图未解码前即显示底色），**不做淡入**（与原型「直接显示」一致）；淡入/失败兜底待 ui-kit 卡片补钩子后再接（记已知风险）。
- **理由：** 纯异步、尊重 reduce-motion、复用 ui-kit 图位；占位色走 token。
- **代价：** 缩略图淡入与原型「直接显示」略有差，属克制增强、可接受。

### D5 · ⋯ 菜单走 `DayzSheet.actions` + `Routes.memory` 入口
- **状态：** 采纳
- **背景：** 屏源 `screen.js` 的 `[data-otd-menu]` 打开 sheet：标题「往年今日」，项「生成回忆卡片」（`post nav→memory`）+「分享这一天」（toast）。DESIGN-REF §3 sheet 映射 `showModalBottomSheet`；ui-kit 交付 `DayzSheet.actions` + `DayzSheetItem`；ui-shell 交付 `Routes.memory`/`DayzToast`。
- **选项：** (A) 屏内裸 `showModalBottomSheet`（重复 ui-kit）；(B) 调 `DayzSheet.actions(context, items:[...])`，「生成回忆卡片」`onTap` → `context.go(Routes.memory)`（携当前 month/day 或日期入参，供 memory-card-export 屏用），「分享这一天」`onTap` → `DayzToast.show(...)`。
- **选择：** B。
- **2026-10-10 对齐现状 API：** 现行 `DayzSheet.actions(context, items:, cancelLabel:)` 无 `title` 参数，菜单不渲染标题行；`DayzSheetItem.icon` 是 Material `IconData`（与「不用 `Icons.*`」冲突），菜单项不带图标，「生成回忆卡片」带 `desc` 副文案（对应 screen.js）。导航用 `context.pushNamed(Routes.memory, extra: {'month': m, 'day': d})`（push 而非 go，保证可返回往年今日）；屏外无 `GoRouter` 时（demo）走回调。toast 用 `DayzToast.show(context, text, DayzToastTone.ok)`。
- **理由：** 复用 ui-kit sheet/toast 与 ui-shell 路由常量；「生成回忆卡片」是跨屏入口，经 `Routes.memory` 解耦（目标屏未就绪落 `PlaceholderScreen`）。
- **代价：** `Routes.memory` 与 memory-card-export 入参契约待该 spec 定（本屏先传 month/day，记已知风险/待确认）。

### D6 · 屏头与年份相对文案：`intl` + `AppLocalizations`，禁裸中文/裸数字
- **状态：** 采纳
- **背景：** 屏源屏头有裸文本「5月29日」「过去的今天，你写过 3 篇」「同一天，不同的年份。慢慢往回看。」与年份分隔「2024 / 两年前」。UI 文案唯一来源是 zh/en ARB；日期/数字走 `intl`，屏内禁裸中文。
- **选项：** (A) 屏内硬编码中文/拼接「N 篇」「N 年前」（违 D4）；(B) kicker 日期 + 年份用 `intl`（`DateFormat`/`DateFormat.MMMd` 等中文 locale），篇数 N、「N 年前」用 `intl` 数字 + `AppLocalizations` 模板（如 `l10n.onThisDayCount(n)` / `l10n.yearsAgo(n)` 返回组合串，内部用 `intl`），副文案/空态/kicker 模板字面量入 `AppLocalizations`。
- **选择：** B。本屏向 `lib/l10n/arb/app_zh.arb`、`lib/l10n/arb/app_en.arb` 补 onthisday 文案 key（标题模板、副文案、空态标题/说明、⋯ 菜单两项、Semantics 标签等），并跑 `gen-l10n`；日期/篇数/「N 年前」经 `intl` / ARB ICU 运算。
- **2026-10-10 对齐现状：** 已有 `onThisDayCount`（「今天共 N 篇」，被 i18n demo/测试占用）与屏源标题「过去的今天，你写过 N 篇」不是同一句，故新增 `onThisDayHeadline(count)`，不改旧 key；「N 年前」复用 ui-kit `DayzYearSeparator` 内置的 `yearsAgo`；顶栏标题复用已有 `onThisDay`、更多钮复用已有 `more`。新增 key 以 `onThisDay` 前缀命名（headline / subtitle / empty* / menu* / shareDone / back / openEntry 语义标签）。
- **理由：** 落实 D4 集中可验收；widget 测试用 `find.text(l10n.xxx)` / 校验 `intl` 输出而非裸中文。
- **代价：** 「N 年前」相对年份是中文特例（「去年/两年前/N 年前」），用 `AppLocalizations` 模板 + `intl` 数字承载，非真 i18n（范围外），可接受。

### D7 · Debug Home demo（两态 + 假数据，不连真实 DB/媒体）
- **状态：** 采纳
- **背景：** 方法论 §10 第 5 条 / CLAUDE.md：每个 UI spec 末尾挂一个 Debug Home 入口，真机调试走 demo；R9。
- **选择：** `lib/demo/onthisday_screen_demo.dart`：用内存 stub `OnThisDayData`（含带封面 `AssetImage`/`MemoryImage` 的卡片、收藏项、多年份段）喂屏，提供 `default`/`empty` 切换；`lib/demo/demo_entry.dart` 的 `demos` 列表**末尾追加一行**（不插中间、不改 `DemoEntry` 字段）。demo 用 stub provider，**不触发** `ThumbnailCache.warmup`、不连真实 `EntryRepo`/`MediaRepo`。
- **理由：** 屏可在真机被看见 + widget test 可独立 pump；与红线不冲突（demo 不走真实缩略图链路）。
- **代价：** demo 配图用占位 asset 而非真实加密媒体；与真实链路有别，但正是「屏只吃 VM」解耦的好处，可接受。

### D8 · 路由接线经端口注册（对齐组合根现状）
- **状态：** 采纳（2026-10-10 执行前补）
- **背景：** 组合根已交付：`lib/app/router_ports.dart` 的 `bindRouterPorts` 把 `AppServices` 的 Repo 注入路由层端口；阅读屏经 `registerReaderRepository` 注册、端口未注册时路由保持 `PlaceholderScreen`（裸路由 widget test 依赖这一点）。
- **选项：** (A) 在 `app_router.dart` 里再加一个模块级端口变量 + 注册函数（要改 builder 以外的行）；(B) 端口变量与 `registerOnThisDayRepository(OnThisDayRepository?)` 放在本屏 `onthisday_controller.dart`，`app_router.dart` **只改 `Routes.onthisday` 的 builder**（读端口：未注册 → 占位；已注册 → `OnThisDayPage`），`router_ports.dart` 在 `bindRouterPorts` / `unbindRouterPorts` 各补一行注册。
- **选择：** B。`OnThisDayPage`（`onthisday_screen.dart` 内）持有 controller：首帧 `load(今天)`，订阅 `watchChanges()` 回刷（阅读屏改收藏/删除后返回即生效），未出数前渲染只有顶栏的骨架；屏本体 `OnThisDayScreen` 仍只吃 VM。
- **理由：** 守住「`app_router.dart` 只动一行 builder」的归属约定，端口归属本屏模块；装配与阅读屏同一路径（组合根 → 端口 → 路由）。
- **代价：** `router_ports.dart` 归组合根，本屏列入其「文件变更」仅限补注册行（见下）。

## 架构

```mermaid
graph TD
  R[ui-shell-navigation: Routes.onthisday] --> SCR[OnThisDayScreen · CustomScrollView]
  CTRL[onthisday_controller.dart · 取数/缩略图编排（屏外）] --> VM[OnThisDayData / YearGroup / EntryCardVM · 纯数据，无 Drift]
  VM --> SCR
  SCR --> TOP[DayzGlassAppBar · ui-kit/shell 交付，本屏装配]
  SCR --> HEAD[屏头摘要 · kicker(intl)+标题(intl 篇数)+副文案(AppLocalizations)]
  SCR --> LIST[SliverList · 展平: YearSeparator + EntryCard ...]
  LIST --> YS[DayzYearSeparator · 普通行非吸顶, 年份/N年前 走 intl]
  LIST --> EC[DayzEntryCard · 封面 ImageProvider + DayzFavoriteStar]
  SCR --> EMPTY[DayzEmptyState · empty 态整屏]
  SCR --> MENU[DayzSheet.actions · ⋯ 菜单]
  MENU --> MEM[Routes.memory · memory-card-export 入口（未就绪落 PlaceholderScreen）]
  MENU --> TOAST[DayzToast · 分享这一天]
  CTRL -. EntryRepo.onThisDay/MediaRepo .-> DATA[data-layer / media-storage]
  CTRL -. ThumbnailCache.warmup（异步入队，禁同步重建）.-> THUMB[thumbnail-cache]
  DEMO[onthisday_screen_demo.dart · 假 VM 两态] --> SCR
  DEMO --> DH[demo_entry.dart · demos 末尾追加一行]
```

## 文件变更

> 这是本 spec 任务「可改文件」的**唯一来源与上界**；任一任务可改文件 MUST ⊆ 本清单。新建 Dart 文件 MUST 加 MPL-2.0 头注（模板见 README「License」/ AGENTS.md）。本屏 MUST NOT 列入别的模块/别的 spec 的文件（token 归 tokens-theme、组件归 ui-kit、外壳/路由归 ui-shell、取数归 data-layer、媒体/缩略图归 media/thumbnail）。

**本屏 `lib/ui/onthisday/`**
- `lib/ui/onthisday/onthisday_screen.dart`        新建（`OnThisDayScreen`：`CustomScrollView` 装配顶栏 + 屏头 + SliverList + 空态 + ⋯ 菜单，D1/D2/D5）
- `lib/ui/onthisday/onthisday_view_model.dart`     新建（纯数据 VM：`OnThisDayData`/`YearGroup`/`EntryCardVM`，无 Drift 类型，D3；T2 按 D3「对齐现状 API」调整字段）
- `lib/ui/onthisday/onthisday_controller.dart`     新建（屏外编排：经 `EntryRepo.onThisDay`/`MediaRepo` 组装 VM + 对带封面项 `ThumbnailCache.warmup` 入队 + 异步 `ImageProvider`，D3；未就绪用内存 stub）

**gen-l10n 文案**
- `lib/l10n/arb/app_zh.arb`、`lib/l10n/arb/app_en.arb`                修改（补 onthisday zh/en 文案与模板 key，D6）
- `lib/l10n/gen/app_localizations*.dart`                             修改（`flutter gen-l10n` 生成产物）

**Debug Home 入口 `lib/demo/`**
- `lib/demo/onthisday_screen_demo.dart`            新建（两态 + 假 VM demo，D7）
- `lib/demo/demo_entry.dart`                       修改（**仅末尾追加一行**，不插中间、不改 `DemoEntry` 字段）

**外壳路由接线（本屏就绪后把占位换成真实屏；归属在 ui-shell-navigation D1 已约定「由各屏 spec 改 `app_router.dart` 对应行」）**
- `lib/ui/shell/app_router.dart`                   修改（**仅** `Routes.onthisday` 一行的 `builder`：端口未注册保持 `PlaceholderScreen`、已注册 → `OnThisDayPage`；连带一条 import；不新增/改其它路由常量、不动 `Routes.memory`/其它 builder）
- `lib/app/router_ports.dart`                      修改（2026-10-10 补列，D8：**仅**在 `bindRouterPorts` 补 `registerOnThisDayRepository(DataLayerOnThisDayRepository(...))`、在 `unbindRouterPorts` 补 `registerOnThisDayRepository(null)`，连带一条 import；不动其它端口）

**测试目录（白名单 hook 对 `test/**/*_test.dart` 自动放行；非 `_test.dart` 共享基建由任务 `验收基建` 字段预批）**
- `test/ui/onthisday/`                             新建（屏 widget test + VM 映射 test + 几何/样式/无障碍 test；共享假数据 helper `test/ui/onthisday/onthisday_test_data.dart`）
- `test/demo/onthisday_screen_demo_test.dart`      新建（demo + Debug Home 入口测试）
- `test/demo/dev_seed_demo_test.dart`              修改（2026-10-10 T7 补列，回归修正：原用例钉死 `demos.last` 为「示例数据」，与「新 demo 末尾追加」约定冲突，改为按标题查找，断言意图不变）

## 已知风险

- **跨 spec 依赖未就绪的降级（W2 早于部分底层全就绪）**：
  - `design-tokens-theme`（README 依赖列）：`context.dayz.*`、`DayzSpacing/Radii/Motion/Fonts`、`AppLocalizations` 约定、六套主题。**强依赖**，未定稿则本屏被阻塞（READY 门）。
  - `ui-kit-components`（README 依赖列）：`DayzEntryCard`/`DayzYearSeparator`/`DayzEmptyState`/`DayzFavoriteStar`/`DayzGlassAppBar`/`DayzSheet`(.actions)/`DayzToast`/`dayzMotionDuration`。**强依赖**；其组件 API 未定稿则本屏装配阻塞。
  - `ui-shell-navigation`（README 依赖列）：`Routes.onthisday`/`Routes.reader`/`Routes.memory`、`PlaceholderScreen`、`app_router.dart` 接线点、`DayzGlassAppBar` 装配方式。**强依赖**；`Routes.*` 改名是破坏性变更（其 D2 约定），本屏引用其常量。
  - `data-layer`（README 依赖列）：`EntryRepo.onThisDay(month, day)` 签名 + `EntryRepo`/`MediaRepo`/`TagRepo`。**未就绪时降级**：`onthisday_controller` 用内存 stub VM；落库接线作为依赖就绪后的后续，**MUST NOT 为赶进度在屏/controller 直接写 Drift/SQL**（NF5 红线）。
  - `media-storage`（README 依赖列）：`MediaRepo` 封面元数据 + 解密读、媒体 key 独立于主密码。**未就绪时降级**：封面用占位 asset；真实加密读链路就绪后接线。媒体 key 归属红线：本屏 MUST NOT 暗示「主密码锁住照片」。
  - `thumbnail-cache`（README 依赖列）：`ThumbnailCache.warmup` 异步入队 + `ImageProvider`。**未就绪时降级**：占位灰块；就绪后 controller 接 `warmup`。**红线**：本屏/ controller MUST NOT 调任何同步全量重建接口（thumbnail-cache 本就只暴露 `warmup`）。
  - `memory-card-export`（**非 README 依赖**，仅导航入口目标，尚未立 spec）：「生成回忆卡片」经 `Routes.memory` 导航，目标屏未就绪时落 `PlaceholderScreen`；入参契约（month/day 或日期/entryId 集）**待确认**，由 memory-card-export 立项时拍板，本屏先传 month/day。
  - `design-sync-automation`（**非依赖**，仅验证基建关系）：参数/几何抽取 harness、`element-map.yaml`、SSIM 兜底属其交付物；本屏几何/样式断言用 Flutter 原生 `tester.getRect`/解析 widget 属性自验，**不依赖 harness 就绪**；对设计稿源屏比框的部分留给 design-sync 期二，本 spec 不重造。
- **2026-10-10 执行前登记（底层能力缺口，本屏不越界补）**：① `thumbnail-cache` 不提供解密后的 `ImageProvider`、组合根未构造 `ThumbnailCache` → 真路由暂无封面（D3）；② `DayzEntryCard` 图位无 `frameBuilder`/`errorBuilder` → 无淡入/失败兜底（D4）；③ `DayzIcons` 无左箭头 path → 返回钮用屏内私有常量（照抄屏源 `.app-top [data-nav-back]` 的 `m15 5-7 7 7 7`，走 `DayzIcon.path` 渲染），待 ui-kit 补 `DayzIcons` 后替换；④ `DayzSheet.actions` 无标题参数（D5）；⑤ 条目标签批量查询 spec 待立（D3）。**v1 拍板**：不做心情 mood、不做纸色轴（只验「纯净」纸色下的六套主题）。
- **ARB 合并风险**：本屏补 `app_zh.arb` / `app_en.arb` key，MUST 保持 zh/en key 集合一致并跑 `gen-l10n`；不得新增屏内 strings 类或静态文案常量。
- **`app_router.dart` 接线归属**：该文件归 `ui-shell-navigation`，但其 D1 已约定「页面级 spec 改对应屏的 `builder` 行」；本屏仅改 `Routes.onthisday` 一行 builder。若 ui-shell 尚未交付该文件/常量 → 停下协调，不擅自新建路由文件。
- **年份分隔非吸顶**（D2）：这是与时间线屏的关键区别，执行时 MUST NOT 误用 `SliverPersistentHeader(pinned)`；verification 留布局几何核验（年份分隔随滚动离开视口）。
- **无持久化 schema 变更**：本屏只读取数、不新增/改 DB schema → 无数据迁移/回滚要素。
- **新文件加 MPL-2.0 头注**：`lib/ui/onthisday/*.dart`、`lib/demo/onthisday_screen_demo.dart` 等全部新建 Dart 文件 MUST 在文件顶部加 MPL-2.0 头注。
