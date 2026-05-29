# DayZ 更新日志（Changelog）

> 按**天**记录更新，每条标注涉及的**模块**便于筛选。
> 格式：`- [模块] 变更描述`。一天内可有多条，按模块归类。
> 模块清单会持续扩充，新增模块请同步补到下方「模块索引」。

## 模块索引
- **设计规范** — `design-system/`：tokens、组件、文档
- **主题色** — 雾紫 / 暖黄 / 雾绿三套强调色体系
- **侧边栏** — 手机端抽屉式导航
- **底部操作** — FAB 速拨（写日记 / 拍照 / 语音 / 清单）
- **图标** — 内联 SVG 图标与约定
- **文档** — CLAUDE.md、DESIGN-REF、changelog 等项目说明
- **数据层** — Drift / SQLite schema（见 docs/design）
- **编辑器** — 富文本编辑器（AppFlowy Editor，方案 A）
- **页面** — 产品页面设计交付物（`pages/`）：原型 + 画布双模式
- **架构** — 页面原型架构（`docs/PROTOTYPE-ARCH.md`）：一套屏幕源/两种呈现 + Flutter 映射
- **原型套件** — `prototype-kit/`：业务无关的可复用原型外壳（供新项目沿用）
- **UI** — Flutter `lib/ui` 界面实现

---

