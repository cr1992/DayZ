# 编辑页对接手册（原生 ↔ 原型 差异 + 落地要求）

> 状态: 🚧 待原生落地（验收 checklist §6 全过后移入 `_archive/`，约定见 `docs/handoff/README.md`）
> 走查: 🔁 2026-06-04 复查——#1–#4 已对齐；#5 图片插入未落地（§5）；#6 代码块、#7 工具栏重排+标注块已定调，原型已落地、待原生跟进（§7/§8）。
> 受众:实现 Flutter 编辑页的原生 agent。覆盖代码区 `lib/ui/editor/*` + `lib/editor/*`。
> 真源:原型 `pages/screens/editor.html` + `pages/assets/editor.{css,js}`;基调见根 `CLAUDE.md` §设计基调 / §约定(Flutter 优先)。
> 背景:编辑器用 **AppFlowy Editor（方案 A）**,工具栏用 `MobileToolbarV2`。本文只覆盖**编辑页**,逐条列出当前原生实现与设计的差异、严重度、改法。

---

## 0. 结论速览
> **走查更新 2026-06-04**（对照 `lib/ui/editor/*` + `lib/editor/contract/*` 现状）：原生已修掉 **#1–#4**（色板 / meta 图标 / 日期·关闭图标 / 标题正文项全部对齐）；**#5「图片插入」设计已定档但原生完全未落地**（仍是旧的直连相册单图），并新发现 **#6 代码块能力矛盾**（§7）。「走查」列即 2026-06-04 原生现状。

原生编辑器主体**没漂**——内容样式(`editor_style.dart`)、工具栏 chrome 配色(`MobileToolbarV2` 的 bg/ink/accent/onAccent/hairline/danger)都已用 DayZ token 套过,纯 toggle 类按钮(B/I/U/S/代码/列表/引用/分隔线)也对。

| # | 漂移点 | 严重度 | 走查(06-04) | 根因 | 改法 |
|---|---|---|---|---|---|
| 1 | 颜色/高亮用了 AppFlowy 默认高饱和原色板 | 🔴 高 | ✅ 已修 | `buildColorItem` 没传自定义色板 | 传 DayZ 暖调色板(§2) |
| 2 | meta chip(心情/天气/地点/标签)用 Material Icons | 🟠 中 | ✅ 已修 | DayzIcons 缺这 4 个 path | 补 path + 换用(§3) |
| 3 | 日期 kicker / 关闭按钮用 Material Icons | 🟡 低 | ✅ 已修 | 现成 DayZ path 没被用 | 换 `DayzIcons.calendarPath` / `closePath`(§3) |
| 4 | 标题菜单无「正文」显式项 | 🟡 低 | ✅ 已修 | 用了 AppFlowy 原件,靠再点切回 | 加「正文」项(§4) |
| 5 | 图片直接进相册,无来源选择 + 大图无查看器 | 🔴 高 | 🚧 **未落地** | `onImageTap` 直连 `ImagePicker(gallery)`（单图） | 全屏微信式选择器 `DZ.picker` + 大图查看器 `DZ.lightbox`(§5) |
| 6 | 代码块:原型 demo / 能力清单有,但两边工具栏 + 原生 registry 都没有 | 🟠 中 | ✅ 已定调(做) | demo 超出实际可用能力 | 补块:原型已落地,原生跟进(§7) |
| 7 | 工具栏 14 件太长 + 格式分散 | 🟠 中 | ✅ 已定调 | 一排堆满易误触 | 精简 8 件 + 格式面板全集 + 标注块(§8) |

> **模式判断(重要)**：二级菜单**保留 AppFlowy「键盘位内联面板」模式**（点 `Aa·格式` / 颜色 → 面板替代键盘升起，文档与选区不被遮挡），**不要改成底部 sheet**——这是与原生一致、且更顺手的编辑手势，原生已用 DayZ token 套过色。原型 `editor.html` 已照此模式 1:1 还原，作为视觉真源。唯一用 sheet 的是「图片来源」（一次性插入动作，非格式化，§5）。

---

## 1. 逐条对账(原生现状 → 设计期望)

| 工具栏项 | 原生实现 | 设计期望 | 差异 |
|---|---|---|---|
| B/I/U/S、行内代码 | `toggleAttribute`,选中 `primaryColor` | 同 | ✅ |
| 无序/有序/待办/引用 | `formatNode` toggle | 同 | ✅ |
| 分隔线 | AppFlowy 原件 | 同 | ✅ |
| 标题 H | `headingMobileToolbarItem` 原件,H1/H2/H3 一行 | 加「正文」项 → 四项 | ⚠️ §4 |
| 颜色/高亮 | `buildTextAndBackgroundColorMobileToolbarItem()`,**默认色板** | DayZ 暖调色板 | ❌ §2 |
| 链接 | `linkMobileToolbarItem`,URL 单字段 + 取消/完成 | URL 单字段一致;**入口下沉到格式面板「文字样式」段** | ⚙️ §8a(不再是顶层工具栏项) |
| 图片 | `onImageTap` → 直接 `ImagePicker(gallery)` | 全屏微信式选择器 + 大图查看器 | ❌ §5 |
| 内容样式 | `dayzEditorStyle`:cursor/selection/正文衬线/code/href 全 token | 同 | ✅ |
| meta chip 图标 | Material `Icons.*` | 内联 SVG(§5 基调) | ❌ §3 |

