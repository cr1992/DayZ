# DayZ — 项目说明（CLAUDE.md）

## 产品
**DayZ** 是一款跨平台、**本地优先（local-first）、注重隐私、体验精致**的日记 App，对标 Day One。
技术栈：Flutter / Dart；数据层 Drift（SQLite + SQLCipher 加密）。当前 `lib/ui/` 为空，UI 属新建阶段。

核心场景：
- **时间线**：无限滚动的日记卡片流（游标分页）。
- **往年今日**：按 month/day 匹配历史条目。
- **富文本编辑器**：**AppFlowy Editor**（方案 A · Flutter 原生，`packages/appflowy-editor`）。能力集：标题(H1–H3)、粗/斜/下划线/删除线/行内代码、文字颜色·高亮、无序/有序/待办列表、引用、代码块、链接、分隔线、图片。内容存 `content_json` + `content_plain`。（`assets/editor/` 的 TipTap WebView 为备选方案 B，非当前选型。）
- **元数据**：标签（多对多）、心情、天气、地点、收藏；多日记本（journal 带 `color` 字段）。
- 全部软删除，按"将来要做同步与加密"预留字段。

## 设计基调（已与用户确认）
- 气质：**温润、安静、克制**，适合长期书写。
- 模式：**浅色 + 深色都要**。浅色为暖白纸感，深色为暖炭黑（非纯黑）。
- 排版：**中文为主、兼顾英文**。正文/日记用衬线，UI 用无衬线。
  - **Latin** 用品牌字体：衬线 **Newsreader**、无衬线 **Hanken Grotesk**（体积小，产品 Flutter 端以**打包字体资源**下载引入；原型 HTML 用轻量 CDN 仅加载这两套）。
  - **中文一律用系统原生字体**（衬线 Songti SC / 宋体，无衬线 PingFang SC 等），**不加载 Noto Serif/Sans SC 等大体积 CJK Web 字体**——克制、零下载。字体栈见 `tokens.css` 的 `--font-sans` / `--font-serif`（Latin 品牌字优先，其后接原生 CJK）。
- 主题色：**三套独立的强调色体系** —— 雾紫 purple / 暖黄 amber / 雾绿 sage。每套都是完整的一套色板（accent / strong / soft / ink / on-accent），可整体切换。

## 设计 Token
所有 token 定义在 `design-system/assets/tokens.css`，通过 `:root[data-theme][data-mode]` 切换。
- 切勿凭空发明颜色/字号/间距，一律引用 `var(--*)`。
- 中性色只随 `data-mode` 变；强调色随 `data-theme` + `data-mode` 变。
- 间距 4px 基准（`--sp-*`），圆角 `--r-*`，阴影暖调（`--shadow-*`）。
- 主题色映射到产品里 journal 的 `color` 字段与强调用途（按钮/选中/链接/图标点缀）。

## 交付物与文档
- `design-system/design-system.html` —— 网页版设计规范文档（人看：颜色/字体/间距/组件总览），含实时主题与明暗切换。
- `docs/DESIGN-REF.md` —— **AI / 开发速查手册**（机器友好）：token 全表 + 组件目录 + 类名 + 最小 HTML 片段 + 图标/贡献约定。**复用组件前先读它。**
- `docs/PROTOTYPE-ARCH.md` —— **页面原型架构**：`pages/` 的「一套屏幕源、两种呈现（原型/画布）」iframe 体系 + postMessage 协议 + 路由栈，并含**对应的 Flutter 落地映射**。改 `pages/` 结构或新增屏幕前先读它；§8 是把这套框架搬到新项目的移植指南。
- `prototype-kit/` —— **可复用原型启动套件**：上述框架抽出的业务无关外壳（壳 + 通用屏内逻辑 + 空屏模板 + 示例屏 + README）。新项目要沿用这套原型方式时,从这里复制起步。
- `docs/CHANGELOG.md` —— 更新日志（按天 + 模块标签）。
- `docs/BACKLOG.md` —— **待办 / 需求池**：记录尚未动手或未定档的需求与交互缺口（「要做的」）；与 CHANGELOG（「做完的」）互补。某项定档后从 BACKLOG 移除并写入 CHANGELOG。
- `docs/handoff/` —— **走查任务单**：按目标代码区一份（如 `editor.md` 对 `lib/ui/editor/*`），列原型↔原生差异 + 改法 + 验收 checklist，受众是落地该模块的原生 agent。生命周期「🚧 待落地 → 验收全过 → 移入 `_archive/`」，约定见 `docs/handoff/README.md`。
- 项目文档统一收纳在 `docs/`（CLAUDE.md 因需置于根目录而保留在根）。

