---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-29
文档状态：草稿
---

# backup-full-snapshot（全量单文件备份 + 整库覆盖式还原）

## 背景

v6 第 8 节定调 MVP 备份就是「形态一 · 单文件快照」：`.mydiary` 自定义后缀容器，含完整 db + 全部 media + manifest，独立可还原（无需 App 已安装的旧数据），用户可放本地、手动上传网盘、AirDrop。第 8.3 节明确**media 增量与持久备份目标是阶段二**，**本里程碑只做全量**。第 8.4 节定义还原是整库覆盖式（关 db → 换文件 → 拷 media → 重启 → 重建 FTS → 缩略图懒生成 + 后台预热）。**绝对禁止**还原时同步全量重建缩略图。

整体依赖 **M0**、**M1 备份口令派生（getDeriveBackupKey / generateBackupSalt）**、**M2 db 加密 + Repository**、**M3 媒体加密读写 + streamForBackup/encryptForBackup**、**M5 ThumbnailCache.warmup**。

## 范围外

- **持久备份目标** + media 增量（v6 8.3 阶段二）。
- **PDF / HTML 给人看的归档**（v6 8.5）。
- **备份导出 / 还原向导 UI**（含口令输入框、二次确认、进度条）—— 待设计稿；本期暴露接口与回调。
- **文件类型关联**（双击 `.mydiary` 唤起 App）—— 阶段二。
- **合并式还原（JSON 备份的 upsert 路径）**—— 本期只做整库覆盖式；JSON 备份可选导出但合并式 import 不做。
- **备份瘦身 / 孤儿清理**—— 阶段二随持久目标一起做。

## 功能需求

### R1 · 备份包格式（.mydiary 容器）
备份包 MUST 为 **单一二进制文件**，后缀 `.mydiary`，格式：
```
magic(8 字节)="MYDIARY\0"
format_version(1 字节)=1
salt_len(2 字节, big-endian)
backup_salt(salt_len 字节)   ← 未加密（导入侧需要先用它派生密钥才能解密下文）
encrypted_payload_size(8 字节, big-endian)
encrypted_payload(...)        ← MediaCodec 文件格式（AES-256-GCM）加密，密钥 = Argon2id(backupPassword, salt)
  解密后是 TAR 内容，含：
    manifest.json
    db/main.sqlite
    media/<media_id>.bin     ← 这里是「以备份口令派生密钥」重加密的 MediaCodec 格式
    media/<media_id>.bin     ← 同上
    ...
```
所有 `media/*.bin` 在 TAR 内仍为 **MediaCodec 加密格式（备份口令派生密钥版）**，避免大文件解密一次再加密一次的二次开销与明文落 TAR。

### R2 · manifest 内容
manifest.json MUST 含：
```json
{
  "format_version": 1,
  "backup_type": "full",
  "schema_version": 1,
  "generated_at": "2026-05-23T...",
  "app_version": "x.y.z",
  "entry_count": N,
  "media_count": M,
  "media_index": [{ "id": "...", "mime": "...", "size": ... }, ...]
}
```

### R3 · 全量导出流程
系统 MUST 提供 `BackupExporter.export({password, outputPath, onProgress, onCancel?}) -> Future<void>`：
1. 用 M1 `generateBackupSalt()` 生成 salt
2. 用 M1 `deriveBackupKey(password, salt)` 派生 backupKey
3. **VACUUM INTO** 当前 db 到临时 `<tmp>/full_<ts>.db`（v6 8.3）
4. 在 isolate 中：
   - 流式 TAR 组装
   - 把临时 db 文件读流 → MediaCodec 加密（backupKey）→ TAR entry `db/main.sqlite`
   - 遍历 media 表存活行：用 M3 `streamForBackup(relPath) | encryptForBackup(backupKey)` 管道 → TAR entry `media/<id>.bin`
   - manifest.json 字符串 → bytes → MediaCodec 加密 → TAR entry `manifest.json`
   - TAR 内容流 → MediaCodec 加密一次（payload 层加密）→ 写入 `.mydiary` 文件头之后
5. 写盘原子化：先 `<outputPath>.tmp` → rename
6. 任何步骤失败 / 取消 MUST 删 `.tmp` + 临时 db

