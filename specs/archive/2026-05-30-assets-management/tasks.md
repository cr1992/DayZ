---
作者：@Ray
创建日期：2026-05-29
---

# 任务列表：assets-management

## 依赖速览
> 以各任务 inline「同 spec 依赖」字段为准；跨 spec 依赖以 README「依赖」列为准（本 spec 跨 spec 依赖＝无）。
T1 → T2

-----

- [x] T1 · 添加 flutter_gen 依赖 + assets 目录 + 生成配置

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R1, R2, R3, R4 ｜ **依据设计：** D1, D2, D3 ｜ **可改文件：** `pubspec.yaml`, `flutter_gen.yaml`, `assets/images/.gitkeep`, `assets/icons/.gitkeep`, `assets/fonts/.gitkeep`

### 背景
搭建类型安全静态资源引用的基础设施，依据 `docs/design/07`。原 data-layer 的 T15 即此，剥离至本 spec。仓库已存在 `assets/editor/`（含共享 demo 图 `assets/editor/demo_image.png`，已被 git 跟踪、`pubspec.yaml` 已声明），本任务在其上扩充 `images/`、`icons/`、`fonts/` 基线分类，并落锚 R4 的共享 demo 图规范路径。

### 实施
1. `pubspec.yaml` 添加 `flutter_gen_runner` **与 `build_runner`**（均 dev 依赖，锁版本；`build_runner` 为共享构建基建，本 spec 引入/复用其 codegen，与 data-layer 的 drift builder 并存——若 data-layer 已带入则复用，否则由本 spec带入，以保证可独立先行）；`flutter.assets` 段补声明 `assets/images/`、`assets/icons/`、`assets/fonts/`（`assets/editor/` 已声明，保持不动）
2. 根目录创建 `flutter_gen.yaml`，`output` 指向 `lib/gen/`
3. 创建 `assets/images/`、`assets/icons/`、`assets/fonts/` 目录，各放 `.gitkeep` 占位（保证空目录入库）
4. `git add` 三个 `.gitkeep`，使空目录被 git 跟踪
5. `flutter pub get`

### 验收标准（做完即止）
- `flutter pub get` 成功解析依赖（含新增 `flutter_gen_runner`/`build_runner` dev 依赖，否则 `pub get` 报缺失/版本冲突而 fail——以解析结果而非配置字符串验证依赖就位）（自动）
- `dart run build_runner build --delete-conflicting-outputs` 能跑通（exit 0），证明 `build_runner` + `flutter_gen_runner` builder 已被构建系统识别且配置（`flutter_gen.yaml`/`flutter.assets`）生效——这是「依赖与配置真的可用」的行为断言，取代原先 grep `pubspec.yaml` 里依赖字面量与 `flutter_gen.yaml` 文本（自动）
- 三个 assets 子目录存在且其 `.gitkeep` 已被 git 跟踪（已进版本库，非仅本地存在）（自动）
- 共享 demo 图规范路径 `assets/editor/demo_image.png` 存在且已被 git 跟踪（R4）（自动）

### 验收方式
- 自动：
  ```bash
  # pub get 成功 = 新增 dev 依赖确实可解析（缺/冲突则非 0 退出）；
  # build_runner build 成功 = 依赖 + flutter_gen 配置真的可用（builder 被识别、配置生效）
  flutter pub get \
    && test -d assets/images && test -d assets/icons && test -d assets/fonts \
    && git ls-files --error-unmatch assets/images/.gitkeep assets/icons/.gitkeep assets/fonts/.gitkeep \
    && test -f flutter_gen.yaml \
    && git ls-files --error-unmatch assets/editor/demo_image.png \
    && dart run build_runner build --delete-conflicting-outputs
  ```
  （`flutter pub get` 退出码断言依赖**可解析**、`build_runner build` 退出码断言 builder 与 `flutter_gen.yaml`/`flutter.assets` 配置**真的生效可运行**——两者均验行为，取代原先 grep `pubspec.yaml` 依赖字面量与 grep `flutter_gen.yaml` 文本的正向存在性检查。生成产物的强类型引用取值正确性由 T2 的 import 编译/行为测试进一步验证。）

