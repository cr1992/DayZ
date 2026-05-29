---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 设计：editor-json-contract（编辑器文档 JSON 契约）

> **精确字段补全约定**：本文凡标注 **【实现时补全】** 处，AppFlowy 的精确字段名/结构以 `packages/appflowy-editor/lib/appflowy_editor.dart` 导出的 `Document` / `Node` 及各 `*BlockKeys`（如 `ImageBlockKeys`、`HeadingBlockKeys`、`TodoListBlockKeys`）源码为准，实现任务须先读源码再落字段，不在本契约里凭空发明。已通过读源码确认的结构（根 `page`、节点 `type`/`data`/`children`、文本 `delta`、`ImageBlockKeys.url/width/height/align`、`HeadingBlockKeys.level`、`TodoListBlockKeys.checked`）直接写入下文，不再标补全。

## AppFlowy 文档结构（已读源码确认的事实基线）

- 文档根为单个 `Node`，`type='page'`，其 `children` 为块节点列表；`Document.toJson()` 产出 `{'document': <root.toJson()>}`。
- 每个 `Node` JSON 形如 `{'type': String, 'data': Map<String,Object>, 'children': List<Node>}`（`node.dart`）。
- 含文本的块（段落/标题/列表/引用/待办）文本存在 `data.delta`（Quill 风格 delta：`[{'insert': '...', 'attributes': {...}}]`），行内样式（bold/italic/underline/strikethrough/code/href）落在 delta 段的 `attributes`。
- 图片块 `type='image'`，`data` 含 `url`/`width`/`height`/`align`（`ImageBlockKeys`）——**注意：原生 `url` 字段正是本契约要改造的落点**（见 D2）。
- 块组件与自定义块通过 `BlockComponentBuilder` / `NodeWidgetBuilder` 注册到编辑器（`block_component_service.dart`）。

## 技术决策

### D1 · 序列化：用 AppFlowy 原生 `Document.toJson/fromJson` vs 加薄封装层
- **背景：** `content_json` 需既能喂回编辑器，又能被只读渲染器/抽取器/导出器消费；同时 R1 要求带 `docVersion` 文档格式版本号，而原生 `toJson()` 顶层只有 `{'document': {...}}`，没有版本位。
- **选项：**
  - A. 直接存原生 `Document.toJson()`，版本号无处安放，未来迁移靠结构嗅探。
  - B. **薄封装层**：入库结构为 `{'docVersion': 1, 'document': {...}}`，`document` 子树原样复用 AppFlowy 的 `toJson()`/`fromJson()`，封装层只负责包/拆版本号 + 校验。
  - C. 自定义一套 JSON、运行时与 AppFlowy 互转——重复造轮、易漂移。
- **选择：** B。提供 `EditorDocCodec.encode(Document) -> String` / `decode(String) -> (int version, Document)` 薄封装。
- **理由：** 既满足 R1 版本位，又最大化复用 AppFlowy 原生序列化（编辑器写入即合法），封装层逻辑极薄、不触碰块内部结构，降低与上游包演进的耦合。读取时按 `docVersion` 路由迁移（当前仅 v1，迁移表留空占位）。
- **代价：** 入库 JSON 比原生多一层包裹，所有消费方须经 `EditorDocCodec.decode` 拆包而非直接 `Document.fromJson`——以一个明确的统一入口换取版本可演进，可接受。

### D2 · 图片节点 media.id 落点：复用 image node 的 url 字段 vs 自定义 attribute
- **背景：** R2 要求图片引用 `media.id` 而非路径，但 AppFlowy 原生 image 块的 `data.url` 期望是可直接加载的 url/路径。需决定 `media.id` 放哪、运行时如何解析为真实文件。
- **选项：**
  - A. 把 `media.id` 直接塞进原生 `url` 字段——污染语义，第三方工具/上游渲染器会当真去 load 一个非法 url。
  - B. **自定义 scheme 复用 url**：`url = 'dayz-media://<media.id>'`，保留原生字段位，由一个 `ImageUrlResolver` 拦截该 scheme，经 `media.id → media.rel_path → 当前媒体目录` 解析为运行时可读路径（解密流见 `media-storage`）。
  - C. **加自定义 attribute**：在 image node `data` 中增 `media_id` 字段，`url` 留空，渲染时优先读 `media_id`。
- **选择：** 倾向 **C（`data.media_id` 为权威引用键，`url` 不入库/置空）**，**最终落点【实现时补全】**——须读 `ImageBlockKeys` 与 `image_block_component.dart` 确认自定义 `data` 字段能否被原生 image builder 忽略而不报错；若原生 builder 强依赖 `url`，则回退方案 B（自定义 scheme），二选一在实现首个任务中拍板并记录。
- **理由：** C 语义最干净（引用键与可加载 url 解耦，契约层不掺运行时路径）；B 是兼容性更稳的退路。无论 C/B，`content_json` 中 MUST NOT 出现真实路径——满足 R2「路径变化不破坏文档」。
- **代价：** 需要一个统一的「图片节点 → 真实文件」解析层（`ImageUrlResolver`/自定义 image BlockComponentBuilder），编辑器与只读渲染器都要接它；C 还需确认原生 image builder 对额外字段的容忍度。

