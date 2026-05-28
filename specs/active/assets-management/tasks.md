---
作者：@Ray
创建日期：2026-05-29
---

# 任务列表：assets-management

## 依赖速览
> 以各任务 inline「依赖」字段为准。
T1 → T2

-----

- [ ] T1 · 添加 flutter_gen 依赖 + assets 目录 + 生成配置

**依赖：** 无 ｜ **关联需求：** R1, R2, R3 ｜ **依据设计：** D1, D2 ｜ **可改文件：** `pubspec.yaml`, `flutter_gen.yaml`, `assets/images/.gitkeep`, `assets/icons/.gitkeep`, `assets/fonts/.gitkeep`

### 背景
搭建类型安全静态资源引用的基础设施，依据 `docs/design/07`。原 data-layer 的 T15 即此，剥离至本 spec。

### 实施
1. `pubspec.yaml` 添加 `flutter_gen_runner`（dev 依赖，锁版本）；`flutter.assets` 段声明 `assets/images/`、`assets/icons/`、`assets/fonts/`
2. 根目录创建 `flutter_gen.yaml`，`output` 指向 `lib/gen/`
3. 创建 `assets/images/`、`assets/icons/`、`assets/fonts/` 目录，各放 `.gitkeep` 占位（保证空目录入库）
4. `flutter pub get`

### 验收标准（做完即止）
- 依赖解析通过、三个 assets 子目录存在（自动）
- `flutter_gen.yaml` 与 `pubspec.yaml` 的 assets 声明就位（自动 grep）

### 验收方式
- 自动：
  ```bash
  flutter pub get \
    && test -d assets/images && test -d assets/icons && test -d assets/fonts \
    && test -f flutter_gen.yaml \
    && grep -q 'flutter_gen_runner' pubspec.yaml
  ```

### 验收记录
```
日期：—
自动：—
人工：—（无）
```

-----

- [ ] T2 · 跑通生成，产出 assets.gen.dart

**依赖：** T1 ｜ **关联需求：** R1, R3 ｜ **依据设计：** D1 ｜ **可改文件：** `lib/gen/assets.gen.dart`（生成产物）, `assets/images/`（必要时放一张占位图供生成）

### 背景
执行代码生成，确认 `flutter_gen` 工具链可用、产物可复现，且与 data-layer 的 drift build_runner 共存无冲突。

### 实施
1. 必要时在 `assets/images/` 放一张占位资源（如 1×1 png），确保生成器有可扫内容
2. `dart run build_runner build --delete-conflicting-outputs`
3. 确认 `lib/gen/assets.gen.dart` 生成且含强类型引用类
4. 把生成产物纳入版本库（按项目约定，不 gitignore `lib/gen/assets.gen.dart`）

### 验收标准（做完即止）
- `lib/gen/assets.gen.dart` 成功生成，含对应类（自动）
- 重复执行生成命令幂等，无脏 diff（人工核查 @Ray）

### 验收方式
- 自动：
  ```bash
  dart run build_runner build --delete-conflicting-outputs && test -f lib/gen/assets.gen.dart
  ```
- 人工（@Ray）：连续两次生成后 `git diff lib/gen/assets.gen.dart` 无变化（幂等）

### 验收记录
```
日期：—
自动：—
人工：—（核查人 @Ray）
```
