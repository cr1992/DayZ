---
作者：@Ray
创建日期：2026-06-04
最后更新：2026-06-04
文档状态：进行中（iOS 冒烟管线已跑通）
---

# e2e-harness（端到端原生测试基建 · Patrol）

## 背景

现有测试栈是 **widget/unit 为主**（~154 个 `flutter_test` 用例 + 1 个 vanilla `integration_test`），它们覆盖了绝大多数 in-Flutter 行为，但**碰不到原生边界**：相册授权选图、真机文件 IO、Keychain、SQLCipher 落盘、前后台切换、软键盘/IME。这些链路当前的验收最终落在**人工真机走查**（如 `backup-full-snapshot` 的「待 @Ray 真机演示/回归确认」、`ui-kit-components` 的「画廊目检」），其中**功能回归**那一截是机械重复、可自动化的。

本 spec 把 **Patrol（XCUITest 驱动的原生自动化）** 工件化为一套可复用基建：一次性趟通 iOS 原生接入（SPM 回落、UITest target、flaky 防护），让未来需要原生 E2E 的屏 spec **依赖本 spec** 而非各自重踩原生配置坑。同时把「验收标准」从"靠人走查"演进为**"自动化覆盖功能回归 + 人工只守设计目检与不可逆终验"**。

> 实测成本与决策依据见 [`design.md`](./design.md) §成本账。结论：接入**非一次性轻活**（SPM 回落 + 建 UITest target + 两类 flaky，其中两条与 DayZ 技术栈强相关），但**搭通后可稳定复用**。

## 范围外

- **各屏具体 E2E 用例内容** —— 随各屏 spec 落；本 spec 只定**目录约定、harness 形态、验收分层契约**，并交付一个跑通的冒烟样例。
- **设计 / 手感目检** —— 像素对齐、间距、配色、动画手感、文案语境，Patrol 替不掉，仍走人工（见 [design-sync-automation](../design-sync-automation/) 四层闸）。
- **替换现有 154 个 widget/unit 测试** —— 不替换。E2E 是**增量层**，跑得慢得多，纯 in-Flutter 逻辑继续用 widget test。
- **CI 接入** —— 后置（W4）。需先把 patrol_cli 的 flaky（R4）跑稳 + R7 零执行守卫到位。注：Android 冒烟**已在本 spec 跑通**（含 `argon2id_ffi` 的 Rust 交叉编译 aarch64-linux-android），不再属范围外。
- **`patrol_finders` 单测用法** —— 在普通 widget test 里用 `$` 语法是**可选的轻量改进**（零原生配置），与本 spec 的原生 E2E 正交，不在此强制。

## 功能需求

### R1 · 验收分层契约
屏 / 功能 spec 的 `verification.md` SHALL 把验收项显式切成两类，不得混写：
- **自动化可覆盖**：widget test 或 Patrol E2E 能断言的功能/回归项。
- **必须人工**：设计目检（手感/像素）与**安全·不可逆链路的终验**（加密/备份/还原）。

判据：纯 in-Flutter 行为 → widget test 即可，不要求 Patrol；**有原生跨界或不可逆副作用**的链路 → 标注「需 E2E」并指向本 harness。

### R2 · iOS harness 就绪（本 spec 主交付）
`patrol test` SHALL 能在 iOS 模拟器上跑通 `patrol_test/` 下的用例，启动**真实** DayZ 生产入口（`main()`，含 SQLCipher 加密库初始化）。交付证据 = 冒烟用例 `patrol_test/patrol_smoke_test.dart` 在 iPhone 模拟器上绿（见 [`verification.md`](./verification.md) V2）。

### R3 · 测试目录约定
Patrol 用例 SHALL 放在 `patrol_test/`（patrol_cli ≥ 4.0 的默认目录）；vanilla `integration_test/`（如 `argon2id_ffi_test.dart`）**保持不动**。两条轨道互不干扰。

> 约束来源：patrol_cli 4.0 把默认测试目录从 `integration_test/` 改为 `patrol_test/`；把 patrol 用例放进 `integration_test/` 会触发 `test_bundle.dart` 的导入路径拼接 bug（实测）。

### R4 · flaky 防护（采纳本 spec 即必须固化）
harness SHALL 对 patrol_cli 两类已知 flaky 提供确定性防护：
- **启动遥测 handshake**：禁用 analytics（`~/.config/patrol_cli/analytics.json` 置 `enabled:false` 且 `PATROL_ANALYTICS_ENABLED=false`），避免 google-analytics 的 TLS handshake 偶发崩 CLI。
- **native asset 重下**：patrol 用独立 `derivedDataPath` 触发 native assets 从零重建 → 重新下载 `sqlite3mc` 的 iOS dylib → 网络中途掐断。运行入口 SHALL 对该失败 retry。

