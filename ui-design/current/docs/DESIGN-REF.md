# DayZ 设计规范 · AI 速查手册（DESIGN-REF）

> 本文件是**给 AI / 开发快速复用的索引**，不是给人看的展示文档（展示见 `DayZ 设计规范/DayZ 设计规范.html`）。
> **复用任何组件前先读本文件**：直接抄类名与最小 HTML 片段，不必重读 CSS。
> 黄金规则：**只引用 `var(--*)`，绝不写死颜色 / 字号 / 间距**；改完若定档，按 `CHANGELOG.md` 规矩记录。

## 文件结构
```
项目根/
├── CLAUDE.md             # 项目说明（必须在根目录，自动加载）
├── docs/
│   ├── DESIGN-REF.md     # 本文件 · AI 速查
│   └── CHANGELOG.md      # 更新日志（按天 + 模块标签）
├── DayZ 设计规范/
│   ├── DayZ 设计规范.html # 人看的展示文档（含实时主题/明暗切换）
│   └── assets/
│       ├── tokens.css    # 所有设计变量（唯一真源）
│       ├── spec.css      # 布局 + 组件样式（含页面级组件）
│       ├── spec.js       # 主题/明暗切换、交互演示、FAB 长按
│       └── demo_image.png
└── pages/                # 产品页面设计（交付物）
    ├── DayZ 页面设计.html # 外壳：原型路由 + 静态多状态画布（双模式 viewer）
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
- 在根元素挂 `data-theme` + `data-mode`：
  - `data-theme` = `purple`（雾紫）｜ `amber`（暖黄）｜ `sage`（雾绿）
  - `data-mode` = `light` ｜ `dark`
- **中性色只随 `data-mode` 变；强调色随 `data-theme` + `data-mode` 变。**
- 三套主题**共享同一套 token 命名与语义**，仅色相不同 → 组件只要用变量就自动适配 6 种组合。
- `spec.js` 负责切换并持久化到 `localStorage['dayz-spec-pref']`。

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

### 2.4 排版类（直接套用）
`.t-display` `.t-h1` `.t-h2`（衬线）· `.t-h3`（无衬线粗）· `.t-body`（UI 正文 1.7）· `.t-diary`（日记衬线 1.85）· `.t-caption` · `.t-overline`
> CJK 正文行高 1.7–1.8；标题/日记正文用衬线，界面文字用无衬线。

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
按钮 `.tb`（激活 `.on`）；分隔 `.div`；演示切换加 `data-toggle`。对接 **AppFlowy Editor**（能力集见 §3b 「编辑页 `.compose-*`」）。

### 提示条 `.toast` / 弹窗 `.dialog`
`.toast` 深色款 + `.toast.surface` 表面款（`.ic` 图标 / `.acc` 操作）；`.dialog`（`h4` + `p` + `.acts`）。

### 时间线日记卡片 `.entry`
```html
<div class="entry">
  <div class="date"><div class="d">29</div><div class="m">MAY</div><div class="w">周五</div></div>
  <div class="card">
    <div class="photo"><img src="…"></div>      <!-- 可选配图 -->
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

---

## 3b. 页面级组件（产品页面复用）
> 用于实际页面（见交付物 `pages/DayZ 页面设计.html`）。沿用 token，禁止写死值。
> **真源分两处**：跨端共享的组件在 `DayZ 设计规范/assets/spec.css`（改后须复制到 `pages/assets/`）；**仅原型用的屏内组件/骨架**在 `pages/assets/screen.css`（不回流设计规范）。本节(3b)= spec.css；下一节(3c)= screen.css。

### 时间线年月吸顶头 `.tl-month`
`position:sticky; top:0`，置于滚动容器顶部。
```html
<div class="tl-month"><span class="y">5月</span><span class="c">2026 · 12 篇</span></div>
```

