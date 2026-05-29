---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# onthisday-screen（往年今日屏）

## 背景

「往年今日」是 DayZ 招牌浏览功能之一（v6 招牌查询 `repo.onThisDay(5, 23)`）：按今天的 **month/day** 跨年匹配历史日记，让用户回看「同一天、不同年份」写下的条目。屏由抽屉「浏览」组进入（`ui-shell-navigation` 的 `Routes.onthisday`），其屏源为 [`ui-design/current/pages/screens/onthisday.html`](../../../ui-design/current/pages/screens/onthisday.html)，含两个屏内状态（`data-when="default"` 有内容、`data-when="empty"` 空态）。

这是页面级 spec（方法论 W2 波次，见 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §9），只**装配**已有的视觉底座与组件：token/主题层（`design-tokens-theme`）、可复用组件（`ui-kit-components` 的 `DayzEntryCard`/`DayzYearSeparator`/`DayzEmptyState`/`DayzGlassAppBar` 等）、外壳路由与顶栏（`ui-shell-navigation` 的 `Routes`/`DayzGlassAppBar` 装配/sheet），取数经 `EntryRepo.onThisDay`（`data-layer`），配图走加密媒体读取（`media-storage`）+ 异步缩略图（`thumbnail-cache`）。本 spec **不发明颜色/组件/路由**，只引用上述交付物。

关键红线落点（屏内须如实兑现，不许写出违反的路径）：
- **列表滚动禁止同步重建缩略图**：缩略图只经 `ThumbnailCache.warmup` 异步入队 + `ImageProvider` 异步取，滚动期间绝不触发同步 decode/resize（见 [`docs/design/10`](../../../docs/design/10-ui-restore-and-design-sync.md) §3、`thumbnail-cache`）。
- **Repository 边界**：取数只经 `EntryRepo`/`MediaRepo`，屏内 MUST NOT 持 Drift 句柄或写 SQL（NF5）。
- **媒体 key 独立于主密码**：配图能否显示与主密码无关（媒体经设备 key 派生解密）；本屏不暴露任何「主密码锁住照片」的错误暗示。

## 范围外

- **时间线主屏**（无限滚动 + 月份吸顶 + 日历跳转）—— 归 `timeline-screen`（另立 spec）。往年今日是**普通行年份分隔**（非吸顶），与时间线吸顶头机制不同，MUST NOT 在本 spec 引入 `SliverPersistentHeader(pinned)` 吸顶逻辑。
- **回忆卡片生成/分享屏**（画幅/风格切换、`RepaintBoundary.toImage` 导出、`share_plus`）—— 归 `memory-card-export`（另立 spec）；本屏只提供「⋯ → 生成回忆卡片」**入口**，点击经 `Routes.memory` 导航过去（目标屏未就绪时落 `ui-shell-navigation` 的 `PlaceholderScreen`）。
- **单篇阅读屏** `.reader` 的版式 —— 归 `reader-screen`；本屏卡片点击经 `Routes.reader` 携 entryId 导航过去。
- **真实相册/相机选图链路、缩略图生成算法本体** —— 归 `media-storage` / `thumbnail-cache` / media-picker；本屏只**消费** `ImageProvider` 与 `warmup` 入队。
- **每日本地通知（往年今日）** —— 归通知 spec，非 UI 屏。
- **`EntryRepo.onThisDay` 查询实现本体、月/日冗余字段重算** —— 归 `data-layer`；本屏只调用其方法签名。
- **参数/几何抽取 harness 与 SSIM 兜底** —— 归 `design-sync-automation`；本屏几何/样式断言用 Flutter 原生 `tester.getRect`/解析 widget 属性自验（见 verification）。

## 功能需求

> 屏内状态以屏源 `onthisday.html` 的 `data-when` 为准：**`default`（有内容）** 与 **`empty`（空态）** 两态。

### R1 · 往年今日列表（按 month/day 跨年匹配）
系统 SHALL 进入本屏时按**今天的 month/day** 经 `EntryRepo.onThisDay(month, day)` 取历史条目，并按**年份从新到旧**分组渲染。
- 前提：用户经抽屉「浏览 → 往年今日」进入本屏（`Routes.onthisday`），该 month/day 存在历史条目。
- 操作：屏构建、取数完成。
- 结果：渲染若干年份段，每段含该年同月日的日记卡片（`DayzEntryCard`）；段内卡片可点击经 `Routes.reader` 进单篇阅读（携 entryId）。

