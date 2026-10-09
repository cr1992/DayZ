---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-06-06
文档状态：草稿
---

# 验证：trash-screen

> 落「能由本屏/本组件 widget test 独立验证」的部分（方法论 §4/§11）：样式参数闸（解析后样式 == 设计稿、读 token）、布局几何闸（`tester.getRect` 断顺序/包含/不溢出 + fixed-geometry 尺寸；content-driven 文本块不硬断块高）、无障碍专项。**参数/几何抽取 harness 与对设计稿源屏 `trash.html` 的 SSIM 兜底属 `design-sync-automation`（跨 spec 依赖），不在本 spec 重造**；golden 基线本 spec 自带（任务「验收基建」预批）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 列表态渲染 | 给定软删条目进入本屏 | 顶栏「回收站」+「清空」+ 30 天提示条 + 每条卡（日期/标题/2行摘要/元信息/恢复/彻底删除） | R1, R6 | 自动 |
| 恢复条目 | 点某条「恢复」 | controller `restore` 经 `EntryRepo` 恢复入口调一次 + 该卡移出 + 成功 toast（含标题） | R2 | 自动 |
| 彻底删除·确认 | 点「彻底删除」→ 确认 | 弹确认 sheet（永久删除？）→ `EntryRepo.hardDelete` 调一次 + 卡移出 + danger toast | R3 | 自动 |
| 彻底删除·取消 | 点「彻底删除」→ 取消 | 不调 `hardDelete`、列表不变 | R3 | 自动 |
| 清空·非空 | 点顶栏「清空」→ 确认 | 弹清空 sheet → 全部 `hardDelete` + 转空态 + danger toast | R4 | 自动 |
| 清空·空态守卫 | 空态点顶栏「清空」 | 仅 toast「回收站已经是空的」、不弹 sheet | R4 | 自动 |
| 空态 | 无软删条目 / 恢复或清空致空 | 仅 `DayzEmptyState`（标题/说明），隐列表 + 提示条，顶栏「清空」仍在位 | R5 | 自动 |
| 返回 | 点顶栏返回钮 | 本屏出栈回上一屏 | R7 | 自动 |
| Debug Home 入口 | 进 Debug Home → 回收站 demo | 可 pump 进入 demo、演示四类交互 | R8 | 自动 |
| 删除链路闭环（跨屏） | reader 删除 → 入回收站 → 恢复 → 回时间线 | 软删后来源不可见、回收站可见、恢复后时间线可见，`Total:` 非零 | R1, R2, R7 | 自动（E2E，依赖 e2e-harness）|

## 专项检查
> 对应 requirement 的 NF 编号。无障碍按本屏实际渲染断言，**不 grep 被改文件自身**。

### Repository 边界（NF1）
- [ ] `trash_controller.dart` 取数/删/恢复**只经注入的 `EntryRepo` 抽象**，未 import `lib/data` 内部、无 Drift 句柄 / SQL — 自动：`flutter test test/ui/trash/trash_controller_test.dart`（注入 `FakeEntryRepo`，断言四操作经 `EntryRepo` 接口调用 + 行为，被测对象不持具体 Drift 实现；行为级断言，非源码 grep）
- [ ] `TrashScreen` / 卡片 / DTO 不直接持有 `EntryRepo` 或 Drift（取数全经 controller 回调）— 自动：`flutter test test/ui/trash/trash_screen_test.dart`（屏只接 `entries`+回调驱动，验其无数据层直连）

