# DayZ 更新日志（Changelog）

> 按**天**记录更新，每条标注涉及的**模块**便于筛选。**最新的日期段在最上面**（newest-first）。
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
- **相册** — 多图日记九宫格 `.gallery`（列数随张数 + 超量收起）
- **媒体** — 沉浸式媒体层：大图查看器 `.lbx`(DZ.lightbox) + 全屏选择器 `.pk`(DZ.picker)，暖近黑 `--media-*`
- **提示条** — 全局 toast 系统 `.toast` / `.toast-host` + 引擎 `DZ.toast()`
- **弹层** — 底部弹层 sheet（动作菜单 / 选择器 / 轻表单）+ 引擎 `DZ.sheet()`
- **背景/纸色** — `data-bg` 纸色轴（纯净/暖纸/主题微染/深褐/自定义）
- **UI** — Flutter `lib/ui` 界面实现
- **工具** — `tools/`：机读 guard 脚本（token 纪律 / changelog 卫生）

---

## 2026-06-26
- [设计规范/字体] **字体反转：中文改打包思源 SC（定档）**：推翻此前「字体瘦身·偏原生·零下载」决定——产品 Flutter 端打包**思源黑体/宋体**（Noto Sans/Serif SC，全简体 ~8200 字子集 × 4 字重，OFL-1.1，约 23MB）作 CJK 主力，换取各平台渲染一致；体积代价 Ray 主动接受。
  - `tokens.css`（×3：pages/design-system/app-icons）字体栈调为「Latin 品牌字 → 思源 SC → 系统字」，系统 Songti/PingFang 退为生僻字深层兜底；CLAUDE 设计基调 + DESIGN-REF §2.3 同口径改写。
  - 原型 serif 内联思源宋子集保 WYSIWYG（`Noto Serif SC` 挂进各屏 Google Fonts `<link>`，build-standalone.py 构建期按可见字 `&text=` 子集化 + `__DZ_FONTS__` 去重，weights 400/600；产物 7.9MB、零外部请求）；onthisday 屏 Flutter 未落地，真机截图验收 defer（见 BACKLOG）。

## 2026-06-04
- [编辑器] **工具栏二次调整：列表上提、链接下沉（定档）**：无序/有序列表提到工具栏（`data-tb-block=ul|ol|todo` 与面板块状态双向同步），工具栏由 7→8 件；链接较低频，收进格式面板「文字样式」行（`data-mark=link` 拉起链接面板）。同步 DESIGN-REF §3c + handoff §8a。
- [编辑器] **工具栏按高频重排 + 格式面板全集 + 新增标注块（定档）**：`.toolbar.editor-dock` 精简为 7 件高频（Aa·格式/B/I/颜色/待办/图片/链接），其余格式收进 `Aa·格式`键盘位面板（段落+列表与块+文字样式三段，additive·状态双向同步）。
  - 代码块 `data-block=code` 入「列表与块」（定调：做）；新增**标注块 callout** `.cb-callout`（`--accent-soft` 底 + `--accent-ink` 信息图标），接 AppFlowy `CalloutBlockKeys`。
  - 面板加 `.kb`：`min-height:288px` 向键盘看齐、内容多时自然生长（`max-height:62vh` 兜底滚动）；同步 DESIGN-REF §3c + handoff §7/§8。
- [编辑器] **走查原生编辑页，回写 handoff §0/§5/§6（定档）**：对照 `lib/ui/editor/*` + `lib/editor/contract/*`，#1–#4（暖调色板/meta·日期·关闭图标/标题「正文」项）原生已对齐，§6 对应项打勾。
  - #5 图片插入「设计已定档但原生未落地」：`editor_image_inserter.dart` 仍直连 `ImagePicker(gallery)` 单图，全库无 `photo_view` → `DZ.picker`/`DZ.lightbox` 两件套件原生仍为 0，列为待落地。
  - 新增 §7 代码块矛盾：原型 `rich`/DESIGN-REF 列了代码块，但两边工具栏无按钮、原生 registry `block_types` 不含 codeblock（会渲染成「[未支持块]」）——待定调（建议删 demo）。
