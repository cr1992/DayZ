---
作者：@Ray
创建日期：2026-05-29
---

# vendored 第三方包本地改动留痕

## 背景
DayZ 把 `appflowy_editor`（6.2.0）以**纯源码 vendored** 在 `packages/appflowy-editor`，经 pubspec `dependency_overrides` path 引用。方案 A 已选定，其图片交互等弱项需**直接改 vendored 源码**补足，已改过数次。两个命门必须补：

1. 代码里没有改动标记 → 升级 appflowy 时会**静默冲掉**本地改动且无人察觉。
2. 没有「标记 ↔ 记录」对账机制 → 改了忘记记，历史改动漏档。

需要一套「成对标记 + 台账登记 + 脚本对账」的留痕机制，让每处本地改动都可被定位、可被审计、升级时不被悄悄丢失。

## 范围外
- 不为 vendored 包做自动化的「升级即重放 patch」工具（仅在 design 写人工 SOP）。
- 不替换 vendored 方式本身（path override 维持不变）。
- 不追踪非 `packages/appflowy-editor/lib` 之外目录的改动；纯 `dart format` 风格差异不分配 ID、不打标记。
- 不强制要求每个 patch 立即提 upstream PR（仅作为原则写入 design）。

## 需求

### R1 · 代码内成对标记
对 vendored 包源码的每一处本地改动，MUST 在源码处打成对标记：
`// >>> DAYZ-PATCH[Pxxx]: 原因` … `// <<< DAYZ-PATCH[Pxxx]`，每个 patch 一个稳定 ID（`P` + 数字）。
- 前提：在 `packages/appflowy-editor/lib/**` 改了源码逻辑。
- 操作：在改动区间首尾加成对注释标记。
- 结果：每个 `>>>` 都有同 ID 的 `<<<` 闭合；同一逻辑改动可跨多处但共用一个 ID。

### R2 · CHANGELOG 台账登记
`packages/CHANGELOG.md` MUST 为每个 patch ID 记录：ID + 文件定位（路径 + 函数/符号）+ 原因 + 关联（spec/bug）+ upstream issue（如有）。
- 前提：代码已打 P 标记。
- 操作：在 CHANGELOG「Patch 台账」补对应条目。
- 结果：代码中出现的每个 patch ID 都能在 CHANGELOG 找到一条带定位信息的记录。

### R3 · 脚本对账
`scripts/check_patches.sh` SHALL 校验：
- 前提：代码与 CHANGELOG 已就位。
- 操作：运行 `bash scripts/check_patches.sh`。
- 结果：
  1. 标记成对（每个 `>>>` 配同 ID `<<<`，不成对即报错 exit 1）；
  2. 代码每个 patch ID 必在 CHANGELOG（否则=漏记，报错 exit 1）；
  3. CHANGELOG 有记录但代码无标记 → **告警**（=被升级冲掉或已合并上游），exit 0。

### R4 · 历史改动回填
现有历史改动 MUST 被分配 ID 并补齐标记与台账定位，确保 CHANGELOG 的 ID 与代码标记一一对齐。
- 前提：vendored 包已有未留痕的历史改动（来自提交 `eb2b46e`、`ab8eb40`）。
- 操作：用干净基线比对定位实际改动行，补成对标记并登记台账。
- 结果：`check_patches.sh` 对当前仓库退出 0。

### R5 · 约定固化与升级 SOP
项目约定 MUST 写明「改 `packages/` 下 vendored 包须打标记 + 记 CHANGELOG + 跑脚本」；升级流程 MUST 有文档化 SOP（干净基线 + patch 重放 + 对账）。
- 前提：团队/AI 后续会再改 vendored 源码或升级版本。
- 操作：在 `AGENTS.md` 加约定，在 design.md 写升级 SOP。
- 结果：后续改动有明确可遵循的流程，升级时本地改动不被静默丢失。
