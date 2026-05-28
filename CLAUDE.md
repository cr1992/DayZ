# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **维护契约**：本文件只放**慢变量**——命令、架构大图、文档导航。**会变的东西**（有哪些 spec、功能进度、单个 `D#`/`T#`、各模块实现细节）一律以 `specs/README.md` + 文件树为唯一真相，本文只给指针、不复述。协作规范/红线以 [`AGENTS.md`](./AGENTS.md) 为准。修改本文件前先读底部「维护本文件」。

## 先认清仓库当前状态（最重要）

DayZ 是一个 **spec 驱动、本地优先、隐私优先的日记 App**（Flutter / Dart，stable 渠道最新版）。两个反直觉但关键的事实：

1. **应用代码基本还没写。** `lib/` 下 `backup/ data/ drafts/ media/ security/ thumbnails/ ui/` 七个模块目录目前**只有 `.gitkeep` 占位**；真正有代码的只有 `lib/main.dart`、`lib/app.dart` 和 `lib/demo/`。下面「架构大图」描述的是 **spec/design 规定的目标架构（处方），尚未落码**——不要去这些目录里找不存在的实现。
2. **架构活在文档里，不在源码里。** 模块边界、文件清单、依赖方向写在 `docs/design/*.md`（冻结决策）和 `specs/active/<feature>/design.md`（每个模块的"文件变更"清单）。**接到编码任务 → 先在对应 spec 的 `tasks.md` 找 `T#`，按 `docs/spec-guide-ai.md` 的执行协议做；新增功能/重大改动先开 spec，不在源码里直接发挥。**

## 常用命令

从仓库根目录运行：

```bash
flutter pub get                                   # 装依赖（含对 appflowy_editor 的本地 path override）
flutter run                                       # 真机/模拟器 debug 运行（启动后进入 Debug Home，见下）
flutter test                                      # 跑全部测试
flutter test test/demo/debug_home_test.dart       # 跑单个测试文件
flutter test --name "描述子串"                     # 按用例名跑单个测试（可附文件路径限定范围）
flutter analyze                                   # 静态分析 / lint（flutter_lints，配置见 analysis_options.yaml）
dart format .                                      # 格式化
```

非显然的两条管线：

```bash
# 1) WebView 版编辑器构建链（editor-build 是独立 Node 项目，不归 Flutter/pub 管）
cd editor-build && npm install                    # 首次
cd editor-build && npm run build                  # esbuild 打包 index.js → ../assets/editor/editor.js
# 注：editor.html 是手写的，build 不生成它，只生成 editor.js。
# 重要：编辑器选型已定为方案 A（AppFlowy，纯 Dart）。这条 TipTap/WebView 链（editor-build/、
# assets/editor/、lib/demo/editor_webview_tiptap_demo.dart）是被否的方案 B 遗留研究代码，勿当生产路径扩展。

# 2) vendored 包改动留痕对账（改了 packages/ 下源码后、提交前必须跑且退出 0）
bash scripts/check_patches.sh
```

平台事实（已核实出处，非引自可能失效的文档链接）：包名/Bundle ID `com.dayz`（`android/app/build.gradle.kts` 的 `applicationId`、`ios/Runner.xcodeproj/project.pbxproj` 的 `PRODUCT_BUNDLE_IDENTIFIER`）；Android `minSdk = 26`（同 gradle 文件）；iOS 部署目标 `13.0`（`project.pbxproj` 的 `IPHONEOS_DEPLOYMENT_TARGET`；注意 `ios/Podfile` 里那行 `platform :ios` 是注释掉的，别拿它当真相源）。

## 架构大图（需读多个文件才能拼出，均为 spec/design 处方）

