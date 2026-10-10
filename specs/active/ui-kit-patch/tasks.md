---
作者：@Ray
创建日期：2026-10-10
---

# 任务列表：ui-kit-patch

## 依赖速览
> 以各任务 inline「同 spec 依赖」字段为准；跨 spec 依赖以 README「依赖」列为准。
T1, T2, T3, T4（彼此独立，可并行）

-----

- [x] T1 · `DayzIcons` 补左箭头，往年今日返回钮改用

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** ui-kit-components：`DayzIcons` / `DayzIcon` ｜ **关联需求：** R1 ｜ **依据设计：** D1 ｜ **可改文件：** `lib/ui/widgets/dayz_icons.dart`、`lib/ui/onthisday/onthisday_screen.dart` ｜ **验收基建：** `test/ui/widgets/dayz_icons_test.dart`、`test/ui/onthisday/onthisday_screen_test.dart`

### 背景
往年今日在 ui-kit 补齐前用屏内私有 `_OnThisDayIcons.backPath`。本任务只加常量并替换这一处；其他屏的 Material 返回图标不在本任务。

### 实施
1. `DayzIcons.chevronLeftPath = 'm15 5-7 7 7 7'`（屏源 `.app-top [data-nav-back]`）。
2. 往年今日 `_TopIconButton(path: DayzIcons.chevronLeftPath)`，删除 `_OnThisDayIcons`。

### 验收标准（做完即止）
- `DayzIcon.path(DayzIcons.chevronLeftPath)` 渲染出 `SvgPicture`，标记为 `<path d="m15 5-7 7 7 7"/>`（自动，R1）。
- 往年今日返回钮内的 `DayzIcon.markup` 等于 `DayzIcons.chevronLeftPath` 包成的 `<path>`（自动，R1）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub test/ui/widgets/dayz_icons_test.dart test/ui/onthisday/onthisday_screen_test.dart
  ```
  （断言渲染出的 `DayzIcon` 标记与 `SvgPicture` 存在；不 grep 源码）

### 验收记录
```
日期：2026-10-10
自动：`flutter test --no-pub test/ui/widgets/dayz_icons_test.dart test/ui/onthisday/onthisday_screen_test.dart` 通过（8 tests：chevronLeftPath 渲染为 `<path d="m15 5-7 7 7 7"/>` + SvgPicture；往年今日返回钮 DayzIcon 标记等于该常量）；`flutter analyze --no-pub` 四文件 No issues。
人工：N/A
```

-----

- [x] T2 · 卡片封面 / 相册格子补 `frameBuilder` 淡入与 `errorBuilder` 兜底

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** design-tokens-theme：`dayzMotionDuration` / `DayzMotion.dur` / `accentSoft2` ｜ **关联需求：** R2 ｜ **依据设计：** D2 ｜ **可改文件：** `lib/ui/widgets/dayz_image_slot.dart`、`lib/ui/widgets/dayz_entry_card.dart`、`lib/ui/widgets/dayz_gallery.dart`、`lib/ui/components.dart` ｜ **验收基建：** `test/ui/widgets/dayz_image_slot_test.dart`

### 背景
解密图源就绪前无帧、失败时报错（thumbnail-provider R2 / R4）。本任务只在 widgets 层补占位 / 淡入 / 兜底，时间线、往年今日、阅读屏的相册自动受益，不改各屏。`DayzEntryCard` 星位语义归 T3，本任务只动封面图位。

### 实施
1. 新建 `DayzImageSlot`（D2）：底色 `accentSoft2` 常驻；`frameBuilder` 非同步加载时 `AnimatedOpacity(frame == null ? 0 : 1, dayzMotionDuration(context))`；`errorBuilder` 返回带 `placeholderKey` 的同色占位。
2. `DayzEntryCard` 封面、`_DayzGalleryTile` 改用 `DayzImageSlot`；`components.dart` 导出。

### 验收标准（做完即止）
- 可控图源未给帧：`AnimatedOpacity.opacity == 0`，底色为 `accentSoft2`（自动，R2）。
- 给帧后：`opacity == 1`、`duration == DayzMotion.dur`；开启 `disableAnimations` 时 `duration == Duration.zero`（自动，R2）。
- 图源失败：出现 `DayzImageSlot.placeholderKey`，`tester.takeException()` 为 null（自动，R2）。
- `DayzEntryCard(cover:)` 与 `DayzGallery(images:)` 的图位都经 `DayzImageSlot` 渲染（自动，R2）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub test/ui/widgets/dayz_image_slot_test.dart
  ```
  （用可控 `ImageStreamCompleter` 驱动无帧 / 出帧 / 失败，断言不透明度、时长、占位与异常；不 grep 源码）

### 验收记录
```
日期：2026-10-10
自动：`flutter test --no-pub test/ui/widgets/dayz_image_slot_test.dart` 通过（5 tests：无帧 opacity 0 + 底色 accentSoft2；出帧 opacity 1、duration == DayzMotion.dur；disableAnimations 时 duration == 0；图源失败出 placeholderKey 且 takeException 为 null；卡片封面 1 个 / 相册 2 格均经 DayzImageSlot）；回归 `flutter test --no-pub test/ui/widgets test/ui/onthisday test/ui/timeline test/ui/reader` 140 全绿；`flutter analyze --no-pub` 五文件 No issues。
人工：N/A
```

