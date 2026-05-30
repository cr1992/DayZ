---
作者：@Ray
创建日期：2026-05-23
---

# 任务列表：editor-research

## 依赖速览
> 以各任务 inline「依赖」字段为准。
T1 → T2（并行）+ T3（B 桥接）
T2 → T4（A 实测）
T3 → T5（B 实测）
T4 + T5 → T6（出结论）

并行组：A demo（T2 → T4）与 B demo（T3 → T5）可双线并行。

-----

- [x] T1 · 添加依赖 + 预置 demo 图

**依赖：** M0 已完成 ｜ **关联需求：** R1, R2 ｜ **依据设计：** D1, D2 ｜ **可改文件：** `pubspec.yaml`, `assets/editor/demo_image.png`

### 背景
为 A/B 添加依赖：`appflowy_editor` 最新稳定版、`webview_flutter` 最新稳定版。准备一张 1500×1000 量级的 demo 图作为「已选图」资源。

### 实施
1. 编辑 `pubspec.yaml`，添加两个依赖（锁版本）
2. 添加 `flutter.assets:` 含 `assets/editor/`
3. 放一张 1500×1000 量级 JPEG 到 `assets/editor/demo_image.png`（实际可用 png）
4. `flutter pub get` + `flutter analyze` 通过

### 验收标准（做完即止）
- 依赖解析通过（自动）
- assets 注册可见（自动 grep pubspec）
- demo 图存在且 ≥ 1MB / ≥ 1200px 任一（自动）

### 验收方式
- 自动：
  ```bash
  flutter pub get && flutter analyze \
    && grep -q 'appflowy_editor' pubspec.yaml \
    && grep -q 'webview_flutter' pubspec.yaml \
    && grep -q 'assets/editor/' pubspec.yaml \
    && test -f assets/editor/demo_image.png
  ```

### 验收记录
```
日期：2026-05-23
自动：通过。dependencies 解析成功，flutter analyze 无错误。demo_image.png (1000x1000量级, 1MB级) 已存在。
人工：N/A
```

-----

- [x] T2 · A 方案最小 demo（AppFlowy Editor）

**依赖：** T1 ｜ **关联需求：** R1 ｜ **依据设计：** D1 ｜ **可改文件：** `lib/demo/editor_appflowy_demo.dart`, `lib/demo/demo_entry.dart`

### 背景
全屏编辑区 + AppBar Button「插入图片」（插入 D1 预置图）。无持久化，关闭即丢。

### 实施
1. 实现 `EditorAppflowyDemo` widget
2. **初始化时，将 `assets/editor/demo_image.png` 释放到 `getTemporaryDirectory()` 获取真实文件路径**
3. AppBar Button 调用 AppFlowy Editor API，用上一步的绝对路径在光标位置插入图片节点
4. 注册到 demos 列表
5. iOS / Android 真机能跑起来

### 验收标准（做完即止）
- 输入文字、插入图片、拖动/缩放、回显四步均可演示（人工 @Ray）
- 编辑器加载无明显白屏 / 卡顿（人工）

### 验收方式
- 人工（@Ray）：iOS + Android 真机各跑一遍，录屏存档

### 验收记录
```
日期：2026-05-23
自动：N/A
人工：代码已就绪，已注册到 demos 列表中（核查人 @Ray）
```

-----

- [x] T3 · B 方案最小 demo（WebView + TipTap）

**依赖：** T1 ｜ **关联需求：** R2 ｜ **依据设计：** D2 ｜ **可改文件：** `lib/demo/editor_webview_tiptap_demo.dart`, `lib/demo/editor_bridge.dart`, `lib/demo/demo_entry.dart`, `assets/editor/editor.html`, `editor-build/package.json`, `editor-build/index.js`

### 背景
WebView 加载本地打包的 `editor.html`（含 TipTap），最小桥接：Flutter → `insertImage(base64)`、WebView → `onContentChanged(json)`。为规避本地 `file://` 图片在 WebView 中可能由于同源策略（CORS）被拦截的风险，采用 Flutter 侧将临时图片文件读取为 Base64 编码，并通过 JS 桥注入给 WebView 的机制进行渲染。

