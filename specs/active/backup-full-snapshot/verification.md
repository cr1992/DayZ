---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-31
文档状态：定稿
---

# 验证：backup-full-snapshot

> 跨任务校验。命中：加密 / 安全（NF4, NF5）、性能（NF1, NF2, NF3）、多端、数据完整性、还原回滚。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 全量导出 | export 3 entries + 2 media | `.mydiary` 文件创建、hexdump 无明文 | R3, NF4 | 自动 |
| 错密码还原 | 错口令 → restore | 抛 BadPassword | R5 | 自动 |
| schema 不兼容还原 | 篡改 manifest schema_version=999 | 抛 SchemaIncompatible | R7 | 自动 |
| manifest 损坏还原 | payload 内 manifest.json 删除/置非法 JSON/缺 R2 必需字段 → restore | 抛 ManifestCorrupted、不进入确认与切换、本机库不变 | R11 | 自动 |
| confirmOverwrite false | callback 返 false | 抛 BackupCancelledException、本机库不变 | R10 | 自动 |
| 正常还原往返 | export → restore | entries / media 完全一致；FTS 搜索可用 | R3, R5, R6 | 自动 |
| 缩略图懒生成 | restore 完成后立即查 thumbs/ | 目录空或部分文件；warmup 异步进行 | R6, D7 | 自动 |
| FTS 立即可用 | restore 完成后搜索 | 返回原 entries | R6 | 自动 |

## 专项检查

### 加密 / 安全（NF4, NF5）
- [x] hexdump `.mydiary` 在 header 后所有位置不可见明文 — 自动：随机抽样 bytes 不出现 "SQLite" / 测试 entry plain 文字
- [x] export 不创建明文临时文件 — 自动：监视临时目录
- [x] restore 不创建明文临时文件 — 自动：监视临时目录
- [x] 任一正常 / 异常 / 取消路径结束后无残留 `.tmp` / `.restoring` / `media/.old` / `full_*.db` — 自动：T9 cleanup_test
- [x] 备份包不收录 observability 诊断日志：预置 `ApplicationSupport/logs/app.log*` 后导出，解析 TAR 条目清单不含 `logs/` / `app.log` / 轮转日志 — 自动：`flutter test test/backup/exporter_test.dart`（承接 `observability` 归档复验的跨 spec 约束）

### 性能（NF1, NF2, NF3）
- [ ] 中端真机 10000 entries + 500 media x 3 MiB 导出 < 3 分钟 — 人工（@Ray），数据来源 Backup demo Benchmark 区
- [ ] 同体量还原 < 4 分钟 — 人工（@Ray），数据来源 Backup demo Benchmark 区
- [ ] 导出 / 还原 RSS 增量 < 300 MiB — 人工（@Ray），借 Profiler；页面仅输出耗时，RSS 以系统 Profiler 为准

### 还原原子性（R8，依 docs/design/09 约定二）
- [x] 写临时位置阶段（解密 db / 重加密 media）注入故障 → 旧 db 与旧 media **完整可用**、可正常打开并读出原 entries 与原图；仅 `main.sqlite.restoring` / `media/.restoring/` 被清 — 自动
- [x] 切换阶段前注入故障 → 同上，现役产物未被触碰 — 自动：`flutter test test/backup/restorer_apply_test.dart`（用 `media/.old` 阻塞文件在临时产物全部写好、现役 media/db 尚未移动前触发失败）
- [x] 还原失败后本机状态满足不变式：**全旧或全新**，不出现「db 在、media 被清空」的半成品（断言旧 db 引用的每个 media 文件仍存在且可解密）— 自动

