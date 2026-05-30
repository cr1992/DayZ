---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-31
文档状态：定稿
---

# ui-shell-navigation（应用外壳与导航）

## 背景

UI 三层还原（token → 组件 → 屏）的**外壳/导航层**：在 `design-tokens-theme`（视觉底座）与 `ui-kit-components`（可复用组件）之上，搭起把各屏串起来的**导航中枢**——路由表、抽屉、FAB 速拨、换肤通路，并用真外壳取代 `lib/app.dart` 当前的 `home: DebugHome()`（见 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §1/§9 W1，§10 第 5 条）。

它是**全部页面级 spec 的硬依赖**：后续每个屏 spec 都要往这套路由表里注册自己的路由、从抽屉/FAB 被导航进入。因此本 spec 的产出（路由名/导航 API/外壳组件/换肤控制器的命名与边界）必须**稳定、清晰、可被直接引用**——本 spec 只交付外壳骨架与导航装置，**不实现任何业务屏的内容**（屏内容归各页面级 spec）。

设计稿真源：抽屉 `.drawer-stage`、FAB `.fab-wrap`/`.fab-scrim`、覆盖式毛玻璃顶栏与 `?state=`/`postMessage` 导航机制见 `ui-design/current/docs/DESIGN-REF.md` §4 与 `PROTOTYPE-ARCH.md` §6；屏清单以 `ui-design/current/pages/screens/` 为准（本 spec 不写死屏数）。

## 范围外

- **任何业务屏的内容实现**（时间线/阅读/编辑/往年今日/搜索/设置/日历/收藏/回忆/回收站等屏体）—— 归各**页面级 spec**；本 spec 只为它们注册**占位路由（placeholder route）**并提供进入路径。本 spec MUST NOT 实现任何屏的真实内容。
- **可复用组件本体**（按钮/卡片/顶栏/sheet/抽屉视觉外观等）—— 归 `ui-kit-components`；本 spec **复用**其交付物（如毛玻璃顶栏壳、sheet 引擎对应的 `showModalBottomSheet` 封装），不在本 spec 重造。
- **主题数据与换肤的视觉值**（六套 `ThemeData`、`DayzColors`、`context.dayz`、纸色派生）—— 归 `design-tokens-theme`；本 spec 只**装配与切换** `ThemeData`，不定义颜色。
- **主题/外观偏好的加密持久化落库**—— 偏好读写最终经数据层（见 D6 / 跨 spec 依赖）；本 spec MUST NOT 持有 Drift 句柄或写 SQL（Repository 边界，见 NF5）。本 spec 阶段若数据层偏好入口尚未就绪，换肤状态先内存态 + 内存 fallback，落库由依赖就绪后接线（记入 `## 已知风格` 与 D6）。
- **新建日记本的真实落库、切本后列表的真实数据查询**—— 归 data-layer / 时间线屏 spec；本 spec 只接线「打开新建日记本 sheet」「请求切换当前日记本 → 通知时间线刷新」的**导航与事件通路**，数据经 `JournalRepo` / 路由参数承载（见 D5 / NF5）。
- **i18n 全量**（`flutter_localizations`、英文 arb、RTL 完整支持）—— 本 spec 遵循 `design-tokens-theme` D4 取向（文案集中 `AppStrings`、日期数字走 `intl`），MUST NOT 引入 localizations 全量。
- **`reduce-motion` 之外的高级动效编排**、画布/storybook 多状态浏览（属 widgetbook，归 `ui-kit-components`）。

## 功能需求

### R1 · 路由表覆盖设计稿当前全部屏
系统 SHALL 用 `go_router` 提供一张声明式路由表，为 `ui-design/current/pages/screens/` 下当前每一屏注册一条具名路由（路由名 = 该屏的稳定 spec 标识，供页面级 spec 引用），并设一个初始路由。
- 前提：App 启动后进入真外壳。
- 操作：`context.go('/<screen>')` 或 `context.goNamed('<screenName>')`（屏名以路由表常量为准）。
- 结果：导航到对应屏的占位 Widget；返回手势可回退；未知路径落到一个明确的 not-found 占位（不白屏、不崩溃）。
> 屏的具体清单不在 requirement 写死，以路由表常量 + 设计稿 `screens/` 为准；本 spec 注册占位 Widget，真实屏体由各页面级 spec 替换（见 D1）。

