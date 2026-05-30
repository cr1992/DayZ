---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-30
文档状态：草稿
---

# 验证：editor-json-contract（编辑器文档 JSON 契约）

> 覆盖跨任务质量，不重复任务内已验证内容。本契约跨「编辑器 / 只读渲染器 / 抽取器 / 导出器」四方，触发标准档 verification。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 全块往返 | 构造含块清单**每一种**块的样例文档，encode→入库→decode | 还原后块种类/顺序/层级/文本/样式与原文档完全一致；docVersion=1 | R1, R5 | 自动 |
| 路径无关性 | 含图片的文档 encode 后，改变模拟媒体目录（重装场景），再 decode 渲染 | `content_json` 不变，图片经 media.id 重新解析仍指向正确文件 | R2 | 自动 |
| 自定义块降级一致 | 含位置/天气块文档，分别走抽取器与导出器 | 两路产出同一文本行 `📍 上海` / `🌤 18°C` | R3 | 自动 |
| 抽取覆盖全块 | 对全块样例文档跑抽取器 | 每种块按降级表产出对应文本；标题=第一行 | R4, R5 | 自动 |
| 未知块韧性 | 注入清单外 type 块，跑只读渲染 + 抽取 | 均不崩溃，未知块降级/跳过，其余块正常 | R5 | 自动 |

## 专项检查

> 对应 requirement 的 NF 编号。

### 抽取性能（NF1）
- [x] 50 块典型文档抽取 < 5ms（主机 Dart VM bench；阈值源自中端真机预算，见 NF1 度量口径） — 自动：`flutter test test/editor/contract/plain_text_extractor_bench_test.dart`
- [x] 1000 块极端文档抽取 < 50ms — 自动：同上
- [x] 抽取过程无任何文件/DB I/O — 自动：`flutter test test/editor/contract/plain_text_extractor_test.dart`

### 编辑器↔只读渲染器一致性（NF2）
- [x] 块清单每种块在编辑态与只读态语义一致（种类/顺序/层级/文本/图片引用目标/行内样式） — 自动：`flutter test test/editor/contract/render_consistency_test.dart`
- [x] 自定义块（位置/天气）两端呈现相同结构化值 — 自动：同上
- [x] 行内样式（粗/斜/下划线/删除线/行内代码/链接）两端一致 — 自动：同上
- [-] 仅光标/选区/占位等编辑专属装饰存在差异，无内容差异 — 人工复核（@Ray）

## 契约一致性交叉检查

- [x] **块清单单一来源**：抽取器/渲染器/导出器实际识别的 type 集合 == `block_types.dart` 暴露的支持 type 集合（== design 块清单表枚举），无第五种私自新增 — 自动：`flutter test test/editor/contract/block_inventory_consistency_test.dart`
- [x] **降级表同源**：对块清单每一种块，导出器 `exportFallbackLine(node)` 的返回值 == 抽取器对同一 node 的产出行（逐块逐字节相等 → 证明二者共用同一份「降级表现」映射、不存在两套文本） — 自动：`flutter test test/editor/contract/export_fallback_test.dart`
- [x] **media.id 引用完整性**：任意 encode 后的 `content_json` 中，图片节点不含真实路径，仅含 media.id；扫描全文无 `/var/mobile`、`/data/data`、`media/*.bin` 等路径串 — 自动：`flutter test test/editor/contract/media_ref_integrity_test.dart`
- [x] **docVersion 存在性**：所有 encode 产物顶层含 `docVersion` 整数 — 自动：`flutter test test/editor/contract/editor_doc_codec_test.dart`

## 回归检查
- [-] `content_plain` 第一行作为标题与 data-layer/搜索消费方约定一致（取值方式未漂移） — 人工复核（@Ray）
- [-] 契约层不引入对编辑页 UI / PDF 导出全流程的反向依赖（保持「被依赖」单向） — 人工复核（@Ray）

## @Ray 人工核查最短清单

> 目标：只覆盖当前仍未闭环的人工项；自动项已由 `flutter analyze lib/editor/contract test/editor/contract` 与 `flutter test test/editor/contract` 覆盖，无需重复。

- [ ] **T1 / D2 / 代码块归属**
  - 打开 `specs/active/editor-json-contract/design.md`
  - 核对三点：
    1. 图片落点已定为 `url='dayz-media://<media.id>'`
    2. 该结论与上游原生 image builder / encoder 直接读取 `url` 的事实一致
    3. `code` 已移出 MVP 的理由成立（上游可识别 `type='code'`，但默认 `standardBlockComponentBuilderMap` 未注册对应 builder）

- [ ] **NF2 人工复核：编辑态 vs 只读态只差编辑装饰**
  - 参考 `test/editor/contract/render_consistency_test.dart` 的样例内容
  - 重点核对：正文内容、行内样式、图片占位、自定义块值一致；允许差异仅限光标/选区/占位等编辑专属装饰

- [ ] **标题回归：第一行契约未漂移**
  - 核对 `lib/editor/contract/plain_text_extractor.dart` 中 `extractTitle()` 的“取第一行”规则
  - 与 data-layer / 搜索消费方当前预期比对，确认没有出现标题来源漂移

- [ ] **依赖方向回归：契约层仍是被依赖方**
  - 核对 `lib/editor/contract/` 当前实现只依赖 `appflowy_editor` 与契约内模块
  - 确认未反向依赖编辑页 UI、PDF/HTML 导出全流程、页面层或业务层模块

> @Ray 核查完成后，可：
> 1. 把本文件中的 3 个 `[-]` 人工项改为 `[x]`
> 2. 把 `specs/active/editor-json-contract/tasks.md` 中 T1 的人工记录补为已确认
> 3. 再将 `specs/README.md` 中 `editor-json-contract` 从「进行中」推进到「已完成」并归档

## 验证命令（汇总自动项）
```bash
flutter analyze lib/editor/contract/
flutter test test/editor/contract/
```
