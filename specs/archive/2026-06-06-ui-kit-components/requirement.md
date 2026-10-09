---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# ui-kit-components（通用组件层）

## 背景

UI 还原三层（token → 组件 → 屏）的**中间层**：在 `design-tokens-theme` 浇好的视觉底座之上，把 [`DESIGN-REF.md`](../../../ui-design/current/docs/DESIGN-REF.md) §3 / §3b / §4 登记过的**可复用 widget** 与**跨屏共用外壳**实现成一组稳定、命名清晰的 Flutter 组件，供后续每个页面级 spec 直接引用（见 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §1 分层、§9 拆分波次 W1）。

为什么必须先于页面：若各屏各写一份按钮/卡片/顶栏，颜色字号会被硬编码散进各屏 × 六套主题（踩「一律走 token、不在屏里硬编码」红线），且毛玻璃顶栏、toast、底部 sheet 这类跨屏外壳会重复实现、互相漂移。本 spec 把这些**落一次、各屏共享**，并补一个 **widgetbook 多状态画廊**覆盖「组件 × 主题 × 状态」矩阵——Debug Home 的单列表只能逐 demo 进入，覆盖不了这种二维矩阵的快速目检。

**准入门槛（硬约束）**：只实现 `DESIGN-REF.md §3 / §3b / §4` 已登记（有类名 + 最小 HTML）的组件，不凭空造 widget；**有多少组件、叫什么、几个变体，一律以 DESIGN-REF 当前内容为准**，本 spec 不写死个数（设计稿是移动靶，枚举会腐化）。组件的命名与 API 边界一旦在此定稿，即成 10 个页面级 spec 的公共契约，求**稳定**。

## 范围外

- **屏幕级页面实现**（时间线/阅读/编辑/往年今日/搜索/设置等整屏）—— 各页面级 spec；本 spec 只交付它们拼装用的零件与外壳。
- **路由 / 抽屉实体内容 / FAB 接真实创建动作 / 取代 `DebugHome` 的真外壳** —— 归 `ui-shell-navigation`。本 spec 的 `DayzGlassAppBar`、底部 sheet、FAB 视觉外形是**无状态/无路由的纯展示与回调**组件，MUST NOT 在本 spec 内接 `go_router` / Navigator / 抽屉导航树 / 真实数据写入。
- **取数与持久化** —— 组件 MUST NOT 直接读写数据；只接受入参与回调（见 NF4）。真实数据装配归页面级 spec，经 `data-layer` 的 Repository。
- **token 数值、主题、字体、`AppLocalizations` 基础设施的"建立"** —— 归 `design-tokens-theme` / `i18n-localization`（本 spec 是其消费者）。本 spec 只补组件层用到的 zh/en ARB 文案 key，并通过 `AppLocalizations.of(context)` 使用；不得新增或追加静态文案常量桶。
- **参数对齐 / 布局几何抽取 harness、SSIM 兜底、`element-map.yaml`** —— 归 `design-sync-automation`（跨 spec 依赖）；本 spec 的几何/样式断言用 Flutter 原生 `tester.getRect` / 解析 widget 属性，不重造 harness。
- **AppFlowy 编辑器内核与富文本块渲染** —— `.toolbar` 组件只做按钮条的**视觉外壳 + 激活态 + 回调**，能力对接（粗体/列表/引用等真实 editor 命令）归编辑器集成的页面级 spec 与 `editor-json-contract`。
- **真实照片来源（相册/相机）** —— 九宫格 `.gallery` 组件只接受 `ImageProvider` 列表 + 回调，相册链路归 media-picker 页面级 spec。

## 功能需求

