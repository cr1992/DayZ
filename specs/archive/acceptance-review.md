---
作者：@Ray
创建日期：2026-05-30
---

# 归档验收说明

本文件记录 2026-05-30 初次复验与 2026-05-31 补充复验后，对 `specs/README.md`「已归档」表中 15 个 spec 的终局复验结论。后续不再逐个回翻历史 tasks / verification 做人工 review；历史文档中旧式 `人工：—（无）`、已由自动化覆盖的 `待确认`、以及已转由后续 spec 承接的跨 spec 占位，以本说明的结论为准。

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
- `auto-save-draft`
- `data-layer`
- `dayz-security-rust`
- `media-storage`
- `thumbnail-cache`
- `ui-shell-navigation`

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

2026-05-31 补充复验命令：

```bash
cargo test --manifest-path packages/argon2id_ffi/rust/Cargo.toml
cargo build --manifest-path packages/argon2id_ffi/rust/Cargo.toml --release --lib
cd packages/argon2id_ffi && ARGON2ID_FFI_LIB=/Users/xiaji/dev/DayZ/packages/argon2id_ffi/rust/target/release/libargon2id_ffi.dylib flutter test test/crypto_ffi_test.dart -j 1
ARGON2ID_FFI_LIB=/Users/xiaji/dev/DayZ/packages/argon2id_ffi/rust/target/release/libargon2id_ffi.dylib flutter test test/security/ -j 1
flutter test test/data/ -j 1
flutter test test/media/ -j 1
flutter test test/drafts/ -j 1
flutter test test/thumbnails/ -j 1
flutter test test/demo/debug_home_test.dart test/security/demo_test.dart test/data/demo_test.dart test/media/demo_test.dart test/drafts/demo_test.dart test/thumbnails/demo_test.dart -j 1
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/data lib/media lib/drafts lib/thumbnails lib/security test/data test/media test/drafts test/thumbnails test/security
! grep -RIn 'TODO(data-layer-integration)' lib/security/
! grep -RnE 'dynamic|Map<String' lib/data/repositories/
! grep -RIn 'skipTagVerification\|ignoreTag\|noVerify' lib/media/
! grep -RIn '/var/mobile\|/data/data' lib/media/
! grep -Eq 'AppFlowy|TipTap|WebView' lib/drafts/draft_coordinator.dart
```

结果：上述复验命令通过；`git check-ignore -q` 返回 1，表示 l10n 生成产物未被 ignore，符合预期。首次包内 FFI `flutter test` 在普通沙箱因 Flutter SDK cache 写权限失败，按项目备忘提升权限重跑同一命令后通过。

2026-05-31 `ui-shell-navigation` 归档复验命令：

```bash
flutter pub get
flutter test test/ui/shell/ test/app_router_mount_test.dart test/demo/ -j 1
dart analyze lib/app.dart lib/ui/shell test/ui/shell test/app_router_mount_test.dart test/demo
bash spec-kit/scripts/lint_acceptance_commands.sh specs
bash spec-kit/scripts/lint_keywords.sh specs
bash spec-kit/scripts/check_dead_links.sh specs
bash spec-kit/scripts/archive_spec.sh ui-shell-navigation
```

