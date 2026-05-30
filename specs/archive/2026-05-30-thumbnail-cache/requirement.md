---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-29
文档状态：草稿
---

# thumbnail-cache（缩略图缓存层）

## 背景

v6 第 7.1 / 9.4 节明确：时间线只解密加密**缩略图**（几十 KB 级，快），绝不在滚动中解全尺寸原图；缩略图与原图都用**设备密钥**加密，**不进备份**，可重建。还原期必须懒生成 + 后台预热，绝不同步全量重建（8.4 第 5 步）。本里程碑落地：缩略图生成、加密落盘（复用 M3 加密路径）、失效判断、可取消任务队列、后台预热 isolate。**滚动触发与未就绪占位 UI** 由后续 UI spec 接入；本里程碑只提供「请求一张缩略图」与「取消一个任务」的纯逻辑 API。

整体依赖 **M0**、**M1 设备媒体密钥**、**M2 MediaRepo（写入 thumb 字段）**、**M3 MediaStore（加密读写复用）**。

## 范围外

- 时间线 / 列表的滚动节流触发逻辑（依赖 UI 设计稿）。
- 未就绪占位 UI（灰块 / blurhash 渲染）—— 待设计稿；本期接口只暴露状态（`pending / ready / failed / cancelled`，见 R3）。
- 缩略图加密向备份的对接 ——**不进备份**（v6 9.4），本里程碑不需提供任何备份相关 API。
- 视频帧抽取缩略图 —— MVP 不做（只 image）。

## 功能需求

### R1 · 缩略图尺寸与编码
缩略图 MUST 按**长边 ≤ 384 px** 等比缩放（短边按原比例）；MUST 用 **JPEG quality 85** 重编码（avif/webp 留后续优化）。
- 前提：原图为 1500×1000
- 操作：生成缩略图
- 结果：缩略图长边 = 384，短边按比例 ≈ 256；JPEG 字节级 < 80 KB

### R2 · 加密落盘
缩略图 MUST 加密落盘到 `<app_documents>/thumbs/<media_id>.bin`，**使用设备媒体密钥**（与原图同一把，复用 M3 MediaCodec 文件格式）；MUST 在 media 表写入 `thumb_path = "thumbs/<media_id>.bin"`、`thumb_w`、`thumb_h`、`thumb_src_updated_at = media.updated_at` 当时值。

### R3 · 按需生成 API（唯一契约）
系统 MUST 提供**唯一一个请求入口** `ThumbnailCache.request(mediaId, {ThumbnailPriority priority = ThumbnailPriority.normal}) -> ThumbnailHandle`（同步返回 handle；生成结果经 `handle.future` 异步交付）。R5（优先级）、R6（warmup）均复用此入口，不另立 `requestWithPriority` 等并行签名。
- 若 media 表已有 thumb_path 且 `thumb_src_updated_at == media.updated_at`：handle 直接进入 ready
- 否则入队生成任务 → 完成后 handle 进入 ready
- 错误（原图损坏 / 解码失败）handle 进入 failed + 原因

```dart
enum ThumbnailPriority { normal, low }          // 仅两档，见 R5；normal 默认，low 给 warmup
enum ThumbnailState { pending, ready, failed, cancelled }  // cancelled 由 R5 取消路径产生

class ThumbnailHandle {
  ThumbnailState get state;
  Future<ThumbnailResult> get future;            // 失败时携带原因（如 ThumbnailGenerationException）
  void cancel();
}

class ThumbnailResult {
  final String relPath;
  final int w;
  final int h;
}
```

### R4 · 失效判断（脏比较）
判断缩略图是否需重建：**对比 `media.thumb_src_updated_at` 与 `media.updated_at`**；不一致即过期。
- 前提：原图被替换、`media.updated_at` 更新但 `thumb_src_updated_at` 未更新
- 操作：再次 `request`
- 结果：重新生成、覆盖旧缩略图、更新 `thumb_src_updated_at` 为最新

不引入独立脏标志位（v6 9.4 明确）。

