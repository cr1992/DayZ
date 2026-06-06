---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-06-06
文档状态：定稿
---

# 验证：settings-screen

> 本文件落「需多任务产物同时成立的集成/端到端/专项检查」与「跨任务的样式参数闸 / 布局几何闸 / golden / 无障碍专项」；单任务内可独立验证的回调/结构断言留在 tasks。参数/几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec，仅验证基建关系，非 README 依赖）——本 spec 的样式/几何断言用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验，**不依赖该 harness 就绪**；需对设计稿源屏比框的部分留给 design-sync 期二，不在本 spec 重造。

## 功能验证（端到端，经 demo 接最小控制器/spy）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 设置屏结构 | pump 设置屏喂假 accountStats | 账户头卡 + 四分组 + 各行按 settings.html 就位 | R1 | 自动 |
| 主题色换肤端到端 | demo 内点「主题色」→ 选暖黄 | `onPickTheme` 上抛 → 最小控制器换肤 → `context.dayz.accent` 切暖黄、`.val` 更新 | R2 | 自动 |
| 外观模式换肤端到端 | demo 内点「外观模式」→ 选深色 | `onPickMode` 上抛 → `ThemeMode.dark` 即时切换、`.mv` 更新 | R3 | 自动 |
| 数据库加密只读 | 查看/点击「数据库加密」行 | 右侧恒「已加密」、无开关/无 chev、点击零回调 | R4 | 自动 |
| 媒体红线文案显形 | 查看「隐私与加密」分组 | 「主密码不会加密照片…」文案可见且语义可读 | R5 | 自动 |
| 开关/导航回调 | 拨「恢复未完成的编辑」/ 点「导出」 | 对应回调被调用传值；本屏不落库/不触发真实业务 | R6 | 自动 |
| 真路由接入 | 经 `Routes.settings` 导航 | 落到真实 `SettingsScreen`，非 `PlaceholderScreen` | R1, R7 | 自动 |
| 返回行为 | 从其它页 push 设置后点返回 / 直接打开 settings 后点返回 | 可 pop 时回来源页；栈底回 `Routes.timeline` | R7 | 自动 |
| Debug Home 入口 | 进 Debug Home → 设置屏 demo | 入口可达、假数据渲染、可切换换肤、开关视觉回写、红线文案可读 | R8 | 自动 + 人工 |

## 专项检查
> 对应 requirement 的 NF 编号。

### 样式参数闸（NF1）
> 断言元素**解析后样式 == 设计稿对应 token**，读 `context.dayz.*`/`DayzSpacing`/`DayzRadii`，不 grep 屏源/被改文件文本。
- [x] settings 专属图标 path 不含写死色值 / `fill=` / `stroke=`，图标着色留给渲染侧 `colorFilter` — 自动：`flutter test test/ui/settings/settings_strings_icons_test.dart`
- [ ] 行图标徽实际 `colorFilter`、分组内边距 / 行间距 / 圆角的解析值逐项比对设计稿 token — 维护态后置：需补参数 fixture 或 design-sync 期二抽取基线；当前 v1 不以不存在的 fixture / golden 阻塞
- [x] 账户副行篇数/库大小经 `intl` 格式化（非硬编码字符串）— 自动：`flutter test test/ui/settings/settings_screen_structure_test.dart`（改入参文本随之变）

### 布局几何闸（NF2 点击目标 + 不溢出）
> fixed-geometry（图标徽、开关、chev、返回钮、选择器项）硬断尺寸/命中盒；content-driven（行主/次文案块）只断顺序/包含/不溢出，不硬断块高（中英混排换行差异，方法论 §4）。
- [x] 备份 / 导出 tappable 行命中区 ≥ 44×44 — 自动：`flutter test test/ui/settings/settings_rows_callbacks_test.dart`（`tester.getSize`）
- [ ] 选择器项 / 开关 / 返回钮命中区 ≥ 44×44 全量几何硬断 — 维护态后置：当前自动测试覆盖选择器可选中、开关语义与回调、返回行为；未补全逐项 `getRect`
- [x] 分组/行按 settings.html 顺序排列，账户头卡 + 四分组 + 设计稿各行可定位 — 自动：`flutter test test/ui/settings/settings_screen_structure_test.dart`
- [ ] 行内文本不溢出专项断言 — 维护态后置：当前结构测试只断顺序 / 包含，不伪造 overflow 几何检查

### 无障碍（NF2 对比度 + Semantics + reduce-motion）
- [ ] 行主/次文案、`.val`、「已加密」只读文本对底色 ≥ 4.5:1（六套主题逐套，复用 tokens-theme 对比度判定族，按 `ThemeData` 实际渲染对算相对亮度比、不 grep token）— 维护态后置：当前仓库无 `test/ui/settings/settings_a11y_contrast_test.dart`；token 层对比度由 `design-tokens-theme` 保证，本屏 v1 仅核验不新增屏级对比度硬闸
- [x] 开关有 Semantics 标签（App 锁 / 草稿恢复）、媒体红线文案语义可读 — 自动：`flutter test test/ui/settings/settings_encryption_redline_test.dart` + `settings_rows_callbacks_test.dart`（`find.bySemanticsLabel`）
- [x] 返回按钮行为可达且语义接入真实返回路径 — 自动：`flutter test test/ui/settings/settings_route_test.dart`
- [ ] 选择器（DayzSheet）动效在 `MediaQueryData(disableAnimations:true)` 下为瞬时（经 `dayzMotionDuration` 门）— 维护态后置：当前 `settings_pickers_test.dart` 覆盖 picker 行为与回调，未注入 `disableAnimations`

