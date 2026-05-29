---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# 验证：backup-full-snapshot

> 跨任务校验。命中：加密 / 安全（NF4, NF5）、性能（NF1, NF2, NF3）、多端、数据完整性、还原回滚。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 全量导出 | export 3 entries + 2 media | `.mydiary` 文件创建、hexdump 无明文 | R3, NF4 | 自动 |
| 错密码还原 | 错口令 → restore | 抛 BadPassword | R5 | 自动 |
| schema 不兼容还原 | 篡改 manifest schema_version=999 | 抛 SchemaIncompatible | R7 | 自动 |
| confirmOverwrite false | callback 返 false | 抛 BackupCancelledException、本机库不变 | R10 | 自动 |
| 正常还原往返 | export → restore | entries / media 完全一致；FTS 搜索可用 | R3, R5, R6 | 自动 |
| 缩略图懒生成 | restore 完成后立即查 thumbs/ | 目录空或部分文件；warmup 异步进行 | R6, D7 | 自动 |
| FTS 立即可用 | restore 完成后搜索 | 返回原 entries | R6 | 自动 |

## 专项检查

### 加密 / 安全（NF4, NF5）
- [ ] hexdump `.mydiary` 在 header 后所有位置不可见明文 — 自动：随机抽样 bytes 不出现 "SQLite" / 测试 entry plain 文字
- [ ] export 不创建明文临时文件 — 自动：监视临时目录
- [ ] restore 不创建明文临时文件 — 自动：监视临时目录
- [ ] 任一正常 / 异常 / 取消路径结束后无残留 `.tmp` / `.restoring` / `media/.old` / `full_*.db` — 自动：T9 cleanup_test

### 性能（NF1, NF2, NF3）
- [ ] 中端真机 10000 entries + 500 media 导出 < 3 分钟 — 人工（@Ray），数据来源 T8
- [ ] 同体量还原 < 4 分钟 — 人工（@Ray）
- [ ] 导出 / 还原 RSS 增量 < 300 MiB — 人工（@Ray），借 Profiler

### 还原原子性（R8，依 docs/design/09 约定二）
- [ ] 写临时位置阶段（解密 db / 重加密 media）注入故障 → 旧 db 与旧 media **完整可用**、可正常打开并读出原 entries 与原图；仅 `main.sqlite.restoring` / `media/.restoring/` 被清 — 自动
- [ ] 切换阶段前注入故障 → 同上，现役产物未被触碰 — 自动
- [ ] 还原失败后本机状态满足不变式：**全旧或全新**，不出现「db 在、media 被清空」的半成品（断言旧 db 引用的每个 media 文件仍存在且可解密）— 自动

### 与 M5 协作约束（R6, D7）
- [ ] restore 调用栈中不出现「同步全量重建缩略图」函数 — 自动 grep
- [ ] warmup 调用立即返回（不 await）— 自动
- [ ] grep `await ThumbnailCache.warmup` 应**无匹配** — 自动

## 回归检查

- [ ] M1 / M2 / M3 / M5 模块单测仍全过 — 自动
- [ ] Debug Home 中其他 demo 仍可演示，Backup demo 新增 — 人工（@Ray）

## 验证命令（汇总自动项）

```bash
flutter analyze
flutter test test/backup/
flutter test
! grep -RIn 'await\s\+ThumbnailCache.warmup' lib/backup/
```
