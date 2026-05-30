# 11 · 国际化与本地化方案

> 状态：冻结决策（取向定稿；落地细节随 `i18n-localization` spec 迭代）
> 作者：@Ray
> 创建：2026-05-30
> 定位：回答一个结构性问题——DayZ 的 UI 文案、日期、数字、复数怎么做国际化，使「加一门语言」不是大返工。
> 配套真源：落地清单见 `specs/active/i18n-localization/`；字体回退策略见 `docs/design/10-ui-restore-and-design-sync.md` §2 与 `design-tokens-theme`（D3）。

> **会变的东西一律以 arb 为准、本文不枚举**：支持哪些语言、有哪些文案 key、每条翻译是什么——指向真源 `lib/l10n/arb/`，本文只给取向与约束。

-----

## 0. 一句话结论（先记这句，其余都是展开）

DayZ 采用 **Flutter 官方 `flutter gen-l10n` + `.arb`** 的国际化方案：所有用户可见文案走 `.arb` → 生成 `AppLocalizations` → `AppLocalizations.of(context)` 取用；MVP 首发**简体中文（zh）+ 英文（en）双语全量**；日期/数字/复数走 `package:intl` 与 ICU message format。

## 1. 技术选型

- **工具链 = Flutter 官方 `flutter gen-l10n`**（基于 `l10n.yaml`），**不引第三方**（slang / easy_localization 等）。理由：官方零额外运行期依赖、与 `flutter_localizations` / Material / Cupertino 本地化无缝、生成代码同源依赖 `intl`、社区与文档最厚。
- **委托链**：`MaterialApp.localizationsDelegates` 挂 `AppLocalizations.delegate` + `GlobalMaterialLocalizations` / `GlobalWidgetsLocalizations` / `GlobalCupertinoLocalizations`；`supportedLocales = [Locale('zh'), Locale('en')]`。
- **日期 / 数字 = `package:intl`**（`DateFormat` / `NumberFormat`，按当前 locale）；**MUST NOT** 自拼 `'2026年5月'` / `'3 条'`。
- **复数 / 选择 = arb 的 ICU `plural` / `select`**，不在 Dart 里手拼分支。

## 2. 目录与产物布局

```text
l10n.yaml                              # gen-l10n 配置（仓库根）
lib/l10n/
├── arb/
│   ├── app_zh.arb                     # template-arb-file（母语中文，元数据/占位符描述源）
│   └── app_en.arb                     # 英文，key 集合与 zh 完全一致
└── gen/                               # 生成产物（纳入版本库，可复现）
    ├── app_localizations.dart         # AppLocalizations 抽象类 + delegate
    ├── app_localizations_zh.dart
    └── app_localizations_en.dart
```

约束（细节落 spec）：
- **template = `app_zh.arb`**（产品母语中文，文案先写中文，占位符 `@key` 元数据在此登记）。
- **生成产物纳入版本库、MUST NOT gitignore**：与 `assets.gen.dart`（`docs/design/07` / `assets-management`）同一策略——任意开发者/CI 跑同一条生成命令产出一致，IDE 无需先跑生成即可解析。
- **`synthetic-package` 路线已弃用**：用 `synthetic-package: false` + 显式 `output-dir: lib/l10n/gen`，import `package:dayz/l10n/gen/app_localizations.dart`（具体配置项以 `i18n-localization` design D2 为准，执行时按本机 Flutter 版本核实）。

## 3. locale 解析与切换策略

- **默认跟随系统**：系统 locale ∈ `supportedLocales` 则采用；否则**回退 `zh`**（基线语言）。
- **手动覆盖 + 持久化**：提供 `LocaleController`（状态 + 持久化），用户可在 `跟随系统 / zh / en` 间切换，选择持久化、重启沿用。**切换的 UI 控件归 `settings-screen`**（本方案只提供 controller + 接线，不在 i18n 层造设置页）。
- **RTL**：MVP 两种语言均 LTR，不引入 RTL 专项；但布局 **SHOULD** 用 `EdgeInsetsDirectional` + `start/end`（零成本 RTL-ready）。

## 4. 横切契约（对所有 UI / 屏级 spec 生效）

这是本方案影响面最大的部分——它约束**每一个屏怎么写 `Text`**：

1. **文案唯一来源 = arb**：`lib/` 下一切用户可见文案 **MUST** 经 `AppLocalizations.of(context)` 取用；屏内 **MUST NOT** 出现硬编码用户可见字面量（中/英皆然）。widget 测试经 `AppLocalizations` 取键、不写裸字面量。
2. **双语对齐**：新增任一文案 **MUST** 同时在 `app_zh.arb` 与 `app_en.arb` 补齐——两份 arb 的 **key 集合必须完全一致**（无缺翻译、无孤儿 key），此为可自动校验的硬不变式。
3. **复数走 ICU**：可数名词/相对时间（「N 篇」「N 年前」等）**MUST** 用 arb `plural`，**MUST NOT** 手拼。
4. **日期/数字走 intl**：见 §1。
5. **合规红线文案**（如 settings 的「主密码锁不住照片」「已加密」只读说明）同样入 arb，双语都要有审计落点。

## 5. 范围与分期

- **本期（`i18n-localization` spec）**：生成管线 + 中英双 arb（seed 文案）+ `MaterialApp` 接线 + locale 解析（跟随系统/回退 zh）+ `LocaleController`（状态+持久化）+ key 对齐校验 + Debug Home 语言切换 demo + 横切契约落档。
- **范围外/后续**：① 语言切换的设置页 UI（归 `settings-screen`）；② RTL 完整支持；③ zh/en 之外的语言（加一份 `app_xx.arb` 即可，非本期）；④ 各屏的全量文案抽取（随各屏 spec 落地，本期只 seed）。

-----

## 维护本文件

- 本文是 i18n 取向的**冻结决策**，只放取向与横切约束。支持语言清单、文案 key、翻译内容一律以 `lib/l10n/arb/` 为真源，本文不枚举。
- 落地细节（`l10n.yaml` 具体配置、任务拆分、验收）下沉到 `specs/active/i18n-localization/` 四件套，本文只留指针与跨 spec 约束。
