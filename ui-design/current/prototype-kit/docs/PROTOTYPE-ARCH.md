# 页面原型架构（PROTOTYPE-ARCH）

> 本文件沉淀 `pages/` 这套**「一套屏幕源、两种呈现」**的设计原型架构，并给出**对应的 Flutter 落地映射**。
> 定位：`pages/` 是**设计原型**（HTML，用于评审与交互演示），**不是产品代码**；真实产品是 Flutter。本文件让两边对得上。
> 配套：视觉 token/组件见 `DESIGN-REF.md`；变更记录见 `CHANGELOG.md`。

---

## 0. 一句话概括
**每个屏幕是一个独立 HTML 文件（`screens/*.html`），原型模式把它当 iframe「活」嵌进 iPhone 里跑真交互，画布模式把同一批文件按状态缩略平铺——同一份源，零markup重复。**

---

## 1. 复用关系（原型 ↔ 画布）

```
            screens/timeline.html  reader.html  editor.html …   ← 唯一真源（屏幕本体）
                       │                    │
        ┌──────────────┴───────┐   ┌────────┴─────────────┐
        ▼                      ▼   ▼                      ▼
  原型模式（proto）                画布模式（canvas）
  单台 iPhone 内 1 个 iframe        每屏多个 iframe（不同 ?state=）
  实时交互 + 路由栈                  无限画布：点阵网格 + 平移缩放
                                    卡片可直接交互（屏内抽屉/FAB/开关）
```

- **画布是“方便看效果”的浏览面**：无模式切换。平移是通用手势（空白拖 / 滚轮 / `空格`+拖），缩放用 `⌘`+滚轮、右下控件或 `+`/`-`/`0`；卡片 `pointer-events:auto`，可直接点进去试屏内交互（抽屉/FAB/开关/搜索展开；跨屏 nav 仍仅原型路由生效）。

- **两种模式加载的是同一批 `screens/*.html`**，区别只在外壳（`index.html` + `pages.css` + `app.js`）如何摆放 iframe。
- 屏幕**不知道**自己被谁嵌入：它只负责渲染自身 + 通过 `postMessage` 向上发导航意图。外壳决定「原型里真的跳转」还是「画布里忽略」。
- 改一处屏幕内容 → 原型和画布同时更新。**这是本架构的核心收益。**

---

## 2. 文件职责

| 文件 | 职责 | 谁加载 |
|---|---|---|
| `screens/<id>.html` | 单屏本体：结构 + 多状态块（`data-when`） | 两种模式都以 iframe 加载；也可单独打开调试 |
| `assets/screen.css` | **屏内**样式：iOS chrome、固定头/滚动区、抽屉层级、空状态、多状态显隐 | 仅 `screens/*.html` |
| `assets/screen.js` | **屏内**逻辑：注入 chrome、按 `?state=` 显隐、屏内交互（抽屉/FAB/开关）、`postMessage` 导航、接收主题 | 仅 `screens/*.html` |
| `assets/tokens.css` `spec.css` | 设计 token + 组件（自设计规范复制，保持同步） | 屏 + 外壳 |
| `index.html` | **外壳**：顶栏（主题/明暗/呈现切换）、iPhone 外框、原型栈容器、画布容器 | 顶层 |
| `assets/pages.css` | **外壳**样式：iPhone 外框、iframe 路由栈转场、**无限画布**（点阵网格 `.board` / 变换层 `.canvas-world` / 缩放控件 `.cv-zoom`）与左侧索引 | 仅外壳 |
| `assets/app.js` | **外壳**逻辑：主题下发各 iframe、原型路由栈（缓存+预热）、画布构建、**平移/缩放控制器**（`view{x,y,k}`→`canvas-world` transform + 网格 background-position/size 同步）、索引聚焦联动 | 仅外壳 |

> 边界铁律：**屏内只管自己**；**跨屏与摆放只在外壳**。屏内不得直接 `parent.location` 或操作别的 iframe，一律走 `postMessage`。

---

## 3. 屏幕契约（写新屏照抄）

```html
<!-- screens/<id>.html -->
<html lang="zh-CN">
<head>
  <!-- 首屏脚本：把 URL 参数写到 <html> 上，供 screen.css/js 读取 -->
  <script>(function(){var p=new URLSearchParams(location.search),r=document.documentElement;
    r.setAttribute("data-theme",p.get("theme")||"purple");
    r.setAttribute("data-mode", p.get("mode") ||"light");
    r.setAttribute("data-state",p.get("state")||"default");})();</script>
  <link …fonts…>
  <link rel="stylesheet" href="../assets/tokens.css">
  <link rel="stylesheet" href="../assets/spec.css">
  <link rel="stylesheet" href="../assets/screen.css">
</head>
<body>
  <div class="pg [drawer-stage] [has-dock]">
    <div class="app-top">…固定头…</div>
    <div class="app-scroll">
      <div data-when="default">…默认状态内容…</div>
      <div class="empty" data-when="empty">…空状态…</div>
      <!-- 多状态：data-when="a b" 命中任一即显示 -->
    </div>
    <!-- 可选：.scrim + .drawer（抽屉）、.fab-wrap（FAB） -->
  </div>
  <script src="../assets/screen.js"></script>
</body>
</html>
```

