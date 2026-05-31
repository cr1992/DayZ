---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# trash-screen（回收站屏）

## 背景

回收站是 DayZ「软删除安全网」在 UI 上的闭环出口（方法论 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §9 的页面级 spec，W2 波次）。产品红线：**删除一篇日记 = 移到回收站（软删，写 `deleted_at`），不是当场销毁**——reader / onthisday 等屏的删除动作经确认 + 可撤销 toast 后软删，条目落入回收站；回收站再提供「恢复 / 彻底删除」两条出路，30 天后台阶自动清除。整条删除/恢复链路全部经 `EntryRepo` 的软删/恢复/硬删，**不出 Repository 边界**（UI 不持 Drift、不写 SQL）。

源屏（多状态真源）：[`ui-design/current/pages/screens/trash.html`](../../../ui-design/current/pages/screens/trash.html)（`?state=default` 列表态 / `?state=empty` 空态）。本屏在导航树里是「抽屉 → 浏览组 → 回收站」的叶子页（见 `ui-shell-navigation` 抽屉结构 §D3），下钻自抽屉，无更深子页。

## 范围外

- **删除动作的发起方 UI**（reader / onthisday / 时间线卡片上的「删除」按钮 + 二次确认 sheet + 可撤销 toast）——归各自页面级 spec；本 spec 只**消费**软删结果（列出回收站）、并定义本屏自身的「彻底删除二次确认 sheet」「清空二次确认 sheet」。删除链路语义（软删=移回收站、可撤销窗口）作为**跨屏约定**写入本 spec R1 的「前提」，但发起方按钮不在本 spec 文件变更内。
- **30 天到期的后台台阶清理任务本身**（定时/启动时扫描 `deleted_at` 超期并 `hardDelete`）——属 data-layer / 后台任务范畴；本屏只**显示**「N 天后清除」倒计时与提示条，MUST NOT 在本屏实现后台清理调度。
- **EntryRepo 的软删/恢复/硬删/「列回收站条目」查询实现**——归 `data-layer`；本 spec 按交付物名调用，不写任何 Drift/SQL（NF5）。其中「恢复」与「列已软删条目」当前尚未在 data-layer 设计里显式交付，列为跨 spec 依赖并标待确认（见 design `## 已知风险`）。
- **缩略图 / 封面图渲染**：回收站条目卡按设计稿 `.trash-item` 只展示日期 / 标题 / 两行摘要 / 删除元信息，**无封面图**（源屏 `.trash-item` 无 `.photo`/`.gallery`）；故本屏不触发缩略图生成（天然避开「列表滚动禁止同步重建缩略图」红线）。
- 多选批量恢复 / 批量删除、回收站内搜索 / 排序 / 分组——源屏未呈现，MUST NOT 在本 spec 自行扩展。
- 媒体附件随条目硬删时的媒体文件级联清理——归 media-storage / 后台清理；本屏「彻底删除」只调 `EntryRepo.hardDelete`，文件级联归彼处（记已知风险）。

## 功能需求

### R1 · 回收站条目列表（默认态）
While 回收站非空，本屏 SHALL 以列表渲染全部已软删（`deleted_at` 非空）的日记条目，每条对应一张 `.trash-item` 卡。
- 前提：存在经删除链路软删的条目（删除链路约定：reader/onthisday 等屏删除 = 二次确认 + 可撤销 toast → `EntryRepo.softDelete`，条目落回收站；本屏不实现发起方按钮，见范围外）。
- 操作：进入回收站屏（抽屉「回收站」或 `Routes.trash`）。
- 结果：渲染顶栏「回收站」+「清空」按钮 + 30 天提示条 + 每条卡片含：删除日期（`.ti-date` 形如「5月 24 · 周六」，走 `intl`）、标题（`.ti-h4` 衬线）、两行摘要（`.ti-ex`，`maxLines:2` + 省略号截断，对齐 `-webkit-line-clamp:2`）、删除元信息（`.ti-left` 形如「删除于 3 天前 · 27 天后清除」，走 `intl`）、「恢复」按钮（`.btn-soft.btn-sm`）、「彻底删除」按钮（`.btn-text.btn-sm.ti-purge`，文字色 `--danger`）。

