---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：editor-integration-screen

> 本文件落「需多任务集成 / 跨任务才成立 / 专项」的检查；单任务自身可独立验证的条件已在 `tasks.md` 各任务「验收标准」。
> 视觉还原口径（方法论 §4/§11）：本屏 widget test 用 Flutter 原生 `tester.getRect`/`getSize` + 解析 widget 属性自验（样式参数闸 ②、布局几何闸 ③）；**对设计稿源屏 `editor.html` 比框/比像素的参数抽取 harness 与区域化 SSIM 属 `design-sync-automation`（跨 spec 依赖，期二）**，本 spec 不重造——下方标「依赖 design-sync」的项由其交付 harness 后接入，本 spec 先以原生几何自验兜住确定性主闸。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 正文是 AppFlowy | pump 编辑页 | 正文区为 `AppFlowyEditor`，非 TextField | R1 | 自动 |
| 无边框标题 | 聚焦标题输入 | 标题无可见边框（聚焦也不显描边），占位==AppStrings | R2 | 自动 |
| 加载解 docVersion | 喂 content_json(docVersion=1) | 解码出 Document 渲染进编辑器 | R3 | 自动 |
| 保存产双产物 | 点「完成」 | encode 出 content_json(带 docVersion) + extractPlainText 出 content_plain(首行=标题) | R3 | 自动 |
| 工具栏走 AppFlowy 体系 | 聚焦编辑器 | 工具栏由 AppFlowy mobile_toolbar 渲染、绑定 EditorState、editor-dock 能力齐备 | R4 | 自动 |
| 不自管键盘停靠 | 注入不同 viewInsets | 本屏不额外平移工具栏（停靠由 AppFlowy 管），本屏无 viewInsets 手动顶起 | R5 | 自动 |
| 高亮态派生自选区 | 选区移入/移出粗体 | B item 随选区实际格式即时亮/灭，非本地布尔 | R6 | 自动 |
| 图片插入加密链路 | 选一张图 | image_picker→MediaStore.put(DMED,独立媒体key)→MediaRepo.addMeta→插 image 块(media.id)；content_json 无真实路径 | R7, NF2 | 自动 |
| 自动保存对接 | 编辑后停顿 / 退出 | onChanged 翻 plain payload 喂 DraftCoordinator；退出/完成 forceFlush | R8 | 自动 |
| 三状态呈现 | 以 empty/writing/rich 进入 | 占位/正文/顶栏标题文案与 editor.html 对应态一致(经 AppStrings)，日期 kicker 经 intl | R9 | 自动 |
| 顶栏与 chip | 点「完成」/点 chip | 完成走保存(R3/R8)后返回；chip 点开占位选择并 .on 回显 | R10 | 自动 |

## 专项检查
> 对应 requirement 的 NF 编号。

### Repository 边界（NF1，安全/红线 · 跨任务）
- [ ] 本屏全部 Dart 源（`lib/ui/editor/*.dart`）**不 import** `package:.../lib/data/` 的 Drift 句柄、不出现 SQL/Drift 查询 — 自动：`flutter test test/ui/editor/repo_boundary_test.dart`（**行为/结构验**：测试运行时本屏取数/写数只命中注入的 Repository fake；并以一个独立断言核 `lib/ui/editor/` 编译单元未引入 Drift 符号——核验来源为编译/import 图，**非 grep 被改文件文本**）
- [ ] 图片元数据只经 `MediaRepo`、媒体字节只经 `MediaStore`，无直写文件/DB — 自动：`flutter test test/ui/editor/editor_image_inserter_test.dart`（fake 断言链路只命中 MediaStore/MediaRepo）

### 安全 / 媒体密钥独立（NF2，安全 · 跨任务）
- [ ] 插入图片后 `content_json` 内**无真实文件路径**、只含 `media.id`（路径变化不破坏文档）— 自动：`flutter test test/ui/editor/editor_image_inserter_test.dart`（断言序列化文本不含路径分隔/绝对路径、含 media.id）
- [ ] 本屏图片/隐私文案不暗示「主密码锁住照片」（媒体走独立设备 key，不随主密码/rekey）— 人工（@Ray）（核 AppStrings 内本屏相关文案口径，与 settings 屏红线文案单一来源一致）

### 权限（NF5 之一，权限 · 真机 · 跨任务）
- [ ] `image_picker` 在 iOS 13+ / Android 8+ 触发相册/相机系统权限并能取图 — 人工（@Ray，真机各一次）

