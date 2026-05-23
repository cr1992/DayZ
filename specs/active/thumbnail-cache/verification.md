---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
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
- [ ] 中端真机平均生成 < 200ms — 人工（@Ray），数据来源 T7
- [ ] 峰值 RSS < 250 MiB — 人工（@Ray）

### 取消响应（NF3）
- [ ] cancel 调用到 state=cancelled 间隔 < 100ms — 自动：T6 测试

### 多端（NF4）
- [ ] iOS 与 Android 生成缩略图尺寸一致（同源图）— 自动：跨端测试可在 CI 跑 unit-only
- [ ] iOS 真机演示通过 — 人工（@Ray）
- [ ] Android 真机演示通过 — 人工（@Ray）

### 与 M6 还原期协作（R7）
- [ ] ThumbnailCache 未暴露任何同步全量重建 API — 自动：grep 接口列表
- [ ] warmup 返回是异步 Future 但调用立即返回 — 自动

## 回归检查

- [ ] M3 模块单测仍全过 — 自动：`flutter test test/media/`
- [ ] M2 MediaRepo.updateThumb 路径有测试覆盖 — 自动
- [ ] Debug Home 其他 demo 未受影响 — 人工（@Ray）

## 验证命令（汇总自动项）

```bash
flutter analyze
flutter test test/thumbnails/
flutter test
```
