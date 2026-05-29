# 10 · UI 还原与设计稿同步

> 状态：方法论 + 架构决策（部分定稿、部分待对应 spec 细化，逐节标注）
> 作者：@Ray
> 定位：回答两个工程问题——(A) 怎么把 `ui-design/` 的 HTML 设计稿用 Flutter 还原；(B) 设计稿会**持续迭代**，怎么不被移动靶拖垮。
> 配套：视觉 token/组件见 `ui-design/current/docs/DESIGN-REF.md`；HTML→Flutter 机制映射见 `ui-design/current/docs/PROTOTYPE-ARCH.md §6`；spec 执行协议见 `docs/spec-guide-ai.md`。
> 本文是 UI 系列 spec（`design-tokens-theme` / `ui-kit-components` / `ui-shell-navigation` / `design-sync-automation` / 6 个页面级 spec）的总纲。

-----

## 0. 两个核心判断（先记这两句，其余都是展开）

1. **「还原」不是把 HTML 翻译成 Flutter，而是自底向上重建三层**：token/主题层 → 通用组件层 → 屏幕层。下层是上层的硬依赖，反过来不成立。先做屏 = 把颜色/字号硬编码散进 6 屏 × 6 主题，直接踩「一律走 ThemeExtension token、不在屏里硬编码」的红线。
2. **「同步」要按层差速，不能整体自动化**：HTML 原型（iframe + postMessage + URL state）和 Flutter（Sliver/Navigator/Riverpod）是两套渲染范式，`PROTOTYPE-ARCH §6` 给的是「等价做法」而非可转译代码。**只有 token 层能机械再生**；组件/布局层只能靠 diff 信号 + 参数对齐驱动可控的自动跟进，并用「钉住设计稿版本」切断移动靶。

-----

## A. 如何还原

## 1. 分层还原策略（自底向上，建造顺序 = 依赖顺序）【定稿】

```
┌─ 屏幕层 (6 屏 + 状态/转场/抽屉/FAB/吸顶/无限滚动)   ← 最后，最不可机械同步
│   依赖 ↓
├─ 通用组件层 (DayzButton/EntryCard/Toolbar/Drawer/Fab …) ← 中间，半机械
│   依赖 ↓
└─ token/主题层 (DayzColors ThemeExtension + 静态常量 + 字体) ← 最先，唯一可机械再生
```

| 层 | 产物文件 | 关键 widget/类 | 量级 |
|---|---|---|---|
| **token/主题层** | `lib/ui/theme/dayz_tokens.g.dart`(生成) + `dayz_colors.dart`/`dayz_fonts.dart`/`dayz_text_theme.dart`(手写) | `DayzColors extends ThemeExtension`、`DayzSpacing/Radii/Motion/Fonts` 静态类、`ThemeData×6` | 6 套主题数据 |
| **通用组件层** | `lib/ui/widgets/*.dart` | `DayzButton/TextField/Switch/Tag/Segmented/Mood/WeatherChip/Toolbar/EntryCard/MonthHeader/YearSep/Fab/Drawer/EmptyState`、`DayzGlassAppBar`（毛玻璃顶栏，6 屏共用） | ~16 个 |
| **屏幕层** | `lib/ui/<feature>/<feature>_page.dart` | `TimelinePage/ReaderPage/EditorPage/OnThisDayPage/SearchPage/SettingsPage` + 各自 `demo.dart` | 6 屏 |

**准入门槛（硬约定）**：组件层只实现 `DESIGN-REF.md §3` 登记过的组件（有类名 + 最小 HTML 才算可复用），不凭空造 widget。

## 2. token → ThemeExtension【定稿】

`tokens.css` 有**三条独立变化轴**，不要全塞进一个巨型 ThemeData：

| 轴 | 内容 | 落地位置 | 套数 |
|---|---|---|---|
| 全局常量（与 theme/mode 无关） | 间距 `--sp-*`、圆角 `--r-*`、动效 `--ease/--dur`、字体栈 | **静态类**（不进 ThemeExtension，否则被复制 6 遍、徒增漂移面） | 1 |
| 中性色 + 阴影（仅随 mode） | bg/surface/ink×4/hairline/overlay/danger/favorite/shadow×3 | `DayzColors` 字段 | 2 |
| 强调色（随 theme×mode） | accent 7 元组 | `DayzColors` 字段 | 6 |

**代码生成（强烈建议，且是同步策略的支点）**：写 `bin/gen_tokens.dart` 解析 `ui-design/current/design-system/assets/tokens.css` → 生成 `lib/ui/theme/dayz_tokens.g.dart`（6 套 `DayzColors` 常量 + 静态类）。

