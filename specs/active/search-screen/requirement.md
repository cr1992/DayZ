---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# search-screen（搜索屏）

## 背景

搜索屏是从外壳顶栏放大镜钮（`ui-shell-navigation` 的 `Routes.search`）进入的次级叶子页，让用户按关键词/标签找回历史日记。设计稿真源 [`ui-design/current/pages/screens/search.html`](../../../ui-design/current/pages/screens/search.html)（含 `?state=typing|results|empty` 三态）给出三种**呈现态**，但**原型只画了静态呈现、没画"正在查"与"查询出错"**——真实 Flutter 屏必须把它补成一个完整的状态机（见 R1）：输入 → 防抖 → 查询 → 按命中计数判空 → 切态，查询失败要有 error 兜底，否则一遇异常就白屏。

本屏的取数**只经 Repository**（`EntryRepo`），UI 不持 Drift 句柄、不写 SQL（硬红线，NF2）。但 `data-layer` 本期 **D8 明确「Repository 不暴露 FTS 查询 API」**，中文 FTS（ICU/trigram）归远期——故本屏 MVP **先做标题 / 标签 / 纯文本（`content_plain`）的 LIKE 子串匹配**，依赖一个**尚未存在**的 `EntryRepo` 查询入口（见 design D6 跨 spec 依赖与已知风险，标「待确认」）。中文 FTS 切换是后续远期事。

结果列表**复用 `ui-kit-components` 的 `DayzEntryCard`，但用朴素 `ListView`**——不套时间线屏的吸顶月份头 / 日历跳转 / 无限滚动那套复杂度（那些归 `timeline-screen`）。命中词在标题与摘要里高亮（R3）。

## 范围外

- **中文 FTS（ICU / trigram tokenizer）** —— 归 `data-layer` 远期 FTS spec；本屏 MUST NOT 自接 tokenizer，只用 LIKE 子串匹配。
- **时间线的吸顶月份头 / 日历跳转 / 无限滚动游标分页** —— 归 `timeline-screen`；本屏结果列表 SHALL 用朴素 `ListView`，MUST NOT 引入 `SliverPersistentHeader` 吸顶或日历面板。
- **筛选 chip 的真实筛选落库逻辑**（`# 家` / `全部日记本` / `有照片` / `2026` 等条件的查询拼装） —— 本屏只渲染筛选 chip 的**视觉与去除交互（`.x`）**并把筛选条件作为查询入参传给 `EntryRepo`；筛选条件如何转成 where 子句归 `EntryRepo` 实现（data-layer），本屏 MUST NOT 写筛选 SQL。
- **最近搜索 / 标签建议的持久化存储** —— idle 态的「最近搜索」列表与「标签」建议来源（`TagRepo` / 最近搜索历史）属数据层；本屏接收列表入参渲染，落库归 data-layer / 后续，未就绪用空列表降级（见 design 已知风险）。
- **进入阅读页后的渲染** —— 点结果卡片 SHALL 导航 `Routes.reader`（携 entryId）；阅读屏本体归 `reader-screen`。
- 顶栏就地展开搜索（`.topsearch` / `data-search-open`）—— 那是**时间线顶栏**内的交互（归 `ui-shell-navigation` / `timeline-screen`），本屏是它跳转后的**结果页**，自身是独立的 `.search-head` 全屏搜索屏。

## 功能需求

### R1 · 搜索状态机（五态，补齐原型缺的 querying / error）
搜索屏 SHALL 实现一个显式状态机，至少含五态：`idle`（无输入，显示最近搜索 + 标签建议）、`typing`（有输入、防抖等待中）、`querying`（查询执行中）、`results`（有命中）、`empty`（零命中）；并在查询抛错时进入 `error`（不期望行为兜底）。
- 前提：用户在搜索屏。
- 操作：聚焦输入框（无文字）→ 键入字符 → 等待防抖窗口 → 查询返回。
- 结果：依次呈现 idle → typing → querying →（命中>0）results /（命中==0）empty；查询抛异常则呈现 error 态（带重试入口），不白屏、不崩。

### R2 · 输入防抖触发查询
While 用户连续键入，搜索屏 SHALL 对查询做防抖（去抖窗口内只发最后一次查询），并在每次发起新查询前丢弃上一次未完成查询的结果（避免乱序覆盖）。
- 前提：输入框已有焦点。
- 操作：在防抖窗口内连续键入 `梅`→`梅子`→`梅子酱`。
- 结果：只对最终词 `梅子酱` 发起一次有效查询；中途 `梅`/`梅子` 的迟到结果 MUST NOT 覆盖最终结果（旧查询结果被丢弃）。

### R3 · 命中词高亮（Text.rich 直角高亮）
Where 结果卡片的标题或摘要包含命中词，搜索屏 SHALL 用 `Text.rich` 把命中子串渲染为高亮 `TextSpan`（背景 `--accent-soft-2`、文字 `--accent-ink`，对应设计稿 `.hl`），非命中部分保持常规文本样式。
- 前提：results 态，某卡片标题含查询词。
- 操作：渲染该卡片。
- 结果：命中子串的 `TextSpan` 背景色 == `context.dayz.accentSoft2`、前景色 == `context.dayz.accentInk`；其余文字用卡片常规样式；高亮包裹不改变文本换行语义（仍为同一段 `Text.rich`）。

### R4 · 按命中计数判空切态
When 查询返回，搜索屏 SHALL 依命中条数切态：`count > 0` → results（顶部 `.search-stat` 显示「找到 N 篇 · 按时间倒序」）；`count == 0` → empty（显示空态插画 + 「没有找到『{query}』」+ 引导文案）。
- 前提：querying 态、查询已发起。
- 操作：查询返回 count。
- 结果：count>0 渲染 N 张 `DayzEntryCard` 且计数文案的 N == 实际卡片数；count==0 渲染 `DayzEmptyState`，标题含当前查询词。