- [原型套件] **kit 去 DayZ 具体设计 + newest-first/handoff 约定回灌（定档）**：明确 kit 只承载脚手架 + 工作约定，不带具体设计。拿走 `spec.css`/`screen.css` 里的 DayZ 产品件（心情/天气/日记卡/编辑器工具栏 + dock/抽屉内容/FAB速拨/整段页面级组件/富格式 cb），FAB 中性化为单动作、抽屉留壳，`tokens.css` 去 `--font-diary`/`--favorite` 并去品牌。
  - 通用机制（按钮/输入/开关/分段/标签/toast/dialog/sheet/抽屉壳/FAB壳）保留；示例屏 home/detail 本就中性、未动。spec.css 856→509 行，check-tokens burn-down 9 处。
  - CLAUDE/CHANGELOG 模板 + ARCH 同步去 DayZ；newest-first 与 `docs/handoff/` 生命周期约定回灌 kit 文档体系。
- [媒体] **大图查看器 `DZ.lightbox`（定档）**：全屏沉浸看图，横向 scroll-snap 翻页 + 顶部 `N/总数` 计数，暖近黑 `--media-*`（明暗/主题一致）。`data-lightbox` 容器自动成组，已接阅读页封面 + 九宫格；卡片封面图不接（整卡进详情）。
  - 新增 `assets/lightbox.js` + spec.css `.lbx`；Flutter 映射 `photo_view` PhotoViewGallery。
- [媒体] **微信式全屏图片选择器 `DZ.picker`（定档）**：顶栏（取消/相册名 ▾）+ 4 列网格（首格相机）+ 底栏（预览/原图/完成(N)），多选带顺序编号徽标，编号/完成走主题 accent。替掉编辑器旧的相册/拍照 sheet。
  - 新增 `assets/picker.js` + spec.css `.pk`；选择按格身份去重（非 src，避免原型复用图误连选）；Flutter 映射 `wechat_assets_picker`。
- [设计规范] 新增 `--media-*` token（媒体层底/面/文字/描边/遮罩），登记 DESIGN-REF Token 速查 + 组件目录（`.lbx`/`.pk`）。
- [编辑器] `handoff/editor.md` §5 漂移 #5 从🟡升级为🟢已定档：图片插入 = 全屏选择器 + 大图查看器，含原生 `wechat_assets_picker`/`photo_view` 落地映射与验收项。
- [编辑器] **富格式 demo 补全为 AppFlowy 全能力集（定档）**：编辑页 `rich` 状态原只画了 H2/粗/待办/引用，现补齐 H1–H3 · 斜/下划线/删除线/行内代码 · 文字色/高亮 · 有序·无序列表 · 代码块 · 链接 · 分隔线 · 图片——作画布样式真源、消除还原偏差。
  - 文字色/高亮由 editor.js 从工具栏同一套色板注入（`[data-fc]`/`[data-hl]`），单一真源不漂；新增 `.cb-code`/`.cb-codeblock`/`.cb-link`/`.cb-hr`/`.cb-img` 等 demo 块（screen.css，token 化），登记 DESIGN-REF §3c。
- [文档] **新建 `docs/handoff/` 走查任务单目录 + 生命周期约定（定档）**：原 `EDITOR-HANDOFF.md` → `docs/handoff/editor.md`（按走查的代码区命名）；加 `README.md` 定义「待走查→验收通过→归档 `_archive/`」流程 + 状态栏；CLAUDE.md 文档清单同步。

## 2026-06-03
- [工具] **新增两个机读 guard（定档）**：把 DoD 表里靠自觉的两条纪律变成可机检守卫（read_file → run_script 执行，只用沙箱 helper）。
  - `tools/check-tokens.js`：自动遍历 `design-system/`/`pages/`/`prototype-kit/` + 根 `index.html`，抓裸 hex / 裸 rgba / 假 fallback；跳过 `tokens.css` 与 `img/`；带 baseline 只报增量。首版 `check-tokens.baseline.json` 接受 156 处现状（设备 chrome / 文档色板 / 种子数据属合理保留，产品 CSS 蒙层散值待 burn-down）。
  - `tools/check-changelog.js`：纯只读扫本文件——重复同日段=FAIL、超 200 行=warn、条目超 3 子 bullet=warn。