### R4 · 进度回调与可取消
`onProgress(phase, processed, total)` MUST 在四阶段上报：`vacuuming`、`exporting_db`、`exporting_media`（按 media 数量计数）、`finalizing`。
`onCancel` MUST 在调用方触发时停止流式处理（在 TAR entry 边界或 1 MiB 加密块边界）。

### R5 · 整库覆盖式还原（写临时位置 + 全成功后原子切换）
系统 MUST 提供 `BackupRestorer.restore({inputPath, password, onProgress, confirmOverwrite}) -> Future<void>`，按 v6 8.4 步骤，并遵守 `docs/design/09`「约定二·覆盖式还原」——**新产物全部先写临时位置，全部成功后才原子切换；任一步失败只删临时产物，旧 db 与旧 media 原样不动**：
1. 读 `.mydiary` header → 取 salt → `deriveBackupKey(password, salt)`
2. 解密 payload → TAR 流
3. 读 `manifest.json` → 校验 `schema_version` 与当前 App 兼容（不一致：通过 App migration 路径或拒绝并提示）
4. **回调 `confirmOverwrite()` 请用户确认**（高危操作）；未确认中止
5. 关闭当前 db 连接（`Database.close()`）
6. **写临时位置阶段（不触碰任何现役产物）**：
   - 解密 `db/main.sqlite` → 写到 `<app_documents>/db/main.sqlite.restoring`
   - 解密每个 `media/<id>.bin` → 用**当前设备的设备媒体密钥重加密** → 写到独立临时目录 `<app_documents>/media/.restoring/<id>.bin`（M3 MediaCodec）
   - 此阶段全程 **绝不删除、绝不覆盖现役 `<app_documents>/db/main.sqlite` 与 `<app_documents>/media/` 下任何文件**
7. **切换阶段（仅在第 6 步全部成功后进入，集中做 rename，尽量短）**：
   - rename `<app_documents>/media/<id>.bin` 现役旧文件移走（或将旧 `media/` 整体移到 `media/.old/`）
   - rename `<app_documents>/media/.restoring/*` → `<app_documents>/media/`
   - rename `main.sqlite.restoring` → `<app_documents>/db/main.sqlite`
   - 切换成功后删除被替换下来的旧 db 与旧 media（`media/.old/`）
8. 删除 `<app_documents>/thumbs/`（缩略图全部重建；属派生数据，删旧即可，无需临时位置保护）
9. 重启数据层（重新打开 db）
10. **同步**调用 SQL 重建 `entries_fts`（秒级）
11. **异步**调用 `ThumbnailCache.warmup(allMediaIds)` —— **绝对不能**同步全量重建

### R6 · 重建 FTS 同步、缩略图异步
重建 FTS 是「DELETE FROM entries_fts; INSERT INTO entries_fts SELECT id, content_plain FROM entries WHERE deleted_at IS NULL」级别的纯 CPU 操作，MUST 在 restore 流程中同步完成（不让用户看见时间线但搜不到的状态）。
缩略图 MUST **不在 restore 流程内同步生成**——还原后立即可用 + 后台预热（M5 warmup）。

### R7 · schema_version 不兼容处理
若 manifest.schema_version > 当前 App.schemaVersion：拒绝并提示「请升级 App 后再还原」。
若 manifest.schema_version < 当前 App.schemaVersion：通过 App 自身的 Drift migration 路径升级（即还原成 schema 1 → migrate 到当前）。

### R8 · 失败回滚（旧态保全，无数据丢失）
还原过程中任一步失败 MUST 保证本机数据为**旧态完整可用**——遵守 `docs/design/09`「约定二」：
- 失败发生在 R5 第 6 步「写临时位置阶段」（解密 / 重加密 / 空间不足等）：**只删除临时产物**（`main.sqlite.restoring`、`media/.restoring/`），旧 db 与旧 media 原封不动、原样可用。
- 失败发生在 R5 第 7 步「切换阶段」之前：同上，旧产物未被触碰。
- restore 调用方收到失败错时，本机数据 MUST 满足覆盖式还原不变式：**要么全旧（旧 db + 旧 media 完整）、要么全新（新 db + 与之匹配的新 media 全部就位）**，**绝不允许「旧 db 在、但它引用的 media 已被清空」的半成品**（这正是先清空旧 media 再写回模型的数据丢失坑，本 spec 明令禁止）。
- 切换阶段（一组集中的 rename）设计上应尽量短且独立；切换全部成功后才删旧产物，故切换中途失败仍可凭未删除的旧产物保持旧态。

