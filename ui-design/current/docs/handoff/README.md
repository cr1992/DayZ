# Handoff 走查任务单（docs/handoff/）

> 每份 handoff = **针对某个目录/模块的「原型 ↔ 原生」走查任务单**：列出该区现状与设计的差异、改法、验收 checklist。
> 受众是**落地该模块的原生 agent**。与 `DESIGN-REF.md`（组件索引）、`CHANGELOG.md`（已做）、`BACKLOG.md`（要做）互补——handoff 专管「某块怎么从原型对齐到原生、怎么验收」。

## 生命周期
```
待走查/待落地  →  原生照单实现  →  逐条过 checklist  →  全过 ⇒ 归档
  （本目录）                                            （_archive/）
```
- **进行中**：文件直接放 `docs/handoff/<区域>.md`，顶部 `状态: 🚧 待原生落地`。
- **归档**：当 §验收 checklist **全部勾完**（原生已对齐、肉眼/机检通过），把文件整体移到 `docs/handoff/_archive/<区域>.md`，顶部状态改 `✅ 已对齐 YYYY-MM-DD`，原样保真不删内容。归档同步在 `CHANGELOG.md` 记一条 `- [文档] <区域> handoff 走查通过，归档`。

## 命名
- 一个目标区一份，按**走查的代码区**命名（非原型屏名）：`editor.md`（覆盖 `lib/ui/editor/*` + `lib/editor/*`）、`timeline.md`、`settings.md`…
- 一份 handoff 可覆盖多屏/多文件，只要它们同属一个落地模块。

## 写法约定（每份至少含）
1. **§0 结论速览**：一句话定性 + 漂移表（# / 漂移点 / 严重度 🔴🟠🟡 / 根因 / 改法指向小节）。
2. **逐条对账**：原生现状 → 设计期望 → 差异。
3. **分节改法**：每个漂移点给 Flutter 落地方案（优先标准 widget / 成熟 package）。
4. **§验收 checklist**：可逐条勾、可证伪——这是能否归档的唯一判据。

## 现有
- `editor.md` — 🚧 编辑页（`lib/ui/editor/*`）。走查 2026-06-04：#1–#4（色板/图标/标题正文项）已对齐；余 图片选择器 `DZ.picker` + 大图查看器 `DZ.lightbox` 未落地、代码块矛盾待定调。
