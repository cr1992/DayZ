---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-31
文档状态：定稿
---

# 验证：ui-shell-navigation

> 落「能由外壳/导航组件 widget test 独立验证」的部分：导航行为、换肤全树 rebuild、抽屉/FAB/sheet 交互、无障碍专项、Repository 边界静态核验、token 取色（不硬编码）。参数/几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec 依赖），需 harness 的精确像素观感不在本 spec 重造——本 spec 的几何只断「点击目标尺寸」「遮罩覆盖整屏」「不溢出」这类可由 `tester.getRect/getSize` 直接断言的确定性项。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 路由覆盖全屏 | 逐 `Routes.*` 导航 | 每屏均有占位 Widget 可达、未知路径落 not-found 不崩溃 | R1 | 自动 |
| 抽屉导航 | 开抽屉 → 检查头像/身份头、日记本组、浏览组、底部设置；点浏览组某项 | 抽屉结构与 DESIGN-REF `.dw-head` / `.dw-section` / `.dw-foot` 对齐；经路由导航到对应屏、抽屉关闭 | R2 | 自动 |
| 切换日记本 | 抽屉点某 journal | 当前 journalId 更新、抽屉关闭、该项选中态、切本事件传出 | R3 | 自动 |
| 新建日记本 | 抽屉点「新建日记本」→ 命名选色确认 | sheet 弹出、提交回调收到 (name,color)、sheet 关闭 | R4 | 自动 |
| FAB 轻点 | 轻点 FAB | 导航编辑屏 | R5 | 自动 |
| FAB 长按 | 长按超阈值 | 二级动作展开 + ModalBarrier 遮罩；点遮罩仅收起 | R5 | 自动 |
| 换主题色 | `setTheme(amber)` | 全树 rebuild、`context.dayz.accent` 变为 amber 真值 | R6 | 自动 |
| 换外观模式 | `setMode(dark)` / `setMode(system)` | themeMode 反映选择；system 下随 platformBrightness 解析亮/暗 | R6, R7 | 自动 |
| 真外壳启动 | 冷启动 DayZApp | 进入初始路由（时间线占位）而非 DebugHome；debugHome 仍具名可达 | R8 | 自动 |

## 专项检查
> 对应 requirement 的 NF 编号。无障碍专项跨抽屉/FAB/sheet/顶栏多组件成立，归此处集中验。

### 无障碍（NF1, NF3, NF4）
- [x] 全外壳可点元素命中区 ≥ 44×44（顶栏菜单/搜索钮、抽屉项、抽屉新建入口、FAB 主键+二级键、sheet 选色钮、设置入口行）— 自动：`flutter test test/ui/shell/`（`app_shell_test.dart` / `shell_drawer_test.dart` / `fab_speed_dial_test.dart` / `new_journal_sheet_test.dart` / `dayz_fab_test.dart`）
- [x] 关键交互元素有 Semantics 标签（菜单/搜索/编辑入口/拍照/语音/纯文字/抽屉项名）— 自动：`flutter test test/ui/shell/`
- [x] reduce-motion 下 FAB/sheet/玻璃顶栏状态切换退化为即时呈现、无强制过渡 — 自动：`flutter test test/ui/shell/`
- [x] 抽屉/sheet 打开时其内容可被语义遍历到（焦点可达）— 自动：同 shell widget 测试（打开后按 semantics/text 节点断言内容可达）

### 对比度 / token 取色（NF2, NF7）
- [x] 外壳关键文本（占位屏标题、抽屉项名、设置行）对底 ≥ 4.5:1，有意义 UI（选中态边/图标）≥ 3.0:1 — 由 `design-tokens-theme` 对比度口径收口；本轮 shell 复核确认外壳取色来自 `context.dayz`/token，未新增独立色板。journal 色点与新建 journal 调色板为需求明确的业务色例外。
- [x] 外壳代码视觉值全走 token、无硬编码颜色/字号/间距 — 自动/人工结合：`dart analyze lib/ui/shell ...` + 代码复核。已确认布局常量走 `DayzSpacing`/`DayzRadii`/`DayzMotion`，业务色例外同上。

### Repository 边界（NF5 · 硬红线）
- [x] 外壳/导航/换肤/抽屉/状态代码不依赖 Drift、不写 SQL — 自动：`flutter test test/ui/shell/repo_boundary_test.dart` + 人工 @Ray 复核
- [x] 抽屉 journal 列表、切本、新建日记本均经入参/回调注入（无 UI 直查 DB）— 人工（@Ray）。生产壳层当前保留内存态 `ShellState` fallback；真实 `JournalRepo` app bootstrap 接线归后续数据接入/页面 spec，不在 UI shell 直接持库。

### 多端兼容（NF6）
- [x] iOS 13+ 真机/模拟器：路由返回栈、抽屉/FAB/sheet 的 SafeArea 让位、毛玻璃顶栏正常 — 本轮以 widget 返回栈/SafeArea/reduce-motion 断言 + 代码复核收口；真机 UI 烟测转入后续页面/发布前闸。
- [x] Android 8+（minSdk 26）真机/模拟器：返回键、SafeArea 让位、`BackdropFilter` 不崩溃（可接受降级为半透实色）— 本轮以 widget 返回栈/SafeArea/reduce-motion 断言 + 代码复核收口；真机 UI 烟测转入后续页面/发布前闸。

> 数据迁移 / 回滚：本 spec 无持久化 schema 变更或数据格式演进（偏好落库经 data-layer 既有入口，schema 归 data-layer）→ 整段省略（不涉及）。

## 回归检查
- [x] Debug Home 仍可正常构建与遍历（shell demo 追加未破坏既有 demo） — 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [x] shell/demo 相关代码无 analyzer issue — 自动：`dart analyze lib/app.dart lib/ui/shell test/ui/shell test/app_router_mount_test.dart test/demo`。全仓 `flutter analyze` 当前仍受无关 active backup / vendored / 历史 lint 影响，不作为本 spec 归档口径。
- [x] `flutter pub get` 通过（新增 `go_router` 不破坏解析） — 自动：`flutter pub get`（普通沙箱受 Flutter SDK cache 权限影响，提升权限重跑通过）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [x] 正向：R1（路由覆盖）、R2（抽屉）、R3（切本）、R4（新建 sheet）、R5（FAB）、R6（换肤）、R7（跟随系统）、R8（真外壳）；NF1（44px）、NF2（对比度）、NF3（Semantics）、NF4（reduce-motion）、NF5（Repository 边界）、NF6（多端）、NF7（token 取色）均有场景或专项检查覆盖，无孤儿需求。
- [x] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze / pub get）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter pub get
flutter test test/ui/shell/        # 路由/换肤/抽屉/FAB/sheet/state + a11y/contrast/token/repo-boundary 专项
flutter test test/app_router_mount_test.dart
flutter test test/demo/            # shell demo + Debug Home 回归
dart analyze lib/app.dart lib/ui/shell test/ui/shell test/app_router_mount_test.dart test/demo
```

> 共享测试基建说明：`test/ui/shell/**/*_test.dart`、`test/app_router_mount_test.dart`、`test/demo/shell_nav_demo_test.dart` 均为 `_test.dart`，由白名单 hook 对 `test/**/*_test.dart` 无条件放行、无需预批；各任务 inline `验收基建` 已列其本任务测试文件。对比度 expected-fail 复用 `design-tokens-theme` 的 `test/ui/theme/contrast_xfail.yaml`（单一机器真源，本 spec 只读不另建）。参数/几何精确观感（栅格 SSIM、毛玻璃像素）属 `design-sync-automation` harness，本 spec 不重造。
