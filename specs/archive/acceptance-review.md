---
作者：@Ray
创建日期：2026-05-30
---

# 归档验收说明

本文件记录 2026-05-30 对 `specs/README.md`「已归档」表中 9 个 spec 的终局复验结论。后续不再逐个回翻历史 tasks / verification 做人工 review；历史文档中旧式 `人工：—（无）`、已由自动化覆盖的 `待确认`、以及已转由后续 spec 承接的跨 spec 占位，以本说明的结论为准。

## 复验范围

- `i18n-localization`
- `key-management`
- `observability`
- `assets-management`
- `app-scaffold`
- `editor-research`
- `appflowy-patch-tracking`
- `design-tokens-theme`
- `editor-json-contract`

## 已执行命令

```bash
bash spec-kit/scripts/check_dead_links.sh specs
bash spec-kit/scripts/lint_acceptance_commands.sh specs
bash spec-kit/scripts/lint_keywords.sh specs
bash scripts/check_patches.sh
bash scripts/check_arb_sync.sh
bash test/scripts/check_arb_sync_test.sh
bash test/scripts/check_tokens_sync_test.sh
cargo build --manifest-path packages/argon2id_ffi/rust/Cargo.toml --release --lib
flutter test test/l10n/ test/demo/i18n_demo_test.dart test/assets/assets_gen_compile_test.dart test/ui/theme/ test/demo/theme_gallery_demo_test.dart test/demo/debug_home_test.dart
flutter test test/observability/ test/demo/observability_demo_test.dart
flutter test test/editor/contract/
ARGON2ID_FFI_LIB=packages/argon2id_ffi/rust/target/release/libargon2id_ffi.dylib flutter test test/security/
flutter test test/demo/debug_home_test.dart test/widget_test.dart
dart analyze lib/security test/security lib/demo/demo_entry.dart
flutter build apk --debug
flutter build ios --debug --no-codesign
```

补充检查：

```bash
git ls-files --error-unmatch lib/l10n/gen/app_localizations.dart
git check-ignore -q lib/l10n/gen/app_localizations.dart
```

结果：上述复验命令通过；`git check-ignore -q` 返回 1，表示 l10n 生成产物未被 ignore，符合预期。

## 结论

| spec | 归档结论 | 说明 |
|---|---|---|
| `i18n-localization` | 通过 | l10n 生成产物、ARB key 对齐、demo / MaterialApp / controller 测试均通过。 |
| `key-management` | 通过 | Rust release lib 构建通过；按归档口径注入 `ARGON2ID_FFI_LIB` 后 `test/security/` 全过；裸跑 `flutter test test/security/` 因 host FFI 库未注入失败，不作为归档命令口径。 |
| `observability` | 通过 | observability 单元、demo、降级、轮转、脱敏、路径解析均通过；历史真机操作项不再要求二次人工确认。`backup-full-snapshot` 未落地导致的“备份包不含 logs/”联测占位归后续备份 spec 承接，不阻塞本归档。 |
| `assets-management` | 通过 | `flutter_gen` 产物存在且可编译，强类型资源引用测试通过；生成产物已入库。 |
| `app-scaffold` | 通过 | Debug Home widget test、Android debug build、iOS debug build 均通过；历史 grep 命令已按当前 Kotlin DSL 修正。 |
| `editor-research` | 通过 | 选型已由 @Ray 拍板为 AppFlowy Editor；后续 editor spec 均以该结论为依赖，不再补做旧研究任务的人工复测。 |
| `appflowy-patch-tracking` | 通过 | `scripts/check_patches.sh` 通过，代码 patch 标记与 `packages/CHANGELOG.md` 台账一致。 |
| `design-tokens-theme` | 通过 | token/theme/font/demo 测试与同源脚本测试通过；当前对比度 expected-fail 以 `test/ui/theme/contrast_xfail.yaml` 为机器真源记录，按当前设计源不阻塞归档。历史视觉人工项不再要求二次确认。 |
| `editor-json-contract` | 通过 | editor contract 全目录测试通过，块类型、codec、抽取、只读渲染、导出降级、media ref 等契约均有行为测试覆盖。 |

## 不作为归档阻塞

- 全仓 `flutter analyze` 当前仍有历史 / vendored / active worktree 相关 issue；本轮已确认归档核心命令通过，且 `dart analyze lib/security test/security lib/demo/demo_entry.dart` 通过。全仓 analyze 清理不再追溯阻塞这些归档 spec。
- 真机冷启动计时、字体观感、observability 真机按钮操作等历史人工项不再要求二次确认；后续若需要真机覆盖，归新 active spec 的验收范围。
- `backup-full-snapshot` 尚未实现时，observability 的备份包联测只能作为后续备份 spec 约束，不阻塞 observability 归档。