### R1 · DESIGN-REF §3 基础组件成套实现
系统 SHALL 实现 `DESIGN-REF.md §3` 登记的全部基础可复用组件（按钮 `.btn` 全变体/尺寸/图标钮/禁用、输入 `.field`+`.input`+`.textarea`、开关 `.switch`、勾选/单选 `.opt`、分段 `.segmented`、标签 `.tag`、心情 `.mood`、天气 `.weather-chip`、工具栏 `.toolbar`、提示条 `.toast` 结构、弹窗 `.dialog`、时间线卡片 `.entry`、相册九宫格 `.gallery`），每个组件的视觉一律取自 token。
- 前提：在挂了任一套 DayZ 主题（`design-tokens-theme` 六套之一）的 widget 树内。
- 操作：实例化某组件并渲染。
- 结果：该组件解析后的样式参数（颜色/圆角/内边距/字号/阴影）等于 DESIGN-REF 对应类名在该主题下的设计值（均经 `context.dayz.*` / `DayzSpacing` / `DayzRadii` 等 token，非硬编码）；其变体（如 `.btn-primary`/`.btn-soft`/`.btn-ghost`/`.btn-text`/`.btn-danger`、`.tag`/`.tag-outline`、`.opt .box`/`.opt .dot`）各自呈现对应外观。

> 组件清单、变体名、心情脸数量等以 DESIGN-REF §3 当前内容为准，本需求不固化个数；新增/删改由 `design-sync-automation` 三档分流增量驱动。

### R2 · DESIGN-REF §3b 页面级复用组件实现
系统 SHALL 实现 `DESIGN-REF.md §3b` 登记的跨端页面级复用组件（时间线年月吸顶头 `.tl-month`、往年今日年份分隔 `.year-sep`、设置分组列表 `.set-*` 行/分组/头卡、搜索头 `.search-head` 的可复用部分等），作为页面级 spec 拼装单元。
- 前提：在挂了主题的 widget 树内。
- 操作：以入参（如月份文案、篇数、是否展开）实例化组件。
- 结果：渲染结构与样式参数符合 DESIGN-REF §3b 对应类名设计值；文案经 `AppLocalizations`/`intl`，无裸中文与裸日期拼接。

> §3b 真源是 `spec.css`；§3c 屏内专属（`.cal-*`/`.empty`/`.suggest-row`/`.topsearch`/`.nj-*` 等）多数随对应页面级 spec 落地。本 spec **纳入** §3c 中明确"跨屏复用"的件——空状态 `.empty`（多屏共用的兜底插画态）；其余屏内一次性件留给对应屏 spec。空状态归属点见 design D7。

### R3 · 跨屏共用外壳：毛玻璃顶栏（含降级）
系统 SHALL 提供 `DayzGlassAppBar`（对应 §3c 覆盖式固定头 + §4 顶栏），静止为干净实底、滚动后毛玻璃浮起覆盖状态栏 + 0.5px 底分割。
- 前提：放入一个可滚动页面，初始未滚动。
- 操作：内容向上滚动越过顶栏阈值。
- 结果：顶栏从实底（`--bg`）切换为半透 `--bg` 80% + `blur(20px)` 的毛玻璃态（`BackdropFilter`），并显 0.5px 底分割线；颜色/模糊半径取自 token / design 标定值。

### NF（降级）见 NF5——`saturate` 在 Flutter 无原生等价，须有确定性降级。

### R4 · 跨屏共用外壳：全局 toast
系统 SHALL 提供全局 toast 能力（对应 §3「全局 toast 系统」），底部居中浮现、自动消失、可堆叠（上限 3）、底色中性、语义只靠图标点色（默认/成功/信息=主题色、danger=`--danger`、fav=`--favorite`），可带一个操作按钮。
- 前提：任意已挂 `ScaffoldMessenger`（或等价 host）的页面。
- 操作：调用 toast API（如 `DayzToast.show(context, ...)`）传文案 + tone + 可选 action。
- 结果：浮现一条 toast，tone 决定图标点色而非整条底色；有 action 时停留更久（与设计 4.2s / 2.6s 对齐量级）并暴露 action 回调；超过 3 条时最旧者退场。

### R5 · 跨屏共用外壳:底部 sheet(动作菜单/选择器/轻表单/确认)
系统 SHALL 提供统一底部弹层组件(对应 §3「底部弹层 `.sheet`」一套引擎覆盖的形态),覆盖动作菜单、单选选择器、轻表单、删除/危险二次确认四种形态,从底部滑入、scrim 点击关闭、圆角顶 + 拖拽柄 + 底部留白。
- 前提:任意页面,有可触发动作。
- 操作:调用 sheet API(如 `DayzSheet.actions(...)` / `.picker(...)` / `.form(...)` / `.confirm(...)`)。
- 结果:从底部滑入对应形态;动作菜单逐项 `label/icon/tone` + 默认「取消」行;单选项命中右侧打勾;表单含 `primary`(可加 `secondary`)按钮;确认形态含危险动作 `tone: danger` 与取消;scrim 点击或返回手势关闭。

