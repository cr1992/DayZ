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