### R2 · 抽屉导航中枢
系统 SHALL 提供取代标签栏的导航抽屉（对应 `.drawer-stage`/`.drawer`），分区呈现：日记本组（全部日记 + 各日记本带色点）、浏览组（往年今日 / 收藏 / 日历 / 回收站）、底部「设置」。**搜索不入抽屉**（统一走顶栏）。
- 前提：在挂了抽屉的外壳屏（如时间线）。
- 操作：点顶栏菜单钮（`data-drawer-open` 对应入口）打开抽屉，点某导航项。
- 结果：抽屉滑入（scrim 可点关闭）；点浏览组/设置项 → 经 R1 路由导航到对应屏并关抽屉；点某日记本 → 触发 R5 切本。

### R3 · 切换日记本刷新列表
When 用户在抽屉里点选某个日记本（含「全部日记」），the 系统 SHALL 把「当前日记本」切换为该选择，关闭抽屉，并使时间线据此刷新其条目查询入参。
- 前提：抽屉打开，存在多个日记本。
- 操作：点某日记本项。
- 结果：当前日记本状态更新；时间线收到新的「当前日记本」入参（经路由参数或共享状态，本 spec 只交付通路、不查数据）；抽屉关闭；被选中项呈选中态（`.on`）。

### R4 · 新建日记本入口（底部 sheet）
When 用户在抽屉里点「新建日记本」，the 系统 SHALL 打开一个底部 sheet（对应 `.sheet` 轻表单 + `.nj-*` 选色），承载命名 + 选色表单。
- 前提：抽屉打开。
- 操作：点「新建日记本」。
- 结果：弹出新建日记本 sheet（命名输入 + 六色选色，选中态可观测）；确认时把「名称 + 颜色」交给落库通路（经 `JournalRepo`，落库本身归 data-layer）；取消/确认后 sheet 关闭。本 spec 只交付 sheet 的呈现与提交回调通路，**不实现 journal 的真实落库**。

### R5 · FAB 速拨（轻点写 / 长按展开 + 遮罩）
系统 SHALL 提供底部悬浮 FAB（对应 `.fab-wrap`）：**轻点 = 进入写日记（编辑屏）**；**长按（约 0.34s）= 展开二级动作**（拍照 / 语音 / 纯文字），展开时以全屏 `ModalBarrier` 遮罩（对应 `.fab-scrim`）压暗背景、点遮罩收起。
- 前提：在挂了 FAB 的外壳屏。
- 操作：轻点 FAB；或长按 FAB 超过阈值。
- 结果：轻点 → 经 R1 路由进入编辑屏；长按 → 展开二级动作且出现遮罩；点任一二级动作 → 收起并进入编辑屏（携带对应创建意图入参）；点遮罩 → 仅收起、不导航。

### R6 · 换肤通路（settheme / setmode → 全树 rebuild）
系统 SHALL 提供换肤控制器：设置屏改主题色（对应 `settheme`，purple/amber/sage）或外观模式（对应 `setmode`，light/dark/system）时，驱动 `MaterialApp` 顶层 `ThemeData` 切换，全树 rebuild 即时换肤，无需重启。
- 前提：App 运行中，当前为某主题×模式。
- 操作：经设置屏触发换主题色 / 换外观模式（本 spec 提供控制器与 API，设置屏体归 settings spec）。
- 结果：`MaterialApp.theme`/`darkTheme` 取自 `design-tokens-theme` 的六套之一、`themeMode` 反映选择；界面立即切换为目标主题×模式的 token 渲染（`context.dayz.accent` 等同步变化）。

### R7 · 跟随系统外观
Where 外观模式选为「跟随系统」（`setmode=system`），the 系统 SHALL 用 `ThemeMode.system`，由 `MediaQuery.platformBrightness`/系统 `prefers-color-scheme` 解析为亮/暗，并在系统外观变化时随之切换。
- 前提：外观模式 = 跟随系统。
- 操作：系统在亮/暗之间切换（或启动时读系统外观）。
- 结果：App 渲染对应亮/暗主题；用户显式选 light/dark 时则不跟随系统、固定该模式。

