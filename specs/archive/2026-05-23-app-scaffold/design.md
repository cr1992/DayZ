---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# 设计：app-scaffold

## 技术决策

### D1 · 项目名与 bundle id
- **背景：** 创建 Flutter 项目需定项目名 / bundle id；改起来麻烦，先定好。
- **选项：** `dayz` / `dayz_diary` / `diary_app`。
- **选择：** Flutter 项目名 `dayz`；iOS bundle id `com.dayz`；Android applicationId `com.dayz`。
- **理由：** 走最短路径——Flutter `--org com --project-name dayz` 即可拼出 `com.dayz`，无需后期手工改 bundle id。
- **代价：** 项目名比较简短，无歧义；若将来被 App Store 拒（同 id 冲突）再统一替换。

### D2 · 目录划分：按功能模块而非按层
- **背景：** Flutter 社区有「按层（widgets/screens/services）」和「按功能」两派。
- **选项：** 按层 / 按功能。
- **选择：** 按功能模块（`lib/security/`、`lib/data/` 等），与 spec 里程碑一一对应。
- **理由：** spec 的「可改文件」白名单直接对应目录；多个 spec 并行开发时碰撞最少；模块边界清晰。
- **代价：** 后期 UI 多了需要在 `lib/ui/` 下做二级拆分；可接受。

### D3 · Debug Home 与 Demo 注册框架
- **背景：** 后续每个里程碑都要插自己的 demo，要保证「新增一个 demo 不动 Debug Home 代码」。
- **选项：** 复杂路由库（go_router）/ 简单静态注册 + `Navigator.push` / Drawer 菜单。
- **选择：** 静态 `List<DemoEntry>` + `Navigator.push(MaterialPageRoute)`。
- **理由：** MVP 阶段 demo 数 ≤ 10，简单注册足够；零依赖；新增一行不影响其他人。
- **代价：** demo 多到几十个时 ListView 长；那时再拆分组（按里程碑分 group），现在不预设。

### D4 · 不引入状态管理库
- **背景：** 基础层多为同步 / 异步函数调用，不需要全局响应式状态。
- **选项：** 立即引入 Provider/Riverpod / 等到需要时再引 / 一直不引。
- **选择：** 本里程碑不引入；任何后续里程碑若需要全局状态，自己决定并立即落入新 spec。
- **理由：** 不预设；避免「为了对称而引入」。
- **代价：** 后期补 retrofit 一些状态时可能需要重构；可接受。

### D5 · iOS 最低 13.0、Android minSdk 26
- **背景：** 与 key-management NF3 对齐；Android Keystore 在 8.0+ 更稳定。
- **选项：** iOS 12 / 13 / 14；Android minSdk 21 / 24 / 26。
- **选择：** iOS 13、Android minSdk 26。
- **理由：** 覆盖 95%+ 在用设备；规避 Android 7 及更旧的 Keystore 已知 bug；规避 iOS 12 SwiftUI 限制（虽然本期不用 SwiftUI）。
- **代价：** 极少数老旧设备无法安装；可接受。

### D6 · Flutter / Dart 工具链版本
- **背景：** 项目无历史包袱，关键依赖（Drift、SQLCipher、webview_flutter）在新版本上有持续修复。
- **选项：** 钉死某个 LTS-like 版本 / 跟随 stable 渠道最新 / 走 beta。
- **选择：** **跟随 Flutter stable 渠道最新稳定版**；T1 执行 `flutter create` 前先 `flutter upgrade`。
- **理由：** 早期项目，跟新代价低、收益高；spec 后续若因版本升级需要调参（如 Argon2id 调参），同步更新对应 design 即可。
- **代价：** stable 渠道偶有 regression；通过 `pubspec.yaml` 不钉死过紧的 SDK 上限，遇到问题可锁版本。同步约束：第三方包优先选近 6 个月内有 release 的活跃维护包（详见 AGENTS.md 第 10 条）。

## 架构

```mermaid
graph TD
  Main[main.dart] --> App[app.dart<br/>MaterialApp + Theme]
  App --> DH[demo/debug_home.dart]
  DH --> List[ListView 渲染 demos]
  List --> Entry[DemoEntry { title, builder }]
  Entry --> Push[Navigator.push 进入]
  Push --> DemoWidget[各模块 demo widget]

  Demos[demo/demos.dart<br/>List<DemoEntry>] -.注册.-> List
  M1[lib/security/demo.dart] -.追加一行.-> Demos
  M2[lib/data/demo.dart] -.追加一行.-> Demos
  M3[lib/media/demo.dart] -.追加一行.-> Demos
  M4[lib/drafts/demo.dart] -.追加一行.-> Demos
  M5[lib/thumbnails/demo.dart] -.追加一行.-> Demos
  M6[lib/backup/demo.dart] -.追加一行.-> Demos
```

## 文件变更

- `pubspec.yaml`                    新建（`flutter create` 产出）
- `lib/main.dart`                   新建
- `lib/app.dart`                    新建
- `lib/security/.gitkeep`           新建（占位，M1 填充）
- `lib/data/.gitkeep`               新建
- `lib/media/.gitkeep`              新建
- `lib/drafts/.gitkeep`             新建
- `lib/thumbnails/.gitkeep`         新建
- `lib/backup/.gitkeep`             新建
- `lib/ui/.gitkeep`                 新建
- `lib/demo/debug_home.dart`        新建
- `lib/demo/demo_entry.dart`        新建（DemoEntry 模型 + demos 列表）
- `lib/demo/hello_demo.dart`        新建（示例 demo 验证框架）
- `test/demo/debug_home_test.dart`  新建（widget test）
- `ios/Runner.xcodeproj/...`        修改（最低版本 13.0、bundle id）
- `android/app/build.gradle`        修改（minSdk 26、applicationId）
- `.gitignore`                      新建（`flutter create` 产出）

## 已知风险

- **iOS Pod 安装** 在某些 macOS 版本第一次会卡——T1 提供 fallback：`cd ios && pod install --repo-update`。
- **Android 26 minSdk** 排除少量老旧设备；将来如果用户反馈，可下调到 21，但 Keystore 兼容代价由 key-management 承担。
- **静态 demos 列表 顺序依赖文件加载**：用 `const`/`final` 列表可避免；如改 `late` 需注意初始化顺序。
