# DayZ 更新日志（Changelog）

> 按**天**记录更新，每条标注涉及的**模块**便于筛选。
> 格式：`- [模块] 变更描述`。一天内可有多条，按模块归类。
> 模块清单会持续扩充，新增模块请同步补到下方「模块索引」。

## 模块索引
- **设计规范** — `DayZ 设计规范/`：tokens、组件、文档
- **主题色** — 雾紫 / 暖黄 / 雾绿三套强调色体系
- **侧边栏** — 手机端抽屉式导航
- **底部操作** — FAB 速拨（写日记 / 拍照 / 语音 / 清单）
- **图标** — 内联 SVG 图标与约定
- **文档** — CLAUDE.md、DESIGN-REF、changelog 等项目说明
- **数据层** — Drift / SQLite schema（见 docs/design）
- **编辑器** — 富文本编辑器（AppFlowy Editor，方案 A）
- **页面** — 产品页面设计交付物（`pages/`）：原型 + 画布双模式
- **架构** — 页面原型架构（`docs/PROTOTYPE-ARCH.md`）：一套屏幕源/两种呈现 + Flutter 映射
- **UI** — Flutter `lib/ui` 界面实现

---

## 2026-05-29
- [文档] 初始化 `CLAUDE.md`，沉淀产品定位、设计基调（温润/克制、浅深双模式、中文为主）、token 架构与约定。
- [文档] 新建本 `CHANGELOG.md`，确立「按天 + 模块标签」记录规范。
- [设计规范] 搭建网页版设计规范文档骨架：`DayZ 设计规范/`（tokens.css / spec.css / spec.js）。
- [主题色] 定义雾紫 / 暖黄 / 雾绿三套独立强调色体系，各含浅色 + 深色（accent / strong / soft / ink / on-accent / ring）。三套共享同一套 token 命名与语义，仅色相不同，组件自动适配。
- [设计规范] 定义中性色（暖白纸感 / 暖炭黑）、字体（衬线正文 + 无衬线 UI，中文优先）、间距 / 圆角 / 阴影标度。
- [设计规范] 组件样式：按钮、输入框、开关 / 勾选 / 分段控件、时间线日记卡片、编辑器工具栏、标签 / 心情 / 天气标记、顶栏、提示条 / 弹窗。
- [设计规范] **定档 v1.0**：主题色与基础规范确认，后续围绕此套 token 设计。
- [侧边栏] 新增手机端抽屉式侧边栏（从左滑出）：账户 → 搜索 → 视图（全部/往年今日/收藏/日历/媒体/地图）→ 日记本（小色点 + 计数）→ 标签 → 底部回收站/设置；选中态 accent-soft 底 + 左侧色条。
- [底部操作] 移除底部标签栏，改为单个 FAB 速拨：轻点直接写日记，长按展开拍照 / 语音 / 清单；导航统一收入抽屉。
- [文档] 新建 `docs/DESIGN-REF.md`（AI 速查手册）：token 全表 + 组件目录 + 类名 + 最小 HTML 片段 + 图标/贡献约定。
- [文档] 文档归档：`CHANGELOG.md`、`DESIGN-REF.md` 移入 `docs/`；CLAUDE.md 留根目录并补「DESIGN-REF 维护」约定（改动即同步、单一真源、准入门槛）。
- [图标] 重绘设置图标为轴对齐手绘齿轮（齿在正上下左右 + 四角，不再倾斜）；心情表情由 emoji 改为手绘 SVG 笑脸；新增全局图标垂直对齐规则。
- [设计规范] 新增页面级组件（spec.css）：时间线年月吸顶头 `.tl-month`、单篇阅读版式 `.reader`、往年今日年份分隔 `.year-sep`、搜索栏 `.search-*`、编辑页元信息/标题/正文 `.compose-*` + 底部停靠工具栏 `.editor-dock`、设置分组列表 `.set-*` / `.set-account`、搜索命中高亮 `.hl`；同步登记 DESIGN-REF。
- [编辑器] 明确选型为 **AppFlowy Editor**（方案 A）；编辑工具栏按其能力设计：标题、粗/斜/下划线/删除线/行内代码、文字颜色·高亮、无序/有序/待办列表、引用、链接、分隔线、图片（横向滚动工具条）。
- [侧边栏] 抽屉调整：回收站上移至「浏览」分组，底部仅留设置（传统齿轮图标）；抽屉 / 遮罩层级提至固定导航栏之上、状态栏之下。
- [页面] **定档**：交付 `pages/DayZ 页面设计.html` —— 6 屏（时间线 / 阅读 / 编辑 / 往年今日 / 搜索 / 设置）。**原型模式**：单台 iPhone（灵动岛）跑可导航完整 App，带 iOS 推入/返回转场、返回栈、抽屉、FAB 起草；**画布模式**：6 屏平铺速览，可平移缩放。三主题×明暗实时切换；图片为程序生成的氛围占位图（可替换真实照片）。
- [文档] 更正 `CLAUDE.md` 编辑器选型：ProseMirror → **AppFlowy Editor**（方案 A），并补全能力集；`assets/editor/` 的 TipTap WebView 标记为备选方案 B。
- [页面] **重构为独立 iframe 架构**：每屏拆为独立可单独打开的文件 `pages/screens/<屏>.html`，状态用 URL 参数区分（`?state=`）；外壳（`pages/DayZ 页面设计.html` + `assets/pages.css` + `assets/app.js`）用 iframe 嵌入。**原型模式**：单机内嵌 iframe，跨屏跳转走 `postMessage`（`{type:nav|back}`），父级维护路由栈；主题经 `postMessage({type:theme})` 下发各 iframe。**画布模式**：改为**静态多状态**——每模块并排展示多个状态卡（iframe，pointer-events:none），左侧索引面板点击滚动定位。屏内逻辑收敛到 `assets/screen.css` + `assets/screen.js`（注入 iOS chrome、按 `data-when` 显隐状态、抽屉/FAB/导航）。
- [页面] 各模块新增状态：时间线（默认/抽屉/空）、阅读（含封面/纯文字）、编辑（空白/书写中/富格式）、往年今日（有内容/空）、搜索（输入中/有结果/无结果）、设置（默认）。
- [架构] **定档**：新建独立文档 `docs/PROTOTYPE-ARCH.md` 沉淀「一套屏幕源、两种呈现」原型架构——文件职责、屏幕契约、`postMessage` 协议、路由栈（缓存+预热），并给出**逐项 Flutter 落地映射**（屏→go_router 页、转场→CupertinoPageRoute、抽屉→Drawer、FAB→FloatingActionButton+BoxDecoration、token→ThemeExtension、编辑器→AppFlowy 等）。CLAUDE.md / DESIGN-REF 同步引用。
- [底部操作] FAB 立体化：色相受光渐变 + 三层投影（主色光晕/环境影/接触影）+ 顶部细高光，按压态加深、长按态浮起；按 Flutter 可落地方式实现（BoxDecoration gradient + List&lt;BoxShadow&gt;，避开 inset 阴影）。顶部高光偏白，后调淡（渐变白 78%→92%、高光 .30→.16）。
- [图标] 图标着色定调：曾尝试「分层多彩」（设置彩色徽 + 分类彩色描边 + 双色往年今日），评估过于花哨，**回退为统一单色** `currentColor`；仅保留日记本色点 `.dw-dot` 与收藏星 `--favorite` 两处数据性颜色。移除 `--ic-*` token。「往年今日」保留重设计的时钟回拨造型（单色）。DESIGN-REF §5 同步。
- [侧边栏] 抽屉底色由纯白 `--surface` 改为暖纸 `--bg`，降低"太白"感；移除抽屉内搜索入口（搜索统一走顶栏）。
- [搜索] 顶栏放大镜改为**就地展开输入框**（点击 → 顶栏morph为搜索框，回车 → 跳转搜索结果页），替代直接跳转；屏内由 `screen.js` 接管（`data-search-open/close/input`）。
- [页面] 时间线首页移除「全部日记」标题字样；原型路由改为页面缓存 + 空闲预热，跳转（搜索/往年今日等）秒开无加载等待。
- [页面] 根目录新增 `index.html`：直接跳转到 `pages/DayZ 页面设计.html`（不做独立落地页）。
- [文档] 沉淀补全（防腐化）：DESIGN-REF 登记此前只活在 `screen.css` 的屏内组件——`.empty`(空状态)、`.suggest-row`(搜索建议行)、`.topsearch`(顶栏展开搜索 + `data-search-*` 契约)、`.cb-*`(编辑器富格式块)、`.pg` 骨架；明确**真源分两处**（共享组件 spec.css / 屏内专属 screen.css）并分节(3b/3c)；修正残留腐化「工具栏对接 ProseMirror」→ AppFlowy；FAB 立体做法补进组件条目；搜索展开交互补进 PROTOTYPE-ARCH（含 Flutter `SearchAnchor`/`showSearch` 映射）。