### 导航：屏内只「喊」，不自己跳
```html
<button data-nav="reader">…</button>   <!-- 请求进入某屏 -->
<button data-nav-back>返回</button>     <!-- 请求返回 -->
```
`screen.js` 捕获点击 → `parent.postMessage({type:'nav', to:'reader'})` / `{type:'back'}`。
外壳收到后：原型模式执行真实 push/pop；画布模式忽略（静态）。

### 多状态：URL 驱动
- 用 `?state=xxx` 区分；屏内 `[data-when="xxx"]` 命中才显示（`screen.js` 加 `.show`）。
- 特例：`?state=drawer` 时 `screen.js` 自动给 `.drawer-stage` 加 `.open`（画布里直接看抽屉打开态）。
- **新增状态** = 加一个 `data-when` 块 + 在外壳 `SCREENS[].states` 登记一项。

---

## 4. postMessage 协议（屏 ↔ 外壳）

| 方向 | 消息 | 含义 |
|---|---|---|
| 屏 → 外壳 | `{type:'nav', to:'<id>'}` | 进入某屏（原型 push；画布忽略） |
| 屏 → 外壳 | `{type:'back'}` | 返回（原型 pop） |
| 屏 → 外壳 | `{type:'ready'}` | 屏已就绪，索要当前主题 |
| 屏 → 外壳 | `{type:'settheme', theme}` | 设置类屏请求换主题色 → 外壳 applyTheme + 广播 |
| 屏 → 外壳 | `{type:'setmode', appearance}` | 请求外观 light/dark/system（system 用 `matchMedia(prefers-color-scheme)`） |
| 外壳 → 屏 | `{type:'theme', theme, mode}` | 下发主题/明暗，屏即时换肤 |

> 屏内交互例：**分段控件**、**抽屉开关**、**FAB 导航**等由 `screen.js` 统一处理；业务专属交互在各屏自行添加。全由 `screen.js` 处理，不需外壳参与。

主题切换：外壳改自身 `data-theme/mode` 后，向**所有** `.workspace iframe` 广播 `theme` 消息；新建/预热的 iframe 在 `ready` 时主动拉一次，避免初始不同步。

---

## 5. 原型路由栈（秒开关键）
- 外壳维护 `stack`（id 数组）+ `pageCache`（id→已建 iframe 页）。
- `pushScreen`：复用缓存页，仅调 `z-index` 与转场 class（`is-entering`→入场，前页 `is-behind`）。
- `popScreen`：顶页 `is-leaving` 滑出，到期 `is-parked` 泊到屏外，**不销毁 iframe**。
- **预热**：首屏就绪后，空闲时段（`requestIdleCallback`）预建其余屏 iframe（泊在屏外 `is-parked`）。→ 后续跳转无加载等待，秒开。开。
- ⚠️ iframe **重新挂载 DOM 会重载**，所以缓存页只移 `z-index`/class，绝不 reparent。

---

## 5b. 画布交互（无限画布 + 三模式）
> 画布是**纯设计评审视图**，不进产品。平移/缩放与三模式都在外壳 `app.js`，屏内零感知。

## 5b. 画布交互（无限画布 · 浏览）
> 画布是**纯设计评审/看效果视图**，不进产品。无模式切换——平移/缩放都在外壳 `app.js`，屏内零感知。

**视图模型**：`view{x,y,k}` → `.canvas-world` 的 `translate()scale()`；点阵网格用 `.board` 的 `background-position/size` 跟随 `view` 同步，造无限延展感。`zoomAt(cx,cy,k)` 以光标为锚点缩放。

**交互**：
- **平移**（通用手势）：空白处拖拽 / 滚轮 / `空格`+拖拽（按住空格给 `.board.space-pan`，临时把卡片 iframe 设 `pointer-events:none` 以便在卡片上也能拖）。
- **缩放**：`⌘/Ctrl`+滚轮（以光标为锚点）、右下 `.cv-zoom` 控件、快捷键 `+`/`-`/`0`（重置自适应）。
- **卡片可交互**：`.cv-frame iframe` 默认 `pointer-events:auto`，可直接点进屏内试抽屉/FAB/开关/搜索；跨屏 nav 在画布忽略（仅原型路由生效）。
- 左侧索引点击 `focusSection()` 平移居中目标区块。

**铁律**：`pointerdown` 命中 `.cv-zoom` 直接 return——否则 `setPointerCapture` 会吞掉控件点击。键盘只在 `present==='canvas'` 且焦点不在输入框时生效。

> 注：曾试做「拖拽/交互/选择」三模式 + 元素 token 反查检视器，评估为面向 AI/开发场景过重（token 速查已在 DESIGN-REF），**回退为单一浏览**。如需取 token 查 `DESIGN-REF.md`。

---

## 6. Flutter 实现对照（产品落地）
> HTML 原型里的每个机制，对应 Flutter 的标准做法。**做产品时照此映射，别照抄 HTML。**

