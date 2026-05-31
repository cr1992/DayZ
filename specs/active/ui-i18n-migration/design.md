---
作者：@Ray
创建日期：2026-05-31
最后更新：2026-05-31
文档状态：定稿
---

# 设计：ui-i18n-migration

## 技术决策

### D1 · 直接迁到 gen-l10n，不保留运行期兼容层
- **背景：** `AppStrings` 是 i18n 前的中文静态常量桶，无法随 locale 切换。
- **选择：** 所有生产 UI 调用点改为 `final l10n = AppLocalizations.of(context)`，默认文案在 build/show 方法内解析。
- **理由：** 符合 `docs/design/11` 的唯一来源约束；避免再维护一层无 context 的静态代理。
- **代价：** 少数组件构造函数的默认字符串参数需要改成 nullable，再在 build 期回填 l10n。

### D2 · 保留可注入字符串 API，只把默认值本地化
- **背景：** 一些组件允许调用方传自定义标题、label、语义标签。
- **选择：** 自定义字符串参数继续保留；当参数为 null 时使用 `AppLocalizations` 默认文案。
- **理由：** 不破坏既有可配置 API；页面级 spec 后续可传业务文案。
- **代价：** 部分字段从非空 `String` 变成 `String?`，组件内部需统一 resolve。

### D3 · 数量和相对时间走 ICU
- **背景：** `entryCount` / `yearsAgo` 旧实现手拼中文。
- **选择：** `entryCount(count)`、`yearsAgo(count)`、`galleryMoreCount(count)` 迁为 ARB ICU 方法。
- **理由：** 英文复数与数字格式必须由 locale 决定。
- **代价：** 少数测试期望需要从旧中文常量改为 `lookupAppLocalizations(locale)`。

### D4 · UI spec 规则修订与迁移同批完成
- **背景：** 迁移前活跃 UI spec 中仍有 `AppStrings` 旧约定，会继续污染后续实现。
- **选择：** 修改 DayZ overlay、i18n 设计文档和活跃 UI spec，把文案规则统一指向 ARB / `AppLocalizations`。
- **理由：** 代码迁移和执行规则必须同源，否则后续任务会回退。
- **代价：** 文档改动面较大，但只改约束文本，不改变页面视觉范围。

## 文件变更

- `lib/l10n/arb/app_zh.arb` 修改
- `lib/l10n/arb/app_en.arb` 修改
- `lib/l10n/gen/app_localizations.dart` 修改（生成）
- `lib/l10n/gen/app_localizations_zh.dart` 修改（生成）
- `lib/l10n/gen/app_localizations_en.dart` 修改（生成）
- `lib/ui/strings/app_strings.dart` 删除
- `lib/ui/widgets/*.dart` 修改
- `lib/ui/shell/*.dart` 修改
- `lib/ui/timeline/*.dart` 修改
- `lib/demo/*.dart` 修改
- `test/l10n/*.dart` 修改
- `test/ui/**/*.dart` 修改
- `test/demo/*.dart` 修改
- `test/app_router_mount_test.dart` 修改
- `docs/spec-guide-ai.md` 修改
- `docs/design/11-internationalization-and-localization.md` 修改
- `specs/README.md` 修改
- `specs/active/*/{requirement,design,tasks,verification}.md` 修改（UI spec 文案约束）

## 已知风险

- 迁移前活跃 UI spec 文档里旧 `AppStrings` 引用较多，需避免误改历史归档 spec。
- 测试 helper 若未挂 l10n delegate，会在迁移后暴露缺 delegate 的旧测试，需要同步补 wrapper。
