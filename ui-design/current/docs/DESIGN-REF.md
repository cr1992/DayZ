# DayZ 设计规范 · AI 速查手册（DESIGN-REF）

> 本文件是**给 AI / 开发快速复用的索引**，不是给人看的展示文档（展示见 `design-system/design-system.html`）。
> **复用任何组件前先读本文件**：直接抄类名与最小 HTML 片段，不必重读 CSS。
> 黄金规则：**只引用 `var(--*)`，绝不写死颜色 / 字号 / 间距**；改完若定档，按 `CHANGELOG.md` 规矩记录。

## 文件结构
```
项目根/
├── CLAUDE.md             # 项目说明（必须在根目录，自动加载）
├── docs/
│   ├── DESIGN-REF.md     # 本文件 · AI 速查
│   └── CHANGELOG.md      # 更新日志（按天 + 模块标签）
├── design-system/
│   ├── design-system.html # 人看的展示文档（含实时主题/明暗切换）
│   └── assets/
│       ├── tokens.css    # 所有设计变量（唯一真源）
│       ├── spec.css      # 布局 + 组件样式（含页面级组件）
│       ├── spec.js       # 主题/明暗切换、交互演示、FAB 长按
│       └── demo_image.png
└── pages/                # 产品页面设计（交付物）
    ├── index.html # 外壳：原型路由 + 静态多状态画布（双模式 viewer）
    ├── screens/          # 每屏一个独立可单开文件，状态用 ?state= 区分
    │   ├── timeline.html  reader.html  editor.html
    │   └── onthisday.html  search.html  settings.html
    └── assets/
        ├── tokens.css spec.css   # 自设计规范复制（保持同步）
        ├── screen.css screen.js  # 屏内：iOS chrome / 多状态显隐 / 屏内交互 / postMessage 导航
        ├── pages.css  app.js     # 外壳：iPhone 外框 / iframe 路由栈 / 画布索引
        └── img/                  # 氛围占位图（bookstore/plum/sea，可替换真实照片）
```
接入新页面（设计规范文档内）：引入 `tokens.css` + `spec.css`，在 `<html data-theme="purple" data-mode="light">` 上挂属性即可。
接入新产品屏（pages/）：见 `docs/PROTOTYPE-ARCH.md`（屏幕契约 + postMessage 协议 + Flutter 映射）。

---

## 0. 维护约定（本文件如何保证不腐化）
> 详见 `CLAUDE.md` 的「DESIGN-REF 维护」。要点：
- **改动即同步**：新增/修改 token、组件、模式时，**与定档同一步**更新本文件——新组件补「组件目录」（类名 + 最小 HTML），改 token 补「Token 速查」。改完本文件再写 `docs/CHANGELOG.md`，二者成对出现。
- **单一真源**：`tokens.css` 是 token 唯一真源；本文件只索引与释义，不复制数值。冲突时以 `tokens.css` 为准并立即修正本文件。
- **准入门槛**：组件只有在本文件登记后才算「可复用」；没登记的视为临时草稿，不得在新页面引用。
- **校验**：复用前比对类名是否仍存在于 `spec.css`；若对不上，说明本文件落后，先修文件再用。

---

## 1. 主题与明暗切换机制
- 在根元素挂 `data-theme` + `data-mode`（+ 可选 `data-bg`）：
  - `data-theme` = `purple`（雾紫）｜ `amber`（暖黄）｜ `sage`（雾绿）
  - `data-mode` = `light` ｜ `dark`
  - `data-bg`（背景纸色，可选）= 缺省`纯净` ｜ `mint` 浅绿 ｜ `mist` 雾蓝 ｜ `cloud` 云灰 ｜ `tinted` 主题微染 ｜ `custom` 自定义（均浅淡耐读；曾有 warm/paired/sepia，已移除）
- **中性色只随 `data-mode` 变；强调色随 `data-theme` + `data-mode` 变。**
- **背景纸色随 `data-bg` 覆盖背景相关中性色**（`--bg/--bg-2/--surface/--surface-2/--hairline*`，Sepia 另微调 `--ink*`）；`tinted` / `custom` 用 `color-mix` 从 `--accent` / `--paper-seed` 派生，故自动随 theme + mode 联动。详见 §2.5。
- 三套主题**共享同一套 token 命名与语义**，仅色相不同 → 组件只要用变量就自动适配 6 种组合（× 纸色再叠加）。
- `spec.js` 负责切换并持久化到 `localStorage['dayz-spec-pref']`（含 `theme/mode/bg/paperSeed`）。

---

## 2. Token 速查（真源：`tokens.css`）

### 2.1 强调色（随 theme + mode）
| Token | 用途 |
|---|---|
| `--accent` | 主操作色：主按钮底、FAB、开关开、选中色点、链接 |
| `--accent-strong` | accent 的 hover / pressed 加深态 |
| `--accent-soft` | 浅色调底：次按钮底、选中行底、tag 底、心情选中圈 |
| `--accent-soft-2` | 比 soft 更深一档：hover 底、描边、照片占位 |
| `--accent-ink` | 着色文字 / 图标（落在 soft 底或浅底上时） |
| `--on-accent` | 落在实色 `--accent` 上的文字（黄主题为深墨，紫/绿为白） |
| `--accent-ring` | 聚焦光环 `box-shadow: 0 0 0 4px var(--accent-ring)` |

