---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-31
文档状态：定稿
---

# editor-integration-screen（编辑页：AppFlowy 编辑器集成屏）

## 背景

编辑页是 DayZ 最重的一屏：正文是富文本（AppFlowy Editor，非 `TextField`），承载标题/元数据 chip/格式工具栏/图片插入/自动保存全链路。屏源为 `ui-design/current/pages/screens/editor.html`（多状态 `?state=empty|writing|rich`，见 PROTOTYPE-ARCH §3）。本 spec 把这一屏落成 Flutter 页面：

- **正文 = vendored `AppFlowyEditor`**（`packages/appflowy-editor`），不是 `TextField`——这是已拍板的编辑器选型 A（见 `specs/README.md` 顶部、`ui-design/current/CLAUDE.md`）。
- 屏自身只做**装配与接线**：取 token / 组件层 widget（`ui-kit-components`）、走外壳路由（`ui-shell-navigation` 的 `Routes.editor` + FAB 创建意图入参），底层能力（文档 codec、媒体加密、草稿协调器、Repository 取数）一律按**跨 spec 依赖交付物名**消费，不在本屏重造。

把这屏单独立 spec 的理由：它跨度大、接缝多（编辑器 / codec / 媒体 / 草稿 / Repository / 工具栏命令派生），是页面级 spec 里依赖最深、最容易踩 Repository 边界与媒体密钥红线的一屏，须用四件套把接缝逐条钉死。

> 本 spec 是**页面级**还原（方法论 §9 W2）。视觉/参数/几何还原口径见 design「视觉依据」指针与 verification；底层契约的具体字段以各前置 spec 为准，本屏不复述、不发明。

## 范围外

> 用 MUST NOT / SHOULD NOT 规范化表述（spec-guide P1）。

- **底层文档契约本体**——`EditorDocCodec` 的 encode/decode、`docVersion` 迁移、`extractPlainText`、自定义块（location/weather）的 BlockComponentBuilder、`ImageUrlResolver`、只读渲染器——MUST NOT 在本 spec 实现，归 `editor-json-contract`；本屏只**调用**其交付物。
- **媒体加密容器与落盘**（`DMED` 格式、AES-256-GCM、`MediaStore.put/openRead`、设备媒体 key 的 HKDF 派生）MUST NOT 在本 spec 实现，归 `media-storage`；本屏只调 `MediaStore` + `MediaRepo` 元数据接口。
- **草稿协调器内核**（防抖、串行队列、生命周期 flush、`startupCheck`、写盘事务）MUST NOT 在本 spec 实现，归 `auto-save-draft`；本屏只把编辑器 onChanged 翻成 plain payload 喂 `DraftCoordinator`，并消费 `DraftRecoveryStatus`。
- **草稿恢复提示条 / 设置项「恢复未完成的编辑」UI** 本 spec SHOULD NOT 实现（属独立「自动保存草稿恢复 UI」spec，见 README 待立清单）；本屏只在进入时**消费**协调器的恢复状态决定加载哪份草稿。
- **撤销/重做工具条按钮**本 spec SHOULD NOT 实现（属「撤销/重做」spec，接 AppFlowy undo manager）；本屏不在工具栏放 undo/redo 钮（editor.html 工具栏也无 undo/redo）。
- **相册/相机选图链路的权限与系统弹层细节** 由 `image_picker` 承担；本屏只调其 API 取图字节，MUST NOT 自绘系统相册 UI。
- **缩略图生成 / 占位（blurhash/灰块）** MUST NOT 在本屏触发同步缩略图重建（红线，见 `docs/design/05`/`thumbnail-cache`）；本屏插入图片走原图加密容器 + image node，缩略图归 `thumbnail-cache`。
- **PDF / HTML 导出**、**心情/天气/地点/标签选择器的完整数据录入流**：本屏只放 chip 触发钮（`compose-meta`）与已选态回显；选择器的具体录入 sheet 与落库归各自后续 spec，本屏触发后以回调/路由参数交接（MVP 可先打开占位 sheet）。
- **真外壳路由接管**（`MaterialApp.router`、`Routes.editor` 注册）归 `ui-shell-navigation`；本屏只**替换** placeholder builder 为本屏 widget（归属在 README/各屏协调，见 design D 文件变更）。

## 功能需求

### R1 · 正文用 AppFlowyEditor 渲染与编辑
正文区 SHALL 由 vendored `AppFlowyEditor`（`packages/appflowy-editor`）承载，MUST NOT 用 `TextField`/`EditableText` 当正文。
- 前提：进入编辑页（新建或加载既有条目）。
- 操作：在正文区输入/编辑文本与块。
- 结果：渲染出 AppFlowy 文档（段落/标题/列表/待办/引用/分隔线/图片等块，块集合以 `editor-json-contract` 块清单为准）；编辑产生的变更可被读出为 `Document`，供 codec/草稿消费。