## 约定
- **Flutter 优先（最高约定）**：每做一个设计/交互，**先想「Flutter 怎么还原」，而不仅是网页能不能实现**。优先选能映射到标准 widget 的方案（`SliverAppBar`/`SliverPersistentHeader(pinned)`/`BackdropFilter`/`ScrollController`/`scrollable_positioned_list` 等，映射见 `PROTOTYPE-ARCH.md` §6）。**若某效果 Flutter 难做或代价过高，宁可退一步简化设计**，也不要在原型里做出无法落地的网页专属效果；确需保留的网页取巧要在 §6 注明其 Flutter 对应/降级方案。
- 新设计/组件一律遵循上述 token 与基调，保持克制（少即是多，避免无意义的数字、图标、渐变堆砌）。
- CJK 正文行高放宽（1.7–1.8）以保证中文阅读舒适度。
- 移动端点击目标 ≥ 44px。

## Changelog 维护
- 维护 `docs/CHANGELOG.md`，**按天 + 模块标签**记录（格式 `- [模块] 描述`）。
- **定档后自动更新**：仅当某项工作被确认定稿（"定档"）后，才把它写入当天 changelog；过程中的草稿/试验不记录。无需用户提醒，定档即写。
- 新增模块时同步补充 changelog 顶部「模块索引」。
- **同日合并（硬规则）**：写条目前先 `grep '^## <今天日期>' docs/CHANGELOG.md`，命中就把新条目 append 到那段，**绝不新开第二个同日 `## YYYY-MM-DD`**。新的一天则在文件**顶部**（模块索引下方）开新段——**newest-first，最新日期段永远在最上面**。
- **深度上限**：一条 = 1 行标题 + 最多 3 子 bullet。变更叙事不是验尸报告——根因/踩坑一句话带过，深内容分流到对应 doc 并指路。
- **滚动窗口 + 归档**：主文件只留最近约 2 个会话日；超 ~200 行就把窗口外**最旧的整段（文件底部）**移到 `docs/_archive/CHANGELOG-YYYY-MM.md`（原样保真），底部留链接。

## 收尾同步表（DoD · `done` 前逐行过）
> 核心纪律：**任何影响产物的改动都带一个同步义务**，漏一项 = 文档/索引漂移。下表是 checklist，各项「为什么」见下方维护小节。

| 改了 | 必做 |
|---|---|
| `tokens.css` 加/改 token | 同步 `DESIGN-REF.md` Token 速查表 |
| 新增 / 改 / 删可复用组件 | 登记 / 更新 `DESIGN-REF.md` 组件目录（类名 + 最小 HTML）；没登记的视为临时草稿 |
| 在某屏**局部私补**基础组件样式（如给 `.btn` 补 `justify-content`）才能用 | 当作「基础类有洞」的信号：优先回 `spec.css` 补基础类、撤掉私补，而非就地绕过 |
| 给组件加了 spec 里**已定义却从没被触发**的变体（如 `.btn[disabled]`） | 确保至少一处真实用例会触发它——没用例 = 没被肉眼测过，必腐化 |
| 改 `pages/` 屏结构或新增屏 | 同步 `SCREENS[]`；必要时更新 `docs/PROTOTYPE-ARCH.md` |
| 任何 CSS/JSX 改了**颜色相关**值 | 自查 + 跑 `tools/check-tokens.js`（read_file → 粘进 run_script）：禁裸 `#hex` / 禁裸 `rgba()` / 禁假 fallback，一律 `var(--*)`（允许 token→token fallback）。脚本带 baseline 只报增量；清了旧违规跑 `args=['--write-baseline']` 同步 |
| 在实战中改进了 `prototype-kit/` 外壳/逻辑/模板 | 反哺 kit + 记 `- [原型套件] …`；改了契约同步 `PROTOTYPE-ARCH.md` |
| 改了 `docs/CHANGELOG.md` | 跑 `tools/check-changelog.js`（read_file → run_script）：重复同日段 = FAIL · 超 200 行 = warn 提示归档 · 条目超 3 子 bullet = warn 点名。纯只读、无 baseline |
| 任意定档 | 写当天 `CHANGELOG.md`（先 grep 同日段，命中即 append） |

