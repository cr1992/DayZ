---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# calendar-screen（日历屏）

## 背景

日历屏是「按日期回看日记」的入口：一屏内一个**全屏月视图**（周一起始、有条目日标 accent 圆点、今日 accent 环、选中日实底）+ **月份导航**（上/下月、回到今天）+ 下方**选中日条目列表**。它与时间线屏「点月份头落下的日历面板」（`ui-design/current/docs/DESIGN-REF.md` §3c `.cal-*`）**同数据源、不同载体**：日历面板是吸顶下拉、只做月/日跳转；本屏是独立可下钻屏，落在抽屉「浏览 → 日历」入口下，月视图 + 当日条目共屏。

数据契约：月视图「哪天/哪月有条目 + 篇数」由 `EntryRepo` 一条**按月聚合计数**查询提供（对应原型 `calendar.js` 内 `monthData(y,m)` 轻量月份索引）；选中某有条目的日 → 由 `EntryRepo` 取**该自然日的条目列表**。两者皆经 Repository 边界、不在屏内写 SQL/Drift（红线，见 NF5）。屏源真源 = `ui-design/current/pages/screens/calendar.html`。

本屏属 UI 还原线第三层（屏幕层），依赖底座三件套（`design-tokens-theme` / `ui-kit-components` / `ui-shell-navigation`）与数据层（`data-layer`）；分层与建造顺序见 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §1/§9。

## 范围外

- **时间线吸顶下拉日历面板（`.cal-*` / `.tl-month` 触发）** —— 归时间线屏 spec；本屏只共享其 `EntryRepo` 按月聚合查询的**数据契约**，MUST NOT 实现时间线滚动定位 / `scrollable_positioned_list` 跳转。
- **年视图（12 个月网格 `.cal-months`）** —— 该交互属时间线日期跳转面板（DESIGN-REF §3c），本独立日历屏的 `calendar.html` 源**只有月视图**，不含年视图；本 spec MUST NOT 实现年视图。
- **`EntryRepo` 的查询实现（按月计数 SQL、按日取条目 SQL、游标分页、时区三冗余字段重算）** —— 归 `data-layer`；本 spec 只**调用**其方法签名，不写任何 Drift/SQL（NF5）。
- **条目卡片 `DayzEntryCard` 的实现** —— 归 `ui-kit-components`；本 spec 只**复用**它渲染选中日条目并接「点击进 reader」回调。
- **路由表 / 抽屉「日历」入口接线 / 毛玻璃顶栏外壳** —— 归 `ui-shell-navigation`；本 spec 只复用 `Routes.calendar` / `Routes.reader` 常量与外壳顶栏壳，MUST NOT 自建路由表。
- **新建/编辑条目、删除、收藏切换** —— 本屏为只读回看视图；条目项收藏星仅**展示** `favorite` 状态，SHALL NOT 在本屏提供编辑/收藏切换交互。
- **多日记本筛选** —— 本屏按全部日记本聚合（与原型一致），不做按本筛选。

## 功能需求

### R1 · 全屏月视图（周一起始 + 日格三态）
系统 SHALL 渲染选中月份的月视图网格：周一起始、7 列、前导空格用占位格补齐；每个有条目的日格标一个 accent 圆点（`--accent`），今日格标 accent 环，被选中且有条目的日格为 accent 实底。
- 前提：进入日历屏，默认月 = 今日所在月、默认选中日 = 今日。
- 操作：观察月视图网格。
- 结果：当月每一天一个日格；有条目日（`monthData` 命中）为可点态 + accent 圆点（对应 `.cm-day.has` + `::after`）；今日格有 accent 环（对应 `.cm-day.today` 的 inset ring）；选中且有条目日为 `--accent` 实底 + `--on-accent` 文字（对应 `.cm-day.sel`）；无条目日为不可点、`--ink-4` 文字（对应无 `.has` 的禁用态）；前导占位格不可见不可点（对应 `.cm-day.pad`）。

### R2 · 月份导航（上/下月 + 月标题）
系统 SHALL 提供「上个月 / 下个月」导航，切换后重渲染月视图与月标题；月标题经 `package:intl` 格式化（如「2026 年 5 月」），MUST NOT 自拼字符串。
- 前提：当前查看某月。
- 操作：点「上个月」(`.cm-nav[data-prev]`) 或「下个月」(`.cm-nav[data-next]`)。
- 结果：查看月 ±1（跨年时年份进位/退位），月视图与月标题同步刷新；切月后**选中日不自动改变**（与原型一致：仅 `renderGrid`，选中态在新月若非同日则不高亮）。

### R3 · 回到今天
系统 SHALL 在顶栏提供「回到今天」动作，点击后查看月归位到今日所在月、选中日归位到今日，并刷新月视图与选中日条目列表。
- 前提：已切到非今日月份 / 选中非今日。
- 操作：点顶栏「回到今天」(`.ico[data-today]`)。
- 结果：查看月 = 今日月、选中日 = 今日；月视图与下方条目列表同步刷新到今日（对应原型 `data-today` 分支的 `render()`）。

### R4 · 选中日 → 当日条目列表
When 用户点一个有条目的日格，the 系统 SHALL 把该日设为选中并经 `EntryRepo` 取该自然日条目列表渲染到月视图下方（日期头 + 列表），列表项复用 `DayzEntryCard`。
- 前提：月视图中存在有条目日格。
- 操作：点某个 `.cm-day.has`（携 `data-day`）。
- 结果：该日格变选中实底；下方区显示选中日日期头（「M 月 D 日」+「周X · N 篇」，日期/计数走 `intl`/`AppStrings`）+ 该日条目列表（每项标题 + 摘要 + 收藏星状态）；点某条目项 → 经 `Routes.reader` 携该 entry id 导航进阅读屏。

