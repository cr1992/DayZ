# Spec 规范（DayZ · AI 执行版）

> **方法论规则的唯一真源 = [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)。**
> 本文件只放 **DayZ 专项 overlay**，**不复述规则**——历史上它曾是「Flutter 具体版」，与 kit 的「通用版」并存而 drift；
> 现已把规则统一收进 kit（含写时白名单默认 deny、`可改文件 ⊆ design 文件变更` 不变式等最新约定），本文降为薄 overlay。

## 规则看哪（都在 kit）

- 选档（精简/标准）、`R`/`NF`/`D` 编号、EARS 句式、任务卡字段、**验收抗规避（信任根）**、
  **可改文件 ⊆ design「## 文件变更」** 不变式、**硬执行闸**（死链/验收/关键词/白名单**默认 deny**+反馈模型）、
  归档（`archive_spec.sh`）、契约/不变式 spec、完整示例 —— **全在 [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)**。
- 闸的安装与用法（`install.sh --with-<agent>` / 兜底闸 / CI）—— [`../spec-kit/README.md`](../spec-kit/README.md)。
- 设计与缘由（为什么 deny、实操发现的问题、多-agent 适配）—— [`../spec-kit/docs/`](../spec-kit/docs/)。

## DayZ 占位映射（kit 是栈中立的，代入 DayZ 技术栈即可）

| kit 里的占位 | DayZ 实际 |
|---|---|
| `{测试运行器} {测试文件}` | `flutter test test/...` |
| 源码后缀 `.{ext}` / 目录 `src/` | `.dart` / `lib/` |
| 测试目录与命名 | `test/`，`*_test.dart`（白名单 hook 已按此约定自动放行） |
| 「状态容器 / 持久化层」等中性词 | 对应 DayZ 的状态方案、Drift + Repository 数据层 |

> 验收命令闸的「源码后缀」与白名单 hook 的「测试文件自动放行」已是 Dart 约定，无需再裁剪（见 `../spec-kit/README.md`「按你的技术栈裁剪」）。

## DayZ 专项约定（在通用规则之上的加法，记此以免污染通用 kit）

- **视觉验收的默认升级**：通用规则说「确实无法自动化的（视觉/真机/人因）走人工核查项，禁止用假装能测的 grep 凑数」。
  DayZ 在 UI 还原线把默认从 *default-人工* 升级为 *default-确定性闸（参数/几何断言）+ golden/SSIM 自动验，视觉模型/人眼仅标红终审、不阻断*——
  详见 [`design/10-ui-restore-and-design-sync.md`](./design/10-ui-restore-and-design-sync.md)，随 `design-sync-automation` spec 定稿。**「禁止假装能测的 grep」红线不变**。
- （后续 DayZ 专项约定追加于此；通用规则的改动一律去改 [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)，不在本文重复。）
