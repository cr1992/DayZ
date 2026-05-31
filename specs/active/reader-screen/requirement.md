---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-31
文档状态：草稿
---

# reader-screen（单篇阅读屏）

## 背景

「单篇阅读」是时间线 / 往年今日 / 搜索 / 收藏点开一篇日记后的**叶子屏**（导航树最深一层）：经 `CupertinoPageRoute` 右滑推入、支持边缘返回，**只读**呈现一篇日记的封面、衬线正文、元数据（天气 / 地点 / 心情 / 标签）与多图九宫格，并在顶栏提供收藏星 toggle 与 ⋯ 动作菜单（编辑 / 分享 / 移到日记本 / 收藏 / 删除）。它是 DayZ「温润、安静、克制」基调最重的阅读场景，版式**数据驱动**——空字段不渲染、不留空槽。

屏源真源：[`ui-design/current/pages/screens/reader.html`](../../../ui-design/current/pages/screens/reader.html)（两态：`?state=default` 图文长篇含封面 + 九宫格 + 多标签；`?state=text` 纯文字短篇，无封面 / 天气 / 地点 / 九宫格）；版式组件 `.reader` / `.read-hero` 见 [`DESIGN-REF.md`](../../../ui-design/current/docs/DESIGN-REF.md) §3b；HTML→Flutter 机制映射见 [`PROTOTYPE-ARCH.md`](../../../ui-design/current/docs/PROTOTYPE-ARCH.md) §6（`CupertinoPageRoute` / 页面入参 + 状态、`showModalBottomSheet`、`ScaffoldMessenger`）。

本屏是**页面级 spec**（方法论 [`docs/design/10`](../../../docs/design/10-ui-restore-and-design-sync.md) §9 W2），消费 `design-tokens-theme` / `ui-kit-components` / `ui-shell-navigation` 的交付物，取数只经 Repository（NF5 硬红线）。

## 范围外

- **编辑功能本身**：动作菜单「编辑」MUST 仅经 `Routes.editor` 导航到编辑屏（携 entryId），编辑屏的富文本能力归 `editor-json-contract` / 编辑屏 spec；本 spec MUST NOT 实现任何编辑 / AppFlowy 命令。
- **真实分享链路**：动作菜单「分享」在本 spec 仅触发一条 toast 占位反馈（对齐原型 `data-share` 行为）；真实分享（`RepaintBoundary.toImage` / `share_plus` / 链接生成）归后续 spec，本 spec SHALL NOT 接入真实分享 SDK。
- **回收站列表与恢复 / 彻底删除**：删除在本屏只做「软删除（`EntryRepo.softDelete`）+ toast 撤销」，回收站屏（`trash`）与 30 天清理归各自 spec。
- **正文富文本渲染引擎**：本 spec v1 的只读正文 SHALL 仅按 `content_plain` 切分段落，并按设计稿 `.r-body p`（衬线段落）渲染纯文本；MUST NOT 在本屏解析 `content_json`、实现 AppFlowy 只读渲染器或行内格式 / 列表 / 引用渲染。富文本只读渲染归 `editor-json-contract` / 编辑屏后续交付；未来仅替换 `ReaderBody` 的正文渲染注入点，不改变本屏版式、媒体、菜单与动作编排验收口径。
- **相册查看器（全屏看图 / 缩放 / 翻页）**：点九宫格图进入的全屏查看器归 media-picker / 后续相册查看器 spec；本屏只做「九宫格展开（`+N` 蒙层就地展开）」。
- **参数 / 几何抽取 harness 与 SSIM 兜底**：归 `design-sync-automation`；本 spec 用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验。

## 功能需求

### R1 · CupertinoPageRoute 推入与边缘返回
单篇阅读屏 SHALL 经 `CupertinoPageRoute`（或 `go_router` 配置的 Cupertino 转场）推入，带 iOS 右滑入场动画与边缘返回手势；顶栏返回钮亦 SHALL 触发返回（`Navigator.pop`）。
- 前提：从时间线 / 往年今日 / 搜索 / 收藏点开一篇日记（携 entryId 入参）。
- 操作：进入本屏；点顶栏返回钮或边缘右滑。
- 结果：入场为右滑转场；返回钮 / 边缘手势均退回上一屏。

