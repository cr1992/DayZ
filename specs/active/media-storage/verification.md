---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# 验证：media-storage

> 跨任务质量校验。命中：加密（NF1）、性能（NF2, NF4）、多端（NF3）、路径安全（NF5）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| put → openRead 往返 | 1 MiB 图：put 后 openRead | 字节完全一致 | R1, R2 | 自动 |
| 元数据写入 | put 后查询 media 表 | rel_path / width / height 与传入一致 | R3 | 自动 |
| softDelete | softDelete(id) 后 list | deleted_at 写入，文件保留 | R4 | 自动 |
| hardDelete | hardDelete(id) 后查询 | 文件不存在 + db 行不存在 | R4 | 自动 |
| 重加密为备份 | streamForBackup + encryptForBackup | 用 backupKey 能解密回明文，与原文件一致 | R6 | 自动 |
| 篡改密文 | 修改某字节后 openRead | 抛 MediaCorruptedException | R7 | 自动 |
| 错误密钥 | 用别的密钥 openRead | 抛 MediaCorruptedException | R7 | 自动 |
| 写盘原子化 | put 中途模拟崩溃 | 仅留 `.tmp` 文件、media 表无对应行 | R3, D5 | 自动 |

## 专项检查

### 加密强度（NF1）
- [ ] 每次 put 的 nonce 不重复 — 自动：批量 put 1000 文件，nonce 哈希集大小 = 1000
- [ ] auth tag 校验不能被绕过（不存在「跳过验证」分支）— 自动：源码 grep + 篡改测试
- [ ] HKDF info = `dayz/media/v1` 一致 — 自动 grep

### 性能（NF2, NF4）
- [ ] 100 MiB 流式 put 不爆内存（RSS 增量 < 200 MiB）— 人工（@Ray），可借 OS profiler
- [ ] 中端真机 iOS 写 ≥ 30 MiB/s — 人工（@Ray），数据来源 T7
- [ ] 中端真机 iOS 读 ≥ 50 MiB/s — 人工（@Ray），数据来源 T7
- [ ] 中端真机 Android 写 / 读达标 — 人工（@Ray），数据来源 T7

### 多端一致（NF3）
- [ ] iOS 写入文件能在同设备另一进程读 — 人工（@Ray），通过 demo + 杀进程重启
- [ ] Android 同上 — 人工（@Ray）

### 路径安全（NF5）
- [ ] MediaStore 公开 API / 异常 message 不含绝对路径 — 自动：grep `/var/` / `/data/` 在 `lib/media/`
- [ ] demo 页 UI 不展示绝对路径 — 人工（@Ray）目视

## 回归检查

- [ ] M1 / M2 模块单测仍全过 — 自动：`flutter test test/security/ test/data/`
- [ ] M1 KeyProvider 新增 `getDeviceMediaKey()` 后老的 `getAppDbKey()` 路径不受影响 — 自动 单测
- [ ] Debug Home 中 Security / Data demo 仍可演示，Media demo 新增 — 人工（@Ray）

## 验证命令（汇总自动项）

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
grep -RIn '/var/\|/data/' lib/media/ || true
```