### 验收记录
```
日期：2026-05-30
自动：自动验收命令执行通过，成功拉取依赖并跑通首次 build_runner。
人工：无
```

-----

- [x] T2 · 跑通生成，产出 assets.gen.dart

**同 spec 依赖：** T1 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R1, R3, R4 ｜ **依据设计：** D1, D3 ｜ **可改文件：** `lib/gen/assets.gen.dart`（生成产物）, `assets/images/`（必要时放一张占位图供生成）｜ **验收基建：** `test/assets/assets_gen_compile_test.dart`（import 生成产物的编译/行为测试，预批）

### 背景
执行代码生成，确认 `flutter_gen` 工具链可用、产物可复现且可编译。`build_runner` 为共享构建基建，本 spec 引入/复用其 codegen（builder = `flutter_gen_runner`），与 data-layer 的 drift builder 并存、输出目录隔离（assets 在 `lib/gen/`），互不冲突。仓库已存在 `assets/editor/demo_image.png` 等实际资产，生成器有可扫内容。

### 实施
1. 仓库已有 `assets/editor/demo_image.png` 可被扫描；若 `assets/images/` 仍需占位资源（如 1×1 png）以触发对应类生成，则补放一张
2. `dart run build_runner build --delete-conflicting-outputs`
3. 确认 `lib/gen/assets.gen.dart` 生成且含强类型引用类
4. 把生成产物纳入版本库（`git add lib/gen/assets.gen.dart`；确认未被 gitignore）
5. 写 `test/assets/assets_gen_compile_test.dart`：`import 'package:dayz/gen/assets.gen.dart'`（包名 `dayz`），断言生成的强类型引用解析到正确资源路径（如 `Assets.editor.demoImage.path == 'assets/editor/demo_image.png'`，对应 R4 规范路径 / R1 强类型引用）

### 验收标准（做完即止）
- `dart run build_runner build` 成功产出 `lib/gen/assets.gen.dart`（exit 0，R3 可复现）（自动）
- **生成产物可编译且行为正确**：`flutter test test/assets/assets_gen_compile_test.dart` 通过——该测试 import 生成的 `Assets` 类（若产物缺类/不可编译则编译失败、test fail），并断言 `Assets.editor.demoImage.path == 'assets/editor/demo_image.png'`（R1 强类型引用解析到 R4 规范路径；断言来源是生成产物的**运行期取值**，独立于 `pubspec.yaml`/`flutter_gen.yaml`配置文本）（自动）
- `lib/gen/assets.gen.dart` 已被 git 跟踪且未被 gitignore（R3 纳入版本库）（自动）
- 重复执行生成命令幂等，无脏 diff（人工核查 @Ray）

### 验收方式
- 自动：
  ```bash
  dart run build_runner build --delete-conflicting-outputs \
    && test -f lib/gen/assets.gen.dart \
    && ! git check-ignore -q lib/gen/assets.gen.dart \
    && git ls-files --error-unmatch lib/gen/assets.gen.dart \
    && flutter test test/assets/assets_gen_compile_test.dart
  ```
  （`flutter test` 断言生成的 `Assets.editor.demoImage.path` **取值** == `assets/editor/demo_image.png`——把原先仅 `test -f` 存在性检查升级为「import 产物 + 断言强类型引用解析到规范路径」的行为断言，验到 R1/R4；断言来源是产物运行期取值，非配置文件文本。）
- 人工（@Ray）：连续两次生成后 `git diff lib/gen/assets.gen.dart` 无变化（幂等）

### 验收记录
```
日期：2026-05-30
自动：自动验收命令执行通过，成功生成 assets.gen.dart，且单元测试通过。
人工：[x]（经 @Ray 人工核查确认连续两次生成无脏 diff，幂等性通过）
```
