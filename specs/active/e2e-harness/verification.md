---
作者：@Ray
创建日期：2026-06-04
最后更新：2026-06-04
文档状态：进行中（V2 通过；T2/T3/T4 工件交付，wrapper 逻辑自验过；live 连跑/干净 checkout/CI 留人闸与后置）
---

# 验证：e2e-harness

> 跨任务校验。命中：原生测试管线、flaky 防护、验收方法论。本 spec 自身也吃自己的狗粮——验收项按 R1 分「自动 / 人工」两栏。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| iOS 冒烟跑通 | `patrol test -d <ios-sim>`（经 T3 wrapper） | 真 app 冷启动（SQLCipher 初始化）、`$(MaterialApp).waitUntilVisible` 绿、`Total:1 Successful:1` | R2 | 自动 |
| 目录约定 | patrol 用例置于 `patrol_test/` | bundle 生成无路径拼接报错；`integration_test/argon2id_ffi_test.dart` 不受影响仍可 `flutter test` | R3 | 自动 |
| handshake 防护 | 禁 analytics 后连跑 3 次 | 无一次因 google-analytics TLS handshake 崩在启动 | R4 | 自动 |
| native asset 重下防护 | 清 `build/ios_integ` 后跑 | dylib 下载中断被 retry，最终构建成功 | R4 | 自动 |
| 零执行拦截 | 构造 0 用例运行 | wrapper 解析 `Total:0` → 非零退出、判失败 | R7 | 自动 |
| 测试隔离/产物清理 | 经 wrapper 跑 iOS 模拟器目标 | 跑前/绿后清 app 数据容器（保留安装、对齐 clearPackageData）；旧 xcresult 修剪保留最近 N；非 iOS 目标 no-op | R8 | 自动 |
| 相册授权选图（T5，后置） | 进编辑器插图 → 选相册 | Patrol 处理 iOS 原生授权弹窗、选图落库 | R2 | 自动 |

## 专项检查

### iOS harness 就绪（R2）
- [x] `patrol test` 在 iPhone 17 模拟器跑通冒烟、1 用例绿 — 自动：证据 `build/ios_results_*.xcresult`、`Total:1 / Successful:1 / Failed:0`
- [x] 直接 `xcodebuild build-for-testing -only-testing:RunnerUITests` 成功（target 配置正确、patrol.framework 正常链接、`@import patrol` 可解析）— 自动
- [x] `RunnerUITests` 已在 `Runner.xcscheme` 的 TestAction（`scheme_testables=RunnerTests, RunnerUITests`，无重复/悬空）— 自动：`scripts/setup_patrol_ios.rb` 输出
- [ ] 干净 checkout 照 T2 文档可从零搭到冒烟绿 — 人工（@Ray），一次性走查（文档已就绪：`docs/patrol-e2e-onboarding.md`）

### flaky 防护（R4, R7）
- [x] T3 wrapper 落地：禁 analytics（盘+env）+ Flutter tool deterministic 注入稳定 sqlite3mc hook cache + native-asset/Maven/Android-Total:0 retry + `Total:N` 非零校验 — 自动：`scripts/patrol_test.sh`
- [x] wrapper 逻辑静态自验（**静态层；真机实证见下条**）：`bash -n` 语法过；`--selftest` 验 deterministic 注入（保留既有参数 / 不重复 / 可关闭）、解析+零执行守卫过；对 stub `patrol` 跑全控制流 8 例均符合预期——pass→exit0/1att；假绿 Total:0→R7 拦截 exit1/重试用尽；真断言失败 Failed≥1（含 status=0 坏退出码、报错文本含 "timed out" 的）→exit1/1att **绝不重试**；Failed 行缺失→fail-closed 重试后判失败；非 infra 非零→exit1/1att 不重试；flaky→重试恢复 exit0/2att — 自动（无需真机）
- [ ] 连续 3 次 **live**（真机/模拟器）wrapper 调用 0 次假崩 — 自动·**待实跑**（命令就绪、逻辑已静态自验；缺真 patrol + 真网络抖动下的实证，由 @Ray 在真机/模拟器跑 3 次确认）
- [x] 根因记录在案：handshake=patrol_cli 启动遥测 POST google-analytics；sqlite3mc 重下=`sqlite3` 3.3.x hook 的 `download-*` 目录 hash 默认跨 VM 进程不稳定、绕开 shared-cache — 文档（design.md 成本账）

### 测试隔离 + 产物清理（R8）
- [x] R8 落地 wrapper：iOS 目标跑前/绿后清 app **数据容器**（`get_app_container ... data` 后清内容、**保留安装**，对齐 Android `clearPackageData`）+ 旧 xcresult 修剪 + 非 iOS/真机目标 no-op — 自动：`scripts/patrol_test.sh`
- [x] 静态自验（stub 驱动，无需真机）：`-d fake`→R8 全程 no-op；stub `xcrun` 指向临时数据容器→清内容但保留容器目录（app 不卸）、非 `*/Containers/Data/Application/*` 路径**拒删**（rm 护栏）；`PATROL_RESULTS_GLOB` 注入 5 假 xcresult/keep=3→修剪剩最新 3；真 booted UDID 命中 `simctl list`（检测正向）、`fake` 不命中（负向）— 自动
- [x] patrol 生成的 `test_bundle.dart` 不入库 — 自动：`git check-ignore patrol_test/test_bundle.dart` 退 0
- [ ] live 真机/模拟器跑后 app 仍在、其数据已清（无残留真加密 DB）— 人工（@Ray），与 flaky live 连跑合并走查

### 验收方法论（R1, R5, R6）
- [x] 「验收分层」方法论已落文档（**doc 交付，非自动断言**）：`specs/README.md` §验收分层 blockquote + `AGENTS.md` 规则段，并指向可复制骨架 `verification-skeleton.md`。**可套用性**的最终判定见下一条 @Ray 评审
- [ ] 提供屏 spec `verification.md` 两栏骨架，新屏可无歧义套用 — 骨架已交付（`verification-skeleton.md`）；可无歧义套用的最终判定（「AI 能否无歧义执行」）待 @Ray 评审
- [x] R6 人闸约束写明：加密/备份/还原即便 E2E 绿仍保留人工终验 — 文档（requirement R6）

### 边界 / 不回退（不可逆 & 既有栈）
- [ ] 接入未破坏既有 vanilla `integration_test`（argon2id_ffi 仍走 `flutter test integration_test/`）— 自动·**待跑**（patrol 接入未动 argon2id 测试文件，但**必须实跑确认**，不得以「仅增量改动」推断通过）
- [ ] 接入未破坏正常 app 构建（`flutter run -d <ios-sim>` 仍可启动；SPM+CocoaPods 混用下 app 正常）— 人工（@Ray）走查一次
- [x] footprint 全部可回退（未提交，集中在 `ios/` 原生工程 + `pubspec` + 新增 `patrol_test/`、`ios/RunnerUITests/`、`scripts/setup_patrol_ios.rb`）— 文档（design.md footprint）

### Android（T6）/ CI（T7）
- [x] Android 模拟器跑通同一冒烟（`Total:1 / Successful:1`）— 自动：含 argon2id 的 Rust 交叉编译 aarch64-linux-android、sqlite3mc android `.so`；首跑偶发 `Total:0`、重跑绿（实证 R7）— 证据 `build/app/reports/androidTests/connected/debug/index.html`
- [ ] CI 接 patrol test（iOS+Android）且非零执行 — 自动（T7，blocked：T3 + R7 守卫）
