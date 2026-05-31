---
作者：@Ray
创建日期：2026-05-31
最后更新：2026-05-31
文档状态：定稿
---

# 任务列表：ui-i18n-migration

## 依赖速览

T1 ARB + 失败测试 → T2 组件/shell/timeline 迁移 → T3 测试迁移 → T4 spec 规则修订 → T5 验证收口

-----

- [x] T1 · ARB 补全与迁移回归测试

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** i18n-localization：gen-l10n 基础设施 ｜ **关联需求：** R1, NF1, NF2 ｜ **依据设计：** D1, D3 ｜ **可改文件：** `lib/l10n/arb/app_zh.arb`、`lib/l10n/arb/app_en.arb`、`lib/l10n/gen/app_localizations.dart`、`lib/l10n/gen/app_localizations_zh.dart`、`lib/l10n/gen/app_localizations_en.dart` ｜ **验收基建：** `test/l10n/app_localizations_test.dart`、`test/l10n/ui_i18n_migration_test.dart`

### 背景
先补全旧 UI 文案 key，并用测试证明 en locale 能取到英文 UI 默认文案。

### 实施
1. 给 zh/en ARB 补旧 `AppStrings` key。
2. 跑 `flutter gen-l10n`。
3. 增加 l10n 取值和 UI 迁移回归测试。

### 验收方式
- 自动：
  ```bash
  bash scripts/check_arb_sync.sh && flutter test test/l10n/app_localizations_test.dart test/l10n/ui_i18n_migration_test.dart
  ```

### 验收记录
```
日期：2026-05-31
自动：`bash scripts/check_arb_sync.sh` 通过；`flutter gen-l10n` 普通沙箱因 Flutter SDK cache 权限失败，按项目备忘升权重跑通过；`flutter test test/l10n/ test/ui/widgets/ test/ui/shell/ test/ui/timeline/ test/demo/ test/app_router_mount_test.dart` 通过（143 tests）。
人工：N/A
```

-----

- [x] T2 · 生产 UI 移除 AppStrings

**同 spec 依赖：** T1 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R2, R3 ｜ **依据设计：** D1, D2, D3 ｜ **可改文件：** `lib/ui/widgets/*.dart`、`lib/ui/shell/*.dart`、`lib/ui/timeline/*.dart`、`lib/demo/*.dart`、`lib/ui/strings/app_strings.dart`

### 背景
把所有生产 UI 文案从静态中文常量改为 build 期 l10n。

### 验收方式
- 自动：
  ```bash
  ! rg "AppStrings\\.|ui/strings/app_strings|\\.\\./strings/app_strings" lib
  ```

### 验收记录
```
日期：2026-05-31
自动：`rg "AppStrings|app_strings" lib test -n` 无命中；聚焦 Flutter 测试通过（143 tests）。
人工：N/A
```

-----

- [x] T3 · 测试迁移与本地化 wrapper

**同 spec 依赖：** T2 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R2, NF2 ｜ **依据设计：** D2, D3 ｜ **可改文件：** `test/l10n/*.dart`、`test/ui/**/*.dart`、`test/demo/*.dart`、`test/app_router_mount_test.dart`

### 验收方式
- 自动：
  ```bash
  flutter test test/l10n/ test/ui/widgets/ test/ui/shell/ test/ui/timeline/ test/demo/ test/app_router_mount_test.dart
  ```

### 验收记录
```
日期：2026-05-31
自动：`flutter test test/l10n/ test/ui/widgets/ test/ui/shell/ test/ui/timeline/ test/demo/ test/app_router_mount_test.dart` 通过（143 tests）；本次触达 Dart 文件专项 `dart analyze ...` 无问题。
人工：N/A
```

-----

- [x] T4 · UI spec 默认国际化

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R4 ｜ **依据设计：** D4 ｜ **可改文件：** `docs/spec-guide-ai.md`、`docs/design/11-internationalization-and-localization.md`、`specs/README.md`、`specs/active/*/requirement.md`、`specs/active/*/design.md`、`specs/active/*/tasks.md`、`specs/active/*/verification.md`

### 验收方式
- 自动：
  ```bash
  ! rg "AppStrings|app_strings|app_strings_[^[:space:]]*_test\\.dart" specs/active --glob '!specs/active/ui-i18n-migration/**'
  ! rg "app_strings_[^[:space:]]*_test\\.dart" docs/spec-guide-ai.md docs/design/11-internationalization-and-localization.md specs/README.md specs/active
  ```
  迁移 spec 自身和全局规则文档允许保留 `AppStrings` / `app_strings` 的历史与废弃说明；其他活跃 UI spec 不得继续出现相关要求或旧测试路径名。

### 验收记录
```
日期：2026-05-31
自动：`rg "AppStrings|app_strings|app_strings_[^[:space:]]*_test\\.dart" specs/active --glob '!specs/active/ui-i18n-migration/**' -n` 无命中；`rg "app_strings_[^[:space:]]*_test\\.dart" docs/spec-guide-ai.md docs/design/11-internationalization-and-localization.md specs/README.md specs/active -n` 无命中。
人工：N/A
```

-----

- [-] T5 · 分析与回归

**同 spec 依赖：** T1, T2, T3, T4 ｜ **跨 spec 依赖：** 无 ｜ **关联需求：** R1, R2, R3, R4, NF1, NF2 ｜ **依据设计：** D1, D2, D3, D4 ｜ **可改文件：** `specs/active/ui-i18n-migration/tasks.md`、`specs/README.md`

### 验收方式
- 自动：
  ```bash
  dart format lib test && dart analyze && bash scripts/check_arb_sync.sh && flutter test test/l10n/ test/ui/widgets/ test/ui/shell/ test/ui/timeline/ test/demo/ test/app_router_mount_test.dart
  ```

### 验收记录
```
日期：2026-05-31
自动：`dart format <本次触达 Dart 文件>` 通过；`dart analyze <本次触达 Dart 文件>` 无问题；`dart analyze` 全仓库仍返回 2，剩余为既有非本次触达 warning/info（`bin/gen_tokens.dart`、`packages/appflowy-editor/**`、`test/ui/theme/contrast_test.dart`、`lib/demo/theme_gallery_demo.dart`、`test/l10n/material_app_locale_test.dart`）；`bash scripts/check_arb_sync.sh` 通过；`flutter test test/l10n/ test/ui/widgets/ test/ui/shell/ test/ui/timeline/ test/demo/ test/app_router_mount_test.dart` 通过（143 tests）。
人工：N/A
```
