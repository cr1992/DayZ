---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# favorites-screen（收藏屏）

## 背景

收藏屏是时间线的**过滤变体**：把所有被点亮收藏星的条目按时间倒序聚到一处，配一个「N 篇值得再读的」计数头与空态引导。屏源 [`ui-design/current/pages/screens/favorites.html`](../../../ui-design/current/pages/screens/favorites.html)（含 `?state=default|empty` 多状态），是抽屉「浏览」组下钻的次级页（导航层级见 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §9）。

设计上它**刻意比时间线简单**：无年月吸顶头、无日历跳转、无向上无限滚动——条目本就稀疏，朴素一段倒序列表即可（不套时间线屏的 sliver / `SliverPersistentHeader` / `scrollable_positioned_list` 复杂度）。它复用组件层的日记卡片 `DayzEntryCard`（含收藏星 `DayzFavoriteStar`）、空态 `DayzEmptyState`、毛玻璃顶栏 `DayzGlassAppBar`（均 `ui-kit-components` 交付），取数走 `EntryRepo` 的收藏过滤查询（`data-layer` 交付），不发明新取数路径、不持 Drift 句柄。

## 范围外

- **条目卡片本体**（`.entry`：date 列 / photo / head+star / excerpt / foot）与**收藏星**、**空态骨架**、**毛玻璃顶栏**的实现 —— 归 `ui-kit-components`（`DayzEntryCard` / `DayzFavoriteStar` / `DayzEmptyState` / `DayzGlassAppBar`），本 spec MUST NOT 重造，只组合复用。
- **收藏过滤查询 / 计数查询 / 软删除过滤** 的 SQL/Drift 实现 —— 归 `data-layer`（`EntryRepo`）；本屏 MUST NOT 写 SQL/Drift，只调 Repository 方法。
- **进入阅读页** 的阅读屏本体 —— 归 reader 页面级 spec；本屏点卡片只发 `Routes.reader` 导航（携 entryId），不实现阅读屏。
- **在本屏取消收藏后的乐观更新 / 即时移除动画** —— MVP 不做就地取消收藏交互（本屏卡片星标按设计为**只读展示**，取消收藏在阅读/编辑页完成）；SHOULD NOT 在本屏实现星标点击切换。
- **多日记本过滤 / 标签过滤 / 排序切换** —— 本屏只「全部收藏，按时间倒序」单一视图，不做二次筛选。
- 年月吸顶头、日历跳转、向上无限滚动 —— 时间线屏专属，本屏 MUST NOT 引入。

## 功能需求

### R1 · 收藏列表（有内容态）
When 收藏屏加载且存在收藏条目, the 收藏屏 SHALL 经 `EntryRepo` 取「全部未删除且 `is_favorite` 为真」的条目，按 entry 时间**倒序**渲染为一段朴素竖直列表，每条用 `DayzEntryCard` 呈现。
- 前提：库中有 ≥1 条收藏条目（`is_favorite=true` 且 `deleted_at IS NULL`）。
- 操作：导航到 `Routes.favorites`。
- 结果：列表按时间从新到旧排列；每张卡片显示日期列 / 标题 / 摘要 / 可选封面 / 可选 foot（标签·地点·心情）与已点亮的收藏星；卡片顺序与 `EntryRepo` 返回顺序一致。

### R2 · 计数头
While 处于有内容态, the 收藏屏 SHALL 在列表上方渲染计数头：overline 行（收藏星图标 + 「收藏」字样，着色文字走 `--accent-ink`、星用 `--favorite`）+ 衬线大标题「{N} 篇值得再读的」+ 副标题说明。
- 前提：有内容态，收藏数 = N。
- 操作：渲染计数头。
- 结果：标题中的 N 等于 `EntryRepo` 返回的收藏总数；N 经 `package:intl`（`NumberFormat`）格式化、MUST NOT 自拼字符串；overline / 标题 / 副标题文案取自 `AppStrings`，屏内禁裸中文。

### R3 · 空态
If 收藏屏加载且不存在任何收藏条目, then the 收藏屏 SHALL 隐藏列表与计数头，居中渲染 `DayzEmptyState`（收藏星空心插画 + 标题「还没有收藏」+ 引导「在某篇日记里点亮星标，它就会留在这里。」）。
- 前提：库中收藏条目数为 0。
- 操作：导航到 `Routes.favorites`。
- 结果：不渲染计数头与任何 `DayzEntryCard`；可见 `DayzEmptyState`，其标题与说明取自 `AppStrings`。

### R4 · 顶栏（返回 + 标题）
系统 SHALL 在收藏屏顶部渲染带返回钮的顶栏：左侧返回钮（`Routes` 栈 `pop`）、居中标题「收藏」、右侧无操作位。
- 前提：从抽屉「浏览 › 收藏」或其他入口下钻进入。
- 操作：点返回钮。
- 结果：返回上一屏（`Navigator.pop` / `context.pop`）；顶栏标题文案取自 `AppStrings`，返回钮带 Semantics 标签「返回」。
> 顶栏视觉外观（毛玻璃、滚动浮起、覆盖状态栏）由 `ui-kit-components` 的 `DayzGlassAppBar` 承载；本屏只装配它并接返回回调与标题，不重造毛玻璃。

