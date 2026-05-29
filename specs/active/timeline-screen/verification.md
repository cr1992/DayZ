---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：timeline-screen

> 本文件落「需多任务产物同时成立 / 专项跨任务」的集成与无障碍/兼容/视觉验证；单任务可独立验证的（分组分页、卡片字段、面板开关等）在 `tasks.md` 各任务内，不在此重复。
> 验收口径遵循 `docs/design/10-ui-restore-and-design-sync.md` §4（②样式参数闸 / ③布局几何闸 / ④栅格观感闸）与 §11（widget test 断言可观测值，禁止假装能测的 grep）。② 的样式参数 fixture（`timeline_params.fixture.json`）与 ③/④ 的「对设计稿源屏比框 / 区域化 SSIM」抽取 harness 属 `design-sync-automation` 交付物——**需 harness 的部分标依赖它，本 spec 用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验的部分不依赖 harness 就绪**。

## 功能验证（端到端，跨任务）
| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 滚动骨架 | pump 时间线（多月假数据）滚动 | 顶栏 pinned 不离场；月份头吸顶顶替；卡片归月 | R1 | 自动 |
| 向上无限分页 | 滚近底部多次 | 经 `EntryRepo.timeline` 追加更早月，无并发重复取页，取尽显「已到最早」终态 | R2 | 自动 |
| 空状态 | 假 Repo 空配置进屏 | 仅渲染 `DayzEmptyState`，无月份头/列表/loader | R3 | 自动 |
| 月份头落日历 | 点月份头 | 面板落下；点 scrim/再点同头关闭 | R4 | 自动 |
| 跳未加载远期月 | 日历选远期未加载月 | 先补载该月、再月级停靠到该月份头 | R5 | 自动 |
| 卡片进阅读屏 | 点卡片 | 发起 `Routes.reader` 导航携 entryId | R6 | 自动 |
| 切本刷新 | 切 journalId | controller 重查 + 列表淡入（reduce-motion 下瞬时） | R7 | 自动 |
| 顶栏导航 | 点搜索/往年今日钮 | 发起 `Routes.search` / `Routes.onthisday` 导航 | R7 | 自动 |
| Debug Home 入口 | Debug Home 点该 demo | 进入假数据时间线，可滚动/切空与有内容 | R8 | 自动 |

## 专项检查
> 对应 requirement 的 NF 编号。

### Repository 边界（NF1）
- [ ] `lib/ui/timeline/**`（含 controller）不 import `package:dayz/data/database.dart`、不出现 Drift 句柄/SQL — 自动：`flutter test test/ui/timeline/timeline_boundary_test.dart`（用反射/`Library` 解析或运行期断言：构造 `TimelineController` 仅依赖 `EntryRepo` 抽象、注入假 Repo 即可完整驱动全部取数路径 → 证明无直连 DB 的隐藏路径。**断言行为/依赖关系，非 grep 被改文件文本**）
- [ ] 时间线全部取数经 `EntryRepo` 方法（注入假 Repo 即可跑通分页/计数/分组，无需真实 DB）— 自动：同上测试（假 Repo 能完整驱动 = 无旁路）

### 列表滚动不触发同步重活（NF2）
- [ ] 滚动/分页期间卡片 build 路径不同步解码大图 / 不触发缩略图重建 — 自动：`flutter test test/ui/timeline/timeline_no_heavy_work_test.dart`（`DayzGallery` 注入计数型假 `ImageProvider`，断言滚动多页期间未发生同步解码调用；缩略图只经异步 warmup）
- [ ] 缩略图未就绪显示占位（灰块），不阻塞 build — 自动：同上（断言占位 widget 出现、无同步重活）

### 无障碍（NF3, NF4, NF5, NF6）
- [ ] 点击目标 ≥ 44×44：月份头触发器 / 卡片 / 收藏星 / 日历日格·月格 / loader 可点项 — 自动：`flutter test test/ui/timeline/timeline_a11y_test.dart`（`tester.getRect` 断言各命中区尺寸 ≥44，NF3）
- [ ] 六套主题（purple/amber/sage × light/dark）下本屏文本对底对比度遵循 tokens-theme NF1 分族口径 — 自动：`flutter test test/ui/timeline/timeline_contrast_test.dart`（按当前 `ThemeData` 解析本屏文本/背景实际取色算相对亮度比，分族断言；已知 token 级 expected-fail 读 `test/ui/theme/contrast_xfail.yaml` 单一真源、xfail 放行，不在本屏改 token，NF4）
- [ ] Semantics：菜单/搜索/往年今日钮、FAB、月份头(展开/收起态)、收藏星、日历面板(dialog+「跳转到日期」)、空状态可被屏幕阅读器标签定位 — 自动：`flutter test test/ui/timeline/timeline_a11y_test.dart`（`find.bySemanticsLabel(AppStrings.xxx)`，NF5）
- [ ] reduce-motion：`MediaQueryData(disableAnimations:true)` 下切本淡入 / 日历落下 / FAB 展开 / 顶栏滚动渐显时长为 0 — 自动：`flutter test test/ui/timeline/timeline_reduce_motion_test.dart`（注入 disableAnimations 断言动效时长经 `dayzMotionDuration` 归零，NF6）

