# Prototype Kit · 原型框架（可复用）

> 一套与业务解耦的 HTML 原型外壳:**「一套屏幕源、两种呈现」**——
> 同一批 `screens/*.html`,**原型模式**当 iframe「活」嵌进 iPhone 里跑真交互(带 iOS 推入/返回转场 + 路由栈),
> **画布模式**把它们按状态平铺在可平移缩放的无限画布上看效果。改一处屏幕,两种呈现同时更新。
>
> 本套来自 DayZ 项目的 `pages/`,已抽成业务无关的启动套件。完整架构 + Flutter 落地映射见 `../docs/PROTOTYPE-ARCH.md`。

> 🚀 **新项目从 0 到 1 怎么走?先读 [`GETTING-STARTED.md`](GETTING-STARTED.md)** —— 设计操盘手册(定基调 → 搭设计系统 → 立文档 → 画屏 → 定档维护)。下面是浓缩版流程 + 坑。

---

## 文档体系(随 kit 一起带走)
这套方法的另一半是**文档纪律**,模板都在 kit 里:
- `GETTING-STARTED.md` —— 从 0 到 1 的设计操盘手册(先读这个)。
- `CLAUDE.template.md` —— 项目说明骨架(复制到新项目根改名 `CLAUDE.md`)。
- `docs/DESIGN-REF.template.md` —— AI 速查手册骨架(token 全表 + 组件目录)。
- `docs/CHANGELOG.template.md` —— 更新日志骨架(按天 + 模块标签,定档即写)。
- `docs/PROTOTYPE-ARCH.md` —— 页面原型架构(已通用,直接用)。

---

## 从 0 到 1 流程(浓缩版)
> 完整版在 `GETTING-STARTED.md`。铁律:**设计系统先行**——token 真源到位才开始画屏。
```
空项目
 └─① 提问定基调 ───────► 填 CLAUDE.md（复制 CLAUDE.template.md）
 └─② tokens.css → spec.css → 展示页.html  （token 先行，组件只用 var(--*)）
 └─③ docs/ 三件套（DESIGN-REF / PROTOTYPE-ARCH / CHANGELOG）
 └─④ 复制 kit 到 pages/ → 改 SCREENS[] → 照 _template 一屏屏画
 └─⑤ 定档即写 changelog + 同步 DESIGN-REF（不腐化）
```

## 易踩的坑
- **跳过设计系统直接画屏** → 一边发明颜色一边设计,必然腐化。先做 `tokens.css` 真源。
- **写死颜色/字号/间距** → 一律 `var(--*)`。未解析的 `var()` 会静默回退浏览器默认值,很难发现。写前先在 `tokens.css` 查真实变量名,**别猜**。
- **自绘 iOS 状态栏/灵动岛/Home 条** → 由 `screen.js` 注入,屏内只写内容区。
- **加了屏却不登记 `SCREENS[]`** → 原型跳不到、画布不平铺。`SCREENS[]` 是外壳唯一认识业务的地方。
- **跨屏跳转直接写 `<a href>`** → 该用 `data-nav="<目标屏 id>"` / `data-nav-back`,交给 `screen.js` 走路由栈(否则画布里会整页跳转)。
- **画布里点跨屏 nav 没反应** → 正常。画布只看不路由;要走流程去原型模式。
- **屏内改了 token/组件但忘同步文档** → 定档同一步补 `DESIGN-REF.md` + 写 `CHANGELOG.md`,二者成对出现;否则下次复用时查不到。
- **`tokens.css`/`spec.css` 两处不同步** → 设计规范目录是真源,`pages/assets/` 下是复制品;改了真源记得重新复制过去。
- **吸顶子头与「覆盖式顶栏」之间留出一段空隙** → `position:sticky` 的 `top` 是相对滚动容器**内容盒**量的，而 `.app-scroll` 已 `padding-top:var(--top-h)` 把内容推到顶栏之下；此时吸顶子头要用 **`top:0`**（不是 `top:var(--top-h)`，否则会把 `--top-h` 叠加两次，正好空出一整段）。
- **`box-shadow`/`transition` 让阴影压根不显示** → CSS **不能从 `none` 过渡 `box-shadow`**（部分引擎会卡在起始帧、computed 恒为透明零值）。要么去掉过渡做即时，要么给一个**显式透明起点**（`box-shadow: 0 0 0 0 rgba(...,0)`）再过渡到目标值。debug 时：`transition:none` 一关阴影就出来 = 八成是这个坑。
- **顶栏与紧贴其下的吸顶子头「看着割裂」** → 让两者用**同一份毛玻璃配方**（同 `--bg` 透明度 + 同 `blur`），并把分割线/投影从「两者之间」挪到「整个头部最下沿」（只给真正吸顶中的那一个子头 + 柔和投影），即并成一条连续磨砂头。

