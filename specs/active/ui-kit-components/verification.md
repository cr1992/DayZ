---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：ui-kit-components

> 落「能由本组件 widget test 独立验证」的部分（方法论 §4 ②样式参数闸 / ③布局几何闸、§11 验收口径）：样式参数断言（解析后样式 == 设计稿、读 token）、布局几何断言（`tester.getRect` 断顺序/包含/不溢出 + fixed-geometry 元素尺寸位置；content-driven 文本块不硬断块高）、无障碍专项。
> **参数/几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec）**——本 spec 用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验，不重造 harness；需"对设计稿源屏比框"的 ④ 栅格观感闸留给 design-sync 期二，本 spec 不在此跑 golden/SSIM。

## 功能验证（端到端 / 跨任务）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| §3 基础件成套 | 六套主题各 pump 每个 §3 组件 | 解析样式参数==设计 token 值；变体外观各异 | R1 | 自动 |
| §3b 页面级件 | pump 月份头/年份分隔/设置行/搜索框 | 结构与样式==设计；日期/篇数经 intl | R2 | 自动 |
| 毛玻璃顶栏滚动态 | 未滚动→滚动越阈值 | 实底→BackdropFilter 毛玻璃覆状态栏 + 0.5px 底分割 | R3 | 自动 |
| 全局 toast | 调 show（各 tone / 有无 action） | 中性底 + tone 图标点色；有 action 停留更久；上限 3 | R4 | 自动 |
| 底部 sheet 四形态 | 触发 actions/picker/form/confirm | 各形态结构/勾选/回调/关闭正确 | R5 | 自动 |
| FAB 速拨 | 轻点 / 长按 | 轻点回调；长按展开动作+scrim；点 scrim 收起 | R6 | 自动 |
| 收藏星规范 path | 切已收藏/未收藏 | fill `--favorite`/描边 currentColor，path 不变 | R8 | 自动 |
| widgetbook 矩阵 | 切主题 addon + 组件状态 | 组件在所选主题×状态即时渲染；变体编目齐 | R7 | 自动 + 人工(@Ray 矩阵观感) |

## 专项检查

### 无障碍（NF1 点击目标 / NF2 对比度 / NF3 语义 / NF4 reduce-motion）
> 按渲染断言可观测值，不 grep 源文件。

- [ ] 全部可交互件（按钮/图标钮/开关/勾选/分段/标签删除叉/sheet item/FAB/star/设置可点行）命中区 ≥ 44×44 — 自动：`flutter test test/ui/`（`tester.getRect` 断命中盒尺寸）
- [ ] 图标钮/无文字件/开关/收藏星有可定位 `Semantics` 标签（`AppStrings`）、装饰图标被 `ExcludeSemantics` — 自动：`flutter test test/ui/`（`find.bySemanticsLabel` 命中 + 装饰件不在语义树）
- [ ] 组件未误用 token 引入新不达标渲染对（正文不用 `--ink-3`、着色文字落 soft 底、实色底文字用 `--on-accent`）— 自动：`flutter test test/ui/`（断组件文本/UI 用对 token 角色；对比度数值本身由 tokens-theme `contrast_test` 负责，本项只验"用对语义"）
- [ ] toast/sheet/FAB/顶栏动效在 `MediaQuery.disableAnimations==true` 时降级为无动效/瞬时 — 自动：`flutter test test/ui/`（注入 `MediaQueryData(disableAnimations:true)` 断动效时长为 0，经 `dayzMotionDuration` 单点门）

### Repository 边界（NF5 硬红线）
- [ ] 组件层无任何 `package:.../data` 或 `drift` import、无 Drift 句柄/SQL — 自动：`flutter test test/ui/architecture_no_repo_import_test.dart`（用 `dart:io` 扫 `lib/ui/` 源文件的 import 声明，断言不含 `data/`/`drift`/`sqlite`；这是对**目录整体**的结构断言，非 grep 被改文件自身的实现内容，符合抗规避——断言的是"全层 import 拓扑"这一可观测结构，不是某文件里有没有某行字面量）
- [ ] 组件 API 只接入参 + 回调（不接 Repository 类型）— 人工（@Ray，复核 design `## 文件变更` 各组件签名无 Repo 形参）

### 多端兼容（NF6 / NF7 saturate 降级）
- [ ] iOS 13+ 真机/模拟器：BackdropFilter 毛玻璃、多层 boxShadow、flutter_svg 收藏星、CJK 回退渲染正常 — 人工（@Ray）
- [ ] Android 8+（minSdk 26）真机/模拟器：同上，毛玻璃 saturate 降级观感可接受 — 人工（@Ray）
- [ ] 毛玻璃降级 = blur + 标定不透明度叠色（不追 saturate），参数在标定区间 — 自动：`flutter test test/ui/shell/dayz_glass_app_bar_test.dart`（断 blur sigma + 叠色不透明度==标定，NF7）

> 数据迁移 / 回滚：本 spec 无持久化 schema 变更或数据格式演进 → 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（画廊追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）
- [ ] 屏内禁裸中文：组件层用户可见文案均经 `AppStrings`，widget 测试以 `find.text(AppStrings.xxx)` 命中（回归护栏，落实 tokens-theme D4）— 自动：`flutter test test/ui/`（测试只引 `AppStrings` 常量即自带"只引常量"回归；裸中文会致测试无法用常量命中）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（§3 成套）、R2（§3b）、R3（毛玻璃顶栏）、R4（toast）、R5（sheet）、R6（FAB）、R7（widgetbook）、R8（收藏星）、NF1（≥44px）、NF2（对比度用对 token）、NF3（Semantics）、NF4（reduce-motion）、NF5（Repository 边界）、NF6（多端）、NF7（saturate 降级）均有对应场景/专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze / 禁裸中文护栏）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/        # 基础件/页面级件/外壳/图标/无障碍/边界/禁裸中文护栏
flutter test test/demo/      # widgetbook 画廊 + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`test/ui/**/*_test.dart`、`test/demo/widget_gallery_demo_test.dart`（含 `architecture_no_repo_import_test.dart`）由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**。本 spec 不依赖 golden/SSIM 基线（那属 design-sync-automation 期二），故无需在此预批 golden 基建。`pubspec.yaml`/`pubspec.lock` 的依赖增改是源码白名单（非测试基建），已在 T1 inline 可改文件列出。
