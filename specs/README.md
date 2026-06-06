# Specs 索引

> 本文件是功能生命周期的**唯一来源**。tasks 完成情况驱动状态更新；归档后将该行移入「已归档」表。

> **编辑器选型 = A (AppFlowy Editor)** — 2026-05-29 @Ray 拍板（见 [archive/2026-05-29-editor-research](archive/2026-05-29-editor-research/)）。后续编辑器集成、JSON 契约、PDF 导出均以方案 A 为准。

> **UI 文案默认走 gen-l10n**：未来 UI / 屏幕 spec 新增或修改用户可见文案，统一写入 `lib/l10n/arb/app_zh.arb` + `app_en.arb`，运行期通过 `AppLocalizations.of(context)` 取用并跑 `gen-l10n`。`AppStrings` 已废弃，不得新增或追加；存量引用由 [ui-i18n-migration](active/ui-i18n-migration/) 迁移。

## 进行中

| 功能 | 优先级 | 状态 | 依赖 | 负责人 | 创建 |
|------|--------|------|------|--------|------|
| [backup-full-snapshot](active/backup-full-snapshot/) | P2 | 进行中（功能域自动验收通过；性能真机基准后置记录；待 @Ray 真机演示 / 回归确认） | app-scaffold, key-management, data-layer, media-storage, thumbnail-cache, observability | @Ray | 2026-05-23 |
| [design-sync-automation](active/design-sync-automation/) | P2 | 进行中（期一 M1 已完成；期二待首屏） | design-tokens-theme | @Ray | 2026-05-29 |
| [ui-kit-components](active/ui-kit-components/) | P1 | 进行中（T1–T9 自动验收 + @Ray 目检通过；待归档整理） | design-tokens-theme, e2e-harness | @Ray | 2026-05-29 |
| [ui-i18n-migration](active/ui-i18n-migration/) | P1 | 进行中（迁移与聚焦自动验收通过；全仓库 analyze 剩既有非本次 warning/info） | i18n-localization, ui-kit-components, ui-shell-navigation | @Ray | 2026-05-31 |
| [onthisday-screen](active/onthisday-screen/) | P2 | 进行中（T1 已完成） | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer, media-storage, thumbnail-cache | @Ray | 2026-05-29 |
| [search-screen](active/search-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [settings-screen](active/settings-screen/) | P2 | 待实现 | design-tokens-theme, ui-kit-components, ui-shell-navigation, key-management | @Ray | 2026-05-29 |
| [calendar-screen](active/calendar-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [favorites-screen](active/favorites-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-29 |
| [trash-screen](active/trash-screen/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer, reader-screen, timeline-screen, e2e-harness | @Ray | 2026-05-29 |
| [memory-card-export](active/memory-card-export/) | P2 | 草稿 | design-tokens-theme, ui-kit-components, ui-shell-navigation, onthisday-screen, media-storage, e2e-harness | @Ray | 2026-05-29 |
| [e2e-harness](active/e2e-harness/) | P2 | 进行中（M1 iOS+Android 冒烟双端绿；M2 复现 SOP / flaky wrapper / 验收分层骨架 / R8 测试隔离·产物清理工件已交付，wrapper 逻辑自验过——live 连跑+干净 checkout 走查留 @Ray；T5 跨 spec、T7 CI 后置） | 无 | @Ray | 2026-06-04 |
| [editor-rich-blocks](active/editor-rich-blocks/) | P1 | 草稿（2026-06-06 设计同步实质档派生：编辑器新增块类型；本轮实现 callout 标注块，code 代码块占位后置） | editor-json-contract, e2e-harness | @Ray | 2026-06-06 |

> **优先级分层**（治此前「全 P1」导致选取规则退化为创建序）：**P0** = 数据/加密主干（被依赖最多、当前就绪的关键路径）｜ **P1** = 核心功能 + UI 地基（主干推进项 + 可立即并行的无依赖项）｜ **P2** = 上层 / 支撑（依赖较深或非关键路径）。通用排序纪律（新增/归档触发的相对定位与复核、区分度要求）见 [`spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)；UI 页面级 spec 的优先级（按页面层级 × 数据依赖、波次 W0–W4）见 [`docs/spec-guide-ai.md`](../docs/spec-guide-ai.md) + [`docs/design/10-ui-restore-and-design-sync.md`](../docs/design/10-ui-restore-and-design-sync.md) §9。

> **验收分层**（随 [e2e-harness](active/e2e-harness/) 落地）：屏 / 功能 spec 的 `verification.md` 把验收项分两类——**自动化可覆盖**（widget test 或 Patrol E2E）与**必须人工**（设计目检 + 加密/备份/还原等不可逆链路的终验）。判据：纯 in-Flutter 行为 → widget test 即可，不强制 E2E；**有原生跨界 / 不可逆副作用**的链路 → 标「需 E2E」并依赖 `e2e-harness`。安全 / 不可逆链路即便 E2E 全绿也**保留人工终验**（patrol_cli 有静默假阳性 + iOS 模拟器 CI flaky 先例）。**新屏可复制的两栏骨架**见 [`active/e2e-harness/verification-skeleton.md`](active/e2e-harness/verification-skeleton.md)；**Patrol 一次性接入 SOP** 见 [`docs/patrol-e2e-onboarding.md`](../docs/patrol-e2e-onboarding.md)。

## 已交付·随设计维护

> 仅限屏幕级 spec。交付 v1 后不归档，后续设计变更按 `design-sync-automation` 的微调档 / 实质档 / 大改档分流；对齐状态由 `active/design-sync-automation/screens.yaml` 与各屏 `test/ui/<feature>/` 基线维护。

| 功能 | 当前对齐 | 依赖 | 负责人 | 进入维护态 |
|------|----------|------|--------|------------|
| [timeline-screen](active/timeline-screen/) | v1.0 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer | @Ray | 2026-05-31 |
| [reader-screen](active/reader-screen/) | v1.0 | design-tokens-theme, ui-kit-components, ui-shell-navigation, data-layer, media-storage, thumbnail-cache, e2e-harness | @Ray | 2026-05-31 |
| [editor-integration-screen](active/editor-integration-screen/) | v1.0（+设计维护 S1/S2 进行中） | design-tokens-theme, ui-kit-components, ui-shell-navigation, editor-json-contract, media-storage, auto-save-draft, editor-rich-blocks, e2e-harness | @Ray | 2026-06-01 |

## 执行顺序（派生快照）

> **选取规则**（同 spec-guide）：在「待实现 / 进行中」**且依赖就绪**（依赖列前置全「已完成」）的 spec 里挑优先级最高的；同级按创建序。**串行**＝照此逐个推进；**并行**＝同时开所有就绪项，容量不足时按优先级让路。
> 下表是当前快照（`app-scaffold` / `key-management` / `data-layer` / `media-storage` / `thumbnail-cache` / `auto-save-draft` / `observability` / `design-tokens-theme` / `editor-json-contract` / `assets-management` / `dayz-security-rust` 已归档完成）；**真源＝上方「优先级」+「依赖」列**，spec 增删后据此重新派生，不手工同步本表。‖＝可并行。

1. **现在就绪**：W2 页面级屏 spec 依各自底层依赖解锁（`timeline/search/calendar/favorites/trash/settings` 等数据依赖已就绪；`reader/onthisday` 媒体与缩略图依赖已就绪；`editor-integration` 编辑器/媒体/草稿依赖已就绪；`memory-card-export` 仍需 `onthisday-screen`）‖ `design-sync-automation`(P2，期二 blocked：待首屏)

> ★＝数据/加密主干剩余链当前只余 `backup-full-snapshot`；`media-storage` / `thumbnail-cache` / `auto-save-draft` / `key-management` / `data-layer` 均已归档完成。
>
> **UI 轨（并行于主干，波次见 [doc 10](../docs/design/10-ui-restore-and-design-sync.md) §9）**：W0 `design-tokens-theme` 已归档，`design-sync-automation` 期一 M1 已完成 → W1 `ui-kit-components` T1–T9 已验收，待归档整理 → W2 十个页面级屏 spec（`*-screen` / `memory-card-export`，各 dependsOn tokens+ui-kit+shell + 各自数据/编辑器/媒体底层 spec，故仍按各自底层依赖解锁）+ `design-sync-automation` 期二（等首屏+shell 落后补）。UI 页面级 spec 全列 P2（依赖较深、非主干），波次内细分见 §9，不靠 P 区分。

## 已归档

> 终局复验说明见 [`archive/acceptance-review.md`](archive/acceptance-review.md)。历史 tasks / verification 中已由该说明收口的旧式人工项不再重复 review。

| 功能 | 结果 | 归档日期 |
|------|------|----------|
| [ui-shell-navigation](archive/2026-05-31-ui-shell-navigation/) | 已完成 | 2026-05-31 |
| [thumbnail-cache](archive/2026-05-30-thumbnail-cache/) | 已完成（单元测试 Benchmark 耗时 8.0ms/张，支持 Isolate 限制并发、设备密钥加密落盘、一致性补偿） | 2026-05-30 |
| [media-storage](archive/2026-05-30-media-storage/) | 已完成（本机基线吞吐 write=14.4 MiB/s, read=14.5 MiB/s） | 2026-05-30 |
| [auto-save-draft](archive/2026-05-30-auto-save-draft/) | 已完成 | 2026-05-30 |
| [dayz-security-rust](archive/2026-05-30-dayz-security-rust/) | 已完成 | 2026-05-30 |
| [data-layer](archive/2026-05-30-data-layer/) | 已完成 | 2026-05-30 |
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

## 待立 spec（工程后置件）

- **argon2id_ffi 发布真机闸门**（衍生自 `dayz-security-rust`）— iOS archive/TestFlight、Android 真机 release、整包 `--analyze-size`、并发 OOM；当前按模拟器口径归档，不阻塞主线，发布前再补。

补 spec 时直接在 `active/` 下新建对应目录，并在本表添加一行。
