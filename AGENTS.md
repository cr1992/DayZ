# AGENTS.md · DayZ

跨平台、本地优先、注重隐私的日记 App。Flutter / Dart，stable 渠道最新版。

## 先读哪里

| 想知道 | 看这里 |
|---|---|
| 技术选型 / 加密 / 备份 / 编辑器决策 | [`docs/README.md`](./docs/README.md) |
| spec 怎么写、执行协议、档位选择 | [`spec-kit/spec-guide.md`](./spec-kit/spec-guide.md)（规则真源）；DayZ 专项 overlay [`docs/spec-guide-ai.md`](./docs/spec-guide-ai.md) |
| 当前有哪些功能在做、状态、优先级、依赖 | [`specs/README.md`](./specs/README.md) |
| 单个功能的需求 / 设计 / 任务 | `specs/active/<feature>/` |

## 工作流

1. 接到任务 → 在 `specs/active/<feature>/tasks.md` 找对应 T# 项。
2. 按 spec-kit/spec-guide.md 的执行协议做事（DayZ 专项见 docs/spec-guide-ai.md）；可改文件、验收方式都在任务卡里。
3. 完成后填验收记录，按 specs/README.md 更新状态。

新增功能或重大改动 → 先开 spec，不在源码里直接做（开 spec 时按 spec-guide「排序维护纪律」**想清依赖、相对现有 spec 定优先级**，并落到 [`specs/README.md`](./specs/README.md) 的依赖 / 优先级列——别留空或无脑同档）。spec 已经写明的事，不要在这里、commit message、PR 描述里重复。

## 本项目专有约定（v6 / spec-guide 之外的）

- **UI 设计稿未到，基础层先行**。基础 spec 末尾都挂一个 Debug Home 入口（M0 提供框架），真机调试走 demo 页。
- **包名 `com.dayz`**，iOS 13+，Android minSdk 26（详见 [M0](./specs/archive/2026-05-23-app-scaffold/)）。
- **作者署名统一 `@Ray`**。
- **授权:整库 MPL-2.0，但仓库为混合授权**。本项目原创代码采用 Mozilla Public License 2.0（根目录 `LICENSE`）；`packages/appflowy-editor/` 是上游 fork，**保留其原本的 AGPL-3.0 / MPL-2.0 双授权、不可重新授权**，本项目按 MPL 一臂使用。新建 Dart 源文件 MUST 在文件顶部加 MPL-2.0 头注（`This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0...`，模板见 README「License」）。任何"换成更宽松/更严格 license"的提议，都换不掉 `packages/appflowy-editor/` 那部分——别被误导。
- **本地 Package 修改规范**：对 `packages/` 下本地 package 的修改，必须在 `packages/CHANGELOG.md` 中补充变更说明；且 Package 相关的代码、测试、`pubspec.lock` 及 CHANGELOG 文件必须作为一个独立的 Git Commit 提交，不得同业务或 Demo 层代码混合。
- **vendored 包改动留痕**：改 `packages/` 下 vendored 包（如 `appflowy-editor`）的源码，MUST 三件套齐全：① 在改动区间打成对标记 `// >>> DAYZ-PATCH[Pxxx]: 原因` … `// <<< DAYZ-PATCH[Pxxx]`（每个 patch 一个稳定 ID）；② 在 `packages/CHANGELOG.md` 的「Patch 台账」登记 ID + 文件定位 + 原因 + 关联 + upstream；③ 提交前跑 `bash scripts/check_patches.sh` 对账（须退出 0）。机制与升级 SOP 见 [`specs/active/appflowy-patch-tracking/`](./specs/active/appflowy-patch-tracking/)。
- **AI 助手交互规范**：本项目的问答与开发指导始终使用中文回复；且未经用户明确许可，AI 助手严禁执行任何 `git commit` 或提交代码的操作。
- **静态资源管理 (flutter_gen)**：本项目使用 `flutter_gen` 进行类型安全的静态资源访问。**绝对禁止**在代码中直接使用硬编码的字符串资源路径（如 `Image.asset('assets/images/logo.png')`），必须使用强类型引用类（如 `Assets.images.xxx.path` 或 `Assets.images.xxx.image()`）。每次新增/修改内置资源（`assets/` 目录下）后，必须运行 `dart run build_runner build` 更新 `lib/gen/assets.gen.dart` 并将其一并提交。
- **国际化 (i18n)**：用户可见文案一律经 `AppLocalizations.of(context)` 取用（Flutter 官方 `gen-l10n` + `.arb`，中英双语）。**绝对禁止**硬编码用户可见字面量（中/英皆然）；复数走 arb `plural`、日期/数字走 `package:intl`。新增任一文案 MUST 同时补 `app_zh.arb` 与 `app_en.arb`（两份 key 必须一致）。取向与横切契约见 [`docs/design/11-internationalization-and-localization.md`](./docs/design/11-internationalization-and-localization.md) 与 [`specs/active/i18n-localization/`](./specs/active/i18n-localization/)。

其余规则（加密路径、Repository 边界、媒体密钥归属、isolate 处理重活、时区字段同步重算等）在 v6 与各 spec 中有明文——遵循 spec 即可，本文不复述。
