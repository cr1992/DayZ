---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：onthisday-screen

> 本屏可由 widget test 独立验证的部分（样式参数闸 / 布局几何闸 / 无障碍专项 / golden 兜栅格）落本文件；跨任务集成（屏装配 + controller 取数 + 缩略图编排端到端）也归此。**几何/样式断言用 Flutter 原生 `tester.getRect`/解析 widget 属性自验**，参数/几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec 依赖），需要 harness 的「对设计稿源屏比框」部分标为依赖它、不在本 spec 重造。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 往年今日列表 | controller `load(m,d)`（fake EntryRepo 返回多年份）→ 屏渲染 | 年份段从新到旧，段内卡片有序，屏头篇数 == 命中总数 | R1, R3 | 自动 |
| 年份分隔（普通行非吸顶）| 渲染含多段列表 → 向下滚动 | 每段前一行 `DayzYearSeparator`，随滚动离开视口、不停靠顶栏下 | R2 | 自动 |
| 卡片配图（异步 + 红线）| controller 组装带封面项 | 带封面项 `coverImage` 非空、触发 `ThumbnailCache.warmup` 异步入队，全程无同步缩略图重建调用 | R4, NF5 | 自动 |
| 空态 | fake EntryRepo 返回空 → 渲染 | 屏显 `DayzEmptyState`（「今天还没有往事」），无卡片/年份段/屏头 | R5 | 自动 |
| 收藏星 | 渲染含收藏项的 VM | 收藏项显填充 `DayzFavoriteStar`，非收藏项不显 | R6 | 自动 |
| ⋯ 菜单 + 回忆卡片入口 | 点更多钮 → 点「生成回忆卡片」 | 弹两项 sheet；导航 `Routes.memory`（携 month/day），「分享这一天」出 toast | R7 | 自动 |
| 顶栏与返回 | 渲染屏 + 滚动 + 点返回 | `DayzGlassAppBar` 承载标题/返回/更多；滚动后毛玻璃浮起；返回出栈 | R8 | 自动 + 人工 |
| 路由接线 | 经 `app_router` 导航 `Routes.onthisday` | 落 `OnThisDayScreen`（非 `PlaceholderScreen`），其它路由不受影响 | R8 | 自动 |
| Debug Home 入口 | 进 Debug Home → 点往年今日 demo | 进入屏 demo，可切 default/empty 两态 | R9 | 自动 + 人工 |

## 专项检查

### 样式参数闸（NF6 · 元素解析后样式 == 设计稿，读 token、断言值）
> 按 ThemeData 实际渲染断言样式值，**不** grep 屏文件；抽样关键元素。
- [ ] 屏内颜色/字号/间距全经 token：kicker 着 `context.dayz.accentInk`、卡片标题用衬线排版角色、屏头标题字族/字号取自 `DayzFonts`/排版角色 — 自动：`flutter test test/ui/onthisday/onthisday_screen_test.dart`（解析渲染后 `TextStyle`/装饰断言 == token 值，无硬编码色/号）
- [ ] 年份分隔/卡片/空态间距取自 `DayzSpacing`、圆角取自 `DayzRadii` — 自动：同上（断言 padding/radius == 对应常量）

### 布局几何闸（R2 · 顺序/包含/不溢出 + 非吸顶行为）
> fixed-geometry（顶栏钮/收藏星/分隔线）硬断尺寸位置；content-driven（标题/摘要文本块）只断顺序+包含+不溢出，不硬断块高（CJK 换行差异，见方法论 §4）。
- [ ] 列表项顺序 == `flatten` 顺序（年份分隔在其段卡片之前；段降序）— 自动：`onthisday_screen_test.dart`（`tester.getRect` 比较 top 序）
- [ ] **年份分隔非吸顶**：滚动后分隔 `tester.getRect` 顶部位置随滚动改变、不停靠在顶栏下方固定位（区别于时间线吸顶头）— 自动：同上（滚动前后位置 delta 断言）
- [ ] 卡片/屏头/空态不溢出视口宽度（无 overflow）— 自动：同上（右边界 ≤ 屏宽）
- [ ] 顶栏返回钮/更多钮为 fixed-geometry：尺寸/相对位置稳定（≤1–2px 容差）— 自动：同上

### 无障碍（NF2, NF3, NF4）
- [ ] 返回钮/更多钮/可点卡片命中区 ≥ 44×44 px — 自动：`flutter test test/ui/onthisday/onthisday_a11y_test.dart`（`tester.getSize` 断言）
- [ ] 返回/更多/收藏星/可点卡片有 Semantics 标签 — 自动：同上（`find.bySemanticsLabel(AppStrings.*)`）
- [ ] reduce-motion：`MediaQueryData(disableAnimations: true)` 下顶栏渐显/配图淡入/ sheet 动效时长为 0（经 `dayzMotionDuration` 门）— 自动：`onthisday_a11y_test.dart` + `onthisday_empty_image_test.dart`

