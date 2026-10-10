---
作者：@Ray
创建日期：2026-06-06
最后更新：2026-10-10
文档状态：定稿
---

# editor-rich-blocks（编辑器富块扩展：标注块 callout）

## 背景

`editor-json-contract`（已归档）把编辑器文档结构定档为一个**封闭块清单**——段落 / 标题 / 列表 / 待办 / 引用 / 分割线 / 图片 + 两个 DayZ 自定义块（location / weather）。该契约的封闭集里**没有** callout（标注块）与 code（代码块）。

2026-06-04 设计走查（`ui-design/current/docs/handoff/editor.md` §8c）新增「标注块 callout」能力：日记场景常把「一句心得 / 提醒」高亮成块。原型 `editor.html` 的格式面板「列表与块」段已落地标注块按钮，内容样式见 `screen.css` 的 `.compose-body .cb-callout`（`--accent-soft` 底 + `--accent-ink` 信息图标 + 圆角 `--r-md`，**不做左边框配色**）。

**关键事实（已读源码确认）：** fork 包 `packages/appflowy-editor/lib/src/editor/block_component/` 下**没有** callout 目录，上游**未提供** `CalloutBlockComponentBuilder` / `CalloutBlockKeys`。因此 callout 须**在 DayZ 侧自建**，沿用既有自定义块（location / weather）的落法：每块各带编辑 + 只读 builder，注册进 `editor_block_registry.dart`，type 收进 `block_types.dart` 的封闭集，并按 `editor-json-contract` 处理自定义块的方式扩展 codec 往返与导出降级（markdown / plain）。

本 spec 是对该封闭契约的**扩展**（契约已归档、终态只读，扩展按 spec-guide「返工一律新建 spec」走）。**本轮只实现 callout**；代码块（§7）设计已再定档但实现后置，仅在本 spec 立一张占位卡记录，避免遗失。

### 现状对齐（2026-10-10 定稿审阅）

按设计真源 `editor.html`「列表与块」`data-block=ul|ol|todo|quote|code|callout|divider` 逐项核对（代码基线 `9d6fdf8`）：

| 块类型 | 块契约（type / builder / codec / 降级） | 格式面板入口 | 本 spec 动作 |
|---|---|---|---|
| 段落 / 标题 / 无序 / 有序 / 待办 / 引用 / 分隔线 / 图片 | `editor-json-contract` 封闭集已覆盖 | `editor-integration-screen` S2 已实现（`[-]` 待 @Ray 人工签收） | 无（NF3 不回归） |
| callout | 本 spec T1–T4 已交付（`0d4cfda`） | S2 已实现（「列表与块」标注项，`DayzIcons.callout`） | T7：渲染参数 / 图标收口到设计真源与仓库约束 |
| code | 未覆盖（fork 仍无 code builder，2026-10-10 复核） | S2 本轮省略（handoff §7 延后） | T6 后置登记，v1 不实现 |
| location / weather | `editor-json-contract` 自定义块 | 非面板项（meta 区） | 无 |

审阅发现 T2 交付的 callout 渲染与设计真源 / 仓库约束有偏差：图标用 `Icons.info_outline_rounded`（违「图标一律走 `DayzIcons`」）、圆角写死 8（真源 `--r-md`=14）、内距 10/12（真源 `--sp-3 --sp-4`）、图标 18 / 间距 8（真源 20 / `--sp-3`）、块外距沿用 AppFlowy 默认上下 4（真源 `margin: --sp-4 0`）。R2 / NF2 已据此收紧，补 T7 落地。与 S2 的边界不变：S2 只负责入口与 type 切换，本 spec 只负责块本身。

## 范围外

- **工具栏 / 格式面板的 callout 插入入口** SHALL NOT 在本 spec 实现——入口（格式面板「列表与块」段的标注项、状态双向同步）归 `editor-integration-screen`（S2，已实现）。本 spec 只交付 block type + 块渲染 + 注册 + codec 往返 + 导出降级。
- v1 拍板不做心情 mood、不做纸色轴；本 spec 不涉及二者，callout 配色只随既有 data-theme × data-mode。
- **代码块（code block）本轮 MUST NOT 实现**——仅立占位卡记录再定档结论与后置理由（见 R4）。
- callout 的**富文本嵌套结构 / 多段内容**：本轮 callout MUST 只承载单行 `delta` 文本（对齐原型 `.cb-callout .tx` 单段文字），不支持块内嵌子块。
- callout 不引入「类型 / emoji / 多色变体」等扩展属性；样式固定走 `--accent-soft` + `--accent-ink`，SHALL NOT 预留左边框配色那套。
- 上游官方 HTML / Markdown encoder 对 callout 的原生序列化：不接入；导出仅保证本契约的 plain / markdown 降级（与 location / weather 同策略）。

## 需求

### R1 · callout 块 type 经 EditorDocCodec 无损往返
系统 SHALL 支持 `type='callout'` 的块节点，经 `EditorDocCodec.encode` → `decode` 后结构与文本无损还原，且 `EditorBlockTypes.supported` 与 `EditorExportFallback.supportedTypes` 封闭集**包含** `callout`、不再落到未知块兜底。
- 前提：一个含 callout 节点（带 `delta` 文本）的 `Document`
- 操作：`EditorDocCodec.encode(doc)` 得字符串，再 `EditorDocCodec.decode(str)`
- 结果：还原出的 `Document` 中该 callout 节点 `type=='callout'`、`delta` 文本与原文逐字一致；`EditorBlockTypes.supported.contains('callout')` 为真