- **规范源唯一**：只认 `design-system/assets/tokens.css` 这一份；`pages/` 与 `prototype-kit/` 下的 `tokens.css` 是同源副本，不当真源。
- 转换规则（确定性）：`#RRGGBB → Color(0xFFrrggbb)`；`rgba(r,g,b,a) → Color(0x..)`；多层 `box-shadow → List<BoxShadow>`；`--accent-strong → accentStrong`、`--sp-4 → s4`。
- **行为代码不生成**（`lerp`/`copyWith`/helper getter 手写、放 base 文件），生成文件只产纯数据字段。
- 接进 `dayz-design-sync` 流程：每次同步设计稿后 `dart run bin/gen_tokens.dart`，diff 校验保证 `.g.dart` 与 `tokens.css` 永不漂移。
- ⚠️ **解析器鲁棒性是命门**（见 §12.1）：`box-shadow` 值里 `rgba()` 内部也有逗号，裸 `split(',')` 会拆错；alpha 取整策略要固定（如 `0.32 → 0x52`）。解析器一脆，脚本静默产错值而「diff 为空」检查照样通过——所有「零漂移」承诺就成空话。**必须做成 `design-tokens-theme` 的硬验收项。**

PoC 骨架（purple-light 真值取自 `tokens.css`，已逐字段核对属实）：

```dart
@immutable
class DayzColors extends ThemeExtension<DayzColors> {
  final Color bg, surface, ink, ink2, hairline, accent, accentStrong,
      accentSoft, accentSoft2, accentInk, onAccent, accentRing /* …+danger/favorite/overlay/ink3/ink4… */;
  final List<BoxShadow> shadowSm, shadowMd, shadowLg;
  const DayzColors({required this.bg, /* …全 required… */});

  // ⚠️ 顶栏毛玻璃不是裸 blur：screen.css 实测是 `saturate(1.5) blur(20px)`。
  //    Flutter 的 ImageFilter.blur 只模糊不提饱和度，要 compose 一层 saturation matrix（见 §4 timeline / §12.2）。
  //    注：0.82 与 saturate/blur 系数都是 screen.css 的屏内值、不在 tokens.css 里；此处为示意，
  //    真值随 §4 参数抽取从 screen.css 核定（文末「真源是 tokens.css」只管 token，兜不住这几个屏内值）。
  Color get glassSurface => surface.withValues(alpha: 0.82);

  @override DayzColors lerp(ThemeExtension<DayzColors>? o, double t) { /* 每色 Color.lerp，阴影 BoxShadow.lerpList */ }
  @override DayzColors copyWith({/* … */}) { /* 逐字段 ?? */ }
}

const dayzPurpleLight = DayzColors(
  bg: Color(0xFFFAF7F1), surface: Color(0xFFFFFFFF), ink: Color(0xFF2C2823),
  accent: Color(0xFF786CAD), accentStrong: Color(0xFF635693),
  accentSoft: Color(0xFFEEEBF6), accentInk: Color(0xFF564A86),
  onAccent: Color(0xFFFFFFFF), accentRing: Color(0x52786CAD), /* …其余… */);

extension DayzColorsX on BuildContext {
  DayzColors get dayz => Theme.of(this).extension<DayzColors>()!; // 用法 context.dayz.accent
}
```

**字体**：打包 Newsreader（衬线）+ Hanken Grotesk（无衬线）两套小体积 Latin（确认 SIL OFL 许可后入 `pubspec.yaml`）；**绝不打包 CJK web 字体**，中文靠 `fontFamilyFallback` 落系统 PingFang/Songti。注意 Flutter 对**可变字体字重轴支持有限，多数情况仍要切静态字重 ttf**（`spec.css` 大量用 `font-weight:600`，至少要 regular + semibold）。CJK 行高放宽（正文 1.7、日记/阅读 1.85），配 `TextLeadingDistribution.even`。

**i18n 取向【待拍板】**：当前全部 spec 无 i18n。这是结构性决定（影响每屏 `Text` 怎么写），**须在 `design-tokens-theme` 阶段拍板「MVP 是否单中文硬编码」**，否则 6 屏写完再抽 `flutter_localizations + arb` 是大返工。

## 3. 逐屏还原要点

> 下列难度标注（最复杂/最重/最简单）是**本文的工程评估**，设计稿文档里并无这套分级；不要当成引用。共用基建：毛玻璃顶栏抽成 `DayzGlassAppBar` 组件，6 屏共享。

- **timeline（最复杂）**：`CustomScrollView` = `SliverAppBar(pinned)` + 每月 `SliverPersistentHeader(pinned)`（月份头）+ 该月 `SliverList`(EntryCard) + 尾部 loader sliver。抽屉 `Scaffold(drawer:)`；FAB `DayzFab`；无限滚动 `ScrollController` 近底触发或 `infinite_scroll_pagination`。
  - **关键妥协**：完美吸顶头 与 `scrollable_positioned_list` 的按 index 跳转**不兼得**。**降级 = 日历跳转只到「月级」**（对标 Day One），实现用**每月 header 的 `GlobalKey` + `Scrollable.ensureVisible`，不引第三方包**（vendored appflowy 虽带 `scroll_to_index`，但别为日级精度搬过来）。
  - 吸顶投影：`SliverPersistentHeaderDelegate.build(overlapsContent)` 里 `overlapsContent==true` 才给 `BoxShadow`，原生等价 `.stuck`。
  - 顶栏 + 吸顶头并成一条磨砂：两 sliver 的 `BackdropFilter` 配方/背景色须完全一致、相邻不留缝。
  - FAB 立体 + 长按速拨：`Container(BoxDecoration(gradient: fabGradient, boxShadow:[×3]))`；轻点/长按 340ms 用 `GestureDetector`；speed-dial staggered 动画。Flutter 无 inset 阴影，顶高光降级为顶部浅渐变或 0.5px 白边。
