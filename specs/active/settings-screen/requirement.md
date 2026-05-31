---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-31
文档状态：定稿
---

# settings-screen（设置屏）

## 背景

设置屏（设计稿源 `ui-design/current/pages/screens/settings.html`，外壳屏 id `settings`、`Routes.settings`）是 UI 还原波次 W2 里**结构最简单的叶子屏**：一个账户头卡 + 若干分组的纵向列表，无吸顶/无限滚动/相册等复杂机制。它的价值在两处：

1. **首个把 `ui-kit-components` 的 `DayzSetRow`/`DayzSwitch`/`DayzSheet` 串成一整屏的页面级 spec**，验证组件层在真实页面装配下的可用性（列表行 + 开关 + 底部选择器）。
2. **承载两条合规红线文案的单一可见落点**——「主密码锁不住照片」（媒体 key 独立、不随 rekey）与「数据库加密始终开启 · 已加密只读、无关闭入口」。这两条是 `docs/design/06`、`key-management` D7、`media-storage` 的产品行为在 UI 上**必须如实解释**的地方（方法论 §3「媒体相关 UI 须如实说明主密码锁不住照片」）。

本 spec 取**最简范围**：只做设置屏的**渲染 + 外观选择器接外壳换肤 + 红线文案 + 导航/事件上抛**。各设置项背后的真实业务（本地备份执行、导出生成、App 锁开关落库、主密码模式切换 rekey、草稿恢复开关持久化）归各自底层 spec 与后续页面级 spec；本屏对这些项**只渲染状态 + 点击导航到占位 / 上抛回调**，不在本 spec 内实现落库或 rekey。

## 范围外

- **不**实现备份执行 / 导出生成 / App 锁开关的真实落库 / 主密码模式切换（rekey）/ 草稿恢复开关的偏好持久化——这些归 `backup-full-snapshot`、`key-management`、`auto-save-draft` 与后续页面级 spec。本屏 MUST NOT 写任何 Drift/SQL、MUST NOT 调 `PRAGMA rekey`、MUST NOT 直接持 `KeyProvider` 句柄做密钥操作。
- **不**自绘 `CupertinoListSection.insetGrouped`——列表行一律用 `ui-kit-components` 的 `DayzSetRow`/`DayzSetGroup`（自绘 token 驱动 Row + `flutter_svg` 图标徽），不赌 Cupertino 分组件的视觉与设计稿一致。
- **不**新建毛玻璃顶栏、抽屉、FAB、底部 sheet 引擎——复用 `ui-shell-navigation` 的外壳与 `ui-kit-components` 的 `DayzGlassAppBar`/`DayzSheet`。
- **不**实现「主题色 / 外观模式」之外的设置项的选择器交互（备份、导出仅渲染 + 导航占位）。
- 设计稿 settings.html 当前**只有 `default` 一个状态**（外壳 `SCREENS[].states=[{k:'default'}]`，无多 `?state=`）——本 spec 不预造额外状态分支。

## 功能需求

> 屏内分组与行清单**以设计稿 `settings.html` 为准**：账户头卡（`.set-account`）+ 4 个分组（`隐私与加密` / `备份与导出` / `外观` / `书写`）。下列 R# 按设计稿当前结构定；设计稿增删行由 `design-sync-automation` 三档分流增量驱动，不在本 spec 预判。

### R1 · 设置屏骨架与分组渲染
设置屏 SHALL 在 `Routes.settings` 路由下渲染一个账户头卡 + 设计稿四个分组（`DayzSetGroup`：分组标题 `.lab` + `DayzSetRow` 列表），承载于 `ui-kit-components` 的 `DayzGlassAppBar`（标题「设置」+ 返回钮）下的唯一滚动区。
- 前提：从外壳导航进入 `Routes.settings`。
- 操作：渲染设置屏。
- 结果：路由落到真实 `SettingsScreen`（非 `PlaceholderScreen`）；可见账户头卡（头像字 + 姓名 + 「N 篇 · 本地库 X MB」副行）与四个分组，各行图标徽（`flutter_svg`）+ 主/次文案 + 右侧尾随件（switch / val / chev）按设计稿就位。

