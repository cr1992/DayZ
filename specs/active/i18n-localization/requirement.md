---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
---

# i18n-localization（国际化基础设施 + 中英双语）

## 背景

DayZ 做国际化，取向定为：Flutter 官方 `flutter gen-l10n` + `.arb` 生成 `AppLocalizations`，所有用户可见文案经 `AppLocalizations.of(context)` 取用，MVP 首发简体中文（zh）+ 英文（en）双语全量，日期/数字/复数走 `package:intl` 与 ICU。冻结决策见 `docs/design/11-internationalization-and-localization.md`。

本 spec 落地其**基础设施**：生成管线 + `MaterialApp` 接线 + locale 解析（跟随系统 / 回退 zh）+ 手动切换 controller + 中英双 arb（seed 文案）+ 翻译完整性校验 + 「所有 UI 文案走 `AppLocalizations`」的横切契约。

## 范围外

- **语言切换的设置页 UI**——本 spec 只交付 `LocaleController`（状态+持久化）与 `MaterialApp` 接线，切换控件归 `settings-screen`。
- **RTL 完整支持**——MVP 两语言均 LTR；布局 SHOULD 用 `EdgeInsetsDirectional`（RTL-ready），但不做 RTL 专项验证。
- **zh / en 之外的语言**——加一个 `app_xx.arb` 即可扩展，非本期。
- **各屏全量文案抽取**——随各页面级 spec 落地；本 spec 只提供基础设施 + seed 文案 + 契约。

## 功能需求

### R1 · l10n 生成管线（可复现）
系统 SHALL 经 Flutter 官方 `flutter gen-l10n`（基于仓库根 `l10n.yaml`）从 `lib/l10n/arb/` 的 arb 生成 `AppLocalizations`（`lib/l10n/gen/`），生成产物纳入版本库且 MUST NOT 被 gitignore。
- 前提：`l10n.yaml` + 中英 arb 就位。
- 操作：运行生成命令（`flutter gen-l10n`，或 `flutter pub get` 触发 `generate: true`）。
- 结果：`lib/l10n/gen/app_localizations.dart`（+ `_zh` / `_en`）生成，含 `AppLocalizations` 类与各 key 的强类型取值方法；产物已被 git 跟踪、未被 gitignore；重复执行幂等。

### R2 · MaterialApp 本地化接线
系统 SHALL 在 `MaterialApp` 挂 `localizationsDelegates`（`AppLocalizations.delegate` + `GlobalMaterialLocalizations` / `GlobalWidgetsLocalizations` / `GlobalCupertinoLocalizations`）与 `supportedLocales = [zh, en]`。
- 前提：App 任意 widget 树内。
- 操作：`AppLocalizations.of(context)`。
- 结果：取到非空 `AppLocalizations`，其文案随当前 locale 切换；Material / Cupertino 内建控件（日期选择器、文本选择菜单等）随 locale 本地化。

### R3 · locale 解析（跟随系统 + 回退 zh）
系统 SHALL 在运行期按"跟随系统"解析 locale：系统 locale ∈ `supportedLocales` 则采用；否则回退基线语言 `zh`。
- 前提：设备系统语言为某值。
- 操作：启动 App。
- 结果：系统=en → 英文；系统=zh → 中文；系统=不支持的语言（如 fr）→ 回退中文。

### R4 · 中英双语 arb（key 对齐 + seed 文案）
系统 SHALL 提供 `app_zh.arb`（template）与 `app_en.arb`，两份 **key 集合完全一致**；至少含 seed 文案（App 标题等基础串）与一条 ICU `plural` 示例（验证复数链路）。
- 前提：arb 目录。
- 操作：检视两份 arb。
- 结果：zh/en key 一一对应、无缺漏；含至少一条 `plural` 文案；占位符在 template 有 `@key` 元数据。

### R5 · locale 手动覆盖 + 持久化（LocaleController）
系统 SHALL 提供 `LocaleController`：可在 `跟随系统 / zh / en` 间切换；用户选择持久化、重启沿用；切换即时生效（无需重启）。
- 前提：App 运行中。
- 操作：经 controller 切到指定语言。
- 结果：界面即时切换；偏好写入持久化层；重启后 `init()` 优先采用持久化值，无值则回退"跟随系统"。

### R6 · 文案唯一来源
`lib/` 下用户可见文案 MUST 经 `AppLocalizations.of(context)` 取用，屏内 MUST NOT 出现硬编码用户可见字面量；可数/相对时间 MUST 用 arb `plural`，MUST NOT 手拼；日期/数字 MUST 走 `package:intl`（按 locale）。
- 前提：任一含用户可见文案的 widget。
- 操作：渲染该 widget。
- 结果：文案来自 `AppLocalizations`；切 locale 文案随变；无裸字面量（本 spec 自带 demo 入口可示范，全量回归随各屏 spec 落地）。

## 非功能需求

### NF1 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上 locale 解析与双语显示一致：zh/en 文案正确切换；中文经 `fontFamilyFallback` 落系统 CJK 字（见 `design-tokens-theme` D3 字体策略），Latin 走品牌字。

### NF2 · 翻译完整性（key 对齐）
`app_zh.arb` 与 `app_en.arb` 的 key 集合 MUST 完全一致——无缺失翻译、无孤儿 key（`@`/`@@` 元数据键与占位符定义除外）。此为可自动校验的硬不变式。

### NF3 · 生成确定性 / 可复现
对同一组 arb，`flutter gen-l10n` MUST 产出一致的 `AppLocalizations`（无随机/时间戳序），使"生成后 `git diff` 为空"可作为不漂移的 CI 校验。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 文案与 locale 偏好，不碰密钥/加密/敏感数据（locale 偏好非敏感）。 |
| 权限 | 否 | 不申请任何系统权限。 |
| 无障碍 | 否 | 不新增对比度/语义标签等可度量无障碍约束。 |
| 性能 | 否 | 生成在构建期；运行期为查表取值，无可度量运行阈值。 |
| 多端兼容 | **是** | locale 解析、CJK 字体回退、双语显示需 iOS/Android 各端验证（NF1）。 |

→ 命中「多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。文件变更落在 `pubspec.yaml` / `l10n.yaml`（根）+ `lib/`（主 app 模块），单模块、不跨模块。