---

## 2. 🔴 颜色 / 高亮色板(最该修)
AppFlowy 默认色板是 Material 高饱和原色(红 `f44336`/黄 `ffeb3b`/蓝 `2196f3`/绿 `4caf50`/粉 `e91e63`/紫 `9c27b0`…),与 DayZ「温润克制」冲突。`TextColorOptionsWidgets` / 背景色组件都留了 `textColorOptions` / `backgroundColorOptions` 钩子——**只需在 `buildColorItem` 里把 DayZ 色板传进去**即可,无需改包。

真源:`pages/assets/editor.js` 的 `TEXT_COLORS` / `HL_COLORS`。

### 文字颜色 `font_color`(AppFlowy 格式 `0xFF` + RRGGBB)
| 语义 | hex | font_color |
|---|---|---|
| 默认(墨) | — | `null`(清除,落到 `--ink`) |
| 红褐 | `#B5524B` | `0xffB5524B` |
| 暖橙 | `#C2772F` | `0xffC2772F` |
| 金棕 | `#B07D2A` | `0xffB07D2A` |
| 橄榄 | `#5E7F4E` | `0xff5E7F4E` |
| 雾蓝 | `#4E7A99` | `0xff4E7A99` |
| 雾紫 | `#7A6BA8` | `0xff7A6BA8` |

### 高亮 `bg_color`
原型 swatch 展示的是**浅色模式解析后的实色**。落地建议用**半透明 `bg_color`**(`0x40` ≈ 25% alpha + 同名饱和基色),一个值在浅/深都读得清;若坚持实色则需提供深色模式的暗版浅染。
| 语义 | 浅色实色(swatch 展示) | 建议 bg_color(半透,双模式) |
|---|---|---|
| 无 | — | `null` |
| 暖黄 | `#F2E3B0` | `0x40E8C84A` |
| 浅绿 | `#D8E6CE` | `0x4093C16E` |
| 浅蓝 | `#D2E0EC` | `0x405B9BD0` |
| 浅紫 | `#E2DAEF` | `0x40967ED8` |
| 浅粉 | `#F1DBDE` | `0x40D08A98` |

> 浅/深都要肉眼过:浅色纸上文字色要够沉、高亮要透气;深炭黑上文字色要够亮、高亮不糊。

---

## 3. 🟠 图标:回到内联 SVG(基调 §5)
基调硬规则:**功能图标一律内联 SVG(`viewBox 0 0 24 24` / `stroke=currentColor` / `2px` / 圆角端)**,不用 Material Icons、不用 emoji 当功能图标。当前编辑页有三处用了 Material:

- `editor_meta_bar.dart`:`Icons.sentiment_satisfied_alt` / `wb_sunny_outlined` / `location_on_outlined` / `local_offer_outlined`
- `editor_screen.dart`:日期 kicker `Icons.calendar_today_outlined`、关闭 `Icons.close`

**改法:**
1. 日期、关闭:直接换现成 `DayzIcons.calendarPath`、`DayzIcons.closePath`(已存在,只是没用)。
2. meta chip 四个图标:`DayzIcons` 里没有 → **新增 4 条 path**(d-string 取自原型 `editor.html` 的 `.compose-meta .chip-btn`,即设计真源),再用 `SvgPicture.string` 渲染(同 `editor_toolbar.dart` 里 image 的 `_svg()` 写法):

```dart
// 追加到 DayzIcons（lib/ui/widgets/dayz_icons.dart）
static const String moodPath = 'M9 10h.01M15 10h.01M8.5 14.5h7';            // 极简笑脸(无脸框版,同原型 chip)
static const String weatherSunPath = 'M12 7.8a4.2 4.2 0 1 0 0 8.4 4.2 4.2 0 0 0 0-8.4ZM12 3v2M12 19v2M3 12h2M19 12h2M5.5 5.5l1.4 1.4M17.1 17.1l1.4 1.4M18.5 5.5l-1.4 1.4M6.9 17.1l-1.4 1.4';
static const String locationPinPath = 'M12 21s7-5.4 7-11a7 7 0 1 0-14 0c0 5.6 7 11 7 11ZM12 12.4a2.4 2.4 0 1 0 0-4.8 2.4 2.4 0 0 0 0 4.8Z';
static const String tagPath = 'M4 12V6a2 2 0 0 1 2-2h6l8 8-8 8z';            // 配 circle cx9 cy9 r1.4(或并入 d)
```

