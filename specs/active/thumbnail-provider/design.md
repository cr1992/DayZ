---
作者：@Ray
创建日期：2026-10-10
---

# 设计：thumbnail-provider

## 技术决策

### D1 · 图源形态：`ThumbnailImageLoader` + `ThumbnailImageProvider`
- **背景：** 往年今日端口 `OnThisDayThumbnails` 要的是 `warmup(mediaIds)` 和 `ImageProvider providerFor(mediaId)`（onthisday-screen D3）；`DayzEntryCard` / `DayzGallery` 吃的也是 `ImageProvider`。现有 `ThumbnailHandle` 只给 relPath。
- **选择：** 在 `lib/thumbnails/thumbnail_image_provider.dart` 新增：
  ```dart
  typedef ThumbnailRequester =
      ThumbnailHandle Function(String mediaId, {ThumbnailPriority priority});
  typedef ThumbnailKeyLoader = Future<Uint8List> Function();
  typedef ThumbnailDecryptor =
      Future<Uint8List> Function(Uint8List cipher, Uint8List key);

  class ThumbnailImageLoader {
    ThumbnailImageLoader({
      required ThumbnailRequester request,        // 传 ThumbnailCache.request 的 tear-off
      required ThumbnailKeyLoader loadDeviceMediaKey,
      DocumentsDirectoryProvider? documentsDirectoryProvider,
      ThumbnailDecryptor? decrypt,                // 缺省 Isolate.run(decryptBytes)
      int maxEntries = 64,
      int maxBytes = 8 * 1024 * 1024,
    });
    void warmup(List<String> mediaIds);           // request(id, low)，失败吞掉
    ThumbnailImageProvider providerFor(String mediaId); // 纯构造，无 IO
    Future<Uint8List> load(String mediaId);       // 解密后的 JPEG 字节
    void evict(String mediaId);
    void clear();
  }

  class ThumbnailImageProvider extends ImageProvider<ThumbnailImageProvider> {
    // key = (mediaId, identical(loader))；loadImage → MultiFrameImageStreamCompleter
  }
  ```
  `load` 的流程：查 LRU → 查在途表 → `request(id).future` 等就绪 → 读 `<docs>/<relPath>` 密文 → 取设备媒体密钥 → 解密 → 清零密钥副本 → 入 LRU。
- **理由：** 加载器只依赖一个函数签名，不依赖 `ThumbnailCache` 的具体类，测试可以注入可控的请求方；图源本身是标准 `ImageProvider`，屏和 ui-kit 不用改。
- **代价：** 多出一个和 `ThumbnailCache` 并列的对象，组合根要同时持有两者。

### D2 · 密钥归属：设备媒体密钥，不经主密码
- **背景：** 原设计规定缩略图和原图用同一把设备媒体密钥加密、不进备份（thumbnail-cache R2 / D2）。
- **选择：** 每次解密都经 `KeyProvider.getDeviceMediaKey` 现取（HKDF 从设备根密钥派生，主密码模式下也不需要主密码），用完 `fillRange(0)` 清零本地副本；加载器不缓存密钥。
- **理由：** 与原图、生成路径同一把钥匙、同一种格式，不新增任何密钥材料。
- **代价：** 每次缓存未命中都要多读一次安全存储；缩略图只在未命中时才解密，次数有限，可以接受。

### D3 · 异步与线程：后台 isolate 解密 + 引擎解码
- **背景：** 原设计口径是「绝不在滚动中解原图」，未就绪显示占位。`cryptography` 的 AES-GCM 是纯 Dart 实现，在主 isolate 上解几十 KB 也会占用帧时间。
- **选择：** 解密缺省走 `Isolate.run(() => decryptBytes(cipher, key))`，复用 `generator.dart` 的 `decryptBytes`；图像解码走 `ImageDecoderCallback`（引擎异步）。`obtainKey` 是同步 future（key 就是 provider 自身），但 `loadImage` 只返回一个 completer，真正的工作都在 future 里。
- **理由：** build 和滚动路径上只有「构造 provider」和「Image 订阅 stream」这两步，都是 O(1) 且没有 IO。
- **代价：** 每次未命中都有一次 isolate 启动开销（约 5–10 ms），只在后台，不阻塞帧。

