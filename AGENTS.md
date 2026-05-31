# AGENTS.md · DayZ

跨平台、本地优先、注重隐私的日记 App。Flutter / Dart，stable 渠道最新版。

## 上下文指引（按需阅读）

| 想知道 | 看这里 |
|---|---|
| 技术选型 / 加密 / 备份 / 编辑器等冻结决策 | `docs/README.md` → `docs/design/0X-*.md` |
| spec 怎么写、执行协议、档位选择 | `spec-kit/spec-guide.md`（规则真源）；DayZ overlay `docs/spec-guide-ai.md` |
| 当前功能列表、状态、优先级、依赖 | `specs/README.md` |
| 单个功能的需求 / 设计 / 任务 | `specs/active/<feature>/` |
| UI 像素级对齐还原与避坑 SOP | [docs/design/10-ui-restore-and-design-sync.md](file:///Users/xiaji/dev/DayZ/docs/design/10-ui-restore-and-design-sync.md#13-实战踩坑与-sop-避坑沉淀以侧边栏全部日记与日记本对齐为例) |

## 工作流

1. 接到任务 → 在 `specs/active/<feature>/tasks.md` 找对应 T# 项。
2. 按 `spec-kit/spec-guide.md` 执行协议做事（DayZ 专项见 `docs/spec-guide-ai.md`）；可改文件、验收方式都在任务卡里。
3. 完成后填验收记录，按 `specs/README.md` 更新状态。

屏幕 spec 交付 v1 后进入「已交付·随设计维护」泳道，终态→归档规则被 DayZ overlay override；细则见 `docs/spec-guide-ai.md`。

新增功能或重大改动 → 先开 spec，不在源码里直接做。开 spec 时按 spec-guide「排序维护纪律」**想清依赖、相对现有 spec 定优先级**，并落到 `specs/README.md` 的依赖 / 优先级列——别留空或无脑同档。spec 已经写明的事，不要在这里、commit message、PR 描述里重复。

## 规则

- **中文回复**：本项目的问答与开发指导始终使用中文。
- **绝对禁止自行提交**：未经当次明确的交互授权，严禁自行执行 `git commit` 或 push。即使在用户泛指“收尾提交”的语境下，也必须在执行 commit 前，向用户出示 Diff 与 commit message，并在用户明确回复“确认提交”或类似确认指令后，方可执行 commit 动作。
- **作者署名统一 `@Ray`**。
- **授权 MPL-2.0（混合授权）**：新建 Dart 源文件 MUST 加 MPL-2.0 头注（模板见 README「License」）。`packages/appflowy-editor/` 保留上游 AGPL-3.0 / MPL-2.0 双授权，不可重新授权。
- **包名 `com.dayz`**，iOS 13+，Android minSdk 26。
- **本地 Package 独立提交**：`packages/` 下的代码、测试、`pubspec.lock` 及 `packages/CHANGELOG.md` 必须作为独立 Git Commit，不得同业务或 Demo 层代码混合。
- **vendored 包改动留痕**（三件套缺一不可）：① 成对标记 `// >>> DAYZ-PATCH[Pxxx]` … `// <<< DAYZ-PATCH[Pxxx]`；② `packages/CHANGELOG.md` 台账登记；③ 提交前 `bash scripts/check_patches.sh` 须退出 0。详见 `specs/active/appflowy-patch-tracking/`。
- **静态资源 `flutter_gen`**：**禁止**硬编码资源路径，必须用 `Assets.images.xxx` 等强类型引用。新增/修改资源后运行 `dart run build_runner build`。
- **国际化 `gen-l10n`**：用户可见文案经 `AppLocalizations.of(context)` 取用，**禁止**硬编码。新增文案 MUST 同时补 `app_zh.arb` 与 `app_en.arb`（key 一致）。详见 `docs/design/11-internationalization-and-localization.md`。
- **屏幕 spec 维护态 override**：屏幕级 spec 交付 v1 后不按通用「终态→归档」处理，转入 `specs/README.md`「已交付·随设计维护」泳道；该 override 仅限屏幕 spec，见 `docs/spec-guide-ai.md`。
- **UI 设计稿未到，基础层先行**：基础 spec 末尾挂 Debug Home 入口，真机调试走 demo 页。

## Agent 备忘（踩坑记录，非项目规则）

- **Flutter SDK cache 沙箱权限**：在 Codex 沙箱内，`flutter pub get` / `flutter test` / `flutter build ...` /
  `flutter run` 等 Flutter 命令都可能先执行 SDK 内部 `update_engine_version.sh`，写
  `/opt/homebrew/Caskroom/flutter/.../bin/cache/engine.stamp.tmp.*`、`engine.realm` 等工作区外缓存；若报
  `Operation not permitted`，这通常是沙箱权限问题，不是依赖解析或业务代码问题。按审批机制对**同一条
  Flutter 命令**提升权限重跑；不要在普通沙箱里反复重试，也不要先改源码排查。
- **build_runner 权限注意**：本环境里普通沙箱曾出现 `dart run build_runner ...` 无输出卡住；需要 codegen 时优先用已批准的提升权限 `dart run build_runner ...`。若已卡住，先终止卡住的 `dart.*build_runner` 进程，再 `dart run build_runner clean` 后重跑。
- **Git index 写入权限**：`git add` / `git commit` / 部分 `git update-index` 会创建或更新 `.git/index.lock`；若在 Codex 沙箱内实际报 `Operation not permitted`，按审批机制对该 git 命令请求提升权限重跑，不要在普通沙箱里反复重试。`git status` / `git diff` 等只读检查不需要升权。
- **Flutter/Dart 命令串行**：不要并行跑多个 `flutter test` / `dart run build_runner` / Flutter 工具命令；它们可能抢启动锁、`ios/Flutter/ephemeral`、`.dart_tool/build` 或 `build/native_assets/*`，导致偶发删除失败、签名失败或旧产物误判。涉及 native assets / SQLCipher 的测试统一 `-j 1` 串行跑。
- **iOS 构建排障权限**：在 Codex 内跑 `flutter build ios` / `flutter run` 会写 Flutter SDK cache、Xcode DerivedData、CoreSimulator 等工作区外目录；若沙箱里出现 `Operation not permitted`，或 Xcode Pods embed framework 脚本偶发 `Killed: 9`，先提升权限单独重跑一次确认。若提升权限能过、用户终端仍失败，再清 DerivedData/Pods 缓存排查，不要先改业务源码。
- **Drift 测试导入冲突**：测试文件若只需要 `Value`，用 `import 'package:drift/drift.dart' show Value;`，避免引入不必要符号并减少与 `flutter_test` / `matcher` 断言命名互扰。
- **SQLite DateTime 断言**：Drift/SQLite 读回 `DateTime` 时可能变成本地时区表示同一瞬间；测试比较同一时刻时先 `.toUtc()`，不要直接和 UTC 字面值比对象。
- **timezone UTC 别名**：`timezone` 的 `UTC` alias 支持可能随包版本 / 数据集变化；项目工具已将 `UTC` 归一到 `Etc/UTC`。后续测试和调用优先用 IANA 名称，常见 UTC 输入仍应保持兼容。
- **SQLCipher 探测口径**：当前 `sqlite3` 3.x + SQLite3MultipleCiphers 下 `PRAGMA cipher_version` 可能为空；验证 SQLCipher 模式用 `PRAGMA cipher == sqlcipher`，并结合密文文件头与错密钥抛 `WrongKeyException` 行为验证。