| 原型（HTML） | Flutter 落地 |
|---|---|
| `screens/<id>.html` | 一个页面 Widget（`StatelessWidget`/`StatefulWidget`），用 `go_router` / Navigator 2.0 注册路由 |
| iframe 路由栈 + iOS 推入/返回转场 | `Navigator.push` + `CupertinoPageRoute`（系统自带右滑入场 + 边缘返回手势） |
| `postMessage({type:'nav'})` | 直接 `context.go('/reader')` / `Navigator.push`；无需消息层 |
| `?state=` 多状态 | 页面入参 + 状态管理（`Riverpod`/`Bloc`）：空/有数据/加载 用同一 Widget 按 state 渲染 |
| iOS chrome（状态栏/灵动岛/Home 条） | 真机系统提供；用 `SafeArea` + `MediaQuery.padding` 让位，不要自绘 |
| 固定头 `.app-top` + `.app-scroll` | `Scaffold(appBar: …)` 或 `CustomScrollView` + `SliverAppBar(pinned:true)` |
| 抽屉 `.drawer-stage` | `Scaffold(drawer: Drawer(...))`，`scrim` 与滑动系统内置 |
| FAB `.fab-wrap`（轻点动作） | `FloatingActionButton`（`onPressed`→导航/动作） |
| 主题 token（`tokens.css`） | `ThemeData` + 自定义 `ThemeExtension`（多主题×明暗）；token 名一一对应 |
| 底部弹层 `.sheet`（`DZ.sheet` / `DZ.confirm`：动作菜单/选择器/轻表单/确认） | `showModalBottomSheet`（圆角顶 + 拖拽柄 + `SafeArea` 底部留白）；确认用 `showModalBottomSheet`/`AlertDialog`，单选用 `ListTile`+`trailing: check` |
| 设置选择器 → `settheme/setmode` | 设置页改 `ThemeData` / `ThemeMode`，全树 rebuild；「跟随系统」= `ThemeMode.system` + `MediaQuery.platformBrightness` |
| 主题广播到 iframe | 顶层 `ThemeData` 切换，全树自动 rebuild；无需广播 |
| 画布多状态平铺 / 浏览 | **无运行时对应**——纯设计评审视图；Flutter 侧用 widgetbook/storybook 看各状态 |
| 氛围占位图 `assets/img/*` | 真实用户照片（本地相册）；占位图仅原型用 |

---

## 7. 新增一屏 / 一状态的清单
1. 写 `screens/<id>.html`（照 §3 契约，引 3 个 css + screen.js）。
2. 外壳 `app.js` 的 `SCREENS[]` 加一项：`{id, idx, name, label, proto:<默认态>, states:[…]}`。
3. 需要被别处跳转 → 在来源屏的元素上加 `data-nav="<id>"`。
4. 新状态 = 屏内加 `data-when` 块 + `states[]` 加一项。
5. 双模式各看一眼（原型能跳到、画布能平铺），三主题×明暗抽查。
6. 定档：更新 `CHANGELOG.md`；若动了 token/组件，同步 `DESIGN-REF.md`；动了架构，回来更新本文件。

---

## 8. 复用这套框架做新原型（移植指南）
> 这套「一套屏幕源、两种呈现（原型 iPhone 路由 + 无限画布浏览）」是**与业务解耦的通用外壳**，以后做别的原型可直接照搬。外壳代码不含任何业务，唯一的项目耦合点是 `SCREENS[]` 清单 + 视觉 token + 屏幕本体。

**外壳文件（直接复制，几乎不改）**
- `pages/index.html`（壳容器：顶栏 + iPhone 框 + 原型栈 + 画布）— 改标题/品牌字样即可。
- `pages/assets/pages.css`（外壳样式：iPhone 框、路由栈转场、无限画布）— 通用。
- `pages/assets/app.js`（外壳逻辑：主题下发、路由栈+预热、画布平移缩放、索引）— 通用，**只改顶部 `SCREENS[]`**。
- `pages/assets/screen.css` `screen.js`（屏内：iOS chrome、`?state=` 显隐、抽屉/FAB/搜索、`postMessage` 导航、收主题）— 通用。
- `pages/screens/_template.html`（空屏模板，照 §3 契约，复制改名即用）。

**项目专属（每个新原型要写的 3 处）**
1. **视觉**：换 `assets/tokens.css`（+ `spec.css` 组件）——来自该项目的设计规范。外壳与屏全走 `var(--*)`，换了 token 自动换肤。
2. **清单**：改 `app.js` 顶部 `SCREENS[]`（每屏 `{id, idx, name, label, proto:<默认态>, states:[…]}`）。这是外壳唯一认识业务的地方。
3. **屏幕**：照 `_template.html` 写每个 `screens/<id>.html`（多状态用 `data-when`，跳转用 `data-nav`）。

**移植步骤**：复制 `pages/` 整目录 → 替换 tokens/spec → 清空 `screens/` 只留 `_template.html` → 按 §7 一屏一屏加。机制（路由栈、画布、主题广播、postMessage 协议）全部现成,无需重写。

> 设备外框、状态栏不想自绘时,也可换用平台的 `ios_frame`/`android_frame` 起子组件;本框架自带的 iPhone 框已够用。