### R2 · 年份分隔（普通行，非吸顶）
系统 SHALL 在每个年份段**前插**一行年份分隔（`DayzYearSeparator`，对应 `.year-sep`），显示年份 + 「N 年前」相对文案 + 分隔线。
- 前提：列表含 ≥1 个年份段。
- 操作：渲染列表。
- 结果：每段顶部出现一行 `DayzYearSeparator`，随内容**正常滚动离开视口**（MUST NOT 吸顶停靠）；年份与「N 年前」经 `package:intl` / `AppStrings` 生成，**禁裸中文/裸数字拼接**。

### R3 · 屏头摘要（kicker + 标题 + 副文案）
系统 SHALL 在列表顶部渲染屏头：日期 kicker（如「5月29日」，着 `--accent-ink`）、衬线大标题（如「过去的今天，你写过 N 篇」，N = 命中条目总数）、次要副文案。
- 前提：`default` 态、命中 N (>0) 条。
- 操作：渲染屏头。
- 结果：标题中的篇数 N 经 `intl` 数字格式化、随取数结果变化；kicker 日期经 `intl` 格式化；副文案取自 `AppStrings`。

### R4 · 卡片配图（加密媒体 + 异步缩略图）
Where 某条目带封面媒体，the 系统 SHALL 在 `DayzEntryCard` 的 `.photo` 位渲染封面缩略图，图源经 `MediaRepo` + `thumbnail-cache` 异步获得（解密在外、`ImageProvider` 异步取），并在缩略图就绪前显示占位、就绪后平滑呈现。
- 前提：条目有封面 media。
- 操作：卡片进入视口、滚动浏览。
- 结果：封面经 `ThumbnailCache.warmup` 异步入队 + 异步 `ImageProvider` 渲染；**滚动期间不发生同步缩略图重建**（NF5 红线）；无封面的条目不渲染 `.photo` 位、不留空洞。

### R5 · 空态
If 今天的 month/day **无任何历史条目**，then 系统 SHALL 渲染空态（`DayzEmptyState`，对应 `data-when="empty"`）：居中插画徽 + 标题「今天还没有往事」 + 引导说明，MUST NOT 渲染年份段/屏头摘要。
- 前提：`EntryRepo.onThisDay` 返回空。
- 操作：取数完成。
- 结果：屏显空态插画 + 文案（取自 `AppStrings`），无卡片、无年份分隔。

### R6 · 收藏星标记
Where 某条目被收藏，the 系统 SHALL 在该卡片 `.head` 位显示收藏星（`DayzFavoriteStar`，填充态、着 `--favorite`）。
- 前提：条目 `favorite == true`。
- 操作：渲染卡片。
- 结果：卡片标题行出现填充收藏星；未收藏的条目不显示星。

### R7 · ⋯ 菜单与「生成回忆卡片」入口
系统 SHALL 在顶栏右侧提供「更多」按钮（`data-otd-menu`），点击经 `DayzSheet.actions` 弹出动作菜单，含「生成回忆卡片」（经 `Routes.memory` 导航 memory-card-export 屏）与「分享这一天」两项。
- 前提：本屏任意态。
- 操作：点顶栏「更多」→ 弹 sheet → 点「生成回忆卡片」。
- 结果：经 `Routes.memory` 导航（目标屏未就绪时落 `PlaceholderScreen`）；「分享这一天」触发一条 toast（`DayzToast`）。菜单标题/项文案取自 `AppStrings`。

### R8 · 顶栏与返回
系统 SHALL 以 `DayzGlassAppBar`（覆盖式毛玻璃顶栏）承载标题「往年今日」+ 左侧返回钮 + 右侧更多钮；返回钮经路由出栈返回来源屏。
- 前提：本屏任意态、列表可滚动。
- 操作：向下滚动 / 点返回钮。
- 结果：顶栏静止态干净实底、滚动后毛玻璃浮起（复用 `DayzGlassAppBar` 配方，本屏不重造）；返回钮 `Navigator/go_router` 出栈。