### D3 · 位置 / 天气自定义块的 AppFlowy 注册方式
- **背景：** R3 要求预留位置块/天气块，且其值引用 `entries` 的结构化字段而非自由文本；需在 AppFlowy 中成为一等块。
- **选项：**
  - A. 用段落块 + 特殊文本前缀模拟——无法结构化、抽取易误判、UI 无法做专属样式。
  - B. **自定义 node type + BlockComponentBuilder**：注册 `type='location'` 与 `type='weather'` 两个自定义块，各配 `NodeWidgetBuilder`/`BlockComponentBuilder`（编辑器）与只读 builder（只读渲染器）。
- **选择：** B。两个自定义块：
  - 位置块 `type='location'`，`data`: `{ place_name, lat, lng }`（镜像 `entries.place_name/lat/lng`）。
  - 天气块 `type='weather'`，`data`: `{ weather_code, weather_temp }`（镜像 `entries.weather_code/weather_temp`）。
  - **精确 data 字段名与 BlockComponentBuilder 注册 API 形态【实现时补全】**（读 `block_component_service.dart` / `page_block_component.dart` 确认 builder 注册与自定义 `data` 序列化是否随原生 `Node.toJson` 自动透传——已确认 `Node.toJson` 透传任意 `data`，故自定义字段可无损往返）。
- **理由：** 自定义块是 AppFlowy 一等机制，编辑器/只读渲染器/抽取器/导出器都能按 `type` 分支识别；值引用结构化字段，导出降级与 UI 渲染都有确定数据源。
- **代价：** 每个自定义块要写两套 builder（编辑 + 只读），且自定义块不被上游 markdown/html encoder 识别，导出降级须由本契约的导出器显式处理（见 D4）——已在 R3/NF2 覆盖，可接受。

### D4 · content_plain 遍历抽取策略 + 自定义块降级规则
- **背景：** R4/NF1 要求纯同步、无 I/O 地把文档树抽成纯文本，覆盖所有块；R3 要求自定义块降级为文本行。同一套「块 → 文本行」映射也是导出降级的基础。
- **选项：** 递归 DFS 遍历 vs 复用 AppFlowy 的 `NodeIterator`。
- **选择：** 一个纯函数 `extractPlainText(Document) -> String`，按块清单表的「`content_plain` 降级表现」列逐块映射，深度优先遍历 `children`，块间以 `\n` 连接：
  - 文本块（段落/标题/列表项/待办/引用）：取 `delta.toPlainText()`（已确认 `text_delta.dart` 提供），列表/待办按表格规则加前缀。
  - 标题：纯文本即可，标题层级不进 plain（条目标题取**第一行**，R4）。
  - 图片/分割线：图片产出占位文本或空行（见表）；分割线产出空（或 `---`，按表）。
  - 位置块 → `📍 {place_name}`；天气块 → `🌤 {weather_temp}°C`（缺值时降级，规则见表注）。
  - 未知块（R5）：尝试取其 `data.delta` 文本，无则跳过，不抛异常。
- **抽取规则与导出降级规则 MUST 同源**（同一张「降级表现」表驱动），避免 plain 与导出出现两套文本。
- **理由：** 纯函数、无 I/O 满足 NF1；表驱动保证四方一致与可测。
- **代价：** 图片/媒体在 plain 中只剩占位、不含描述（MVP 无 alt 文本），可接受；将来加 alt 再扩展。

## 块 / 节点清单

> 这是 @Ray 做编辑页/块样式 UI 设计的直接输入，也是抽取器/只读渲染器/导出器的封闭识别清单（R5）。
> 「AppFlowy node type」列：标准块取自已确认的 `*BlockKeys.type` 常量；自定义块为本契约新增。
> 「content_plain 降级表现」列同时是导出降级规则的来源（D4）。

| 块类型 | AppFlowy node type | 关键属性（data） | content_plain 降级表现 | 是否自定义块 |
|--------|--------------------|------------------|------------------------|--------------|
| 段落 | `paragraph` | `delta`（行内文本+样式） | 文本原文 | 否 |
| 标题 H1 | `heading` | `level=1`, `delta` | 文本原文（首块即条目标题来源） | 否 |
| 标题 H2 | `heading` | `level=2`, `delta` | 文本原文 | 否 |
| 标题 H3 | `heading` | `level=3`, `delta` | 文本原文 | 否 |
| 无序列表项 | `bulleted_list` | `delta`, `children`（可嵌套） | `• ` + 文本，每项一行 | 否 |
| 有序列表项 | `numbered_list` | `delta`, `children`（可嵌套；序号运行时算） | `1. ` 起的序号 + 文本 | 否 |
| 待办 checkbox | `todo_list` | `checked`(bool), `delta` | `[x] `/`[ ] ` + 文本 | 否 |
| 引用 | `quote` | `delta` | `> ` + 文本 | 否 |
| 代码块 | `code`（**type 名【实现时补全】**，确认是否内置/需启用插件） | `delta`, `language`(可选) | 代码文本原文（保留换行） | 否（若需插件则标注） |
| 分割线 | `divider` | （无 delta） | 空行（导出为 `---`） | 否 |
| 图片 | `image` | **`media_id`（D2 权威引用键）**, `width`, `height`, `align`；`url` 不入库 | `[图片]` 占位行 | 否（结构原生，引用键改造） |
| 位置块 | `location`（自定义） | `place_name`, `lat`, `lng` | `📍 {place_name}` | **是** |
| 天气块 | `weather`（自定义） | `weather_code`, `weather_temp` | `🌤 {weather_temp}°C` | **是** |
| 行内样式（非块） | — | delta `attributes`: `bold`/`italic`/`underline`/`strikethrough`/`code`/`href` | 仅保留文字，丢样式 | 否（行内，附于上述文本块） |