### R5 · 选中无条目日 / 空月态
If 选中日没有条目，then 系统 SHALL 在下方显示该日日期头 + 一句空态说明（不渲染条目列表、不报错）。
- 前提：选中一个无条目日（或当月任何天均无条目）。
- 操作：选中该日（注：无条目日在 R1 为不可点；本需求覆盖「今日恰无条目」「`回到今天`后今日无条目」等选中态落到无条目日的情形）。
- 结果：下方显示日期头 +「这一天没有记录」类空态文案（`AppStrings`），无条目卡片、无异常（对应原型 `.cm-none`）。

### R6 · 数据加载中 / 失败的可观测态
While 月聚合计数或当日条目正在异步加载，the 系统 SHALL 显示非阻塞加载占位；If 查询失败，then 系统 SHALL 显示可重试的错误态，MUST NOT 让屏崩溃或停在空白。
- 前提：`EntryRepo` 查询为异步（`Future`/`Stream`）。
- 操作：进入屏 / 切月 / 选日触发查询，注入「pending」与「失败」两种数据态。
- 结果：pending → 月视图/列表区显示加载占位（不冻结导航）；失败 → 显示错误提示 + 重试入口，重试再次发起查询。

## 非功能需求

### NF1 · 视觉一律走 token（不硬编码）
本屏所有颜色/字号/间距/圆角/阴影 MUST 取自 `design-tokens-theme` 交付物（`context.dayz.*` + `DayzSpacing`/`DayzRadii`/`DayzMotion`/排版角色），MUST NOT 在屏内硬编码颜色十六进制 / 字号 / 间距。
- 度量：六套主题（purple/amber/sage × light/dark）下，日格圆点/环/实底取色等于该 theme×mode 的 `accent`/`accent-ink`/`on-accent` 真值；屏内不出现裸 `Color(0x..)` / 裸字号。

### NF2 · 对比度（WCAG AA）
本屏文本与有意义 UI 的对比度 MUST 满足 [`design-tokens-theme`](../design-tokens-theme/requirement.md) NF1 的分族标准：
- 选中日实底文字（`--on-accent` 落 `--accent`）MUST ≥ 4.5:1；
- 日期头/篇数/空态等真实辅助文本 MUST ≥ 4.5:1（用 `--ink-2`，不用纯 placeholder 的 `--ink-3`）；
- 今日环 / 选中圆点等有意义 UI（accent 贴 bg）MUST ≥ 3.0:1。
> 本屏复用 tokens-theme 已验的色对，不重复跑全套对比度；只验「本屏实际用到的渲染对」落在已验通过区间（tokens-theme 三处 expected-fail 若波及本屏用色，沿用其阻塞口径，MUST NOT 在本屏擅自改 `tokens.css`）。

### NF3 · 点击目标 ≥ 44px
所有可点元素（月份导航钮、回到今天钮、返回钮、可点日格、条目列表项）的命中区 MUST ≥ 44×44 逻辑像素。
- 度量：widget test 用 `tester.getSize` 断言各可点元素命中盒 ≥ 44；日格视觉虽小（`aspect-ratio:1/1`），命中区须以 padding/`MaterialTapTargetSize` 撑到 ≥ 44。

### NF4 · Semantics 标签
月份导航钮、回到今天钮、返回钮、日格、条目项 MUST 提供无障碍语义标签（`AppStrings` 集中），屏幕阅读器可识别用途；日格语义须含「日期 + 有/无条目 + 是否今日/选中」信息。
- 度量：`find.bySemanticsLabel` / `SemanticsNode` 断言关键控件有非空且语义正确的标签。

### NF5 · Repository 边界（硬红线）
本屏取数 MUST 只经 `EntryRepo`（按月聚合计数 + 按日取条目），MUST NOT import `lib/data/`、持有 Drift 句柄、或在屏内写 SQL/Drift 语句。
- 度量：屏源码静态核验不出现 `package:dayz/data/`、`drift`、`Database`、原始 SQL；取数全部经注入的 `EntryRepo` 抽象。

### NF6 · 动效尊重 reduce-motion
月切换 / 选中日切换 / 加载占位等动效 MUST 在系统「减弱动态效果」开启时降级为瞬时（无位移/缩放过渡）。
- 度量：注入 `MediaQueryData(disableAnimations: true)` 时，相关过渡时长经 `ui-kit-components` 的 `dayzMotionDuration` 门取得 `Duration.zero`（不在本屏自判，统一走该门）。

### NF7 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上正常渲染：月视图网格不溢出窄屏、CJK 日期/文案字体回退正常（沿用 tokens-theme NF2 字体回退结论）。
- 度量：360dp 宽视口下月视图 7 列网格不水平溢出（几何闸）；真机各验一次（人工）。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 只读回看，不碰密钥/写库/媒体密钥 |
| 权限 | 否 | 不申请任何系统权限 |
| 无障碍 | **是** | 点击目标 ≥ 44（NF3）、对比度 AA（NF2）、Semantics（NF4）、reduce-motion（NF6） |
| 性能 | 否 | 月级聚合查询轻量、无重活/无 isolate；无可度量运行阈值 |
| 多端兼容 | **是** | iOS 13+ / Android 8+ 渲染与字体回退（NF7） |

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui/` + `lib/demo/` + `test/`），不跨模块。
