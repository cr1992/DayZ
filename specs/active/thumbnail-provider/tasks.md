---
作者：@Ray
创建日期：2026-10-10
---

# 任务列表：thumbnail-provider

## 依赖速览
> 以各任务 inline「同 spec 依赖」字段为准；跨 spec 依赖以 README「依赖」列为准。
T1 → T2

-----

- [x] T1 · 解密图源 + LRU（`ThumbnailImageLoader` / `ThumbnailImageProvider`）

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** `thumbnail-cache`：`ThumbnailCache.request` / `ThumbnailHandle` / `decryptBytes`；`media-storage`：`MediaCodec` 文件格式、`resolveRelPathWithDocumentsDir`、`MediaCorruptedException` ｜ **关联需求：** R1, R2, R3, R4 ｜ **依据设计：** D1, D2, D3, D4 ｜ **可改文件：** `lib/thumbnails/thumbnail_image_provider.dart` ｜ **验收基建：** `test/thumbnails/thumbnail_image_provider_test.dart`

### 背景
补齐「relPath → 可渲染图源」这一层。归属：本任务只在 `lib/thumbnails/` 里新增加载器和图源，不改 `ThumbnailCache` / generator 的既有行为，也不接线组合根（接线归 T2）。

### 实施
1. 按 D1 定义 `ThumbnailRequester` / `ThumbnailKeyLoader` / `ThumbnailDecryptor` 三个 typedef 和 `ThumbnailImageLoader`（`warmup` / `providerFor` / `load` / `evict` / `clear`）。
2. `load`：先查 LRU 再查在途表；未命中时等 `request(id).future` → 读密文 → 取设备媒体密钥 → 缺省用 `Isolate.run` 解密 → 清零密钥副本 → 入 LRU（D2 / D3）。失败只清在途表，不入缓存（R4）。
3. LRU 用 `LinkedHashMap`，张数和字节双上限，单张超过字节上限时不入缓存（D4）。
4. `ThumbnailImageProvider`：`obtainKey` 返回自身，`loadImage` 返回 `MultiFrameImageStreamCompleter`，字节经 `ImmutableBuffer` 交给 `decode`；`==` / `hashCode` 按 (mediaId, loader 同一性)。

### 验收标准（做完即止）
- 端到端：真 `ThumbnailCache` 生成 800×400 原图的缩略图后，`load` 返回的字节能解码成 384×192 的 JPEG，而磁盘上的 `thumbs/<id>.bin` 不以 JPEG SOI 开头（R1，自动）。
- `providerFor` 不触发请求；同 id、同加载器的图源相等，换 id 或换加载器则不等（R2，自动）。
- widget：handle 完成前 `Image` 的 `frameBuilder` 拿到的 frame 为 null（占位），解密次数为 0；完成后异步出帧，`RawImage` 尺寸为 4×3（R2，自动）。
- LRU：`maxEntries=2` 时 a、b、a、c 的访问序列会淘汰 b，a 的命中不会再请求；字节上限按 LRU 淘汰，超过上限的单张不入缓存；同 id 并发请求只请求、解密一次（R3，自动）。
- 错密钥抛 `MediaCorruptedException` 且不入缓存，第二次请求会重新请求；生成失败原样透出；错密钥时 `Image` 走 `errorBuilder`；`warmup` 用 low 优先级入队，失败不抛给调用方（R4，自动）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub -j 1 test/thumbnails/thumbnail_image_provider_test.dart
  ```
  （断言解码尺寸、密文落盘、帧状态、LRU 成员与请求 / 解密计数、异常类型；不 grep 源码）

### 验收记录
```
日期：2026-10-10
自动：`flutter test --no-pub -j 1 test/thumbnails/thumbnail_image_provider_test.dart` 通过（10 tests：端到端解密 384×192 + 落盘仍为密文、provider 惰性与相等性、未就绪无帧→异步出帧、LRU 张数 / 字节 / 并发去重、错密钥 MediaCorruptedException 不缓存可重试、生成失败透出、errorBuilder 兜底、warmup low 优先级吞错）；`flutter analyze --no-pub` 两文件 No issues。
人工：N/A
```

-----

- [x] T2 · 组合根构造缩略图缓存，并接上往年今日缩略图端口

**同 spec 依赖：** T1 ｜ **跨 spec 依赖：** `thumbnail-cache`：`ThumbnailCache`；`media-storage`：`MediaStore` ｜ **关联需求：** R5 ｜ **依据设计：** D5 ｜ **可改文件：** `lib/app/app_services.dart`、`lib/app/router_ports.dart` ｜ **验收基建：** `test/app/thumbnail_wiring_test.dart`

### 背景
onthisday-screen 的 `registerOnThisDayRepository` 已经留好了 `thumbnails:` 参数，controller 也只用 `warmup` + `providerFor`。本任务只在组合根里构造对象并传进去，不改 `lib/ui/onthisday` 和外壳路由。

### 实施
1. `AppServices.forDatabase` 增加可选的 `keyProvider` / `documentsDirectoryProvider` 参数，构造 `keyProvider`、`thumbnailCache`、`thumbnailImages` 三个字段；`open` 透传 `keyProvider`；`close` 时 `thumbnailImages.clear()`。
2. `router_ports.dart`：私有 `_OnThisDayThumbnailsAdapter implements OnThisDayThumbnails` 委托给 `services.thumbnailImages`；`bindRouterPorts` 用它注册 `registerOnThisDayRepository(..., thumbnails: ...)`；`MediaStore` 的密钥缺省改为 `services.keyProvider`。
3. `unbindRouterPorts` 保持 `registerOnThisDayRepository(null)`（端口随仓库一并清空）。

### 验收标准（做完即止）
- `bindRouterPorts(services)` 后 `onThisDayThumbnailsPort` 非空，`unbindRouterPorts` 后为空（R5，自动）。
- 内存库 + 临时文档目录 + 固定设备密钥：端口的 `providerFor(mediaId)` 是 `ThumbnailImageProvider`，经 `services.thumbnailImages.load` 能解出该媒体的缩略图（长边 384）；`warmup` 让该媒体的 `thumb_path` 落库（R5，自动）。
- 往年今日 controller 用真实端口加载时，带图条目的 `coverImage` 是 `ThumbnailImageProvider`，无图条目为 null（R5，自动）。
- 既有 `test/app`、`test/ui/onthisday`、`test/demo` 全部通过（回归，自动）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub -j 1 test/app/thumbnail_wiring_test.dart
  flutter test --no-pub -j 1 test/thumbnails test/app test/ui/onthisday test/demo
  ```
  （断言端口注册状态、图源类型、解码尺寸、`thumb_path` 落库与 VM 封面；不 grep 源码）

### 验收记录
```
日期：2026-10-10
自动：`flutter test --no-pub -j 1 test/app/thumbnail_wiring_test.dart` 通过（4 tests：端口注册 / 清空、端口图源解出 384×288 缩略图、warmup 落库 thumb_path 且文件存在、controller 带图条目 coverImage 为 ThumbnailImageProvider / 无图为 null）；回归 `flutter test --no-pub -j 1 test/thumbnails test/app test/ui/onthisday test/demo` 全绿（124 tests）；`flutter analyze --no-pub lib/app lib/thumbnails test/app test/thumbnails` No issues（全仓 error 仅在 packages/ 下 vendored 包，既有、与本次无关）。
人工：N/A
```
