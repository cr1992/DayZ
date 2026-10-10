---
作者：@Ray
创建日期：2026-10-10
---

# 设计：ui-kit-patch

## 技术决策

### D1 · 左箭头取屏源 path，命名对齐 `chevronRightPath`
- **背景：** 屏源 `onthisday.html` / `reader.html` / `settings.html` 等的 `.app-top [data-nav-back]` 一律是 `<path d="m15 5-7 7 7 7"/>`；lucide 原版 chevron-left 是 `m15 18-6-6 6-6`，两者形状一致但尺寸不同。
- **选择：** `DayzIcons.chevronLeftPath = 'm15 5-7 7 7 7'`（屏源为真源，不取 lucide 原版）；往年今日 `_TopIconButton(path: DayzIcons.chevronLeftPath)`，删掉 `_OnThisDayIcons`。
- **理由：** 与设计稿逐字一致，像素对齐不需要再调；命名与已有 `chevronRightPath` 成对。
- **代价：** 与 `chevronRightPath`（lucide `m9 18 6-6-6-6`）不是严格镜像；两者都按各自屏源，接受。

### D2 · 图位抽成 `DayzImageSlot`：底色占位 + `frameBuilder` 淡入 + `errorBuilder` 兜底
- **背景：** 卡片封面和相册格子各自写了 `ColoredBox(accentSoft2) + Image`，两处要补同一套帧 / 错误处理。thumbnail-provider 的图源就绪前「无帧」、失败时 `ImageStream` 报错（thumbnail-provider R2 / R4）。
- **选择：** 新增 `lib/ui/widgets/dayz_image_slot.dart`：
  ```dart
  class DayzImageSlot extends StatelessWidget {
    const DayzImageSlot({super.key, required this.image, this.fit = BoxFit.cover});
    static const Key placeholderKey; // 失败兜底的占位
  }
  ```
  外层 `ColoredBox(accentSoft2)` 常驻作底色；`Image.frameBuilder`：同步命中缓存（`wasSynchronouslyLoaded`）直接出图，否则包 `AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: dayzMotionDuration(context))`；`errorBuilder` 返回带 `placeholderKey` 的同色 `ColoredBox`。`DayzEntryCard` 封面与 `_DayzGalleryTile` 改用它；barrel `components.dart` 导出。
- **理由：** 一处实现两处共用，阅读屏经 `DayzGallery` 也自动受益；底色常驻让「无帧」时天然显示占位，不需要额外分支；`errorBuilder` 接住错误后 `Image` 不再把异常交给 `FlutterError`。
- **代价：** 多一个导出组件；淡入不带曲线 token（`DayzMotion.ease` 目前是 CSS 字符串，见 README「design-tokens-theme 生成器收口」），用默认线性曲线。

### D3 · 收藏星语义规则集中在 `DayzFavoriteStar`
- **背景：** `DayzFavoriteStar` 与 `DayzEntryCard` 的星位各自算语义标签，都只按 `isFavorite` 选「收藏 / 取消收藏」，没区分可点与只读。
- **选择：** `DayzFavoriteStar` 新增静态 `semanticsLabelFor(l10n, {isFavorite, interactive})`：可点 → `favorite` / `unfavorite`；只读 → 已收藏返回新 key `favorited`（zh「已收藏」/ en「Favorited」），未收藏返回 null。只读态：`IconButton.tooltip = null`，整颗星包 `ExcludeSemantics`，外层 `Semantics(container: true, button: false, label: …)` 仅在标签非空时出现。`DayzEntryCard` 的星位改用同一个静态方法与同一规则。
- **理由：** 规则只写一处，卡片与独立星不会再漂移。
- **代价：** 往年今日 a11y 测试原先断言只读星读作「取消收藏」，需同步改断言（`test/ui/onthisday/onthisday_a11y_test.dart`）。

