---
作者：@Ray
创建日期：2026-06-04
最后更新：2026-06-04
文档状态：进行中（iOS 冒烟管线已跑通）
---

# 设计：e2e-harness（Patrol iOS 接入）

> 本文把 [`requirement.md`](./requirement.md) 的需求钉成实现级决策，并记录**实测成本账**作为「是否/如何推进」的依据。所有决策均来自一次真实落地（已跑通 iOS 冒烟）。

## 技术决策

### D1 · 选 Patrol，且仅在「原生跨界」用，不替换 widget test
- **状态：** 采纳
- **背景：** DayZ 原生面极小（实测只有 `image_picker` 一条真原生链路；无权限插件/通知/WebView/深链/生物识别）。多数"模拟点击"widget test 已能做。
- **选择：** Patrol 作为 **E2E 增量层**，只覆盖原生跨界 / 不可逆链路；in-Flutter 行为继续 widget test。
- **理由：** Patrol 独占价值＝原生自动化；其余场景 widget test 更快更稳、已在 CI。
- **代价：** 团队要同时维护两层测试心智；用 R1 验收分层把边界说清。

### D2 · iOS 用 CocoaPods 回落（patrol 不支持 SPM）
- **状态：** 采纳
- **背景：** DayZ 跑在 Flutter **SPM 模式**（`ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage` 在、无 Podfile）；patrol 只支持 CocoaPods，`flutter pub get` 会警告 `patrol does not support Swift Package Manager`。
- **选择：** 让 Flutter 为 patrol **自动回落生成 Podfile**（`flutter build ios --config-only` 触发），SPM 与 CocoaPods 共存——其余插件留 SPM，patrol 走 Pod。
- **理由：** 不必把整个项目从 SPM 退回 CocoaPods；改动最小。
- **代价：** 项目从"纯 SPM"变"SPM+CocoaPods 混用"，多一套 `ios/Podfile(.lock)` 要维护。

### D3 · UITest target 用 xcodeproj gem 程序化建，不手改 pbxproj
- **状态：** 采纳
- **背景：** patrol iOS 需要一个 `RunnerUITests`（UI Testing Bundle）target，正常是 Xcode GUI 手点；手改 `project.pbxproj`（UUID、build phase、scheme 引用）极易崩。
- **选择：** 固化脚本 [`scripts/setup_patrol_ios.rb`](../../../scripts/setup_patrol_ios.rb) 用 CocoaPods 自带的 `xcodeproj` gem 建 target + 挂 scheme，幂等可重跑。桥接文件 `ios/RunnerUITests/RunnerUITests.m`：
  ```objc
  @import XCTest;
  @import patrol;
  @import ObjectiveC.runtime;
  PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
  ```
- **理由：** 可复现、可 code review、不依赖人点 Xcode。
- **代价：** 依赖 CocoaPods 的 `xcodeproj` gem（藏在其 GEM_HOME，系统 ruby 找不到，脚本头注明调用法）。关键 build setting：`TEST_TARGET_NAME=Runner`、`GENERATE_INFOPLIST_FILE=YES`、`CLANG_ENABLE_MODULES=YES`；**不要**硬设 `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES`（让它继承 Pods xcconfig，否则链接告警/隐患）。Podfile 侧在 `target 'Runner'` 内嵌套 `target 'RunnerUITests' do inherit! :complete end` 并加 `use_modular_headers!`。

### D4 · 冒烟用例形态 = 启动真 app + `$` finder
- **状态：** 采纳
- **选择：** `patrol_test/patrol_smoke_test.dart` 直接 `await app.main()` 拉起真实生产入口，再用 `$(MaterialApp).waitUntilVisible()` 断言外壳渲染。
- **理由：** 一举验证三件事——Patrol 原生管线打通、真 app 冷启动（含 SQLCipher 加密库真初始化）、`$` 自动等待可用。
- **代价：** `main()` 会开真加密库、在模拟器落盘真 DB；可接受（正是要测的真实路径）。注意 patrol 约束：用例内**不要**自己调 `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`（DayZ `main()` 调的是基类 `WidgetsFlutterBinding.ensureInitialized()`，与 PatrolBinding 兼容）。

### D5 · flaky 防护固化（见 R4/R7）
- **状态：** 采纳
- **选择：**
  - analytics 双关：写 `~/.config/patrol_cli/analytics.json` = `{"enabled":false,...}` + 跑测时带 `PATROL_ANALYTICS_ENABLED=false`。
  - sqlite3mc native asset 稳定缓存：运行入口给 Flutter tool 注入 `--deterministic`，稳定 `sqlite3` hook 的 `download-*` 目录，复用 `.dart_tool/hooks_runner/shared` 下的 sqlite3mc 缓存；`PATROL_NO_DETERMINISTIC_HASH=1` 可临时关闭。
  - native asset / Maven 下载失败：运行入口对 `Building native assets failed` / `Connection closed while receiving data` / download handshake 类错误 retry。
  - CI 前置：解析 patrol 输出 `Total: N` 校验非零（防静默假阳性）。