- **reader**：`CupertinoPageRoute` 推入（自带右滑入场 + 边缘返回）。单一数据驱动版式，天气/地点/心情可空则不渲染对应 chip。收藏星用 DESIGN-REF §5 规范五角星 path（CustomPaint/flutter_svg），不用 `Icons.star`。
- **editor（最重）**：正文是 **vendored AppFlowyEditor**（`packages/appflowy-editor`），不是 TextField；标题用 `TextField(border:none)`。
  - 工具栏吸键盘：**定调用 AppFlowy 的 `mobile_toolbar_v2` 体系**（fork 已带 `keyboard_height_plugin`），只改 item 集与样式，**别自己监听 `MediaQuery.viewInsets.bottom`**——两套键盘高度源会竞争抖动。
  - 格式高亮态必须由选区实际格式派生（`EditorState.selection` + toggledStyle），不是本地 bool toggle。
  - 与 `editor-json-contract` 的硬接缝：load/save 走 codec、解 `docVersion`；自定义块（`cb-*`）的 `blockComponentBuilder` 必须与该契约的块清单一一对齐；内容存 `content_json + content_plain`。
  - 图片插入跨模块：`image_picker` → media-storage 加密容器 → 插 image node（串独立媒体 key）。
- **onthisday**：每年一段 `SliverList` 前插 `DayzYearSep`（普通行，非吸顶）。卡片配图走加密 media + 异步缩略图（`MediaRepo` 解密 + thumbnail `warmup`），**列表滚动禁止同步重建缩略图**（红线）。空态 `SliverFillRemaining(hasScrollBody:false)`。
- **search**：三态状态机，**须补 `querying`/`error`**（原型只有 typing/results/empty）。结果复用 `DayzEntryCard` 但用朴素 `ListView`，**别套 timeline 的吸顶/日历复杂度**（search.html 只引 screen.js、没引 timeline.js）。命中词高亮用 `Text.rich`，接受 TextSpan 直角高亮（圆角还原不了）。输入 debounce → Drift 查询 → 命中计数判空 → 切态 + 高亮。中文 FTS 归远期，先做标题/标签/纯文本 LIKE。
- **settings（最简单）**：倾向**自绘 token 驱动的 Row + flutter_svg 图标徽**，别赌 `CupertinoListSection.insetGrouped`（accent-soft 圆角方徽 + 56px 行高 + 自定义几何图标会和它内建 padding 持续打架）。开关 `CupertinoSwitch(activeColor: accent)`。文案红线：**媒体相关 UI 必须说明「主密码锁不住照片」**（媒体 key 独立、不随 rekey）；数据库加密行恒为只读「已加密」，无关闭入口。

-----

## B. 设计稿持续迭代，如何保持同步

## 4. 验证：四层闸，从硬到软——视觉对比也尽量做成确定性【定稿】

**关键认知：跨引擎「截图比像素」必挂，但「视觉对比」≠「比像素」。把视觉对比拆成「样式参数」+「布局几何」两层后，绝大部分可做成确定性断言；真正模糊的只剩残余的栅格观感。**

| 闸 | 查什么 | 怎么查 | 性质 |
|---|---|---|---|
| **① token 值闸** | Flutter token 常量 == `tokens.css` 值 | `gen_tokens.dart` 生成 + diff 校验 | 确定性 |
| **② 样式参数闸** | 每元素**解析后样式** == 设计稿（color/font/radius/padding/shadow + **截断/行钳制** `text-overflow`/`-webkit-line-clamp` ↔ `maxLines`/`overflow`/`softWrap`…） | `getComputedStyle` 抽取 → widget test 断言 | 确定性 |
| **③ 布局几何闸** | **顺序/包含/不溢出**（全元素）+ **位置/尺寸**（仅 fixed-geometry 元素硬断言） | `getBoundingClientRect` vs `RenderObject` 几何；元素先分 fixed / content-driven（见 §4 ③） | 确定性\*（文本块尺寸除外） |
| **④ 栅格观感闸** | 真实像素观感（渐变、FAB 多层影、saturate 玻璃、抗锯齿） | Flutter golden（回归锁）+ 区域化 SSIM/pixelmatch（确定性分数）+ 视觉模型（**可选**，仅残余边界判定） | 半确定性 |

②③ 是确定性主闸，由**同一次浏览器抽取**产出（`getComputedStyle` 喂 ②、`getBoundingClientRect` 喂 ③）；③ 唯一的不确定来自「文本回流驱动的尺寸」（见 §4 ③说明，按 fixed / content-driven 分治化解）。④ 模糊面最大，但大头（golden / SSIM）仍是确定性，视觉模型退成可选。

