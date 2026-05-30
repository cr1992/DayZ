---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
---

# 验证：dayz-security-rust（argon2id_ffi）

## 功能验证（端到端）

| 场景 | 操作 | 预期 | 关联 | 方式 | 状态 |
|------|------|------|------|------|------|
| Argon2id 正确性（Rust 层） | 4 组 KAT 对 argon2-cffi(P-H-C C) | 逐字节一致 | R1 | `cargo test` | ✅ 7/7 |
| HKDF 正确性（Rust 层） | RFC 5869 §A Case 1/2/3 | 逐字节一致 | R2 | `cargo test` | ✅ |
| 手写 ffi 端到端（Dart 层） | host 加载 dylib，调 argon2/hkdf | Dart 得到与 Rust 逐字节一致 | R1,R2 | `flutter test` | ✅ 6/6 |
| DayZ Argon2Kdf 接入（host） | 主工程经 `ARGON2ID_FFI_LIB` 加载 release dylib | KAT 字节兼容、确定性、salt 敏感、Dart password buffer 清零 | R1,R4 | `flutter test test/security/argon2_kdf_test.dart` | ✅ 4/4 |
| 错误路径 | salt 过短 / 越界 | 抛 `Argon2idFfiException` 而非静默 | R1 | Rust+Dart | ✅ |
| 空口令 / None salt 边界 | 空数组 / salt=null | 字节正确 | R1,R2 | `flutter test` | ✅ |
| 双端交叉编译 | iOS arm64/sim + Android arm64 | 链接成功、产物对应架构 | R3 | `cargo build --target` | ✅ |
| 内存擦除（R4） | 见专项 | 入参 Vec 被显式 zeroize | R4 | 单测 | best-effort |

## 专项检查

### R4 · zeroize（结果级，非"看源码"）
- [x] Rust 侧对入参 `password/ikm` Vec 显式 `zeroize`；可加 `#[cfg(test)]` 断言擦后字节全 0（best-effort，编译器可能优化）。
- [x] 文档已声明非端到端：派生结果不擦、Dart 侧 `Uint8List` GC 托管擦不到（见 requirement R4）。

### 性能（NF1）— 详见 `BENCHMARK.md` §2
方法学：同参数 N=11、预热 1、取中位；Rust `examples/timing.rs`(release) 与 C `scripts/bench_compare.py`(argon2-cffi) 同机同口径。
- [x] 工作机 aarch64：v0 Rust 59.9ms vs C 77.2ms（快 1.29×），三组参数均 <1.5s。
- [ ] **iOS / Android 真机** release 中位 < 1.5s 且不劣于 498ms — 人工(@Ray)，走 `example/integration_test`。

### 体积（NF2）— 详见 `BENCHMARK.md` §3
方法学：单架构 cdylib（DCE+strip）字节为准；`.a` 是链接前归档不算。真机整包以 `--analyze-size` 下载体积差为准。
- [x] 单架构 cdylib：iOS 0.317MB / Android 0.333MB（≪ 3MB）。
- [ ] **真机整包增量**（带本包 vs 不带）≤ 3MB — 人工(@Ray)，`--analyze-size` / `--split-per-abi`。

### 兼容性（R3） — 符号解析按平台分流，AOT 多端已验证
- [x] **iOS release strip 风险已定位修复**：实测 `flutter build ios --release` 二进制动态导出表**无**该符号
  → 运行期 `dlsym` 会失败；iOS/macOS 改用 **`@Native(symbol:)`**（编译期静态引用、抗 strip）。
- [x] **macOS profile/AOT(已 strip)**：example integration_test 通过（69ms）—— @Native 在 AOT 下解析正常（iOS 代理）。
- [x] **Android profile/AOT**：真实 DayZ app 在模拟器跑 integration_test 通过（132ms）—— Android 用
  `.so` + `DynamicLibrary.open + lookupFunction`（导出符号 release 下仍在，无 iOS 静态链接剥离问题）。
- [x] **iOS 模拟器(debug)**：真实 DayZ app 跑通（3/3）。
- [x] cargokit gradle 与新版 Gradle 兼容（`plugin.gradle` 改用 `ExecOperations`）。
- [ ] **iOS 真机 archive/TestFlight 运行**（最终确认，iOS 模拟器不跑 AOT、需实机；macOS-AOT 是强代理）— 人工(@Ray)。
- [ ] Android **真机** release 运行（已过模拟器 AOT，真机补一次）— 人工(@Ray)。
- [ ] 并发 OOM：64MiB × 多 isolate RSS 峰值可控（建议并发限 2）— 人工(@Ray)，profile DevTools。

## 需求 ↔ 验证 覆盖核验（双向闭环）

| 需求 | 验证去向 |
|---|---|
| R1 Argon2id | Argon2id 正确性(Rust) + ffi 端到端(Dart) + 错误路径 + 空口令边界 |
| R2 HKDF | HKDF 正确性(Rust) + ffi 端到端(Dart) + None salt 边界 |
| R3 双端编译 | 双端交叉编译 + 兼容性专项（含 release 符号留存） |
| R4 zeroize | 专项 R4（结果级 + 边界声明） |
| NF1 性能 | 性能专项（工作机实测 ✅ + 真机待补） |
| NF2 体积 | 体积专项（单架构 cdylib ✅ + 真机整包待补） |

反向：上表所有行均挂 R#/NF#，无孤儿验证。

## 验证命令（汇总自动项）

```bash
cd packages/argon2id_ffi/rust && cargo test                         # Rust 算法正确性
cd packages/argon2id_ffi/rust && cargo build --release              # 产出 host dylib
cd packages/argon2id_ffi && \
  ARGON2ID_FFI_LIB="$PWD/rust/target/release/libargon2id_ffi.dylib" \
  flutter test test/crypto_ffi_test.dart                            # Dart 手写 ffi 端到端
ARGON2ID_FFI_LIB="$PWD/packages/argon2id_ffi/rust/target/release/libargon2id_ffi.dylib" \
  flutter test test/security/argon2_kdf_test.dart                    # DayZ KDF 接入 host 复验
cd packages/argon2id_ffi/rust && cargo run --release --example timing && cargo bench  # 性能
```

> macOS host `flutter test` 不会把 iOS/macOS 静态链接符号注入测试进程；主工程 KDF 测试必须显式设置
> `ARGON2ID_FFI_LIB` 走动态库 escape hatch。设备 / AOT 路径仍按 D2 的平台分流验证。