### 2.2 中性色（仅随 mode）
| Token | 用途 |
|---|---|
| `--bg` / `--bg-2` | 应用底色（暖白纸/暖炭黑）/ 凹陷区、分组底 |
| `--surface` / `--surface-2` | 卡片、浮层 / 次级表面 |
| `--ink` / `--ink-2` / `--ink-3` / `--ink-4` | 主文字 / 次级 / 辅助·占位 / 禁用 |
| `--hairline` / `--hairline-2` | 分割线 / 强描边 |
| `--overlay` | 遮罩底色 |
| `--media-bg` / `--media-surface` | 沉浸式媒体层底 / 层内条格底（大图查看器·选择器，暖近黑，明暗一致） |
| `--media-ink` / `--media-ink-2` | 媒体层主文字图标 / 次级·空心描边 |
| `--media-hairline` / `--media-scrim` / `--media-chip` | 媒体层分割线 / 渐隐遮罩·投影 / 圆钮底 |
| `--danger` / `--danger-soft` | 危险操作文字 / 其浅底 |
| `--favorite` | 收藏星标（暖金） |
| `--shadow-sm` / `--shadow-md` / `--shadow-lg` | 暖调投影三档 |

### 2.3 间距 · 圆角 · 字体 · 动效
| 组 | Token → 值 |
|---|---|
| 间距(4px基准) | `--sp-1`4 `--sp-2`8 `--sp-3`12 `--sp-4`16 `--sp-5`20 `--sp-6`24 `--sp-8`32 `--sp-10`40 `--sp-12`48 `--sp-16`64 |
| 圆角 | `--r-xs`6 `--r-sm`10 `--r-md`14 `--r-lg`20 `--r-xl`28 `--r-full`999 |
| 字体 | `--font-sans`(UI) `--font-serif`(标题/日记) `--font-diary`(=serif) `--font-mono` |
| 动效 | `--ease` `--dur`(220ms) |

> **字体加载（打包思源 · 跨平台一致）**：Latin 两套**小体积品牌字**——`Newsreader`(衬线) + `Hanken Grotesk`(无衬线)；**中文打包思源**——`Noto Serif SC`(衬线/日记) + `Noto Sans SC`(无衬线/UI)，全简体 ~8200 字子集、OFL-1.1，产品 Flutter 端打包约 23MB（4 字重）。字体栈即「Latin 品牌字 → 思源 SC → 系统字」，按字符自动回退；系统 `Songti SC`/`PingFang SC` 退为思源未覆盖生僻字的深层兜底。原型 serif 用内联思源宋静态子集保 WYSIWYG。（推翻早前「偏原生·移除 Noto」决定，详见 CHANGELOG 2026-06-26。）

### 2.4 排版类（直接套用）
`.t-display` `.t-h1` `.t-h2`（衬线）· `.t-h3`（无衬线粗）· `.t-body`（UI 正文 1.7）· `.t-diary`（日记衬线 1.85）· `.t-caption` · `.t-overline`
> CJK 正文行高 1.7–1.8；标题/日记正文用衬线，界面文字用无衬线。

### 2.5 背景 · 纸色（`data-bg`，覆盖背景中性色）
在根元素挂 `data-bg` 切换背景「纸色」；只改 `--bg / --bg-2 / --surface / --surface-2 / --hairline / --hairline-2`（Sepia 另微调 `--ink/--ink-2/--ink-3` 更暖），**强调色与排版不动**。每套都有浅 / 深两版。
| `data-bg` | 含义 | 派生方式 |
|---|---|---|
| （缺省） | 纯净 · 中性暖纸 | 固定值（即 §2.2 基础中性色） |
| `mint` | 浅绿 · 豆绿护眼 | 固定值（浅淡耐读，theme 无关） |
| `mist` | 雾蓝 · 清冷低眩光 | 固定值（浅淡耐读，theme 无关） |
| `cloud` | 云灰 · 中性沉静 | 固定值（浅淡耐读，theme 无关） |
| `tinted` | 主题微染 · 跟 accent 走 | `color-mix(in oklab, var(--accent) N%, 基底)` → **随 theme + mode 联动**（轻染） |
| `custom` | 自定义 | `color-mix(in oklab, var(--paper-seed) N%, 基底)`；`--paper-seed` 由 JS 设（如色相滑块 → `hsl(H 42% 56%)`） |
> 曾有 `warm` 暖纸 / `paired` 主题配套 / `sepia` 深褐，评估同色发闷、捆绑不自由后移除；纸与主题色各自独立（点主题不换纸）。每套都让 `surface` 比 `bg` 亮一档，突出主体。
- **不要写死背景色**：组件一律用 `var(--bg/--surface/...)`，纸色切换即自动生效。
- 切换 + 持久化在 `spec.js`（`.paper-btn[data-bg]` 点击；`#paperHue` 滑块 → `custom` + 设种子）。展示见 `design-system.html` §02。
- **联动**：点顶栏主题色（`.swatch-btn`）= 切主题 **并** 把纸设为 `paired`（配套纸）；单独点纸（`.paper-btn`）只改纸、不动主题。顶栏切换后自动滚到 §06 真实界面看效果（`spec.js` `jumpToContext`）。
- **Flutter**：纸色 = 一个 `paper` 枚举 + 可空 `paperSeed` 颜色；`tinted`/`custom` 用 HSL/oklch 把 accent 或 seed 以低比例混入基底背景（`Color.alphaBlend` 或手算），映射到 `ThemeExtension` 的背景族。

