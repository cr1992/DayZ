---
作者：@Ray
创建日期：2026-05-29
---

# 设计：assets-management

## 技术决策

### D1 · 资源引用生成方案 - flutter_gen
- **背景：** 避免硬编码字符串资源路径（拼写错、重构静态分析查不到）；依据 `docs/design/07` 第 1 节。
- **选择：** 用 **`flutter_gen`**（`flutter_gen_runner` dev 依赖 + `build_runner`）自动生成 `lib/gen/assets.gen.dart`，代码用 `Assets.images.xxx` 强类型引用。
- **理由：** 与项目已有的 `build_runner` 工作流（data-layer 的 drift codegen）集成好，无需引入额外工具链；编译期类型检查 + IDE 补全。
- **代价：** 需配置 `flutter_gen.yaml` 并运行代码生成；与 drift codegen 共用 `build_runner`，注意生成顺序无冲突（输出文件路径不同，互不干扰）。

### D2 · 目录结构规范
- **背景：** `docs/design/07` 第 2 节规定统一 `assets/` 分类目录。
- **选择：** 建立 `assets/images/`、`assets/icons/`、`assets/fonts/` 作为基线分类；`editor/`、`lotties/` 等按需扩展。多倍率图（`2.0x/`、`3.0x/`）仅大型背景图/插画使用，普通图标走矢量（SVG / Icon Font），避免多套位图膨胀包体积。
- **理由：** 与 design 07 一致，结构清晰、便于 `flutter_gen` 按目录归类生成。
- **代价：** 需在 `pubspec.yaml` 的 `flutter.assets` 段声明目录；新增子目录类别时同步声明。

## 文件变更
- `pubspec.yaml`            修改（添加 `flutter_gen_runner` dev 依赖；`flutter.assets` 声明 `assets/` 子目录）
- `flutter_gen.yaml`        新建（flutter_gen 生成配置：output 指向 `lib/gen/`）
- `assets/images/`          新建（目录，含 `.gitkeep` 占位）
- `assets/icons/`           新建（目录，含 `.gitkeep` 占位）
- `assets/fonts/`           新建（目录，含 `.gitkeep` 占位）
- `lib/gen/assets.gen.dart` 生成产物（由 build_runner 产出，纳入版本库）

## 已知风险
- **空目录不被 git 跟踪**：`assets/*` 初期无资产，需放 `.gitkeep` 占位，否则目录在干净检出时丢失，`flutter_gen` 无目录可扫。
- **flutter_gen 对空目录的处理**：部分版本对完全空的 assets 目录会生成空类或告警；放一个占位资源或确保至少声明目录即可，T1 验证生成命令可跑通。
- **与 drift build_runner 共存**：两者都用 `build_runner`，`--delete-conflicting-outputs` 时确认互不删除对方产物（输出目录不同：drift 在 `lib/data/`，assets 在 `lib/gen/`）。
