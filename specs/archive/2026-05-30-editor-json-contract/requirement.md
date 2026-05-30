---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# editor-json-contract（编辑器文档 JSON 契约）

> **前提（本 spec 假设）：** 编辑器选型 = **方案 A（AppFlowy Editor，纯 Dart）**，@Ray 2026-05-29 拍板（见 `specs/README.md` 顶部 / `specs/archive/2026-05-29-editor-research/`）。本契约的全部结构约定均以 A 的 `Document` JSON 为基线，无需再为 B 预留分叉。

## 背景

编辑器选型已定为**方案 A（AppFlowy Editor，纯 Dart）**（见 `docs/design/03-rich-text-editor-research.md` 第 4 节）。
`docs/design/02-data-storage-and-schema.md` 第 5 节确立：日记正文内容存两份——`content_json`（编辑器序列化的文档 JSON）+ `content_plain`（抽取的纯文本，供搜索/预览/标题）。

本 spec 把 **`content_json` 的结构约定** 固化为一份**跨模块共享契约**。它不是某个具体功能的实现，而是下列模块的**共同依赖**：

- **UI 设计**（@Ray 的编辑页 / 块样式设计直接以本契约的「块清单」为输入）；
- **编辑器集成**（把 AppFlowy Editor 接进编辑页，读写 `content_json`）；
- **Flutter 只读渲染器**（时间线卡片 / 详情页非编辑态，需与编辑器对**同一份 JSON** 渲染一致）；
- **PDF / HTML 导出**（`docs/design/03` 第 6 节：A 方案需 JSON→HTML 或 widget→PDF，自定义块导出降级为文本行）；
- **`content_plain` 抽取器**（编辑器专属；选型已定 A，故本期仅落 A 的一套抽取器，须与 `content_json` 同步）。

契约的两条核心约束（`docs/design/03` 第 6 节）：① 图片节点引用 `media.id`、不写死路径；② 预留「位置块」「天气块」自定义节点，导出降级为文本行 `📍 上海` / `🌤 18°C`。

> 本 spec 落契约与抽取器逻辑，**不落编辑页 UI、不落 PDF 导出全流程**——那些是下游消费方，各自立 spec。本 spec 提供它们引用的「结构 + 抽取器 + 只读渲染器一致性基线」。

## 范围外

- 编辑页 UI / 工具栏 / 块插入菜单的视觉与交互 —— 待 UI 设计稿后立 spec，以本契约的块清单为输入。
- PDF / HTML 导出的完整流程与排版 —— 归后续 `pdf-export` spec；本 spec 只定义「自定义块导出降级规则」供其消费。
- 撤销/重做、协同/CRDT —— 走 AppFlowy 内置 history 与远期同步，受选型决定，不在本 spec。
- 媒体文件的加密存储与缩略图 —— 归 `media-storage` / `thumbnail-cache`；本契约只约定**如何引用** `media.id`，不碰文件本体。
- audio / video 块 —— MVP 仅 image；契约为媒体节点预留 `kind`/`media_id` 通用形态，但本期只实现 image 路径。
- 表格、嵌套列表的复杂排版细节 —— 表格列入「已支持但非 MVP」，本期块清单标注其状态；不实现表格的 plain 抽取以外的导出排版。

## 功能需求

### R1 · content_json 使用 AppFlowy Document JSON 并带文档格式版本号
`content_json` MUST 是合法的 AppFlowy Editor `Document.toJson()` 结构（根 `{'document': {'type':'page', 'children':[...]}}`），且 MUST 在文档顶层附带一个**文档格式版本号**字段（`docVersion`，整数，初值 `1`），用于将来格式演进时识别与迁移。
- 前提：编辑器保存一篇含若干块的文档
- 操作：序列化为 `content_json` 字符串入库
- 结果：该字符串可被 `Document.fromJson` 无损还原；顶层可读出 `docVersion`

### R2 · 图片节点 MUST 引用 media.id 而非写死路径
图片块 MUST 以 `media` 表的 `id` 作为引用键（落在图片节点 data 的约定字段，见 design D2），MUST NOT 在 `content_json` 中写死绝对路径或 `<app_documents>` 相对路径。
- 前提：往年同一篇日记，App 重装导致 iOS 沙盒容器 UUID 变化（`docs/design/02` 第 5 节实战避坑）
- 操作：重新打开该篇日记
- 结果：`content_json` 不变（仍引用同一 `media.id`）；运行时由 `media.id → media.rel_path → 当前媒体目录` 解析出真实文件，文档完整性不被路径变化破坏