### 样式参数闸（NF7 · 解析后样式 == 设计稿，读 token）
> 抽取自源屏 `pages/screens/trash.html` 的 `.trash-*` 与复用件参数；widget test 断言解析后值 == `context.dayz` token 取值（非硬编码）。
- [ ] 提示条 `.trash-banner`：底色 `--bg-2`、圆角 `--r-md`、文本色 `--ink-2`、图标色 `--ink-3` — 自动：`flutter test test/ui/trash/trash_banner_test.dart`
- [ ] 卡 `.trash-item`：底色 `--surface`、描边 `--hairline`、圆角 `--r-md`、阴影 `--shadow-sm` — 自动：`flutter test test/ui/trash/trash_item_card_test.dart`
- [ ] 摘要 `.ti-ex` 行钳制：`maxLines==2` + `overflow==ellipsis` + `softWrap==true`（对齐 `-webkit-line-clamp:2`，方法论 §4 ② 截断族，堵 ②/③ 缝）— 自动：同上
- [ ] 「彻底删除」`.ti-purge` / 顶栏「清空」危险文字色 == `--danger` — 自动：`trash_item_card_test.dart` + `trash_screen_test.dart`

### 布局几何闸（NF7 · tester.getRect 顺序/包含/不溢出）
> fixed-geometry（按钮命中盒、提示条图标、卡描边盒）硬断尺寸/相对位置（≤1–2px 容差）；content-driven（标题、摘要文本块）只断顺序 + 包含 + 不溢出，不硬断块高（CJK 回退字宽换行差异，方法论 §4 ③）。
- [ ] 卡内顺序：日期 → 标题 → 摘要 → 元信息行（恢复/彻底删除在元信息行右侧）— 自动：`flutter test test/ui/trash/trash_item_card_test.dart`（`getRect` 断 top 递增 / 同行包含）
- [ ] 屏内顺序：顶栏 → 提示条 → 列表（空态时：顶栏 → 空态居中，无提示条/列表）— 自动：`flutter test test/ui/trash/trash_screen_test.dart`
- [ ] 摘要文本块不溢出卡片宽度（content-driven 只断包含/不溢出，不断块高）— 自动：`trash_item_card_test.dart`

### 无障碍 — 点击目标（NF2）
- [ ] 「恢复」「彻底删除」（`.btn-sm`）命中区 ≥ 44×44 — 自动：`flutter test test/ui/trash/trash_item_card_test.dart`（`tester.getSize` ≥ 44）
- [ ] 顶栏「清空」「返回」、sheet 确认/取消命中区 ≥ 44×44 — 自动：`flutter test test/ui/trash/trash_screen_test.dart`

### 无障碍 — 对比度（NF3）
> 按本屏实际渲染对，算相对亮度比、断言值；六套主题逐项（复用 tokens-theme 的对比度算法/口径）。
- [ ] 标题/摘要（`--ink`/`--ink-2` 对 `--surface`）≥ 4.5:1 — 自动：`flutter test test/ui/trash/trash_contrast_test.dart`
- [ ] 提示条文本（`--ink-2` 对 `--bg-2`）≥ 4.5:1 — 自动：同上
- [ ] 危险文字「彻底删除」「清空」（`--danger` 对其底）≥ 4.5:1 — 自动：同上
- [ ] 元信息「删除于…·…后清除」（`.ti-left` 用 `--ink-3` 作真实辅助文本）≥ 4.5:1 — 自动：同上（**若实测 < 4.5（tokens-theme 已登记 `--ink-3` 作辅助文本 2.77 expected-fail）→ 阻塞放行、报 @Ray 调 token 或改用 `--ink-2`，MUST NOT 在本屏硬编码绕过**；机器真源沿用 tokens-theme `test/ui/theme/contrast_xfail.yaml`，不另开第二处）

### 无障碍 — Semantics 标签（NF4）
- [ ] 「恢复」/「彻底删除」按钮语义标签含条目标题（「恢复 {title}」「彻底删除 {title}」）可经 `find.bySemanticsLabel` 定位 — 自动：`flutter test test/ui/trash/trash_item_card_test.dart`
- [ ] 顶栏「清空」「返回」、空态、提示条有合理语义 — 自动：`flutter test test/ui/trash/trash_screen_test.dart`

### 无障碍 — reduce-motion（NF5）
- [ ] 注入 `MediaQueryData(disableAnimations: true)`，卡移出动效时长为 0 / 瞬时移除（经 `dayzMotionDuration` 门）— 自动：`flutter test test/ui/trash/trash_item_card_test.dart`