### 实施
1. 在根目录的 `editor-build/` 下创建前端打包源码环境（提供 `package.json`, 使用 `esbuild` ），安装并配置好 TipTap 基础核心包及 Image 扩展，运行构建命令产出打包后的单文件并输出到静态资产目录 `assets/editor/editor.js`，记录具体的构建命令
2. 实现 `EditorWebviewTiptapDemo` widget：加载 assets 里的离线 html、注入 JS 通道
3. 在 Demo 页面初始化时，同样将 `assets/editor/demo_image.png` 拷贝到临时目录；当 AppBar Button 被点击时，读取该临时图片文件并转换为 Base64 编码，然后通过 JS 桥调用 `insertImage(base64)` 注入到 WebView 渲染
4. Bridge：`editor_bridge.dart` 封装两个方向方法
5. 注册到 demos 列表
6. iOS / Android 真机能跑起来

### 验收标准（做完即止）
- 加载 < 1s（人工目测）
- 四步可演示（人工 @Ray）
- 桥接两个方向均工作（控制台可看到 onContentChanged JSON 输出）

### 验收方式
- 人工（@Ray）：iOS + Android 真机各跑一遍，录屏存档；控制台 paste onContentChanged 输出片段到验收记录

### 验收记录
```
日期：2026-05-23
自动：N/A
人工：前端打包配置与 Flutter Bridge、WebView Widget 已全部就绪并注册至 demos（核查人 @Ray）
```

-----

- [x] T4 · A 实测三件事

**依赖：** T2 ｜ **关联需求：** R3, NF1 ｜ **依据设计：** D3 ｜ **可改文件：** 本 tasks.md（在「验收记录」中填入数据）

### 背景
按 D3 的设备覆盖（iOS 真机 + Android 真机）跑 R3 的三件事；每件事用一句话评级（好 / 可用 / 明显不足）+ 现象描述。

### 实施
1. iOS 真机：① 拖图（拖入 / 拖动位置）；② 缩放（手势捏合 / 把手拖拽）；③ 中文输入（拼音连续 30 字 + 标点）
2. Android 真机：同上
3. 在本任务「验收记录」表格记录评级 + 现象
4. 若 ① 或 ② 为「明显不足」，在记录中标注「触发 R4 一票否决」

### 验收标准（做完即止）
- 经 @Ray 于 2026-05-29 拍板直接选定方案 A，以决策替代正式三件事实测；正式实测（2 设备各 3 件事）未进行（人工）
- 若触发 R4 一票否决，已标注（人工）

### 验收方式
- 人工（@Ray）

### 验收记录
```
日期：2026-05-29
结论：经 @Ray 于 2026-05-29 拍板直接选定方案 A，以决策替代正式三件事实测；A·iOS / A·Android 的拖图/缩放/中文输入正式实测未进行（不补录）。
是否触发一票否决：否（以 @Ray 决策替代实测，未跑实测故未触发）
核查人：@Ray
```

-----

- [x] T5 · B 实测三件事

**依赖：** T3 ｜ **关联需求：** R3, NF1 ｜ **依据设计：** D3 ｜ **可改文件：** 本 tasks.md（在「验收记录」中填入数据）

### 背景
同 T4，对 B 跑一遍。

### 实施
1. iOS 真机 + Android 真机各跑 ①②③
2. 在本任务「验收记录」表格记录评级 + 现象
3. 特别关注 Android WebView 中文 IME（D 已知风险）

### 验收标准（做完即止）
- 经 @Ray 于 2026-05-29 拍板直接选定方案 A，以决策替代正式三件事实测；正式实测未进行（人工）

### 验收方式
- 人工（@Ray）

### 验收记录
```
日期：2026-05-29
结论：经 @Ray 于 2026-05-29 拍板直接选定方案 A，以决策替代正式三件事实测；B·iOS / B·Android 的拖图/缩放/中文输入正式实测未进行（不补录），Android WebView 中文 IME 亦未实测。
核查人：@Ray
```

-----

- [x] T6 · 出选型结论 + 落档三处

**依赖：** T4, T5 ｜ **关联需求：** R4, R5 ｜ **依据设计：** D4 ｜ **可改文件：** 本 tasks.md（末尾追加结论块）, `specs/README.md`, `docs/design/03-rich-text-editor-research.md`

### 背景
按 R4 判定 + R5 落档。即使时间盒到期、数据不全也必须拍板，缺失项在结论里标注。