### R2 · 恢复条目
When 用户点某条目的「恢复」，本屏 SHALL 调 `EntryRepo`「恢复」交付物清除该条 `deleted_at`，并将该卡以移出动效（透明 + 右移）从列表移除，随后 toast「『{标题}』已恢复到时间线」（成功 tone）。
- 前提：回收站列表态、某条目可见。
- 操作：点该条「恢复」按钮。
- 结果：该条目从回收站消失（恢复后 `deleted_at` 为空 → 回时间线）；列表少一条；toast 出现且带条目标题；若列表恢复后变空，转入空态（R5）。

### R3 · 彻底删除（二次确认）
When 用户点某条目的「彻底删除」，本屏 SHALL 先弹二次确认 sheet（标题「永久删除？」、说明「这篇日记将被彻底删除，无法再恢复。」、确认按钮「彻底删除」、危险图标）；仅在用户确认后调 `EntryRepo.hardDelete(id)` 真删该条并以移出动效移除，随后 toast「已永久删除」（danger tone）。
- 前提：回收站列表态、某条目可见。
- 操作：点「彻底删除」→ 在确认 sheet 中点「彻底删除」。
- 结果：sheet 关闭 → `EntryRepo.hardDelete(id)` 被调用一次 → 该卡移除 → danger toast。
- If 用户在 sheet 中取消，then 本屏 SHALL NOT 调用 `hardDelete`、列表不变。

### R4 · 清空回收站（顶栏 · 二次确认）
When 用户点顶栏「清空」，本屏 SHALL：若回收站为空则仅 toast「回收站已经是空的」、不弹 sheet；否则弹二次确认 sheet（标题「清空回收站？」、说明「回收站里的所有日记将被永久删除，无法恢复。」、确认按钮「清空回收站」、危险图标），确认后对全部回收站条目逐条 `EntryRepo.hardDelete`、全部以移出动效移除并转入空态，随后 toast「回收站已清空」（danger tone）。
- 前提：回收站屏。
- 操作：点顶栏「清空」→ （非空时）在 sheet 中点「清空回收站」。
- 结果：全部条目硬删、列表转空态、danger toast。
- If 用户在 sheet 中取消，then 本屏 SHALL NOT 删除任何条目。

### R5 · 空态
While 回收站为空（无软删条目，或恢复/清空后变空），本屏 SHALL 显示空态（中性插画徽 + 标题「回收站是空的」+ 说明「删除的日记会先来这里待一阵，给你反悔的时间。」），并隐藏列表与 30 天提示条；顶栏「清空」仍在位（点击走 R4 的「已经是空的」分支）。
- 前提：回收站无可见条目。
- 操作：进入回收站屏 / 在屏内恢复或清空致列表变空。
- 结果：仅渲染 `.empty`（经 `DayzEmptyState`）；列表与提示条不可见。

### R6 · 30 天清除提示条
While 列表态，本屏 SHALL 在列表上方显示一条提示条（`.trash-banner`：时钟图标 + 文案「回收站里的日记在删除 30 天后自动永久清除，期间随时可以恢复。」），样式取 token（`--bg-2` 底、`--r-md`、`--ink-2` 文本、图标 `--ink-3`）。
- 前提：列表态（非空）。
- 操作：进入回收站屏。
- 结果：提示条可见、文案与设计稿一致、无封面图遮挡；空态下隐藏（R5）。

### R7 · 返回
When 用户点顶栏返回钮，本屏 SHALL 经 `Routes`/Navigator 返回上一屏（抽屉来源 → 关闭本屏回到时间线/抽屉栈），不残留本屏状态。
- 前提：本屏任意态。
- 操作：点顶栏左上返回钮（`.ico[data-nav-back]`）。
- 结果：本屏出栈，回上一屏。

### R8 · Debug Home 入口
本 spec SHALL 在 `lib/demo/demo_entry.dart` 的 `demos` 列表末尾追加一行，挂回收站屏 demo（可切默认态/空态、用内存假数据走恢复/彻底删/清空交互）。
- 前提：Debug Home 可用（真外壳就绪后降级为 `Routes.debugHome`，见 `ui-shell-navigation` D7）。
- 操作：进入 Debug Home → 选回收站 demo。
- 结果：可 pump 进入回收站屏 demo，演示四类交互；不插中间、不改 `DemoEntry` 字段。