**参数对齐怎么做（关键，且完全可 AI 自动化）**——抽参数 → 断言参数相等，不靠肉眼比像素：

1. **抽源真相参数**：用 headless 浏览器（gstack）跑**源屏** `pages/screens/<id>.html`，**不是** assembled 的 `dayz-prototype.html`（后者是 `build-standalone.py` 把各屏内联进 `iframe`/`window.__DZ_SCREENS__` 的构建产物，引两个坑）：
   - **时序坑**：源屏改后须先重建 standalone 才抽得到新值，否则抽的是旧 prototype；
   - **穿透坑**：`.entry/.card` 在 iframe 里，`getComputedStyle` 得钻 `contentDocument`。

   直接跑源屏两坑全免，且与 §6 Phase 1 的 diff 路由目标天然对齐。对稳定类名（`.entry`/`.card`/`.tl-month`/`.btn`/`.compose-body`…，DESIGN-REF §3 已登记）逐个 `getComputedStyle`，拿**解析后**的真实值：`padding`/`gap`/`border-radius`/`font-size`/`font-weight`/`line-height`/`color`/`background`/`box-shadow`——已把 CSS 级联 / `var(--*)` 全解析成最终 px/rgb，不用手写 specificity。（同一次抽取里 ③ 一并取 `getBoundingClientRect`、④ 一并截图，全取自源屏。）
2. **反查回 token + 落成参数清单（fixture）**：`16px→sp-4`、`14px→r-md`、`rgb()` 按值匹配回 6 套 `DayzColors`、多层 shadow 解析成 `List<BoxShadow>`。顺带抓出「设计稿用了不在 token 里的硬编码值」——这是设计侧要修的，标红。
3. **Flutter 端断言实际属性**（widget test，读渲染属性）：
   ```dart
   final deco = tester.widget<Container>(find.byType(...)).decoration as BoxDecoration;
   expect(deco.borderRadius, BorderRadius.circular(DayzRadii.md));   // r-md
   expect(deco.boxShadow, ctx.dayz.shadowMd);
   final text = tester.widget<Text>(find.text('…'));
   expect(text.style!.height, 1.85);                                 // 行高
   expect(text.style!.color, ctx.dayz.ink);                          // 颜色 token
   ```

**为什么这层强**：① 确定性、CI 秒级、不请视觉模型；② 它顺便是**最精确的 diff 信号**——设计把 `.entry` padding 从 sp-4 改成 sp-5，参数清单重抽后该 widget test 立刻红，精确到字段，比「html 文件变了」强。

**布局几何闸怎么做（③）**——比的是几何不是像素，跨引擎稳；但**必须按元素分治**，否则会重蹈 golden test 覆辙：
- HTML 侧：对稳定类名取 `getBoundingClientRect()` → 归一化布局树（固定 iPhone 视口下各元素 x/y/w/h）；Flutter 侧：widget/integration test 里 `tester.getRect(find...)` / `RenderObject` 几何 → 同形布局树。比**相对几何**（顺序、相邻间距、包含/重叠、宽高比），不比绝对坐标——其中「相邻间距」对 content-driven 邻居必须取 **gap = `next.top − prev.bottom`**（不是 top-to-top / 中心距），才与未断言的块高解耦；否则前块高度一卷进来，content-driven 分治就白做了。
- **元素先分两类（③ 能不能立住的关键）**：
  - **fixed-geometry**（图标、chip、FAB、固定尺寸卡、分隔线…）：**硬断言尺寸 + 位置**（相对几何 + ≤1–2px 容差，容差有亚像素舍入的物理依据）。
  - **content-driven**（正文、标题、可换行文本块…）：**只硬断言顺序 + 包含 + 不溢出**，块高放宽或由内容行数推导——**不硬断言块高**。
