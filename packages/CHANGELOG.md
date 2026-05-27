# Changelog - Local Packages

记录 `packages/` 目录下本地包的修改历史。

## [2026-05-27]

### appflowy-editor
- **图片插入行为优化**：
  - 修复插入图片时光标未定位到图片下方段落的 Bug。
  - 支持在插入图片时，如果当前是空段落则直接替换为图片节点并在其后追加空段落；如果当前非空段落，则在下一行插入图片并再追加空段落。
  - 自动将光标（Selection）移动聚焦到新插入图片下方的空段落首部。

---

## [2026-05-24]

### appflowy-editor
- **包引入与最新 Flutter 版本兼容调整** (Commit: `eb2b46e`)：
  - 首次将 `appflowy-editor` 源码引入至本地 `packages/appflowy-editor`，以便进行定制和离线开发。
  - 针对 Flutter 最新 Stable 版本进行兼容性调整（调整 SDK 环境约束及相关第三方依赖版本）。
- **选择区命令修复与退格键删除逻辑优化** (Commit: `e9807c7`)：
  - 修复 Selection 移动命令中，当选区折叠且执行 forward/backward 移动时抛出 `UnimplementedError` 的 Bug。
  - 处理退格键删除无 delta 且非表格块的前一个节点时的光标回退逻辑。