### R5 · DoD 升级（差异化，不一刀切）
屏 spec 的「交付」定义 SHALL 升级为：
- **有原生跨界 / 不可逆副作用**的链路 → 加一条「主链路 E2E 冒烟通过」。
- **纯 in-Flutter** 的链路 → 维持 widget test 基线，**不**强制 E2E。

### R6 · 安全 / 不可逆链路保留人闸
即使 E2E 全绿，加密 / 备份 / 还原等**不可逆**链路 SHALL 保留人工终验。理由：patrol_cli 有**静默假阳性**先例（"0 用例却全 pass"）+ iOS 模拟器 CI flaky；对命根子数据，绿勾不足以撤掉人闸。

### R7 · 防静默假阳性（CI 前置）
接入 CI 前，harness SHALL 断言「**确实跑了 ≥ N 个用例**」（解析 patrol 输出的 `Total:` 计数并校验非零），把"全 pass 但零执行"挡在闸外。

### R8 · 测试隔离与产物清理
E2E 跑测 SHALL NOT 向后续运行泄漏持久化的设备 app 状态（残留的真加密 DB/媒体会污染下一次跑、造成顺序依赖型 flaky，对加密 app 还是隐私卫生问题），且测试产生的产物 SHALL NOT 提交入库：
- **iOS 状态隔离**：iOS 无 Android 的 `clearPackageData`（Android 已每用例清数据），故运行入口 SHALL 在跑前（及绿后）清 app 容器（`xcrun simctl uninstall <ios-sim> com.dayz`），使每次跑干净起步——追平 Android 的 clean-slate。红跑可保留现场供 post-mortem（下次跑前再清）。
- **产物清理**：patrol 生成的 `test_bundle.dart` SHALL gitignore（不入库）；主机构建产物（`build/ios_results_*.xcresult` 等）SHALL 受控修剪、一律不提交。

判据：纯无状态冒烟可不强清；**有状态 E2E**（插数据 / 落库）的链路 SHALL 保证起始态干净（容器重置或用例 teardown）。

## 非功能需求

### NF1 · 多端兼容
同一冒烟用例 MUST 在 iOS 模拟器（iPhone）与 Android 模拟器（API 36）**双端**跑通，各报 `Total:1 / Successful:1 / Failed:0`。度量：两端经 wrapper 跑 `patrol test` 退出 0 且 `Total` 非零。

### NF2 · 防假阳性（可靠性）
flaky 防护 wrapper MUST 在 `Total:0`（零执行）时以非零码退出；对已知可重试模式（启动 handshake、native-asset/Maven 下载中断、Android 首跑 `Total:0`）MUST 自动重试，默认上限 3 次（`PATROL_MAX_RETRIES`）；真实用例断言失败 MUST NOT 重试（不得掩盖真 bug）。度量：`scripts/patrol_test.sh --selftest` 对 stub patrol 的四类控制流（pass / 假绿 / 真失败 / flaky）行为符合预期。

### NF3 · 安全（真加密 + 人闸）
harness 启动真实生产入口 `main()` 时 MUST 走真实 SQLCipher 加密库初始化（不 mock 加密层）；加密 / 备份 / 还原等不可逆链路即便 E2E 全绿 MUST 保留人工终验（见 R6）。度量：冒烟经真实 `AppDatabase.open` 落盘；不可逆链路 verification 项标「人工（@Ray）」。

## 选档（标准档）

专项 5 维逐维表态（任一为「是」即标准档）：

| 维度 | 命中 | 依据 |
|---|---|---|
| 安全 | 是 | 启动真实 SQLCipher 加密库；R6 / NF3 守不可逆链路人闸 |
| 权限 | 是 | T5 测 iOS 相册授权弹窗（原生权限自动化是 patrol 核心独占场景）|
| 无障碍 | 否 | 本 spec 是测试基建，不涉 UI 无障碍 |
| 性能 | 否 | 构建 / 测试耗时仅记录在 design 成本账，不立性能 NF 约束 |
| 多端兼容 | 是 | iOS + Android 双端 harness（NF1）|

跨多模块：design `## 文件变更` 落在 `ios/`、`android/`、`scripts/`、`patrol_test/`、`specs/` 等多个顶层目录。→ **标准档**（含 verification.md）。