- **理由：** 实测两类 flaky 各废过运行（handshake 约半数崩、sqlite3mc dylib 下载中途断）。2026-06-06 复盘确认 `sqlite3` 3.3.x hook 的 `PrebuiltSqliteLibrary.dirname` 基于 `Object.hash`，默认跨 Dart VM 进程不稳定，导致 shared-cache 被绕开、`.dart_tool/hooks_runner/shared/sqlite3/build/` 堆多个等价 `download-*` 目录；`dart --deterministic` 可稳定同一目标的目录名。
- **代价：** 运行需包一层 wrapper（见 tasks T3），不能裸调 `patrol test`；wrapper 会默认影响 Flutter tool 的 VM hash 随机性，仅限测试构建链路。

### D6 · Android 已跑通，CI 后置
- **状态：** Android 采纳（已实测跑通）；CI 暂缓
- **背景：** 先 iOS（既有 `integration_test` 的验证目标、构建已证可行），Android 随后补、已补上。
- **选择 / 实测：** Android 接法＝`android/app/build.gradle.kts` 加 `testInstrumentationRunner = PatrolJUnitRunner` + `testInstrumentationRunnerArguments["clearPackageData"]="true"` + `testOptions { execution = "ANDROIDX_TEST_ORCHESTRATOR" }` + `androidTestUtil orchestrator`；新增 `android/app/src/androidTest/java/com/dayz/MainActivityTest.java`（`PatrolJUnitRunner` 枚举 Dart 用例）。`argon2id_ffi` 的 Rust 交叉编译（aarch64-linux-android）在 patrol 构建链里**实测通过**——前提是 rustup 接管（rust 已 `brew unlink`）、4 个 android target 已装、NDK 在（[[reference_rust_cross_compile]]）。
- **代价：** Android 多两处网络抖动（kotlin-compiler-embeddable 的 Maven handshake、sqlite3mc android `.so`），retry 兜底；**首跑偶发 `Total:0`（app-service 时序），重跑即绿——实证 R7 守卫必要**。CI 仍暂缓：需 D5 三类防护 + R7 跑稳。

### D7 · 测试隔离 + 产物清理：iOS 容器重置（追平 Android clearPackageData）
- **状态：** 采纳（@Ray 拍板：harness 容器重置；**不**在加密数据路径上开测试缝）
- **背景：** `AppDatabase.open()` 把 DB 路径硬编码成 `getApplicationDocumentsDirectory()/db/main.sqlite`（`lib/data/database.dart:103`，无 env/test 覆写缝）；patrol 跑 `main()` 会把**真·生产加密 DB/媒体**落进模拟器容器的生产路径、**跨次留存**。Android 已每用例清（`clearPackageData=true` + Orchestrator），iOS 无等价机制 → 残留污染下次跑（顺序依赖型 flaky）+ 隐私卫生。
- **选择：** 三选一里取 **harness 数据容器重置**（弃「生产加 `DAYZ_DATA_DIR` 测试缝」与「仅用例 teardown」）：`scripts/patrol_test.sh` 检测到目标是 iOS 模拟器时，跑前（及绿后）清 app 的**数据容器**（`xcrun simctl get_app_container <ios-sim> com.dayz data` 后清其内容，**保留 app 安装、不卸包**——精确对齐 Android `clearPackageData`；早期实现曾用 `simctl uninstall`，因「连 app 一起卸、比 clearPackageData 更激进」改为只清数据）；并修剪旧 `build/ios_results_*.xcresult`（保留最近 `PATROL_KEEP_XCRESULTS`，默认 3）。`PATROL_NO_RESET=1` 可关；非 iOS/Android/真机目标全程 no-op。
- **理由：** 零生产代码改动；**不在加密数据面开环境变量缝**（安全面更干净，对加密 app 是有意识的取舍）；与 Android clean-slate 对齐。红跑保留现场便于 post-mortem。
- **代价：** 粒度 = 每次跑（非每用例）；将来并行多用例需另解（当前单用例够用）。依赖 booted 模拟器——app 未安装时 `get_app_container` 取不到数据容器即跳过（无害）；清理只 `rm` 形如 `*/Containers/Data/Application/*` 且真实存在的路径（严格护栏防误删）。可测性靠 `PATROL_FORCE_IOS_SIM` / `PATROL_RESULTS_GLOB` 注入缝（+ stub `xcrun` 指向临时容器），stub 驱动即可验「清数据保留容器目录」「非容器路径拒删」「xcresult 修剪」而不碰真机。

## 成本账（实测 · DayZ iOS）

