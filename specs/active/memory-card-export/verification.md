---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：memory-card-export

> 落「能由本屏 / 本组件 widget test 独立验证」的跨任务集成与专项检查；单任务自身可验的（单卡宽高比 / 单个回调 / exporter PNG bytes 等）留在 tasks 各任务，不在此重复。
> 验收口径对齐方法论 §4/§11：样式参数闸（解析渲染后样式 == token / 设计值）、布局几何闸（`tester.getRect` 断顺序 / 包含 / 不溢出 + fixed-geometry 尺寸位置；content-driven 文本块不硬断块高）、golden 兜栅格、无障碍专项。**参数 / 几何抽取 harness 与 SSIM 兜底属 `design-sync-automation`（跨 spec 依赖）**——本 spec 几何 / 样式断言用 Flutter 原生 `tester.getRect` / 解析 widget 属性自验，**不依赖 harness 就绪**；「对设计稿源屏 `memory.html` 比框 / 区域 SSIM」留给 design-sync 期二，不在本 spec 重造。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 单卡预览 | 以单条 `MemoryCardData` 进屏 | 竖版 + 纸感单卡可见，标题 / 摘要 / 往年段 / 页脚字标在场 | R1 | 自动 |
| 画幅：竖版↔方形 | 切画幅段 | 单卡宽高比在 9:16 / 1:1 间切，选中态更新 | R2 | 自动 |
| 画幅：切长图 | 切到长图 | 显示 `DayzMemoryLongCard`、单卡隐藏、风格行禁用置灰 | R2, R3 | 自动 |
| 风格：纸感↔大图压字 | 切风格段（非长图） | 单卡在 paper/photo 版式间切 | R3 | 自动 |
| 长图固定纸感联动 | 长图→切回竖版 | 风格行恢复可交互、沿用上次风格 | R3 | 自动 |
| 长图多段 | 以 N 段 `MemoryDayData` 切长图 | 段数 == N，「写过 N 篇」/「共 N 段回忆」计数正确（intl 成品文案） | R4 | 自动 |
| 保存到相册 | 点保存（注入假 exporter） | `saveToGallery` 被调用、收当前卡片 widget；成功出 toast | R5 | 自动 |
| 保存失败 / 拒权 | 假 exporter 返回 error | 失败 toast（tone=danger）、不崩溃、不静默吞 | R5, NF6 | 自动 |
| 分享 | 点分享（注入假 exporter） | `share` 被调用、出分享 toast | R6 | 自动 |
| 分享取消 | 假 exporter 返回 cancelled | 静默回屏、不报错 | R6 | 自动 |
| 取数边界 | 静态解析屏 / 卡片 / 模型源码 import | 不含 `package:.../data/` / Drift 句柄，数据经纯模型入参 | R7 | 自动 |
| Debug Home 入口 | 进入 `demos` 末尾新增项 | 假数据渲染本屏、可切 / 可触发假导出 | R8 | 自动 |

## 专项检查
> 对应 requirement 的 NF 编号。

### 无障碍（NF1, NF2, NF3, NF4）
- [ ] 纸感款正文 / 标题（`--ink`/`--ink-2` 落 `--surface`）≥ 4.5:1 — 自动：`flutter test test/ui/memory_card_export/contrast_test.dart`（按 `ThemeData` 渲染对算相对亮度比，六套逐项；复用 tokens-theme 机器真源 `test/ui/theme/contrast_xfail.yaml`，遇 expected-fail 阻塞、报 @Ray，不新建 xfail 源）
- [ ] 往年段着色文字（`--accent-ink` 落 `--accent-soft`）≥ 4.5:1 — 自动：同上
- [ ] 大图压字款白字落底部渐变最暗端区域 ≥ 4.5:1 — 自动：同上（按渐变末端 `rgba(20,16,12,0.82)` 对验白字；照片中段局部低对比属设计取舍，记已知像素差不阻塞）
- [ ] 画幅 / 风格每项、保存 / 分享、返回钮命中区 ≥ 44×44 — 自动：`flutter test test/ui/memory_card_export/`（`getRect` 断命中盒，NF2）
- [ ] 返回 / 画幅项 / 风格项 / 保存 / 分享有 Semantics 标签，分段选中态经语义暴露 — 自动：`find.bySemanticsLabel(l10n.xxx)` + selected 语义（NF3）
- [ ] 切换 / 长图滚动 / 底栏动效在 `disableAnimations:true` 下时长为 0 — 自动：注入 `MediaQueryData(disableAnimations:true)` 断动效时长为 0（NF4，经 `dayzMotionDuration` 门）

