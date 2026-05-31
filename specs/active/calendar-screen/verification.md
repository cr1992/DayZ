---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：calendar-screen

> 本文件落「需跨多任务才成立 / 屏级专项」的检查；单任务自身可独立验证的条件已在 `tasks.md` 各任务验收，不在此重复。验收口径遵循方法论 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §4（四闸：①token 值 / ②样式参数 / ③布局几何 / ④栅格观感）/§11。
> **跨 spec 边界**：参数/几何抽取 harness（对设计稿源屏 `calendar.html` 比框）与 SSIM 兜底属 `design-sync-automation`（**非本 spec README 依赖**，仅验证基建关系）。本 spec 的样式参数闸 / 布局几何闸用 Flutter 原生 `tester.getRect` / 解析 widget 渲染属性**自验**，不依赖 harness 就绪；「对设计稿源屏比框 + 区域化 SSIM」留 `design-sync-automation` 期二，不在本 spec 重造。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 默认进屏 | 注入 fake repo 进入日历屏 | 月标题=今日月、月视图渲染、今日选中区显示 | R1 | 自动 |
| 月视图三态 | 渲染含「有条目/今日/选中」的月 | has 圆点 / today 环 / sel 实底 各就位且取色为对应 token 真值 | R1, NF1 | 自动 |
| 上/下月导航 | 点上个月 / 下个月（含跨年） | 查看月 ±1、月标题与网格刷新、选中日不变 | R2 | 自动 |
| 回到今天 | 切到非今日月后点回到今天 | 归位今日月 + 今日选中区刷新 | R3 | 自动 |
| 选中有条目日 | 点某有条目日格 | 该日实底选中 + 下方 DayzEntryCard 列表渲染 | R4 | 自动 |
| 条目点击导航 | 点某条目项 | 触发 Routes.reader 导航并携该 entry id | R4 | 自动（mock observer） |
| 选中无条目日 | 选中无条目日 | 日期头 + 空态文案，无卡片、不崩 | R5 | 自动 |
| 月聚合/当日异步加载 | 注入 pending 态 | 区域加载占位、导航不冻结 | R6 | 自动 |
| 查询失败可重试 | 注入 error 态后点重试 | 错误文案 + 重试钮，重试再次发起查询 | R6 | 自动 |

## 专项检查
> 对应 requirement 的 NF 编号。

### 无障碍（NF2, NF3, NF4, NF6）
- [ ] 选中日实底文字（on-accent 落 accent）≥ 4.5:1 — 自动：`flutter test test/ui/calendar/calendar_screen_test.dart`（按本屏实际渲染色对算相对亮度比；复用 tokens-theme 已验色对、落已验通过区间）（NF2）
- [ ] 日期头/篇数/空态真实辅助文本用 `--ink-2` 且 ≥ 4.5:1（非纯 placeholder ink-3）— 自动：同上（NF2）
- [ ] 今日环 / 有条目圆点（accent 贴 bg）有意义 UI ≥ 3.0:1 — 自动：同上（NF2；若用色波及 tokens-theme 三处 expected-fail 则沿用其阻塞口径、报 @Ray，**不在本屏改 tokens.css**）
- [ ] 所有可点元素（月导航钮/回到今天/返回/可点日格/条目项）命中盒 ≥ 44×44 — 自动：`flutter test test/ui/calendar/`（`tester.getSize`）（NF3）
- [ ] 月导航钮/回到今天/返回/日格/条目项有非空 Semantics 标签；日格标签含「日期 + 有无条目 + 今日/选中」 — 自动：同上（`SemanticsNode`/`find.bySemanticsLabel`）（NF4）
- [ ] reduce-motion（`disableAnimations: true`）下月切换/选中切换/加载占位过渡时长经 `dayzMotionDuration` 为 0 — 自动：`flutter test test/ui/calendar/calendar_month_grid_test.dart` + `calendar_screen_test.dart`（注入 `MediaQueryData(disableAnimations: true)`）（NF6）

### 视觉还原（NF1）—— ②样式参数闸 + ③布局几何闸（确定性主闸）
> 断言元素**解析后样式 == 设计稿/token**、几何**顺序/包含/不溢出 + fixed 元素尺寸位置**；content-driven 文本块只断顺序/包含/不溢出、不硬断块高（§4 分治）。
- [ ] ②样式参数：日格 `has` 圆点色 / `today` 环色 / `sel` 实底色 / `on-accent` 文字色 == 对应 theme×mode token 真值；屏内无裸 `Color(0x..)` / 裸字号（值断言，非 grep）— 自动：`flutter test test/ui/calendar/`（NF1）
- [ ] ③布局几何（fixed）：月视图 7 列等宽、日格 `aspect-ratio:1/1`、周表头 7 列对齐 — 自动：`tester.getRect` 断言列宽相等 / 行列对齐（NF1）
- [ ] ③布局几何（content-driven）：选中日条目列表项**顺序/包含/不溢出**（不硬断条目块高，CJK 换行差异噪声）— 自动：同上（NF1）
- [ ] ④栅格观感：月视图 + 选中日区 golden 基线（六套其一兜栅格；区域化 SSIM 与对设计稿源屏比框留 `design-sync-automation` 期二）— 自动：`flutter test test/ui/calendar/`（golden）+ 人工首次基线复核（@Ray）

### 多端兼容（NF7）
- [ ] 360dp 窄屏月视图 7 列网格无水平溢出 — 自动：`flutter test test/ui/calendar/calendar_screen_test.dart`（几何断言无 overflow）
- [ ] iOS 13+ 真机/模拟器：月视图 + CJK 日期文案字体回退正常 — 人工（@Ray）
- [ ] Android 8+ 真机/模拟器：月视图 + CJK 字体回退观感可接受 — 人工（@Ray）

### Repository 边界（NF5，硬红线）
- [ ] 本屏（`lib/ui/calendar/**`）取数全部经注入 `EntryRepo`，控制器仅用注入的 `EntryRepo` 抽象即可驱动全部状态（无需 Drift 句柄）— 自动：`flutter test test/ui/calendar/calendar_controller_test.dart`（注入内存 fake `EntryRepo`、无 Drift 即跑通全部状态转移，**以行为证明不直连 DB**，非 grep）
- [ ] 屏/控制器/月视图不 import `package:dayz/data/`、不持 Drift 句柄、不写 SQL — 人工（@Ray 静态走查 `lib/ui/calendar/**` import 与调用面，确认取数仅经 `EntryRepo` 抽象）

> 数据迁移 / 回滚：本屏只读取数据、不新增/改 DB schema（schema 归 data-layer）→ 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（日历 demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（默认进屏/三态）、R2（月导航）、R3（回到今天）、R4（选日→列表/导航）、R5（空态）、R6（加载/失败可重试）、NF1（token/样式参数）、NF2（对比度）、NF3（命中区）、NF4（Semantics）、NF5（Repo 边界）、NF6（reduce-motion）、NF7（多端/不溢出）均有对应场景或专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/calendar/      # 日期数学 / 月视图 / 控制器 / 屏 / AppLocalizations / 对比度 / 几何 / golden
flutter test test/demo/             # 日历 demo + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`*_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；真正需预批的非 `_test.dart` 共享基建——`test/ui/calendar/fakes/fake_entry_repo.dart`（内存 fake `EntryRepo`，T3 建、T4/T5 复用）与 `test/ui/calendar/goldens/`（golden 基线，T2/T4 共用）——已在 T3/T2/T4 的 inline `验收基建` 字段预批（执行协议第 2 条）。
