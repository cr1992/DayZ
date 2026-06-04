---
作者：@Ray
创建日期：2026-06-04
最后更新：2026-06-04
文档状态：进行中（V2 已通过）
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
| 相册授权选图（T5，后置） | 进编辑器插图 → 选相册 | Patrol 处理 iOS 原生授权弹窗、选图落库 | R2 | 自动 |

## 专项检查

### iOS harness 就绪（R2）
- [x] `patrol test` 在 iPhone 17 模拟器跑通冒烟、1 用例绿 — 自动：证据 `build/ios_results_*.xcresult`、`Total:1 / Successful:1 / Failed:0`
- [x] 直接 `xcodebuild build-for-testing -only-testing:RunnerUITests` 成功（target 配置正确、patrol.framework 正常链接、`@import patrol` 可解析）— 自动
- [x] `RunnerUITests` 已在 `Runner.xcscheme` 的 TestAction（`scheme_testables=RunnerTests, RunnerUITests`，无重复/悬空）— 自动：`scripts/setup_patrol_ios.rb` 输出
- [ ] 干净 checkout 照 T2 文档可从零搭到冒烟绿 — 人工（@Ray），一次性走查

### flaky 防护（R4, R7）
- [ ] T3 wrapper 落地：禁 analytics（盘+env）+ native-asset retry + `Total:N` 非零校验 — 自动（T3 交付后置 [x]）
- [ ] 连续 3 次 wrapper 调用 0 次假崩 — 自动
- [x] 根因记录在案：handshake=patrol_cli 启动遥测 POST google-analytics；asset 重下=独立 derivedDataPath 触发 sqlite3mc dylib 重新下载 — 文档（design.md 成本账）

### 验收方法论（R1, R5, R6）
- [ ] `specs/README.md` 有「验收分层」方法论段（自动化可覆盖 vs 必须人工/不可逆终验）— 自动：grep README（T4 交付后置 [x]）
- [ ] 提供屏 spec `verification.md` 两栏骨架，新屏可无歧义套用 — 人工（@Ray）评审「AI 能否无歧义执行」
- [x] R6 人闸约束写明：加密/备份/还原即便 E2E 绿仍保留人工终验 — 文档（requirement R6）

### 边界 / 不回退（不可逆 & 既有栈）
- [ ] 接入未破坏既有 vanilla `integration_test`（argon2id_ffi 仍走 `flutter test integration_test/`）— 自动（**待跑**：patrol 接入仅增量改动，argon2id 测试文件未动，但尚未重跑确认）
- [ ] 接入未破坏正常 app 构建（`flutter run -d <ios-sim>` 仍可启动；SPM+CocoaPods 混用下 app 正常）— 人工（@Ray）走查一次
- [x] footprint 全部可回退（未提交，集中在 `ios/` 原生工程 + `pubspec` + 新增 `patrol_test/`、`ios/RunnerUITests/`、`scripts/setup_patrol_ios.rb`）— 文档（design.md footprint）

### Android（T6）/ CI（T7）
- [x] Android 模拟器跑通同一冒烟（`Total:1 / Successful:1`）— 自动：含 argon2id 的 Rust 交叉编译 aarch64-linux-android、sqlite3mc android `.so`；首跑偶发 `Total:0`、重跑绿（实证 R7）— 证据 `build/app/reports/androidTests/connected/debug/index.html`
- [ ] CI 接 patrol test（iOS+Android）且非零执行 — 自动（T7，blocked：T3 + R7 守卫）
