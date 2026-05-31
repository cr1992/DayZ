---
作者：@Ray
创建日期：2026-05-31
最后更新：2026-05-31
文档状态：定稿
---

# 验证：ui-i18n-migration

- [x] `bash scripts/check_arb_sync.sh`
- [x] `! rg "AppStrings\\.|ui/strings/app_strings|\\.\\./strings/app_strings" lib`
- [x] `! rg "AppStrings|app_strings|app_strings_[^[:space:]]*_test\\.dart" specs/active --glob '!specs/active/ui-i18n-migration/**'`
- [x] `! rg "app_strings_[^[:space:]]*_test\\.dart" docs/spec-guide-ai.md docs/design/11-internationalization-and-localization.md specs/README.md specs/active`
- [x] 人工核查：`docs/spec-guide-ai.md`、`docs/design/11-internationalization-and-localization.md`、`specs/README.md`、`specs/active/ui-i18n-migration/` 中保留的 `AppStrings` / `app_strings` 仅为“已废弃 / 迁移 / 禁止回退”说明。
- [-] `dart analyze`：本次触达 Dart 文件专项 analyze 无问题；全仓库仍有既有非本次 warning/info，详见 `tasks.md` T5 验收记录。
- [x] `flutter test test/l10n/ test/ui/widgets/ test/ui/shell/ test/ui/timeline/ test/demo/ test/app_router_mount_test.dart`
