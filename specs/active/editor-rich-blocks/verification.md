---
作者：@Ray
创建日期：2026-06-06
最后更新：2026-06-06
文档状态：草稿
---

# 验证：editor-rich-blocks（标注块 callout）

> 本文承载**跨任务校验**——callout 的「插入 → 渲染 → codec 往返 → 导出降级」串联依赖 T2/T3/T4 产物同时存在（见 requirement 选档说明）。单任务内可独立验证的断言（如 T1 封闭集、T4 单块降级）留各自 tasks 卡，不在此重复。

## 功能验证（端到端）
| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| callout codec 往返 | 含 callout（delta="记得复盘"）的 Document → `EditorDocCodec.encode` → `decode` | 还原节点 `type=='callout'`、delta 文本逐字一致；`supported` 含 callout | R1 | 自动 |
| callout 注册渲染 | decode 结果用 `EditorBlockRegistry` builders 渲染 | callout 走 `CalloutBlockComponentBuilder`，不落 `_UnknownBlockComponentBuilder`（无「[未支持块]」） | R1 | 自动 |
| callout 主题色渲染 | 在 amberDark / sageLight 两主题下分别渲染 callout | 背景 == 对应主题 `DayzColors.accentSoft`、图标 == `accentInk`、无左边框 | R2 | 自动 + 人工(@Ray 截图签收) |
| callout 真机视觉 | Patrol 设备上渲染 callout 并截图 | 截图工件产出，暖调 `--accent-soft` 底随主题、质感对齐设计稿 | R2 | 自动(Patrol)+人工(@Ray) |
| callout plain 降级 | `EditorPlainTextExtractor.extract(含 callout 文档)` | plain 含一行 `记得复盘`（与降级同源） | R3 | 自动 |
| callout markdown 降级 | callout 节点经 `EditorExportFallback` 取 markdown 行 | 前缀 `> ` + delta 文本 | R3 | 自动 |
| callout 空文本降级 | callout `delta` 为空时抽取 | 该行为空字符串、`extract` 不抛异常 | R3, NF1 | 自动 |
| 既有块不回归 | 跑 `editor-json-contract` 既有契约测试 | location/weather/标准块往返·抽取·降级全部通过 | NF3 | 自动 |
| 代码块后置登记 | 检查本轮交付 | `supported` 不含 code、registry 未注册 code builder | R4 | 人工(@Ray)·N/A（后置） |

## 专项检查

> 本 spec 无 NF 性能/安全/无障碍/多端阈值（见 requirement 选档说明，5 维全否）。下列为 callout 跨任务质量的视觉与一致性专项，非 NF 阈值检查。

### 视觉（R2 · Patrol 真机）
- [ ] callout 在设备上渲染、截图工件产出，主题 `--accent-soft` 跟随（amber/sage/purple × light/dark 任一切换可见变化） — 自动：`bash scripts/patrol_test.sh -d <device-id> --target patrol_test/editor_callout_visual_test.dart`（校验 `Total:` 非零、`Failed:` = 0，真实信号 = 截图工件 + 非零执行，非「测试跑过」）
- [ ] callout 暖调质感与设计稿 `.cb-callout` 一致、无左边框俗套 — 人工（@Ray，复核 Patrol 截图）

### 契约一致性（R1, R3, NF2, NF3）
- [ ] callout 配色仅引用 `DayzColors`（accentSoft/accentInk/ink），无写死 hex/`Colors.*` — 自动：`flutter test test/editor/contract/blocks/callout_block_test.dart`（断言渲染色 == 对应 `DayzColors` 取值，跨主题切换证随主题；行为断言而非源码 grep，满足 NF2）
- [ ] callout 进封闭集且 codec 往返无损 — 自动：`flutter test test/editor/contract/block_types_test.dart test/editor/contract/blocks/callout_block_test.dart`
- [ ] callout plain/markdown 降级与既有块同源、互不漂移 — 自动：`flutter test test/editor/contract/export_fallback_test.dart`

## 回归检查
- [ ] editor-json-contract 既有契约测试无破坏（往返/抽取/一致性） — 自动：`flutter test test/editor/contract/`（回归）
- [ ] 全量编辑器契约测试绿 — 自动：`flutter test test/editor/`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，确保无遗漏。任一项不通过则 verification 未定稿。
- [ ] 正向：R1（codec 往返 + 注册渲染场景）、R2（主题色渲染 + 真机视觉 + 视觉专项）、R3（plain/markdown/空文本降级场景）、R4（代码块后置登记场景）、NF1（空文本降级不崩溃）、NF2（配色一致性专项）、NF3（既有块不回归场景 + 回归检查）均有验证，无孤儿需求。
- [ ] 反向：每个验证项「关联需求」均指向真实 R/NF；回归检查已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/editor/contract/block_types_test.dart \
             test/editor/contract/blocks/callout_block_test.dart \
             test/editor/contract/export_fallback_test.dart
flutter test test/editor/contract/   # 回归：既有契约测试不破坏
bash scripts/patrol_test.sh -d <device-id> --target patrol_test/editor_callout_visual_test.dart  # R2 视觉
```

> 共享测试基建说明：`test/editor/contract/blocks/callout_block_test.dart` 针对 `blocks/callout_block.dart`、`export_fallback_test.dart` 针对 `export_fallback.dart`，均按栈测试命名约定落在测试目录，属隐含延伸预批（执行协议第 2 条），无需额外 `验收基建` 字段。`patrol_test/editor_callout_visual_test.dart` 已在 T5 可改文件白名单内。
