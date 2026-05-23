---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# app-scaffold（应用壳 + Demo 框架）

## 背景

仓库目前只有 `docs/`，没有 Flutter 项目本体；所有后续 spec 都假设 `lib/` 目录结构与 `pubspec.yaml` 存在。同时设计稿尚未到位，需要一种「模块化 Demo 页」的开发手段：每个基础层里程碑（M1-M6）完工后挂一个调试入口到 Debug Home，在真机上独立验证能力，不必等正式 UI。本里程碑负责把这两件事一次性立起来——应用壳 + Demo 注册框架，作为后续所有 spec 的前置依赖。

## 范围外

- 任何业务能力（密钥、数据层、媒体、备份）——属各自里程碑。
- 正式产品 UI（时间线、设置页等）——待设计稿。
- 状态管理库（Provider / Riverpod / BLoC）——本期不预设；按需在后续 spec 引入。
- 多语言 / 主题切换——后续按需另立 spec。
- CI / 自动化构建配置——本期只确保本地 `flutter build` 通过。

## 功能需求

### R1 · Flutter 项目初始化
系统 MUST 用 `flutter create` 创建标准 Flutter 项目，含 `lib/`、`ios/`、`android/`、`test/`、`pubspec.yaml` 与 `.gitignore`。
- 前提：仓库根目录目前只有 `docs/` 与 `specs/`
- 操作：执行项目初始化
- 结果：上述目录与文件存在，且 `flutter doctor` 在本机不抛错

### R2 · 模块化目录结构
`lib/` 下 MUST 按基础模块划分子目录（与 spec 一一对应），便于「可改文件白名单」的精准约束。约定结构：
```
lib/
  main.dart
  app.dart                  ← 顶层 MaterialApp / 路由
  security/                 ← M1 key-management
  data/                     ← M2 data-layer
  media/                    ← M3 media-storage
  drafts/                   ← M4 auto-save-draft
  thumbnails/               ← M5 thumbnail-cache
  backup/                   ← M6 backup-full-snapshot
  demo/                     ← M0 demo 框架 + 各模块的 demo 页
  ui/                       ← 待设计稿到位后填充
test/                       ← 镜像 lib 结构
```

- 前提：项目壳已创建
- 操作：建立上述目录（可放 `.gitkeep` 占位）
- 结果：目录全部存在；空目录不影响构建

### R3 · 主入口与基础主题
系统 MUST 提供 `main.dart` 启动 `MaterialApp`，使用 Material 3；启动后首页为 Debug Home（R4）。
- 前提：项目已构建
- 操作：iOS / Android 启动 App
- 结果：屏幕显示 Debug Home（不是 Flutter 默认 counter demo）

### R4 · Debug Home 列表页
系统 MUST 在 Debug Home 渲染一个滚动列表，每行为一个 Demo 入口（`DemoEntry { title, subtitle?, builder }`）；点击进入对应 demo widget；从 demo 返回回到 Debug Home。
- 前提：至少注册一个示例 demo（见 R5）
- 操作：点击列表项
- 结果：进入 demo 页；back 返回列表

### R5 · Demo 注册框架
系统 MUST 提供静态 `demos` 列表（`List<DemoEntry>`），后续每个里程碑通过**追加一行**注册自己的 demo，不修改其他注册项；MUST 提供一个示例 demo「Hello Demo」验证框架可用。
- 前提：框架已实现
- 操作：在 demo 注册列表追加 `DemoEntry(...)`
- 结果：Debug Home 自动多出一行；无需改 Debug Home 页面代码

### R6 · 跨平台 debug 构建通过
项目 MUST 在 iOS 与 Android debug 构建通过。
- 前提：本地装好 Xcode + Android SDK
- 操作：执行构建命令
- 结果：`flutter build apk --debug` 与 `flutter build ios --debug --no-codesign` 均退出码 0

## 非功能需求

### NF1 · 最低系统版本
iOS deployment target MUST = 13.0（与 key-management NF3 对齐）；Android `minSdkVersion` MUST ≥ 26（Android 8.0；Keystore 在 8+ 上更稳定）。

### NF2 · 启动到 Debug Home < 2s（debug build）
冷启动（杀进程）到 Debug Home 可交互 MUST < 2s（debug 构建、中端真机）。

### NF3 · 多端一致
SHALL 在 iOS 13+ 与 Android 8+ 真机各启动一次确认 Debug Home 渲染正确。

### NF4 · 目录可扩展
新增一个基础模块的 demo 入口 MUST 只动 demo 注册列表 + 新 demo 文件两处，不动 Debug Home 页面代码。