> 心情/天气目前是多 subpath;`_svg()` 现在只包一个 `<path>`,渲染前把多段塞进同一个 `d`(空格分隔合法),或扩展 `_svg()` 支持多 path。天气太阳齿要**轴对称**(正上下左右+四角),别用倾斜默认齿(基调 §5)。

---

## 4. 🟡 标题菜单加「正文」项(建议)
AppFlowy 原件只有 H1/H2/H3,**靠再点一次激活项切回正文**——不可发现。原型在最前加了显式「正文/段落」项(共四等分:正文 · H1 大标题 · H2 中标题 · H3 小标题)。
**改法:** 不再直接复用 `headingMobileToolbarItem.itemMenuBuilder`,改成自写一个 4 项的 menu builder(参考其源码,首项 `ParagraphBlockKeys.type`,选中态比对 `node.type == paragraph`)。若暂不做,保留 toggle-back 也能用,但优先级建议补上。

---

## 5. 🔴 图片插入：全屏选择器（微信式）+ 大图查看器（设计定档·原生未落地）
> **走查 2026-06-04**：设计端已定档（`DZ.picker`/`DZ.lightbox` + 原生映射均备齐），但**原生代码一行未改**：`editor_image_inserter.dart:24` 仍是 `ImagePicker().pickImage(source: ImageSource.gallery)`——即本手册当初标 ❌ 的旧行为，且只能插单张；大图查看器全库 grep 不到 `photo_view`/`PhotoView` 任何痕迹。两件套件原生侧**仍为 0**，是本轮最需落地的二项。

原生现在点图片直接 `ImagePicker(gallery)`。原型已改成两件套件，均为覆盖整个手机视口的沉浸式媒体层（暖近黑 `--media-*`，明暗/主题一致，强调色走 accent）：

**(a) 全屏图片选择器 `DZ.picker`（代替原来的相册/拍照 sheet）**
微信式：顶栏（取消 / 相册名 ▾）+ 4 列网格（**首格即相机**，不再要中间一层「相册/拍照」菜单）+ 底栏（预览 / 原图 / 完成(N)）。多选带**顺序编号徽标**，超 9 张拦截。
- Flutter：**`wechat_assets_picker`**（`AssetPicker.pickAssets(maxAssets:9, ...)`）——预览/原图/编号/相机格全内置，主题色传 `AssetPickerConfig.themeColor: accent`；或 `photo_manager` 取资源 + 自绘 `GridView`。
- 当前 `onImageTap` 的直进相册逻辑改为拉起该选择器；相机格 → `ImageSource.camera`。

**(b) 大图查看器 `DZ.lightbox`（凡有内容图皆可点开）**
全屏沉浸看图，横向滑动翻页 + 顶部 `N / 总数` 计数。阅读页封面 + 九宫格已接（点谁从谁开）。
- Flutter：**`photo_view`** 的 `PhotoViewGallery.builder` + `PageController(initialPage:index)`，背景暖近黑，`onPageChanged` 更新计数。
- **边界**：只给「内容型」图片（详情页封面/九宫格）接；**时间线/收藏/往年今日的卡片封面图不接**——整卡点击 = 打开这篇日记（Day One 同此）。

---

## 6. 验收 checklist(原生改完逐条过)
> 勾选 = 2026-06-04 走查已确认（代码层面）；未勾选 = 未落地或需运行时肉眼复查。
- [x] 颜色面板出现的是 DayZ 暖调 6+5 色,**没有** Material 原色。（`buildColorItem` 已注入色板）
- [ ] 浅色 + 深色 × 紫/黄/绿 三主题各开一次颜色/标题/链接面板,配色不突兀。（需运行时肉眼）
- [x] 编辑页再无 `Icons.*`。（`grep Icons\.` 于 `lib/ui/editor` 已零命中）
- [x] 标题菜单含「正文」项。（`_DayzHeadingMenu` 四等分 正文·H1·H2·H3）
- [ ] 图片插入为全屏微信式选择器（首格相机 + 多选编号 + 预览/原图/完成），非旧的相册/拍照 sheet。🚧 **未落地**（仍直连 gallery）
- [ ] 详情页封面 + 九宫格点击能开全屏大图查看器、可左右滑；卡片封面图仍是整卡进详情。🚧 **未落地**（无 `photo_view`）
- [x] 二级菜单仍是键盘位内联面板,**未被改成底部 sheet**。（`MobileToolbarV2` 未动）
- [ ] 代码块已可用（§7）：格式面板有入口、`block_types` 注册 `code`、内容样式 mono+边框；插入代码块不再显示「[未支持块]」。
- [ ] 工具栏精简为 8 件高频（§8a，含无序/有序列表），链接收进格式面板文字样式行；其余格式收进 `Aa·格式` 面板（§8b），状态与快捷件双向同步。
- [ ] 新增标注块 callout 可插入并按 `--accent-soft` 渲染（§8c）。

