# DayZ 页面原型架构（PROTOTYPE-ARCH）

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
  实时交互 + 路由栈                  缩略平铺 + 左侧索引，pointer-events:none
```

- **两种模式加载的是同一批 `screens/*.html`**，区别只在外壳（`DayZ 页面设计.html` + `pages.css` + `app.js`）如何摆放 iframe。
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
| `DayZ 页面设计.html` | **外壳**：顶栏（主题/明暗/模式切换）、iPhone 外框、原型栈容器、画布容器 | 顶层 |
| `assets/pages.css` | **外壳**样式：iPhone 外框、iframe 路由栈转场、画布平铺与左侧索引 | 仅外壳 |
| `assets/app.js` | **外壳**逻辑：主题下发各 iframe、原型路由栈（缓存+预热）、画布构建、索引联动 | 仅外壳 |

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
    <div class="app-top">…固定头…</div>      <!-- 或 .search-head -->
    <div class="app-scroll">
      <div data-when="default">…默认状态内容…</div>
      <div class="empty" data-when="empty">…空状态…</div>
      <!-- 多状态：data-when="a b" 命中任一即显示 -->
    </div>
    <!-- 可选：.scrim + .drawer（抽屉）、.fab-wrap（FAB）、.toolbar.editor-dock -->
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
| 外壳 → 屏 | `{type:'theme', theme, mode}` | 下发主题/明暗，屏即时换肤 |

> 屏内交互例：**顶栏展开搜索**——点 `[data-search-open]` 使 `.app-top` 加 `.searching` 展开 `.topsearch` 输入框，回车发 `{type:'nav',to:'search'}`；`[data-search-close]` 收起。全由 `screen.js` 处理，不需外壳参与。

主题切换：外壳改自身 `data-theme/mode` 后，向**所有** `.workspace iframe` 广播 `theme` 消息；新建/预热的 iframe 在 `ready` 时主动拉一次，避免初始不同步。

---

## 5. 原型路由栈（秒开关键）
- 外壳维护 `stack`（id 数组）+ `pageCache`（id→已建 iframe 页）。
- `pushScreen`：复用缓存页，仅调 `z-index` 与转场 class（`is-entering`→入场，前页 `is-behind`）。
- `popScreen`：顶页 `is-leaving` 滑出，到期 `is-parked` 泊到屏外，**不销毁 iframe**。
- **预热**：首屏 `timeline` 就绪后，空闲时段（`requestIdleCallback`）预建其余屏 iframe（泊在屏外 `is-parked`）。→ 后续跳转无加载等待，搜索/往年今日等秒开。
- ⚠️ iframe **重新挂载 DOM 会重载**，所以缓存页只移 `z-index`/class，绝不 reparent。

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
| FAB `.fab-wrap`（轻点写/长按展开） | `FloatingActionButton` + 自定义 `GestureDetector(onLongPress)`；展开用 `showModalBottomSheet` 或自绘 speed-dial |
| FAB 立体（渐变+多层影+顶高光） | `Container(decoration: BoxDecoration(gradient: LinearGradient(...), boxShadow: [BoxShadow×3], shape: circle))`；顶高光用顶部浅色渐变或 0.5px 白色半透明 `Border`（Flutter 无 inset 阴影） |
| 主题 token（`tokens.css`） | `ThemeData` + 自定义 `ThemeExtension`（三主题×明暗 = 6 套）；token 名一一对应 |
| 顶栏展开搜索（`.topsearch` + `data-search-*`） | `SearchAnchor`/`showSearch(SearchDelegate)`，或 `AppBar` 内 `TextField` 切换；提交 → push 搜索结果页 |
| 主题广播到 iframe | 顶层 `ThemeData` 切换，全树自动 rebuild；无需广播 |
| 富文本编辑器（`editor.html` 工具栏） | **AppFlowy Editor**（`packages/appflowy-editor`），工具集即 §DESIGN-REF 所列；内容存 `content_json` + `content_plain` |
| 图标点缀色 `--ic-*` | 同名常量 / `ThemeExtension`；分类图标着色，chrome 图标用 `IconTheme` 当前色 |
| 画布多状态平铺 | **无运行时对应**——纯设计评审视图；Flutter 侧靠 widgetbook/storybook 类工具看各状态 |
| 氛围占位图 `assets/img/*` | 真实用户照片（本地相册）；占位图仅原型用 |

---

## 7. 新增一屏 / 一状态的清单
1. 写 `screens/<id>.html`（照 §3 契约，引 3 个 css + screen.js）。
2. 外壳 `app.js` 的 `SCREENS[]` 加一项：`{id, idx, name, label, proto:<默认态>, states:[…]}`。
3. 需要被别处跳转 → 在来源屏的元素上加 `data-nav="<id>"`。
4. 新状态 = 屏内加 `data-when` 块 + `states[]` 加一项。
5. 双模式各看一眼（原型能跳到、画布能平铺），三主题×明暗抽查。
6. 定档：更新 `CHANGELOG.md`；若动了 token/组件，同步 `DESIGN-REF.md`；动了架构，回来更新本文件。
