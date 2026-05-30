---
作者：@Ray
创建日期：2026-05-29
---

# 设计：assets-management

## 技术决策

### D1 · 资源引用生成方案 - flutter_gen
- **背景：** 避免硬编码字符串资源路径（拼写错、重构静态分析查不到）；依据 `docs/design/07` 第 1 节。
- **选择：** 用 **`flutter_gen`**（`flutter_gen_runner` dev 依赖 + `build_runner`）自动生成 `lib/gen/assets.gen.dart`，代码用 `Assets.images.xxx` 强类型引用。
- **理由：** `flutter_gen` 是 Flutter 生态主流的类型安全资源方案，编译期类型检查 + IDE 补全；走 `build_runner` 代码生成机制。`build_runner` 为本仓库共享构建基建，本 spec 引入/复用其 codegen（builder = `flutter_gen_runner`，产物在 `lib/gen/`），与 data-layer 的 drift builder（产物在 schema 旁）并存：builder 不同、输出路径不同，互不干扰，谁先落地即由其引入 `build_runner` dev 依赖、另一方复用。
- **代价：** 需新增 `build_runner` 与 `flutter_gen_runner` dev 依赖、配置 `flutter_gen.yaml` 并运行代码生成；`build_runner` 与 data-layer 共用时须确认输出目录隔离（assets 在 `lib/gen/`）、`--delete-conflicting-outputs` 不误删对方产物。

### D2 · 目录结构规范
- **背景：** `docs/design/07` 第 2 节规定统一 `assets/` 分类目录。仓库已存在 `assets/editor/`（`demo_image.png`、`editor.html`、`editor.js`，已被 git 跟踪，`pubspec.yaml` 已声明 `assets/editor/`），本 spec 在其上扩充基线分类目录约定，而非从零搭建。
- **选择：** 新建 `assets/images/`、`assets/icons/`、`assets/fonts/` 作为基线分类（各放 `.gitkeep` 占位入库）；已有的 `assets/editor/` 保持不动并纳入约定，`lotties/` 等其余类别按需扩展。多倍率图（`2.0x/`、`3.0x/`）仅大型背景图/插画使用，普通图标走矢量（SVG / Icon Font），避免多套位图膨胀包体积。
- **理由：** 与 design 07 一致，结构清晰、便于 `flutter_gen` 按目录归类生成；沿用已存在的 `assets/editor/`，避免重复造目录或迁移既有资产。
- **代价：** 需在 `pubspec.yaml` 的 `flutter.assets` 段补声明新增子目录（`assets/editor/` 已声明）；新增子目录类别时同步声明。

### D3 · 共享 demo 图规范路径（单一来源）
- **背景：** 多个 spec 引用同一张 demo 图，历史上出现三处路径写法不一致；需一处定锚。
- **选择：** 规范化共享 demo 图路径为 `assets/editor/demo_image.png`（已存在并被 git 跟踪，`pubspec.yaml` 已声明 `assets/editor/`），本 spec 作为该路径的单一来源，其它 spec 引用一律指向此路径。
- **理由：** 该文件已实际存在于 `assets/editor/`，就地定锚成本最低、不产生迁移；集中一处声明可消除跨 spec 路径漂移。
- **代价：** demo 图归属于 `editor/` 类别而非 `images/`，与「业务图片入 images/」的直觉略有出入；但其确为编辑器演示资产，归 `editor/` 合理，可接受。

## 文件变更
- `pubspec.yaml`            修改（添加 `build_runner` + `flutter_gen_runner` dev 依赖；`flutter.assets` 补声明 `assets/` 子目录，`assets/editor/` 已声明）
- `flutter_gen.yaml`        新建（flutter_gen 生成配置：output 指向 `lib/gen/`）
- `assets/images/.gitkeep`  新建（占位，保证空目录入库、被 git 跟踪）
- `assets/icons/.gitkeep`   新建（占位，保证空目录入库、被 git 跟踪）
- `assets/fonts/.gitkeep`   新建（占位，保证空目录入库、被 git 跟踪）
- `lib/gen/assets.gen.dart` 生成产物（由 build_runner 产出，纳入版本库，MUST NOT gitignore）

## 已知风险
- **空目录不被 git 跟踪**：`assets/images|icons|fonts` 初期无资产，需放 `.gitkeep` 占位并入库，否则目录在干净检出时丢失、`flutter_gen` 无目录可扫；验收须核对 `.gitkeep` 已被 git 跟踪（`git ls-files`），仅本地存在不够。
- **flutter_gen 对空目录的处理**：部分版本对完全空的 assets 目录会生成空类或告警；放一个占位资源或确保至少声明目录即可，T2 验证生成命令可跑通（仓库已有 `assets/editor/demo_image.png` 等实际资产，生成器有可扫内容）。
- **build_runner 为共享构建基建**：`build_runner` 是本仓库共享的 codegen 基建，本 spec 引入/复用其 codegen（builder = `flutter_gen_runner`），与 data-layer 的 drift builder 并存；两者 builder 不同、输出目录不同（assets 在 `lib/gen/`），互不冲突。共用时须确认输出目录隔离、`--delete-conflicting-outputs` 不误删对方产物。若 data-layer 先落地已带入 `build_runner` dev 依赖，本 spec 复用即可；否则由本 spec 带入。