## 2026-05-29
- [文档] 初始化 `CLAUDE.md`，沉淀产品定位、设计基调（温润/克制、浅深双模式、中文为主）、token 架构与约定。
- [文档] 新建本 `CHANGELOG.md`，确立「按天 + 模块标签」记录规范。
- [设计规范] 搭建网页版设计规范文档骨架：`design-system/`（tokens.css / spec.css / spec.js）。
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
- [页面] **定档**：交付 `pages/index.html` —— 6 屏（时间线 / 阅读 / 编辑 / 往年今日 / 搜索 / 设置）。**原型模式**：单台 iPhone（灵动岛）跑可导航完整 App，带 iOS 推入/返回转场、返回栈、抽屉、FAB 起草；**画布模式**：6 屏平铺速览，可平移缩放。三主题×明暗实时切换；图片为程序生成的氛围占位图（可替换真实照片）。
- [文档] 更正 `CLAUDE.md` 编辑器选型：ProseMirror → **AppFlowy Editor**（方案 A），并补全能力集；`assets/editor/` 的 TipTap WebView 标记为备选方案 B。
- [页面] **重构为独立 iframe 架构**：每屏拆为独立可单独打开的文件 `pages/screens/<屏>.html`，状态用 URL 参数区分（`?state=`）；外壳（`pages/index.html` + `assets/pages.css` + `assets/app.js`）用 iframe 嵌入。**原型模式**：单机内嵌 iframe，跨屏跳转走 `postMessage`（`{type:nav|back}`），父级维护路由栈；主题经 `postMessage({type:theme})` 下发各 iframe。**画布模式**：改为**静态多状态**——每模块并排展示多个状态卡（iframe，pointer-events:none），左侧索引面板点击滚动定位。屏内逻辑收敛到 `assets/screen.css` + `assets/screen.js`（注入 iOS chrome、按 `data-when` 显隐状态、抽屉/FAB/导航）。
- [页面] 各模块新增状态：时间线（默认/抽屉/空）、阅读（含封面/纯文字）、编辑（空白/书写中/富格式）、往年今日（有内容/空）、搜索（输入中/有结果/无结果）、设置（默认）。
- [架构] **定档**：新建独立文档 `docs/PROTOTYPE-ARCH.md` 沉淀「一套屏幕源、两种呈现」原型架构——文件职责、屏幕契约、`postMessage` 协议、路由栈（缓存+预热），并给出**逐项 Flutter 落地映射**（屏→go_router 页、转场→CupertinoPageRoute、抽屉→Drawer、FAB→FloatingActionButton+BoxDecoration、token→ThemeExtension、编辑器→AppFlowy 等）。CLAUDE.md / DESIGN-REF 同步引用。
- [底部操作] FAB 立体化：色相受光渐变 + 三层投影（主色光晕/环境影/接触影）+ 顶部细高光，按压态加深、长按态浮起；按 Flutter 可落地方式实现（BoxDecoration gradient + List&lt;BoxShadow&gt;，避开 inset 阴影）。顶部高光偏白，后调淡（渐变白 78%→92%、高光 .30→.16）。
- [图标] 图标着色定调：曾尝试「分层多彩」（设置彩色徽 + 分类彩色描边 + 双色往年今日），评估过于花哨，**回退为统一单色** `currentColor`；仅保留日记本色点 `.dw-dot` 与收藏星 `--favorite` 两处数据性颜色。移除 `--ic-*` token。「往年今日」保留重设计的时钟回拨造型（单色）。DESIGN-REF §5 同步。
- [侧边栏] 抽屉底色由纯白 `--surface` 改为暖纸 `--bg`，降低"太白"感；移除抽屉内搜索入口（搜索统一走顶栏）。
- [搜索] 顶栏放大镜改为**就地展开输入框**（点击 → 顶栏morph为搜索框，回车 → 跳转搜索结果页），替代直接跳转；屏内由 `screen.js` 接管（`data-search-open/close/input`）。
- [页面] 时间线首页移除「全部日记」标题字样；原型路由改为页面缓存 + 空闲预热，跳转（搜索/往年今日等）秒开无加载等待。
- [页面] 根目录新增 `index.html`：直接跳转到 `pages/index.html`（不做独立落地页）。
- [页面] **画布模式重做为无限画布**：原先竖向文档式滚动 → 改为真正的设计画布——点阵网格背景（随平移/缩放无限延展）、按住拖拽平移、滚轮平移 / `Ctrl/⌘`+滚轮（或触控板捏合）以光标为锚点缩放、右下浮动缩放控件（±/百分比，点百分比重置并自适应铺排）；左侧索引由「滚动定位」改为「聚焦定位」（平移居中目标区块）；屏卡仍为各页多状态 iframe（pointer-events:none，静态评审）。PROTOTYPE-ARCH §1/§2 同步。
- [页面] **画布三模式 → 回退为单一浏览**：曾加「拖拽/交互/选择」三模式 + 元素 token 反查检视器（同源 iframe 注入探针把 `getComputedStyle` 反查 `var(--*)`），评估为面向 AI/开发场景过重（token 速查已在 DESIGN-REF），**定档为单一浏览**：无模式切换，卡片默认可交互，平移为通用手势（空白拖拽/滚轮/`空格`+拖拽）。修复过程中发现的「悬浮控件被平移吞点击」也一并保留修复（`pointerdown` 命中 `.cv-zoom` 跳过平移）。
- [页面] **画布缩放快捷键**：`+` 放大 · `-` 缩小 · `0` 重置自适应；`空格` 临时平移。仅画布、焦点不在输入框时生效。
- [架构] **框架沉淀为可复用启动套件**：将 `pages/` 的业务无关外壳抽成 `prototype-kit/`（`index.html` + `assets/{pages,app,screen}.css/js` + `tokens/spec.css` + `screens/{_template,home,detail}.html` + `README.md`），并在 `pages/screens/` 补 `_template.html` 空屏模板。PROTOTYPE-ARCH 新增 §8「复用这套框架做新原型（移植指南）」：复制整目录 → 换 tokens → 改 `SCREENS[]` → 照模板写屏。供以后新项目沿用。
- [文档] 沉淀补全（防腐化）：DESIGN-REF 登记此前只活在 `screen.css` 的屏内组件——`.empty`(空状态)、`.suggest-row`(搜索建议行)、`.topsearch`(顶栏展开搜索 + `data-search-*` 契约)、`.cb-*`(编辑器富格式块)、`.pg` 骨架；明确**真源分两处**（共享组件 spec.css / 屏内专属 screen.css）并分节(3b/3c)；修正残留腐化「工具栏对接 ProseMirror」→ AppFlowy；FAB 立体做法补进组件条目；搜索展开交互补进 PROTOTYPE-ARCH（含 Flutter `SearchAnchor`/`showSearch` 映射）。
- [原型套件] **沉淀文档体系**：kit 内补 `GETTING-STARTED.md`（从 0 到 1 设计操盘手册：定基调 → 设计系统先行 → 文档骨架 → 画屏 → 定档维护）、`CLAUDE.template.md`、`docs/{DESIGN-REF,CHANGELOG}.template.md` 与通用 `docs/PROTOTYPE-ARCH.md`；README 增「从 0 到 1 流程」「易踩的坑」「文档体系」三节。文件名一律英文（`从零开始.md` → `GETTING-STARTED.md`）。
- [文档] **新增「prototype-kit 反哺」常驻约定**（CLAUDE.md）：每次定档时若发现 kit 外壳/模板/文档有不足，同一步回灌改进——只回通用部分、改进要落档、保持 `index.html` 可独立跑通；让 kit 始终是当前最佳实践快照。
- [文档] **文件名去中文化**：`DayZ 设计规范/` → `design-system/`、`DayZ 设计规范.html` → `design-system.html`、`pages/DayZ 页面设计.html` → `pages/index.html`；全项目路径引用（根 `index.html` 跳转、CLAUDE.md、DESIGN-REF、PROTOTYPE-ARCH、CHANGELOG）同步更新。中文仅保留于正文/注释/标题，不再用于文件与目录命名。
- [页面] **时间线首页优化（定档）**：① 顶栏由"占位 flex 行"改为**悬浮覆盖层**——内容从其下方穿行，**毛玻璃覆盖到状态栏**；静止干净实底、滚动后（`.pg.scrolled`）半透 `--bg` 80% + `blur(20)` 浮起 + 0.5px 底分割。② 月份 `.tl-month` 吸顶停在顶栏正下方（`screen.js` 实测顶栏高写入 `--top-h`，供滚动留白 + 吸顶偏移）。③ **向上无限滚动**：最新在最上，滚到底按需追加更早月份 + 底部「载入更早」加载器 `.tl-loader`。
- [页面] **日期快速跳转 = 日历面板（定档）**：点月份头 `.tl-month` → 日历从顶栏下落下（`.cal-*`）。月视图（有条目的日 accent 圆点 + 今日环，可点跳到该日）/ 年视图（12 个月 + 篇数，点跳到该月）/「回到今天」。数据用 JS 轻量月份索引 `MONTHS`（哪些月/日有条目）→ 对应 Flutter 按月计数查询；跳到未渲染的更早月份先补渲染再滚。真源 `pages/assets/timeline.{css,js}`（时间线专属，不入通用 kit）。
- [架构/原型套件] **覆盖式顶栏 + 滚动毛玻璃 + `--top-h` 回灌 kit**：此属业务无关的通用外壳改进，已同步回 `prototype-kit/assets/screen.{css,js}`（示例屏 home/detail 直接受益）；PROTOTYPE-ARCH §3 屏幕契约同步说明。日期跳转/无限滚动为 DayZ 业务逻辑，留在 `pages/`，不回灌。
- [页面] **修复月份吸顶留白**：`.tl-month` 此前用 `top:var(--top-h)`，但 sticky 的 `top` 是相对滚动容器内容盒量的，而 `.app-scroll` 已 `padding-top:var(--top-h)`，导致叠加一段 `--top-h` 空隙。改为 `top:0`，月份头紧贴覆盖式顶栏底缘（gap=0）。
- [设计规范/字体] **字体瘦身（偏原生 · 定档）**：移除 `Noto Serif SC` + `Noto Sans SC` 两套 MB 级中文 Web 字体，**中文改走系统原生**（衬线 Songti SC/SimSun，无衬线 PingFang SC 等）；仅保留 `Newsreader` + `Hanken Grotesk` 两套小体积 Latin 品牌字（CDN）。`tokens.css` 字体栈调为「Latin 品牌字优先 → 原生 CJK」；全项目 13 处 Google Fonts `<link>` 同步去掉 Noto 两族。产品(Flutter)端两套 Latin 以打包字体资源下载引入。CLAUDE.md 设计基调 / DESIGN-REF §2.3 同步。
- [文档/约定] **新增最高约定「Flutter 优先」**（CLAUDE.md）：每个设计先想 Flutter 怎么还原，优先可映射到标准 widget 的方案；难做则退一步简化，不做无法落地的网页专属效果。
- [页面] **时间线头部融合 + 吸顶阴影**：① 顶栏与吸顶月份**共用同一毛玻璃**（80% 底 + blur20），去掉夹在两者间的分割线 → 并成一条连续磨砂头（消除割裂感）。② 真正吸顶中的月份（`.stuck`，timeline.js 按滚动判定，对应 Flutter `SliverPersistentHeader` 的 `overlapsContent`）底部加一道柔和投影与内容分层。③ **修复** `box-shadow` 无法从 `none` 过渡导致阴影不显示的问题——改为即时（Flutter 侧吸顶阴影本就即时）。
- [页面] **月份头交互改版**：去掉"下拉"箭头（易误解为展开），整行可点直接唤出日期跳转日历；右侧改放**小日历图标**作"按日期跳转"提示。
- [架构] **PROTOTYPE-ARCH §6 增补首页各效果的 Flutter 映射**：覆盖式毛玻璃顶栏（`extendBodyBehindAppBar`+`BackdropFilter`+`scrolledUnderElevation`）、吸顶头+`overlapsContent` 阴影、日历跳转（`scrollable_positioned_list`）、无限滚动+月份计数查询；并标注**痛点**（pinned 头 × 跳到未加载远期日期）与**退步方案**（日历只定位到月）。
- [文档] **痛点 + 踩坑沉淀（防遗忘）**：① 上述 Flutter 痛点 + 退步方案同时写进 `timeline.js` `jumpToMonth` 上方注释（贴着代码，落地时一眼可见）。② 两个通用 CSS 坑沉到 kit「易踩的坑」——「吸顶子头在 `padding-top` 容器里要用 `top:0` 否则留空隙」「`box-shadow` 不能从 `none` 过渡、否则阴影不显示」「顶栏与吸顶子头要同毛玻璃配方否则割裂」。③ **修正 DESIGN-REF 腐化**：吸顶 `top` 说明从过时的 `var(--top-h)` 改回实际的 `top:0`（与代码对齐）。
- [图标] **收藏星重绘（定档）**：原各处五角星为手绘、点位不对称（顶点偏移、左右臂不等长 → 视觉歪斜），统一替换为以中心 (12,12) 数学求点的对称五角星（外半径 9.5 / 内半径 4.2、顶点正上），填充/描边态只换 `fill`/`stroke`、path 不变。覆盖时间线卡片(`timeline.{js,html}`)、往年今日、阅读页收藏按钮、抽屉"收藏"、设计规范卡片/抽屉示例；规范路径登记进 DESIGN-REF §5 图标约定（防再次手绘走样）。
- [侧边栏] **抽屉选择即关闭（定档）**：切换日记本 / 切浏览视图等选择类操作选完即自动收起抽屉（90ms 让选中态先闪现再滑出）；带导航的项（往年今日 / 设置）本就跳走。新建日记本「＋」不关闭。
- [页面] **切换日记本刷新列表（定档）**：抽屉选中某本日记本后，更新顶栏标题为该本名（"全部日记"则留空）+ 列表滚回顶部 + 一次淡入重演（`.tl-refreshing`，模拟按所选本重新查询铺列表）；`screen.js` 派发 `dayz:journalchange`、`timeline.js` 接管刷新。对应 Flutter journal 变更后列表 rebuild + FadeTransition。
