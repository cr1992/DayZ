---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：ui-shell-navigation

> 落「能由外壳/导航组件 widget test 独立验证」的部分：导航行为、换肤全树 rebuild、抽屉/FAB/sheet 交互、无障碍专项、Repository 边界静态核验、token 取色（不硬编码）。参数/几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec 依赖），需 harness 的精确像素观感不在本 spec 重造——本 spec 的几何只断「点击目标尺寸」「遮罩覆盖整屏」「不溢出」这类可由 `tester.getRect/getSize` 直接断言的确定性项。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 路由覆盖全屏 | 逐 `Routes.*` 导航 | 每屏均有占位 Widget 可达、未知路径落 not-found 不崩溃 | R1 | 自动 |
| 抽屉导航 | 开抽屉 → 点浏览组某项 | 经路由导航到对应屏、抽屉关闭 | R2 | 自动 |
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
- [ ] 全外壳可点元素命中区 ≥ 44×44（顶栏菜单/搜索钮、抽屉项、FAB 主键+二级键、sheet 选色钮、设置入口行）— 自动：`flutter test test/ui/shell/a11y_hit_target_test.dart`（`tester.getSize` 逐元素断言 ≥ 44，NF1）
- [ ] 关键交互元素有 Semantics 标签（菜单/搜索/写日记/拍照/语音/纯文字/抽屉项名）— 自动：`flutter test test/ui/shell/a11y_semantics_test.dart`（`find.bySemanticsLabel(ShellStrings.xxx)` 定位，NF3）
- [ ] reduce-motion 下抽屉/FAB/sheet/路由转场退化为即时呈现、无强制过渡 — 自动：`flutter test test/ui/shell/reduce_motion_test.dart`（`MediaQuery(disableAnimations:true)` 下 pump 一帧即终态，NF4）
- [ ] 抽屉/sheet 打开时其内容可被语义遍历到（焦点可达）— 自动：同 semantics 测试（断言打开后内容节点在语义树中）

### 对比度 / token 取色（NF2, NF7）
- [ ] 外壳关键文本（占位屏标题、抽屉项名、设置行）对底 ≥ 4.5:1，有意义 UI（选中态边/图标）≥ 3.0:1，**按实际渲染对算**、六套逐项 — 自动：`flutter test test/ui/shell/shell_contrast_test.dart`（取 `context.dayz` 渲染色算相对亮度比，与 tokens-theme NF1 同口径；已知 expected-fail 复用 `test/ui/theme/contrast_xfail.yaml` 单一真源、阻塞放行报 @Ray，不在本 spec 另建 xfail）
- [ ] 外壳代码视觉值全走 token、无硬编码颜色/字号/间距 — 自动：`flutter test test/ui/shell/no_hardcoded_visual_test.dart`（**断行为而非 grep**：构造两套差异明显的 `DayzColors` 主题各 pump 一次外壳，断言 FAB/抽屉选中态/占位屏关键元素的解析后颜色随主题改变——若硬编码则两套渲染色相同，测试红；NF7）

### Repository 边界（NF5 · 硬红线）
- [ ] 外壳/导航/换肤/抽屉/状态代码不依赖 Drift、不写 SQL — 自动：`flutter test test/ui/shell/repo_boundary_test.dart`（**断依赖图而非 grep 文本**：读 `lib/ui/shell/*.dart` 的 import 集合，断言不含 `package:drift`/`drift/`/项目 Drift DB 包路径；这是「可观测的依赖结构」而非被改文件自身字面）+ 人工 @Ray 复核取数确经 `JournalRepo`/路由参数注入
- [ ] 抽屉 journal 列表、切本、新建日记本均经 `JournalRepo` 或入参/回调注入（无 UI 直查 DB）— 人工（@Ray）

### 多端兼容（NF6）
- [ ] iOS 13+ 真机/模拟器：路由边缘右滑返回、抽屉/FAB/sheet 的 SafeArea 让位、毛玻璃顶栏正常 — 人工（@Ray）
- [ ] Android 8+（minSdk 26）真机/模拟器：返回手势/键、SafeArea 让位、`BackdropFilter` 不崩溃（可接受降级为半透实色）— 人工（@Ray）

> 数据迁移 / 回滚：本 spec 无持久化 schema 变更或数据格式演进（偏好落库经 data-layer 既有入口，schema 归 data-layer）→ 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（shell demo 追加未破坏既有 demo） — 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）
- [ ] `flutter pub get` 通过（新增 `go_router` 不破坏解析） — 自动：`flutter pub get`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（路由覆盖）、R2（抽屉）、R3（切本）、R4（新建 sheet）、R5（FAB）、R6（换肤）、R7（跟随系统）、R8（真外壳）；NF1（44px）、NF2（对比度）、NF3（Semantics）、NF4（reduce-motion）、NF5（Repository 边界）、NF6（多端）、NF7（token 取色）均有场景或专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze / pub get）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter pub get
flutter test test/ui/shell/        # 路由/换肤/抽屉/FAB/sheet/state + a11y/contrast/token/repo-boundary 专项
flutter test test/app_router_mount_test.dart
flutter test test/demo/            # shell demo + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`test/ui/shell/**/*_test.dart`、`test/app_router_mount_test.dart`、`test/demo/shell_nav_demo_test.dart` 均为 `_test.dart`，由白名单 hook 对 `test/**/*_test.dart` 无条件放行、无需预批；各任务 inline `验收基建` 已列其本任务测试文件。对比度 expected-fail 复用 `design-tokens-theme` 的 `test/ui/theme/contrast_xfail.yaml`（单一机器真源，本 spec 只读不另建）。参数/几何精确观感（栅格 SSIM、毛玻璃像素）属 `design-sync-automation` harness，本 spec 不重造。
