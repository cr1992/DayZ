# AGENTS.md · DayZ

跨平台、本地优先、注重隐私的日记 App。Flutter / Dart，stable 渠道最新版。

## 上下文指引（按需阅读）

| 想知道 | 看这里 |
|---|---|
| 技术选型 / 加密 / 备份 / 编辑器等冻结决策 | `docs/README.md` → `docs/design/0X-*.md` |
| spec 怎么写、执行协议、档位选择 | `spec-kit/spec-guide.md`（规则真源）；DayZ overlay `docs/spec-guide-ai.md` |
| 当前功能列表、状态、优先级、依赖 | `specs/README.md` |
| 单个功能的需求 / 设计 / 任务 | `specs/active/<feature>/` |

## 工作流

1. 接到任务 → 在 `specs/active/<feature>/tasks.md` 找对应 T# 项。
2. 按 `spec-kit/spec-guide.md` 执行协议做事（DayZ 专项见 `docs/spec-guide-ai.md`）；可改文件、验收方式都在任务卡里。
3. 完成后填验收记录，按 `specs/README.md` 更新状态。

屏幕 spec 交付 v1 后进入「已交付·随设计维护」泳道，终态→归档规则被 DayZ overlay override；细则见 `docs/spec-guide-ai.md`。

新增功能或重大改动 → 先开 spec，不在源码里直接做。开 spec 时按 spec-guide「排序维护纪律」**想清依赖、相对现有 spec 定优先级**，并落到 `specs/README.md` 的依赖 / 优先级列——别留空或无脑同档。spec 已经写明的事，不要在这里、commit message、PR 描述里重复。

## 规则

- **中文回复**：本项目的问答与开发指导始终使用中文。
- **禁止自行提交**：未经用户明确许可，严禁执行 `git commit` 或 push。
- **作者署名统一 `@Ray`**。
- **授权 MPL-2.0（混合授权）**：新建 Dart 源文件 MUST 加 MPL-2.0 头注（模板见 README「License」）。`packages/appflowy-editor/` 保留上游 AGPL-3.0 / MPL-2.0 双授权，不可重新授权。
- **包名 `com.dayz`**，iOS 13+，Android minSdk 26。
- **本地 Package 独立提交**：`packages/` 下的代码、测试、`pubspec.lock` 及 `packages/CHANGELOG.md` 必须作为独立 Git Commit，不得同业务或 Demo 层代码混合。
- **vendored 包改动留痕**（三件套缺一不可）：① 成对标记 `// >>> DAYZ-PATCH[Pxxx]` … `// <<< DAYZ-PATCH[Pxxx]`；② `packages/CHANGELOG.md` 台账登记；③ 提交前 `bash scripts/check_patches.sh` 须退出 0。详见 `specs/active/appflowy-patch-tracking/`。
- **静态资源 `flutter_gen`**：**禁止**硬编码资源路径，必须用 `Assets.images.xxx` 等强类型引用。新增/修改资源后运行 `dart run build_runner build`。
- **国际化 `gen-l10n`**：用户可见文案经 `AppLocalizations.of(context)` 取用，**禁止**硬编码。新增文案 MUST 同时补 `app_zh.arb` 与 `app_en.arb`（key 一致）。详见 `docs/design/11-internationalization-and-localization.md`。
- **UI 设计稿未到，基础层先行**：基础 spec 末尾挂 Debug Home 入口，真机调试走 demo 页。
