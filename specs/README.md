# Specs 索引

> 本文件是功能生命周期的**唯一来源**。tasks 完成情况驱动状态更新；归档后将该行移入「已归档」表。

> **编辑器选型 = A (AppFlowy Editor)** — 2026-05-29 @Ray 拍板（见 [archive/2026-05-29-editor-research](archive/2026-05-29-editor-research/)）。后续编辑器集成、JSON 契约、PDF 导出均以方案 A 为准。

## 进行中

| 功能 | 优先级 | 状态 | 依赖 | 负责人 | 创建 |
|------|--------|------|------|--------|------|
| [dayz-security-rust](active/dayz-security-rust/) | P1 | 草稿（已接入 key-management KDF 后端，iOS 真机闸门待补） | app-scaffold | @Ray | 2026-05-30 |
| [data-layer](active/data-layer/) | P0 | 草稿 | app-scaffold, key-management | @Ray | 2026-05-23 |
| [media-storage](active/media-storage/) | P1 | 草稿 | app-scaffold, key-management, data-layer | @Ray | 2026-05-23 |
| [auto-save-draft](active/auto-save-draft/) | P1 | 草稿 | app-scaffold, data-layer | @Ray | 2026-05-23 |
| [thumbnail-cache](active/thumbnail-cache/) | P2 | 草稿 | app-scaffold, key-management, data-layer, media-storage | @Ray | 2026-05-23 |
| [backup-full-snapshot](active/backup-full-snapshot/) | P2 | 草稿 | app-scaffold, key-management, data-layer, media-storage, thumbnail-cache | @Ray | 2026-05-23 |
| [design-sync-automation](active/design-sync-automation/) | P2 | 草稿 | design-tokens-theme | @Ray | 2026-05-29 |
| [ui-kit-components](active/ui-kit-components/) | P1 | 草稿 | design-tokens-theme | @Ray | 2026-05-29 |
| [ui-shell-navigation](active/ui-shell-navigation/) | P1 | 草稿 | design-tokens-theme, ui-kit-components, data-layer | @Ray | 2026-05-29 |
| [timeline-screen](active/timeline-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [reader-screen](active/reader-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer, media-storage, thumbnail-cache | @Ray | 2026-05-29 |
| [editor-integration-screen](active/editor-integration-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, editor-json-contract, media-storage, auto-save-draft | @Ray | 2026-05-29 |
| [onthisday-screen](active/onthisday-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer, media-storage, thumbnail-cache | @Ray | 2026-05-29 |
| [search-screen](active/search-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [settings-screen](active/settings-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, key-management | @Ray | 2026-05-29 |
| [calendar-screen](active/calendar-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [favorites-screen](active/favorites-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [trash-screen](active/trash-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [memory-card-export](active/memory-card-export/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, onthisday-screen, media-storage | @Ray | 2026-05-29 |

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
>
> **UI 轨（并行于主干，波次见 [doc 10](../docs/design/10-ui-restore-and-design-sync.md) §9）**：W0 `design-tokens-theme`（已就绪，P1）+ `design-sync-automation`(期一) → W1 `ui-kit-components` → `ui-shell-navigation` → W2 十个页面级屏 spec（`*-screen` / `memory-card-export`，各 dependsOn tokens+ui-kit+shell + 各自数据/编辑器/媒体底层 spec，故全部**被阻塞**至地基就绪）+ `design-sync-automation`(期二，等首屏+shell 落后补)。UI 页面级 spec 全列 P2（依赖较深、非主干），波次内细分见 §9，不靠 P 区分。

## 已归档

| 功能 | 结果 | 归档日期 |
|------|------|----------|
| [i18n-localization](archive/2026-05-30-i18n-localization/) | 已完成 | 2026-05-30 |
| [key-management](archive/2026-05-30-key-management/) | 已完成 | 2026-05-30 |
| [observability](archive/2026-05-30-observability/) | 已完成 | 2026-05-30 |
| [assets-management](archive/2026-05-30-assets-management/) | 已完成 | 2026-05-30 |
| [app-scaffold](archive/2026-05-23-app-scaffold/) | 已完成 | 2026-05-23 |
| [editor-research](archive/2026-05-29-editor-research/) | 已完成（选型=A，经 @Ray 拍板替代正式实测） | 2026-05-29 |
| [appflowy-patch-tracking](archive/2026-05-29-appflowy-patch-tracking/) | 已完成 | 2026-05-29 |
| [design-tokens-theme](archive/2026-05-30-design-tokens-theme/) | 已完成 | 2026-05-30 |
| [editor-json-contract](archive/2026-05-30-editor-json-contract/) | 已完成 | 2026-05-30 |

## 待立 spec（UI 依附 / 后置件，W3/W4）

> UI 系列的基础档（`design-tokens-theme` / `design-sync-automation`）、组件与外壳档（`ui-kit-components` / `ui-shell-navigation`）、以及全部页面级屏 spec（`timeline/reader/editor-integration/onthisday/search/settings/calendar/favorites/trash-screen` + `memory-card-export`）**均已立项**（见上表）。分层与波次见 [`docs/design/10-ui-restore-and-design-sync.md`](../docs/design/10-ui-restore-and-design-sync.md) §9。
>
> 下列为页面级屏之外的**依附 / 后置件**，按各自依赖排在 W3/W4，随相关屏与底层 spec 就绪后再补需求/设计/任务文档：

- **撤销/重做**（接 AppFlowy undo manager）— 依附 `editor-integration-screen`
- **自动保存草稿恢复 UI**（提示条、设置项「恢复未完成的编辑」）— 依附 `settings-screen` / `auto-save-draft`
- **缩略图未就绪占位**（灰块 / blurhash）— 依附 `ui-kit-components` / `thumbnail-cache`
- **原生相册 / 相机选图链路**（`image_picker`）— 依附 `editor-integration-screen` / `media-storage`
- **备份导出 / 还原向导 UI**（口令输入、二次确认、进度条、文件类型关联）— 依附 `settings-screen` / `backup-full-snapshot`
- **每日本地通知**（往年今日）— 依附 `onthisday-screen`
- **PDF / HTML 归档**（方案 A 无天然 HTML，走 widget→PDF 或 JSON→HTML）
- **持久备份目标 + media 增量**（阶段二）

补 spec 时直接在 `active/` 下新建对应目录，并在本表添加一行。