---

## 目录
```
prototype-kit/
├─ index.html              外壳:顶栏(主题/明暗/原型·画布切换) + iPhone 框 + 画布
├─ assets/
│  ├─ pages.css            外壳样式(iPhone 框 / 路由栈转场 / 无限画布)   ← 通用,不用改
│  ├─ app.js               外壳逻辑(主题下发 / 路由栈+预热 / 画布平移缩放) ← 只改顶部 SCREENS[]
│  ├─ screen.css           屏内样式(iOS chrome / 固定头滚动区 / 抽屉 / 空状态) ← 通用
│  ├─ screen.js            屏内逻辑(注入 chrome / 按 ?state 显隐 / 抽屉·FAB / postMessage 导航) ← 通用
│  ├─ tokens.css           设计 token(颜色/字体/间距/圆角/阴影)            ← 换成你的设计规范
│  └─ spec.css             组件样式                                       ← 换成你的设计规范
└─ screens/
   ├─ _template.html       空屏模板(照契约,复制改名即用)
   ├─ home.html            示例:列表 + 空状态,点行 → 详情
   └─ detail.html          示例:详情 + 返回
```

直接打开 `index.html` 就能跑(默认带 DayZ 的 token 作示例视觉)。

---

## 复用到新项目(3 步)

1. **拷贝** —— 把整个 `prototype-kit/` 复制进新项目(可重命名为 `pages/` 等)。
2. **换视觉** —— 用新项目设计规范的 `tokens.css`(+ `spec.css`)替换 `assets/` 下同名文件。
   外壳与屏全走 `var(--*)`,换了 token 自动换肤。
3. **写屏幕** —— 清空 `screens/` 只留 `_template.html`,照它一屏屏写;
   每加一屏,在 `assets/app.js` 顶部的 `SCREENS[]` 登记一项。

> `SCREENS[]` 是外壳**唯一**认识业务的地方。机制(路由栈、画布、主题广播、postMessage 协议)全部现成,无需重写。

---

## 写一屏的契约(`_template.html` 已含)
- 根 `.pg`;固定头 `.app-top`(`.title` / 左 `.ico` 返回 / 右 `.acts`);滚动区 `.app-scroll`。
  - 顶栏是**悬浮覆盖层**:内容从其下方穿行,毛玻璃覆盖到状态栏(静止实底 → 滚动后 `.pg.scrolled` 浮起)。`screen.js` 实测顶栏高写入 `--top-h`;`.app-scroll` 已 `padding-top:var(--top-h)` 让位,吸顶元素用 `top:var(--top-h)`。
- iOS chrome(灵动岛/状态栏/Home 条)由 `screen.js` 注入,**别自绘**。
- 多状态:块上加 `data-when="xxx"`,`?state=xxx` 命中才显示;并在 `SCREENS[].states` 登记。
- 跳转:元素加 `data-nav="<目标屏id>"`(前进)或 `data-nav-back`(返回)。
  → `screen.js` 转 `postMessage`;原型模式真路由,画布模式忽略。
- 可选:`.drawer-stage`+`.scrim`+`.drawer`(抽屉)、`.fab-wrap`(FAB)、`.toolbar.editor-dock`(底栏)。

## 登记一屏(`app.js` 的 `SCREENS[]`)
```js
{ id: "home", idx: "01", name: "首页", label: "Home · 列表", proto: "default",
  states: [{ k: "default", n: "默认" }, { k: "empty", n: "空状态" }] }
```
`id`=文件名 · `proto`=原型模式默认打开的状态 · `states`=画布里平铺的各状态。

---

## 画布操作
- **平移**:空白拖拽 / 滚轮 / `空格`+拖拽。
- **缩放**:`⌘/Ctrl`+滚轮(锚定光标)、右下控件、`+` / `-` / `0`(重置自适应)。
- **卡片可交互**:直接点进屏内试抽屉/FAB/开关;跨屏 nav 仅原型模式生效。
- 左侧索引点击 → 平移居中该屏。

## 设备外框
自带现代 iPhone 框(灵动岛/窄边)。若想要别的设备,可换平台的 `ios_frame`/`android_frame` 起子组件。
