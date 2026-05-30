---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
---

# 验证：dayz-security-rust

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| Argon2id 计算正确性 | 传入已知 RFC 9106 向量 | 输出的派生密钥字节与预期一致 | R1 | 自动 |
| HKDF-SHA256 计算正确性 | 传入已知 RFC 5869 向量 | 输出字节与预期一致 | R2 | 自动 |
| 双端编译与运行 | 构建并运行本地包的单元测试 | 双端成功载入动态库且测试通过 | R3 | 自动 |
| 敏感内存擦除 (Zeroization) | 验证 Rust 源码使用了 zeroize 机制 | 密码缓冲区被安全覆写 | R4 | 人工 |

## 专项检查

### 性能（NF1）
- [ ] iOS 真机 `argon2idDeriveKey(v1)` 中位数耗时 < 1.5s — 人工（@Ray），数据记录于验收单
- [ ] Android 真机 `argon2idDeriveKey(v1)` 中位数耗时 < 1.5s — 人工（@Ray），数据记录于验收单

### 体积与性能对比 (Size & Performance Comparison)
- [ ] 对比分析自研 Rust 方案与原 C FFI 方案（dargon2_flutter）的包体积（APK/IPA）及计算性能（中位数耗时）— 人工（@Ray），对比数据须记录在最终验证报告或 walkthrough.md 中

### 兼容性（R3）
- [ ] iOS 13+ 真机运行测试通过 — 人工（@Ray）
- [ ] Android 8+ 真机运行测试通过 — 人工（@Ray）

## 验证命令（汇总自动项）

```bash
cd packages/dayz_security_rust && flutter pub get && flutter test
```