- [文档] DoD 表的「颜色相关」「改 CHANGELOG」两行接上对应 guard，并补「机读 guard」小节说明运行方式与 baseline 哲学。
- [编辑器] **二级菜单从「只 toggle」补全为「键盘位内联面板」（定档）**：原型 `editor.html` 点 H/颜色/链接 → 面板从工具栏下方升起（贴合 AppFlowy `MobileToolbarV2`，非底部 sheet），图片走相册/拍照来源 sheet。新增屏内真源 `pages/assets/editor.{css,js}`、登记 DESIGN-REF §3c。
  - 色板 `TEXT_COLORS`/`HL_COLORS`（暖调 6+5）为编辑器文字色/高亮真源；标题面板比 AppFlowy 多显式「正文」项。
- [文档] **新增编辑页 handoff + 走查原生编辑页（定档）**：比对 `lib/ui/editor/*` 与设计，列 5 处漂移（🔴默认 Material 色板 · 🟠meta chip 用 Material Icons · 🟡日期/关闭 Material Icons · 🟡标题缺正文项 · 🟡图片无来源选择）+ 改法 + 色板 hex 表 + 验收清单。

## 2026-05-31
- [侧边栏] **切换日记本不再在顶栏展示本名（定档）**：抽屉选中某本日记本后，顶栏搜索框左侧不再写入该日记本名称（原"全部日记留空、其余显示本名"）；仅保留列表刷新（滚顶 + `tl-refreshing` 淡入）与 `dayz:journalchange` 派发。`screen.js` 去掉对 `.app-top .title` 的赋值。
- [原型套件] **沉淀工作纪律到 kit（定档）**：把通用纪律回灌 `prototype-kit/`（不抄业务/不抄 guard 脚本，只回灌纪律）。
  - `CLAUDE.template.md` 新增「工作纪律」（先 grep 再写 / 按需披露 / 别自造清单）与「收尾同步表（DoD）」，把原散落的 Changelog/DESIGN-REF 维护合并为一张「改了 X → 必做 Y」表。
  - `CHANGELOG.template.md` 补卫生三条：同日合并（grep 后 append）/ 深度上限（≤3 子 bullet）/ 滚动归档（~200 行）。
- [按钮] **修文本贴左 + 接通禁用态（定档）**：基础 `.btn` 补 `justify-content:center`——此前仅 `inline-flex; align-items:center`，在 `.sheet-foot` 纵列里被拉满整宽时文字靠左（创建按钮即此症）；三份 `spec.css` 同步。
  - 顺手接通本就存在却未被触发的 `.btn[disabled]`：新建日记本「创建」默认禁用，名称非空才解锁（去掉空名兜底"新日记本"）。
  - memory.html 私补的 `justify-content:center` 同步撤除（`.mem-actions .btn` 只留 `flex:1`）——基础类已覆盖，留着即"私补未撤"的腐化苗头。
  - 沉淀两条纪律进 `CLAUDE.md` DoD 表：① 局部私补基础组件样式 = 基础类有洞的信号，优先补基础类；② spec 定义却无真实用例触发的变体（如 disabled）必腐化，须接一处用例。
- [文档] **根 `CLAUDE.md` 收尾约定收敛为 DoD 表（定档）**：新增「收尾同步表（`done` 前逐行过）」把 token/组件/屏/颜色/kit反哺/定档六类同步义务并成一张「改了 X → 必做 Y」表；Changelog 维护补同日合并 + 深度上限 + 滚动归档三条卫生。原维护小节保留作「为什么」细节。

