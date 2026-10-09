# AGENTS.md · DayZ

跨平台、本地优先、注重隐私的日记 App。Flutter / Dart，stable 渠道最新版。

## 上下文指引（按需阅读）

| 想知道 | 看这里 |
|---|---|
| 技术选型 / 加密 / 备份 / 编辑器等冻结决策 | `docs/README.md` → `docs/design/0X-*.md` |
| spec 怎么写、执行协议、档位选择 | `spec-kit/spec-guide.md`（规则真源）；DayZ overlay `docs/spec-guide-ai.md` |
| 当前功能列表、状态、优先级、依赖 | `specs/README.md` |
| 单个功能的需求 / 设计 / 任务 | `specs/active/<feature>/` |
| UI 还原方法、四道闸、波次 | `docs/design/10-ui-restore-and-design-sync.md` |
| 设计稿真源、token、组件类名与最小 HTML | `ui-design/current/`（`docs/DESIGN-REF.md` 速查；`pages/screens/*.html` 为各屏真源）。该目录由 `dayz-design-sync` skill 整体覆盖，**不要在里面手改** |
| 代码分层 | `lib/ui/theme`（token/主题）→ `lib/ui/widgets`（ui-kit）→ `lib/ui/shell`（外壳/路由）→ `lib/ui/<feature>`（各屏）；`lib/app/` 是生产装配（组合根）；`lib/demo/` 只放 Debug Home demo |

## 工作流

0. **开工先写白名单**：把本任务的「可改文件 + 验收基建」写进仓库根 `.spec-task-whitelist`（每行一个 glob，`#` 注释；格式见 `spec-kit/README.md`「白名单约定」）。写了它，`Edit/Write` 越界会被 PreToolUse hook 直接拒绝；没写等于闸关着。白名单 MUST ⊆ 该 spec `design.md`「文件变更」。
1. 接到任务 → 在 `specs/active/<feature>/tasks.md` 找对应 T# 项。
2. 按 `spec-kit/spec-guide.md` 执行协议做事（DayZ 专项见 `docs/spec-guide-ai.md`）；可改文件、验收方式都在任务卡里。
3. 完成后填验收记录，按 `specs/README.md` 更新状态（`[-]` 的含义见该文件顶部）。
4. **收尾跑闸**（pre-commit 会自动跑前三条，提交前自己先跑一遍省得被拦）：

   ```bash
   bash spec-kit/scripts/check_specs_index.sh specs && bash spec-kit/scripts/check_dead_links.sh specs && bash spec-kit/scripts/lint_acceptance_commands.sh specs && bash scripts/check_arb_sync.sh && bash scripts/check_tokens_sync.sh && bash scripts/check_ui_sync.sh
   ```

屏幕 spec 交付 v1 后进入「已交付·随设计维护」泳道，终态→归档规则被 DayZ overlay override；细则见 `docs/spec-guide-ai.md`。

新增功能或重大改动 → 先开 spec，不在源码里直接做。开 spec 时按 spec-guide「排序维护纪律」**想清依赖、相对现有 spec 定优先级**，并落到 `specs/README.md` 的依赖 / 优先级列——别留空或无脑同档。spec 已经写明的事，不要在这里、commit message、PR 描述里重复。

**多会话并行**：同一仓库可能同时有多个 agent 会话各推一个 spec。规则：① 一个会话只认领一个 spec，不碰别人 spec 的「文件变更」清单；② 共享文件（`lib/app.dart`、`lib/main.dart`、`lib/ui/shell/app_router.dart`、`lib/ui/shell/app_shell.dart`、`lib/demo/demo_entry.dart`、两份 arb、`pubspec.*`）同一时间只允许一个会话改，开工前 `git status` 看一眼谁已经动了；③ `.spec-task-whitelist` 是单文件，先到的会话把并行会话的可改文件也列进去（注释注明），后到的只追加不覆盖；④ 跨会话改动靠小步 commit 交接，不靠口头同步。

## 规则