-----

- [x] T3 · 收藏星只读态读状态而非动作

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** i18n-localization：gen-l10n 流程 ｜ **关联需求：** R3 ｜ **依据设计：** D3 ｜ **可改文件：** `lib/ui/widgets/dayz_favorite_star.dart`、`lib/ui/widgets/dayz_entry_card.dart`、`lib/l10n/arb/app_zh.arb`、`lib/l10n/arb/app_en.arb`、`lib/l10n/gen/app_localizations*.dart` ｜ **验收基建：** `test/ui/widgets/dayz_favorite_star_test.dart`、`test/ui/onthisday/onthisday_a11y_test.dart`

### 背景
往年今日 / 时间线卡片的星只展示状态（不传回调），却读作「取消收藏」并标为按钮。本任务在 `DayzFavoriteStar` 集中语义规则，卡片星位复用；`DayzEntryCard` 封面图位归 T2，本任务只动星位语义。

### 实施
1. arb 两份补 `favorited`（zh「已收藏」/ en「Favorited」），跑 `flutter gen-l10n`。
2. `DayzFavoriteStar.semanticsLabelFor(l10n, isFavorite:, interactive:)`；只读态去 tooltip、`ExcludeSemantics`、仅在标签非空时包 `Semantics(container: true, button: false, label:)`。
3. `DayzEntryCard` 星位改用同一规则；往年今日 a11y 测试改断言「已收藏」。

### 验收标准（做完即止）
- 只读已收藏：存在标签为 `favorited` 的语义节点，且无按钮标志、无 tooltip；`unfavorite` 标签不存在（自动，R3）。
- 只读未收藏：`favorite` / `unfavorite` / `favorited` 标签都不存在（自动，R3）。
- 可点击：未收藏读 `favorite`、已收藏读 `unfavorite`，带按钮标志，点击回调仍生效（自动，R3）。
- `DayzEntryCard` 只读已收藏星读 `favorited`、无按钮标志（自动，R3）。
- `bash scripts/check_arb_sync.sh` 通过（自动）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub test/ui/widgets/dayz_favorite_star_test.dart test/ui/onthisday/onthisday_a11y_test.dart
  bash scripts/check_arb_sync.sh
  ```
  （读语义树断言标签与 `SemanticsFlag.isButton`；不 grep 源码）

### 验收记录
```
日期：2026-10-10
自动：`flutter test --no-pub test/ui/widgets/dayz_favorite_star_test.dart test/ui/onthisday/onthisday_a11y_test.dart` 通过（11 tests：只读已收藏读 favorited、isButton=false、无 Tooltip、无 unfavorite；只读未收藏三种标签均不存在；可点击读 favorite / unfavorite 且 isButton=true、点击生效；卡片只读 / 可点击星同规则；往年今日只读星读「已收藏」）；`bash scripts/check_arb_sync.sh` 207 keys aligned；`flutter gen-l10n` 产物仅新增 favorited；回归 widgets / onthisday / timeline / reader 144 全绿；`flutter analyze --no-pub` 触及文件 No issues。
人工：N/A
```

-----

- [ ] T4 · `DayzSheet.actions` 可选标题 + `DayzSheetItem` 支持 `DayzIcons`

**同 spec 依赖：** 无 ｜ **跨 spec 依赖：** ui-kit-components：`DayzIcon` ｜ **关联需求：** R4 ｜ **依据设计：** D4 ｜ **可改文件：** `lib/ui/shell/dayz_sheet.dart` ｜ **验收基建：** `test/ui/shell/dayz_sheet_test.dart`

### 背景
设计稿 `DZ.sheet({title})` 出 `.sheet-head .t`；item 图标是 lucide 描边 svg。本任务只加能力，存量调用方不改。

### 实施
1. `DayzSheet.actions(..., String? title)` → `_DayzSheetItems(title:)`，列表前渲染 `_DayzSheetTitle`（`Semantics(header: true)`，`.sheet-head .t` 样式）。
2. `DayzSheetItem` 加 `iconPath` / `iconMarkup`（与 `icon` 互斥，assert）；`_DayzSheetLeading` 经 `DayzIcon` / `DayzIcon.path` 渲染，颜色随 tone，21px（`.sheet-item > .ic svg`）。

### 验收标准（做完即止）
- 带 `title` 打开：标题文本存在、带 `header` 语义、字号 17 / 字重 600（自动，R4）。
- 不带 `title`：不出现标题节点（自动，R4）。
- `iconPath` / `iconMarkup` 条目渲染 `DayzIcon`（标记分别等于 path 包装与原标记、颜色等于 tone 色）；`icon` 条目仍渲染 `Icon`（自动，R4）。

### 验收方式
- 自动：
  ```bash
  flutter test --no-pub test/ui/shell/dayz_sheet_test.dart
  ```
  （断言组件树与语义树；不 grep 源码）

### 验收记录
```
日期：—
自动：—
人工：N/A
```