### D4 · `DayzSheet.actions(title:)` + `DayzSheetItem.iconPath / iconMarkup`
- **背景：** 设计稿 `DZ.sheet({title})` 在 grip 下出 `.sheet-head .t`；`.sheet-item > .ic svg` 为 21px lucide 描边图标。
- **选择：** `DayzSheet.actions` 加可选 `String? title`，传给 `_DayzSheetItems`，在列表前渲染 `_DayzSheetTitle`：`Semantics(header: true)` + 居中 `Text`，样式 `context.dayzText.h2.copyWith(fontSize: 17, fontWeight: w600, letterSpacing: -0.17, color: ink)`，padding `fromLTRB(s3, 2, s3, s3)`（`.sheet-head`）。`DayzSheetItem` 加 `String? iconPath`、`String? iconMarkup`（与 `icon` 三选一，assert），`_DayzSheetLeading` 依次判断：`iconMarkup` → `DayzIcon(markup, size: 21, color: tone 色)`，`iconPath` → `DayzIcon.path(...)`，`icon` → 原 `Icon`。`.sep()` 构造同步补 null。
- **理由：** 只做加法，存量调用方（settings / reader / onthisday / demo）零改动。
- **代价：** `DayzSheetItem` 有三个互斥图标字段，靠 assert 约束而非类型约束。

## 文件变更

- `lib/ui/widgets/dayz_icons.dart`                 修改（D1：`chevronLeftPath`）
- `lib/ui/onthisday/onthisday_screen.dart`         修改（D1：返回钮改用 `DayzIcons.chevronLeftPath`，删私有 `_OnThisDayIcons`）
- `lib/ui/widgets/dayz_image_slot.dart`            新建（D2）
- `lib/ui/widgets/dayz_entry_card.dart`            修改（D2 封面改用 `DayzImageSlot`；D3 星位语义）
- `lib/ui/widgets/dayz_gallery.dart`               修改（D2 格子改用 `DayzImageSlot`）
- `lib/ui/components.dart`                         修改（D2：导出 `dayz_image_slot.dart`）
- `lib/ui/widgets/dayz_favorite_star.dart`         修改（D3）
- `lib/l10n/arb/app_zh.arb`、`lib/l10n/arb/app_en.arb`  修改（D3：`favorited`）
- `lib/l10n/gen/app_localizations*.dart`           修改（gen-l10n 产物）
- `lib/ui/shell/dayz_sheet.dart`                   修改（D4）
- `test/ui/widgets/dayz_icons_test.dart`           新建（T1）
- `test/ui/onthisday/onthisday_screen_test.dart`   修改（T1：返回钮图标断言）
- `test/ui/widgets/dayz_image_slot_test.dart`      新建（T2）
- `test/ui/widgets/dayz_favorite_star_test.dart`   修改（T3）
- `test/ui/onthisday/onthisday_a11y_test.dart`     修改（T3：只读星断言改为「已收藏」）
- `test/ui/shell/dayz_sheet_test.dart`             修改（T4）
- `specs/active/ui-kit-patch/`                     新建（本 spec）
- `specs/README.md`                                修改（进行中表加一行；删掉「待立 spec」里「ui-kit 小补」那条）

## 已知风险

- **选档存疑（无障碍维度）：** R3 改的是读屏语义，按 spec-guide §0 字面可视作命中「无障碍」。本 spec 判为否（只更正既有语义、无新增约束、单任务可测），按 README「待立 spec」原定精简档立项；若 @Ray 判为命中，按棘轮只做加法升标准档（补文件头文档状态、`## 非功能需求`、verification.md）。
- **屏幕层仍用 Material 图标：** 阅读屏顶栏返回 / ⋯ 仍是 `Icons.*`，各屏 sheet 也还没用标题 / `DayzIcons` 图标；本 spec 只提供能力，替换归各屏 spec。
- **golden 基线：** 卡片封面 / 相册格子多了一层 `AnimatedOpacity`，出帧前截 golden 会是纯底色；现有 golden 都在 settle 后截图，预计不受影响，若受影响按各屏基线流程更新。
- **淡入曲线：** 暂用线性曲线，待 `DayzMotion.ease` 生成为 Flutter `Curve` 后再换。