### 安全 / 权限（NF6, R5, R6）
- [ ] 无自动导出：未点保存 / 分享时 exporter 不被调用 — 自动：pump 屏不触发交互，断假 exporter 零调用（D8）
- [ ] 失败 / 拒权显形：假相册 sink 返回拒权 → 失败 toast、不静默 — 自动：屏 test 注入失败 exporter 断 toast（NF6/R5）
- [ ] UI 不暗示导出物受保护 / 加密：屏内文案集合无「加密 / 受保护 / 安全」类误导词 — 人工（@Ray）：复核 `AppLocalizations` 本屏条目无暗示导出物仍受保护的措辞（明文外发是有意为之，docs/design/06）
- [ ] 导出进行中防重入：`_exporting` 时连点保存 / 分享不二次触发 — 自动：连点断 exporter 仅调一次（NF7/D8）
- [ ] 缩略图红线：预览 / 导出路径不触发缩略图生成 / 重建 — 自动：屏 / exporter 源码不 import 缩略图生成入口、封面只消费传入 `ImageProvider`；静态核验 import + 断不依赖缩略图生成 API（NF6，docs/design/05）

### 多端兼容（NF5, NF7）
- [ ] 离屏栅格化以 `pixelRatio = max(devicePixelRatio, 3.0)` 产出清晰 PNG，位图尺寸 == 卡片逻辑尺寸 × pixelRatio — 自动：`flutter test test/ui/memory_card_export/memory_card_exporter_test.dart`（断 PNG 可解码 + 尺寸，NF7）
- [ ] 长图导出含完整长卡（非仅视口）— 自动：断导出位图高度 ≈ 完整子树高度 × pixelRatio（NF7）
- [ ] iOS 13+ 真机 / 模拟器：保存到相册（Photos 权限）+ 分享面板正常，失败路径有反馈 — 人工（@Ray）
- [ ] Android 8+ 真机 / 模拟器：保存到相册（MediaStore / 旧权限）+ 分享正常，失败路径有反馈 — 人工（@Ray）

### 栅格观感（§4 ④ 闸，advisory）
- [ ] 两风格 × 三画幅 + 长图 golden 基线 — 自动：`flutter test test/ui/memory_card_export/`（golden 回归锁）
- [ ] 对设计稿源屏 `memory.html` 的区域 SSIM / 视觉终审 — 依赖 `design-sync-automation`（参数 / 几何抽取 harness + 区域化 SSIM）期二补；本 spec 不重造 harness，残余像素差（saturate 无 / 照片中段对比 / 长图换行）进 SYNC_REPORT 标红、不阻塞

> 数据迁移 / 回滚：本 spec 无持久化 schema 变更或数据格式演进（取数经 Repository 只读、导出只写系统相册 / 分享，不改 DB）→ 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（回忆卡片 demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（单卡）、R2（画幅）、R3（风格 + 长图联动）、R4（长图多段）、R5（保存 + 失败）、R6（分享 + 取消）、R7（取数边界）、R8（Debug Home）、NF1（对比度）、NF2（命中区）、NF3（Semantics）、NF4（reduce-motion）、NF5（多端）、NF6（安全 / 缩略图红线）、NF7（栅格质量 / 完整长图 / 防重入）均有对应场景或专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter pub get
flutter test test/ui/memory_card_export/   # 模型/单卡/长图/底栏/exporter/屏/对比度
flutter test test/demo/                    # 回忆卡片 demo + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`*_test.dart`（含 `contrast_test.dart`、各组件 / 屏 / exporter test）由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；真正需预批的非 `_test.dart` 共享基建——`test/ui/memory_card_export/fixtures/`（假 `MemoryCardData`/`MemoryDayData` + 占位图 provider + 可注入假 exporter / 假分享 / 假相册 sink）与 `test/ui/memory_card_export/golden/`（golden 基线）——已在 T1/T2/T3/T5/T6 的 inline `验收基建` 字段预批（执行协议第 2 条）。对比度机器真源复用 tokens-theme 的 `test/ui/theme/contrast_xfail.yaml`，本 spec 不新建第二处。