## 2026-05-30
- [图标] **App 图标导出（定档）**：基于已定方案 **B · 暖纸底 · 雾紫 Lavender**（暖纸渐变 + `#786CAD` 描边书签本），输出 iOS / Android 全套启动图标到独立目录 `app-icons/exports/`。iOS `AppIcon.appiconset`（含 `Contents.json`，覆盖 iPhone/iPad/1024 满版方形）；Android 自适应图标（`mipmap-anydpi-v26` + 各密度 fg/bg/legacy/round）+ Play 512；附 `Icon Export Preview.html` 明暗 + 遮罩预览与 `README.md` 落地说明。所有尺寸由同一矢量光栅化，未二次缩放。

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
- [相册] **多图日记九宫格 `.gallery`（定档）**：补上此前缺失的多图展示——克制版朋友圈网格，列数随张数变（2→2列 / 3→3列 / 4→2×2 田字 / ≥5→3列 / 1→单张大图）；超 9 张在第 9 格盖「+N」蒙层**收起**（`.ph.more[data-more]`），阅读页点它 `.expanded` 展开全部（`screen.js`），信息流卡片里点图因外层 `data-nav` 先行进阅读页。单张封面仍用 `.entry .photo`，多图才用 `.gallery`。落地 timeline（旧书店 4 图 / 梅子 9+ 收起）+ reader（梅子正文后相册 + 展开）+ 设计规范文档 demo（2/4/9+ 三例）。真源 spec.css（已同步 pages/assets），DESIGN-REF §3 登记。对应 Flutter `GridView.count`（crossAxisCount 由张数定）+ 末格 Stack 叠 +N。
- [提示条] **全局 toast 系统（定档）**：填完「只有静态样例」的坑。提示条底部居中浮现、自动消失、可堆叠（容器 `.toast-host`，最多 3 条，浮在 FAB 之上）。底色保持中性（深色款 / `.surface` 表面款），**语义只靠图标点色**（成功/信息=主题色・`.danger`=`--danger`・`.fav`=`--favorite`）克制不喧哗；可带一个操作 `.acc`（撤销/查看/重试）。新增零依赖引擎 `assets/toast.js`（`DZ.toast()`，可传 tone/variant/action/onAction/duration/host），就近挂载 `[data-toast-host]`→`.screen`→`body`。设计规范文档静态示例改为**可交互 demo**（六按钮触发真实 toast + 浮现舞台）。真源 spec.css + toast.js（均已同步 pages/assets），DESIGN-REF §3 登记。踩坑：进场动画**不用 rAF**（节流态不触发）——append 后强制回流再加 `.in`。对应 Flutter `ScaffoldMessenger.showSnackBar(floating)` + `SnackBarAction`，FAB 由 Scaffold 自动让位。
- [背景/纸色] **背景纸色系统 `data-bg`（定档）**：在中性暖纸之外再给几套背景“纸色”——**纯净 / 暖纸 / 主题微染 / 深褐 Sepia / 自定义**，每套含浅深两版。只覆盖背景相关中性色（`--bg/--bg-2/--surface/--surface-2/--hairline*`，Sepia 另微调 `--ink*`），强调色与排版不动。**主题微染 / 自定义用 `color-mix` 从 `--accent` / `--paper-seed` 派生**，自动随 theme + mode 联动；自定义由色相滑块生成种子色。新增轴 `data-bg`（tokens.css，已同步 pages/assets）+ 设计规范文档 §02 「背景·纸色」可切换区（`.paper-btn` + `#paperHue`，全局即时生效）；spec.js 持久化 `bg/paperSeed`。DESIGN-REF §1/§2.5 登记。对应 Flutter：`paper` 枚举 + 可空 `paperSeed`，低比例混入背景族（ThemeExtension）。作用范围暂为全局（每本日记本独立纸色待定，记入 BACKLOG）。
- [设计规范] **「设计语言」章节（定档）**：在设计规范文档顶部（hero 之后、§01 之前）新增 §00「设计语言」——把一直在说的「为什么」沉淀为 8 条信念原则卡：温润·安静 / 少即是多 / 纸与墨 / 语义用最小手段 / 中文优先 / 一套 token·单一真源 / Flutter 优先 / 移动优先。供新设计拿不准时回来对照。文档专属样式 `.principle-grid`/`.principle`（不入跨端 spec.css）。
- [背景/纸色] **纸色切换器搬到顶栏**：原只在 §02 中性色里（不好找），现在顶栏「主题色 ▏纸」并排放 4 个迷你色片（纯净/暖纸/主题微染/深褐），sticky 常驻、滚到任意区块都能随手切换实时预览；与 §02 的卡片式切换器共用 `.paper-btn` + spec.js，状态同步。
- [设计规范/侧边栏] **§07 抽屉对齐真实屏（修腐化）**：设计规范文档的抽屉 demo 此前是旧版（带抽屉内搜索、媒体/地图/标签、回收站+设置都在底部），与真实页面 `pages/screens/timeline.html` 漂移。现同步为真实结构：去掉 `.dw-search`（搜索统一走顶栏）、日记本组置顶（全部日记 + 各本色点）、回收站并入「浏览」组、底部仅留设置、图标换成现行版本、账户改「林晚 · 本地·已加密」。DESIGN-REF §4 抽屉条目同步修正（删除已废的 `.dw-search` 与「回收站 static」说法）。
- [设计规范] **§06/§07 改为「直接嵌入真实页面」（定档）**：手抄的设备 mock 反复与真实屏漂移（抽屉过期、标题不符等），治本之道——§06 IN CONTEXT / §07 SIDEBAR 改为 `<iframe class="screen-embed">` 嵌 `pages/screens/timeline.html`（§07 用 `?state=drawer` 直接展开抽屉）。文档随顶栏**主题 / 明暗 / 纸色实时同步**到 iframe（监听屏的 `ready` 回发 + MutationObserver 下发；screen.js 的 theme 消息扩展为携带 `bg/paperSeed`）。从此设计规范永远显示当前真实 UI，这类不一致一次性消除；顶部标题也不再需要单独对齐。
- [设计规范] **§01 三套主题色固定行修复**：固定行原用 `<div data-theme>` 探针读色，但强调色选择器锁 `:root`，普通元素不匹配 → 三行都读成当前激活主题色（全同色）。改为「临时切根元素 `data-theme` 同步读值再还原」（`withTheme()`，渲染期间断开 MutationObserver 防递归）；并把 `data-bg` 纳入观察，切纸色时中性色板同步刷新。
- [底部操作/侧边栏] **FAB 遮罩修复（定档）**：`.fab-scrim` 原放在 `.fab-wrap` 内，`inset:0` 只覆盖 58px 按钮盒、且 z(6) 高于按钮(2) → 展开时 `backdrop-filter:blur` 正好把按钮糊掉，且全屏压暗从未生效。改为把 `.fab-scrim` 移出、作为 `.fab-wrap` 的后继兄弟（同在 `.pg` 下）→ `inset:0` 覆盖整屏做压暗+模糊、z(6) 低于 `.fab-wrap`(7) 让按钮与动作清晰浮起；开态选择器改 `.fab-wrap.open ~ .fab-scrim`；`screen.js` 改 `document.querySelector('.fab-scrim')` 绑定关闭。timeline.html + spec.css + screen.js（pages，已同步）同改；DESIGN-REF §4 FAB 条目同步。对应 Flutter speed-dial 的 `ModalBarrier` 全屏遮罩。
- [背景/纸色] **纸色清单定档（去捆绑 + 改用耐读纸）**：先后试过「主题微染（统一轻染）」「主题配套 paired（每主题配色纸）」与「点主题色联动换纸」，评估**同色系发闷、捆绑不自由**，**回退**：去掉 `warm`/`paired`/`sepia`，新增 3 张浅淡耐读纸 `mint` 浅绿（豆绿护眼）/ `mist` 雾蓝（低眩光）/ `cloud` 云灰（中性沉静）；保留 `pure` 纯净、`tinted` 主题微染、`custom` 自定义。主题色与纸**各管各的**（点主题只切主题）。每套都让 `surface` 比 `bg` 亮一档，卡片/文字浮起、突出主体。顶栏迷你色片 = 纯净/浅绿/雾蓝/云灰；§02 列全集。tokens.css 已同步 pages/assets，DESIGN-REF §1/§2.5 同步。
- [设计规范] **顶栏色块悬浮名牌**：主题色与纸色小色块 hover 即时弹出名字（`data-tip` + `::before`；注意主题色块 `::after` 已被内圈环占用，故用 `::before`，否则文字被圆形裁剪「显示不全」）。
- [设计规范] **顶栏切换后自动跳 §06**：点顶栏主题色 / 明暗 / 纸色后，平滑滚到 §06 IN CONTEXT（嵌入的真实手机屏）看效果（`spec.js` `jumpToContext`）；§02 内的纸色卡不跳。
- [设计规范] **§00 设计语言精简为「只谈气质」**：把偏规范/技术的条目移出——撤掉「Flutter 优先 / 一套 token·单一真源 / 移动优先」（落到 CLAUDE / DESIGN-REF / PROTOTYPE-ARCH）；保留 5 条纯设计语言：温润·安静 / 少即是多 / 纸与墨 / 用最轻的方式表达 / 中文优先。文案去技术黑话（token、`var(--*)`、FAB、CJK、44px），改为面向一般人的设计化白话。
- [文档] **新增展示用 `README.md`（根目录）+ `docs/screenshots/`**：README 顶部放 6 张代表性界面图（时间线九宫格 / 阅读 / 编辑 / 往年今日 / 设置 / 深色），含设计基调、特性、仓库导览；`docs/screenshots/README.md` 给出**重生成指南 + 截图踩坑**（直抓屏勿套 iframe、预览不跑过渡需禁用后再截、滚动被钉首屏）。设计改动后须更新这些图。
- [原型套件] **本轮通用踩坑回灌 kit「易踩的坑」**：① 离屏预览冻结 CSS 过渡 / rAF（进场用强制回流非 rAF；验证动画态用「禁用过渡读最终值」非截图）；② `html-to-image` 截不到 iframe（直抓屏）；③ 一元素仅一个 `::before`/`::after`，加 tooltip 前查占用；④ `:root[data-theme]` 只匹配根元素，读他主题 token 要临时切根元素再还原（断 observer 防递归）；⑤ 全屏遮罩须作触发元素后继兄弟而非塞进小容器；⑥ 展示处用 iframe 嵌真实屏防漂移。纸色等业务内容不回灌。
- [原型套件] **FAB 遮罩修复回灌 kit**：此为业务无关的通用外壳 bug，已同步修进 `prototype-kit/assets/spec.css`（`.fab-wrap.open ~ .fab-scrim` + 注释说明 scrim 须作 fab-wrap 后继兄弟）与 `screen.js`（`document.querySelector('.fab-scrim')` 绑定关闭）。纸色 `data-bg` 属 DayZ 业务，不回灌 kit。
- [弹层] **底部弹层 sheet 系统（定档）**：新增业务无关零依赖引擎 `assets/sheet.js`（`DZ.sheet()`），从底部滑入、scrim 点击关闭、圆角顶 + 拖拽柄 + SafeArea 底部留白。一套支持三形态：**动作菜单**（`items[]`，支持 icon / 色点 swatch / `tone:'danger'` / 分隔 `sep` / `desc` 次级行）、**单选选择器**（`selected` 命中项右侧打勾）、**轻表单**（`content` 自定义节点 + `primary/secondary` 按钮）。样式入 `spec.css`（跨端组件，z 48/49 浮于抽屉与 chrome 之上），已同步 pages/assets；DESIGN-REF §3 登记。踩坑同 toast：进场强制回流再加 `.in`（不用 rAF）。对应 Flutter `showModalBottomSheet`。
- [阅读页] **收藏 toggle + ⋯ 更多菜单（定档）**：顶栏星标由静态金星改为**可点 toggle**（实心金 ⇆ 空心线，`data-fav-toggle`，`screen.js` 通用绘制 + toast）；⋯ 接通**条目动作菜单**（`data-entry-menu`）—— 编辑（跳编辑页）/ 分享 / 移到日记本（唤起日记本单选选择器）/ 收藏·取消收藏（与顶栏星双向同步）/ 删除。菜单项文案与图标集中在 `screen.js`，供阅读页 / 往年今日复用。
- [阅读页/侧边栏] **删除 = 移到回收站（定档）**：删除走二次确认 sheet（危险红「移到回收站」+ 取消），确认后 toast「已移到回收站」带**撤销**（撤销 → toast「已恢复」），随后返回时间线。与新建的回收站屏闭环。
- [往年今日] **⋯ → 生成回忆卡片（定档）**：顶栏 ⋯ 接通菜单 —— 生成回忆卡片（跳回忆卡片屏）/ 分享这一天。填上 BACKLOG「生成回忆卡片图」入口。
- [页面] **新屏 · 回忆卡片 `memory.html`（定档）**：把一条回忆渲染成可分享卡片图的**预览屏**。画幅可切（竖版 9:16 / 方形 1:1）、风格可切（纸感：暖纸+衬线 / 大图压字：满幅照片+底部渐隐压字），卡片含日期+第几年前、标题、摘录、地点、DayZ 字标；底部「保存到相册 / 分享」（原型以 toast 模拟，落地走 `RepaintBoundary.toImage()` → `share_plus`/存相册）。屏内专属样式 + 逻辑内联（一次性，不入 spec）。
- [设置] **主题色 + 外观模式选择器（定档）**：两行接通底部选择器 sheet —— 主题色（雾紫 / 暖黄 / 雾绿，色点 + 打勾）、外观模式（**浅色 / 深色 / 跟随系统**三选一）。选择经 `postMessage({type:'settheme'|'setmode'})` 上抛外壳 `app.js` 即时换肤（跟随系统用 `matchMedia(prefers-color-scheme)`）；对应 Flutter 改 `ThemeData` 全树 rebuild。
- [侧边栏] **新建日记本流程（定档）**：抽屉「＋」接通新建表单 sheet —— 命名输入 + 选色（六色板，三主题色 + 三扩展色，打勾选中）+「创建」；确认后即时把新日记本（色点 + 名 + 计数 0）插入抽屉日记本组并 toast。屏内表单选色样式 `.nj-*`（screen.css）。
- [页面] **新屏 · 收藏 `favorites.html`（定档）**：从抽屉「收藏」进入，过滤出收藏条目（复用时间线卡片 + 金星），含计数头与空状态。
- [页面] **新屏 · 回收站 `trash.html`（定档）**：从抽屉「回收站」进入。30 天自动清除提示条 + 软删条目卡（标题/摘录/「删除于…·N 天后清除」），每条**恢复 / 彻底删除**（彻底删走二次确认）；顶栏「清空」（二次确认）；删空切空状态。屏内专属样式 `.trash-*` + 逻辑内联。
- [页面] **新屏 · 日历 `calendar.html`（定档）**：从抽屉「日历」进入。全屏月视图（周一起始、有条目日 accent 圆点、今日环、选中日实底），月份 ‹ › 导航 + 顶栏「回到今天」；下方列出选中日的条目（点进阅读页）。5 月真实数据，其余月份按种子生成示意。屏内专属样式 `.cm-*` + 逻辑内联。
- [页面] **外壳注册 4 新屏 + 抽屉接通导航**：`app.js` `SCREENS[]` 增 回忆卡片 / 收藏 / 日历 / 回收站；抽屉「收藏 / 日历 / 回收站」补 `data-nav`（此前仅选中+关抽屉，背后无屏）。各新屏均引入 `toast.js` + `sheet.js`。
- [架构] **PROTOTYPE-ARCH 同步**：§4 postMessage 协议增 `settheme` / `setmode`（屏→外壳，对应 Flutter 改 ThemeData）；§6 Flutter 映射增「底部弹层 → `showModalBottomSheet`」「回忆卡片导出 → `RepaintBoundary.toImage()`+`share_plus`」。
- [原型套件] **底部弹层 sheet 回灌 kit**：`DZ.sheet` 引擎与样式业务无关，已同步进 `prototype-kit/assets/sheet.js` + `spec.css`，并在示例屏 detail 接一个 ⋯ 动作菜单演示；README 组件清单补一条。DayZ 的菜单文案/新建日记本/回忆卡片属业务，不回灌。
- [弹层/原型套件] **`DZ.confirm()` 便捷封装 + settheme/setmode 外壳协议回灌**：① 给 sheet 引擎加 `DZ.confirm({title,desc,confirmLabel,icon,danger,onConfirm})`——"确认再执行"是最高频特化，DayZ 删除/彻底删/清空回收站改用它；同步进 kit。② 把"设置屏请求换肤"的 `settheme`/`setmode`（含`跟随系统`→`matchMedia`）从 DayZ `app.js` 回灌到 `prototype-kit/assets/app.js`——纯外壳机制，任何带设置页的原型可用；kit PROTOTYPE-ARCH §4/§6 同步。
- [页面] **回忆卡片改版（定档）**：① 修底栏溢出——画幅/风格选择器 + 保存/分享改为**固定底栏**（始终可见，卡片更高时上方预览区滚动），修掉「`.btn` 内 SVG 无尺寸约束被撑爆」。② 新增**长图**画幅——把往年今日"这一天"的多段回忆（含年份分隔 + 配图 + 摘录）竖排成一张可分享长图（纸感款，长图固定纸感、风格行置灰）；满足"往年今日分享一个长图"。画幅三选：竖版 9:16 / 方形 1:1 / 长图。