### R2 · 主题色选择器接外壳换肤
点击「主题色」行（`DayzSetRow.tappable`，右侧 `.val` 显当前主题色点 + 名称 + chev）SHALL 打开底部单选选择器（`DayzSheet.picker`），列雾紫 / 暖黄 / 雾绿三项（带色点），选中项即时经外壳 `theme_controller.setTheme(...)` 上抛换肤、全树 rebuild。
- 前提：当前主题色为某一套（如雾紫）。
- 操作：点「主题色」行 → 选「暖黄」。
- 结果：`theme_controller` 的 themeName 变为 amber，`context.dayz.accent` 全树切到暖黄；选择器关闭，行右侧 `.val` 更新为「暖黄」+ 暖黄色点。

### R3 · 外观模式选择器接外壳换肤
点击「外观模式」行 SHALL 打开底部单选选择器，列 跟随系统 / 浅色 / 深色 三项，选中项经外壳 `theme_controller.setMode(...)` 上抛（对应 `ThemeMode.system/light/dark`），即时切换明暗。
- 前提：当前外观模式为某一项（如跟随系统）。
- 操作：点「外观模式」行 → 选「深色」。
- 结果：`theme_controller` 的 mode 变为 `ThemeMode.dark`，明暗即时切换；选择器关闭，行右侧 `.val` 的 `.mv` 更新为「深色」。

### R4 · 数据库加密行恒为只读「已加密」
设置屏 SHALL 在「隐私与加密」分组渲染「数据库加密」行，主文案「数据库加密」、次文案「SQLCipher · 始终开启」、右侧 `.val` 恒为只读文本「已加密」。该行 MUST NOT 提供任何开关 / 关闭入口 / 可点击的关闭交互。
- 前提：进入设置屏（DB 始终加密，见 `docs/design/06`、`key-management`）。
- 操作：查看「数据库加密」行 / 尝试与右侧交互。
- 结果：右侧只显「已加密」纯文本，无 `DayzSwitch`、无 chev、无 tappable 行为；点击该行不触发任何状态变更或导航。

### R5 · 媒体相关合规文案：主密码锁不住照片
设置屏 SHALL 在与加密/隐私相关的可见处呈现一条说明「设置主密码不会加密照片，照片始终用设备密钥保护」（媒体 key 独立于主密码、不参与 rekey，见 `key-management` D7、`media-storage`），使「设了主密码也锁不住照片」这一有意为之的产品行为对用户显形。
- 前提：进入设置屏。
- 操作：查看「隐私与加密」分组的媒体说明文案（行次文案 / help 文本 / 选择器说明，落点见 design D5）。
- 结果：能读到「主密码不保护照片」的明确解释（文案来自 `AppLocalizations`，非裸中文）。
- 理由：方法论 §3 与 `media-storage` 均要求媒体相关 UI 须如实说明此行为，否则用户对「设了主密码照片仍可被未加密读取」产生错误安全预期。

### R6 · 开关与导航类行的事件上抛（不落库）
设置屏 SHALL 把开关类行（「App 锁」、「恢复未完成的编辑」用 `DayzSwitch`）与导航类行（「本地备份」、「导出」用 chev）做成**纯展示 + 回调上抬**：开关切换发 `onChanged` 回调（默认显示态来自入参，不在本屏落库）、导航行点击发导航回调（指向占位 / 上抛意图）。
- 前提：进入设置屏。
- 操作：拨「恢复未完成的编辑」开关 / 点「导出」行。
- 结果：触发对应回调（widget test 可观测回调被调用 + 传值正确）；本屏不写 Drift/SQL、不触发真实备份/导出/rekey（落库接线归底层 spec）。
- 注：If 底层偏好/业务入口（如 `auto-save-draft` 的草稿恢复偏好、`key-management` 的 App 锁状态、`backup-full-snapshot` 的备份执行）尚未就绪，then 本屏 SHALL 以入参驱动展示态 + 回调留待接线，MUST NOT 为赶进度在本屏直接写库（NF4 红线）。

