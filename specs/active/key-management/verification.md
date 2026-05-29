---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# 验证：key-management

> 跨任务质量校验。本里程碑命中：安全（NF1）、性能（NF2）、多端兼容（NF3）、可演进（NF4）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 首次启动 | 全新安装 → 启动 → 退出 | secure storage 中存在 `device_db_key` | R1 | 自动 |
| 重启读取 | 启动 → 退出 → 再启动 | 读到同一设备密钥，无 UI 提示 | R1 | 自动 |
| 主密码启用 rekey | mode=none → 启用主密码 X | 模式标记为 password、库可用 X 派生密钥打开 | R3, R4 | 自动 |
| 主密码修改 rekey | 启用 X → 改 Y | 库可用 Y 派生密钥打开、旧密钥失效 | R3, R4 | 自动 |
| rekey 中崩溃 | rekey 过程中 kill | 重启后库仍能打开（旧或新密钥确定态） | R4 | 人工（@Ray） |
| 备份口令派生一致 | 同 password+salt 两次调用 | 输出字节一致 | R5 | 自动 |

## 专项检查

### 安全（NF1）
- [ ] 派生密钥 / 设备密钥不出现在任何日志输出 — 自动：`grep -RIn 'print\|log' lib/security` 校验无原始密钥变量直接打印
- [ ] 派生密钥 / 设备密钥不写入任何文件（除 secure_storage 的密文存储）— 人工（@Ray）：审计 `lib/security/` 所有 File / IOSink 使用

### 性能（NF2）
- [ ] 中端真机 `Argon2Kdf.deriveKey(v1 params)` 中位数 < 1.5s — 人工（@Ray），数据来源 T3 验收记录
- [ ] 低端真机不 OOM — 人工（@Ray），数据来源 T3 验收记录

### 兼容性（NF3）
- [ ] iOS 13+ 真机冷启动 → 设备密钥生成 + 读取均成功 — 人工（@Ray）
- [ ] Android 8+ 真机冷启动 → 设备密钥生成 + 读取均成功 — 人工（@Ray）
- [ ] secure_storage 不可用时（模拟 / root 设备）抛 `SecureStoreException(unavailable)`，不静默兜底 — 自动 + 人工（@Ray）

### 可演进（NF4）
- [ ] `KdfParams` 包含 `version` 字段且持久化路径已写入 — 自动：`grep -n 'version' lib/security/argon2_kdf.dart`
- [ ] 读取 v1 params 的派生路径有单元测试 — 自动：`flutter test test/security/argon2_kdf_test.dart`

## Demo 验证（接 Debug Home，对应 T9）

- [ ] Debug Home 看到「Security」入口 — 人工（@Ray）
- [ ] 入口内显示「设备密钥已生成」状态正确 — 人工（@Ray）
- [ ] 派生按钮点击后显示耗时数字 — 人工（@Ray）（耗时 < 1.5s 的门槛见上文「性能（NF2）」节，此处不重复判定）
- [ ] demo 页面不显示任何密钥原文字节 — 人工（@Ray），目视审计

## 回归检查

> data-layer 尚未落地，无 db 集成回归。此处仅做模块内回归：

- [ ] 全模块单元测试通过 — 自动：`flutter test test/security/`
- [ ] 全 App 构建无破坏（iOS + Android 双端，与 T1 双端构建口径一致）— 自动：`flutter analyze && flutter build apk --debug && flutter build ios --debug --no-codesign`

## 验证命令（汇总自动项）

```bash
flutter pub get
flutter test test/security/
flutter analyze
flutter build apk --debug
flutter build ios --debug --no-codesign
grep -RIn 'TODO(data-layer-integration)' lib/security/rekey_service.dart
```
