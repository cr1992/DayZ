---
作者：@Ray
创建日期：2026-05-29
---

# 设计：vendored 第三方包本地改动留痕

## 技术决策

### D1 · 改动标记形式：成对块注释 + 稳定 ID
- **背景：** 需要在 vendored 源码里标出哪些是本地改动，且要能被脚本机械校验、升级时一眼可见。
- **选择：** 成对块注释 `// >>> DAYZ-PATCH[Pxxx]: 原因` … `// <<< DAYZ-PATCH[Pxxx]`，ID 为 `P` + 三位数字，全局唯一且稳定。
- **理由：** 成对块能精确圈出改动区间（不止单行），`>>>`/`<<<` 方向直观；稳定 ID 让「代码 ↔ CHANGELOG ↔ upstream PR」三方可交叉引用；纯注释不改逻辑、对升级合并无副作用。
- **代价：** 注释可能在大段重排时漂移，需靠脚本对账兜底；ID 需人工分配（不自动生成），靠台账维护连号。

### D2 · 一个 patch 可跨多处共用一个 ID
- **背景：** 同一逻辑修复可能落在同一文件的多个分支（如 P002 的 character/word/line 三处 `else`）。
- **选择：** 同一逻辑改动共用一个 ID，可出现多组成对标记；校验按文件做栈式括号匹配，按 ID 统计开/闭。
- **理由：** 避免为同一意图的多处改动制造多个 ID 造成台账膨胀；栈式匹配能识别嵌套与 ID 错配。
- **代价：** 删除其中一处标记不会被「成对」检查发现（开闭仍各减一保持平衡），但「代码 ID 必在 CHANGELOG」与人工 review 可兜底；可接受。

### D3 · 对账脚本三段逻辑与退出码语义
- **背景：** 要区分「漏记」（必须立即修，硬错误）与「被升级冲掉/已合并上游」（信息性，不应阻断）。
- **选择：** ① 成对错误 → exit 1；② 代码有 ID 但 CHANGELOG 无 → exit 1（漏记）；③ CHANGELOG 有 ID 但代码无标记 → 告警 exit 0。
- **理由：** 漏记会让台账失真，必须挡住；而「记录在、标记没了」恰恰是升级冲掉本地改动的信号——它应当被看见但不阻断（此时可能正处于升级重贴流程中），用告警引导人去 design SOP 处理。
- **代价：** 告警可能被忽略；靠 SOP 要求每次升级后必看告警来约束。

### D4 · 干净基线来源：pub.dev 版本快照
- **背景：** 回填历史改动与未来升级都需要一份「未改动的原始源码」做 diff。
- **选择：** 以 pub.dev 发布的对应版本（当前 `appflowy_editor` 6.2.0）为干净基线，CHANGELOG 头部记录基线版本号。
- **理由：** pub.dev 版本不可变、可复现；本机 `~/.pub-cache/hosted/pub.dev/appflowy_editor-<ver>` 即现成快照，`diff -rq` 即可定位全部本地改动。
- **代价：** 升级时基线版本变化，需同步更新 CHANGELOG 的基线版本号；若上游改了目录结构，diff 噪声增大。

## 文件变更
- `specs/active/appflowy-patch-tracking/requirement.md`  新建
- `specs/active/appflowy-patch-tracking/design.md`        新建
- `specs/active/appflowy-patch-tracking/tasks.md`         新建
- `scripts/check_patches.sh`                              新建
- `packages/CHANGELOG.md`                                 修改（加「Patch 台账」段并回填 ID/定位）
- `AGENTS.md`                                             修改（专有约定加一条）
- `packages/appflowy-editor/lib/**`（4 文件）             修改（仅加成对注释标记，不改逻辑）：
  - `.../image_block_component/image_upload_widget.dart`（P001）
  - `.../editor/command/selection_commands.dart`（P002，三处）
  - `.../shortcuts/command/backspace_command.dart`（P003）
  - `.../service/ime/delta_input_service.dart`（P004）

## 上游同步 SOP（升级 appflowy_editor 时执行）

原则：**干净基线（pub.dev 版本快照）+ patch 文件 + 留痕对账**。fork 越薄越好——每个 patch 尽量同步向 upstream 提 PR，合并后即废弃该 patch、控制 fork 膨胀。

升级步骤：
1. **换基线**：从 pub.dev 取新版**干净源码**覆盖 `packages/appflowy-editor`（或新拉一份做对照）。此时本地 DAYZ-PATCH 标记与改动会被新版冲掉。
2. **按 ID 重放 patch**：对每个仍有效的 patch ID，以其 patch 文件（见下）`git apply --3way <Pxxx>.patch` 重放到新基线；冲突按 3way 标记人工解决。
3. **对账**：跑 `bash scripts/check_patches.sh`。
   - 「有记录无标记」告警 = 该 patch 被新基线冲掉且尚未重贴 → 必须重贴或确认废弃。
   - 「漏记」报错 = 重贴时标记/台账没对齐 → 修正。
4. **更新台账**：更新 `packages/CHANGELOG.md` 头部的**基线版本号**为新版本；对已合并入上游的 patch，将其台账条目标注「已合并上游 / 已废弃」并从代码移除标记（届时脚本对该 ID 报告告警属预期，可在台账注明忽略）。
5. **提交**：按 AGENTS.md 约定，包相关代码 + CHANGELOG + `pubspec.lock` 作为独立 commit。

patch 文件（可选落地于 `packages/appflowy-editor-patches/<Pxxx>.patch`）：
- 由 `git diff <干净基线> <含改动> -- <文件>` 生成，文件名即 patch ID，便于步骤 2 按 ID 重放。
- 当前阶段以「代码内成对标记 + CHANGELOG 台账」为主留痕手段；patch 文件目录在首次正式升级时再按需生成，避免与标记重复维护。

## 已知风险
- 标记漂移：上游大重构后注释可能落到错误位置，需人工核对，脚本只能保证「成对 + 在册」。
- ID 复用：废弃的 patch ID 不应被新 patch 复用（避免台账歧义），需人工守约。
- 告警疲劳：升级中途「有记录无标记」告警可能与正常的「已合并上游」混淆，靠台账条目状态注明区分。