- **为什么必须分**：即便 ② 已钉死 font-size/line-height/font-weight，HTML（浏览器 line-breaker）与 Flutter（minikin）对同一段文本的**换行结果仍可能不同**，CJK / 中英混排尤甚；更要命的是 §2 已定「CJK 走系统字回退」——抽取端（gstack 宿主）与 Flutter test 宿主若非同机（典型 CI Linux），回退字体不同 → 字宽不同 → 换行点不同 → 行数不同 → 块高不同。块高一变，下方兄弟「相邻间距」全被推开、超容差 → ③ 要么天天 flaky、要么有人把容差调大到连真·溢出都漏掉（**正是 naive golden test 的失效模式在 ③ 复活**）。根因是 §2 的 CJK fallback 决策，content-driven 分治是它的护栏。
- **对应关系（映射表，也是漂移源）**：HTML 类名 ↔ Flutter widget key 的映射表（DESIGN-REF §3 组件目录是雏形）。⚠️ DOM 与 widget 树**不同构**（一个 `.entry` 可能 = `Column`+多 widget，单 widget 也可能吞两层 div），映射粒度是人工选定的维护面。**铁规则**：源屏出现**映射表里没有的新类名** → 不许被 ③ 当「全过」静默跳过，而是**强制按 §8 ② 实质变更**处理（新增 sync 任务卡 + 补映射）。否则 ③ 的确定性会退化成「对已知元素确定、对新元素假阴性」。每条映射还须挂 **`geometry: fixed | content`** 标签（与映射表**同一处登记**，新条目必须同时定 geometry，缺标签 = 未映射 → 升 ②），别让分类散落进测试代码。
- **③/② 的缝（content-driven 让步的闭合条件，必须堵）**：「不断块高」会漏一种真 bug——**文本截断/行钳制不一致**（设计稿把摘要钳 2 行省略号、Flutter 漏设 `maxLines:2`，或反之）；它样式全对、只是块高变了，③ content-driven 抓不到、② 当前列也没有这族 → **两头落空、静默通过**。闭合办法：**截断/钳制族必须进 ② 的参数 schema**（HTML `text-overflow`/`-webkit-line-clamp` ↔ Flutter `maxLines`/`overflow`/`softWrap`）。补上后 ③ 的残留才只剩「纯换行差异导致的高度噪声」这一类非 bug，「不断块高」让步方成立。
- **一个假设**：content-driven 块的可用宽 = 其 fixed 容器宽 − ② padding；自身内蕴宽度的块（`max-width`/`fit-content`）不归容器 fixed、也不归 padding，会滑过——本设计此类块少，spec 里记一句假设、个案单列即可。

**栅格观感闸怎么做（④，半确定性）**——只剩这层带模糊，且模糊面已很小：
- **Flutter golden**（`matchesGoldenFile`）：确定性回归锁，钉住 Flutter 自身输出不回退。
- **区域化感知度量**：用 ③ 的布局框把两端截图裁成对应区域，逐区域算 **SSIM**（结构相似，对栅格噪声鲁棒）/ pixelmatch（抗锯齿感知差分）/ pHash（粗判「整块不对」）。给确定性分数，**SSIM 阈值是全套里最软、依据最弱的启发式**（③ 的 ≤1–2px 容差是次软但有亚像素舍入物理依据的一个；二者都是判断项，并非「其余全确定、只剩 SSIM」）；区域化（不比整屏）能避开跨引擎字体栅格化噪声。
- **视觉模型**：降为**可选**，只判 SSIM 分数处于边界又难定阈值的残余项；甚至可省——低分区域直接进 SYNC_REPORT 标红。

**诚实边界**：跨引擎**整屏像素级精确匹配**确实不可能（字体栅格化/抗锯齿/渐变插值/saturate 近似都不同），所以才不比整屏像素，而是 ②样式 + ③几何（确定性）扛主力、④ 用 golden + 区域化 SSIM 兜栅格、视觉模型只收边角。模棱两可的项**进 SYNC_REPORT 标红、不静默放过**。

## 5. 还原 = 同步，同一个工作流【定稿】

两件事本质相同——**把某屏的 Flutter 实现驱动到与它的 HTML 源一致**，只差种子与触发：

| | 还原（初次） | 同步（迭代） |
|---|---|---|
| 种子 | 该屏 Flutter 还是空的 | 已有实现 + 一段 diff |
| 触发 | 手动跑一次 | `git diff ui-design/current/` 非空自动触发 |
| 工作流 | **同一个「屏幕对齐工作流」** | **同一个** |

## 6. 同步工作流设计（AI 工作流，不预设人工）【待 design-sync-automation 细化】

```
Phase 1  Detect & Route   ── 解析 git diff，分类路由（确定性，无 agent）
Phase 2  Token Regen      ── dart run gen_tokens.dart + 三份 tokens.css 同源校验 + 对比度/lerp 回归（确定性）
Phase 3  Screen Align     ── pipeline over 受影响屏：读新HTML+§6+现widget → 改 widget（worktree 隔离避免并行冲突）
Phase 4  Verify           ── ①②③ 硬闸（任一红→build fail）；③ 按 fixed/content-driven 分治 → ④ round-budget best-effort（golden + 区域化 SSIM，残余低分标红不阻塞）→ 自修复循环
Phase 5  Pin & Report     ── 更新各屏 pinned hash（screens.yaml）+ 产出 SYNC_REPORT.md
```

**Phase 1 路由表**（文件路径即模块边界，确定性映射）：

| diff 命中 | 路由 |
|---|---|
| `design-system/assets/tokens.css` | → Phase 2 token 重生（全屏覆盖） |
| `pages/screens/<id>.html` | → Phase 3 该屏 |
| `pages/assets/screen.{css,js}` | → Phase 3 **扇出到全部 6 屏**（共享层！抽屉/FAB/顶栏都在这——易被低估的盲点） |
| `pages/assets/timeline.{css,js}` | → 仅 timeline |
| `DESIGN-REF.md §3` | → `ui-kit-components` 增量 |

