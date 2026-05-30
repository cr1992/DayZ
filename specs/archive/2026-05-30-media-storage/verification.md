---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-30
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
- [x] 每次 put 的 nonce 不重复 — 自动：`flutter test test/media/nonce_uniqueness_test.dart`（批量 put 1000 文件，断言收集到的 nonce 去重集 size == 1000）
- [x] auth tag 校验不能被绕过 — 自动：`flutter test test/media/media_codec_test.dart`（断言：篡改 ciphertext / 篡改 tag / 错误密钥三种输入下 `decrypt` **均抛 `MediaCorruptedException`**、且不返回任何字节——以「无论如何都抛」的行为证明不存在「跳过验证」旁路）
- [x] **缺失守卫**：codec 不存在「不验证 tag 仍返回数据」的旁路分支 — 自动：`! grep -RIn 'skipTagVerification\|ignoreTag\|noVerify' lib/media/`（**为缺失/解耦守卫，非行为断言**：断言禁用符号不出现，兜底上一条行为测试覆盖不到的死代码旁路）
- [x] HKDF 设备媒体密钥确实用 info=`dayz/media/v1` 派生 — 自动：`flutter test test/security/key_provider_test.dart`（断言 `getDeviceMediaKey()` 输出 == 用 `dayz/media/v1` 独立重算的 HKDF 期望值，且换 info / 换根密钥则输出变——断言派生值而非源码字面量，与 T2 同源）

### 性能（NF2, NF4）
- [ ] 100 MiB 流式 put 不爆内存（RSS 增量 < 200 MiB）— 人工（@Ray），可借 OS profiler
- [ ] 中端真机 iOS 写 ≥ 30 MiB/s — 人工（@Ray），数据来源 T7
- [ ] 中端真机 iOS 读 ≥ 50 MiB/s — 人工（@Ray），数据来源 T7
- [ ] 中端真机 Android 写 / 读达标 — 人工（@Ray），数据来源 T7

### 多端一致（NF3）
- [ ] iOS 写入文件能在同设备另一进程读 — 人工（@Ray），通过 demo + 杀进程重启
- [ ] Android 同上 — 人工（@Ray）

### 路径安全（NF5）
- [x] MediaStore 公开 API 返回值与异常 message 不含绝对路径 — 自动：`flutter test test/media/path_safety_test.dart`（断言：① `put` 返回的 rel_path 形如 `media/<id>.bin`、不以 `/` 开头；② 制造 MediaNotFound/MediaCorrupted/KeyMissing 三类异常，断言其 `message` 不包含 documents 根绝对前缀、且 `relativize` 对越界绝对路径抛 ArgumentError——断言运行期产出的字符串值而非源码文本）
- [x] **缺失守卫**：`lib/media/` 源码不硬编码平台绝对路径前缀 — 自动：`! grep -RIn '/var/mobile\|/data/data' lib/media/`（**为缺失/解耦守卫，非行为断言**：兜底防止字面量绝对路径混入，与上一条行为测试互补）
- [ ] demo 页 UI 不展示绝对路径 — 人工（@Ray）目视

## 回归检查

- [x] M1 / M2 模块单测仍全过 — 自动：`flutter test test/security/ test/data/`
- [x] M1 KeyProvider 新增 `getDeviceMediaKey()` 后老的 `getAppDbKey()` 路径不受影响 — 自动：`flutter test test/security/key_provider_test.dart`（断言 `getAppDbKey()` 返回值与新增接口前一致、且与 `getDeviceMediaKey()` 输出**不相等**，证明两把密钥未串）
- [ ] Debug Home 中 Security / Data demo 仍可演示，Media demo 新增 — 人工（@Ray）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，确保无遗漏。任一项不通过则 verification 未定稿。
- [x] 正向：R1/R2（put→openRead 往返、元数据写入）、R3（元数据 + 写盘原子化）、R4（soft/hardDelete）、R5/NF1（HKDF 派生 + 加密强度）、R6（重加密为备份）、R7（篡改/错误密钥异常）、NF2/NF4（性能专项）、NF3（多端一致专项）、NF5（路径安全专项）均至少被一个场景或专项检查覆盖，无孤儿需求。
- [x] 反向：各验证项「关联需求」均指向真实 R/NF；「缺失/解耦守卫」「回归检查」已显式标注，不冒充行为断言、不作孤儿测试计入需求覆盖。

## 验证命令（汇总自动项）

```bash
flutter analyze
flutter test                                       # 含加密强度 / 路径安全 / 密钥派生等行为断言
flutter build apk --debug
flutter build ios --debug --no-codesign
# 缺失/解耦守卫（违规即 fail，非 informational）：
! grep -RIn 'skipTagVerification\|ignoreTag\|noVerify' lib/media/   # 无「跳过验证」旁路
! grep -RIn '/var/mobile\|/data/data' lib/media/                    # 无硬编码平台绝对路径
```
