# Patrol 端到端原生测试 · 一次性接入 SOP

> 作者：@Ray ｜ 关联 spec：[`specs/active/e2e-harness/`](../specs/active/e2e-harness/)
>
> 本页是**从干净 checkout 把 Patrol harness 搭到冒烟绿**的 step-by-step runbook。
> **为什么这么搭、实测成本账、踩坑根因**见 spec 的 [`design.md`](../specs/active/e2e-harness/design.md)；本页只讲「照着做」。
> 验收口径（哪些项自动 / 哪些必须人工）见 spec 的 [`verification.md`](../specs/active/e2e-harness/verification.md)。

DayZ 的原生面很小（实测只有 `image_picker` 一条真原生链路）。Patrol 是 **E2E 增量层**，只覆盖原生跨界 / 不可逆链路；纯 in-Flutter 行为继续走 widget test。

---

## 0 · 前置

| 项 | 说明 |
|---|---|
| patrol_cli | `dart pub global activate patrol_cli`（实测 4.4.0）。确保 `$HOME/.pub-cache/bin` 在 PATH。 |
| patrol 依赖 | `pubspec.yaml` `dev_dependencies: patrol: ^4.6.1`（带出 `patrol_finders`）。 |
| patrol 配置块 | `pubspec.yaml` 顶层 `patrol:` —— `app_name: DayZ` / `android.package_name: com.dayz` / `ios.bundle_id: com.dayz`。 |
| 目录约定 | 用例放 **`patrol_test/`**（patrol_cli ≥ 4.0 默认），**不是** `integration_test/`（放错触发 `test_bundle.dart` 路径拼接 bug）。vanilla `integration_test/argon2id_ffi_test.dart` 保持不动，两轨互不干扰。 |

> `patrol_test/test_bundle.dart` 是 `patrol test` 每次自动重生成的产物，已在 `.gitignore`，**不入库**。

---

## 1 · iOS 接入（SPM 项目特有，最硬的一段）

DayZ 跑在 Flutter **SPM 模式**（无 Podfile），而 patrol 只支持 CocoaPods → 让 Flutter 为 patrol **自动回落生成 Podfile**，SPM 与 CocoaPods 共存。

```bash
# 1.1 触发 SPM→CocoaPods 回落，生成 ios/Podfile
flutter pub get
flutter build ios --config-only        # 此步生成 ios/Podfile（SPM 项目原本没有）

# 1.2 在 ios/Podfile 的 target 'Runner' 内嵌套 UITest target（手动确认存在；脚本不改 Podfile）
#     target 'Runner' do
#       use_frameworks!
#       use_modular_headers!
#       flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
#       target 'RunnerUITests' do
#         inherit! :complete
#       end
#     end

# 1.3 程序化建 RunnerUITests（UI Testing Bundle）target + 挂进 Runner scheme 的 TestAction。
#     不手改 project.pbxproj（极易崩）。xcodeproj gem 藏在 CocoaPods 的 GEM_HOME 里，系统 ruby
#     默认找不到 → 必须显式指 GEM_HOME。注意 Homebrew 的 Cellar 目录名带修订后缀（如 1.16.2_2），
#     与 `pod --version`（1.16.2）不一致 —— **别用 $(pod --version) 拼路径**。取实际目录名：
GEM_HOME="$(brew --prefix)/Cellar/cocoapods/$(ls "$(brew --prefix)/Cellar/cocoapods" | tail -1)/libexec" \
GEM_PATH="$GEM_HOME" \
  ruby scripts/setup_patrol_ios.rb
#   通用回落（非 Homebrew，如 rbenv/gem 能直接找到 cocoapods 时）：
#     GEM_HOME="$(dirname "$(dirname "$(gem which cocoapods)")")" ruby scripts/setup_patrol_ios.rb
#   脚本幂等：已存在 RunnerUITests 会先删后建，scheme 引用去重，可反复重跑。

# 1.4 装 Pod
cd ios && pod install && cd ..
```

桥接文件 `ios/RunnerUITests/RunnerUITests.m`（已入库）：

```objc
@import XCTest;
@import patrol;
@import ObjectiveC.runtime;
PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
```

关键 build setting（`setup_patrol_ios.rb` 已设）：`TEST_TARGET_NAME=Runner`、`GENERATE_INFOPLIST_FILE=YES`、`CLANG_ENABLE_MODULES=YES`。**不要**硬设 `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES`——让它继承 Pods xcconfig，否则链接告警/隐患。