**把「人工」换成 AI 的关键**：Phase 3 每屏一个 agent（输入 = 新 HTML + §6 映射 + 现 widget 源 + ui-kit + tokens，输出 = patch，`isolation: worktree` 隔离）；Phase 4 分两级闸：**①②③ 为硬闸（任一红 → build fail；③ 按 fixed-geometry / content-driven 分治，对文本块只断顺序+包含+不溢出，不断块高）**；**④ 为 round-budget best-effort**——①②③ 全过后循环尽力推 ④ 达阈，到轮次上限仍低分的区域写进 SYNC_REPORT 标红、**不阻塞**。SYNC_REPORT 标红项可选人眼终审，亦不阻塞。

> **约定修订**：`docs/spec-guide-ai.md` 有一条「确实无法自动化的（视觉、真机、人因）走人工核查项并注明核查人，不要用『假装能测的 grep』凑数」。**「禁止假装能测的 grep」这条红线保留不变**——本方案的参数/几何断言（§4 ②③，是真断言而非假 grep）恰恰是它的**正面践行**。真正被取代的只是「视觉项**只能**走人工」这个默认：从 default-人工 升级为 **default-①②③ 确定性闸 + ④ golden/SSIM 自动验，视觉模型与人眼仅做标红终审且不阻塞**。落 `design-sync-automation` 时**同 commit 修订 spec-guide-ai.md 该条**；`AGENTS.md` 不需动（其验收段只是转引 spec-guide 的协议，@Ray 署名条与本条无关）。〔按原文片段定位，不写行号——行号会随文件编辑漂移。〕

## 7. 生命周期：屏幕是活的，不归档【待 design-sync-automation 细化】

区分两种生命周期：

| | 生命周期 | 归宿 |
|---|---|---|
| **「建 timeline v1」这个工程** | 有限，会完成 | 完成后归档（历史记录「v1 建好并对齐 @hash」） |
| **timeline 这块屏幕本身** | 永远活着，跟随设计 | **永不归档**，由常驻同步机制 + 活的 test/registry 维护 |

落地：屏幕 spec 不进「已归档」，转入新泳道 **「已交付·随设计维护」**（对现有「进行中 / 已归档」二态的小扩展，落 `design-sync-automation` 时同 commit 改 `spec-guide` / `specs/README.md`）。

**关键**：对齐状态——pinned hash、参数清单 fixture、golden 基线——全部活在**代码/测试树**（`test/ui/<feature>/`）和一份常驻**屏幕登记表** `specs/active/design-sync-automation/screens.yaml`，**不塞进会被归档的 spec 正文**。所以**没有任何东西需要「从归档捞回来」**。

两个「归档」都不是恢复入口：`specs/archive/` = 已完成 spec（不复活）；设计稿旧版 = git 历史（`git show <hash>:ui-design/...`，正常流程不需要——永远对齐 current，用 pinned hash 算增量）。

## 8. 改设计的三档响应【待 design-sync-automation 细化】

让**常见的小改全自动、零 spec**，重流程只留给结构性大改：

| 档 | 什么变了（由信号判定） | 怎么处理 | 人工 |
|---|---|---|---|
| **① 微调** | 只动 token 值 / 参数（padding、color、行高、文案、小布局） | 同步工作流**全自动**：重抽参数清单 → 改 widget → 参数闸+golden 重验 → bump pinned hash → 记 SYNC_REPORT | 0 |
| **② 实质变更** | 新状态 / 新组件 / 区块重排 / 新交互 / DESIGN-REF §3 加条目 | 工作流判定「超出机械再对齐」→ 在该屏**维护态 spec 的 tasks.md 追加一张 sync 任务卡** → 工作流起草+实现+验证 | 0~轻 |
| **③ 大改版** | 整屏被重新构想（信息架构/导航变） | 开**新 active spec**（如 `timeline-redesign`），走完整四件套 | 正常 spec 流程 |

**判定规则**（工作流确定性分流）：
- `git diff <pinned>..HEAD -- pages/screens/<id>.html` 为空 + 只有 `tokens.css` 变 → **①**（甚至不碰这屏）。
- 参数清单重抽后**只有数值变、元素集/结构不变** → **①** 机械再对齐。
- 出现**新元素 / 新 `data-when` 状态 / §3 新组件 / 结构重排** → **②**。（含「源屏出现 ③ 映射表里没有的新类名」——**强制升 ②**，不许被 ③ 当「全过」静默放过，见 §4 ③。）
- 屏的信息架构/导航变 → **③**。

**工作流怎么知道「v1 之后改了啥」**：pinned hash 当锚（存 `screens.yaml`，是工作流每次跑的**输入**，不是文档摆设）；增量 = `git diff <pinned>..HEAD -- <screen>.html` + 参数清单重抽 diff（字段级）。`scripts/check_ui_sync.sh` 反向巡检：哪屏 pinned hash 落后于当前设计且 diff 非空 → 报「待同步」。这就是「hash 会烂成死数字」的解药。

-----

## C. 落地

## 9. spec 拆分：三档【待立 spec】

### 基础档（建一次，之后由同步工作流维护）