### R5 · 进入阅读页
When 用户点击任一收藏卡片, the 收藏屏 SHALL 导航到对应条目的阅读页（`Routes.reader`，携该 entry 的 id）。
- 前提：有内容态、卡片可见。
- 操作：点击卡片可点区域。
- 结果：触发一次到 `Routes.reader` 的导航并传入该 entryId；本屏不实现阅读屏内容（reader spec 负责）。

### R6 · 加载与失败的工程态（设计稿未画，工程必需）
While `EntryRepo` 查询进行中, the 收藏屏 SHALL 显示一个克制的加载占位（不闪烁、不堆砌）；If 查询失败, then 收藏屏 SHALL 显示一个非崩溃的错误占位（含可读文案，文案取自 `AppStrings`），MUST NOT 抛未捕获异常致白屏。
- 理由：设计稿 `?state=` 只给 `default`/`empty`，但真实数据驱动屏必有 loading/error 中间态（PROTOTYPE-ARCH §6「`?state=` 多状态 → 同一 Widget 按 state 渲染」）。把这两态显式建为屏内状态，避免「未定义态 → 白屏 / 异常」。

## 非功能需求

### NF1 · Repository 边界（硬红线）
收藏屏 MUST 只经 `EntryRepo` 取数（收藏过滤 + 计数），MUST NOT `import` `lib/data/`（除 Repository 接口/DTO 外）、MUST NOT 持有任何 Drift 句柄或编写 SQL/Drift 查询。软删除过滤（`deleted_at IS NULL`）由 `EntryRepo` 查询入口默认承担，本屏不重复实现过滤逻辑。

### NF2 · 视觉一律走 token
收藏屏与其屏内私有组件（计数头等）MUST NOT 硬编码颜色 / 字号 / 间距 / 圆角 / 阴影；一律经 `context.dayz.*` + `DayzSpacing` / `DayzRadii` / `DayzMotion` 等取值（`design-tokens-theme` 交付）。计数头大标题用衬线排版角色（`.t-h2`/`.t-h1` 量级，`design-tokens-theme` 的 `dayz_text_theme`）。

### NF3 · 文案集中 + 国际化就绪
屏内用户可见中文 MUST 集中到 `AppStrings`（`ui-kit-components` 首建、本 spec 追加条目），屏内禁裸中文；计数（N 篇）MUST 经 `package:intl`（`NumberFormat`），MUST NOT 自拼数字字符串。widget 测试 MUST 用 `find.text(AppStrings.xxx)` / 断言渲染后的格式化串，而非裸中文字面量。

### NF4 · 无障碍
- **点击目标 ≥ 44px**：顶栏返回钮、可点击卡片命中区 MUST ≥ 44×44 逻辑像素。
- **对比度 ≥ WCAG AA**：计数头各文本（overline `--accent-ink` 落底、大标题 `--ink`、副标题 `--ink-2`）对其背景 MUST ≥ 4.5:1；空态文本同。本屏不引入新 token 值，对比度真源沿用 `design-tokens-theme` NF1 的六套逐项核验。
- **Semantics 标签**：返回钮、收藏星、计数头标题、空态 MUST 有可被屏幕阅读器识别的语义（返回钮「返回」、收藏星「已收藏」语义由 `DayzFavoriteStar` 提供，本屏不重复）。
- **reduce-motion**：本屏任何状态切换 / 加载占位动效 MUST 在系统「减弱动态效果」（`MediaQuery.disableAnimations`）开启时降级为瞬时（经 `ui-kit-components` 的 `dayzMotionDuration` 门）。

### NF5 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上正常渲染：列表滚动流畅、毛玻璃顶栏在低端 Android 允许降级为半透实色（降级在 `DayzGlassAppBar` 侧，本屏不另处理）；中英混排文案字体回退正常（沿用 `design-tokens-theme` NF2）。

### NF6 · 不触发缩略图同步重建（既有红线）
卡片封面图 MUST 经 `DayzEntryCard` 接收的 `ImageProvider`（由取数层提供缩略图），本屏滚动 MUST NOT 同步重建/生成缩略图（缩略图只暴露异步 `warmup`，见 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §3 与 `thumbnail-cache`）；本屏 MUST NOT 直接触发缩略图生成。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 纯展示屏，不碰密钥/加密/落库写入 |
| 权限 | 否 | 不申请任何系统权限 |
| 无障碍 | **是** | 点击目标 ≥44 / 对比度 AA / Semantics / reduce-motion（NF4）|
| 性能 | 否 | 朴素列表、稀疏数据，无可度量运行阈值（不做无限滚动） |
| 多端兼容 | **是** | iOS 13+ / Android 8+ 渲染与字体回退、毛玻璃降级（NF5）|

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui/`），不跨模块。