---

## 3. 组件目录（类名 + 最小 HTML）

### 按钮 `.btn`
变体：`.btn-primary` `.btn-soft` `.btn-ghost` `.btn-text` `.btn-danger`｜尺寸：`.btn-sm` `.btn-lg`｜`.btn-icon`（方形图标钮）｜`[disabled]`
```html
<button class="btn btn-primary">写一篇</button>
<button class="btn btn-soft btn-icon"><svg …></svg></button>
```

### 输入框 `.field`
```html
<div class="field">
  <label>标题</label>
  <input class="input" placeholder="…">
  <span class="help">辅助说明</span>
</div>
<textarea class="textarea"></textarea>
```
聚焦态 = `--accent` 描边 + `--accent-ring` 光环（已内置）。

### 开关 `.switch`
```html
<label class="switch"><input type="checkbox" checked><span class="track"></span><span class="thumb"></span></label>
```

### 勾选 / 单选 `.opt`
方块 `.box`（勾选）/ 圆点 `.dot`（单选）；选中加 `.on`；演示交互加 `data-toggle`。
```html
<div class="opt on" data-toggle><span class="box"></span>选项</div>
<div class="opt" data-toggle><span class="dot"></span>选项</div>
```

### 分段控件 `.segmented`
```html
<div class="segmented">
  <button aria-selected="true">时间线</button>
  <button aria-selected="false">日历</button>
</div>
```

### 标签 `.tag`
实底（accent-soft）默认；`.tag-outline` 描边款；`.x` 删除叉。
```html
<span class="tag"># 旅行 <span class="x">×</span></span>
<span class="tag tag-outline"># 工作</span>
```

### 心情 `.mood` / 天气 `.weather-chip`
心情脸 = 内联 SVG（眼点 + 嘴弧），不用 emoji；`.mood` 选中加 `.sel`。
```html
<div class="mood-row">
  <div class="mood sel"><div class="face"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 10h.01M15 10h.01"/><path d="M8.5 14.5c1.4 1.7 5.6 1.7 7 0"/></svg></div><span>愉快</span></div>
</div>
<span class="weather-chip"><svg …></svg> 晴 26°</span>
```

### 编辑器工具栏 `.toolbar`
按钮 `.tb`（激活 `.on`）；分隔 `.div`；演示切换加 `data-toggle`；二级面板触发加 `data-tb`（不当纯 toggle）。编辑页用 `.toolbar.editor-dock`（精简 7 件，余收进格式面板，见 §3c「键盘位内联面板」）。对接 **AppFlowy Editor**（能力集见 §3b 「编辑页 `.compose-*`」）。

### 提示条 `.toast` / 弹窗 `.dialog`
**全局 toast 系统**：底部居中浮现、自动消失、可堆叠（容器 `.toast-host`，最多 3 条）。底色保持中性（`.toast` 深色款 / `.toast.surface` 表面款），**语义只靠图标点色**承载（默认/成功/信息=主题色 · `.danger`=`--danger` · `.fav`=`--favorite`），克制不喧哗。可带一个操作 `.acc`（撤销/查看/重试）。
- **引擎**：`assets/toast.js`，调 `DZ.toast('文案')` 或 `DZ.toast({text,tone,variant,action,onAction,duration,icon,host})`。`tone`=`default|ok|info|danger|fav`；`variant`=`dark|surface`；有 `action` 时默认停留更久（4.2s vs 2.6s）；无 `action` 时点整条关闭。就近挂载到 `[data-toast-host]` → `.screen` → `body`。
- **进场**：`.toast` 起始 `opacity:0 + translateY`，append 后强制回流再加 `.in` 触发过渡（**不要用 rAF**——节流态不触发）；退场加 `.out`。
- **容器修饰**：`.toast-host.top`（顶部变体）、`.toast-host.no-fab`（无 FAB 屏，缩小底部留白；默认留 96px 让开 FAB）。
> Flutter：`ScaffoldMessenger.showSnackBar`（`behavior: floating`）+ `SnackBarAction`；底色中性、`Icon` 着语义色；FAB 由 Scaffold 自动让位。
```html
<!-- 静态结构（引擎会生成同构 DOM） -->
<div class="toast danger"><span class="ic"><svg…></svg></span><span class="msg">已移到回收站</span><button class="acc">撤销</button></div>
<div class="toast surface"><span class="ic"><svg…></svg></span><span class="msg">已开启端到端加密</span></div>
```
`.dialog`（`h4` + `p` + `.acts`）。

