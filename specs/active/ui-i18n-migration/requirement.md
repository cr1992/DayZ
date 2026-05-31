---
作者：@Ray
创建日期：2026-05-31
最后更新：2026-05-31
文档状态：定稿
---

# ui-i18n-migration（UI 文案迁移到 gen-l10n）

## 背景

DayZ 已接入 Flutter 官方 `gen-l10n`，但早期 UI kit / shell / timeline 仍通过 `lib/ui/strings/app_strings.dart` 提供中文静态常量，导致英文 locale 下仍显示中文，也让后续 UI spec 容易沿用旧约定。本 spec 收尾迁移：现有 UI 用户可见文案全部进入 `lib/l10n/arb/`，运行期经 `AppLocalizations.of(context)` 取用；未来 UI 相关 spec 默认使用国际化。

## 范围外

- SHALL NOT 新增语言，仍只维护 zh / en。
- SHALL NOT 改动非 UI 文案策略、数据层、加密层、备份层。
- SHALL NOT 重做页面级视觉还原；本 spec 只迁移文案来源。

## 功能需求

### R1 · 旧 AppStrings 文案进入 ARB
系统 SHALL 将 `AppStrings` 中仍被 UI 使用的用户可见文案迁入 `app_zh.arb` 与 `app_en.arb`，两份 key 集合保持一致。
- 前提：运行 `flutter gen-l10n`。
- 操作：生成 `AppLocalizations`。
- 结果：所有迁移文案都有 zh/en 强类型 getter 或 ICU 方法。

### R2 · UI 运行期按 locale 显示
系统 SHALL 让现有 UI 组件、shell、timeline、demo 的用户可见文案经 `AppLocalizations.of(context)` 取用。
- 前提：App locale 为 en。
- 操作：渲染相关 UI。
- 结果：默认文案、按钮、语义标签、toast/sheet 默认标签、路由占位页等显示英文；zh locale 下显示中文。

### R3 · 移除 lib 对 AppStrings 的依赖
`lib/` 下生产代码 MUST NOT import 或引用 `AppStrings`；旧文件可删除，或仅在无生产引用时保留为迁移说明。
- 前提：迁移完成。
- 操作：搜索 `lib/`。
- 结果：无 `AppStrings.` 使用点，无 `ui/strings/app_strings.dart` import。

### R4 · 未来 UI spec 默认国际化
UI 相关 spec 与 DayZ overlay SHALL 明确：新增/修改用户可见文案必须写入 `lib/l10n/arb/app_zh.arb` 与 `app_en.arb`，并通过 `AppLocalizations.of(context)` 使用；不得再向 `AppStrings` 追加文案。
- 前提：新建或修改 UI spec。
- 操作：编写需求/设计/任务。
- 结果：文案约束指向 gen-l10n / ARB，而不是 `AppStrings`。

## 非功能需求

### NF1 · 翻译完整性
`app_zh.arb` 与 `app_en.arb` 的消息 key 集合 MUST 完全一致。

### NF2 · 行为可回归
迁移后的 widget / shell 测试 MUST 在至少 en locale 下验证旧中文默认文案不再固定显示。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 只迁移 UI 文案来源，不碰敏感数据。 |
| 权限 | 否 | 不申请系统权限。 |
| 无障碍 | 是 | 语义标签从中文常量迁到 locale 文案，会影响读屏输出。 |
| 性能 | 否 | 文案查表无新增性能阈值。 |
| 多端兼容 | 是 | 文案和 Material 本地化需在支持 locale 下跨端一致。 |

→ 命中无障碍 / 多端兼容，按标准档执行。
