---
作者：@Ray
创建日期：2026-05-23
---

# 设计：editor-research

## 技术决策

### D1 · A demo 边界
- **背景：** 不能让 demo 自己也变成大项目；只验证「日常体验三件事」。
- **选择：** A demo 用 AppFlowy Editor 最新稳定版，仅做一个全屏编辑区 + 一个 AppBar Button 触发「插入本地图片」。为避免引入相册权限，**需在运行时将 `assets/editor/demo_image.png` 释放到应用临时目录**，以提供真实的本地绝对路径（`file://`）。不接相册、不接相机、不接 JSON 持久化（demo 关闭即丢）。
- **理由：** 避开权限申请、避开存储集成、专注于编辑器内能力；同时满足编辑器对真实文件路径的要求。
- **代价：** 不模拟真实选图流程；但选图体验本就由 Flutter 侧统一处理（v6 4.2），不影响选型判定。

### D2 · B demo 边界
- **背景：** WebView 集成涉及本地 HTML 打包、JS 桥、键盘联动；demo 不做工业级。
- **选择：**
  - 用 `webview_flutter` 加载 `assets/` 下打包的 `editor.html`（内嵌 TipTap + 必要 JS，不联网）；
  - 桥接最小：Flutter → WebView `insertImage(base64)`、WebView → Flutter `onContentChanged(json)`；
  - 图片插入：点 Flutter AppBar Button → 考虑到 WebView 加载本地文件常遇 CORS 跨域拦截，**优先采用在 Flutter 端将临时目录图片读取为 Base64 字符串，通过桥接直接注入 WebView 渲染**。
- **理由：** 离线 HTML 是必须项（v6 4.2）；桥接两个方向是 B 体验的核心；Base64 注入规避了最易卡壳的跨域权限黑盒。
- **代价：** assets 打包 TipTap bundle 需要前端构建步骤；Base64 传输稍耗内存，但在 Demo 阶段完全可接受。

### D3 · 评测设备覆盖
- iOS：iPhone 11 / 13 任一（真机优先；模拟器中文输入法不可靠，禁用）。
- Android：中端机型（如 Pixel 4 / 红米 Note 12 / OPPO A 系列），真机优先。
- 每个 demo × 两个平台 = 4 套数据点。

### D4 · 拍板时机与归档
- 时间盒：本 spec 起始日起 7 自然日内出结论。
- 即使到期数据缺失也必须拍板（@Ray），缺失部分在结论中标注「待补」。
- 出结论后本 spec 归档到 `specs/archive/2026-XX-XX-editor-research/`；归档前在 `tasks.md` 末尾写一节「选型结论」记录 winner / 数据 / 取舍。

## 文件变更

- `pubspec.yaml`                              修改（添加 `appflowy_editor`、`webview_flutter`）
- `assets/editor/`                            新建（B demo 的 HTML / JS / CSS 打包产物）
- `assets/editor/demo_image.png`              新建（预置图，A/B 共用）
- `lib/demo/editor_appflowy_demo.dart`        新建（A demo widget）
- `lib/demo/editor_webview_tiptap_demo.dart`  新建（B demo widget）
- `lib/demo/editor_bridge.dart`               新建（B 用的最小桥接）
- `lib/demo/demo_entry.dart`                  修改（追加两个 DemoEntry）

## 已知风险

- **AppFlowy Editor API 演进**：版本间不稳定；预研期锁版本。
- **TipTap bundle 体积**：assets 加几百 KB～几 MB；MVP 可接受，正式集成时考虑用 deferred component / on-demand。
- **WebView 中文输入法**：Android 上历史有 IME 输入框聚焦问题；T4 真机评测必须覆盖。
- **预置 demo 图分辨率**：太小看不出缩放/混排；用 1500×1000 量级 JPEG 作为基线。
- **WebView CORS 与本地加载安全限制**：若直接引用本地绝对路径图片可能被 Web 浏览器内核同源策略阻拦，已通过首选 Base64 注入方案降低该风险。
