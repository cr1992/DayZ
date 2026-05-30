---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-30
文档状态：定稿
---

# data-layer（数据层：Drift + SQLCipher + Schema + Repository）

## 背景

方案 v6 第 3、5 节定调主库走 Drift（SQLite ORM）+ SQLCipher 加密，schema 已设计完毕（journals / entries / media / tags / entry_tags / editing_session / entries_fts）。本里程碑落地 schema、加密集成、索引、并以 Repository 层为页面与查询逻辑之间的唯一接缝——页面层不直接写 SQL/Drift 查询。该里程碑是几乎所有上层功能（时间线、往年今日、备份、自动保存）的依赖。

整体依赖 **M0 app-scaffold**（项目壳与 Debug Home）与 **M1 key-management**（提供 db 加密密钥）。

## 范围外

- 时间线 / 往年今日的页面渲染——属 UI，待设计稿。
- FTS 中文 tokenizer（ICU / trigram）——远期，FTS5 虚拟表本期仅建表占位，不接 ICU。
- 同步字段的实际同步行为——预留字段不实现。
- editing_session 的写入与启动检测——属 auto-save-draft 里程碑（本里程碑只建表 + 暴露 CRUD）。
- 媒体文件读写本体——属 media-storage（本里程碑只建 media 表）。
- 备份导入的合并 upsert 路径——属 backup-full-snapshot。
- 主密码 rekey 的 db 侧对接——本期补 key-management T7 留下的 stub，但 UI 接入推迟。

## 功能需求

### R1 · Drift 表定义与 schema 创建
系统 MUST 用 Drift 的 Dart 表类定义 v6 第 5 节全部表（含 entries、journals、media、tags、entry_tags、editing_session）与所有索引；MUST 创建 `entries_fts` FTS5 虚拟表（使用默认 tokenizer 占位）。
- 前提：全新数据库
- 操作：首次打开 db
- 结果：所有表 / 索引 / FTS 虚拟表均存在，schema_version=1

### R2 · SQLCipher 加密集成
系统 MUST 以 key-management 提供的 db 密钥打开 SQLCipher 加密数据库；MUST 验证打开后 `PRAGMA cipher_version` 返回非空。
- 前提：device_db_key 已生成
- 操作：初始化数据层
- 结果：db 文件为密文（hexdump 首字节非 SQLite 明文 magic）；密钥错误时打开失败抛 `WrongKeyException`

### R3 · UUID v7 主键生成
所有主键 MUST 由系统统一生成 UUID v7（时间有序），暴露 `Ids.next()` 工具方法。
- 前提：调用方需要新主键
- 操作：调用 `Ids.next()`
- 结果：返回 32 字符（含连字符 36 字符）的 UUID v7；同一毫秒内连续生成的两个 UUID 大小关系与生成顺序一致

### R4 · 时区三件套写入
插入 / 更新 entries 时，若调用方提供 `entry_dt_utc` 与 `entry_tz`，系统 MUST 自动计算并填入 `local_year / local_month / local_day`；**编辑这两个字段时也 MUST 重算（不是只在新建时算）**。
- 前提：用户编辑某条 entry 的 entry_dt_utc 或 entry_tz
- 操作：Repository.updateEntry
- 结果：local_year / local_month / local_day 三字段按新值重算后持久化

### R5 · Repository 层封装
系统 MUST 把所有数据访问 API 集中在 Repository 类（按聚合根分：JournalRepo / EntryRepo / MediaRepo / TagRepo / EditingSessionRepo）；页面层与备份层只通过 Repository 调用，不直接持有 Drift db 句柄。
- 前提：上层需要数据访问
- 操作：调用 Repository 方法（如 `EntryRepo.onThisDay(month, day)`）
- 结果：返回所需数据，调用方代码中不出现 Drift / SQL 字符串

### R6 · 软删除墓碑
所有支持删除的表（entries / journals / media / tags）的删除 MUST 是软删除（写 `deleted_at`），查询默认过滤 `deleted_at IS NULL`；Repository 暴露独立的 `hardDelete` 用于备份合并后清理（本期仅留空方法或标记，备份合并归 M6）。
- 前提：某条 entry 存活
- 操作：`EntryRepo.softDelete(id)`
- 结果：行 `deleted_at` 写当前时间戳；默认 query 不再返回该行

### R7 · Migration 框架
系统 MUST 启用 Drift migration 机制；MUST 在数据层暴露 `Database.schemaVersion`；首次 schema 即版本 1。
- 前提：新版本上线带 schema 变更
- 操作：升级 schemaVersion
- 结果：旧库自动跑 migration 步骤；本期仅需框架，不需实际迁移逻辑

### R8 · key-management rekey 对接
本里程碑 MUST 把 key-management 里程碑 T7 留的 stub（PRAGMA rekey 真正调用块）补全：暴露 `Database.rekey(newKey)` 方法，由 `RekeyService` 调用。
- 前提：库已打开，准备 rekey
- 操作：`Database.rekey(newKey)`
- 结果：库以新密钥加密；后续以新密钥打开成功，旧密钥失败

## 非功能需求

### NF1 · 性能 - 时间线查询命中索引
`(entry_dt_utc, id)` 游标分页查询 MUST 命中 `idx_entries_timeline` 索引，`EXPLAIN QUERY PLAN` 结果含 `USING INDEX idx_entries_timeline`。

### NF2 · 性能 - 往年今日查询命中索引
`(local_month, local_day)` 查询 MUST 命中 `idx_entries_monthday` 索引。

### NF3 · 性能 - 加密开销可接受
基准用例：10000 条 entries 的库，时间线分页（每页 30 条）单次查询 MUST < 100ms（中端机）。

### NF4 · 多端一致
SHALL 在 iOS / Android 两端正常工作；db 文件相对路径一致（`<app_documents>/db/main.sqlite`）。

### NF5 · 类型安全
所有 Repository 公开 API MUST 用强类型 model（不用 Map / dynamic）；time 字段统一用 `DateTime`（UTC）而非 `int`。

## 专项维度逐维表态

> 选档锁定：本 spec = **标准档**（含 NF1-NF5、verification.md、文件头文档状态、README 索引）。下表为 §0「专项维度逐维表态」，每维显式表态一次；任一为「是」即升标准档。

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 是 | R2/R8 走 SQLCipher 加密、密钥注入与 rekey，db 文件须为密文、错误密钥须抛 `WrongKeyException`。 |
| 权限 | 否 | 数据层不涉及系统权限申请（相册/相机等权限归 media-storage / UI 层）。 |
| 无障碍 | 否 | 本 spec 无 UI 表层（demo 入口仅 Debug Home 调试用，无障碍归后续 UI spec）。 |
| 性能 | 是 | NF1/NF2 查询须命中索引、NF3 时间线分页单次 < 100ms，均为可度量硬约束。 |
| 多端兼容 | 是 | NF4 要求 iOS / Android 两端正常工作、db 相对路径一致。 |

结论：安全 / 性能 / 多端兼容 三维为「是」（≥1 个「是」），与已选**标准档**自洽。