### R7 · 真路由接入与返回
设置屏 SHALL 接入 `Routes.settings` 的真实路由，并提供可预测的返回行为。
- 前提：从抽屉「设置」或其它入口进入 `Routes.settings`。
- 操作：观察页面 / 点击顶栏返回按钮。
- 结果：页面为 settings 设计稿对应的独立设置屏，MUST NOT 仍显示占位页；点击返回时若路由栈可回退则 `pop` 回来源页，若不可回退则回到 `Routes.timeline`，MUST NOT 让用户停在无返回路径的设置页。
- 约束：本 spec 只允许改 `Routes.settings` 自己的 route definition / builder 及主题控制器暴露所需的最小外壳接线，MUST NOT 改 `Routes` 常量命名、抽屉条目语义或其它屏 builder。

### R8 · Debug Home 入口
设置屏 SHALL 挂一个 Debug Home demo 入口（`lib/demo/settings_screen_demo.dart`），在 `lib/demo/demo_entry.dart` 的 `demos` 列表**末尾追加一行**（不插中间、不改 `DemoEntry` 字段），供真机走查与 widget test 独立 pump。
- 前提：App 启动进 Debug Home。
- 操作：进入设置屏 demo。
- 结果：在假数据下可见完整设置屏，可切主题色/外观看换肤、可拨开关看回调、可读两条红线文案。

## 非功能需求

### NF1 · 视觉走 token（不硬编码）
设置屏与本 spec 内任何 widget MUST NOT 硬编码颜色 / 字号 / 间距 / 圆角 / 阴影；一律走 `context.dayz.*` + `DayzSpacing/DayzRadii/DayzMotion`（来自 `design-tokens-theme`）。
- 度量：本 spec 新建文件经样式参数闸（widget test 断言解析后样式取值 == 设计稿对应 token），无字面色值/像素常量。

### NF2 · 无障碍
设置屏 MUST 满足：
- **点击目标 ≥ 44px**：所有可点击行（tappable `DayzSetRow`、选择器项、开关、返回钮）命中区 ≥ 44×44 逻辑像素。
- **对比度 ≥ WCAG AA**：行主/次文案、`.val` 文本、「已加密」只读文本对其底色 MUST ≥ 4.5:1（六套主题逐套；复用 `design-tokens-theme` 的对比度判定族，本屏不重造 token、只验本屏实际渲染对）。
- **Semantics 标签**：开关有「App 锁」/「恢复未完成的编辑」语义标签与开关状态；选择器项有可读标签；返回钮有「返回」标签；只读「已加密」与媒体说明文案可被屏幕阅读器读到。
- **reduce-motion**：选择器（`DayzSheet`）的弹出动效在系统「减弱动态效果」（`MediaQuery.disableAnimations`）开启时降级为瞬时（经 `ui-kit-components` 的 `dayzMotionDuration` 门，本屏不另写动效时长）。

### NF3 · 多端兼容
设置屏 SHALL 在 iOS 13+ 与 Android 8+ 上正常布局与字体回退（中英混排走 `design-tokens-theme` 的字族回退）；底部选择器在两端均经 `SafeArea` 让出底部安全区。

### NF4 · Repository 边界（硬红线）
设置屏 MUST NOT 持有 Drift 句柄、MUST NOT 写 SQL / Drift、MUST NOT import `lib/data` 内部 DAO；任何取数/落库一律经 Repository（`JournalRepo` 等）或外壳状态层（`theme_controller` 换肤）。本 spec 取最简范围，**仅消费**「账户头卡统计（篇数 / 库大小）」与「当前换肤偏好」两类只读数据，且经入参注入，不在本屏直接调 Repo（取数编排归外壳；data-layer 未就绪时用假数据，见 design 已知风险）。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | **是** | 承载加密/主密码/媒体 key 合规文案（R4/R5），错述会误导用户安全预期 |
| 权限 | 否 | 本屏不申请系统权限（生物识别授权归 key-management） |
| 无障碍 | **是** | 点击目标 ≥ 44px / 对比度 WCAG AA / Semantics / reduce-motion（NF2） |
| 性能 | 否 | 静态列表屏，无可度量运行阈值 |
| 多端兼容 | **是** | iOS 13+ / Android 8+ 布局与字体回退（NF3） |

→ 命中「安全 / 无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。文件变更仍在单个 Flutter app 模块内，不跨顶层 package。
