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
- 排版：**中文为主、兼顾英文**。正文/日记用衬线（Newsreader + Noto Serif SC），UI 用无衬线（Hanken Grotesk + Noto Sans SC）。
- 主题色：**三套独立的强调色体系** —— 雾紫 purple / 暖黄 amber / 雾绿 sage。每套都是完整的一套色板（accent / strong / soft / ink / on-accent），可整体切换。

## 设计 Token
所有 token 定义在 `DayZ 设计规范/assets/tokens.css`，通过 `:root[data-theme][data-mode]` 切换。
- 切勿凭空发明颜色/字号/间距，一律引用 `var(--*)`。
- 中性色只随 `data-mode` 变；强调色随 `data-theme` + `data-mode` 变。
- 间距 4px 基准（`--sp-*`），圆角 `--r-*`，阴影暖调（`--shadow-*`）。
- 主题色映射到产品里 journal 的 `color` 字段与强调用途（按钮/选中/链接/图标点缀）。

## 交付物与文档
- `DayZ 设计规范/DayZ 设计规范.html` —— 网页版设计规范文档（人看：颜色/字体/间距/组件总览），含实时主题与明暗切换。
- `docs/DESIGN-REF.md` —— **AI / 开发速查手册**（机器友好）：token 全表 + 组件目录 + 类名 + 最小 HTML 片段 + 图标/贡献约定。**复用组件前先读它。**
- `docs/PROTOTYPE-ARCH.md` —— **页面原型架构**：`pages/` 的「一套屏幕源、两种呈现（原型/画布）」iframe 体系 + postMessage 协议 + 路由栈，并含**对应的 Flutter 落地映射**。改 `pages/` 结构或新增屏幕前先读它。
- `docs/CHANGELOG.md` —— 更新日志（按天 + 模块标签）。
- 项目文档统一收纳在 `docs/`（CLAUDE.md 因需置于根目录而保留在根）。

## 约定
- 新设计/组件一律遵循上述 token 与基调，保持克制（少即是多，避免无意义的数字、图标、渐变堆砌）。
- CJK 正文行高放宽（1.7–1.8）以保证中文阅读舒适度。
- 移动端点击目标 ≥ 44px。

## Changelog 维护
- 维护 `docs/CHANGELOG.md`，**按天 + 模块标签**记录（格式 `- [模块] 描述`）。
- **定档后自动更新**：仅当某项工作被确认定稿（"定档"）后，才把它写入当天 changelog；过程中的草稿/试验不记录。无需用户提醒，定档即写。
- 新增模块时同步补充 changelog 顶部「模块索引」。

## DESIGN-REF 维护（保证不腐化）
- **改动即同步**：任何对 token / 组件 / 模式（pattern）的新增或修改，**与定档同一步**更新 `docs/DESIGN-REF.md`——新增组件补「组件目录」条目（类名 + 最小 HTML），改 token 补「Token 速查」。改完 DESIGN-REF 再写 changelog，二者成对出现。
- **单一真源**：`tokens.css` 是 token 唯一真源；DESIGN-REF 只做索引与语义说明，不重复定义数值。若两者冲突，以 `tokens.css` 为准并立即修正 DESIGN-REF。
- **新组件准入**：组件只有在 DESIGN-REF 有条目后才算「可复用」；没登记的视为临时草稿。
