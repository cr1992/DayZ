---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
---

# dayz-security-rust（自研 Argon2id / HKDF 库 · argon2id_ffi）

## 背景

DayZ 需要在 iOS+Android 上跑 Argon2id（主密码 KDF）。现有选项各有硬伤：纯 Dart argon2
移动端慢到秒级（违反 NF1）；`dargon2_flutter`（C FFI）快但 ~2 年失维、且 iOS pod 漏标
`ffiPlugin:true` 致符号剥离，目前靠 `ios/Podfile` 一段运行期 force-load hack 才跑通。

本里程碑自研一个**最小、可发布到 pub 的 native KDF 库 `argon2id_ffi`**：RustCrypto
（argon2/hkdf，活跃 + 经审计 + 原生 zeroize）+ **手写 `dart:ffi`**（C-ABI，无 flutter_rust_bridge）
+ cargokit 交叉编译。既满足 DayZ 自身需求，也填补 pub 生态空缺。

> **诚实定调**：性能**不是**换库理由——dargon2 已实测 498ms 达标（key-management T3）。真实
> 动因是**可维护性 + 构建可控 + 最小依赖可发布**。NF1 因此是"不得回退"的护栏而非要解决的缺陷。

## 范围外

- 主密码 / 加密设置 UI（属设置页与外壳 spec）；数据库加解密逻辑（属 `data-layer`）。
- **DayZ 生产接入（已落地 2026-05-30）**：`lib/security/argon2_kdf.dart` 后端已切到 argon2id_ffi、
  移除 `dargon2_flutter` 与 `ios/Podfile` 的 force-load hack、删除 `argon2_probe.dart`。验证：Argon2Kdf
  KAT 字节兼容 6/6、iOS 模拟器 + Android profile/AOT 在真实 app 内跑通。**唯一待补**：iOS 真机 archive/TestFlight
  符号留存最终确认（iOS 模拟器不跑 AOT、需实机；macOS profile/AOT 已作强代理验证）。
- **接入 key-management 的 `getDeviceMediaKey` / `hkdf.dart`**：HKDF 的生产实现归属 key-management
  （D7/T10，纯 Dart）。本库的 HKDF 是通用能力暴露，**不接入、不替换**它。

## 功能需求

### R1 · Argon2id
库 MUST 暴露异步 Dart API `argon2idDeriveKey`（手写 `dart:ffi` → C-ABI `argon2id_ffi_derive`）。
- 输入：`password`(Uint8List)、`salt`(Uint8List, ≥8B)、`mCost`(KiB)、`tCost`、`parallelism`、`outputLen`(∈[16,1024])
- 结果：返回派生密钥(Uint8List)；相同入参确定性一致；非法入参**抛 `Argon2idFfiException` 而非静默**。
- 重活在 `Isolate` 内执行，不阻塞 UI。

### R2 · HKDF-SHA256（通用能力，不接入生产）
库 MUST 暴露 `hkdfSha256DeriveKey`（→ C-ABI `hkdf_sha256_ffi_derive`）。
- 输入：`ikm`(Uint8List)、`salt`(Uint8List?，null=RFC5869 全零 salt)、`info`(Uint8List)、`outputLen`
- 结果：对齐 RFC 5869。
- **约束**：不替换 key-management 的纯 Dart `lib/security/hkdf.dart`、不接入 `getDeviceMediaKey`（见 D6）。

### R3 · 双端编译与链接
库 MUST 能为 iOS（真机+模拟器）和 Android（真机+模拟器）交叉编译并链接。
- cargokit 把构建胶水（podspec/gradle）注入工程；iOS anti-strip 由生成的 `ios/argon2id_ffi.podspec`
  接好（`-force_load …libargon2id_ffi.a` + `script_phase` + `Classes/dummy_file.c`），Rust 侧 C-ABI 函数
  加 `#[no_mangle]` + `#[used]`。**debug 假绿、release/archive 才暴露剥离**——R3 验收必须覆盖 release/archive。

### R4 · 敏感内存擦除（best-effort）
- Rust 侧 MUST 对入参 `password` / `ikm` 的 `Vec` **显式** `zeroize`；argon2 `zeroize` feature 擦内部块。
- **边界（非端到端）**：派生结果需返回不能擦；`dart:ffi` 把 Dart `Uint8List` 拷成 native 缓冲后才进
  Rust，**Dart 侧原 `Uint8List` 由 GC 托管、擦不到**。调用方负责清 Dart 侧。

## 非功能需求

### NF1 · 性能回归门槛
v0 参数（m=64MiB, t=3, p=1, len=32）下，中端移动**真机** release 单次中位耗时 MUST < 1.5s，
且不得劣于 dargon2 基线（498ms 同环境对照）。已知（工作机 aarch64）：比 C 快 ~1.29×（见 `BENCHMARK.md`），真机数待补。

### NF2 · 包体积增量
**单架构**安装包体积增量 SHOULD ≤ 3MB。已实测 cdylib（DCE+strip）：**iOS 0.317MB / Android 0.333MB**
（余量 ~9×）。验收以 `flutter build appbundle --analyze-size` 真机整包口径为准。

## 专项维度逐维表态（选档依据）

> 涉及底层安全 + 多端 FFI 交叉编译，升**标准档**。

| 专项维度 | 命中？ | 依据 |
|---|---|---|
| 安全 | 是 | 密码学核心 + 显式内存擦除（R4，含诚实边界）+ 输入校验。 |
| 权限 | 否 | 无权限逻辑。 |
| 无障碍 | 否 | 纯算法库，无 UI。 |
| 性能 | 是 | 有 <1.5s 门槛（NF1，不得回退），已同机实测留痕。 |
| 多端兼容 | 是 | iOS/Android 双端交叉编译 + FFI 链接（R3），iOS 需 anti-strip。 |