### 对比度（NF1）
> 按本屏实际渲染对算相对亮度比，六套主题逐项；复用 `design-tokens-theme` NF1 分族口径与其 `contrast_xfail.yaml` 机器真源（单一来源，不另开第二处）。
- [ ] kicker（`--accent-ink` 落浅底）、卡片标题/摘要（`--ink`/`--ink-2` 对 `--surface`）≥ 4.5:1 — 自动：`flutter test test/ui/onthisday/onthisday_contrast_test.dart`（按渲染对算比值）
- [ ] 卡片 meta / 年份「N 年前」/ 空态说明若用 `--ink-3` 作真实辅助文本 ≥ 4.5:1（否则改 `--ink-2`）— 自动：同上（**复用 tokens-theme 已登记 ink-3 expected-fail → 阻塞、报 @Ray 或改 ink-2**）
- [ ] 收藏星 `--favorite` / accent 作有意义 UI 贴底 ≥ 3.0:1 — 自动：同上
> token 本身 expected-fail（tokens-theme 预登记三处）遇到时**显形并阻塞放行**、停下报 @Ray 调 token，本屏 **MUST NOT 擅自改 `tokens.css`** 或屏内硬编码替代色。

### 安全 / 红线（NF5 · Repository 边界 + 缩略图 + 媒体 key 归属）
- [ ] 屏与 controller **不持 Drift 句柄、不写 SQL/Drift**：取数只经 `EntryRepo`/`MediaRepo`/`TagRepo` 抽象 — 自动：`onthisday_controller_test.dart`（注入 fake repo，断言无 data 层 Drift 依赖；测试只用 Repo 抽象即编译通过）+ 静态核验（controller/屏不 import `lib/data`）
- [ ] **缩略图只异步 `warmup`、滚动不同步重建**：带封面项触发 `ThumbnailCache.warmup`，全程无任何同步缩略图重建调用 — 自动：`onthisday_controller_test.dart`（fake cache 只暴露 `warmup`，断言被异步入队、无同步重建）
- [ ] **媒体 key 归属**：本屏 UI **不暴露「主密码锁住照片」错误暗示**（配图与主密码无关）— 人工（@Ray）：走查屏内文案/空态/失败态无相关错误暗示

### 多端兼容（NF7）
- [ ] iOS 13+ 真机/模拟器：列表滚动 + 毛玻璃顶栏 + 中英混排字体回退正常 — 人工（@Ray）
- [ ] Android 8+ 真机/模拟器：毛玻璃允许降级为半透实色 + 细分割线（复用 `DayzGlassAppBar` 降级），字体回退观感可接受 — 人工（@Ray）

> 数据迁移 / 回滚：本屏只读取数、无持久化 schema 变更或数据格式演进 → 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（往年今日 demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `app_router` 其它路由 builder 未受 `Routes.onthisday` 接线影响 — 自动：`flutter test test/ui/onthisday/onthisday_route_test.dart`（回归：抽查另一路由仍落原屏/占位）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）

## 栅格观感（④ golden 兜底，半确定性）
> golden 作确定性回归锁；区域化 SSIM/视觉模型属 `design-sync-automation`（跨 spec），本 spec 只产 golden 基线、不重造 harness。
- [ ] 本屏 `default`/`empty` 两态 golden 基线（六套主题抽样）无破坏 — 自动：`flutter test test/ui/onthisday/`（golden）+ 人工复核（@Ray）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（列表）、R2（年份分隔非吸顶）、R3（屏头篇数）、R4（配图异步）、R5（空态）、R6（收藏星）、R7（⋯ 菜单/回忆卡片入口）、R8（顶栏/返回/路由）、R9（Debug Home）、NF1（对比度）、NF2（命中区）、NF3（Semantics）、NF4（reduce-motion）、NF5（Repository/缩略图/媒体 key 红线）、NF6（token）、NF7（多端）均有对应场景/专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / app_router / analyze）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/onthisday/        # 屏装配/VM/controller/菜单/空态配图/无障碍/对比度/路由/几何/golden
flutter test test/demo/                # 往年今日 demo + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`test/ui/onthisday/*_test.dart`、`test/demo/onthisday_screen_demo_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；本屏不引入非 `_test.dart` 的额外共享基建（fake repo/cache 作为测试内嵌或同目录 helper 由各任务 `验收基建` 字段就近预批）。对比度复用 `design-tokens-theme` 的 `test/ui/theme/contrast_xfail.yaml` 机器真源（单一来源），不在本 spec 重建第二处。golden 基线为本屏验收基建，归 verification 跨任务专项、随屏 widget test 目录自动放行。