### R5 · idle 态：最近搜索 + 标签建议
While 输入为空（idle），搜索屏 SHALL 显示「最近搜索」分组（`.suggest-row`：图标 + 词 + 可选「N 篇」计数）与「标签」分组（`DayzTag` chip 列）。
- 前提：进入搜索屏、输入框为空。
- 操作：观察首屏。
- 结果：渲染「最近搜索」与「标签」两个 `.search-sec` 分组（数据由入参提供，空列表则该分组不渲染或显示空骨架）；点某条建议 / 标签 SHALL 回填查询词并触发查询（进入 typing→querying）。

### R6 · 取消返回
搜索屏 SHALL 在 `.search-head` 右侧提供「取消」按钮，点击返回来源页（弹出本路由）。
- 前提：在搜索屏任意态。
- 操作：点「取消」。
- 结果：当前路由出栈，回到来源页；输入态不残留。

### R7 · 进入阅读页
When 用户点击某结果卡片，搜索屏 SHALL 导航到 `Routes.reader` 并携带该 entry 的 id。
- 前提：results 态。
- 操作：点击一张 `DayzEntryCard`。
- 结果：路由变为 `Routes.reader`，携 entryId 入参（reader 屏渲染归 `reader-screen`）。

### R8 · error 态可重试
If 查询抛出异常（如取数入口失败），then 搜索屏 SHALL 进入 error 态，显示错误说明与「重试」入口，点重试以**相同查询词**重发查询。
- 前提：querying 态查询抛错。
- 操作：进入 error → 点「重试」。
- 结果：error 态显示错误文案 + 重试钮（不崩、不白屏）；点重试回到 querying 态、以同词重发；成功后正常切 results/empty。

### R9 · Debug Home 入口
搜索屏 SHALL 提供一个 Debug Home demo 入口，可在真机/模拟器以假数据独立 pump 进入并走查五态。
- 前提：开发调试。
- 操作：从 Debug Home 列表进入搜索 demo。
- 结果：demo 用内存假数据渲染，可手动切换/触发 idle / typing / querying / results / empty / error 各态。

## 非功能需求

### NF1 · 无障碍
- **点击目标 ≥ 44px**：取消钮、建议行、标签 chip、筛选 chip 的去除叉 `.x`、结果卡片可点区，命中盒 MUST ≥ 44×44 逻辑像素。
- **对比度 ≥ WCAG AA**：高亮文字（`--accent-ink` 落 `--accent-soft-2`）、`.search-stat` 计数文本、空态文案对其背景 MUST ≥ 4.5:1（普通文本）；占位/辅助态 ≥ 3.0:1 仅限纯装饰。对比度真源沿用 `design-tokens-theme` 的 `test/ui/theme/contrast_xfail.yaml`，本屏不另立阈值、不重复造表。
- **Semantics 标签**：取消钮（「取消」）、输入框（「搜索日记」）、结果卡片（含标题语义）、空态、重试钮 MUST 有可被屏幕阅读器识别的 `Semantics` 标签（取自 `AppLocalizations`）。
- **reduce-motion**：输入光标 `.caret` 闪烁（设计稿 `dz-caret` 动画）与任何切态过渡 MUST 在系统「减弱动态效果」(`MediaQuery.disableAnimations`) 下降级为静止/瞬时（经 `ui-kit-components` 的 `dayzMotionDuration` 门，不在本屏自判）。

### NF2 · Repository 边界（硬红线）
搜索屏的全部取数 MUST 只经 `EntryRepo`（命中查询）/ `TagRepo`（标签建议，若用）；UI 层 MUST NOT import `lib/data` 的 Drift 句柄、MUST NOT 出现任何 SQL / Drift 查询字符串、MUST NOT 自行拼装 FTS / LIKE 语句（LIKE 子句的拼装归 `EntryRepo` 实现）。本屏对取数入口的依赖以**接口签名**方式持有（构造注入），可用假实现独立测试。

### NF3 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 正常工作：朴素 `ListView` 滚动流畅、中英混排命中高亮换行正常（CJK 走系统字回退，沿用 tokens-theme 字体策略）、安全区（顶部 `.search-head` / 底部）让位正确。

### NF4 · 视觉走 token（不硬编码）
本屏所有颜色 / 字号 / 间距 / 圆角 / 动效 MUST 走 `context.dayz.*` + `DayzSpacing/DayzRadii/DayzMotion`（来自 `design-tokens-theme`），MUST NOT 在屏内硬编码色值/字号/间距；屏内私有视觉值（如 `.search-input` 的 `--bg-2` 底 + `--r-full` 圆角、`.hl` 的 `--accent-soft-2`/`--accent-ink`/3px 圆角/`0 2px` padding）以 `search.html` 关联的 `spec.css` 解析后值为参数闸真源（见 verification 样式参数闸）。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 纯展示/查询屏，不碰密钥；取数经 Repo（边界是 NF2，不属"安全"专项的加解密范畴）。 |
| 权限 | 否 | 不申请任何系统权限。 |
| 无障碍 | **是** | NF1（点击目标 ≥44 / 对比度 AA / Semantics / reduce-motion）。 |
| 性能 | 否 | 无可度量运行阈值硬约束（防抖是行为需求 R2、非性能阈值；列表性能沿用 data-layer 索引 NF，不在本屏立阈）。 |
| 多端兼容 | **是** | NF3（iOS 13+ / Android 8+，中英混排换行、安全区）。 |

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui` + `lib/demo` + `test/`），不跨模块（design `## 文件变更` 仅落 `lib/ui/search/`、`lib/demo/`、`test/ui/search/`，复核确认无第二模块）。
</content>
</invoke>
