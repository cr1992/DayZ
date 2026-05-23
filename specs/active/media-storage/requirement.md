---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# media-storage（媒体文件系统 + 加密）

## 背景

v6 第 3.2 / 5 / 9.4 节明确：媒体不进 SQLite blob，存文件系统；库内只存相对路径 + 宽高；媒体始终用**设备随机密钥**加密、不随主密码走、不参与 rekey。本里程碑落地媒体文件本体的加密读写 API 与目录约定，并与 M2 的 MediaRepo 配合写入元数据。原图与缩略图的加密都走本里程碑提供的统一加密路径；缩略图生成逻辑归 M5。备份导出时的「设备密钥解密 → 备份口令重加密」中转走本里程碑提供的**流式 API**（防止明文落临时文件），具体的备份打包流程归 M6。

整体依赖 **M0**（项目壳）、**M1**（设备密钥）、**M2**（MediaRepo 元数据写入）。

## 范围外

- 缩略图生成 / 失效 / 节流 —— 归 M5 thumbnail-cache。
- 备份包格式与导出全流程 —— 归 M6 backup-full-snapshot（但本期提供它需要的流式 API）。
- 原生相册/相机选图 UI —— 待设计稿；本期 demo 用预置图。
- audio / video 的播放与格式适配 —— MVP 只处理 image；接口对 kind 通用化，但不实现 audio/video 转码等。
- 媒体外链 / 云盘上传 —— 远期。

## 功能需求

### R1 · 文件系统目录约定
系统 MUST 把媒体落到 `<app_documents>/media/`，加密原文件命名 `<media_id>.bin`（统一后缀，类型来自 media 表 mime 字段）；MUST 在 media 表 `rel_path` 中存**相对 `<app_documents>` 的路径**（如 `media/<media_id>.bin`），**不存绝对路径**（v6 第 5 节实战避坑）。
- 前提：调用方传入媒体数据流 + kind + mime
- 操作：调用 `MediaStore.put(stream)`
- 结果：文件落到 `<app_documents>/media/<id>.bin`；media 表插入一行 rel_path=`media/<id>.bin`

### R2 · 加密读写（AES-256-GCM 流式）
系统 MUST 用**设备密钥（M1 KeyProvider.deviceMediaKey）**对媒体原文件做对称加密；MUST 提供流式 `put(Stream<List<int>>) -> rel_path` 与 `openRead(rel_path) -> Stream<List<int>>` API；MUST 不在加解密中产生明文临时文件。
- 前提：device media key 已就绪
- 操作：写入 1MB 测试文件
- 结果：磁盘上 `<id>.bin` 为密文（含 nonce 头 + ciphertext + auth tag）；读取流解密后字节完全一致

### R3 · 元数据写入
`MediaStore.put` MUST 在写盘成功后调用 M2 `MediaRepo.addMeta` 写入 media 表元数据（id、entry_id、kind、rel_path、width、height、mime、file_size、created_at、updated_at）；任一步失败必须整体回滚（已写的文件删除 / 已写的 db 行回滚）。
- 前提：DB 与 KeyProvider 就绪
- 操作：put 一张 1500×1000 的 JPEG
- 结果：media 表多一行；查询能拿到准确的 width/height

### R4 · 软删除与硬删除
删除媒体走两种语义：
- `softDelete(id)`：仅写 `media.deleted_at`，文件保留（用于「撤销删除」未来需求与备份归档）。
- `hardDelete(id)`：删除文件 + 删除 media 行（备份合并后清理 / 备份瘦身的支撑能力）。

硬删除 MUST 先删文件再删 db 行；任一步失败标记为可重试，**不允许 db 已删但文件还在的孤儿状态**（孤儿可由 backup 瘦身扫描捕获）。

### R5 · 设备密钥来源固定
媒体加密用的密钥 MUST 来自 KeyProvider 暴露的「设备媒体密钥」（M1 T6 已暴露 `getAppDbKey()`；本里程碑要求 M1 补一个 `getDeviceMediaKey()` 接口或在 KeyProvider 中暴露统一访问）；**不得**接受由调用方传入的密钥（避免误用主密码派生密钥加媒体）。

### R6 · 备份导出用流式中转 API
为 M6 提供 `MediaStore.streamForBackup(rel_path) -> Stream<List<int>>`（解密后明文流）与 `MediaStore.encryptForBackup(plainStream, backupKey) -> Stream<List<int>>`（用备份口令派生密钥重加密的密文流）。
- 前提：M6 调用，传入备份口令派生密钥
- 操作：先取明文流，再喂入重加密流
- 结果：链式流式处理，明文不落文件

### R7 · 异常路径定义
统一异常类型：
- `MediaCorruptedException`：密文 auth tag 校验失败
- `MediaNotFoundException`：rel_path 指向的文件不存在
- `KeyMissingException`：device media key 不可用

## 非功能需求

### NF1 · 加密强度
对称算法 MUST 为 **AES-256-GCM**（或等价 AEAD 算法），每个文件随机 nonce（12 字节），auth tag 附在文件末尾。MUST 避免 nonce 复用。

### NF2 · 流式不爆内存
任何 put / read 操作 MUST 是流式（按 64 KiB 量级分块），单条 100 MiB 媒体 MUST 不爆内存（峰值 RSS 增量 < 200 MiB）。

### NF3 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上读写一致——某端写入的密文文件能在同设备另一进程读取；跨设备读取（迁移）走备份路径（M6），不在本里程碑要求。

### NF4 · 加密对吞吐影响有限
中端真机连续写入 100 MiB（10 张 10 MiB 图）吞吐 MUST ≥ 30 MiB/s；读取吞吐 MUST ≥ 50 MiB/s。低于该基线需在 design 中记录原因并升级到 verification。

### NF5 · 路径不外泄绝对路径
任何对外暴露的 API（含异常 message / 日志） MUST 使用相对路径；MUST 不出现 `/var/mobile/...` / `/data/data/...` 等绝对路径。