### 底部弹层 `.sheet`（动作菜单 / 选择器 / 轻表单）
**全局 sheet 系统**：从底部滑入、scrim 点击关闭、圆角顶 + 拖拽柄 + 底部留白。一套引擎 `assets/sheet.js`（`DZ.sheet(opts)`）覆盖三种形态：
- **动作菜单**：`items:[{label, icon, tone:'danger', onTap}]`，默认带「取消」行。
- **单选选择器**：`items:[{label, swatch:'#色', selected:true, onTap}]`，命中项右侧打勾。
- **轻表单**：`content`(节点/HTML) + `primary:{label,onTap}`（可加 `secondary`）。
- item 字段：`label / desc`(次级行) `/ icon`(SVG 串) `/ swatch`(色点) `/ tone:'danger' / selected / keepOpen / onTap`；`sep:true` 为分隔线。
- 就近挂载到 `.pg` → `.screen` → `body`；z 48/49（浮于抽屉与 chrome 之上）。进场同 toast：append 后强制回流再加 `.in`（不用 rAF）。
- **业务用法集中在 `screen.js`**：条目动作菜单（`[data-entry-menu]`）、移到日记本、删除确认、新建日记本（`[data-new-journal]`）、设置选择器（`[data-theme-picker]`/`[data-mode-picker]`）、往年今日 ⋯（`[data-otd-menu]`）。
> Flutter：`showModalBottomSheet`（圆角顶 + 拖拽柄 + `SafeArea` 底部留白）；单选用 `ListTile`+`trailing: Icon(check)`，表单用内嵌 `Column`+`FilledButton`。
```html
<!-- 引擎生成同构 DOM；手写一般只调 DZ.sheet() -->
<div class="sheet-scrim in"></div>
<div class="sheet in">
  <div class="sheet-grip"></div>
  <div class="sheet-head"><div class="t">更多</div></div>
  <div class="sheet-list">
    <button class="sheet-item"><span class="ic"><svg…></svg></span><span class="tx"><b>编辑</b></span><span class="chk"><svg…></svg></span></button>
    <div class="sheet-sep"></div>
    <button class="sheet-item danger"><span class="ic"><svg…></svg></span><span class="tx"><b>删除</b></span><span class="chk"></span></button>
  </div>
  <button class="sheet-cancel">取消</button>
</div>
```

### 时间线日记卡片 `.entry`
```html
<div class="entry">
  <div class="date"><div class="d">29</div><div class="m">MAY</div><div class="w">周五</div></div>
  <div class="card">
    <div class="photo"><img src="…"></div>      <!-- 单张封面（多图改用 .gallery，见下） -->
    <div class="body">
      <div class="head"><h4>标题</h4><span class="star"><svg…></svg></span></div>
      <p class="excerpt">两行摘要…</p>
      <div class="foot">
        <span class="tag"># 生活</span>
        <span class="meta"><svg…></svg> 上海</span>
        <span class="meta">😊 愉快</span>
      </div>
    </div>
  </div>
</div>
```

### 相册九宫格 `.gallery`（多图日记）
卡片正文区 / 阅读页正文后的多图网格。列数随张数变（克制版朋友圈）：`data-n="2"`→2列、`"3"`→3列、`"4"`→2×2 田字、`≥5`→3列铺满、`"1"`→单张大图(4:3)。超 9 张时在**第 9 格**加 `.more`（`data-more="N"` 显示「+N」蒙层）**收起**，被收起的格加 `.hidden`；阅读页点 `.more` 由 `screen.js` 给 `.gallery` 加 `.expanded` 露出全部。信息流卡片里外层 `data-nav` 先行导航 → 点图直接进阅读页（不就地展开）。单张封面仍用 `.entry .photo`，多图才用 `.gallery`。
> Flutter：`GridView.count`（crossAxisCount 由张数 2/3 决定）+ 最后一格 `Stack` 叠 +N 蒙层；点 +N 展开或进相册查看器。
> **点图看大图**：给 `.gallery` 加 `data-lightbox` 即可（容器内图自动成组，点谁从谁开；见「大图查看器 `.lbx`」）。
```html
<div class="gallery" data-n="9">
  <div class="ph"><img src="…" alt=""></div>          <!-- 第 1–8 格 -->
  <div class="ph more" data-more="2"><img …></div>   <!-- 第 9 格：+2 收起 -->
  <div class="ph hidden"><img …></div>              <!-- 仅阅读页：展开后露出 -->
</div>
```

---

## 3b. 页面级组件（产品页面复用）
> 用于实际页面（见交付物 `pages/index.html`）。沿用 token，禁止写死值。
> **真源分两处**：跨端共享的组件在 `design-system/assets/spec.css`（改后须复制到 `pages/assets/`）；**仅原型用的屏内组件/骨架**在 `pages/assets/screen.css`（不回流设计规范）。本节(3b)= spec.css；下一节(3c)= screen.css。

### 时间线年月吸顶头 `.tl-month`
`position:sticky; top:var(--top-h)`，停靠在覆盖式顶栏正下方（`--top-h` 见 §3c 骨架）。**现为可点击触发器**（`<button>`）：点它打开日期跳转日历（见 §3c「时间线日期跳转」）。带 `data-cal-open` + `data-ym="YYYY-M"` + 末尾下拉 `.tl-caret`（展开态 `aria-expanded="true"` 时旋转）。
```html
<button class="tl-month" data-cal-open data-ym="2026-5" aria-expanded="false">
  <span class="y">5月</span><span class="c">2026 · 12 篇</span>
  <svg class="tl-caret" viewBox="0 0 24 24" …><path d="m6 9 6 6 6-6"/></svg>
</button>
```

### 单篇阅读版式 `.reader`
`.r-kicker`(日期，含日历图标) → `h1`(衬线大标题) → `.r-meta`(weather-chip + tag + 地点) → `.r-body p`(衬线 1.85) → `.r-tags`。封面用 `.read-hero > img`。封面 + 正文后九宫格都已加 `data-lightbox`，点图进大图查看器（见下）。

