---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-31
文档状态：定稿
---

# timeline-screen（时间线主屏）

## 背景

时间线是 DayZ 的**主屏 / 落地页**：进 App 第一眼、导航树根（抽屉与 FAB 都挂在它上面）、也是结构最复杂的一屏——`CustomScrollView` 同时承载「毛玻璃顶栏 + 每月吸顶月份头 + 该月日记卡片列表 + 向上无限滚动 loader」，外加抽屉、FAB、点月份头落下「日期跳转日历面板」。它把 `design-tokens-theme`（视觉底座）、`ui-kit-components`（`DayzGlassAppBar`/`DayzMonthHeader`/`DayzEntryCard`/`DayzGallery`/`DayzEmptyState`/`DayzFab`/`DayzToast` 等组件）、`ui-shell-navigation`（`app_shell`/`shell_drawer`/`Routes`/FAB speed-dial）与 `data-layer`（`EntryRepo` 游标分页）四条线**第一次拼成一个可滚动的真屏**，故它的难点不是发明组件，而是把 Sliver 体系（`SliverAppBar` pinned + `SliverPersistentHeader` pinned + `SliverList`）正确编排、并守住「列表滚动不触发同步重活、UI 不直连 Drift」两条红线。

屏的视觉与交互真源 = `ui-design/current/pages/screens/timeline.html`（+ `pages/assets/timeline.{css,js}`），多状态由 `?state=` 区分（`default` / `drawer` / `empty`）。HTML→Flutter 机制映射见 `ui-design/current/docs/PROTOTYPE-ARCH.md` §6（含「pinned 吸顶头 × 按 index 跳任意项不易兼得 → 日历跳转降级到月级」这一关键痛点）。

## 范围外

- **毛玻璃顶栏组件本体 / FAB 速拨外形 / 抽屉中枢 / 各通用组件本体**：归 `ui-kit-components`（`DayzGlassAppBar`/`DayzFab`/`DayzMonthHeader`/`DayzEntryCard`/`DayzGallery`/`DayzEmptyState`/`DayzToast`/`DayzFavoriteStar`）与 `ui-shell-navigation`（`app_shell`/`shell_drawer`/`fab_speed_dial`/`Routes`/换肤）。本 spec **MUST NOT** 重新实现它们，只**装配 + 喂数据 + 接交互**。
- **进入阅读屏 / 编辑屏 / 搜索屏 / 往年今日屏的目的屏本体**：本 spec 只发起导航（`context.go(Routes.reader, ...)` 等），目的屏归各自页面级 spec。
- **`EntryRepo` / `JournalRepo` 的查询与分页实现、按月计数查询的落库**：归 `data-layer`；本 spec 只**调用其交付方法**（`EntryRepo.timeline(...)` 等），MUST NOT 写任何 SQL/Drift。
- **真实相册照片链路与缩略图生成**：归 `media-storage` / `thumbnail-cache`；卡片九宫格只接 `ImageProvider` 列表占位，本屏 MUST NOT 触发同步缩略图重建。
- **同步工作流的参数/几何抽取 harness 与 SSIM 兜底**：归 `design-sync-automation`；本 spec 的几何/样式断言用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验，需 harness 的「对设计稿源屏比框」部分依赖它、不在本 spec 重造。
- 日记本切换的落库、新建日记本表单：通路归 `ui-shell-navigation`（`ShellState` 切本事件 / `new_journal_sheet`）；本屏只**响应**当前 journalId 变化重查列表。

## 功能需求

> 屏内状态清单（对齐 `timeline.html` 的 `data-when` / `?state=`）：`default`（有内容）、`drawer`（抽屉打开，内容同 default）、`empty`（空状态）；交互态（同一 widget 内按数据/滚动渲染）：顶栏静止↔滚动毛玻璃浮起、月份头吸顶（`.stuck`）、`cal-open`（日历面板落下）、向上无限滚动 loader（`载入更早…` / `已经到最早的一篇了`）、切本刷新淡入。

### R1 · 时间线滚动骨架
系统 SHALL 用单个 `CustomScrollView` 渲染时间线，自上而下为：`DayzGlassAppBar`（pinned 毛玻璃顶栏）→ 每个月一段「`DayzMonthHeader`（吸顶月份头，`SliverPersistentHeader(pinned:true)`）+ 该月 `DayzEntryCard` 列表（`SliverList`）」→ 尾部 loader sliver。
- 前提：库内有跨多个月的日记。
- 操作：进入时间线屏、上下滚动。
- 结果：顶栏始终 pinned 不滚走；同一月的卡片归在该月月份头之下；滚动到下一月时，上一月份头被下一月份头顶替吸顶（任一时刻 sliver 区至多一个月份头停靠在顶栏正下方）。

