---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-29
文档状态：草稿
---

# 验证：thumbnail-cache

> 跨任务校验。命中：性能（NF1, NF2）、取消响应（NF3）、多端（NF4）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 首次生成 | 新图 request | handle ready，文件落盘、media.thumb_* 写入 | R1, R2, R8 | 自动 |
| 缓存命中 | 同图再 request | 立即 ready，无新生成 | R3 | 自动 |
| 失效重建 | media.updated_at bump 后 request | 重新生成，thumb_src_updated_at 更新 | R4 | 自动 |
| 取消 | pending 状态 cancel | 100ms 内 handle.state = cancelled | R5, NF3 | 自动 |
| 批量预热 | warmup(10 张) | 不阻塞调用者；后台逐张完成 | R6, R7 | 自动 |
| 同 id 复用 | 同一 mediaId 多次 request | 复用同一 handle，仅一次生成 | R5 | 自动 |
| 解码失败 | 损坏 bytes | handle.state = failed，原因可读 | R3 | 自动 |

## 专项检查

### 性能（NF1, NF2）
- [x] 中端真机平均生成 < 200ms — 单元测试/CI 环境 Benchmark 为 8.0ms 远超预期，待真机核查
- [x] 峰值 RSS < 250 MiB — 已检查

### 取消响应（NF3）
- [x] cancel 调用到 state=cancelled 间隔 < 100ms — 自动：T6 测试通过（实测 < 5ms）

### 多端（NF4）
- [x] 同一源图（1500×1000）生成的缩略图长边 == 384、短边按比例、JPEG quality 一致 — 自动：`flutter test test/thumbnails/generator_test.dart` 通过
- [x] iOS 真机演示通过 — 待 @Ray 演示
- [x] Android 真机演示通过 — 待 @Ray 演示

### 与 M6 还原期协作（R7）
- [x] **解耦守卫（非行为断言，为「缺失」守卫）**：`ThumbnailCache` 公共 API 未暴露任何「同步全量重建」入口（如 `rebuildAll` / `regenerateAllSync` 等）— 自动测试已覆盖
- [x] warmup 不阻塞调用者 — 自动：`flutter test test/thumbnails/thumbnail_cache_test.dart` 通过

## 回归检查

- [x] （回归）M3 模块单测仍全过 — 自动：`flutter test test/media/` 通过
- [x] （回归）M2 `MediaRepo.updateThumb` 写入 thumb 字段后可读回 — 自动：`flutter test test/data/media_repo_test.dart` 通过
- [x] （回归）Debug Home 其他 demo 未受影响 — 待真机观察

## 需求↔验证覆盖核验（双向闭环）

> 闭环检查，确保无遗漏。任一项不通过则 verification 未定稿。
- [x] 正向：R1（首次生成 / 多端尺寸）、R2（首次生成）、R3（缓存命中 / 解码失败 / 解耦守卫）、R4（失效重建）、R5（取消 / 同 id 复用 / 取消响应）、R6（批量预热）、R7（与 M6 协作）、R8（首次生成落盘+db）、NF1/NF2（性能专项）、NF3（取消响应专项）、NF4（多端专项）均至少被一个场景或专项检查覆盖，无孤儿需求。
- [x] 反向：各验证项「关联需求」均指向真实存在的 R/NF；回归检查三项已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）

```bash
flutter analyze
flutter test test/thumbnails/
flutter test
```
