---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：favorites-screen

> 验收口径遵循 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §4（四闸）/§11：样式参数闸（解析后样式==token/设计值）+ 布局几何闸（`tester.getRect` 断顺序/包含/不溢出；fixed-geometry 断尺寸位置、content-driven 文本块只断顺序不硬断块高）+ golden 兜栅格 + 无障碍专项。「对设计稿源屏比框」的参数/几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec 依赖），本 spec 用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验，需 harness 的部分标依赖它、不在本 spec 重造。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 收藏列表倒序 | fake `EntryRepo` 返回 N 条 → pump 收藏屏 | 渲染 N 张 `DayzEntryCard`，顺序==controller `entries`（时间倒序） | R1 | 自动 |
| 计数头 | 有内容态、count=19 | 上方计数头，标题为 `intl` 格式化「19 篇值得再读的」，文案来自 `AppStrings` | R2 | 自动 |
| 空态 | fake 返回 0 条 → pump | 无计数头/无卡片，可见 `DayzEmptyState`（标题/说明来自 `AppStrings`） | R3 | 自动 |
| 顶栏返回 | 点顶栏返回钮 | 触发 `Navigator.pop`/`context.pop`，标题==`AppStrings.favoritesTitle` | R4 | 自动 |
| 进入阅读页 | 点任一卡片 | 触发一次 `Routes.reader` 导航并携该 entryId | R5 | 自动 |
| 加载态 | fake 用未完成 Future | 显示克制加载占位，不白屏 | R6 | 自动 |
| 失败态 | fake 抛异常 | 显示非崩溃错误占位（`AppStrings` 文案），无未捕获异常 | R6 | 自动 |
| 路由接入 | 经 `Routes.favorites` 导航 | 落到 `FavoritesScreen`（非 `PlaceholderScreen`） | R4, R5 | 自动 |

## 专项检查
> 对应 requirement 的 NF 编号。

### 无障碍（NF4）
- [ ] 顶栏返回钮命中盒 ≥ 44×44 — 自动：`flutter test test/ui/favorites/favorites_screen_geometry_test.dart`（`tester.getRect` 断尺寸）
- [ ] 可点击卡片命中盒 ≥ 44×44 — 自动：同上
- [ ] 返回钮有 Semantics 标签「返回」 — 自动：`flutter test test/ui/favorites/favorites_screen_test.dart`（`find.bySemanticsLabel`）
- [ ] 计数头标题可朗读「N 篇值得再读的」、空态有可读语义 — 自动：`flutter test test/ui/favorites/favorites_count_header_test.dart`（Semantics finder）
- [ ] 计数头各文本对底对比度 ≥ 4.5:1（overline `accentInk` 落底 / 大标题 `ink` / 副标题 `ink2`），空态文本同 — 自动：本屏只用 token、不引入新值，对比度真源沿用 `design-tokens-theme` NF1 六套逐项核验（`flutter test test/ui/theme/contrast_test.dart`）；本 spec 留一项断言「计数头/空态文本颜色解析后==对应 token（未硬编码）」`flutter test test/ui/favorites/favorites_count_header_test.dart`
- [ ] reduce-motion：注入 `MediaQueryData(disableAnimations: true)` 时状态切换/加载占位动效时长为 0 — 自动：`flutter test test/ui/favorites/favorites_screen_test.dart`（经 `dayzMotionDuration` 门，断时长 0）

### 多端兼容（NF5）
- [ ] iOS 13+ 真机/模拟器：收藏屏列表滚动流畅、毛玻璃顶栏、中英混排字体回退正常 — 人工（@Ray）
- [ ] Android 8+ 真机/模拟器：毛玻璃顶栏允许降级为半透实色（降级在 `DayzGlassAppBar` 侧）、列表滚动与字体回退可接受 — 人工（@Ray）

### Repository 边界（NF1，硬红线）
- [ ] 收藏屏与控制器不持 Drift 句柄、不写 SQL/Drift，取数只经 `EntryRepo` — 自动：`flutter test test/ui/favorites/favorites_controller_test.dart`（控制器注入 fake `EntryRepo` 即跑通，**证明无对真 DB/Drift 的硬依赖**；fake 仅实现 `EntryRepo` 接口）；并以行为断言「换 fake repo 即可驱动全部四态」作为「取数仅经 Repository」的可观测证据，而非 grep import
- [ ] 软删除过滤不在本屏重复实现（依赖 `EntryRepo` 默认过滤 `deleted_at`）— 自动：同上（fake repo 返回的即「已过滤」集合，屏不做二次过滤——断言屏渲染条数==fake 返回条数，无屏内过滤）

### 不触发缩略图同步重建（NF6，既有红线）
- [ ] 卡片封面只接 `ImageProvider`、滚动不触发缩略图生成 — 自动：`flutter test test/ui/favorites/favorites_screen_test.dart`（fake 提供占位 `ImageProvider`，pump + 滚动后断言无缩略图生成调用——本屏不持缩略图生成入口；缩略图 `warmup` 红线归 `thumbnail-cache`）

### 栅格观感（golden 兜底）
- [ ] default 屏 golden（代表主题）通过 — 自动：`flutter test test/ui/favorites/favorites_screen_test.dart`（golden 基线在 `test/ui/favorites/goldens/`）
- [ ] empty 屏 golden（代表主题）通过 — 自动：同上
> 跨设计稿源屏的区域化 SSIM / pixelmatch 与 pinned-hash 巡检属 `design-sync-automation`（期二），本 spec 仅落 Flutter 端 golden 回归锁；残余像素差进 SYNC_REPORT 标红、不在本 spec 阻塞。

> 数据迁移 / 回滚：本 spec 纯展示屏，无持久化 schema 变更或数据格式演进 → 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（收藏屏 demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] shell 其他屏路由 builder 未被本 spec 改动（T4 仅改 favorites 一行）— 自动：`flutter test test/ui/favorites/favorites_route_test.dart`（抽查另一路由仍指向其原 builder，回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（倒序列表）、R2（计数头）、R3（空态）、R4（顶栏返回）、R5（进阅读页）、R6（加载/失败态）、NF1（Repository 边界）、NF2（样式==token，见计数头/屏样式参数断言）、NF3（AppStrings+intl，见 R2 与文案断言）、NF4（无障碍专项）、NF5（多端专项）、NF6（不触发缩略图）均有对应场景/专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / 路由抽查 / analyze）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/favorites/        # 控制器/计数头/屏/几何/路由/demo + golden
flutter test test/demo/debug_home_test.dart   # Debug Home 回归
flutter test test/ui/theme/contrast_test.dart # 对比度真源（design-tokens-theme，本屏沿用、不重造）
flutter analyze
```

> 共享测试基建说明：`*_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；真正需预批的非 `_test.dart` 共享基建——`test/ui/favorites/fakes/fake_entry_repo.dart`（内存 fake `EntryRepo`，T1 建、T3/T5 复用）与 `test/ui/favorites/goldens/`（golden 基线）——已在 T1/T3/T5 的 inline `验收基建` 字段预批（执行协议第 2 条）。`contrast_test.dart` 属 `design-tokens-theme` 交付的跨主题专项，本 spec 仅引用、不新建。