### 单篇阅读版式 `.reader`
`.r-kicker`(日期，含日历图标) → `h1`(衬线大标题) → `.r-meta`(weather-chip + tag + 地点) → `.r-body p`(衬线 1.85) → `.r-tags`。封面用 `.read-hero > img`。

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

### 屏幕骨架 `.pg`（固定头 + 可滚动区）
`.pg`(flex 列) > `.app-top`(或 `.search-head`，固定、让出 54px 状态栏) + `.app-scroll`(唯一滚动区)。可选修饰：`.pg.drawer-stage`(挂抽屉)、`.pg.has-dock`(底部停靠工具栏留白)。详见 `docs/PROTOTYPE-ARCH.md` §3。

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

### 编辑器富格式块 `.cb-*`（compose-body 内 · 演示 AppFlowy 块）
`.cb-h`(标题) · `.cb-list`(有序/无序) · `.cb-todo`(待办，勾选态 `.done`，`.bx`+`.tx`) · `.cb-quote`(引用)。仅用于编辑页「富格式」状态示意。

---

## 4. 模式 / Patterns

### 移动设备框 `.device`
`.device > .screen`（`.screen` 已设 `position: relative`，承载抽屉/FAB 的绝对定位层）。顶栏 `.app-top`（`.ico.menu` 菜单钮 + `.title` + `.acts`）。

### 抽屉侧边栏 `.drawer-stage`（手机端导航主入口）
结构：`.drawer-stage > .screen > [内容] + .scrim + .drawer`。
打开/关闭：任意元素加 `data-drawer-open` / `data-drawer-close`；点 `.scrim` 关闭。状态类 `.drawer-stage.open`。
抽屉内：`.dw-head`（`.avatar`+`.who`）→ `.dw-search` → 若干 `.dw-section`（`.dw-label` 分组标题 + `.dw-item`）→ `.dw-foot`。
- `.dw-item` 选中加 `.on`（accent-soft 底 + 左侧色条）；不可选条目加 `.static`（设置/回收站）。
- 日记本色点 `.dw-dot`（对应 DB 里 journal.color）；右侧计数 `.count`。
> 同组内 `.dw-item` 点击互斥选中已由 `spec.js` 处理。

### 底部 FAB 速拨 `.fab-wrap`（取代标签栏）
**轻点 = 写日记；长按 ~0.35s = 展开二级动作**（拍照/语音/清单）。
```html
<div class="fab-wrap">
  <div class="fab-scrim"></div>
  <div class="fab-actions">
    <div class="fab-action" data-label="📷 拍照"><span class="lab">拍照</span><button class="mini"><svg…></svg></button></div>
    <!-- 语音 / 清单… -->
  </div>
  <button class="fab-main"><svg><path d="M12 5v14M5 12h14"/></svg></button>
</div>
```
长按/轻点逻辑、提示气泡 `.fab-toast` 均由 `spec.js` 接管；`data-label` 是点击二级动作时的提示文案。
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
- **能用 SVG 就用 SVG**：心情表情也用手绘 SVG 笑脸，不用 emoji 当功能图标；emoji 仅作纯文本提示内容（如 toast）。

---

## 6. 新增组件的约定
1. **挂 token**：颜色/间距/圆角/阴影一律 `var(--*)`；缺语义时优先组合现有 token，不新造颜色。
2. **命名**：组件级用语义类名（`.timeline` `.drawer`），子元素短名（`.head` `.body` `.foot`）；模块前缀用于易冲突区（`.dw-` 抽屉、`.fab-` 速拨、`.t-` 排版）。
3. **布局**：成组元素用 flex/grid + `gap`，不用裸 margin/空白节点。
4. **可达性**：移动端点击目标 ≥ 44px；聚焦态用 `--accent-ring`。
5. **双模式自测**：浅/深 + 三主题（6 组合）都看一眼，确认无写死色。
6. **定档即记**：确认定稿后写入 `CHANGELOG.md`（`- [模块] 描述`），新模块补「模块索引」。