### R2 · 数据驱动版式（空字段不渲染）
单篇阅读屏 SHALL 按该 entry 的实际数据渲染版式，对**为空**的字段 MUST NOT 渲染其槽位（不留空白占位）。
- 前提：一篇 entry，其封面 / 天气 / 地点 / 心情 / 标签 / 九宫格各自可能有或无（对应 `?state=text` 即无封面 / 无天气 / 无地点 / 无九宫格的纯文字篇）。
- 操作：渲染本屏。
- 结果：有封面才渲染 `read-hero`；有天气 / 地点 / 心情 / 标签才渲染对应 `r-meta` 元素；正文段落始终渲染；无任一字段时其行 / 块在 widget 树中不存在（`find` 不到），相邻块间距按存在的相邻元素折叠（不出现空槽撑出的间距）。

### R3 · 阅读版式结构与排版角色
单篇阅读屏 SHALL 按 `.reader` 版式自上而下渲染：（可选）封面 `read-hero` → `r-kicker`（含日历图标 + 日期，日期走 `intl`）→ `h1`（衬线大标题）→ `r-meta`（weather-chip + tag + 地点，存在才渲染）→ `r-body`（基于 `content_plain` 的衬线纯文本段落）→（可选）九宫格 → `r-tags`（标签组）。
- 前提：渲染 default 态长篇。
- 操作：取各文本块的排版角色与样式。
- 结果：标题用 `.t-h1` 衬线角色、正文段落用 `.t-diary` 衬线角色（`height==1.85`、`leadingDistribution==even`），正文 v1 只断言 `content_plain` 段落渲染，不断言 `content_json` 行内格式 / 列表 / 引用效果；kicker / 地点 meta 用 caption / 次要文本角色；顺序与设计稿 `reader.html` 一致；颜色 / 字号 / 间距 / 圆角全部取自 `context.dayz.*` / `DayzSpacing` / `DayzRadii`，**屏内无硬编码视觉值**。

### R4 · 封面与多图九宫格走加密媒体 + 异步缩略图
Where 该 entry 有媒体，单篇阅读屏 SHALL 经 `MediaRepo` 取媒体元数据、经 `MediaStore.openRead` / `ThumbnailCache` 异步取解密后的封面与九宫格图，**MUST NOT 在构建 / 滚动路径同步重建缩略图**（缩略图只能经 `ThumbnailCache.warmup` 异步入队）。
- 前提：default 态长篇，含封面 + N 张图（N>9 时第 9 格显 `+N` 蒙层收起）。
- 操作：渲染封面与 `DayzGallery`。
- 结果：图源经加密媒体链路异步加载（加载中显占位、就绪后显图）；列数随张数（1/2/3/4/≥5）对齐 `DayzGallery` 约定；超 9 张时第 9 格 `+N` 蒙层、其余收起；构建与滚动期间不触发同步缩略图生成。

### R5 · 九宫格就地展开
While 九宫格第 9 格为 `+N` 收起态，单篇阅读屏 SHALL 在点击该 `+N` 蒙层时**就地展开**露出全部图（对齐 `reader.html` 给 `.gallery` 加 `.expanded`），MUST NOT 因此导航离屏。
- 前提：九宫格 > 9 张、处于收起态。
- 操作：点第 9 格 `+N` 蒙层。
- 结果：原收起的格露出、`+N` 蒙层消失；当前屏不变（不 push 新路由）。

### R6 · 收藏星 toggle（顶栏 ↔ 菜单同步）
单篇阅读屏 SHALL 在顶栏提供收藏星（`DayzFavoriteStar`）；点击在「收藏 / 取消收藏」间切换，经 `EntryRepo` 更新该 entry 的 favorite 字段，并弹 toast；动作菜单内的「收藏 / 取消收藏」项与顶栏星 SHALL 保持状态同步（一处改、另一处即时反映）。
- 前提：进入本屏，entry 当前为未收藏。
- 操作：点顶栏收藏星（或菜单「收藏」项）。
- 结果：星变实心金（`--favorite`）、`Semantics`/`aria-pressed` 反映已选中；toast「已收藏」（tone=fav）；再次点击恢复空心线 + toast「已取消收藏」；顶栏星与菜单项始终一致。

### R7 · ⋯ 动作菜单
单篇阅读屏 SHALL 在顶栏提供 ⋯ 钮，点击经 `DayzSheet.actions` 弹出动作菜单，条目顺序对齐 `reader.html`（screen.js `openEntryMenu`）：编辑 → 分享 → 移到日记本 → 收藏/取消收藏 → （分隔）→ 删除（danger）。
- 前提：进入本屏。
- 操作：点 ⋯ 钮。
- 结果：底部弹层显示上述六项（含一条分隔线，删除为 `tone=danger`）；点「编辑」经 `Routes.editor` 导航；点「分享」弹分享 toast；点「移到日记本」打开单选选择器；点「收藏/取消收藏」同 R6；点「删除」走 R8。