### R2 · 向上无限滚动（游标分页）
While 用户向下滚近列表底部，the 系统 SHALL 经 `EntryRepo.timeline({cursor, limit})` 按需追加更早的日记（最新在最上、向更早方向加载），并在加载中于尾部显示 loader、加载到最早一篇时显示「已到最早」终态。
- 前提：还有更早的日记未加载。
- 操作：滚动到接近底部（阈值内）。
- 结果：触发一次取下一页（带上次返回的 cursor），新月份/卡片追加到列表尾；同一时刻 MUST NOT 重复触发并发取页；取尽后 loader 切「已经到最早的一篇了」终态、不再触发。

### R3 · 空状态
If 当前日记本下无任何日记，then 系统 SHALL 渲染 `DayzEmptyState`（插画 + 标题 + 引导，引导文案提示「轻点右下角写第一页」），不渲染月份头与列表。
- 前提：当前 journalId 下条目数为 0。
- 操作：进入时间线屏。
- 结果：显示空状态、隐藏时间线列表与 loader；FAB 仍可用。

### R4 · 月份头 = 日期跳转触发器
系统 SHALL 把每个 `DayzMonthHeader` 做成可点触发器；点击落下「日期跳转日历面板」（月视图/年视图，有条目的日/月可点），选中后**滚动定位到对应月份段头**。
- 前提：时间线已渲染若干月。
- 操作：点击某月份头 → 面板落下 → 点某有条目的日（或年视图某月）。
- 结果：面板关闭，列表平滑滚动到目标月份段头停靠在顶栏正下方；点击 scrim 或再次点同一月份头则关闭面板不跳转；面板打开态月份头 `aria-expanded` 等价语义为「展开」。

### R5 · 日期跳转降级到月级（含未加载远期）
系统 SHALL 在「目标月尚未加载」时**先按需补加载到该月、再滚动定位**；定位精度 SHALL 为**月级**（停靠到该月份段头），不强求精确到具体某日。
- 理由：`SliverPersistentHeader(pinned)` 与「按 index 跳到任意项」（`scrollable_positioned_list`）不易兼得（PROTOTYPE-ARCH §6 痛点 + `timeline.js` 注释）。月级定位即够用（Day One 同此精度），同时保住完美吸顶头。
- 前提：目标月在当前已加载范围之外。
- 操作：日历选一个更早且未加载月份的某日。
- 结果：先追加加载到该月，再滚动到该月份段头；不因「该日未渲染」而跳转失败或越过。

### R6 · 卡片点击进阅读屏 + 收藏星
系统 SHALL 让 `DayzEntryCard` 整卡可点，点击经 `Routes.reader` 导航到对应 entry 的阅读屏（携 entryId）；卡片按 entry 元数据渲染日期列 / 标题 / 摘要 / 九宫格（多图）/ 标签 / 地点或心情 meta / 收藏星（收藏时显示）。
- 前提：列表有一张卡片对应某 entry。
- 操作：点击该卡片。
- 结果：发起到 `Routes.reader` 的导航并带上该 entryId；卡片渲染字段与该 entry 数据一致（收藏 entry 显示 `DayzFavoriteStar`、非收藏不显示）。

### R7 · 抽屉与 FAB 接入
系统 SHALL 把时间线屏挂进 `ui-shell-navigation` 的 `app_shell`：顶栏菜单钮开抽屉、搜索钮导航搜索屏、往年今日钮导航往年今日屏；FAB 轻点进编辑屏、长按展开二级动作（拍照/语音/纯文字）；抽屉切日记本时本屏按新 journalId 重查并刷新列表（淡入重演）。
- 前提：时间线屏已显示。
- 操作：点菜单钮 / 切日记本 / 点 FAB。
- 结果：抽屉打开；切本后列表按新 journalId 刷新（含淡入过渡，且尊重 reduce-motion）；FAB 轻点导航到 `Routes.editor`。