### 栅格观感（golden 回归锁，advisory）
- [ ] 设置屏 light/purple golden 基线无破坏 — advisory / 维护态后置：当前仓库无 settings golden 基线；多主题/SSIM 兜底属 `design-sync-automation` 期二，本 spec v1 不阻塞、低分标红进 SYNC_REPORT

### 多端兼容（NF3）
- [ ] iOS 13+ 真机/模拟器：设置屏布局、字体回退、底部选择器 SafeArea 让位正常 — 人工（@Ray，维护态终审）
- [ ] Android 8+ 真机/模拟器：设置屏布局、CJK 字体回退、选择器观感可接受 — 人工（@Ray，维护态终审）

### Repository 边界（NF4 硬红线，静态核验）
- [x] `lib/ui/settings/*.dart`、`lib/demo/settings_screen_demo.dart`、settings route builder 接线不 import `package:.../data/`/`lib/data` 内部 DAO、不 import Drift、不持 Drift 句柄、不出现 SQL/`PRAGMA rekey`/直接密钥操作 — 自动：`flutter test test/ui/settings/settings_repo_boundary_test.dart`（断言本屏依赖图不含 data/Drift；用 Dart 分析/导入图断言，**非** grep 被改文件自身文本——断言来源于编译/导入关系这一独立可观测事实）

### 路由接入（R7）
- [x] `Routes.settings` builder 渲染真实 `SettingsScreen`，非占位页 — 自动：`flutter test test/ui/settings/settings_route_test.dart`
- [x] 仅 `Routes.settings` builder 被本 spec 替换，其它未交付屏仍保持原 builder / 占位行为 — 自动：同上
- [x] `ThemeControllerScope`（若新增）能让 settings route builder 读取当前 themeName/mode 并调用 `setTheme/setMode`；选择器端到端切换后全树主题更新 — 自动：同上
- [x] 返回按钮 pop/fallback 语义正确 — 自动：同上

> 数据迁移 / 回滚：本 spec 无持久化 schema 变更或数据格式演进（本屏不碰 DB，偏好/统计经外壳与底层 spec）→ 整段省略（不涉及）。

## 回归检查
- [x] Debug Home 仍可正常构建与遍历（设置屏 demo 追加未破坏既有 demo，开关状态本地回写） — 自动：`flutter test test/demo/debug_home_test.dart` + `flutter test test/demo/settings_screen_demo_test.dart`（回归）
- [x] 本次改动路径 `dart analyze` 无新增告警 — 自动：`dart analyze lib/ui/settings lib/demo/settings_screen_demo.dart lib/demo/demo_entry.dart lib/app.dart lib/ui/shell/app_router.dart lib/ui/shell/theme_controller.dart test/ui/settings test/demo/settings_screen_demo_test.dart`（回归）

### 2026-06-06 自动执行记录
- PASS — `flutter test test/ui/settings/ test/demo/settings_screen_demo_test.dart`（14/14）
- PASS — `flutter test test/demo/debug_home_test.dart test/demo/settings_screen_demo_test.dart`（4/4）
- PASS — `dart analyze lib/ui/settings lib/demo/settings_screen_demo.dart lib/demo/demo_entry.dart lib/app.dart lib/ui/shell/app_router.dart lib/ui/shell/theme_controller.dart test/ui/settings test/demo/settings_screen_demo_test.dart`（No issues found）
- PASS — `bash spec-kit/scripts/check_dead_links.sh`
- PASS — `bash spec-kit/scripts/check_specs_index.sh`
- PASS — `git diff --check`
- 非阻塞记录 — `dart analyze`（全仓库）仍退出 2，剩既有 warning/info：`fab_speed_dial.dart` 未用字段、旧 l10n/editor/theme 测试 warning、vendored appflowy/editor 与生成脚本 info；本次 settings 缺文件错误已清除。

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [x] 正向：R1（结构 + 真路由）、R2（主题换肤）、R3（外观换肤）、R4（加密只读）、R5（媒体红线）、R6（回调上抬）、R7（真路由接入 + 返回）、R8（Debug Home）、NF1（样式 / 图标色值 / intl）、NF2（44px 部分覆盖 / Semantics / reduce-motion 后置）、NF3（多端人工后置）、NF4（Repository 边界）均有对应场景/专项检查或维护态后置记录，无孤儿需求。
- [x] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze）已显式标「回归」，未落地的对比度 / golden / 全量几何项已标维护态后置而非虚假通过。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/settings/ test/demo/settings_screen_demo_test.dart
flutter test test/ui/settings/settings_route_test.dart # Routes.settings 真接入 + 返回 + 主题控制器端到端
flutter test test/demo/debug_home_test.dart test/demo/settings_screen_demo_test.dart
dart analyze lib/ui/settings lib/demo/settings_screen_demo.dart lib/demo/demo_entry.dart lib/app.dart lib/ui/shell/app_router.dart lib/ui/shell/theme_controller.dart test/ui/settings test/demo/settings_screen_demo_test.dart
```

> 共享测试基建说明：`test/ui/settings/**/*_test.dart` 与 `test/demo/settings_screen_demo_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；T2 曾预批的 `test/ui/settings/settings_screen.golden` 当前未落地，已作为维护态后置 / advisory 记录，不计入 v1 自动验收通过口径。对比度判定族复用 `design-tokens-theme` 的 `contrast_xfail.yaml` 机器真源（单一来源，不在本 spec 另开第二处）。