---

## 2 · Android 接入

```kotlin
// android/app/build.gradle.kts —— defaultConfig 内
testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
testInstrumentationRunnerArguments["clearPackageData"] = "true"
// android 块内
testOptions { execution = "ANDROIDX_TEST_ORCHESTRATOR" }
// dependencies 内（版本跟随 build.gradle.kts，当前 1.5.1）
androidTestUtil("androidx.test:orchestrator:1.5.1")
```

新增 `android/app/src/androidTest/java/com/dayz/MainActivityTest.java`（`PatrolJUnitRunner` 运行期枚举 `patrol_test/` 下 Dart 用例，参数化成 JUnit `@Test`）。

**外部前置**：`argon2id_ffi` 的 Rust 交叉编译（`aarch64-linux-android` 等）在 patrol 构建链里实测可过，前提是 **rustup 接管**（本机 Homebrew rust 已 `brew unlink`）+ 4 个 android target 已装 + NDK 在。交叉编译正确命令见 spec 的 [`design.md`](../specs/active/e2e-harness/design.md) §Android（rustup 接管 + android target + NDK）。

---

## 3 · 跑（永远经 wrapper，别裸调）

```bash
# 列设备
flutter devices            # 或 xcrun simctl list devices booted / adb devices

# iOS 模拟器
bash scripts/patrol_test.sh -d <ios-sim-id>

# 指定单个用例
bash scripts/patrol_test.sh -d <ios-sim-id> --target patrol_test/patrol_smoke_test.dart

# Android 模拟器（首跑偶发 Total:0，wrapper 自动重跑）
bash scripts/patrol_test.sh -d <android-emulator-id>
```

**为什么不裸调 `patrol test`**（[`scripts/patrol_test.sh`](../scripts/patrol_test.sh) 封装了这三件事，对应 spec R4 / R7）：

1. **启动遥测 handshake**（R4-a）：patrol_cli 启动 POST google-analytics，偶发 TLS handshake 崩 CLI（约半数运行）。wrapper 写 `~/.config/patrol_cli/analytics.json` `{"enabled":false}` + 导出 `PATROL_ANALYTICS_ENABLED=false` 双关禁掉。
2. **native asset 重下**（R4-b）：patrol 用独立 `derivedDataPath` 触发 native assets 从零重建 → 重下 `sqlite3mc` 的 iOS dylib / android `.so`（Android 还有 `kotlin-compiler-embeddable` 的 Maven handshake）→ 网络中途断。wrapper 对可重试模式 retry（`PATROL_MAX_RETRIES`，默认 3）。
3. **零执行假阳性**（R7）：patrol_cli 有「0 用例却 all pass」先例 + Android 首跑 `Total:0` 时序抖动。wrapper 解析输出 `Total: N`，**N 缺失或为 0 即判失败**（非零退出），把假绿挡在 CI 闸外。**真实用例断言失败不重试**（避免重试掩盖真 bug）。

只验逻辑、不跑真机：`bash scripts/patrol_test.sh --selftest`。

---

## 4 · 冒烟绿 = 接入成功

`patrol_test/patrol_smoke_test.dart` 直接 `await app.main()` 拉起真实生产入口（开真 SQLCipher 加密库、注册仓储、初始化草稿恢复），再 `$(MaterialApp).waitUntilVisible()` 断言外壳渲染。一举验三件事：原生管线打通、真 app 冷启动、`$` 自动等待可用。

> patrol 约束：用例内**不要**自己调 `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`——DayZ `main()` 调的是基类 `WidgetsFlutterBinding.ensureInitialized()`，与 PatrolBinding 兼容。

期望：`Total: 1 / Successful: 1 / Failed: 0`。iOS 证据落 `build/ios_results_*.xcresult`；Android 落 `build/app/reports/androidTests/connected/debug/index.html`。

---

## 5 · footprint（全部可回退）

`pubspec.yaml`(+patrol 依赖与配置块) / `pubspec.lock` / `ios/Podfile(.lock)`(新) / `ios/Runner.xcodeproj/project.pbxproj` / `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` / `ios/Flutter/{Debug,Release}.xcconfig` / `ios/RunnerUITests/`(新) / `patrol_test/`(新) / `scripts/{setup_patrol_ios.rb,patrol_test.sh}`(新) / `android/app/build.gradle.kts` / `android/app/src/androidTest/java/com/dayz/MainActivityTest.java`(新)。
