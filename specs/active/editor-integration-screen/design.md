---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-31
文档状态：定稿
---

# 设计：editor-integration-screen

> 视觉与映射依据：[`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §1（分层：屏依赖组件依赖 token）/§3（逐屏映射立场 + 网页取巧降级 + 重活/加密/IO 红线对 UI 生效）/§4（四闸：token/样式参数/布局几何/栅格观感）/§9（页面级 W2）/§10（动 lib/ui 前红线）/§11（验收口径）；屏源真源 [`ui-design/current/pages/screens/editor.html`](../../../ui-design/current/pages/screens/editor.html)（状态 `?state=empty|writing|rich`）；组件类名与最小 HTML [`ui-design/current/docs/DESIGN-REF.md`](../../../ui-design/current/docs/DESIGN-REF.md) §3「编辑器工具栏 `.toolbar`」/§3b「编辑页 `.compose-*`」/§3c「编辑器富格式块 `.cb-*`」/§5（图标）；HTML→Flutter 机制映射 [`ui-design/current/docs/PROTOTYPE-ARCH.md`](../../../ui-design/current/docs/PROTOTYPE-ARCH.md) §6（富文本编辑器 → AppFlowy Editor；固定头；`?state=`→状态管理）。组件词汇复用 `ui-kit-components`（`DayzGlassAppBar`/`DayzButton`/`DayzTextField`/`DayzTag`/`DayzToolbar`/`DayzSheet`/`AppLocalizations`/`dayzMotionDuration`），路由词汇复用 `ui-shell-navigation`（`Routes.editor` + FAB 创建意图入参 + `PlaceholderScreen` 替换）。

## 技术决策

### D1 · 屏只装配、底层契约全按交付物名消费（接缝定界）
- **状态：** 采纳
- **背景：** 编辑页接缝最多（编辑器 / 文档 codec / 媒体加密 / 草稿协调器 / Repository / 工具栏命令）；若任一接缝在本屏重造，必与对应底层 spec 漂移或撞红线（Repository 边界、媒体密钥、缩略图重建）。
- **选项：** (A) 本屏包揽编辑器装配 + codec + 媒体写入 + 草稿逻辑（自给自足，重造）；(B) 本屏只做「页面组装 + 接线」，文档结构/媒体加密/草稿内核/取数各按前置 spec 交付物名调用；(C) 介于两者，部分接缝本屏临时实现待后续抽离。
- **选择：** B。本屏产物 = `lib/ui/editor/` 下的页面 widget + 一层薄「编辑器适配/接线」代码（把 AppFlowy 的 `EditorState`/`Document`/onChanged ⇄ codec/草稿/媒体 的 glue）。文档契约（`EditorDocCodec`/`extractPlainText`/`block_types`/`editor_block_registry`/`ImageUrlResolver`/自定义块）一律 `import` `editor-json-contract` 交付物；媒体走 `MediaStore`+`MediaRepo`；草稿走 `DraftCoordinator`；取数走 Repository。
- **理由：** 把「会变/有红线」的底层收口到各自 spec，本屏只剩页面级关注点（布局/状态/交互/视觉还原），符合方法论 §1 屏层定位与 §10 红线第 4 条。
- **代价：** 强依赖多个尚未定稿的前置 spec；未就绪时本屏被阻塞或用 stub 跑通（见 D9 与已知风险）。这是页面级 spec 处于波次 W2 的固有成本，换来零重造、零红线越界。

### D2 · 正文 = AppFlowyEditor，标题 = 独立无边框 TextField（两个分离控件）
- **状态：** 采纳
- **背景：** editor.html 把标题（`compose-title` input）与正文（`compose-body`）画成两块；产品选型 A 明确正文是 AppFlowy（PROTOTYPE-ARCH §6）。AppFlowy 文档本身也可承载标题块，但设计稿把标题独立成无边框 `input`、且 `editor-json-contract` 约定「条目标题 = content_plain 首行 / 首个 heading」。
- **选项：** (A) 标题也并进 AppFlowy 文档首个 heading 块（单一编辑器）；(B) 标题用独立 `TextField`（无边框）+ 正文用 `AppFlowyEditor`，两控件分离，保存时本屏负责把标题与正文按 `editor-json-contract` 约定合并/拆分。
- **选择：** B。标题 = `ui-kit` 的 `DayzTextField`（或其无边框变体；若 `DayzTextField` 不支持 borderless 则本屏用裸 `TextField` + `InputDecoration.collapsed` 走 token，记已知风险）；正文 = `AppFlowyEditor`。标题与正文如何映射到 `content_json`/`content_plain` 首行的**精确约定以 `editor-json-contract`（content_plain 首行=标题、heading 首块）为准，实现首个任务对齐**。
- **理由：** 还原设计稿的「无框标题 + 富文本正文」分离观感；标题用普通文本输入比让用户在富文本里编首个 heading 更符合日记直觉（Day One 同此）。
- **代价：** 标题/正文双控件需协调焦点与「标题作为 content_plain 首行」的一致性；交接点明确写进 D 与 verification，可控。

### D3 · 底部工具栏：外形复用 DayzToolbar，富文本能力对接 AppFlowy mobile_toolbar（不自管选区）
- **状态：** 采纳
- **背景：** editor.html `toolbar editor-dock` 是横向滚动按钮条（DESIGN-REF §3「编辑器工具栏 `.toolbar`」，明确「对接 AppFlowy Editor」）；`ui-kit-components` 的 `DayzToolbar` 是**纯外形 + 回调、不接 AppFlowy 命令**（见其 design 已知风险）。而 R4/R5/R6 要求：能力由 AppFlowy mobile_toolbar 体系落地、停靠交给 AppFlowy（不自监听 viewInsets）、高亮态由选区实际格式派生。
- **选项：**
  - A. 完全用 `DayzToolbar`（纯外形）+ 本屏手写每个命令对 `EditorState` 的 transaction + 本屏手监听键盘高度顶起 + 本屏自管按钮高亮布尔。
  - B. 完全用 AppFlowy 原生 `MobileToolbar`/`MobileToolbarV2` + toolbar items，工具栏视觉由 AppFlowy `MobileToolbarStyle` 注入 token 还原 `editor-dock` 外观；停靠/选区高亮/命令全由 AppFlowy 体系处理。
  - C. 混合：外观壳用 `DayzToolbar` 排版，内部按钮的点击/高亮/停靠仍委托 AppFlowy 机制。
- **选择：** B 为主。工具栏直接用 AppFlowy `MobileToolbar(V2)` 配 toolbar items（`packages/appflowy-editor/lib/src/editor/toolbar/mobile/`），用 `MobileToolbarStyle` + token 把外观（背景/按钮/分隔/激活态色）调成 `editor-dock` 观感；停靠随键盘、选区高亮、命令执行全部由 AppFlowy 体系负责（满足 R4/R5/R6 三条且天然不自管）。`DayzToolbar` 的视觉外形作为「目标观感」参照与 golden 比对对象，不在本屏复制其逻辑。**AppFlowy mobile_toolbar 的精确 item 清单与 `MobileToolbarStyle` 可配项以 `packages/appflowy-editor` 源码为准，实现首个任务读源码对齐 editor-dock 能力集（H/B/I/U/S/code/color/list×3/quote/link/divider/image），缺失的 item（如自定义「插入图片」走 D5、分隔线/链接若 mobile item 未内置）由本屏补一个 AppFlowy 自定义 toolbar item，不脱离 AppFlowy 体系自管。**
- **理由：** R5「不自监听 viewInsets」与 R6「高亮态派生自选区」用 AppFlowy 原生体系是**最省且最不易出错**的落法——AppFlowy mobile_toolbar 自带键盘随动停靠与基于 `EditorState.selection` 的 toggled 态。自己用 `DayzToolbar` 复刻这两点等于重造 AppFlowy 已有机制，正是 R5/R6 要避免的坑。
- **代价：** 工具栏外观还原受 `MobileToolbarStyle` 可配项约束，未必能逐像素等同 `editor-dock`（如分隔 `.div`、横向滚动手感）；差异进 golden/SSIM advisory（design-sync 期二），不阻塞。若某能力 AppFlowy mobile item 缺失，须写一个 AppFlowy 自定义 toolbar item（仍在其体系内，避免破 R5/R6）。

### D4 · 三状态用「页面入参 + 状态」渲染，不照搬 `?state=`
- **状态：** 采纳
- **背景：** editor.html 的 `empty/writing/rich` 是原型 `?state=` 显隐（PROTOTYPE-ARCH §3）；§6 映射为「页面入参 + 状态管理，同一 Widget 按 state 渲染」。三状态的差异其实是**文档内容差异**（empty=空文档、writing=一段正文、rich=多块），不是三套独立 UI。
- **选项：** (A) 三个独立 Widget；(B) 一个 `EditorScreen`，按入参（新建 vs 加载的 `Document` 内容）自然呈现三态——empty=空 `Document` + 占位、writing/rich=非空 `Document`；顶栏标题（「新日记」/「草稿已存」）由「是否新建 / 是否已有草稿落库」派生。
- **选择：** B。`EditorScreen({entryId?, initialDraft?, createIntent?})`：无 entryId 且无草稿 = empty；有内容 = writing/rich（rich 仅是 writing 的富块超集，同一渲染路径）。顶栏标题文案由状态派生（empty→`l10n.editorTitleNew`「新日记」、有草稿→`l10n.editorTitleDraftSaved`「草稿已存」）。
- **理由：** 三态本质是数据态，用一套 widget + 状态最省、最贴 §6 映射；避免三份重复布局。
- **代价：** 「草稿已存」标题需与 `auto-save-draft` 的保存状态联动（首次成功 flush 后才显「草稿已存」）；联动点写进 R8 接线与 verification。

### D5 · 图片插入链路：image_picker → MediaStore.put → MediaRepo.addMeta → image node（media.id）
- **状态：** 采纳
- **背景：** R7 + NF2：图片必须经媒体加密容器（`DMED`，独立设备媒体 key）落盘、元数据入 `MediaRepo`，文档只存 `media.id`（权威引用键，落点以 editor-json-contract D2 为准——`data.media_id` 或自定义 url scheme，二选一在 editor-json-contract 拍板）；`content_json` MUST NOT 含真实路径。缩略图重建是红线（不在本屏同步触发）。
- **选项：** (A) 本屏直接 `image_picker` 取图后写明文文件 + 路径塞 image node（违 NF1/NF2/契约）；(B) 本屏只编排链路、各段调交付物：`image_picker.pickImage` 取字节流 → `MediaStore.put(stream, kind: image)` 得 `media.id`/`rel_path` → `MediaRepo.addMeta` → 用 `editor-json-contract` 的 image 块构造（引用 `media.id`）插入文档；渲染时由 `ImageUrlResolver` 解析回真实文件（解码归契约层）。
- **选择：** B。本屏持一个薄 `EditorImageInserter`（glue）：串起 picker→store→repo→插块；插块用 `editor-json-contract` 暴露的 image 节点构造 + `editor_block_registry` 的 image BlockComponentBuilder（渲染期）。本屏 **不** 触发缩略图（warmup 归 thumbnail-cache，异步、非本屏路径）。
- **理由：** 每段都落在已定职责的 spec，本屏只做编排，满足三条红线（Repository 边界 / 媒体密钥独立 / 不同步重建缩略图）。
- **代价：** 链路跨四个交付物，未就绪时 inserter 用 stub（选图后插一个占位 image 块、media.id 用临时值），记已知风险；真链路就绪后只接线。

### D6 · 自动保存接线：onChanged → plain payload → DraftCoordinator，退出 forceFlush
- **状态：** 采纳
- **背景：** `auto-save-draft` D7 拍板「协调器只接受 plain payload（`targetId, draftJson, isNew, cursorPos`），编辑器侧由接入 spec 写薄 adapter」。本屏正是那层 adapter。
- **选项：** (A) 本屏自己防抖落库（重造协调器）；(B) 本屏监听 AppFlowy `EditorState`/`Document` 变更 → 用 `EditorDocCodec.encode` 得 draftJson → 组 plain payload 喂 `DraftCoordinator`；`AppLifecycleListener`/页面退出经协调器 `forceFlush`（本屏只调，不自己监听生命周期——生命周期桥也在 auto-save-draft）。
- **选择：** B。本屏装一个 `EditorDraftBridge`（glue）：把 AppFlowy onChanged → `(targetId=entryId或新建占位id, draftJson=codec.encode(doc), isNew, cursorPos)` 喂协调器；进入时若 `DraftCoordinator.startupCheck`/恢复状态指示有未完成草稿，加载该草稿（恢复提示条 UI 不在本屏，范围外）；点「完成」或退出触发 `forceFlush`。
- **理由：** 协调器中立接口（auto-save D7）正为此设计；本屏只翻译，不碰防抖/事务/重试。
- **代价：** cursorPos 从 AppFlowy `Selection` 翻成协调器期望形态需一层映射；记实现要点。生命周期 flush 依赖 auto-save 的 `lifecycle_bridge`，本屏退出时再补一次显式 `forceFlush` 兜底。

### D7 · 编辑器视觉经 EditorStyle 注入 token，不硬编码
- **状态：** 采纳
- **背景：** NF4 + tokens-theme R6：编辑器正文走衬线日记字（行高 1.85）、UI 无衬线、CJK 行高；颜色/选区/光标色须取 token。AppFlowy 通过 `EditorStyle`/`EditorStyleCustomizer` 配置文本样式、块样式、光标/选区色。
- **选项：** (A) 用 AppFlowy 默认 `EditorStyle`（与设计稿不符、且写死非 token）；(B) 构造一个 `dayzEditorStyle(context)`，从 `context.dayz.*` + `DayzFonts`/`DayzTextTheme`（tokens-theme 交付物）取色与排版，注入 `AppFlowyEditor` 的 style。
- **选择：** B。本屏 `lib/ui/editor/editor_style.dart` 提供 `dayzEditorStyle(BuildContext)`：正文 `t-diary` 衬线 1.85、标题块走 `t-h*`、选区/光标 = `context.dayz.accent`、code/quote 块底色取 token。块样式（待办勾选色、引用左条、分隔线色）一律 token。
- **理由：** 把编辑器纳入与全屏一致的 token 体系，消灭「编辑器内硬编码」违规面（红线）。
- **代价：** AppFlowy `EditorStyle` 可配项有限，个别块（如代码块字体）可能落到 `DayzFonts.mono`，差异可接受；精确可配项以源码为准、实现时对齐。

### D8 · 顶栏与脚手架：复用 DayzGlassAppBar 壳 + has-dock 底部留白
- **状态：** 采纳
- **背景：** editor.html 用 `.pg.has-dock`（底部停靠工具栏留白）+ `.app-top`（关闭钮 + 标题 + 完成钮）。顶栏壳是跨屏外壳（归 ui-kit 的 `DayzGlassAppBar`；ui-shell 负责装配脚手架）。
- **选项：** (A) 本屏自画顶栏；(B) 复用 `DayzGlassAppBar`（关闭钮 = `data-nav-back` 映射 `Navigator.maybePop`/`Routes` 返回；完成钮 = `DayzButton.primary` small）；底部留白用 `Scaffold` + 工具栏停靠（AppFlowy mobile_toolbar 管键盘随动，静止态底部留白对齐 `has-dock`）。
- **选择：** B。顶栏经 `DayzGlassAppBar`（或编辑页这种「关闭/完成」型可用其精简形态），完成钮用 `DayzButton`，关闭钮用图标钮（§5 SVG path 经 `dayz_icons`/`flutter_svg`，ui-kit 交付）。
- **理由：** 复用跨屏外壳，不在本屏复刻毛玻璃/let-position 逻辑（方法论 §3）。
- **代价：** `DayzGlassAppBar` 若只提供 sliver 形态而编辑页非滚动列表为主体（编辑器自带滚动），装配方式需对齐——记已知风险，必要时用其 `AppBar` 形态或最小占位顶栏（与 ui-shell D9 同款降级）。

### D9 · 跨 spec 依赖未就绪的 stub 降级
- **状态：** 采纳
- **背景：** 本 spec 处波次 W2，多个前置（editor-json-contract / media-storage / auto-save-draft / data-layer / ui-kit / ui-shell）可能尚未定稿。需让本屏在依赖未全就绪时仍可被 widget test 独立验证、可在 Debug Home pump。
- **选择：** 对每个跨 spec 交付物定义**本屏侧的窄接口/适配点**，依赖就绪则接真实现、未就绪用内存 stub（codec 用 round-trip 假实现、MediaStore 用内存字节、DraftCoordinator 用记录调用的 fake、Repository 用假数据）。stub 只活在 demo/测试装配，**不**进生产路径的判断分支（生产路径只 import 交付物接口）。
- **理由：** 解耦「页面可独立验证」与「底层全就绪」，符合 ui-shell D1/D3 的同款降级思路。
- **代价：** 需维护一组测试用 fake；属验收基建（在 tasks 预批），可接受。

### D10 · 文案集中 AppLocalizations、日期走 intl（落实 docs/design/11）
- **状态：** 采纳
- **背景：** `docs/design/11` 拍板 UI 文案唯一来源为 zh/en ARB；屏内禁裸中文，日期/数字走 `intl`。
- **选择：** 本屏用到的文案（顶栏「新日记」/「草稿已存」/「完成」/「关闭」、标题占位「标题」、正文占位「写点什么吧……」/「在这里继续写下今天的故事」、chip「心情/天气/地点/标签」、工具栏各 aria-label、媒体合规说明若有）补入 `lib/l10n/arb/app_zh.arb` 与 `app_en.arb`，运行期经 `AppLocalizations.of(context)` / `l10n.xxx` 取用。日期 kicker「今天 · 5月29日 周五」经 `package:intl`（`DateFormat`，当前 locale），MUST NOT 自拼。
- **理由：** 单一可审计文案落点；测试用 `find.text(l10n.xxx)` 自带「只引常量」回归护栏。
- **代价：** `app_zh.arb` / `app_en.arb` 是跨 spec 文件，需保持 zh/en key 集合一致并跑 `gen-l10n`。

## 架构

```mermaid
graph TD
  SHELL[ui-shell-navigation: Routes.editor + FAB 创建意图入参] --> ES[lib/ui/editor/editor_screen.dart]
  ES --> AB[DayzGlassAppBar 壳 · 关闭/完成 · ui-kit]
  ES --> TITLE[标题: 无边框 TextField/DayzTextField · D2]
  ES --> META[compose-meta: chip 触发钮 · DayzTag/DayzButton · D8/R10]
  ES --> AFE[AppFlowyEditor 正文 · packages/appflowy-editor · R1]

  AFE --> STYLE[editor_style.dart · dayzEditorStyle 注入 token · D7/NF4]
  STYLE --> TOK[design-tokens-theme: context.dayz / DayzFonts / DayzTextTheme]
  AFE --> MTB[AppFlowy MobileToolbar(V2) + items · D3/R4/R5/R6]
  MTB --> MTBSTYLE[MobileToolbarStyle ← token · editor-dock 观感]

  ES --> BRIDGE[editor_draft_bridge.dart · onChanged→payload · D6/R8]
  BRIDGE --> CODEC[editor-json-contract: EditorDocCodec.encode/decode + extractPlainText · R3]
  BRIDGE --> DC[auto-save-draft: DraftCoordinator(plain payload) + forceFlush]

  ES --> INS[editor_image_inserter.dart · D5/R7]
  INS --> PICK[image_picker: 取图字节]
  INS --> STORE[media-storage: MediaStore.put(DMED, 独立媒体key) ]
  INS --> MR[data-layer: MediaRepo.addMeta]
  INS --> IMGNODE[editor-json-contract: image node(media.id) + ImageUrlResolver 渲染]

  ES -. 取数禁直连 Drift NF1 .- REPO[data-layer: EntryRepo/JournalRepo/TagRepo/EditingSessionRepo]
  ES --> DEMO[lib/demo/editor_screen_demo.dart · Debug Home 入口]
  DEMO --> DH[lib/demo/demo_entry.dart · demos 末尾追加一行]
```

## 文件变更

> 这是本 spec 任务「可改文件」的**唯一来源与上界**；任一任务可改文件 MUST ⊆ 本清单。新建 Dart 文件 MUST 加 MPL-2.0 头注（模板见 README「License」/ AGENTS.md）。本 spec 文件全部落 `lib/ui/editor/` 与 `lib/demo/` + `test/ui/editor/`；**不列入** `lib/ui/widgets/`（组件归 ui-kit）、`lib/ui/theme/`（token 归 tokens-theme）、`lib/ui/shell/`（外壳归 ui-shell）、`lib/editor/contract/`（契约归 editor-json-contract）、`lib/media/`/`lib/drafts/`/`lib/data/`（底层各 spec）。

**屏体与接线 `lib/ui/editor/`**
- `lib/ui/editor/editor_screen.dart`            新建（编辑页：顶栏装配 + 标题 TextField + compose-meta chip + AppFlowyEditor 正文 + 三状态渲染，D2/D4/D8/R1/R2/R9/R10）
- `lib/ui/editor/editor_style.dart`             新建（`dayzEditorStyle(context)`：AppFlowy `EditorStyle` 从 token 注入，D7/NF4）
- `lib/ui/editor/editor_toolbar.dart`           新建（AppFlowy `MobileToolbar(V2)` 装配 + `MobileToolbarStyle` token + editor-dock 能力集 item 清单 + 缺失能力的自定义 toolbar item，D3/R4/R5/R6）
- `lib/ui/editor/editor_draft_bridge.dart`      新建（AppFlowy onChanged → plain payload → `DraftCoordinator`；退出 `forceFlush`；进入消费恢复状态，D6/R8）
- `lib/ui/editor/editor_image_inserter.dart`    新建（image_picker → MediaStore.put → MediaRepo.addMeta → image node，D5/R7）
- `lib/ui/editor/editor_meta_bar.dart`          新建（`compose-meta` 四 chip 触发钮 + 已选态回显 + 触发占位 sheet，R10；取数经 Repository 入参，NF1）

**gen-l10n 文案**
- `lib/l10n/arb/app_zh.arb`、`lib/l10n/arb/app_en.arb`             修改（补编辑页 zh/en 文案与 aria-label key，D10）
- `lib/l10n/gen/app_localizations*.dart`                          修改（`flutter gen-l10n` 生成产物）
- `lib/ui/shell/app_router.dart`                修改（**归属 ui-shell-navigation**；本屏仅把 `Routes.editor` 的 `builder` 从 `PlaceholderScreen` **替换为** `EditorScreen` 一行，不改路由表其余项；归属在 README/各屏协调）

**共享依赖**
- `pubspec.yaml`                                修改（加 `image_picker`；白名单外共享依赖，显式列出）
- `pubspec.lock`                                修改（`flutter pub get` 后锁定版本，避免「清单只写 pubspec.yaml 顺手改 lock」越界）

**Debug Home 入口 `lib/demo/`**
- `lib/demo/editor_screen_demo.dart`            新建（编辑页 demo：用 stub 依赖 pump 三状态，真机走查；D9）
- `lib/demo/demo_entry.dart`                    修改（**仅末尾追加一行**，不插中间、不改 `DemoEntry` 字段）

**测试目录（白名单 hook 对 `test/**/*_test.dart` 自动放行；非 `_test.dart` 的共享基建由任务 `验收基建` 字段预批）**
- `test/ui/editor/`                             新建（屏体/工具栏/桥/图片插入/状态/无障碍 widget test）
- `test/ui/editor/fakes/`                       新建（跨 spec 依赖的测试 fake：codec/MediaStore/DraftCoordinator/Repository stub，D9，验收基建预批）

## 已知风险

- **跨 spec 依赖（按交付物名引用，多数尚未定稿；READY 门 = 全部前置「已完成」）**：
  - `design-tokens-theme`（README 依赖列）：`context.dayz.*`、`DayzFonts`/`DayzTextTheme`、六套 ThemeData、`AppLocalizations` 约定、`dayzMotionDuration` 上游约定。**强依赖**，未定稿则本屏阻塞。
  - `ui-kit-components`（README 依赖列）：`DayzGlassAppBar`/`DayzButton`/`DayzTextField`/`DayzTag`/`DayzToolbar`（仅作目标观感参照，本屏工具栏用 AppFlowy 体系实现）/`DayzSheet`/`dayzMotionDuration` 门/`dayz_icons`(§5 SVG)。未就绪降级见 D8/D9。**`DayzTextField` 是否支持无边框（borderless）待确认**——若不支持，标题用裸 `TextField` + `InputDecoration.collapsed` 走 token（记此处）。
  - `ui-shell-navigation`（README 依赖列）：`Routes.editor`、FAB 创建意图入参（新建/拍照入口）、`PlaceholderScreen`（本屏替换其 builder）。替换 `app_router.dart` 一行的归属在 README/各屏协调，**待确认**该行由本屏改还是 ui-shell 预留 hook。
  - `editor-json-contract`（README 依赖列）：`EditorDocCodec.encode/decode`(+docVersion)、`extractPlainText`、`block_types`、`editor_block_registry`、`ImageUrlResolver`、image 节点的 `media.id` 落点（**D2 未拍板**：`data.media_id` vs 自定义 url scheme，以该 spec 首任务结论为准）。本屏的 codec/插块/渲染全经其交付物，**MUST NOT 自行解析/拼 content_json**。
  - `media-storage`（README 依赖列）：`MediaStore.put(stream, kind)` / `openRead`、`DMED` 容器、独立设备媒体 key（HKDF，不随主密码/rekey）。
  - `auto-save-draft`（README 依赖列）：`DraftCoordinator`（plain payload）、`forceFlush`、`startupCheck`、`DraftRecoveryStatus`、`lifecycle_bridge`。
  - `data-layer`（**非 README 依赖项？——见下「依赖闭合性待确认」**）：`EntryRepo`/`JournalRepo`/`TagRepo`/`MediaRepo`/`EditingSessionRepo` 是取数/写数入口（NF1）。
- **依赖闭合性待确认（须 README 拍板）**：本屏取数/写元数据触及 `data-layer` 的 Repository，且 `media-storage`/`auto-save-draft`/`editor-json-contract` 自身又依赖 `data-layer`。题面给定 README 依赖列 = `design-tokens-theme, ui-kit-components, ui-shell-navigation, editor-json-contract, media-storage, auto-save-draft`，**未直列 `data-layer`**——其可经 media/auto-save/ui-shell 传递依赖覆盖。是否需把 `data-layer` 显式补进本屏 README 依赖列，**留 README 编排者拍板**（本屏不擅自改 README）。
- **AppFlowy mobile_toolbar 能力覆盖待核实**：editor-dock 能力集（H/B/I/U/S/code/color/list×3/quote/link/divider/image）与 AppFlowy `packages/appflowy-editor` 内置 mobile toolbar items 的对应**实现首任务读源码核实**；缺失项写 AppFlowy 自定义 toolbar item（不脱离其体系，守 R5/R6）。若 vendored 包需改动以支持某能力，走 `packages/CHANGELOG.md` 三件套 + 独立 commit（AGENTS.md 红线）——**该改动若发生，属 `appflowy-patch-tracking` 流程、不在本 spec 文件变更白名单内，须停下声明**。
- **`MobileToolbarStyle` 还原度**：工具栏外观能否逐像素等同 `editor-dock`（横向滚动、分隔 `.div`、激活态）受其可配项约束；像素差进 golden/SSIM advisory（design-sync 期二），不阻塞放行（方法论 §4 ④ 软闸）。
- **编辑器 + 软键盘 + 工具栏停靠（NF5）**：iOS/Android 软键盘高度与 AppFlowy mobile_toolbar 停靠在真机的表现须各验一次（人工，NF5）；本屏不自管 viewInsets（R5）。
- **`saturate` 玻璃顶栏像素差**：沿用 ui-kit `DayzGlassAppBar` 的 saturate 降级（其 D6），饱和度差进 advisory，不在本屏处理。
- **图片明文中转**：`image_picker` 返回的临时文件/字节在加密入库前是明文中转态；本屏 SHOULD 在 `MediaStore.put` 成功后清理 picker 临时文件（细节以 image_picker/平台行为为准，记此提醒）；不在 `content_json` 留任何明文路径（R7/NF2）。
- **无持久化 schema 变更**：本屏不新增/改 DB schema（条目/草稿/媒体表归各底层 spec），→ 无数据迁移/回滚要素（verification 不含迁移段）。
- **新文件加 MPL-2.0 头注**：`lib/ui/editor/*.dart`、`lib/demo/editor_screen_demo.dart` 等全部新建 Dart 文件 MUST 在文件顶部加 MPL-2.0 头注。