### 无障碍（NF3 · 跨任务）
- [ ] 工具栏每个 item、顶栏关闭/完成、四 chip 均有 `Semantics` 标签（对齐 editor.html aria-label，经 AppStrings）— 自动：`flutter test test/ui/editor/editor_a11y_test.dart`（`find.bySemanticsLabel(AppStrings.xxx)` 逐项命中）
- [ ] 所有可点目标命中区 ≥ 44×44 px（含横向滚动工具栏 item）— 自动：同上（`tester.getSize` 断言 ≥ Size(44,44)）
- [ ] 正文/标题文本对底对比度 ≥ WCAG AA（4.5:1），着色元素（accent 日期 kicker / chip 选中）按 tokens-theme NF1 分族口径达标 — 自动：`flutter test test/ui/editor/editor_contrast_test.dart`（按本屏实际渲染对算相对亮度比，六套主题逐项；沿用 tokens-theme token，不新造色；遇 tokens-theme 已登记的 expected-fail 项以其 `contrast_xfail.yaml` 为准、阻塞报 @Ray，不静默通过）
- [ ] 动效尊重「减弱动态效果」：注入 `MediaQueryData(disableAnimations: true)`，工具栏/chip/sheet 动效时长降为近瞬时（经 `dayzMotionDuration`）— 自动：`flutter test test/ui/editor/editor_reduce_motion_test.dart`（断言 disableAnimations 下动效 Duration≈0）

### 视觉参数 / 几何（NF4 · 确定性主闸 · 跨任务）
- [ ] 本屏元素样式参数 == token（顶栏/标题/kicker/meta chip/工具栏配色取 `context.dayz.*`，无硬编码色值/像素字号/魔法间距）— 自动：`flutter test test/ui/editor/editor_style_params_test.dart`（断言解析后样式 == token 值）
- [ ] 布局几何：顶栏在最上、kicker→标题→meta→正文顺序正确、底部 has-dock 留白存在、内容不溢出；fixed-geometry 元素（关闭/完成钮、chip、工具栏 item）尺寸/相对位置硬断言（≤1–2px 容差），content-driven（标题/正文文本块）只断顺序+包含+不溢出、不硬断块高 — 自动：`flutter test test/ui/editor/editor_geometry_test.dart`（`tester.getRect` 分治断言）
- [ ] 栅格观感（编辑器排版、工具栏 editor-dock 外观、毛玻璃顶栏）对照设计稿 — golden 回归锁 + 区域化 SSIM advisory（**依赖 design-sync** 期二 harness；`MobileToolbarStyle`/saturate 像素差进 advisory 标红、不阻塞，方法论 §4 ④）— 自动(golden) + advisory

### 多端兼容（NF5 · 真机 · 跨任务）
- [ ] iOS 13+：软键盘弹出工具栏停靠正确、编辑滚动不被键盘遮挡、AppFlowy mobile toolbar 表现正常 — 人工（@Ray）
- [ ] Android 8+（minSdk 26）：同上，毛玻璃顶栏按 ui-kit 降级正常 — 人工（@Ray）

> 数据迁移 / 回滚：本屏无持久化 schema 变更或数据格式演进（条目/草稿/媒体表归各底层 spec）→ 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（编辑页 demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `Routes.editor` 解析到 `EditorScreen`、其余路由未受影响 — 自动：`flutter test test/ui/editor/editor_route_test.dart`（回归 + R 覆盖）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）
- [ ] vendored 包未被本 spec 改动（若 T3 确需改 AppFlowy 源则应已走 appflowy-patch-tracking 独立 commit、不在本 spec）— 自动：`bash scripts/check_patches.sh`（回归 · 守 AGENTS.md 红线，退出 0）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（AppFlowy 正文）、R2（无边框标题）、R3（codec/docVersion）、R4（AppFlowy 工具栏）、R5（不自管 viewInsets）、R6（高亮派生选区）、R7（图片加密链路）、R8（自动保存）、R9（三状态）、R10（顶栏/chip）、NF1（Repository 边界）、NF2（媒体密钥独立/文案）、NF3（无障碍四项）、NF4（视觉参数/几何）、NF5（多端键盘/取图）均有场景或专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze / check_patches）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/editor/        # 屏体/样式/工具栏/桥/插图/codec/路由/无障碍/对比度/几何/参数/边界
flutter test test/demo/             # 编辑页 demo + Debug Home 回归
flutter analyze                     # 回归
bash scripts/check_patches.sh       # 回归：vendored 包未被本 spec 越界改动（退出 0）
```

> 共享测试基建说明：`*_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；真正需预批的是非 `_test.dart` 的共享基建——`test/ui/editor/fakes/`（codec/MediaStore/DraftCoordinator/Repository 内存 fake），已在 T0/T1/T4/T5/T6 的 inline `验收基建` 字段预批（执行协议第 2 条）。「对设计稿源屏比框/SSIM」的参数抽取 harness 属 `design-sync-automation` 交付物，本 spec 标依赖、不在此重造（方法论 §4）。
