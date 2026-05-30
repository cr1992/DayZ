# argon2id_ffi · 体积与性能 Benchmark

> 把本库（RustCrypto argon2，手写 dart:ffi）与 C 参考实现（argon2-cffi / P-H-C libargon2，
> 即 dargon2 同源）在**同一台机器、同参数、同统计口径**下对比，给性能/体积留硬数据。
> 数字均为**工作机实测**（Apple Silicon, aarch64）；iOS/Android **真机**耗时与安装包整包增量
> 需在真机/CI 补测（见 §5）。

最后更新：2026-05-30 ｜ 作者：@Ray

---

## 0. 一句话结论

- **正确性**：与 C 参考实现**逐字节一致**，HKDF 对齐 RFC 5869。Rust `cargo test` 7/7、Dart 手写 ffi 端到端 6/6。
- **性能**：aarch64（真实移动目标 ISA）上 v0 参数 **比 C 快 ~1.29×**（59.9ms vs 77.2ms）。"纯 Rust 比 C 慢"是 **x86 上 C 用 AVX SIMD** 的结论；ARM 上 P-H-C 的 SIMD 退回标量，而 RustCrypto 拿到 LLVM NEON 自动向量化。
- **体积**：单架构 cdylib（DCE+strip）**~0.32MB/arch**，**比 3MB 低 ~9×**；仅 2 个导出符号、87 crate（无 FRB/tokio）。

---

## 1. 测量环境

| 项 | 值 |
|---|---|
| 机器 | Apple Silicon（aarch64-apple-darwin），与 iOS/Android 真机同 ISA |
| rustc | 1.93.0（rustup stable），release `opt-level=3, lto=true, codegen-units=1, strip=true, panic=unwind` |
| 桥接 | 手写 `dart:ffi`（C-ABI），无 flutter_rust_bridge；cargokit 做交叉编译 |
| 密码学 crate | argon2 0.5.3（`default-features=false, features=["alloc","zeroize"]`）/ hkdf 0.12.4 / sha2 0.10.9 / zeroize 1.8.2 |
| C 对照 | argon2-cffi 25.1.0（封装 P-H-C 官方 libargon2，Argon2id, version 0x13） |
| 移动 target | aarch64-apple-ios / aarch64-linux-android（NDK 28.2, minSdk26） |

> **为何 argon2-cffi 代表 dargon2**：dargon2 移动端底层即 P-H-C 官方 C 参考实现；argon2-cffi 封装同一份 C 库。ARM 上二者都走标量路径，故同机 C-vs-Rust 的**比值**对移动端有代表性（绝对值不可跨环境比，见 §2 注）。

---

## 2. 性能

口径：同参数跑 N=11 次、预热 1 次、取**中位**。Rust 侧 `rust/examples/timing.rs`（release），C 侧 `scripts/bench_compare.py`，参数/口径完全一致。

| 参数 | argon2id_ffi (median, min/max) | C (median) | C / Rust | <1.5s |
|---|---|---|---|---|
| **v0：64MiB / t3 / p1 / len32** | **59.9ms** (59.1 / 64.9) | 77.2ms | **1.29× 更快** | ✅ |
| fallback：32MiB / t4 / p1 | 35.4ms (35.0 / 38.6) | 47.7ms | 1.35× | ✅ |
| OWASP 下限：19MiB / t2 / p1 | 10.1ms (9.7 / 10.3) | 13.4ms | 1.33× | ✅ |

复现：
```bash
cd packages/argon2id_ffi/rust && cargo run --release --example timing   # Rust（务必 --release）
cd packages/argon2id_ffi/rust && cargo bench                            # criterion 严谨统计
pip install argon2-cffi && python3 packages/argon2id_ffi/scripts/bench_compare.py  # C 同机对照
```

> 注：工作机绝对值（~60ms）远快于真机；有意义的是**同机 C-vs-Rust 比值**。真机 release 数见 §5。

---

## 3. 体积

口径：单架构、`opt-level=3 + lto + strip` 的 **cdylib**（移动端实际随包链接、经链接期 DCE 后的动态库）。`.a` staticlib 是链接前归档、含未 GC 的 std 全量，**不代表随包体积**。

| 架构 | 随包 cdylib（DCE+strip） |
|---|---|
| **iOS arm64** | **0.317 MB**（332,552 B） |
| **Android arm64** | **0.333 MB**（349,528 B） |
| host arm64 | 0.320 MB |

旁证：导出符号仅 **2 个**（`nm -gU`，即两个 C-ABI 函数）；Rust 依赖 **87 crate**（无 FRB/tokio）。

复现：
```bash
cd packages/argon2id_ffi/rust
RC=~/.rustup/toolchains/stable-aarch64-apple-darwin; export PATH="$RC/bin:$PATH"
cargo build --release --lib --target aarch64-apple-ios
NDK=~/Library/Android/sdk/ndk/<ver>/toolchains/llvm/prebuilt/darwin-x86_64/bin
CC_aarch64_linux_android=$NDK/aarch64-linux-android26-clang \
AR_aarch64_linux_android=$NDK/llvm-ar \
CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$NDK/aarch64-linux-android26-clang \
  cargo build --release --lib --target aarch64-linux-android
wc -c target/aarch64-apple-ios/release/libargon2id_ffi.dylib \
       target/aarch64-linux-android/release/libargon2id_ffi.so
```

---

## 4. 正确性

| 层 | 方式 | 结果 |
|---|---|---|
| Rust 算法 | `cargo test`：4 组 Argon2id KAT（对 argon2-cffi/C 逐字节）+ RFC 5869 §A Case1/2/3 HKDF + 确定性 + 输入校验 | **7/7** |
| Dart 手写 ffi 端到端 | `flutter test`（host 加载 release dylib）：argon2 KAT、空口令边界、错误码抛异常、确定性、HKDF Case1/Case3(null salt) | **6/6** |
| 内存擦除 | Rust 侧对入参 `password/ikm` Vec 显式 `zeroize`；argon2 `zeroize` feature 擦内部块 | best-effort（见下） |

**zeroize 边界**：argon2 crate 的 `zeroize` 只擦**内部块**，不擦调用方入参——故本库在 `crypto.rs` 对 `password/ikm` Vec **显式** `.zeroize()`。但：① 派生结果需返回不能擦；② dart:ffi 把 Dart `Uint8List` 拷成 native 缓冲后才进 Rust，**Dart 侧原 `Uint8List` 由 GC 托管、擦不到**。故内存擦除是 best-effort、非端到端。

---

## 5. 待真机/CI 补测

1. **iOS/Android 真机 release 中位耗时** — 走 `example/integration_test`（务必 release/profile）。
2. **安装包整包增量** — `flutter build appbundle --analyze-size` / `--split-per-abi`，量「带本包 vs 不带」下载体积差。
3. **iOS 真机 archive/TestFlight 运行** — 符号解析用 `@Native(symbol:)`（编译期静态引用、抗 strip）；
   已验证 macOS profile/AOT(已 strip) 跑通。剩 iOS 真机 archive 最终确认（iOS 模拟器不跑 AOT，需实机）。
4. **并发 OOM** — Argon2 64MiB × 多 isolate 并发的 RSS 峰值；低端机建议把并发限到 2。