> 表注：
> - **MVP 块集合 = 上表去掉「待补全/待定」标注后的封闭集**；代码块若依赖未内置插件，可在首个实现任务中决定「MVP 纳入并启用插件」或「降级为段落、移出 MVP」，结论回填本表。
> - **未知块（清单外 type）**：抽取器取 `data.delta` 文本或跳过；只读渲染器跳过或降级为段落，均不得崩溃（R5）。
> - **位置/天气缺值降级**：`place_name` 为空时位置块产出空（不输出 `📍`）；`weather_temp` 为空但有 `weather_code` 时输出图标+天气描述，二者皆空则产出空。**精确缺值规则在抽取器任务中定稿并补全本注**。
> - **嵌套**：列表/待办的 `children` 嵌套子项，抽取按层级递归，UI 设计需考虑缩进层级呈现。

## 架构

```mermaid
graph TD
  EDITOR[AppFlowy Editor 编辑态] -->|Document.toJson| CODEC[EditorDocCodec 薄封装<br/>+docVersion D1]
  CODEC -->|encode| CJ[(content_json 入库)]
  CJ -->|decode| CODEC2[EditorDocCodec.decode]
  CODEC2 --> RO[只读渲染器]
  CODEC2 --> EXT[extractPlainText 抽取器 D4]
  CODEC2 --> EXP[导出器 JSON→HTML/PDF<br/>下游 spec 消费]
  EXT -->|第一行=标题| CP[(content_plain 入库)]

  subgraph 块识别（封闭清单 R5）
    BC[BlockComponentBuilder 注册<br/>标准块 + location/weather 自定义块 D3]
  end
  EDITOR -.接.-> BC
  RO -.接.-> BC

  subgraph 图片引用解析 D2
    IMG[image 节点 media_id] --> RES[ImageUrlResolver<br/>media.id→rel_path→真实文件]
  end
  EDITOR -.接.-> RES
  RO -.接.-> RES
  RES -.解密流.-> MS[(media-storage)]
```

## 文件变更

> 路径为契约层落点建议；最终包/目录结构随项目壳（M0）确定，**精确路径【实现时补全】**。

- `lib/editor/contract/editor_doc_codec.dart`        新建（D1 薄封装 encode/decode + docVersion + 迁移路由占位）
- `lib/editor/contract/block_types.dart`             新建（块 type 常量 + 自定义块 location/weather 的 data key 常量，R5 封闭清单的代码化）
- `lib/editor/contract/plain_text_extractor.dart`    新建（D4 `extractPlainText`，表驱动降级 + 标题取首行）
- `lib/editor/contract/blocks/location_block.dart`   新建（D3 自定义块定义 + 编辑/只读 BlockComponentBuilder）
- `lib/editor/contract/blocks/weather_block.dart`    新建（D3 自定义块定义 + 编辑/只读 BlockComponentBuilder）
- `lib/editor/contract/image_url_resolver.dart`      新建（D2 media.id → 真实文件解析；接 media-storage）
- `lib/editor/contract/readonly_renderer.dart`       新建（D2/D3/NF2 只读渲染器，T6）
- `lib/editor/contract/editor_block_registry.dart`   新建（D3 编辑/只读共用的统一 BlockComponentBuilder 注册表，T6）
- `lib/editor/contract/export_fallback.dart`         新建（D4 导出降级映射，复用抽取器降级表，T7）
- `test/editor/contract/...`                         新建（往返/抽取/一致性测试）

## 已知风险

- **D2 落点未拍板**（自定义 `data.media_id` vs 自定义 url scheme），取决于原生 image builder 对额外字段/非法 url 的容忍度——首个实现任务读源码后定稿，二选一并回填。
- **代码块是否内置**未确认（`code` type 可能需启用插件），影响 MVP 块集合——首个任务确认后回填块清单表。
- 自定义块（location/weather）不被上游 markdown/html encoder 识别，导出必须由本契约导出降级规则兜底；若将来接 AppFlowy 官方 HTML 导出，需注入自定义块的 HTML 序列化器（远期，本期只保证 plain 降级）。
- `docVersion` 迁移表当前为空（仅 v1）；格式演进时须在 codec 中补迁移函数，避免老文档读不出。
- 抽取器与导出器共用「降级表现」表，二者实现若分散到不同 spec，须以本契约表为唯一来源，防止漂移（verification 设交叉校验）。
