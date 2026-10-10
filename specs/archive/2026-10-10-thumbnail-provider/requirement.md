---
作者：@Ray
创建日期：2026-10-10
---

# thumbnail-provider（缩略图解密图源）

> 修复自 [thumbnail-cache](../../archive/2026-05-30-thumbnail-cache/)（归档后返工 → 新建精简档）。

## 背景

`thumbnail-cache` 交付了生成、加密落盘、失效判断、可取消队列和 `warmup`，但 `ThumbnailHandle` 只交出 `ThumbnailResult.relPath`，屏拿不到能直接渲染的图源；生产组合根也没有构造 `ThumbnailCache`。所以往年今日（`OnThisDayThumbnails` 端口，见 onthisday-screen D3 / D8）在真路由下注不进缩略图，卡片封面一直不出现。

本 spec 补一层「读密文缩略图 → 用设备媒体密钥解密 → 交给引擎异步解码」的图源，并在组合根里构造 `ThumbnailCache`、把缩略图端口接给往年今日。原设计的约束照旧：缩略图用设备密钥加密、不进备份；还原期不同步全量重建；没就绪就显示占位，不在 build 或滚动路径上同步解码。

## 范围外

- 生成、加密落盘、队列、失效判断的行为 MUST NOT 改动（仍归 `thumbnail-cache` 的实现）。
- 占位的视觉（灰块、blurhash、淡入）和 `DayzEntryCard` 图位的 `frameBuilder` / `errorBuilder` MUST NOT 在本 spec 里做，归「ui-kit 小补」。
- 阅读屏封面和相册 MUST NOT 在本 spec 里接线：阅读路由（`lib/ui/shell/app_router.dart`）没有传 `thumbnailCache` 的入口，接线要改外壳路由，记为已知风险。
- 原图（全尺寸）解密与大图查看器 MUST NOT 走本图源。
- 不新增密钥，不改 `MediaCodec` 文件格式，不改 `KeyProvider`。

## 需求

### R1 · 解密图源

系统 SHALL 为任一媒体 id 提供一个 `ImageProvider`。图像被解析时，它经 `ThumbnailCache.request` 等到缩略图就绪，读出 `thumbs/<id>.bin` 密文，用设备媒体密钥（`KeyProvider.getDeviceMediaKey`，不经主密码）解密成 JPEG 明文，再交给引擎解码。
- 前提：媒体行存在，原图是设备密钥加密的 JPEG。
- 操作：渲染该媒体 id 的图源。
- 结果：渲染出的图像尺寸等于缩略图尺寸（长边 ≤ 384）；磁盘上的缩略图仍是密文。

### R2 · 未就绪占位，不同步解码

构造图源 MUST NOT 触发任何请求、IO 或解码。缩略图就绪之前 `Image` MUST 处于「无帧」状态，调用方据此显示占位；解密 MUST 在后台 isolate 里异步完成（测试可注入同 isolate 解密），图像解码交给引擎的 `ImageStream` 异步完成。对外 MUST NOT 暴露同步取图或同步重建入口。

### R3 · 内存上限与复用

解密后的明文字节 SHALL 放在一个同时有张数上限和字节上限的 LRU 里（默认 64 张、8 MiB），只留在内存，MUST NOT 落盘。
- 命中 LRU MUST NOT 再请求或解密，并把该项刷新为最近使用。
- 超过任一上限 MUST 淘汰最久未用的项；单张超过字节上限时照常返回，但不进缓存。
- 同一 id 的并发请求 MUST 只请求一次、解密一次。

### R4 · 失败路径

If 解密失败（如密钥不对、密文损坏），then 系统 SHALL 让这次取图失败并抛出 `MediaCorruptedException`；If 缩略图生成失败，then 原样透出该错误。两种情况下 `Image` 都 SHALL 走 `errorBuilder`，失败结果 MUST NOT 进缓存，下次请求会重试。`warmup` 的失败 MUST NOT 抛给调用方。

### R5 · 组合根接线

生产组合根 `AppServices` SHALL 构造唯一的 `ThumbnailCache` 和解密图源加载器。`bindRouterPorts` SHALL 把缩略图端口（`warmup` + `providerFor`）随 `registerOnThisDayRepository` 一起注册，`unbindRouterPorts` 一并清空。
- 前提：内存库组合根，往年今日的某条目带一张图片媒体。
- 操作：`bindRouterPorts(services)` 后读取往年今日缩略图端口。
- 结果：端口非空；它产出的图源能解出该媒体的缩略图；`warmup` 以 low 优先级入队。

## 专项维度逐维表态

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 复用现成的设备媒体密钥和 `MediaCodec` 格式，不新增密钥、不改加密路径、不新增落盘；明文只放进有上限的内存 LRU，取完即清零密钥副本。 |
| 权限 | 否 | 只读 App 私有目录 `thumbs/`，不新增运行时权限。 |
| 无障碍 | 否 | 只提供图源，不新增 UI；语义和占位视觉归各屏 / ui-kit。 |
| 性能 | 否 | 不新增性能阈值；生成性能沿用 thumbnail-cache 的 NF1 / NF2，LRU 上限是单任务内可测的配置边界（R3）。 |
| 多端兼容 | 否 | 纯 Dart + Flutter 引擎解码，不涉及平台通道或平台差异。 |