### R2 · callout 按主题映射的 `--accent-soft` 渲染（无左边框，参数对齐 `.cb-callout`）
系统 SHALL 用 `CalloutBlockComponentBuilder`（编辑 + 只读两态）渲染 callout：背景取**当前主题**的 `--accent-soft` 对应 Flutter 色（随 data-theme purple/amber/sage × data-mode light/dark 切换），信息图标取 `--accent-ink`，圆角 `--r-md`，正文取 `--ink`；几何参数对齐真源 `screen.css` `.compose-body .cb-callout`：内距 `--sp-3`（上下）`--sp-4`（左右）、图标与文字间距 `--sp-3`、图标 `DayzIcons.callout` 20px、块外距上下 `--sp-4`。
- 前提：编辑器以某主题（如 amberDark）渲染含 callout 节点的文档
- 操作：渲染该 callout
- 结果：callout 容器背景色 == 该主题的 `DayzColors.accentSoft`，图标色 == `DayzColors.accentInk`；切到另一主题（如 sageLight）背景随之变为该主题的 accentSoft；容器 MUST NOT 出现左边框配色（无 `border-left` 等价物）；圆角 == `DayzRadii.md`、内距 == `DayzSpacing.s3`/`s4`、图标为 `DayzIcon(DayzIcons.callout, size: 20)`、块外距 == `DayzSpacing.s4`

### R3 · callout 导出降级（plain / markdown）
系统 SHALL 为 callout 提供与 location / weather 同源的导出降级：`EditorExportFallback.fallbackLineForNode` 与 `EditorPlainTextExtractor` 对 callout 节点产出其 `delta` 纯文本行（markdown 降级用引用前缀 `> ` 标注语义），缺文本时产出空、不抛异常。
- 前提：含 callout（`delta` 文本 = "记得复盘"）的文档
- 操作：调 `EditorPlainTextExtractor.extract(doc)` 取 plain；调 `EditorExportFallback.fallbackLineForNode(node, format: EditorExportFallbackFormat.markdown)` 取 markdown 行（plain 为默认 `format`）
- 结果：plain 含一行 `记得复盘`；markdown 行为 `> 记得复盘`；callout `delta` 为空时该行降级为空字符串、整条抽取不崩溃

### R4 · 代码块占位（本轮不实现，仅登记）
系统层面本轮 SHALL NOT 注册 / 渲染 code 块；该需求仅作**登记占位**——记录设计再定档（handoff §7）、`editor-json-contract` 当初移出 MVP 的理由、以及将来落地时沿用的 DayZ 侧自定义块路径。
- 前提：本轮交付
- 操作：—
- 结果：`block_types.dart` 的 `supported` MUST NOT 含 `code`；`editor_block_registry.dart` MUST NOT 注册 code builder；后置事实记录在 tasks 的占位卡（验收 `N/A（后置）`）

## 非功能需求

### NF1 · 抽取 / 降级纯同步无 I/O
callout 的 plain 抽取与导出降级 MUST 为纯同步函数、无文件 / 网络 I/O（与 `editor-json-contract` NF1 一致），保证可在任意线程同步调用。

### NF2 · 主题契约一致性（不发明颜色）
callout 渲染 MUST 仅引用 `DayzColors` 既有语义色（`accentSoft` / `accentInk` / `ink`）、既有圆角 / 间距 token（`DayzRadii` / `DayzSpacing`）与既有图标标记（`DayzIcons.callout` 经 `DayzIcon` 渲染），SHALL NOT 凭空写死 hex、`Colors.*` 字面色、数值圆角或 `Icons.*`——颜色随主题切换由 `DayzColors` 唯一驱动（对齐 `tokens.css` 为色彩唯一真源）。

### NF3 · 封闭契约扩展不回归既有块
新增 callout MUST NOT 改变 location / weather / 标准块既有的 codec 往返、抽取与降级行为——`editor-json-contract` 既有契约测试须保持通过（扩展是加法，不是改写）。

## 选档说明（专项维度逐维表态）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 仅块渲染 / 序列化，不触加密 / 权限 / 文件 |
| 权限 | 否 | 不涉系统权限 |
| 无障碍 | 否 | 本轮不新增无障碍专项约束（沿用编辑器既有语义） |
| 性能 | 否 | 抽取为纯同步小函数，无量级阈值；NF1 是正确性约束非性能阈值 |
| 多端兼容 | 否 | 纯 Flutter 块组件，不分端实现 |

**升标准档理由（跨任务校验，非专项维度）：** 本 spec 扩展一个**跨消费方的封闭契约**——codec 往返 ⊕ 导出降级（plain/markdown）⊕ 注册表 ⊕ 块清单常量分属不同被改文件，「callout 端到端：插入 → 渲染 → codec 往返 → 导出降级」的串联校验依赖**多个任务产物同时存在**（定义见 spec-guide P1「跨任务校验」），故升标准档、该校验移入 verification.md。