### R8 · 真外壳取代 DebugHome
系统 SHALL 将 `lib/app.dart` 的 `home: DebugHome()` 改为挂载本 spec 的 `go_router` 路由器（`MaterialApp.router`），并把六套 `ThemeData` 与换肤控制器接入；Debug Home 不再是 App 启动入口，但**作为一条具名路由保留**（仍可从外壳进入，调试 demo 不丢）。
- 前提：App 冷启动。
- 操作：启动 App。
- 结果：直接进入真外壳的初始屏（经路由器），而非 `DebugHome`；同 commit 更新 `CLAUDE.md`「Debug Home 入口模式」段，说明入口已由真外壳接管、Debug Home 降级为具名路由（见 D7 与方法论 §10 第 5 条）。

## 非功能需求

### NF1 · 点击目标 ≥ 44px
所有外壳可点元素（顶栏菜单钮、抽屉项、FAB 主键与二级动作键、sheet 行、设置入口行）的可点命中区域 MUST ≥ 44×44 逻辑像素（DESIGN-REF §6.4 / 方法论 §11）。

### NF2 · 对比度 ≥ WCAG AA
外壳元素文本/有意义 UI 的对比度 MUST 满足 `design-tokens-theme` NF1 同口径（正文/辅助文本 ≥ 4.5:1，有意义 UI 边/图标 ≥ 3.0:1），且**经 token 取色**（不在外壳硬编码颜色）。外壳本身不引入新色值，对比度由 token 层保证；本 spec 只须验「确实走 token、未硬编码」与「关键文本对比达标」。

### NF3 · Semantics 标签
外壳交互元素 MUST 提供可被屏幕阅读器识别的语义标签（对应设计稿 `aria-label`：菜单钮「菜单」、搜索钮「搜索」、FAB「写日记」、抽屉项名、二级动作「拍照/语音/纯文字」等），文案经 `AppStrings`。抽屉、sheet 打开时 MUST 正确处理焦点可达（可被语义遍历到）。

### NF4 · reduce-motion（动效尊重系统减弱动态效果）
抽屉滑入、FAB 展开、sheet 弹入、路由转场等动效 MUST 在系统「减弱动态效果」（`MediaQuery.disableAnimations` / `accessibleNavigation`）开启时退化为无动画或即时呈现，MUST NOT 强制播放过渡动画。

### NF5 · Repository 边界（硬红线）
外壳取数/写数 MUST 只经 `JournalRepo`/`EntryRepo`/`MediaRepo`/`TagRepo`/`EditingSessionRepo`，MUST NOT 在外壳/导航/换肤代码中持有 Drift 句柄、import Drift、或写 SQL/Drift 语句。新建日记本（R4）、切本（R3）、换肤偏好持久化（R6）若需落库，一律经对应 Repository（落库实现归 data-layer，本 spec 只调接口）。

### NF6 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+（minSdk 26）上：路由返回手势（iOS 边缘右滑）正常、抽屉/FAB/sheet 的 `SafeArea`（状态栏/灵动岛/Home 条/底部安全区）让位正确、覆盖式顶栏毛玻璃在两端均不崩溃（Android 上 `BackdropFilter` 可接受降级）。

### NF7 · 视觉一律走 token
外壳/导航/FAB/抽屉的颜色、字号、间距、圆角、阴影、动效时长 MUST 取自 `context.dayz.*` 与 `DayzSpacing`/`DayzRadii`/`DayzMotion` 等常量，屏内/组件内 MUST NOT 硬编码上述视觉值（消灭「硬编码颜色/间距」红线违规面）。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 不碰密钥/加解密；偏好落库经 Repository（落库实现归 data-layer），本 spec 不写 SQL |
| 权限 | 否 | 不申请系统权限（拍照/录音权限归 media-picker / 编辑屏 spec） |
| 无障碍 | **是** | 点击目标 ≥44px（NF1）、对比度 AA（NF2）、Semantics（NF3）、reduce-motion（NF4） |
| 性能 | 否 | 无可度量运行阈值（路由/换肤为低频交互；列表性能归时间线屏） |
| 多端兼容 | **是** | 返回手势/SafeArea/毛玻璃在 iOS 13+ 与 Android 8+ 行为（NF6） |

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/ui/` + `lib/app.dart` + `lib/demo/` + `pubspec.yaml`），不跨模块。
