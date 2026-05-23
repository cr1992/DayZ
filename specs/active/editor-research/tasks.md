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

- [ ] T1 · 添加依赖 + 预置 demo 图

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
日期：—
自动：—
人工：—（无）
```

-----

- [ ] T2 · A 方案最小 demo（AppFlowy Editor）

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
日期：—
自动：—（无）
人工：—（核查人 @Ray）
```

-----

- [ ] T3 · B 方案最小 demo（WebView + TipTap）

**依赖：** T1 ｜ **关联需求：** R2 ｜ **依据设计：** D2 ｜ **可改文件：** `lib/demo/editor_webview_tiptap_demo.dart`, `lib/demo/editor_bridge.dart`, `lib/demo/demo_entry.dart`, `assets/editor/editor.html`, `assets/editor/editor.js`（可合并），`assets/editor/editor.css`（可合并）

### 背景
WebView 加载本地打包的 `editor.html`（含 TipTap），最小桥接：Flutter → `insertImage(base64)`、WebView → `onContentChanged(json)`。为规避本地 `file://` 图片在 WebView 中可能由于同源策略（CORS）被拦截的风险，采用 Flutter 侧将临时图片文件读取为 Base64 编码，并通过 JS 桥注入给 WebView 的机制进行渲染。

### 实施
1. 在 `assets/editor/` 目录下初始化极简 npm/Vite 环境，打包出内含 TipTap 的单文件 `editor.html`（记录构建命令）
2. 实现 `EditorWebviewTiptapDemo` widget：加载 assets、注入 JS 通道
3. Bridge：`editor_bridge.dart` 封装两个方向方法。**为规避 WebView 跨域，图片插入采用：Flutter 读本地预置图片转 Base64 → 调用 WebView `insertImage(base64)`**
4. 注册到 demos 列表
5. iOS / Android 真机能跑起来

### 验收标准（做完即止）
- 加载 < 1s（人工目测）
- 四步可演示（人工 @Ray）
- 桥接两个方向均工作（控制台可看到 onContentChanged JSON 输出）

### 验收方式
- 人工（@Ray）：iOS + Android 真机各跑一遍，录屏存档；控制台 paste onContentChanged 输出片段到验收记录

### 验收记录
```
日期：—
自动：—（无）
人工：—（核查人 @Ray）
```

-----

- [ ] T4 · A 实测三件事

**依赖：** T2 ｜ **关联需求：** R3, NF1 ｜ **依据设计：** D3 ｜ **可改文件：** 本 tasks.md（在「验收记录」中填入数据）

### 背景
按 D3 的设备覆盖（iOS 真机 + Android 真机）跑 R3 的三件事；每件事用一句话评级（好 / 可用 / 明显不足）+ 现象描述。

### 实施
1. iOS 真机：① 拖图（拖入 / 拖动位置）；② 缩放（手势捏合 / 把手拖拽）；③ 中文输入（拼音连续 30 字 + 标点）
2. Android 真机：同上
3. 在本任务「验收记录」表格记录评级 + 现象
4. 若 ① 或 ② 为「明显不足」，在记录中标注「触发 R4 一票否决」

### 验收标准（做完即止）
- 4 套数据点（2 设备 × 2 维度? 实际为 2 设备各 3 件事 = 6 项）已记录（人工）
- 若触发 R4 一票否决，已标注（人工）

### 验收方式
- 人工（@Ray）

### 验收记录
```
日期：—
A·iOS：①— ②— ③—
A·Android：①— ②— ③—
是否触发一票否决：—
核查人：@Ray
```

-----

- [ ] T5 · B 实测三件事

**依赖：** T3 ｜ **关联需求：** R3, NF1 ｜ **依据设计：** D3 ｜ **可改文件：** 本 tasks.md（在「验收记录」中填入数据）

### 背景
同 T4，对 B 跑一遍。

### 实施
1. iOS 真机 + Android 真机各跑 ①②③
2. 在本任务「验收记录」表格记录评级 + 现象
3. 特别关注 Android WebView 中文 IME（D 已知风险）

### 验收标准（做完即止）
- 6 项已记录（人工）

### 验收方式
- 人工（@Ray）

### 验收记录
```
日期：—
B·iOS：①— ②— ③—
B·Android：①— ②— ③—
WebView IME 备注：—
核查人：@Ray
```

-----

- [ ] T6 · 出选型结论 + 落档三处

**依赖：** T4, T5 ｜ **关联需求：** R4, R5 ｜ **依据设计：** D4 ｜ **可改文件：** 本 tasks.md（末尾追加结论块）, `specs/README.md`, `docs/日记App技术方案+v6.md`

### 背景
按 R4 判定 + R5 落档。即使时间盒到期、数据不全也必须拍板，缺失项在结论里标注。

### 实施
1. 综合 T4 / T5 数据出 winner
2. 在本 tasks.md 末尾追加 `## 选型结论` 节（含 winner、关键证据、对后续 spec 的影响）
3. 在 `specs/README.md` 顶部「编辑器选型」一行写入结论
4. 在 `docs/日记App技术方案+v6.md` 第 4 节末尾追加「v0.7 选型补丁：选定 X」段（追加不修改）
5. 把本里程碑标为「已完成」，从 README「进行中」移入「已归档」

### 验收标准（做完即止）
- 三处落档全部完成（人工）
- 结论含 winner + 关键证据 + 后续 spec 影响（人工）

### 验收方式
- 人工（@Ray）

### 验收记录
```
日期：—
选定方案：—（A / B）
关键证据：—
后续 spec 影响：—
落档三处：— / — / —
核查人：@Ray
```

-----

## 选型结论
（T6 完成后填入）