### R9 · 媒体重加密「明文不落临时文件」
解密旧密钥 → 重加密为新设备密钥的过程，明文 MUST 仅在内存 / 流中（复用 M3 MediaStore 流式 API 的能力）。
- 前提：备份包 media/<id>.bin 是 backupKey 加密
- 操作：restore 解密 → 设备密钥重加密
- 结果：磁盘上不出现明文 `<id>.bin.plain` 之类的临时文件

### R10 · 高危确认 callback
`restore` MUST 通过 `confirmOverwrite` 异步回调让调用方（未来 UI）显式确认；callback 返回 false 必须中止。

### R11 · manifest 损坏处理
还原读取 manifest 时，若 `manifest.json` 缺失、非合法 JSON、或缺少 R2 必需字段，系统 MUST 抛 `ManifestCorrupted` 并中止还原。
- 前提：备份包 payload 解密成功，但内含 manifest 不可解析
- 操作：restore 读取并解析 manifest
- 结果：抛 `ManifestCorrupted`，不进入确认与切换流程，本机数据原样不动

## 非功能需求

### NF1 · 性能 - 导出吞吐
中端真机：10000 条 entries + 500 张图（共 1.5 GiB）的库，导出耗时 MUST < 3 分钟（含 VACUUM INTO + db 加密 + media 重加密）。

### NF2 · 性能 - 还原吞吐
同体量备份还原 MUST < 4 分钟（含 media 重加密为本机密钥）。**还原后用户进时间线 MUST 立即可滚（缩略图未就绪显示占位由 UI spec 处理）**。

### NF3 · 内存
导出 / 还原过程任何时刻 RSS 增量 MUST < 300 MiB（流式必备，不允许整库整张图入内存）。

### NF4 · 安全 - 备份包密文性
hexdump `.mydiary` 任意位置（除 header 8 + 1 + 2 + salt_len 字节外）MUST 不可读出明文 db / manifest / 媒体内容。

### NF5 · 安全 - 中间产物清理
导出 / 还原结束后（成功或失败）MUST 清理：`<tmp>/full_*.db`、`<output>.tmp`、还原临时产物 `<db>/main.sqlite.restoring` 与 `<media>/.restoring/`、切换后被替换下来的旧产物 `<media>/.old/`、任何 `.tmp`。

## 专项维度逐维表态

> 选档结论：**标准档**（命中 安全 / 性能 / 多端 多维，且必含 verification.md）。任一维「是」即升标准档；本表与已选标准档自洽（含 ≥1 个「是」）。

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 是 | 备份包密文性（NF4：除 header 外任意位置不可读明文）+ media 重加密「明文不落临时文件」（R9）+ 中间产物清理（NF5），全程涉及 Argon2id 派生密钥与 AES-256-GCM。 |
| 权限 | 否 | 备份/还原在 App 自身沙盒目录（`<app_documents>`、`<tmp>`）内读写，不申请系统相册/通讯录等额外权限；网盘/AirDrop 由用户在系统层手动操作，不在本 spec。 |
| 无障碍 | 否 | 本期只暴露 lib 接口与回调，不含 UI（导出/还原向导见 README「待 UI 设计稿」），无可供无障碍评估的可视控件。 |
| 性能 | 是 | 导出 < 3 分钟（NF1）、还原 < 4 分钟（NF2）、RSS 增量 < 300 MiB（NF3）均为可度量阈值，且「还原后立即可滚、缩略图异步」是硬约束。 |
| 多端兼容 | 是 | `.mydiary` 容器须在 iOS / Android 通用解析（D1），media 重加密为「当前设备密钥」，备份包跨设备可还原（R5 第 6 步）。 |