### 大图查看器 `.lbx`（DZ.lightbox · 全局引擎）
**全屏沉浸式看图**：暖近黑底（`--media-*`，明暗/主题一致）、横向 scroll-snap 翻页、顶部计数 `3 / 11` + 关闭钮、可选底部 caption。点空白退出、点图不退出；桌面预览支持 `Esc`/`←`/`→`。
- **引擎**：`assets/lightbox.js`，调 `DZ.lightbox({images:['a.png',{src,caption}], index, host})`。
- **自动接线（推荐）**：给容器加 `data-lightbox` → 容器内所有 `<img>` 成一组，点哪张从哪张开。容器或单图可带 `data-caption`。已接：阅读页 `.read-hero` + `.gallery`。
- **凡有内容图皆可接**：内容型图片（封面/九宫格）直接加 `data-lightbox`；**卡片封面图（时间线/收藏/往年今日）不接**——整卡点击是「打开这篇日记」（Day One 同此），进详情再看大图。
> Flutter：`PhotoViewGallery.builder` + `PageController(initialPage:index)`，背景暖近黑，`onPageChanged` 更新计数。
```html
<div class="gallery" data-n="9" data-lightbox> …<div class="ph"><img src="…"></div>… </div>
```

### 全屏图片选择器 `.pk`（DZ.picker · 微信式 · 全局引擎）
**插入图片入口**：暖近黑全屏，顶栏（取消 / 相册名 ▾）+ 4 列网格（首格相机 `.pk-cam`）+ 底栏（预览 / 原图 / 完成(N)）。多选带**顺序编号徽标** `.pk-badge`（选中 accent 实底 + 缩放 + accent 描边；未选空心圈），超上限 toast 拦截。预览复用 `DZ.lightbox`；编号/完成钮走主题 accent。
- **引擎**：`assets/picker.js`，调 `DZ.picker({assets:[src…], max:9, onDone(srcs){}, onCamera(){}, album, host})`。`onDone` 回选中**顺序**的 src 数组。
- **选择按格身份去重（非 src）**——原型缩略图可能复用同一张图，按 src 去重会误连选。
- 已接：编辑器图片钮（`editor.js` `openImagePicker()`）。
> Flutter：`wechat_assets_picker`（`AssetPicker.pickAssets`：maxAssets/预览/原图/编号全内置）或 `photo_manager` + 自绘 `GridView`。
```html
<!-- 引擎生成；手写一般只调 DZ.picker() -->
<div class="pk in">
  <div class="pk-top"><button class="pk-cancel">取消</button><button class="pk-album">最近项目 ▾</button></div>
  <div class="pk-grid"><button class="pk-cam">📷</button><button class="pk-cell sel"><img><span class="pk-badge">1</span></button>…</div>
  <div class="pk-foot"><button class="pk-preview">预览</button><button class="pk-orig"><span class="box"></span>原图</button><button class="pk-done">完成 (1)</button></div>
</div>
```

### 往年今日年份分隔 `.year-sep`
```html
<div class="year-sep"><span class="yr">2024</span><span class="ago">两年前</span><span class="ln"></span></div>
```

### 搜索 `.search-head`
`.search-input`(图标 + `.q`查询词 + `.caret`光标) + `.search-cancel`；`.search-sec`(分组 `.h` + `.chips`)；`.search-stat`(结果计数)；命中词包 `.hl`。

### 编辑页 `.compose-*`（对接 AppFlowy Editor）
`.compose-title`(标题输入) · `.compose-meta`(日期/心情/天气/地点/标签 `.chip-btn`，选中 `.on`) · `.compose-body`(衬线正文，占位 `.dim` + `.compose-caret`)。底部停靠工具栏 `.toolbar.editor-dock`（横向滚动，承载 AppFlowy 能力：H · B/I/U/S/行内代码 · 颜色高亮 · 无序/有序/待办列表 · 引用 · 链接 · 分隔线 · 图片）。父级加 `.pg.has-dock` 预留底部留白。

### 设置分组列表 `.set-*`
`.set-account`(头卡) + 若干 `.set-group`(`.lab` 分组标题 + `.set-list` > `.set-row`)。`.set-row`：`.ic`(图标徽) + `.tx`(b 主 + span 次) + 右侧 `.switch` / `.val` / `.chev`。

---

## 3c. 屏内专属组件（真源 `pages/assets/screen.css` · 仅原型）
> 这些只服务 `pages/screens/*.html` 的呈现与原型交互，**不属于跨端设计系统**，故不进 spec.css。