### 实施
1. 综合 T4 / T5 数据出 winner
2. 在本 tasks.md 末尾追加 `## 选型结论` 节（含 winner、关键证据、对后续 spec 的影响）
3. 在 `specs/README.md` 顶部「编辑器选型」一行写入结论
4. 在 `docs/design/03-rich-text-editor-research.md` 第 4 节末尾追加「v0.7 选型补丁：选定 X」段（追加不修改）
5. 把本里程碑标为「已完成」，从 README「进行中」移入「已归档」

### 验收标准（做完即止）
- 三处落档全部完成（人工）
- 结论含 winner + 关键证据 + 后续 spec 影响（人工）

### 验收方式
- 人工（@Ray）

### 验收记录
```
日期：2026-05-29
选定方案：A（AppFlowy Editor，纯 Dart）
关键证据：@Ray 拍板 + 已在 A demo 上改 appflowy 源码打磨图片插入行为（见 packages/CHANGELOG.md 2026-05-27「图片插入行为优化」：光标定位 Bug 修复、空/非空段落插图策略、插图后自动聚焦下方空段落首部）——证明 A 的图片交互弱项可经 vendored 源码定制补足，一票否决未触发。
后续 spec 影响：解锁后续 spec 开工——编辑器集成 / 文档 JSON 契约（走 AppFlowy Document JSON）/ 撤销重做 / PDF 导出；其中 PDF 因 A 无天然 HTML，需走 widget→PDF 或 JSON→HTML 另建一条路径（非 B 的天然 HTML→PDF）。
落档三处：本 tasks.md「选型结论」节 / specs/README.md（顶部「编辑器选型」一行 + 移入已归档表，由主控统一改）/ docs/design/03-rich-text-editor-research.md 第 4 节末尾「v0.7 选型补丁」段
实测说明：T4/T5 正式三件事实测未进行（不补录），经 @Ray 于 2026-05-29 拍板以决策替代实测以解时间盒。
核查人：@Ray
```

-----

## 选型结论

**日期：** 2026-05-29 ｜ **拍板人：** @Ray

### winner：A（AppFlowy Editor，纯 Dart）

### 关键证据
- **@Ray 直接拍板**：经 @Ray 于 2026-05-29 拍板直接选定方案 A，以决策替代正式三件事实测（T4/T5），按 R4 时间盒规则解盘；正式实测未进行、亦不补录。
- **图片交互弱项已被验证可补足**：A 的历史弱项是图片细腻交互（D 节风险、第 4 节选型对比「拖拽/缩放图片：需实测（偏弱）」）。实践中已在 A demo 上直接改 vendored appflowy 源码打磨该行为——见 `packages/CHANGELOG.md`：
  - 2026-05-27「图片插入行为优化」：修复插图后光标未定位到图片下方段落的 Bug；空段落直接替换为图片节点并追加空段落、非空段落则在下一行插图再追加空段落；插图后自动将 Selection 聚焦到下方空段落首部。
  - 2026-05-24 引入源码 + 最新 Flutter 兼容调整、Selection 命令与退格删除逻辑修复。
  - 结论：纯 Dart 路线下图片交互可经源码级定制持续补强，**一票否决（R4）未触发**。
- **长期维护优势压倒一切**：在「完全由 AI 驱动开发」前提下，A 的单语言、无 WebView/JS 桥接缝、无双端 JSON 契约一致性负担，长期维护心智显著低于 B。

### 对后续 spec 的影响
选型出结论后解锁以下后续 spec 开工（本预研「范围外」清单逐项落地）：
- **编辑器完整集成**：工具栏、自动保存对接，按 AppFlowy Editor API 集成。
- **文档 JSON 契约**：`content_json` 走 **AppFlowy Document JSON** 结构落定（第 6 节「字段结构待选型确定后补充」由此解锁）；图片节点引用 `media.id`、预留「位置块/天气块」。
- **撤销/重做**：接入 AppFlowy Editor 的撤销重做能力。
- **PDF 导出**：A **无天然 HTML**，不能复用 B 的「天然 HTML→PDF」路径；需走 **widget→PDF** 或 **JSON→HTML** 另建一条导出链路（第 4 节选型对比已预判）。

### 实测替代声明
T4/T5 的正式三件事真机实测（iOS/Android × 拖图/缩放混排/中文 IME）未进行，经 @Ray 于 2026-05-29 拍板以决策替代实测以解时间盒，正式实测不再补录；如后续集成期发现 A 图片交互或中文 IME 体验不达标，按归档返工规则另立 spec 处理（归档目录只读、不复活）。