结果：上述 `ui-shell-navigation` 复验命令通过；`flutter pub get` 首次在普通沙箱因 Flutter SDK cache 写权限失败，按项目备忘提升权限重跑同一命令后通过。全仓 `flutter analyze` 当前仍受无关 active backup / vendored / 历史 lint 影响，按本轮归档口径采用 shell/demo 定向 `dart analyze`。

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
| `auto-save-draft` | 通过 | `test/drafts/` 覆盖防抖、生命周期 flush、启动检测、崩溃恢复、单行模型、失败重试与编辑器中立接口；demo 回归覆盖自动保存、paused flush、提交清空、模拟重启恢复。T7 历史人工“待确认”和 100 KiB 真机 pendingFlush 耗时作为后置人工烟测，不阻塞归档。 |
| `data-layer` | 通过 | `test/data/` 覆盖 schema、SQLCipher 开库、密文文件头、错密钥、UUID、时区、DAO/Repo、migration、rekey 与 Data demo；`TODO(data-layer-integration)` 与弱类型公开 API 守卫无命中。`verification.md` 中 EXPLAIN 专测、db path 专测、UTC type_safety 专测文件当前不存在；索引命中、10000 条性能、WAL/journal 明文目审、Android 真机 CRUD 作为后置补测/人工风险记录。 |
| `dayz-security-rust` | 通过 | Rust KAT、release host dylib、包内 Dart FFI、主工程 `test/security/` 均通过；host Flutter 测试必须先构建 dylib 并注入 `ARGON2ID_FFI_LIB`。iOS 真机 archive/TestFlight、Android 真机 release、真机 release 性能/体积、64 MiB 多 isolate 并发 OOM 明确为发布前后置闸门，不阻塞本归档。 |
| `media-storage` | 通过 | `test/media/` 覆盖 AEAD smoke、设备媒体密钥消费、路径工具、codec 往返、100 MiB 流式读写正确性、nonce 唯一、篡改/错密钥失败、MediaStore put/openRead/soft/hard delete、备份重加密、路径安全与 Media demo；tag 验证旁路和绝对路径硬编码守卫无命中。真机吞吐/RSS、杀进程跨进程读取、demo UI 绝对路径目视、严格 crash fault-injection 作为后置项。 |
| `thumbnail-cache` | 通过 | `test/thumbnails/` 覆盖缩略图生成、加密落盘、DB thumb 字段、脏失效、取消、并发上限、warmup、API 解耦守卫和 demo 入口；本轮定向 analyzer 清理后 `lib/thumbnails` + `test/thumbnails` 无静态问题。真机 isolate/RSS/JPEG 质量一致性、完整 demo 人工路径作为后置人工烟测，不阻塞归档。 |
| `ui-shell-navigation` | 通过 | `test/ui/shell/` + `test/app_router_mount_test.dart` + `test/demo/` 覆盖路由常量/路径、真外壳启动、DebugHome 具名路由、抽屉（含头像/身份头、日记本/浏览/设置结构、计数注入）、FAB/sheet 交互、换肤、返回栈、44px 命中区、reduce-motion 与 Repository 边界；shell/demo 定向 analyzer 无 issue。生产壳层 journal 当前为入参/回调 + 内存 fallback，不持 Drift/SQL；真实 `JournalRepo` app bootstrap 接线归后续数据接入/页面 spec。 |

## 不作为归档阻塞

- 全仓 `flutter analyze` 当前仍有历史 / vendored / active worktree 相关 issue；本轮已确认归档核心命令通过，且 `dart analyze lib/security test/security lib/demo/demo_entry.dart` 通过。全仓 analyze 清理不再追溯阻塞这些归档 spec。
- 真机冷启动计时、字体观感、observability 真机按钮操作等历史人工项不再要求二次确认；后续若需要真机覆盖，归新 active spec 的验收范围。
- `backup-full-snapshot` 尚未实现时，observability 的备份包联测只能作为后续备份 spec 约束，不阻塞 observability 归档。
- `data-layer` 的 EXPLAIN 真索引命中、10000 条性能、WAL/journal 明文目审、Android 真机 CRUD；`media-storage` 的真机吞吐/RSS/跨进程读取和严格 crash fault-injection；`thumbnail-cache` 的真机 isolate/RSS/JPEG 质量一致性；`auto-save-draft` 的 100 KiB 真机 pendingFlush 耗时；`dayz-security-rust` 的真机 release/archive/体积/并发 OOM，均作为后置质量闸或发布前闸门，不追溯阻塞本次归档。
- `ui-shell-navigation` 的真机 SafeArea/返回手势烟测、外壳文案从 `AppStrings` 统一迁移到 gen-l10n `AppLocalizations`、以及真实 `JournalRepo` app bootstrap 接线，均作为后续页面 / 设置 / 数据接入 spec 或发布前闸门处理，不追溯阻塞本次外壳骨架归档。
