---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
---

# dayz-security-rust（自研 Rust 密码学库）

## 背景

在 `key-management` 的预研和实现中，我们发现第三方 C FFI 插件 `dargon2_flutter` 在 iOS 平台上存在严重的 Xcode 符号剥离（Symbol Stripping）和死代码清理（Dead Code Stripping）问题，且由于其长期缺乏维护，无法开箱即用。

而纯 Dart 实现的密码学库（如 `cryptography` 或 `hashlib`）在执行 memory-hard 的 Argon2id 算法时，性能极差（移动端单次计算高达数秒），严重违反 `NF2` 性能要求。

为了获得完全可控的跨平台构建、极高的计算性能以及长远的安全可扩展性，我们决定**自研本地 Package `dayz_security_rust`**，采用 **Rust 语言**实现底层的密码学计算（Argon2id 与 HKDF-SHA256），并通过 `flutter_rust_bridge` (FRB) 自动生成 Dart FFI 绑定代码。

## 范围外

- 主密码和加密设置的 UI — 属于设置页面及外壳 Spec。
- 数据库层具体的数据加密解密逻辑 — 属于 `data-layer` Spec。

## 功能需求

### R1 · Argon2id 算法支持
Rust 库 MUST 暴露 Argon2id 密码哈希与密钥派生算法。
- 输入：`password` (Uint8List), `salt` (Uint8List), `m_cost` (uint32, 单位 KiB), `t_cost` (uint32), `parallelism` (uint32), `output_len` (uint32)
- 触发：调用 Dart 绑定方法 `argon2idDeriveKey(...)`
- 结果：返回计算出的派生密钥 (Uint8List)；相同参数下具有确定性

### R2 · HKDF-SHA256 算法支持
Rust 库 MUST 暴露 HKDF-SHA256 密钥扩展算法（供派生设备媒体密钥等使用）。
- 输入：`ikm` (Uint8List, 输入密钥), `salt` (Uint8List?), `info` (Uint8List), `output_len` (uint32)
- 触发：调用 Dart 绑定方法 `hkdfSha256DeriveKey(...)`
- 结果：返回派生的 32 字节子密钥

### R3 · 双端编译与链接支持
该本地 Rust Package MUST 支持 iOS（真机与模拟器）和 Android（真机与模拟器）的编译和无阻碍链接。
- 结果：`flutter run` 应当能在不进行任何手动 Xcode/Gradle 配置的情况下直接在 iOS/Android 模拟器或真机上拉起并成功执行

### R4 · 敏感内存擦除 (Zeroization)
Rust 库在完成密钥计算后，MUST 尝试对存储敏感信息（如 `password`、`ikm` 及派生出的 `key`）的内存缓冲区进行擦除（Zero-fill）。

## 非功能需求

### NF1 · 计算性能目标
在 v0 参数下（m_cost=64MiB, t_cost=3, parallelism=1），在中端移动设备上单次 `argon2idDeriveKey` 计算时长 MUST < 1.5 秒。

### NF2 · 包体积增量控制
引入 Rust 运行时与 FRB 胶水层后，最终导出的 Android APK 或 iOS IPA 安装包体积增量 SHOULD 控制在 3MB 以内。

## 专项维度逐维表态（选档依据）

> 本 Spec 涉及底层安全模块和多端跨平台 FFI 编译，升级为**标准档**。

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 是 | 密码学核心算法实现，包含敏感内存擦除（R4）与输入校验。 |
| 权限 | 否 | 无用户权限系统相关逻辑。 |
| 无障碍 | 否 | 无 UI 交互，属于纯后台算法包。 |
| 性能 | 是 | 核心目标是用 Rust 原生性能平替纯 Dart，有明确的 <1.5s 耗时指标（NF1）。 |
| 多端兼容 | 是 | 涉及 iOS/Android 双端的 Rust 交叉编译与 FFI 运行时链接（R3）。 |
