# Changelog - Local Packages

记录 `packages/` 目录下本地包的修改历史。

> **改动留痕约定**（详见 [`specs/archive/2026-05-29-appflowy-patch-tracking/`](../specs/archive/2026-05-29-appflowy-patch-tracking/)）：
> 对 vendored 包源码的每一处本地改动都分配一个稳定的 patch ID（`Pxxx`），
> 在源码处打成对标记 `// >>> DAYZ-PATCH[Pxxx]: 原因` … `// <<< DAYZ-PATCH[Pxxx]`，
> 并在本文件按下方「Patch 台账」格式登记（ID + 文件定位 + 原因 + 关联 + upstream）。
> 改动后必须运行 `bash scripts/check_patches.sh` 对账（退出 0 方可提交）。
>
> 基线版本：`appflowy_editor` **6.2.0**（pub.dev 干净源码快照）。
> 升级流程见 spec 的 `design.md`「上游同步 SOP」。

---

## Patch 台账（按 ID）

### P001 · 图片插入后聚焦下方空段落
- **文件定位：** `packages/appflowy-editor/lib/src/editor/block_component/image_block_component/image_upload_widget.dart` → `extension InsertImage on EditorState` 的 `insertImageNode`（`isParagraphEmpty` 分支起至 `transaction.afterSelection`）。
- **原因：** 方案 A（AppFlowy）图片交互弱项补足。原实现插入图片后光标未定位到图片下方段落；本改动在空段落场景直接替换为图片节点并在其后追加空段落，非空段落场景在下一行插入图片再追加空段落，并将光标聚焦到新空段落首部。
- **关联：** 方案 A 编辑器选型（[`specs/archive/2026-05-29-editor-research/`](../specs/archive/2026-05-29-editor-research/)）图片交互弱项。
- **upstream issue：** 暂无（待评估提 PR）。
- **引入提交：** `ab8eb40`（2026-05-27）。

### P002 · 选区折叠且无 delta 时不再抛 UnimplementedError
- **文件定位：** `packages/appflowy-editor/lib/src/editor/command/selection_commands.dart` → `moveCursor(...)` 的 `switch (range)` 三个分支（`character` / `word` / `line`）中 `delta == null` 的 `else` 子句（原 `throw UnimplementedError()`）。
- **原因：** 修复选区折叠且对当前无 delta 的节点执行 forward/backward 移动时抛 `UnimplementedError` 的崩溃；改为按方向退回首/尾偏移（forward→start、backward→end）。
- **关联：** Bug（编辑器内移动光标崩溃）。
- **upstream issue：** 暂无（待评估提 PR）。
- **引入提交：** `eb2b46e`（2026-05-24，随源码引入一并改入）。

### P003 · 退格删除无 delta 且非表格的前一节点时整块选中
- **文件定位：** `packages/appflowy-editor/lib/src/editor/editor_component/service/shortcuts/command/backspace_command.dart` → 退格处理逻辑中 `immediatePrev`（`node.previous`）判断分支。
- **原因：** 当前一节点无 delta（不可合并文本）且非 `TableBlockKeys.type` 表格块时，退格不直接合并删除，而是切到 block 选区类型并整块选中该前节点（`Selection.single` startOffset 0 / endOffset 1），返回 `KeyEventResult.handled`，避免误删/光标丢失。
- **关联：** Bug（退格删除前置非文本节点的光标回退逻辑）。
- **upstream issue：** 暂无（待评估提 PR）。
- **引入提交：** `eb2b46e`（2026-05-24，随源码引入一并改入）。

### P004 · 补 onFocusReceived 覆写以兼容最新 Flutter Stable
- **文件定位：** `packages/appflowy-editor/lib/src/editor/editor_component/service/ime/delta_input_service.dart` → `class DeltaTextInputService` 内新增 `@override bool onFocusReceived() => false;`。
- **原因：** 最新 Flutter Stable 的 `TextInputClient` 接口新增 `onFocusReceived`；6.2.0 干净源码未实现，导致按最新 SDK 编译报错。补一个返回 `false` 的覆写以恢复编译。
- **关联：** Flutter 最新 Stable 兼容性调整（见下方 [2026-05-24] 条目）。
- **upstream issue：** 暂无（属上游对新 SDK 的兼容滞后，可向 upstream 提 PR）。
- **引入提交：** `eb2b46e`（2026-05-24，随源码引入一并改入）。

> 说明：`delta_input_service.dart` 同提交内的其余 diff 仅为 `dart format` 风格差异（无逻辑改动），不分配 patch ID、不打标记。

---

## 变更历史（按日期）

## [2026-05-27]

### appflowy-editor
- **图片插入行为优化**（Patch: `P001`，Commit: `ab8eb40`）：
  - 修复插入图片时光标未定位到图片下方段落的 Bug。
  - 支持在插入图片时，如果当前是空段落则直接替换为图片节点并在其后追加空段落；如果当前非空段落，则在下一行插入图片并再追加空段落。
  - 自动将光标（Selection）移动聚焦到新插入图片下方的空段落首部。

---

## [2026-05-24]

### appflowy-editor
- **包引入与最新 Flutter 版本兼容调整**（基线 `appflowy_editor` 6.2.0；Commit: `eb2b46e`）：
  - 首次将 `appflowy-editor` 源码引入至本地 `packages/appflowy-editor`，以便进行定制和离线开发。
  - 针对 Flutter 最新 Stable 版本进行兼容性调整（调整 SDK 环境约束及相关第三方依赖版本）。
  - **Patch `P004`**：补 `DeltaTextInputService.onFocusReceived()` 覆写以兼容最新 Flutter Stable 的 `TextInputClient` 接口。
- **选择区命令修复与退格键删除逻辑优化**（Commit: `eb2b46e`，CHANGELOG 旧版误记为 `e9807c7`，实为随源码引入一并改入）：
  - **Patch `P002`**：修复 Selection 移动命令中，当选区折叠且执行 forward/backward 移动时抛出 `UnimplementedError` 的 Bug。
  - **Patch `P003`**：处理退格键删除无 delta 且非表格块的前一个节点时的光标回退逻辑。