### 机读 guard（`tools/`）
把上表里靠自觉的两条纪律变成可机检的守卫。我是 agent、不能直接 `node`：流程统一是 **read_file 脚本 → 整个粘到 run_script 执行**（脚本只用沙箱 helper：`readFile`/`saveFile`/`ls`/`log`）。
- `tools/check-tokens.js` — 扫 `design-system/` `pages/` `prototype-kit/` + 根 `index.html` 的 .css/.js/.jsx/.html，抓裸 hex / 裸 rgba / 假 fallback。**自动遍历目录**（新增屏不漏扫、不需维护文件清单），跳过任何 `tokens.css`（token 唯一真源）与 `img/` 资产。带 `tools/check-tokens.baseline.json`：**只报增量**，清了旧违规跑 `args=['--write-baseline']` 同步。首版 baseline（2026-06-03）已接受 156 处现状——设备 chrome（灵动岛/镜片）、文档色板展示值、journal 色点种子数据属合理保留；产品 CSS 里散落的 `#fff`/`#000`/照片蒙层 rgba 是待 burn-down 的尾巴。
- `tools/check-changelog.js` — 纯只读扫 `docs/CHANGELOG.md`：重复同日段=FAIL、超 200 行=warn 提示归档、条目超 3 子 bullet=warn 点名。

## DESIGN-REF 维护（保证不腐化）
- **改动即同步**：任何对 token / 组件 / 模式（pattern）的新增或修改，**与定档同一步**更新 `docs/DESIGN-REF.md`——新增组件补「组件目录」条目（类名 + 最小 HTML），改 token 补「Token 速查」。改完 DESIGN-REF 再写 changelog，二者成对出现。
- **单一真源**：`tokens.css` 是 token 唯一真源；DESIGN-REF 只做索引与语义说明，不重复定义数值。若两者冲突，以 `tokens.css` 为准并立即修正 DESIGN-REF。
- **新组件准入**：组件只有在 DESIGN-REF 有条目后才算「可复用」；没登记的视为临时草稿。

## prototype-kit 反哺（保持可复用）
- **沉淀即反哺**：每次定档时，若在实战中发现 `prototype-kit/` 的外壳 / 屏内逻辑 / 空屏模板 / 文档模板（CLAUDE/DESIGN-REF/CHANGELOG/GETTING-STARTED）有不足或更好写法，**同一步**把改进同步回 kit——让 kit 始终是「当前最佳实践」的快照，而非一次性产物。
- **只回灌通用部分**：业务专属内容（DayZ 的屏、token 值、产品文案）不进 kit；只把与业务解耦的机制、约定、模板改进回灌。
- **改进要落档**：动了 kit 就在 `CHANGELOG.md` 记 `- [原型套件] …`；若改了契约/机制，同步更新 `docs/PROTOTYPE-ARCH.md` 与 kit 内 `README.md`/`GETTING-STARTED.md`。
- **不破坏可独立运行**：改完 kit 后 `prototype-kit/index.html` 必须仍能直接打开跑通（示例屏 home/detail 不依赖业务）。