### R6 · 跨屏共用外壳：FAB 速拨视觉外形
系统 SHALL 提供 FAB 速拨组件的视觉外形（对应 §4 `.fab-wrap`）：轻点回调 + 长按展开二级动作（拍照/语音/纯文字等由入参给定）、全屏 scrim 背景压暗、立体渐变 + 多层投影 + 顶高光（Flutter 用 `BoxDecoration(gradient + boxShadow[])`，无 inset 阴影，顶高光用顶部浅渐变或 0.5px 白半透边）。
- 前提：页面右下放置 FAB。
- 操作：轻点 / 长按。
- 结果：轻点触发 `onTap` 回调；长按 ~0.35s 展开 `.fab-actions` 二级动作 + 全屏 scrim（压暗，FAB 与动作浮于其上、保持清晰），点 scrim 收起；每个二级动作显 `data-label` 文案并暴露各自回调。

> 本组件只提供外形与回调；轻点真的"写日记"、长按动作真的"拍照"由 `ui-shell-navigation` / 各屏接线（范围外）。

### R7 · widgetbook 多状态画廊
系统 SHALL 提供一个 widgetbook 画廊，把本组件层的组件按「组件 × 主题(6 套) × 关键状态」矩阵编目展示，作为 Debug Home 单列表覆盖不了的二维矩阵目检入口。
- 前提：进入画廊（经 Debug Home 入口或独立 demo）。
- 操作：切换主题/明暗轴、选择组件、切换该组件的状态（如按钮 default/hover-pressed/disabled、opt on/off、entry 单图/九宫格/空摘要）。
- 结果：所选组件在所选主题与状态下即时渲染；切换轴不需重启；每个组件至少编目其 DESIGN-REF 登记的全部变体与关键状态。

### R8 · 收藏星等规范图标走规范 path
系统 SHALL 用 `DESIGN-REF.md §5` 规定的**唯一规范 path** 渲染收藏星（外半径 9.5/内半径 4.2、顶点正上的对称五角星，填充/描边只换 fill/stroke），及其它 §5 约定的内联 SVG 图标（`viewBox 0 0 24 24`、`stroke=currentColor`、`stroke-width 2`、单色继承父级文字色），经 `flutter_svg`。
- 前提：渲染收藏星（已收藏 / 未收藏）。
- 操作：取收藏星组件并切换收藏态。
- 结果：已收藏 = 填充 `--favorite` 暖金、未收藏 = 描边 `currentColor`，二者 path 完全一致（不另画导致歪斜）；图标颜色随父级文字色/主题，无写死色。

### R9 · 大图查看器：全屏沉浸式可左右滑动看图（DZ.lightbox）
系统 SHALL 提供一个业务无关、零数据接入的全屏大图查看器组件 `DayzImageViewer`（DESIGN-REF §3c「大图查看器 `.lbx`」/ handoff `editor.md §5(b)`），把一组图片在覆盖整个视口的沉浸式媒体层上铺满呈现，横向滑动翻页。组件只接 `ImageProvider` 列表 + `initialIndex` + 可选 caption + 关闭回调，不知道图片从哪来、不触发任何相册 / 解密 / 缩略图链路（取数与解密由页面级 spec 在打开它之前完成，NF5）。
- 前提：给定一组 `ImageProvider`（≥1 张）与起始下标 `initialIndex`。
- 操作：打开查看器；横向滑动翻页；点空白区域 / 关闭钮退出；点图片本身不退出。
- 结果：
  - 打开即停在 `initialIndex` 对应那张（`PageController(initialPage: initialIndex)`）。
  - **多张时**顶部显示 `N / 总数` 计数（如 `3 / 11`），随翻页更新当前页号；**单张时不显示**计数。
  - 背景为暖近黑沉浸层（`--media-*`，明暗 / 主题一致），左上角关闭钮，可选底部 caption。
  - 点空白退出（触发关闭回调）；点图片本身不退出（便于细看）。
  - 不 import `lib/data/`、不调相册 / 缩略图 / 解密入口（NF5）。