### R8 · Debug Home 入口
系统 SHALL 在 `lib/demo/demo_entry.dart` 的 `demos` 列表**末尾追加一行**挂一个时间线屏 demo（用内存假 `EntryRepo` 数据驱动），供真机走查与可独立 `pump` 的 widget 测试。
- 前提：App 启动进 Debug Home。
- 操作：点该 demo 条目。
- 结果：进入由假数据驱动的时间线屏，可滚动、可开抽屉、可开日历面板、可见空/有内容两态。

## 非功能需求

### NF1 · Repository 边界（硬红线）
本屏取数 MUST 只经 `EntryRepo` / `JournalRepo`（及其他 `*Repo`）；MUST NOT `import 'package:dayz/data/database.dart'` 或任何 Drift 句柄、MUST NOT 在屏内写 SQL/Drift 查询。日记列表、按月计数、分页全部经 Repository 方法获取。

### NF2 · 列表滚动不触发同步重活
While 列表滚动 / 分页追加，the 系统 SHALL NOT 同步重建缩略图或执行任何会卡 UI 的 CPU 重活；缩略图只经异步 `warmup`（`thumbnail-cache` 交付），未就绪时显示占位（灰块 / blurhash），MUST NOT 在卡片 build 路径内同步解码大图。

### NF3 · 点击目标 ≥ 44px
所有可点元素（月份头触发器、卡片、收藏星、FAB、顶栏菜单/搜索/往年今日钮、日历日格/月格、loader 区可点项）命中区 MUST ≥ 44×44 逻辑像素。

### NF4 · 对比度 ≥ WCAG AA
本屏所有文本（月份头标题/篇数、卡片标题/摘要/日期列/meta、空状态标题/说明、loader 文案、日历面板文字）在六套主题（purple/amber/sage × light/dark）下对底色对比度 MUST 遵循 `design-tokens-theme` NF1 的分族口径（正文/次要文本 ≥ 4.5:1、有意义 UI ≥ 3.0:1）；本屏只**消费** token、MUST NOT 自定义颜色，已知 token 级 expected-fail 由 `design-tokens-theme` 负责，本屏不重复改 token。

### NF5 · Semantics 语义标签
顶栏菜单/搜索/往年今日钮、FAB、月份头触发器（含展开/收起态）、收藏星、日历面板（dialog 角色 + 「跳转到日期」标签）、空状态 MUST 提供可被屏幕阅读器识别的 `Semantics` 标签（文案集中 `AppStrings`）；卡片 MUST 暴露「打开日记」语义。

### NF6 · reduce-motion
切本刷新淡入、日历面板落下/收起、FAB 展开、顶栏滚动渐显等动效 MUST 在系统「减弱动态效果」（`MediaQuery.disableAnimations == true`）下降级为瞬时（duration→0），统一经 `ui-kit-components` 的 `dayzMotionDuration` 门取时长，本屏 MUST NOT 自写裸 `Duration`。

### NF7 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+（minSdk 26）正常滚动与渲染；毛玻璃顶栏在低端 Android 允许降级为半透实色 + 细分割线（降级在 `DayzGlassAppBar` 组件侧，本屏不另写）。

### NF8 · 文案集中 + 日期走 intl
本屏用户可见文案 MUST 引 `AppStrings` 常量（屏内禁裸中文）；月份头「YYYY · N 篇」、卡片日期列（日/英文月缩写/周几）、日历标题等日期/数字 MUST 经 `package:intl` 格式化（`intl` 为 Flutter SDK 传递依赖），MUST NOT 自拼 `'2026 · 12 篇'` / `'周五'`。widget 测试用 `find.text(AppStrings.xxx)` / intl 格式化结果，MUST NOT 断言裸中文字面量。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 不碰密钥/加密，取数走 Repository（边界为 NF1 但属红线非安全机制） |
| 权限 | 否 | 本屏不申请系统权限（相册/相机权限归 media-picker/FAB 二级动作目的屏） |
| 无障碍 | **是** | 点击目标 ≥44（NF3）、对比度 AA（NF4）、Semantics（NF5）、reduce-motion（NF6） |
| 性能 | 否 | 分页 < 100ms 的查询硬阈值归 `data-layer` NF3；本屏只「不触发同步重活」（NF2，行为约束非可度量运行阈值） |
| 多端兼容 | **是** | iOS 13+ / Android 8+ 滚动与毛玻璃降级（NF7） |

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui/timeline/` + `lib/demo/` + `test/`）。