### 屏幕骨架 `.pg`（覆盖式固定头 + 在其下穿行的滚动区）
`.pg`(flex 列) > `.app-top`(或 `.search-head`) + `.app-scroll`(唯一滚动区)。可选修饰：`.pg.drawer-stage`(挂抽屉)、`.pg.has-dock`(底部停靠工具栏留白)。详见 `docs/PROTOTYPE-ARCH.md` §3。
- **顶栏改为悬浮覆盖层**：`.app-top` / `.search-head` 用 `position:absolute; top:0`，内容（含状态栏区）从其下方穿行。静止时是干净实底（`--bg`）；滚动后 `.pg.scrolled` 上身 → 毛玻璃浮起（半透 `--bg` 80% + `blur(20px)`）**覆盖到状态栏**，并加 0.5px 底分割。
- **`--top-h`**：`screen.js` 实测顶栏高度写到 `.pg` 上；`.app-scroll` 用 `padding-top:var(--top-h)` 让首屏内容让位。**吸顶子头（如 `.tl-month`）用 `top:0`**——因 `padding-top` 已把内容盒顶推到顶栏之下，sticky 的 `top` 相对内容盒计算，再写 `var(--top-h)` 会叠加两次留出整段空隙（见 kit「易踩的坑」）。
- 抽屉/遮罩层级（`.scrim` 24 / `.drawer` 26）已抬到覆盖式顶栏(20)之上、状态栏(30)之下。

### 时间线日期跳转 `.cal-*` + `.tl-loader`（真源 `pages/assets/timeline.{css,js}` · 仅时间线）
点月份头 `.tl-month` → 日历面板从顶栏下方落下，快速跳到某月/某日。
- **触发**：`[data-cal-open]`（即 `.tl-month`，读其 `data-ym`）；`.cal-scrim` 点击关闭；`.pg.cal-open` 控制显隐。
- **月视图**：`.cal-head`(‹ `.cal-nav` · `.cal-title[data-toyear]` 月份 · `.cal-nav` ›) + `.cal-wd`(周一起始) + `.cal-grid > .cal-day`。日格态：`.has`(有条目，可点，底部 accent 圆点) / `.today`(今日 accent 环) / `.pad`(占位)。底部 `.cal-today-btn`「回到今天」。
- **年视图**：`.cal-title[data-tomonth]` 切回；`.cal-months > .cal-mo`（12 个月，`.has` 有条目 + 篇数，`.cur` 当前月）。
- **无限滚动**：`.tl-loader`（底部「载入更早」转圈，到底加 `.done` 文案）。最新在最上，滚到底按需追加更早月份。
- **数据模型**：JS 内 `MONTHS` 轻量月份索引（哪些月/日有条目 + 篇数）→ 对应 Flutter 一条按月计数查询；正文仍走游标分页。日历跳转用 `scrollTo(header.offsetTop - --top-h)`，未渲染的更早月份先补渲染再滚。

### 空状态 `.empty`
居中插画徽 + 标题 + 说明，用 `data-when` 控制显隐。
```html
<div class="empty" data-when="empty">
  <div class="ill"><svg…stroke="currentColor"></svg></div>   <!-- 中性暖底圆徽，单色线性图标 -->
  <h3>标题一句</h3><p>引导一两句</p>
</div>
```

### 搜索建议行 `.suggest-row`
最近搜索 / 建议项：`svg`(单色) + 文本 + 可选右侧 `.sub`(计数)。
```html
<div class="suggest-row"><svg…></svg>梅子<span class="sub">2 篇</span></div>
```

### 顶栏展开搜索 `.topsearch`（交互见 screen.js）
放大镜就地展开为输入框。结构放在 `.app-top` 内：触发钮 `[data-search-open]`；展开层 `.topsearch`(含 `.field > input[data-search-input]` + `[data-search-close]`)；`.app-top.searching` 控制显隐。回车 → `postMessage({type:'nav',to:'search'})` 跳结果页。

### 编辑器富格式块 `.cb-*`（compose-body 内 · 演示 AppFlowy 全能力集）
编辑页 `data-when="rich"` 状态把 AppFlowy **全部**支持的样式画全（画布样式真源，避免还原偏差；内容长、可滚动）：
- **标题**：`h1/h2/h3.cb-h`（衬线，26/21/17px）。
- **行内**：粗 `<strong>` · 斜 `<em>` · 下划线 `<u>` · 删除线 `<s>`（原生标签）；行内代码 `code.cb-code`（mono+`--bg-2`）；链接 `a.cb-link`（`--accent-ink`+下划线）；文字色 `.cb-fc[data-fc]` / 高亮 `.cb-hl[data-hl]`（**底色由 editor.js 从工具栏同一套 `TEXT_COLORS`/`HL_COLORS` 注入**，高亮固定配深墨文字，明暗都读得清）。
- **块**：无序 `ul.cb-list`(disc) · 有序 `ol.cb-list`(decimal) · 待办 `.cb-todo`（`.done` 勾选，`.bx`+`.tx`）· 引用 `blockquote.cb-quote` · 代码块 `pre.cb-codeblock`（mono+边框）· **标注 `.cb-callout`**（`--accent-soft` 底 + `.ic` 信息图标(`--accent-ink`) + `.tx` 文字，承载一句心得/提醒）· 分隔线 `hr.cb-hr` · 图片 `.cb-img`（圆角，带 `data-lightbox` 可点开大图）。
> 改色板只改 editor.js 的 `TEXT_COLORS`/`HL_COLORS`；demo 自动跟随。Flutter 能力集对照见 `docs/handoff/editor.md`。