### D4 · 内存与缓存上限
- **背景：** 往年今日、时间线可能一屏有多张封面，反复滚动时不该重复解密。
- **选择：** 用 `LinkedHashMap` 实现 LRU 缓存解密后的 JPEG 字节，默认 **64 张 / 8 MiB** 双上限，超过任一上限就淘汰最久未用的项；单张超过字节上限时照常返回、不进缓存；在途请求按 id 去重；失败结果不进缓存。解码后的 `ui.Image` 由 Flutter 全局 `ImageCache`（`PaintingBinding.imageCache`）管理，key 就是 provider，不归本 spec 管。`AppServices.close` 时 `clear()`。
- **理由：** 一张缩略图 < 80 KB（thumbnail-cache R1），8 MiB 能放下所有常见的一屏加回滚余量；张数上限防止大量极小图把 map 撑大。
- **代价：** 明文 JPEG 留在进程内存里，直到被淘汰或进程退出；这与 `ImageCache` 本来就持有已解码像素的风险等级相同。

### D5 · 组合根与端口接线
- **背景：** `AppServices` 没有构造 `ThumbnailCache`；`registerOnThisDayRepository` 已经有 `thumbnails:` 命名参数（onthisday-screen D8）。
- **选择：** `AppServices.forDatabase(database, {KeyProvider? keyProvider, DocumentsDirectoryProvider? documentsDirectoryProvider})` 构造 `keyProvider`、`thumbnailCache`（`ThumbnailCache`）和 `thumbnailImages`（`ThumbnailImageLoader`，请求方是 `thumbnailCache.request`）；`open` 把它拿到的 `keyProvider` 传进去。`bindRouterPorts` 用一个私有适配器（`warmup` → `thumbnailImages.warmup`，`providerFor` → `thumbnailImages.providerFor`）实现 `OnThisDayThumbnails`，传给 `registerOnThisDayRepository(thumbnails: ...)`；`MediaStore` 的密钥来源改为缺省用 `services.keyProvider`（显式传参仍然优先）。适配器放在 `lib/app/`，所以 `lib/thumbnails` 不反向依赖 `lib/ui`。
- **理由：** 进程内只有一个 `ThumbnailCache`，它的队列和并发上限（≤ 2）全局生效；屏和 controller 不用改。
- **代价：** `AppServices` 多了三个字段；测试用的内存组合根也会构造一个 `KeyProvider()`（构造本身不碰平台通道）。

## 文件变更

- `lib/thumbnails/thumbnail_image_provider.dart`   新建（D1–D4）
- `lib/app/app_services.dart`                       修改（D5：构造 `ThumbnailCache` / `ThumbnailImageLoader`，`close` 清缓存）
- `lib/app/router_ports.dart`                       修改（D5：往年今日缩略图端口适配并注册；`MediaStore` 缺省用 `services.keyProvider`）
- `test/thumbnails/thumbnail_image_provider_test.dart`  新建
- `test/app/thumbnail_wiring_test.dart`             新建
- `specs/active/thumbnail-provider/`               新建（本 spec）
- `specs/README.md`                                 修改（进行中表加一行；删掉「待立 spec」里对应的那条）

## 已知风险

- **阅读屏封面和相册仍然不出图：** `reader_image.dart` 的 `ThumbnailCacheReaderAdapter` 在就绪后返回透明占位图，并且阅读路由（`lib/ui/shell/app_router.dart`）不往 `ReaderScreen` 传 `thumbnailCache`。要接上需要改外壳路由，而且应把适配器的 `provider` 换成 `ThumbnailImageLoader.providerFor`；这超出本 spec 的可改范围，留给 reader-screen 维护卡。
- **`DayzEntryCard` 图位没有 `frameBuilder` / `errorBuilder`：** 往年今日真路由下，就绪前图位是空白，失败时也没有兜底（归「ui-kit 小补」）。本图源已经按 R2 / R4 提供了「无帧」和错误这两种状态，ui-kit 补上之后会直接生效。
- **原图被替换后的陈旧缓存：** LRU 和 Flutter `ImageCache` 都按 mediaId 作 key。原图被替换时（`media.updated_at` 变了，`ThumbnailCache` 会重建缩略图），内存里可能还留着旧图，直到被淘汰；调用方可以用 `evict(mediaId)` 加 `provider.evict()` 主动失效。v1 里还没有「替换原图」的流程。
- **warmup 吞错：** 预热失败只在取图时才报出来，没有单独打日志。