### 多端兼容（NF6）
- [ ] iOS 13+ 真机/模拟器：返回手势、intl 中文日期/相对时间、`.btn-sm` 命中、移出动效、中文衬线标题回退正常 — 人工（@Ray）
- [ ] Android 8+ 真机/模拟器：同上，中文衬线落系统字观感可接受 — 人工（@Ray）

### 跨屏闭环（Patrol · T7）
- [ ] reader 删除 → 回收站出现 → 恢复 → 时间线可见的真实 app 闭环 — 自动：`bash scripts/patrol_test.sh -d <device-id> --target patrol_test/trash_restore_flow_test.dart`（校验 `Total:` 非零、`Failed:` = 0，真实信号 = 删除后来源不可见 + 回收站可见 + 恢复后时间线可见）
- [ ] 跨屏跳转、toast、回收站列表状态和恢复后落点无突兀 — 人工（@Ray，复核 Patrol 截图 / 录屏工件；不再承担机械回归）

### 栅格观感（golden 兜底 · 半确定性）
- [ ] 列表态 / 空态 golden 基线无破坏（六套主题抽样）— 自动：`flutter test test/ui/trash/`（golden）+ 人工复核（@Ray）
> 对设计稿源屏 `trash.html` 的区域化 SSIM/pixelmatch 比框属 `design-sync-automation`（跨 spec 依赖），残余低分进 SYNC_REPORT 标红、不在本 spec 阻塞。

> 数据迁移 / 回滚：本屏无持久化 schema 变更或数据格式演进（软删字段由 data-layer 既有 schema 提供，本屏经 `EntryRepo` 只读/改）→ 整段不涉及，省略。

## 跨屏说明（端到端闭环）
> 「删除 = 移到回收站」完整闭环需多 spec 协同（设计 D3 / 已知风险），本 spec 单独验证范围 = 「给定软删数据 → 列表/恢复/彻底删/清空/空态」。
- 删除发起方（reader/onthisday/时间线的删除按钮 + 二次确认 + 可撤销 toast → `EntryRepo.softDelete`）归各自页面级 spec。
- `EntryRepo`「列回收站条目」查询 + 「恢复」方法是 data-layer 待确认缺口（见 design 已知风险）；data-layer + 发起方屏就绪前本屏端到端只能用 `FakeEntryRepo`，就绪后由 T7 的 Patrol 用例覆盖真闭环，@Ray 只复核截图 / 录屏终签。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（回收站 demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（列表态）、R2（恢复）、R3（彻底删除+确认/取消）、R4（清空+空态守卫）、R5（空态）、R6（提示条）、R7（返回）、R8（Debug Home），NF1（Repo 边界）、NF2（点击目标）、NF3（对比度，含 `--ink-3` expected-fail）、NF4（Semantics）、NF5（reduce-motion）、NF6（多端）、NF7（token/参数闸）均有对应场景/专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze）与栅格观感 golden 已显式标「回归」/「兜底」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/trash/        # DTO/banner/card/controller/screen/contrast + golden
flutter test test/demo/            # 回收站 demo + Debug Home 回归
bash scripts/patrol_test.sh -d <device-id> --target patrol_test/trash_restore_flow_test.dart  # 跨屏删除/恢复闭环
flutter analyze
```

> 共享测试基建说明：`test/ui/trash/*_test.dart`、`test/demo/trash_screen_demo_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **自动放行、无需预批**；真正需预批的非 `_test.dart` 共享基建是 `test/ui/trash/fake_entry_repo.dart`（`EntryRepo` 回收站接口的内存假实现，供 controller/屏/demo 测试共用），已在 T4/T5/T6 的 inline `验收基建` 字段预批（执行协议第 2 条）。对比度算法/口径与 `contrast_xfail.yaml` 机器真源复用 `design-tokens-theme`，不在本 spec 重建。