### R2 · 标题用无边框 TextField
标题区 SHALL 是一个独立 `TextField`（`compose-title`），样式 border:none（无边框、无填充框线），与正文 AppFlowyEditor 分离。
- 前提：在编辑页。
- 操作：聚焦标题输入文字。
- 结果：标题不带可见边框（聚焦也不显描边框），占位文案为 `AppLocalizations` 的「标题」；标题文本作为条目标题来源（与 `editor-json-contract` content_plain 首行约定协同，见 design D）。

### R3 · 加载与保存走 editor-json-contract codec（解 docVersion）
加载既有条目时系统 SHALL 经 `EditorDocCodec.decode(content_json)` 拿到 `(docVersion, Document)` 喂编辑器；保存时 SHALL 经 `EditorDocCodec.encode(Document)` 产出 `content_json`，并经 `extractPlainText(Document)` 产出 `content_plain`。
- 前提：有一份既有条目的 `content_json`（含 `docVersion`）。
- 操作：进入编辑页加载该条目，编辑后触发保存。
- 结果：解码按 `docVersion` 路由（当前仅 v1）；保存写出的 payload 同时含 `content_json`（带 docVersion 的封装结构）与 `content_plain`（首行=标题）；本屏 MUST NOT 自行拼/解 JSON，一律经 codec/抽取器。

### R4 · 底部停靠工具栏用 AppFlowy mobile_toolbar 体系
底部停靠格式工具栏 SHALL 复用 AppFlowy 的 `mobile_toolbar` 体系（`MobileToolbar`/`MobileToolbarV2` + toolbar items），承载 editor.html `editor-dock` 所列能力（H · B/I/U/S · 行内代码 · 颜色/高亮 · 无序/有序/待办列表 · 引用 · 链接 · 分隔线 · 图片）。
- 前提：编辑器获得焦点、软键盘弹出。
- 操作：点击工具栏某项。
- 结果：对当前选区应用对应格式/插入对应块（由 AppFlowy mobile_toolbar item 落地）；工具栏停靠在键盘上方。

### R5 · 工具栏不自己监听 viewInsets，停靠交给 AppFlowy
本屏 MUST NOT 自行 `MediaQuery.of(context).viewInsets.bottom` 监听键盘高度来手动顶起工具栏；键盘随动停靠 SHALL 交给 AppFlowy mobile_toolbar 体系处理。
- 前提：编辑器聚焦、软键盘高度变化。
- 操作：键盘弹出/收起。
- 结果：工具栏随键盘正确停靠/隐藏，且本屏代码无 `viewInsets.bottom` 的手动顶起逻辑（red-flag：避免与 AppFlowy 自身停靠机制打架导致抖动/双重位移）。

### R6 · 格式高亮态由选区实际格式派生
工具栏按钮的激活（高亮）态 SHALL 由当前选区的**实际格式**派生（如选区为粗体则 B 高亮），MUST NOT 用独立的「按钮被点过」本地布尔自管。
- 前提：编辑器有一个非空选区。
- 操作：移动光标/改变选区到不同格式的文本。
- 结果：工具栏按钮高亮态随选区实际格式即时切换（选区是粗体→B 亮、退出粗体区域→B 灭）。

### R7 · 图片插入：image_picker → 加密容器 → image node
插入图片时系统 SHALL 经 `image_picker` 取图字节 → 经 `MediaStore.put` 写入媒体加密容器（`DMED`，串独立设备媒体 key）并经 `MediaRepo.addMeta` 记元数据 → 在文档中插入 image 块，块引用 `media.id`（权威引用键，落点以 `editor-json-contract` D2 为准），MUST NOT 把真实文件路径写进 `content_json`。
- 前提：编辑器聚焦，点击工具栏「插入图片」。
- 操作：从相册选一张图。
- 结果：图片被加密存入媒体容器、元数据入 `MediaRepo`、文档插入引用 `media.id` 的 image 块；`content_json` 内不含明文路径（满足 editor-json-contract R2「路径变化不破坏文档」）。

### R8 · 自动保存对接（编辑器 → DraftCoordinator）
编辑器内容变更时本屏 SHALL 把变更翻成 plain payload（`targetId, draftJson, isNew, cursorPos`，draftJson 经 `EditorDocCodec.encode`）喂 `auto-save-draft` 的 `DraftCoordinator`，并在页面失焦/退出等时机触发 `forceFlush`。
- 前提：在编辑页编辑内容。
- 操作：连续输入后停顿，或退出页面。
- 结果：变更经协调器防抖落库（本屏不实现防抖/事务，只调接口）；退出/失焦触发一次 `forceFlush`，未保存内容不丢。