---

## 7. 🟢 代码块：补齐为可用能力（已定调·原型已落地，待原生跟进）
原型 `editor.html` 的 `rich` demo + DESIGN-REF §3c 一直把「代码块」列为能力，但此前两边工具栏都没入口、原生 `block_types.dart` 也没注册 → 会渲染成「[未支持块]」。**已定调：做（不删）**。原型侧 2026-06-04 已落地（格式面板「列表与块」加了代码块按钮 `data-block=code`，radio 互斥）。原生需补三处对齐：
1. **工具栏/格式面板入口**：在格式 `withMenu` 的「列表与块」段加「代码块」项（与无序/有序/待办/引用/标注/分隔线并列）。
2. **注册块**：`editor_block_registry.dart` 注册 AppFlowy 自带的 `CodeBlockComponentBuilder`；`block_types.dart` 的 `supported` 加入 `CodeBlockKeys.type`（`'code'`），让 `content_json` 里的代码块不再落到 `_UnknownBlockComponentBuilder`。
3. **内容样式**：mono 字体 + `--bg-2` 底 + `--hairline` 边框，对齐原型 `pre.cb-codeblock`。
> AppFlowy 自带 `CodeBlockKeys` / `CodeBlockComponentBuilder`，无需改包；选中态切换走 `formatNodeToType(node, CodeBlockKeys.type)`。

---

## 8. 🟢 工具栏重排 + 格式面板全集 + 标注块（已定调·原型已落地，待原生跟进）
**背景**：旧工具栏一排 14 件按钮太长、易误触。2026-06-04 原型重排为「高频在外、全集在面板」，并**新增标注块（callout）**能力。

### 8a 工具栏精简为 8 件高频
`.toolbar.editor-dock` 只留：`Aa·格式`（开格式面板，`data-tb=format`）｜ 加粗 / 斜体 / 颜色 ｜ 无序列表 / 有序列表 / 待办（`data-tb-block=ul|ol|todo`，与面板块状态双向同步）｜ 图片。**链接较低频，收进格式面板「文字样式」行**（`data-mark=link`，点击拉起链接面板）。其余格式（段落级、列表与块全集、下划线/删除线/行内代码）**收进格式面板**——**additive**：面板列全集，工具栏快捷件在面板里也有，状态双向同步。
- Flutter：`MobileToolbarV2` 的 item 列表对应这 8 件；`Aa` 是一个 `MobileToolbarItem.withMenu`，菜单内是下面的三段式；ul/ol/todo 走 `formatNodeToType`。链接项放进 `Aa` 菜单的文字样式段，点击走 `MobileLinkMenu`。

### 8b 格式面板三段式（`data-panel=format` · `.kb` 键盘高）
- **段落** `.tb-headings`：正文 / H1 / H2 / H3（沿用 §4 的四等分，含显式「正文」）。
- **列表与块** `.tb-blocks`（3 列网格，radio 互斥）：无序 / 有序 / 待办 / 引用 / **代码块**（§7）/ **标注**（§8c）/ 分隔线（一次性插入）。与段落互斥。
- **文字样式** `.tb-marks`：B / I / U / S / 行内代码（独立 toggle；B、I 与工具栏快捷件双向同步）。
- 面板高度 `min-height:288px` 向软键盘看齐、内容多时自然生长（`max-height:62vh` 兜底滚动）——对齐用户「面板高度和输入法对齐」的要求。
- Flutter：菜单内用 `Column` + 三个分段标题；段落/块项调 `formatNodeToType`，文字样式项调对应 `toggleAttribute`。面板高度对齐 `MediaQuery.viewInsets.bottom`（键盘高）。

### 8c 新增能力：标注块 Callout `.cb-callout`
日记场景常用「一句心得 / 提醒」高亮成块。AppFlowy 自带 `CalloutBlockKeys`，可直接落地。
- 原型内容样式：`--accent-soft` 底 + `.ic` 信息图标（`--accent-ink`）+ `.tx` 文字，圆角 `--r-md`，**不做左边框配色那套俗套**。
- Flutter：注册 `CalloutBlockComponentBuilder`；`block_types` 加 `CalloutBlockKeys.type`（`'callout'`）；背景用 `--accent-soft` 对应的 theme 色（随 data-theme+data-mode）。
> §6 checklist 末两条对应 §7/§8 的原生跟进验收。