- **中文回复**：本项目的问答与开发指导始终使用中文。
- **禁止自行提交**：未经用户明确许可，严禁执行 `git commit` 或 push。
- **作者署名统一 `@Ray`**。
- **授权 MPL-2.0（混合授权）**：新建 Dart 源文件 MUST 加 MPL-2.0 头注（模板见 README「License」）。`packages/appflowy-editor/` 保留上游 AGPL-3.0 / MPL-2.0 双授权，不可重新授权。
- **包名 `com.dayz`**，iOS 13+，Android minSdk 26。
- **本地 Package 独立提交**：`packages/` 下的代码、测试、`pubspec.lock` 及 `packages/CHANGELOG.md` 必须作为独立 Git Commit，不得同业务或 Demo 层代码混合。
- **vendored 包改动留痕**（三件套缺一不可）：① 成对标记 `// >>> DAYZ-PATCH[Pxxx]` … `// <<< DAYZ-PATCH[Pxxx]`；② `packages/CHANGELOG.md` 台账登记；③ 提交前 `bash scripts/check_patches.sh` 须退出 0。详见 `specs/archive/2026-05-29-appflowy-patch-tracking/`。
- **静态资源 `flutter_gen`**：**禁止**硬编码资源路径，必须用 `Assets.images.xxx` 等强类型引用。新增/修改资源后运行 `dart run build_runner build`。
- **国际化 `gen-l10n`**：用户可见文案经 `AppLocalizations.of(context)` 取用，**禁止**硬编码。新增文案 MUST 同时补 `app_zh.arb` 与 `app_en.arb`（key 一致，`scripts/check_arb_sync.sh` 校验）。详见 `docs/design/11-internationalization-and-localization.md`。
- **UI 只用 token，不写死值**：颜色经 `context.dayz`、字体经 `context.dayzText`、间距/圆角经 `DayzSpacing` / `DayzRadii`。设计稿里确有的字面量（如 `.card h4 { font-size: 17px }`）允许以 `copyWith` 落在组件内，并在旁边注明对应的 CSS 选择器。图标一律走 `DayzIcons` 的 SVG path，不用 `Icons.*`。
- **Repository 边界**：`lib/ui/**` 只经 `*Repo` 取数，禁止持 Drift 句柄或写 SQL。
- **屏幕 spec 维护态 override**：屏幕级 spec 交付 v1 后不按通用「终态→归档」处理，转入 `specs/README.md`「已交付·随设计维护」泳道；该 override 仅限屏幕 spec，见 `docs/spec-guide-ai.md`。
- **Debug Home**：真外壳已接管冷启动（`MaterialApp.router` → 时间线）；Debug Home 降级为具名路由 `/debugHome`，仍是真机走查 demo 的入口。新 demo 只在 `lib/demo/demo_entry.dart` 的 `demos` **末尾追加一行**，不改 `DemoEntry` 字段。

## Agent 备忘（踩坑记录，非项目规则）

- **Flutter/Dart 命令串行**：不要并行跑多个 `flutter test` / `dart run build_runner` / Flutter 工具命令；它们会抢启动锁、`ios/Flutter/ephemeral`、`.dart_tool/build` 或 `build/native_assets/*`。涉及 native assets / SQLCipher 的测试统一 `-j 1` 串行跑。
- **Drift 测试导入冲突**：测试文件若只需要 `Value`，用 `import 'package:drift/drift.dart' show Value;`，避免与 `flutter_test` / `matcher` 断言命名互扰。
- **SQLite DateTime 断言**：Drift/SQLite 读回 `DateTime` 可能是本地时区表示的同一瞬间；比较前先 `.toUtc()`。
- **timezone UTC 别名**：项目工具已将 `UTC` 归一到 `Etc/UTC`；测试和调用优先用 IANA 名称，常见 UTC 输入保持兼容。
- **SQLCipher 探测口径**：`sqlite3` 3.x + SQLite3MultipleCiphers 下 `PRAGMA cipher_version` 可能为空；用 `PRAGMA cipher == sqlcipher` 判定，并结合密文文件头与错密钥抛 `WrongKeyException` 行为验证。
- **widget test 里看真实观感**：`flutter_test` 默认用 Ahem 占位字体、不含 Material 图标字；要出可看的截图需用 `FontLoader` 加载 `assets/fonts/` 的两套 Latin 字，CJK 仍会是方块，用 `en` locale 看版式。
- **Codex 沙箱专项**（SDK cache / build_runner / git index / iOS 构建的 `Operation not permitted`）：见 `docs/agent-notes-codex.md`，仅 Codex 环境相关。