### 编辑器键盘位内联面板 `.editor-dock-wrap` + `.tb-panel`（真源 `pages/assets/editor.{css,js}` · 仅编辑页）
还原 AppFlowy `MobileToolbarV2` 的二级菜单模式:点工具栏 **Aa·格式 / 颜色** → 面板从工具栏**下方**(键盘位)升起,文档与选区保持可见、不压暗。**不要改成底部 sheet**(那是更差的编辑手势,且与原生不符)。唯一例外:**图片**走全屏选择器(一次性插入动作,非格式化)。
- **工具栏分层(高频在外、全集在面板)**:工具栏 `.toolbar.editor-dock` 只放高频 8 件 —— `Aa`(开格式面板,`data-tb=format`) ｜ 加粗 / 斜体 / 颜色 ｜ 无序列表 / 有序列表 / 待办(`data-tb-block=ul|ol|todo`，与面板块状态双向同步) ｜ 图片。链接较低频,**收进格式面板「文字样式」行**(点 `data-mark=link` 拉起链接面板)。其余格式收进「格式」面板(**additive**:面板列全集,工具栏快捷件在面板里也有,状态双向同步)。
- 结构:`.editor-dock-wrap`(贴底，包住工具栏 + 面板) > `.toolbar.editor-dock` + `.tb-panel[data-panel=format|color|link]`;`.editor-dock-wrap.panel-open` 时工具栏补底分割。面板加 `.kb` = 键盘位高度(`min-height:288px` 向软键盘看齐、内容多时自然生长,`max-height:62vh` 兜底滚动)。
- 触发钮在工具栏上用 `data-tb="format|color|image"` 或 `data-tb-block="ul|ol|todo"`(**不用 `data-toggle`**,故 screen.js 不当纯 toggle);开关/选块/选色/链接逻辑在 `editor.js`。
- **格式面板** `.tb-panel[data-panel=format] > .tb-fmt`,三段(`.tb-sec-lab` 段头):
  - **段落** `.tb-headings > .tb-h-opt[data-level=p|1|2|3]`(`.g` 字形 + `.l` 小标签，选中 `.on`)——比 AppFlowy 原件**多一个显式「正文」项**。
  - **列表与块** `.tb-blocks > .tb-blk[data-block=ul|ol|todo|quote|code|callout|divider]`(图标 + 文字，3 列网格，radio 互斥选中 `.on`;`divider` 为一次性插入不驻留)。与段落互斥(选块清标题、选标题清块)。
  - **文字样式** `.tb-marks > .tb-mark[data-mark=bold|italic|underline|strike|icode|link]`(独立 toggle;`bold`/`italic` 与工具栏快捷件双向同步;`link` 不 toggle、点击拉起链接面板)。
  - 任一块/非正文标题激活时,工具栏 `Aa` 触发钮点亮 `.on`。
- **颜色面板** `.tb-panel[data-panel=color].kb > .tb-pal`:两组 `.tb-pal-lab` + `.tb-pal-row[data-pal=text|hl]`,swatch `.tb-sw`(选中 `.on` = accent 光环；`.dot-default`/`.dot-none` 为默认/无)。色板由 `editor.js` `TEXT_COLORS`/`HL_COLORS` 注入,是**编辑器色板真源**。
- **链接面板** `.tb-panel[data-panel=link].kb > .tb-link`:URL 单字段(`.field>.input`) + `.tb-link-acts`(取消/完成)——对齐 AppFlowy `MobileLinkMenu`,**不加「显示文字」字段**。
> Flutter:维持 `MobileToolbarItem.withMenu` 的内联面板;「格式」对应一个 `withMenu` 项,内部按段落/块/文字三段排;块项调 `formatNodeToType`/`CalloutBlockKeys`/`CodeBlockKeys` 等。颜色项把 DayZ 色板传进 `textColorOptions`/`backgroundColorOptions`。完整差异与落地要求见 `docs/handoff/editor.md`。

### 新建日记本选色 `.nj-*`（sheet 内表单 · 仅原型）
`.nj-colorlab`(小标题) + `.nj-colors > .nj-color[data-c]`（六色圆钮，选中 `.on` = 外环 + 白勾）。由 `screen.js` `openNewJournal()` 注入 sheet 的 `content`。色板 = 三主题色 + 三扩展色。

### 设置可点选行 `.set-row.tappable`（仅原型）
给 `.set-row` 加 `.tappable` → hover/active 底纹 + 指针，标记「点开选择器」。配 `data-theme-picker` / `data-mode-picker[data-appearance]`；右侧 `.val` 显当前值（主题色含色点，外观含 `.mv`）。

> 一次性屏内样式（不登记、不复用）：回收站 `.trash-*`、日历 `.cm-*`、回忆卡片 `.mc`/`.mem-*` 直接写在各自 `screens/*.html` 的 `<style>`（按 `_template` 约定）。

---

## 4. 模式 / Patterns

### 移动设备框 `.device`
`.device > .screen`（`.screen` 已设 `position: relative`，承载抽屉/FAB 的绝对定位层）。顶栏 `.app-top`（`.ico.menu` 菜单钮 + `.title` + `.acts`）。