### 与 M5 协作约束（R6, D7）
- [x] restore 不在自身流程内同步（await）生成缩略图 — 自动：`flutter test test/backup/restorer_fts_test.dart`（注入「warmup 永不完成」spy，断言 restore 返回 future 仍 < 50ms complete；若 restore await 了缩略图生成则此断言失败/超时）
- [x] warmup 被调用恰好 1 次、入参 = 全部存活 media id、优先级 low、restore 返回时 `thumbs/` 未被全量填满 — 自动：`flutter test test/backup/restorer_fts_test.dart`（spy 记录调用参数 + 检查 thumbs/ 目录文件数 < media 总数）
- [x] **解耦守卫（为缺失/解耦守卫，非行为断言）：** `lib/backup/` 下不出现 `await ... ThumbnailCache.warmup`——防止后续改动悄悄把异步 warmup 改回 await。此项是上面 behavior test 的低成本纵深防御，behavior test 才是主验收（永不完成 spy 能抓住任何形式的「await 缩略图生成」，grep 只抓字面 await warmup）。— 自动：`! grep -RInE 'await[^;]*ThumbnailCache\.warmup' lib/backup/`

## 回归检查

- [ ] M1 / M2 / M3 / M5 模块单测仍全过 — 自动（回归）
- [x] Backup demo 完整 UI flow seed/export/clear/restore 后自检 PASS — 自动：`flutter test test/backup/demo_test.dart`
- [x] Backup demo Benchmark 区小规模 seed/export/restore 后跑数 PASS；默认 smoke 档，`Use Spec Scale` 一键切 spec 体量 — 自动：`flutter test test/backup/demo_test.dart`
- [ ] Debug Home 中其他 demo 仍可演示 — 人工（@Ray）（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，确保无遗漏。任一项不通过则 verification 未定稿。
- [x] 正向：R3, NF4（全量导出 + 加密/安全专项）、R5（错密码/正常往返）、R6（FTS 立即可用 + 与 M5 协作）、R7（schema 不兼容）、R8（还原原子性专项）、R10（confirmOverwrite false）、**R11（manifest 损坏 → ManifestCorrupted，功能验证表）**、R12/NF6（observability logs 不进备份包专项）、NF1/NF2/NF3（性能专项）、NF5（残留清理专项）均有验证，无孤儿需求。R1/R2/R4/R9 在 tasks 单任务内验（T2/T3 格式与 manifest、T4 进度回调与明文不落临时文件），不重复列入跨任务 verification。
- [x] 反向：各验证项「关联需求」均指向真实存在的 R/NF；回归检查已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）

```bash
flutter analyze lib/backup test/backup
flutter test test/backup/   # 含 restorer_fts_test：注入「warmup 永不完成」spy，断言 restore 不 await 缩略图生成（主验收）
# 下面 grep 为缺失/解耦守卫（非行为断言），是上面 behavior test 的低成本纵深防御：
! grep -RInE 'await[^;]*ThumbnailCache\.warmup' lib/backup/

# 回归项（当前仍被非 backup 范围阻塞，见本轮验收记录）：
flutter analyze
flutter test
```

## 本轮验收记录

日期：2026-05-31

- 自动通过：`flutter pub get`；`flutter analyze lib/backup test/backup`；`flutter test test/backup/`（含切换阶段前故障注入、Backup demo `SELF CHECK: PASS` 完整 UI flow、Benchmark 区小规模 `BENCHMARK: PASS`）；`! grep -RInE 'await[^;]*ThumbnailCache\.warmup' lib/backup/`；`bash spec-kit/scripts/lint_acceptance_commands.sh specs`；`bash spec-kit/scripts/lint_keywords.sh specs`。
- 回归阻塞：全仓 `flutter analyze` 仍有 57 个非 backup 范围 issue；全仓 `flutter test` 失败在 `test/security/argon2_kdf_test.dart` 等 Argon2 native KDF 链接用例。
- 性能后置记录：NF1 / NF2 / NF3 真机基准已具备页面造数 / 跑数入口，但不纳入本次模块代码提交结论，后续由 @Ray 在真机 + Profiler 下补录。
- 人工待确认：T10 iOS + Android 真机演示、Debug Home 其他 demo 回归（核查人 @Ray）。
