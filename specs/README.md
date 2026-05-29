# Specs 索引

> 本文件是功能生命周期的**唯一来源**。tasks 完成情况驱动状态更新；归档后将该行移入「已归档」表。

> **编辑器选型 = A (AppFlowy Editor)** — 2026-05-29 @Ray 拍板（见 [archive/2026-05-29-editor-research](archive/2026-05-29-editor-research/)）。后续编辑器集成、JSON 契约、PDF 导出均以方案 A 为准。

## 进行中

| 功能 | 优先级 | 状态 | 依赖 | 负责人 | 创建 |
|------|--------|------|------|--------|------|
| [key-management](active/key-management/) | P0 | 草稿 | app-scaffold | @Ray | 2026-05-23 |
| [data-layer](active/data-layer/) | P0 | 草稿 | app-scaffold, key-management | @Ray | 2026-05-23 |
| [media-storage](active/media-storage/) | P1 | 草稿 | app-scaffold, key-management, data-layer | @Ray | 2026-05-23 |
| [auto-save-draft](active/auto-save-draft/) | P1 | 草稿 | app-scaffold, data-layer | @Ray | 2026-05-23 |
| [thumbnail-cache](active/thumbnail-cache/) | P2 | 草稿 | app-scaffold, key-management, data-layer, media-storage | @Ray | 2026-05-23 |
| [backup-full-snapshot](active/backup-full-snapshot/) | P2 | 草稿 | app-scaffold, key-management, data-layer, media-storage, thumbnail-cache | @Ray | 2026-05-23 |
| [editor-json-contract](active/editor-json-contract/) | P1 | 草稿 | 无 | @Ray | 2026-05-29 |
| [assets-management](active/assets-management/) | P2 | 草稿 | 无 | @Ray | 2026-05-29 |
| [design-tokens-theme](active/design-tokens-theme/) | P1 | 草稿 | 无 | @Ray | 2026-05-29 |
| [design-sync-automation](active/design-sync-automation/) | P2 | 草稿 | design-tokens-theme | @Ray | 2026-05-29 |

> **优先级分层**（治此前「全 P1」导致选取规则退化为创建序）：**P0** = 数据/加密主干（被依赖最多、当前就绪的关键路径）｜ **P1** = 核心功能 + UI 地基（主干推进项 + 可立即并行的无依赖项）｜ **P2** = 上层 / 支撑（依赖较深或非关键路径）。通用排序纪律（新增/归档触发的相对定位与复核、区分度要求）见 [`spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)；UI 页面级 spec 的优先级（按页面层级 × 数据依赖、波次 W0–W4）见 [`docs/spec-guide-ai.md`](../docs/spec-guide-ai.md) + [`docs/design/10-ui-restore-and-design-sync.md`](../docs/design/10-ui-restore-and-design-sync.md) §9。

## 执行顺序（派生快照）

> **选取规则**（同 spec-guide）：在「未开始 / 进行中」**且就绪**（依赖列前置全「已完成」）的 spec 里挑优先级最高的；同级按创建序。**串行**＝照此逐个推进；**并行**＝同时开所有就绪项，容量不足时按优先级让路。
> 下表是当前快照（`app-scaffold` 已完成）；**真源＝上方「优先级」+「依赖」列**，spec 增删后据此重新派生，不手工同步本表。‖＝可并行。

1. **现在就绪**：★`key-management`(P0) ‖ `design-tokens-theme`(P1) ‖ `editor-json-contract`(P1) ‖ `assets-management`(P2)
2. **`key-management` 完成后**：★`data-layer`(P0)
3. **`data-layer` / `design-tokens-theme` 完成后**：`media-storage`(P1) ‖ `auto-save-draft`(P1) ‖ `design-sync-automation`(P2，期一可随 tokens 起)
4. **`media-storage` 完成后**：`thumbnail-cache`(P2)
5. **`thumbnail-cache` 完成后**：`backup-full-snapshot`(P2)

> ★＝数据/加密主干链（`key-management → data-layer → media-storage → thumbnail-cache → backup-full-snapshot`，依赖强制串行）；无依赖叶子 `design-tokens-theme` / `editor-json-contract` / `assets-management` 可随时并入。

## 已归档

| 功能 | 结果 | 归档日期 |
|------|------|----------|
| [app-scaffold](archive/2026-05-23-app-scaffold/) | 已完成 | 2026-05-23 |
| [editor-research](archive/2026-05-29-editor-research/) | 已完成（选型=A，经 @Ray 拍板替代正式实测） | 2026-05-29 |
| [appflowy-patch-tracking](archive/2026-05-29-appflowy-patch-tracking/) | 已完成 | 2026-05-29 |

## 待 UI 设计稿后再立 spec

> 设计稿已到位（`ui-design/`）。UI 系列 spec 的分层、拆分与依赖拓扑见 [`docs/design/10-ui-restore-and-design-sync.md`](../docs/design/10-ui-restore-and-design-sync.md) §9。基础档 `design-tokens-theme` 已立项（见上表）；下列页面级/外壳功能随后按 §9 波次补 spec：

下列功能包含 UI，**待设计稿到位后**再补需求/设计/任务文档：

- **时间线**（虚拟滚动 + 分组吸顶 + 游标分页）
- **往年今日**入口与浏览
- **编辑器集成**（编辑页、工具栏、与自动保存对接、Flutter 只读渲染器；基于已选方案 A）
- **撤销/重做**（接 AppFlowy undo manager）
- **自动保存草稿恢复 UI**（提示条、设置项「恢复未完成的编辑」）
- **缩略图未就绪占位**（灰块 / blurhash）
- **备份导出 / 还原向导**（含口令输入、二次确认、进度条、文件类型关联）
- **设置页**（加密模式切换 / 主密码 / 文案说明等）
- **原生相册 / 相机选图链路**
- **PDF / HTML 归档**（方案 A 无天然 HTML，走 widget→PDF 或 JSON→HTML）
- **每日本地通知**（往年今日）
- **持久备份目标 + media 增量**（阶段二）

补 spec 时直接在 `active/` 下新建对应目录，并在本表添加一行。