### R8 · 删除 = 软删 + toast 撤销
单篇阅读屏 SHALL 在动作菜单点「删除」时先弹二次确认（`DayzSheet.confirm`：标题「删除这篇日记？」、说明「将移到回收站，30 天内可恢复。」、确认钮「移到回收站」）；确认后经 `EntryRepo.softDelete` 软删该 entry、弹可撤销 toast（tone=danger、action「撤销」）、并返回上一屏；点「撤销」SHALL 经 `EntryRepo`（清除 `deleted_at`）恢复该 entry 并弹「已恢复」toast。
- 前提：进入本屏。
- 操作：⋯ → 删除 → 确认「移到回收站」。
- 结果：调用 `EntryRepo.softDelete(entryId)`；toast「已移到回收站」带「撤销」动作；随后 `Navigator.pop` 返回；点「撤销」恢复并 toast「已恢复」。**MUST NOT 在本屏做硬删除（真 DELETE）**。

### R9 · 移到日记本（单选选择器）
单篇阅读屏 SHALL 在动作菜单点「移到日记本」时经 `DayzSheet.picker` 弹单选选择器，列出经 `JournalRepo` 取得的日记本（名 + 篇数 + 色点），命中当前日记本打勾；选定后经 `EntryRepo` 更新该 entry 的 journalId 并弹 toast「已移到「X」」。
- 前提：进入本屏，entry 属某日记本。
- 操作：⋯ → 移到日记本 → 选一个目标日记本。
- 结果：选择器各行带色点（`journal.color`）与篇数；当前本右侧打勾；选定后 `EntryRepo` 更新 journalId、toast「已移到「目标本名」」。

## 非功能需求

### NF1 · Repository 边界（硬红线）
本屏所有取数 / 写入 MUST 只经 `EntryRepo` / `MediaRepo` / `JournalRepo` / `TagRepo`（及 `MediaStore` / `ThumbnailCache` 的媒体读取入口）；MUST NOT import `lib/data/` 的 Drift 句柄、表、DAO，MUST NOT 在屏内写任何 SQL / Drift 查询。

### NF2 · 媒体不重缩略 / 不同步重建（红线）
封面与九宫格图加载 MUST NOT 在 widget 构建或列表滚动路径触发同步缩略图生成；只能经 `ThumbnailCache.warmup`（异步入队）或读已就绪的 `ThumbnailHandle`。媒体经独立设备媒体密钥解密（不随主密码，见 `docs/design/06`）——本屏不假设主密码可锁住照片。

### NF3 · 无障碍
- 所有可点击控件（返回钮、收藏星、⋯ 钮、九宫格 `+N`、sheet 行）命中目标 MUST ≥ 44×44 px。
- 收藏星 / ⋯ 钮 / 返回钮 MUST 有 `Semantics` 标签（来自 `AppStrings`，如「收藏」「更多」「返回」），收藏星 MUST 暴露选中态（`Semantics.toggled` / `aria-pressed` 等价）。
- 正文 / 标题 / 元数据文本对底对比度 MUST ≥ WCAG AA（4.5:1）；本屏只引 `context.dayz.*` token，对比度由 `design-tokens-theme` NF1 在 token 层保证，本屏不引入屏内硬编码色。
- 动效（sheet 滑入 / 转场 / 九宫格展开）MUST 经 `dayzMotionDuration` 尊重系统「减弱动态效果」（`MediaQuery.disableAnimations`）——开启时动效时长降为 0 / 近瞬时。

### NF4 · 文案集中与本地化
屏内用户可见文案 MUST 集中到 `AppStrings`（屏内禁裸中文）；日期（`r-kicker` 的「2026年5月27日 · 周三」）MUST 走 `package:intl` 格式化，MUST NOT 自拼字符串；widget 测试用 `find.text(AppStrings.xxx)` 而非裸中文。

### NF5 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上正常工作：`CupertinoPageRoute` 边缘返回在 iOS 生效、Android 用系统返回；中英混排正文走 `fontFamilyFallback`（CJK 系统字），九宫格图解码 / 占位在两端观感可接受。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 取数走 Repository、媒体走既有加密链路，本屏不碰密钥 / 加密实现（仅消费） |
| 权限 | 否 | 不申请系统权限（相册选择归 media-picker） |
| 无障碍 | **是** | 点击目标 ≥44 / 对比度 AA / Semantics / reduce-motion（NF3） |
| 性能 | 否 | 单屏只读渲染，无可度量运行阈值；缩略图性能归 thumbnail-cache |
| 多端兼容 | **是** | iOS 13+ / Android 8+ 转场与字体回退（NF5） |

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui/reader/` + `lib/demo/` + `test/`），不跨模块。