### R5 · 可取消任务队列
请求队列 MUST 支持：
- `request` 返回 handle 持有 `cancel()` 方法 → 任务未开始时直接弃；进行中时尝试中断（解码/编码块边界）
- 同一 mediaId 重复 request 复用第一个任务（不重复入队）
- 队列优先级仅 **normal / low 两档**（`enum ThumbnailPriority { normal, low }`，见 R3）：`request` 默认 normal；warmup（R6）用 low。本里程碑**不引入** high 档——视口可见优先级提升属未就绪占位 UI（范围外），待 UI spec 接入时再评估是否扩档。
- 优先级通过 R3 唯一入口的具名参数 `request(mediaId, priority: ...)` 传入，**不另设** `requestWithPriority` 等并行 API。

### R6 · 后台预热
系统 MUST 提供 `ThumbnailCache.warmup(List<mediaId>)`：以 low 优先级批量预热；MUST 在独立 isolate 中执行解码/编码（CPU 重活），不阻塞主 isolate。
- 前提：还原刚完成、用户刚回到时间线
- 操作：调 `warmup(ids)`
- 结果：后台 isolate 按 low 优先级逐张生成，前台 normal 请求可抢占

### R7 · 还原期约束（与 M6 协作）
本里程碑 MUST 保证：还原（M6）后**不会被强制同步全量重建**。M6 调用方式只能是「不调」（按需）或「调 warmup」（异步预热）。`ThumbnailCache.warmup` MUST 不阻塞调用者。

### R8 · 元数据一致性（补偿式：先文件 → db 事务 → db 失败删文件）
文件 IO 进不了 SQLite 事务（物理不可能在「同一事务内同时更新文件 + db 行」），故采用补偿式次序，遵守 `docs/design/09`「约定一·通用写入」：
1. 先写缩略图文件到 `<thumbs>/<media_id>.bin.tmp` → rename 为 `<thumbs>/<media_id>.bin`；
2. db 事务更新 media 表 thumb 字段（`thumb_path` / `thumb_w` / `thumb_h` / `thumb_src_updated_at`）；
3. **db 事务失败 MUST 删除步骤 1 已写的缩略图文件**，使「文件在、db 无引用」的孤儿不残留，任务整体视为失败。
- 不变式：media 表 `thumb_path` 指向的文件必然已落盘；进程在步骤 2 前崩溃留下的孤儿文件（db 未引用）无害，由后续运维/启动清扫处理（见 D2 代价）。

## 非功能需求

### NF1 · 生成性能
中端真机生成单张缩略图（原图 1500×1000）MUST < 200 ms（包含 isolate dispatch + 解码 + 缩放 + 重编码 + 加密落盘 + db 写入）。

### NF2 · 内存上限
后台预热并发 MUST ≤ 2 个 isolate；峰值 RSS 增量 MUST < 250 MiB（多张大图同时解码场景）。

### NF3 · 取消响应
被取消的任务 MUST 在 100 ms 内停止占用 CPU（不强求字节级中断，仅在解码/编码/写盘块边界 check 取消信号）。

### NF4 · 多端
SHALL 在 iOS / Android 真机产生相同质量缩略图（JPEG quality / 长边一致）。

## 专项维度逐维表态

> §0 五个专项维度逐维显式表态，任一为「是」即升标准档。本 spec 已选**标准档**（性能、多端均「是」，且含 NF + verification.md）。

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 是 | 缩略图复用设备媒体密钥加密落盘（R2），属加密数据写入路径，须保证不退化为明文。 |
| 权限 | 否 | 不读写系统相册 / 相机 / 网络，仅在 app 私有目录 `<thumbs>/` 内生成派生文件，无新增运行时权限。 |
| 无障碍 | 否 | 本里程碑只暴露纯逻辑 API，不含任何 UI；未就绪占位、视口渲染均属范围外的 UI spec。 |
| 性能 | 是 | NF1 单张 < 200ms、NF2 ≤ 2 isolate 且峰值 RSS < 250 MiB、NF3 取消 < 100ms，均为可度量硬约束。 |
| 多端兼容 | 是 | NF4 要求 iOS / Android 真机产出相同质量缩略图（JPEG quality / 长边一致）。 |