## 非功能需求

### NF1 · 走 Repository 边界（硬红线）
本屏取数与删/恢复 MUST 只经 `EntryRepo`（列回收站条目 / 恢复 / `softDelete` / `hardDelete`），MUST NOT import `lib/data` 内部、MUST NOT 持 Drift 句柄或写 SQL/Drift。状态层经 `EntryRepo` 取数喂给本屏 widget；屏组件接收数据作入参，自身不持 Repo 句柄（便于 widget test 用假数据独立验证）。

### NF2 · 无障碍 — 点击目标
全部可点元素（返回钮、清空、每条「恢复」/「彻底删除」、sheet 确认/取消、空态无交互）的命中区 MUST ≥ 44×44 逻辑像素（移动端点击目标，DESIGN-REF §6/方法论 §11）。`.btn-sm`（设计 `padding:7px 14px`）视觉虽小，命中盒 MUST 经 padding / `MaterialTapTargetSize` 撑到 ≥44。

### NF3 · 无障碍 — 对比度
本屏实际渲染文本/控件对比度 MUST ≥ WCAG AA：正文/标题（`--ink`/`--ink-2` 对 `--surface`/`--bg`）≥ 4.5:1；「彻底删除」「清空」危险文字（`--danger` 对其底）≥ 4.5:1；提示条文本（`--ink-2` 对 `--bg-2`）≥ 4.5:1。删除元信息「删除于…·…后清除」（`.ti-left` 用 `--ink-3`）作真实辅助文本 MUST ≥ 4.5:1，若 token 实测不达标按 tokens-theme NF1 的 expected-fail 处理（改用 `--ink-2` 或报 @Ray 调 token，**MUST NOT 在本屏硬编码绕过**）。

### NF4 · 无障碍 — Semantics 标签
每条「恢复」/「彻底删除」按钮 MUST 携可被屏幕阅读器识别的语义标签（含条目标题，如「恢复 {标题}」「彻底删除 {标题}」），顶栏「清空」「返回」、空态插画、提示条 MUST 有语义标签 / 合理语义；widget 测试用 `find.bySemanticsLabel` / `find.text(l10n.xxx)` 定位。

### NF5 · 无障碍 — reduce-motion
卡片移出动效（透明 + 右移，源屏 `.trash-item.removing` 0.26s）MUST 尊重系统「减弱动态效果」：`MediaQuery.disableAnimations` 为真时动效时长降为 0（瞬时移除），经 `design-tokens-theme`/`ui-kit-components` 的 `dayzMotionDuration` 门统一取值，MUST NOT 在本屏各自硬判。

### NF6 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 正常工作：返回手势、`intl` 中文日期 / 相对时间格式化、`.btn-sm` 命中盒、移出动效在两端表现一致；中文衬线标题字体回退（落系统字）观感可接受。

### NF7 · 视觉走 token（不硬编码）
本屏全部颜色 / 字号 / 间距 / 圆角 / 阴影 / 动效 MUST 经 token（`context.dayz.*` + `DayzSpacing/DayzRadii/DayzMotion`）取用，MUST NOT 在屏内硬编码色值 / 字号 / 间距。屏内专属样式（`.trash-*`：banner / item / 元信息行 / purge 钮危险态）以本屏私有 widget 实现，私有视觉值仍读 token；用户可见文案写入 `lib/l10n/arb/app_zh.arb` + `app_en.arb`，运行期经 `AppLocalizations` 取用并跑 `gen-l10n`；日期/相对时间走 `intl`（屏内禁裸中文，落实 `docs/design/11-internationalization-and-localization.md`）。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 不碰密钥/加密；删除全经 `EntryRepo`，不直触 DB/文件 |
| 权限 | 否 | 不申请任何系统权限 |
| 无障碍 | **是** | 点击目标 ≥44（NF2）、对比度 WCAG AA（NF3）、Semantics（NF4）、reduce-motion（NF5）|
| 性能 | 否 | 单屏中等列表，无运行期可度量阈值（无缩略图、无无限滚动）|
| 多端兼容 | **是** | iOS 13+ / Android 8+ + intl 日期 + 返回手势（NF6）|

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui/trash/` + `lib/demo/` + `test/`），不跨模块。