| 环节 | 实际 | 成本 |
|---|---|---|
| 装 cli + 加依赖 | `patrol_cli 4.4.0` + `patrol 4.6.1`/`patrol_finders 3.5.0` | 低 |
| SPM 无 Podfile → CocoaPods 回落（D2） | 项目变 SPM+CocoaPods 混用 | 中（SPM 项目特有） |
| 建 UITest target（D3） | xcodeproj 程序化，最硬一步 | 中高 |
| patrol_cli 4.0 目录破坏性改动 | 用例须放 `patrol_test/`，放错触发 bundle 路径 bug | 低但坑 |
| flaky·启动遥测 handshake | 约半数运行崩，禁 analytics 才稳 | 中（CI 杀手） |
| flaky·sqlite3mc native asset 重下 | sqlite3 hook 目录 hash 默认跨 VM 不稳定，曾绕开 shared-cache 反复下载；wrapper 注入 `--deterministic` 稳定缓存，retry 只兜底下载中断 | 中（DayZ 特有） |
| iOS 跑通 | 冷构建 ~98s / 增量 ~20–40s / 测试 ~26s，1 用例模拟器绿 | — |
| Android·Rust 交叉编译 | argon2id aarch64-linux-android 在 patrol 链里实测过（rustup 接管前提下） | 低（工具链已就绪） |
| Android·网络抖动 | kotlin-compiler-embeddable 的 Maven handshake、sqlite3mc android `.so` 首次缓存 | 中（deterministic cache + retry 兜底） |
| Android·首跑 `Total:0` | app-service 时序抖动，重跑即绿 | 低但实证 R7 必要 |
| Android 跑通 | apk 冷构建 ~178s / 测试 ~52s，1 用例模拟器绿 | — |

## 文件变更

本 spec 涉及（**任务「可改文件」白名单的唯一来源与上界**）：

- `pubspec.yaml` / `pubspec.lock`  修改（加 patrol 依赖 + `patrol:` 配置块）
- `ios/Podfile` / `ios/Podfile.lock`  新建（SPM 回落生成 + 嵌套 RunnerUITests）
- `ios/RunnerUITests/RunnerUITests.m`  新建（patrol 桥接）
- `ios/Runner.xcodeproj/project.pbxproj`  修改（RunnerUITests target）
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`  修改（UITest 挂进 TestAction）
- `ios/Flutter/Debug.xcconfig` / `ios/Flutter/Release.xcconfig`  修改（CocoaPods include）
- `android/app/build.gradle.kts`  修改（PatrolJUnitRunner + Orchestrator + androidTestUtil 依赖）
- `android/app/src/androidTest/java/com/dayz/MainActivityTest.java`  新建（Dart 用例枚举入口）
- `patrol_test/patrol_smoke_test.dart`  新建（冒烟用例）
- `scripts/setup_patrol_ios.rb`  新建（xcodeproj 程序化建 UITest target）
- `scripts/patrol_test.sh`  新建（flaky 防护 + 零执行守卫 wrapper + R8 iOS 数据容器清理/产物修剪）
- `docs/patrol-e2e-onboarding.md`  新建（一次性接入 runbook）
- `.gitignore`  修改（忽略 patrol 生成的 `test_bundle.dart`）
- `specs/README.md`  修改（注册 + 验收分层方法论）
- `specs/active/e2e-harness/verification-skeleton.md`  新建（屏 spec 验收两栏骨架）
- `AGENTS.md`  修改（上下文索引 + 规则 + flaky 踩坑）
- `spec-kit/spec-guide.md`  修改（验收段指针）
- `.github/workflows/`  新建（T7 CI，后置）

## 已知风险

- **CI 未接（T7）**：两类 flaky + 静默假阳性使 CI 接入非平凡；`scripts/patrol_test.sh` 已封防护，但 live 连跑稳定性待 @Ray 实证。
- **image_picker 原生 E2E 未写（T5）**：patrol 唯一独占价值（相册授权）尚未落用例，依赖 `editor-integration-screen` + `media-storage`。
- **vendored appflowy-editor 内部测不到**：patrol 把编辑器当 widget 驱动，碰不到 fork 内部（原生 IME / 拼写 / 剪贴板）。
- **SPM + CocoaPods 混用**：为 patrol 引入 Podfile 回落，多一套依赖管理；升级 Flutter / 插件时注意两套并存。
- **patrol 单一供应商 + 原生 selector 脆**：跨 OS 版本 / 语言（DayZ 双语）原生 selector 易漂，坚持 Key 定位、勿按文本。
- **iOS 容器重置是 suite 级（D7/R8）**：跑前清一次容器，粒度非每用例；多用例同跑时用例间不互相隔离，将来若写多个有状态 E2E 需补每用例 teardown 或拆跑。

## 范围外（实现层）
- 不在本 spec 写各屏 E2E；只交付冒烟样例 + 目录 / 契约。
- 不在本 spec 接 CI（T7，见已知风险）。