### 样式参数闸（②，确定性）
- [ ] 月份头 / 卡片 / 日历面板 / loader 等元素**解析后样式**（color/font/radius/padding/shadow + 截断行钳制）== 设计稿参数清单 — 自动：`flutter test test/ui/timeline/timeline_style_params_test.dart`（读 `timeline_params.fixture.json` 断言 widget 解析样式；fixture 由 `design-sync-automation` 从源屏 `timeline.html` 抽取产出，本 spec 消费。**依赖 design-sync-automation 的抽取 harness 产出 fixture**；fixture 未就绪时本项标「待 design-sync-automation」）

### 布局几何闸（③，确定性，按 fixed/content 分治）
- [ ] fixed-geometry（月份头高、收藏星/日历日格尺寸、loader 转圈尺寸、顶栏高）硬断尺寸 + 相对位置（≤1–2px 容差）— 自动：`flutter test test/ui/timeline/timeline_geometry_test.dart`（`tester.getRect`）
- [ ] content-driven（卡片标题/摘要文本块）只断**顺序 + 包含 + 不溢出**，不硬断块高（相邻间距用 `gap=next.top−prev.bottom`）— 自动：同上（避免 CJK 换行差异致 flaky，遵 §4）

### 栅格观感（④，半确定性，advisory 不阻塞）
- [ ] 时间线 default / empty 两态 golden 基线无破坏 — 自动：`flutter test test/ui/timeline/timeline_golden_test.dart` + 人工复核（@Ray）
- [ ] 毛玻璃顶栏 + 吸顶头「并成一条磨砂」区域化 SSIM 兜底（`saturate` 降级的饱和度差进 SYNC_REPORT 标红、不阻塞）— 自动：归 `design-sync-automation`（区域化 SSIM harness），**本 spec 标依赖它**；本 spec 侧只保 golden 回归锁

### 兼容性（NF7）
- [ ] iOS 13+ 真机时间线滚动 / 毛玻璃顶栏正常 — 人工（@Ray）
- [ ] Android 8+（含低端）真机滚动正常；毛玻璃低端降级为半透实色 + 细分割线生效 — 人工（@Ray）

## 回归检查
- [ ] Debug Home `demos` 列表新增一条且其余顺序不变、`DemoEntry` 字段未改 — 自动：`flutter test test/demo/timeline_demo_test.dart`（断言 `demos.last` 与长度，回归）
- [ ] 现有 demo（Hello / 编辑器）仍可进入无异常 — 自动：`flutter test test/demo/` + 人工抽查（@Ray）（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，确保无遗漏。任一项不通过则 verification 未定稿。
- [ ] 正向：R1（滚动骨架/几何）、R2（分页·功能验证+tasks T1）、R3（空态）、R4（日历开关）、R5（跳未加载月）、R6（卡片导航）、R7（切本/顶栏导航）、R8（Debug Home）、NF1（边界专项）、NF2（无重活专项）、NF3/NF4/NF5/NF6（无障碍专项）、NF7（兼容性专项）、NF8（文案/intl，见 tasks T4/T6 与样式参数闸）均有验证，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归检查（demos 顺序 / 现有 demo）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/timeline/        # 边界/几何/样式/无障碍/对比度/reduce-motion/无重活/golden
flutter test test/demo/timeline_demo_test.dart
```

> 共享测试基建说明：`test/ui/timeline/fake_entry_repo.dart`（假 Repo）、`test/ui/timeline/timeline_params.fixture.json`（样式参数 fixture）、`test/ui/timeline/goldens/`（golden 基线）属共享测试文件（文件白名单外），已在 `tasks.md` 对应任务的 `验收基建` 字段预批；样式参数 fixture 抽取与区域化 SSIM harness 属 `design-sync-automation` 交付物，本 spec 消费其产出、不重造（见 design `## 已知风险`「跨 spec 依赖」）。