### R9 · 屏内三状态可呈现
本屏 SHALL 覆盖 editor.html 的三个状态：`empty`（空白新建：标题占位 + 正文占位「写点什么吧……」+ 顶栏标题「新日记」）、`writing`（书写中：有标题与一段正文 + 顶栏标题「草稿已存」）、`rich`（富格式：含标题/待办/引用等多块 + 顶栏标题「草稿已存」）。
- 前提：以某状态进入编辑页（新建 = empty；加载有内容草稿 = writing/rich）。
- 操作：渲染该状态。
- 结果：标题占位/正文占位/顶栏标题文案与 editor.html 对应状态一致（文案经 `AppLocalizations`，禁裸中文）；日期 kicker（「今天 · 5月29日 周五」）经 `package:intl` 格式化。

### R10 · 顶栏关闭/完成 + 元数据 chip 触发钮
顶栏 SHALL 有「关闭」钮（`data-nav-back`，返回）与「完成」主按钮（`btn-primary btn-sm`，保存并返回）；元数据区 SHALL 有心情/天气/地点/标签四个 chip 触发钮（`compose-meta`，`chip-btn`，已选态 `.on`）。
- 前提：在编辑页。
- 操作：点「完成」/点某个 chip 钮。
- 结果：「完成」触发保存（R3/R8 链路）后返回上一屏；chip 钮点击打开对应选择交互（MVP 可占位 sheet）并在选中后以 `.on` 态回显——chip 的取数/落库经 Repository、本屏不直连 Drift（NF5）。

## 非功能需求

### NF1 · Repository 边界（硬红线）
本屏 UI 取数/写数 MUST 只经 `JournalRepo / EntryRepo / MediaRepo / TagRepo / EditingSessionRepo`（经外壳/状态层注入或入参），MUST NOT `import 'package:.../lib/data/...'` 的 Drift 句柄、MUST NOT 在本屏写 SQL / Drift 查询。媒体写入只经 `MediaStore` + `MediaRepo`。

### NF2 · 媒体密钥独立、主密码锁不住照片（合规文案）
插入的图片走**独立设备媒体 key**（HKDF 派生，不随主密码、不参与 rekey，见 `media-storage` D3 / `docs/design/06`）。本屏涉及图片/隐私的文案 MUST NOT 暗示「设了主密码照片就被锁住」；若本屏需呈现该说明，文案走 `AppLocalizations`（与 settings 屏红线文案单一来源协同，tokens-theme D4）。

### NF3 · 无障碍
- 工具栏每个按钮、顶栏关闭/完成、chip 钮 MUST 有 `Semantics` 标签（对齐 editor.html 各 `aria-label`，经 `AppLocalizations`）。
- 所有可点目标命中区 MUST ≥ 44×44 px（含横向滚动工具栏的 `.tb` 钮）。
- 正文/标题文本与底的对比度 MUST ≥ WCAG AA（4.5:1）；着色元素（accent 的日期 kicker / chip 选中态）按 tokens-theme NF1 分族口径达标（沿用六套主题 token，不在本屏新造色）。
- 动效（工具栏出现/chip 选中/sheet 弹出）MUST 尊重系统「减弱动态效果」：经 `ui-kit-components` 的 `dayzMotionDuration` 门，`disableAnimations` 时降为近瞬时。

### NF4 · 视觉走 token、不硬编码
本屏所有颜色/字号/间距/圆角/阴影 MUST 走 `context.dayz.*` + `DayzSpacing/DayzRadii/DayzMotion`（来自 `design-tokens-theme`），MUST NOT 在屏内硬编码色值/像素字号/魔法间距。AppFlowy 编辑器的 `EditorStyle` 配色/字体 MUST 由 token 注入（标题/日记正文衬线、UI 无衬线、CJK 行高，对齐 tokens-theme R6）。

### NF5 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+（minSdk 26）正常工作：软键盘弹出时工具栏停靠正确、`image_picker` 在两端可取图、编辑器滚动与软键盘不互相遮挡。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | **是** | 图片走媒体加密容器 + 独立媒体 key（NF2）；Repository 边界禁直连 DB（NF1） |
| 权限 | **是** | `image_picker` 触发相册/相机系统权限 |
| 无障碍 | **是** | 工具栏/顶栏/chip 的 Semantics + 44px 命中 + 对比度 + reduce-motion（NF3） |
| 性能 | 否 | 富文本编辑为交互态，无可度量运行阈值（重活如缩略图明确范围外） |
| 多端兼容 | **是** | iOS 13+ / Android 8+ 键盘停靠与取图（NF5） |

→ 命中「安全 / 权限 / 无障碍 / 多端兼容」多维 + 跨多模块（消费 tokens / ui-kit / shell / editor-json-contract / media / auto-save / data-layer 多个前置交付物，本 spec 文件变更落 `lib/ui/editor/` 单模块但依赖跨 spec）→ **标准档**（四件套 + `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。