| spec | 拥有什么 | dependsOn |
|---|---|---|
| `design-tokens-theme` | `gen_tokens.dart` 解析器 + `dayz_tokens.g.dart`(6套) + 手写 `DayzColors` + 字体打包 + **i18n 取向拍板** | — |
| `ui-kit-components` | DESIGN-REF §3 那 ~16 个 widget + `DayzGlassAppBar`(含 saturate) + **widgetbook 画廊**（对应原型「画布平铺看全状态」） | tokens-theme |
| `ui-shell-navigation` | go_router 路由 + 抽屉 + FAB 速拨 + 取代 `DebugHome` 的真外壳 | tokens, ui-kit, data-layer |

### 自动化档（同步 SOP 归属，cross-cutting，分两期）

| spec | 拥有什么 | 期 |
|---|---|---|
| `design-sync-automation` | 同步工作流脚本 + diff 路由器 + 样式参数 harness（getComputedStyle→断言）+ 布局几何 harness（getBoundingClientRect→几何断言）+ 栅格兜底（golden + 区域化 SSIM，视觉模型可选）+ `screens.yaml` 登记表 + pinned-hash 巡检 hook + 维护态泳道/三档分流规则 | 期一随 tokens-theme 落（token 重生管线 + diff 路由骨架）；期二等首屏+shell 落后补（屏级还原 + 验证） |

### 页面级档（6 屏，W2 可并行；每屏「实现」本身就是一次工作流跑）

`timeline-screen` / `reader-screen` / `editor-integration-screen` / `onthisday-screen` / `search-screen` / `settings-screen`，各依赖 `tokens + ui-kit + shell + 对应底层 spec`。
（修正：`editor-integration` **不** dependsOn 已归档的 `appflowy-patch-tracking`，改为「遵循 `packages/CHANGELOG.md` 补丁三件套机制」。）

### 依附 / 后置（W3/W4）

`undo-redo`、`media-picker-flow`、`autosave-recovery-ui`、`thumbnail-placeholder-ui` / `backup-restore-wizard-ui`、`onthisday-notification`、`pdf-html-archive`。

### 波次（依赖拓扑）

```
W0  design-tokens-theme  +  design-sync-automation(期一)
W1  ui-kit-components → ui-shell-navigation
W2  6 个页面级 spec（并行）   +  design-sync-automation(期二)
W3  依附件   W4  后置件
```

### 每屏 task 放哪

沿用项目现有约定，每屏一个 spec 目录，task 在自己的 `tasks.md`：

```
specs/active/
├─ design-tokens-theme/{requirement,design,tasks,verification}.md   ← 基础
├─ ui-kit-components/ …
├─ ui-shell-navigation/ …
├─ design-sync-automation/{…, screens.yaml}                          ← 同步 SOP + 屏幕登记表
├─ timeline-screen/  tasks.md ← timeline 的 T# 卡在这
├─ reader-screen/ …  editor-integration-screen/ …  onthisday-screen/ …
├─ search-screen/ …  settings-screen/ …
```

配套产物归在该屏名下，由其 `design.md`「文件变更」声明、`tasks.md`「验收基建」预批：

```
lib/ui/timeline/{timeline_page.dart, demo.dart, ...}
test/ui/timeline/params/*.json   ← 参数清单 fixture（主闸数据，浏览器抽出）
test/ui/timeline/*_test.dart     ← 参数断言 + 行为 widget test
test/ui/timeline/goldens/*.png   ← 截图兜底基线
```

**同步工作流不另开 task 库**：检测到某屏 diff 时，在该屏维护态 spec 的 `tasks.md` 追加一张 sync 任务卡（或只 bump pinned hash）。spec 目录是 task 的唯一持久家，工作流只是执行器。

## 10. 动 `lib/ui/` 前的红线 / 白名单【定稿，引自 AGENTS.md / CLAUDE.md】

`lib/ui/`（及 backup/data/drafts/media/security/thumbnails）目前只有 `.gitkeep`。动它之前：

1. **先有 spec**：四件套已立、档位锁定、`design.md`「文件变更」逐个列出要新建的 `lib/ui/<feature>/*.dart`——这份清单才是任务「可改文件」白名单的来源，没 spec 不得写 `lib/ui`。
2. **先立视觉底座**：第一个落 `design-tokens-theme`，其余全 dependsOn 它，不许每屏硬编码颜色/字号。
3. **复用前读设计参考**：`DESIGN-REF.md`（类名 + 最小 HTML + token 全表）、`PROTOTYPE-ARCH.md §6`（机制 → Flutter 映射 + 痛点 + 退步方案）。
4. **守 Repository 边界（硬红线）**：UI 取数只经 `JournalRepo/EntryRepo/MediaRepo/TagRepo/EditingSessionRepo`，**禁止 UI 持 Drift 句柄或写 SQL/Drift**。
5. **Debug Home 入口**：每个 UI spec 在 `lib/demo/demo_entry.dart` 的 `demos` 末尾**只追加一行**（不插中间、不改 `DemoEntry` 字段），该文件列入对应任务白名单。真外壳取代 `home:DebugHome()` 时，同 commit 改 `lib/app.dart` 与 CLAUDE.md「Debug Home 入口模式」段。
6. **新文件加 MPL-2.0 头注**。
7. **触 `pubspec.yaml`**（go_router/image_picker/flutter_svg/flutter_local_notifications/widgetbook 等）属清单外共享文件，须在 `design.md` 文件变更显式列出并经确认。
8. **golden 等验收基建**须在对应任务「验收基建」字段预批，否则撞白名单墙（hook 校验：`spec-kit/hooks/claude-pretooluse-whitelist.sh`）。