### R3 · 预留位置块 / 天气块自定义节点，降级为文本行
契约 MUST 预留两个自定义块节点类型——**位置块**与**天气块**（节点 type 命名见 design D3），其 data 引用 `entries` 表已有的结构化字段（`place_name` / `lat` / `lng`；`weather_code` / `weather_temp`），而非自由文本。
- 前提：一篇日记含一个位置块（上海）与一个天气块（18°C）
- 操作：抽取 `content_plain` / 执行导出降级
- 结果：自定义块降级为独立文本行 `📍 上海` 与 `🌤 18°C`（图标 + 值；具体格式规则见 design D4）

### R4 · content_plain 抽取器，与 content_json 同步
系统 MUST 提供一个 `content_plain` 抽取器：输入 `content_json`，遍历文档树产出纯文本。MUST 覆盖 R5 块清单中的每一种块类型（按各块的降级表现产出文本）；标题（用于条目标题）MUST 取产出文本的**第一行**（`docs/design/02` 第 5 节）。抽取器 MUST 在每次保存 `content_json` 时同步重算 `content_plain`，二者不得漂移。
- 前提：编辑器保存 `content_json`
- 操作：调用抽取器
- 结果：得到与文档可见文本一致的 `content_plain`；其第一行等于该条目标题；空文档产出空串

### R5 · 支持的块 / 节点清单
契约 MUST 明确一份**封闭的**「支持块清单」（详见 design.md 的块清单表格），编辑器、只读渲染器、抽取器、导出器四方 MUST 仅按此清单识别与处理块类型；遇到清单外的未知块类型，抽取器与只读渲染器 MUST 优雅降级（抽取其 `delta` 纯文本或跳过，不得崩溃），不得静默丢失文档其余内容。
- 前提：`content_json` 中混入一个清单外的未知 type 块
- 操作：只读渲染 / 抽取
- 结果：未知块被安全跳过或降级为其文本，其余块正常渲染/抽取，无异常

## 非功能需求

### NF1 · 抽取性能
`content_plain` 抽取器对一篇典型日记（≈ 50 个块、含图片/列表/标题）MUST 在 **单次 < 5 ms** 完成；对极端长文（1000 个块）MUST < 50 ms。抽取 MUST 为**纯同步、无 I/O**（不读媒体文件、不查库），仅遍历内存中的文档树。

**度量口径**：上述阈值的来源是「中端真机」（典型中端手机 CPU）上的目标预算；但抽取是纯 CPU、无 I/O 的内存遍历，与设备 I/O / 渲染无关，故其性能可由 `flutter test` 的 `*_bench_test.dart` 在**开发/CI 主机的 Dart VM** 上度量并作为唯一可执行的验证门槛。鉴于开发/CI 主机 CPU 通常**强于**中端真机，主机 bench 通过即可视为真机预算达标（保守门槛）；同一阈值表（5 ms / 50 ms）同时作为主机 bench 的断言上限。若将来主机算力与目标真机差距过大需折算，再在本 NF 与 bench 中补换算系数。

### NF2 · 编辑器与只读渲染器对同一 JSON 渲染一致性
对 R5 块清单中的每一种块，**编辑态（AppFlowy Editor）** 与 **只读渲染器** 对**同一份 `content_json`** MUST 产出**语义一致**的呈现：块的种类、顺序、层级（嵌套）、文本内容、图片引用目标、行内样式（粗/斜/下划线/删除线/链接/行内代码）MUST 完全一致；仅允许「可编辑光标/选区/占位提示」这类编辑专属装饰存在差异。自定义块（位置/天气）两端 MUST 呈现相同的结构化值。

## 选档与专项维度逐维表态

档位：**标准档**（命中专项维度「性能」「多端兼容」，且跨「编辑器/只读渲染器/抽取器/导出器」四个消费方 → 含 NF、verification.md、文件头文档状态、README 索引）。下表对 5 个专项维度逐一显式表态（任一为「是」即升标准档，标准档须 ≥1 个「是」）：

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 本契约只约定 `content_json` 结构与 `media.id` 引用键，不碰加解密/密钥/敏感数据（媒体加密归 media-storage）。 |
| 权限 | 否 | 纯内存数据结构与抽取/渲染逻辑，不涉及系统权限、相册/文件访问授权（选图链路另立 spec）。 |
| 无障碍 | 否 | 本期只定义 JSON 契约与纯文本抽取，块的可视/无障碍呈现归编辑页 UI spec（待设计稿），本 spec 不含可交互 UI。 |
| 性能 | **是** | NF1 对 `content_plain` 抽取设硬阈值（50 块 < 5 ms、1000 块 < 50 ms、纯同步无 I/O），需 bench 度量。 |
| 多端兼容 | **是** | NF1 阈值以中端真机为预算口径、NF2 要求编辑态与只读态对同一 JSON 跨形态语义一致，须保证 iOS/Android 两端渲染契约一致。 |

> 结论与已选档位自洽：性能、多端兼容命中「是」，符合标准档「须 ≥1 个『是』」。