## 非功能需求

### NF1 · 无障碍：点击目标 ≥ 44px
所有可交互组件（按钮/图标钮/开关/勾选/分段/标签删除叉/sheet item/FAB/star 切换）的**有效点击命中区** MUST ≥ 44×44 逻辑像素（DESIGN-REF §4 可达性、方法论 §11）。视觉尺寸可小于 44，但命中区（含透明 padding / `MaterialTapTargetSize` / `Semantics` 命中盒）须达标。

### NF2 · 无障碍：对比度 ≥ WCAG AA
组件在六套主题下，其承载的文本/有意义 UI 对比度遵循 `design-tokens-theme` NF1 的分族口径（正文/着色文字/实色底文字 ≥ 4.5:1；聚焦/选中边/选中图标 ≥ 3.0:1）。本 spec **不重算** token 对比度（那是 tokens-theme 的 contrast_test 职责），但 MUST NOT 因组件层用错 token（如正文误用 `--ink-3`、把着色文字放到非 soft 底）而引入新的不达标渲染对——以组件级断言核验"用对了 token 语义"。

### NF3 · 无障碍：Semantics 标签
所有图标钮、无文字或仅图标的可交互件、开关、收藏星 MUST 提供 `Semantics` 语义标签（文案经 `AppLocalizations`），可被 `find.bySemanticsLabel` 定位、被屏幕阅读器朗读；纯装饰图标 MUST 标 `excludeSemantics` / `ExcludeSemantics` 不污染语义树。

### NF4 · 无障碍：尊重系统减弱动态效果（reduce-motion）
组件的进出场/展开动效（toast 进出、sheet 滑入、FAB 展开、顶栏过渡）MUST 在系统开启「减弱动态效果」（`MediaQuery.disableAnimations == true` / `MediaQuery.accessibleNavigation`）时降级为无动效或近瞬时切换，MUST NOT 强制播放位移/缩放动画。

### NF5 · Repository 边界（硬红线）
组件层 MUST NOT 直接持有 Drift 句柄、写 SQL/Drift、或调用 `data-layer` Repository；组件只接受入参（数据模型 / 基本类型 / `ImageProvider`）与回调（`VoidCallback` / `ValueChanged`）。取数与写入由页面级 spec 经 `JournalRepo/EntryRepo/MediaRepo/TagRepo/EditingSessionRepo` 完成。本 spec 在 verification 留一项静态/结构核验，确保组件层无任何 `data`/`drift` import。

### NF6 · 多端兼容
组件 SHALL 在 iOS 13+ 与 Android 8+(minSdk 26) 上正常渲染：`BackdropFilter` 毛玻璃、多层 `boxShadow`、`flutter_svg` 收藏星、CJK 字体回退在两端均可接受（`saturate` 降级见 NF5 关联 R3）。

### NF7 · `saturate` 玻璃效果降级
`DayzGlassAppBar` 的毛玻璃在设计稿用 `saturate(1.5) blur(20px)`，而 Flutter `BackdropFilter` 无原生 `saturate`。系统 SHALL 采用确定性降级：以 `ImageFilter.blur` + 半透 `--bg` 叠色近似，不追像素级等价（PROTOTYPE-ARCH §6 顶栏行已注明降级取向）；降级方案与系数在 design 标定，verification 以参数断言核验"用了 blur + 标定不透明度"而非追 saturate。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 纯展示组件，不碰密钥/数据/IO（NF5 禁数据接入正是为守此线） |
| 权限 | 否 | 不申请任何系统权限（相册/相机链路在范围外的页面级 spec） |
| 无障碍 | **是** | 点击目标 ≥44px（NF1）/ 对比度 AA（NF2）/ Semantics（NF3）/ reduce-motion（NF4） |
| 性能 | 否 | 无可度量运行阈值；列表虚拟化/缩略图重活归页面级与 thumbnail-cache |
| 多端兼容 | **是** | iOS13+/Android8+ 毛玻璃·阴影·SVG·字体回退（NF6）+ saturate 降级（NF7） |

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui/` + `lib/demo/` + `test/`），不跨模块。