- **分层与依赖方向**：`security/`（最底层，谁都依赖它、它不依赖任何业务）→ `data/`（Drift + Repository）→ `media/` → `thumbnails/` → `backup/`（顶层整合）。**Repository 边界是硬的**：UI / demo / backup 只调 `JournalRepo / EntryRepo / MediaRepo / TagRepo / EditingSessionRepo`，Drift DAO 是内部实现、不向上暴露。详见 `specs/active/data-layer/design.md`。
- **加密恒开，可选的只是 key 来源**：DB 用 SQLCipher，**始终加密**（依赖待引入 `drift`/`sqlcipher_flutter_libs`，目前尚未在 `pubspec.yaml`）。`AppDatabase` 在打开时向 `KeyProvider` 取一次 key 注入，用后即弃。可选的是 key 来源：设备随机 key（Keychain/Keystore，零摩擦）vs 主密码（Argon2id 派生，切换=`PRAGMA rekey`）。详见 `docs/design/06`、`specs/active/key-management/design.md`。
- **媒体密钥独立、主密码不保护照片**：媒体用「设备 key 经 HKDF 派生」的独立 key（自定义 AEAD 容器 `DMED|...|AES-256-GCM`），**不跟随主密码、不参与 rekey**。后果：设了主密码也锁不住照片——这是有意为之的产品行为，UI 须解释。详见 `specs/active/media-storage/design.md`、`docs/design/06`。
- **重活进 isolate**：缩略图生成、备份/还原导出、rekey 三处显式用 isolate（"重"=会卡 UI 的 CPU 活）。还原**禁止同步重建全部缩略图**（缩略图模块只暴露异步 `warmup`，让危险路径写不出来）。详见 `specs/active/thumbnail-cache/design.md`、`docs/design/05`。
- **文件 IO 不在 DB 事务内**：永远别声称"文件+DB 一个原子事务"。混写文件与 DB 时遵循 `docs/design/09` 的两套补偿顺序（单文件：写 tmp→rename→写 DB，DB 失败则删文件；还原：全部写入 `.restoring`、全成功才原子切换）。
- **Debug Home demo 入口模式**：UI 设计稿未定，App 启动直接进 demo 启动器——`lib/main.dart` → `lib/app.dart`（`home: DebugHome()`）→ `lib/demo/debug_home.dart` 遍历全局 `demos` 列表。**新 demo 追加到 `lib/demo/demo_entry.dart` 的 `demos` 末尾，不要插中间、不要改 `DemoEntry` 字段**（避免与其他模块冲突）。每个基础 spec 末尾都挂一个 Debug Home 入口、真机调试走 demo 页。

## 本地 vendored 包：`packages/appflowy-editor`

`pubspec.yaml` 声明 `appflowy_editor: ^6.2.0`，但用 `dependency_overrides` 指向仓库内的 fork `packages/appflowy-editor/`（保持上游 6.2.0 版本号，差异只靠台账+标记追踪）。编辑器改动走这里，不要改 pub 缓存。

改 `packages/` 下任何 vendored 源码，**三件套缺一不可**（详见 [`AGENTS.md`](./AGENTS.md) 与 `specs/active/appflowy-patch-tracking/`）：

1. 改动区间打成对标记 `// >>> DAYZ-PATCH[Pxxx]: 原因` … `// <<< DAYZ-PATCH[Pxxx]`（每处一个稳定 ID）；
2. 在 `packages/CHANGELOG.md` 的「Patch 台账」登记（ID + 文件定位 + 原因 + 关联 + upstream）；
3. 提交前 `bash scripts/check_patches.sh` 须退出 0。

且 **package 改动（源码+测试+`pubspec.lock`+`packages/CHANGELOG.md`）必须作为独立 git commit**，不得与业务/demo 层（`lib/`）代码混提。（注意两个 CHANGELOG：要改的是 `packages/CHANGELOG.md`；`packages/appflowy-editor/CHANGELOG.md` 是上游文件，勿动。）

## 文档导航（想知道 X → 看哪）

| 想知道 | 看这里 |
|---|---|
| 协作规范 / 红线 / 项目专有约定 | [`AGENTS.md`](./AGENTS.md)（**唯一规范源**，本文不复述） |
| 怎么写 / 执行 spec、档位选择、归档流程、执行协议 | `docs/spec-guide-ai.md` |
| 当前有哪些功能、状态、优先级、负责人 | `specs/README.md`（功能生命周期**唯一真相**） |
| 某功能的需求 / 设计 / 任务 / 验收 | `specs/active/<feature>/{requirement,design,tasks,verification}.md` |
| 冻结的技术决策（选型 / Schema / 加密 / 备份 / 资源） | `docs/README.md`（索引）→ `docs/design/0X-*.md` |
| 改 crypto/key 之前必读 | `docs/design/06-encryption-and-security-policy.md` |
| 混写文件+DB 之前必读 | `docs/design/09-file-db-write-atomicity.md` |
| vendored 包补丁台账 | `packages/CHANGELOG.md` + `specs/active/appflowy-patch-tracking/` |

## 红线（细节见 AGENTS.md，此处只提醒）

- **始终用中文**回复与开发指导。
- **未经用户明确许可，严禁 `git commit` / push。**
- 作者署名统一 `@Ray`。
- 只改 spec 任务卡「可改文件」白名单内的文件；要碰白名单外的，先停下问。

## 维护本文件

只在改到**慢变量**时才编辑 CLAUDE.md：① 命令变了（新增 codegen、测试方式变、构建脚本变）；② 出现新的结构性约定（新模块层、真 UI 层取代 Debug Home、新的跨切面模式）；③ 指针失效（文档被改名/归档/挪位 → 修路径）。

**不该触发更新**（交给指针自动覆盖）：新增/归档一个 spec、模块内部写代码进度、spec 里加了个 `D#`/`T#`。绝不在此硬编码 active spec 清单——它指向 `specs/README.md`。在本仓库里，若某 spec 任务改了构建命令或引入结构性约定，把本文件一并列入该任务的「可改文件」同 commit 更新，是防 drift 最对路的方式。
