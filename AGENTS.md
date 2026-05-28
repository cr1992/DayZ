# AGENTS.md · DayZ

跨平台、本地优先、注重隐私的日记 App。Flutter / Dart，stable 渠道最新版。

## 先读哪里

| 想知道 | 看这里 |
|---|---|
| 技术选型 / 加密 / 备份 / 编辑器决策 | [`docs/README.md`](./docs/README.md) |
| spec 怎么写、执行协议、档位选择 | [`docs/spec-guide-ai.md`](./docs/spec-guide-ai.md) |
| 当前有哪些功能在做、状态、依赖 | [`specs/README.md`](./specs/README.md) |
| 单个功能的需求 / 设计 / 任务 | `specs/active/<feature>/` |

## 工作流

1. 接到任务 → 在 `specs/active/<feature>/tasks.md` 找对应 T# 项。
2. 按 spec-guide-ai.md 的执行协议做事；可改文件、验收方式都在任务卡里。
3. 完成后填验收记录，按 specs/README.md 更新状态。

新增功能或重大改动 → 先开 spec，不在源码里直接做。spec 已经写明的事，不要在这里、commit message、PR 描述里重复。

## 本项目专有约定（v6 / spec-guide 之外的）

- **UI 设计稿未到，基础层先行**。基础 spec 末尾都挂一个 Debug Home 入口（M0 提供框架），真机调试走 demo 页。
- **包名 `com.dayz`**，iOS 13+，Android minSdk 26（详见 [M0](./specs/active/app-scaffold/)）。
- **作者署名统一 `@Ray`**。
- **本地 Package 修改规范**：对 `packages/` 下本地 package 的修改，必须在 `packages/CHANGELOG.md` 中补充变更说明；且 Package 相关的代码、测试、`pubspec.lock` 及 CHANGELOG 文件必须作为一个独立的 Git Commit 提交，不得同业务或 Demo 层代码混合。
- **vendored 包改动留痕**：改 `packages/` 下 vendored 包（如 `appflowy-editor`）的源码，MUST 三件套齐全：① 在改动区间打成对标记 `// >>> DAYZ-PATCH[Pxxx]: 原因` … `// <<< DAYZ-PATCH[Pxxx]`（每个 patch 一个稳定 ID）；② 在 `packages/CHANGELOG.md` 的「Patch 台账」登记 ID + 文件定位 + 原因 + 关联 + upstream；③ 提交前跑 `bash scripts/check_patches.sh` 对账（须退出 0）。机制与升级 SOP 见 [`specs/active/appflowy-patch-tracking/`](./specs/active/appflowy-patch-tracking/)。
- **AI 助手交互规范**：本项目的问答与开发指导始终使用中文回复；且未经用户明确许可，AI 助手严禁执行任何 `git commit` 或提交代码的操作。

其余规则（加密路径、Repository 边界、媒体密钥归属、isolate 处理重活、时区字段同步重算等）在 v6 与各 spec 中有明文——遵循 spec 即可，本文不复述。