## 11. 验收口径【定稿】

可自动化的尽量 widget test 断言可观测值（②样式参数闸、③布局几何闸、对比度按 ThemeData 算、`SliverAppBar pinned` 行为、滚动后顶栏状态切换、`find.bySemanticsLabel`）。栅格观感走 golden + 区域化 SSIM，视觉模型仅收残余边界——参数/几何断言是真断言，正是「**禁止假装能测的 grep**」的正面践行，不是反例。无障碍至少覆盖：点击目标 ≥ 44px、对比度 ≥ WCAG AA、Semantics 标签、`reduce-motion`（FAB speed-dial / 220ms 转场尊重系统「减弱动态效果」）。

## 12. 落地前要补的洞（对抗性校验的硬发现，方向不变但别漏）

1. **`gen_tokens.dart` 解析器鲁棒性**（§2 已述）——`box-shadow` 逗号嵌套、alpha 取整、rgba vs hex。做成 `design-tokens-theme` 硬验收项。
2. **毛玻璃 `saturate(1.5)` 别丢**——`ImageFilter.compose(饱和度 matrix, blur)`，design.md 记可接受误差。
3. **pinned hash 巡检**（§8）——`scripts/check_ui_sync.sh`，防 hash 烂成死数字。
4. **三份 tokens.css 同源校验**——同步后 `diff -q` 三份副本，分叉则告警（上游若让 prototype-kit 先行试新色，current/ 会忠实镜像分叉，而脚本只读 design-system 那份）。
5. **i18n 取向**（§2）——tokens-theme 阶段拍板。
6. **loading/error 态**——reader 封面、editor 大文档首屏、search 查询中、解密失败/Drift 异常，组件层当一等公民。
7. **widgetbook**——§6 明确多状态预览用 widgetbook，Debug Home 单列表补不了「组件×6主题×N状态」矩阵。
8. **修正 `OPEN.md` 过时段**——`_archive/<时间戳>` 实测目录不存在，skill 已改走 git 回溯。
9. **修正根 `CLAUDE.md` 指向已归档 spec 的指针**——根 `CLAUDE.md` 的「红线」段（vendored 补丁三件套的「详见…」）与「文档导航」表（补丁台账行）仍指 `specs/active/appflowy-patch-tracking/`，但该 spec 已归档至 `specs/archive/2026-05-29-appflowy-patch-tracking/`，且补丁台账是常驻机制（真源 `packages/CHANGELOG.md`）非待做 spec。落 `editor-integration` 或 `design-sync-automation` 时同 commit 把这两处指针改向（**按段落定位、勿用行号**——改 CLAUDE.md 本身就会移动其后所有行号）。

## 13. 建议第一步

**立 `design-tokens-theme` + `design-sync-automation`（期一）的 spec 四件套**，先做 token/主题层 + `gen_tokens.dart` 生成管线 + 参数对齐 harness 骨架。最高杠杆（全部 UI spec 依赖它）、最低风险（纯数据，不碰布局/data 接缝），且一次性把同步策略里**唯一真自动化的那一环**打通。验收项必须含 §12.1（解析器鲁棒性）、§12.4（三份同源校验），并拍板 i18n 取向。

-----

## 关键文件路径速查

- token 规范真源：`ui-design/current/design-system/assets/tokens.css`
- 6 屏 HTML：`ui-design/current/pages/screens/{timeline,reader,editor,onthisday,search,settings}.html`
- 设计参考：`ui-design/current/docs/{DESIGN-REF,PROTOTYPE-ARCH,CHANGELOG,BACKLOG}.md`
- 同步 skill：`.claude/skills/dayz-design-sync/SKILL.md`
- 目标落地目录（待动土）：`lib/ui/`（现仅 `.gitkeep`）

-----

## 维护本文件

- 本文是 UI 系列 spec 的总纲。**对应 spec 立项后**，逐节标注的「待 spec 细化」内容下沉到该 spec 的四件套，本文只保留指针与跨 spec 的总判断，不复述细节。
- 验证策略（§4）、生命周期（§7）、三档响应（§8）若在实战中调整，**与 `design-sync-automation` 同步修订**，并联动 `AGENTS.md` / `spec-guide-ai.md` 的相关约定。
- token PoC（§2）只示意结构，**数值真源永远是 `tokens.css` + 生成的 `.g.dart`**，本文不复制数值。