### R9 · Debug Home 入口
系统 SHALL 在 `lib/demo/demo_entry.dart` 的 `demos` 列表**末尾追加一行**指向本屏 demo（`OnThisDayScreenDemo`），用假数据覆盖 `default`（含配图/收藏）与 `empty` 两态，供真机走查。
- 前提：进入 Debug Home。
- 操作：点列表中的「往年今日」demo 项。
- 结果：进入本屏 demo，可切两态、可滚动、可弹 ⋯ 菜单（用 stub 数据，不连真实 DB/媒体）。

## 非功能需求

### NF1 · 对比度（按屏内实际渲染对验，WCAG AA）
本屏实际渲染的文本/有意义 UI 在六套主题下 MUST 达标（复用 `design-tokens-theme` NF1 分族口径）：
- kicker（`--accent-ink` 落浅底/`accent-soft`）、卡片标题/正文摘要（`--ink`/`--ink-2` 对 `--surface`）MUST ≥ 4.5:1。
- 卡片 meta / 年份分隔「N 年前」/ 空态说明等**真实辅助文本**若用 `--ink-3` MUST ≥ 4.5:1（否则改用 `--ink-2`）。
- 收藏星 `--favorite`、accent 作有意义 UI 贴底 MUST ≥ 3.0:1。
> token 本身的 expected-fail 三处已在 `design-tokens-theme` 预登记并阻塞放行；本屏验证遇到时按其口径停下报 @Ray，**MUST NOT 擅自改 `tokens.css`** 或在屏内硬编码替代色。

### NF2 · 触摸目标 ≥ 44px
顶栏返回钮、更多钮、可点卡片、sheet 菜单项的**命中区** MUST ≥ 44×44 px（移动端最小点击目标，复用 ui-kit 组件自带命中盒）。

### NF3 · Semantics 语义标签
返回钮、更多钮、收藏星、可点卡片 MUST 提供可被屏幕阅读器识别的 Semantics 标签/语义（标签取自 `AppStrings`，如返回/更多/已收藏/打开第 N 篇）；卡片为可点元素须标 `button`/可点语义。

### NF4 · reduce-motion（尊重系统减弱动态效果）
本屏一切动效（顶栏滚动渐显、缩略图淡入、sheet 弹出、转场）在系统「减弱动态效果」（`MediaQuery.disableAnimations`）开启时 MUST 降级为瞬时/无过渡，统一经 ui-kit 的 `dayzMotionDuration` 门取时长，MUST NOT 在屏内各自硬编码 `Duration`。

### NF5 · Repository 边界 + 缩略图红线（硬红线）
- 本屏取数 MUST 只经 `EntryRepo`/`MediaRepo`（封面元数据/解密读）+ `TagRepo`（如需标签），MUST NOT import `lib/data` 的 Drift 句柄、MUST NOT 写任何 SQL/Drift。
- 缩略图 MUST 只经 `ThumbnailCache.warmup`（异步入队）+ 异步 `ImageProvider`；列表滚动 MUST NOT 触发同步缩略图重建（不调任何同步全量重建接口——`thumbnail-cache` 本就不暴露）。

### NF6 · 视觉一律走 token
本屏 MUST NOT 硬编码颜色/字号/间距/圆角/阴影；颜色经 `context.dayz.*`、间距/圆角/动效经 `DayzSpacing/DayzRadii/DayzMotion`、字体经 `DayzFonts`/排版角色，文案经 `AppStrings`、日期/数字经 `package:intl`。

### NF7 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上正常渲染：毛玻璃顶栏在低端 Android 允许降级为半透实色 + 细分割线（复用 `DayzGlassAppBar` 降级，本屏不另做）；中英混排字体回退正常（复用 tokens 字体栈）。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | **是** | 配图经加密媒体读取、媒体 key 独立于主密码（媒体 key 归属红线须如实兑现，不暴露错误暗示）|
| 权限 | 否 | 本屏不申请系统权限（相册/相机选图归 media-picker）|
| 无障碍 | **是** | 对比度 NF1 / 触摸目标 NF2 / Semantics NF3 / reduce-motion NF4 |
| 性能 | **是** | 列表滚动禁止同步重建缩略图（NF5 红线，可观测：滚动不触发同步 decode）|
| 多端兼容 | **是** | iOS 13+ / Android 8+ 毛玻璃降级 + 字体回退 NF7 |

→ 命中「安全 / 无障碍 / 性能 / 多端兼容」 + **跨多模块**（消费 token/ui-kit/shell/data/media/thumbnail 多个交付物，本屏自身落 `lib/ui/onthisday/`）→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。