### 抽屉侧边栏 `.drawer-stage`（手机端导航主入口）
结构：`.drawer-stage > .screen > [内容] + .scrim + .drawer`。
打开/关闭：任意元素加 `data-drawer-open` / `data-drawer-close`；点 `.scrim` 关闭。状态类 `.drawer-stage.open`。
抽屉内：`.dw-head`（`.avatar`+`.who`）→ 若干 `.dw-section`（`.dw-label` 分组标题 + `.dw-item`）→ `.dw-foot`（内嵌一个 `.dw-section`，仅放「设置」）。**搜索不在抽屉里**，统一走顶栏。结构（与真实屏一致）：日记本（全部日记 + 各本色点）→ 浏览（往年今日 / 收藏 / 日历 / 回收站）→ 底部设置。抽屉底色用暖纸 `--bg`（非纯白）。
- `.dw-item` 选中加 `.on`（accent-soft 底 + 左侧色条）；带 `data-nav` 的项（往年今日 / 设置）点击走导航、不参与同组选中。
- 日记本色点 `.dw-dot`（对应 DB 里 journal.color）；右侧计数 `.count`。
> 同组内 `.dw-item` 点击互斥选中已由 `spec.js` 处理。

### 底部 FAB 速拨 `.fab-wrap`（取代标签栏）
**轻点 = 写日记；长按 ~0.35s = 展开二级动作**（拍照/语音/清单）。
**`.fab-scrim` 是 `.fab-wrap` 的「后继兄弟」（同在 `.pg`/`.screen` 下），不在 `.fab-wrap` 内**——这样它能 `position:absolute; inset:0` 覆盖整屏做背景压暗+模糊，且 z-index(6) 低于 `.fab-wrap`(7)，展开时按钮与动作浮在遮罩之上、保持清晰（曾因放在 wrap 内、z 高于按钮而把按钮糊掉，已修）。开态由 `.fab-wrap.open ~ .fab-scrim` 驱动。
```html
<div class="fab-wrap">
  <div class="fab-actions">
    <div class="fab-action" data-label="拍照"><span class="lab">拍照</span><button class="mini"><svg…></svg></button></div>
    <!-- 语音 / 纯文字… -->
  </div>
  <button class="fab-main"><svg><path d="M12 5v14M5 12h14"/></svg></button>
</div>
<div class="fab-scrim"></div>   <!-- 紧跟 .fab-wrap 之后，全屏遮罩 -->
```
长按/轻点逻辑由 `screen.js`（产品）/ `spec.js`（规范演示）接管；`data-label` 是二级动作提示文案。点 `.fab-scrim` 关闭（`screen.js` 用 `document.querySelector('.fab-scrim')` 绑定）。
> **立体**：`.fab-main` 用色相受光渐变 + 三层投影（主色光晕/环境影/接触影）+ `::before` 顶部细高光；按压态加深下沉、长按态浮起。Flutter 用 `BoxDecoration(gradient + boxShadow[])` 落地（无 inset 阴影，顶高光用顶部浅渐变或 0.5px 白边）。
> 导航走抽屉、创建走 FAB —— 这是 DayZ 的移动端基本盘，新页面沿用即可。

---

## 5. 图标约定
- 全部**内联 SVG**，`viewBox="0 0 24 24"`、`fill="none"`、`stroke="currentColor"`、`stroke-width="2"`（FAB 加号 2.2–2.4），`stroke-linecap/linejoin="round"`。
- **单色**：图标统一用 `stroke="currentColor"` 继承父级文字色 → 自动随主题、保持安静克制；**不做多彩图标**（试过逐图标上色，过于花哨，已回退）。
- 唯一的彩色例外：**日记本色点 `.dw-dot`**（对应 DB 里 journal.color，是数据本身的颜色）；以及**收藏星**用 `--favorite`。
- 尺寸由容器的 `svg { width/height }` 控制，勿在 svg 上写死颜色。
- **对齐**：放在 `display:flex; align-items:center` 容器里，svg 设 `display:block; flex-shrink:0`（spec.css 已统一）。
- **几何对称**：齿轮等装饰齿要轴对齐（正上下左右 + 四角），别用倾斜的 Feather 默认齿轮。
- **收藏星（唯一规范路径）**：以中心 (12,12) 数学求点的对称五角星，外半径 9.5 / 内半径 4.2、顶点正上。填充态 `fill="currentColor"`、描边态 `fill="none" stroke="currentColor"`，**只换 fill/stroke，path 不变**——勿再手绘以免歪斜：
  `<path d="M12 2.5L14.47 8.6 21.04 9.06 16 13.3 17.58 19.69 12 16.2 6.42 19.69 8.01 13.3 2.97 9.06 9.53 8.6Z"/>`
- **能用 SVG 就用 SVG**：心情表情也用手绘 SVG 笑脸，不用 emoji 当功能图标；emoji 仅作纯文本提示内容（如 toast）。

---

## 6. 新增组件的约定
1. **挂 token**：颜色/间距/圆角/阴影一律 `var(--*)`；缺语义时优先组合现有 token，不新造颜色。
2. **命名**：组件级用语义类名（`.timeline` `.drawer`），子元素短名（`.head` `.body` `.foot`）；模块前缀用于易冲突区（`.dw-` 抽屉、`.fab-` 速拨、`.t-` 排版）。
3. **布局**：成组元素用 flex/grid + `gap`，不用裸 margin/空白节点。
4. **可达性**：移动端点击目标 ≥ 44px；聚焦态用 `--accent-ring`。
5. **双模式自测**：浅/深 + 三主题（6 组合）都看一眼，确认无写死色。
6. **定档即记**：确认定稿后写入 `CHANGELOG.md`（`- [模块] 描述`），新模块补「模块索引」。
