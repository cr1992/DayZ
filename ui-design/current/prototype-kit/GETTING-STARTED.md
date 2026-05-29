# 从 0 到 1:用 prototype-kit 起一个新设计项目

> 这是**设计操盘手册**——新项目空白起,按阶段走。核心顺序:
> **① 定基调 → ② 搭设计系统(token 真源)→ ③ 立文档骨架 → ④ 画屏(原型+画布)→ ⑤ 定档维护**。
> 关键原则:**设计系统先行**。没有 token 真源就画屏,等于一边发明颜色一边设计,必然腐化。

---

## 阶段 ① 定基调(动手前,先问清楚)
不要急着画。先用一轮提问和用户对齐,把答案写进 `CLAUDE.md` 的「设计基调」:
- **气质**:温润 / 克制 / 锐利 / 活泼……一个明确的形容词方向。
- **明暗**:浅色 / 深色 / 双模式。
- **排版**:正文字体 + UI 字体 + 语言主次(如中文为主)。
- **主题色**:单套还是多套可切换?每套包含哪些角色色(accent / strong / soft / ink / on-accent)?
- **平台与密度**:移动 / 桌面 / 响应式;信息密度高低。

> 产出:`CLAUDE.md`(复制 `CLAUDE.template.md` 改名),把产品定位 + 基调 + 约定填好。这是后续一切的锚。

## 阶段 ② 搭设计系统(token 是唯一真源)
**先建 `tokens.css`,再建组件,最后建展示页。** 顺序不能反。
1. **`〈设计规范〉/assets/tokens.css`** —— 定义全部变量,用 `:root[data-theme][data-mode]` 切换:
   - 中性色只随 `data-mode`;强调色随 `data-theme + data-mode`。
   - 间距 4px 基准(`--sp-*`)、圆角(`--r-*`)、阴影(`--shadow-*`)、字体(`--font-*`)。
2. **`spec.css`** —— 用 token 拼出组件(按钮 / 卡片 / 输入 / 列表…),组件内**只引用 `var(--*)`**。
3. **`〈设计规范〉.html`** —— 给人看的展示页:色板 / 字阶 / 间距 / 组件总览,带实时主题 + 明暗切换。用它和用户对齐视觉,定稿后再往下走。

> 若项目挂了平台的 **Design System**:跳过自建,直接把那套的 token 复制进 `tokens.css`,组件抄进 `spec.css`。kit 全走 `var(--*)`,换完自动换肤。

## 阶段 ③ 立文档骨架(让项目不腐化)
从 kit 复制三份模板到 `docs/`,改名去掉 `.template`:
- **`DESIGN-REF.md`** —— AI 速查:token 全表 + 组件目录(类名 + 最小 HTML)。**画屏时照它抄,不重读 CSS。**
- **`PROTOTYPE-ARCH.md`** —— 原型架构(已通用,直接用)。
- **`CHANGELOG.md`** —— 更新日志骨架。

> 至此「设计基调 + token 真源 + 速查索引」就位,可以开始画了。

## 阶段 ④ 画屏(原型 + 画布)
1. 把 kit 的 `index.html` + `assets/` 放到项目 `pages/`;`assets/tokens.css`、`spec.css` 指向阶段②的真源(复制保持同步)。
2. **一屏一文件**:照 `screens/_template.html` 复制改名写 `screens/<id>.html`。
   - 固定头 `.app-top` + 滚动区 `.app-scroll`;iOS chrome 由 `screen.js` 注入,别自绘。
   - 多状态用 `data-when="xxx"`(`?state=xxx` 命中才显示)。
   - 跳转用 `data-nav="<目标屏id>"` / `data-nav-back`。
3. **登记**:每加一屏,在 `assets/app.js` 顶部 `SCREENS[]` 加一项(`id/idx/name/label/proto/states`)。
4. **两种呈现**自动就位:**原型**当真 App 跑(iPhone 框 + 路由栈),**画布**平铺各状态看效果(拖拽缩放浏览)。

> 画屏节奏:先 `_template` 起骨架 → 填默认态 → 补空/异常等状态 → 登记 → 在原型里点一遍流程 → 画布里三主题×明暗抽查。

## 阶段 ⑤ 定档维护(纪律,别跳过)
- **定档即写**:某屏/组件定稿后,立刻 `CHANGELOG.md` 记一条 `- [模块] 描述`;草稿不记。
- **改动即同步**:动了 token/组件,**同一步**更新 `DESIGN-REF.md`(组件补类名+最小 HTML,token 补速查),再写 changelog,二者成对。
- **新组件准入**:只有 DESIGN-REF 登记过的组件才算「可复用」。
- **单一真源**:数值只在 `tokens.css`;DESIGN-REF 与展示页只做索引,冲突以 tokens.css 为准。

---

## 一页速记
```
空项目
 └─① 提问定基调 ───────────► 填 CLAUDE.md（复制 CLAUDE.template.md）
 └─② tokens.css → spec.css → 展示页.html   （token 先行，组件只用 var(--*)）
 └─③ docs/ 三件套（DESIGN-REF / PROTOTYPE-ARCH / CHANGELOG）
 └─④ 复制 kit 到 pages/ → 改 SCREENS[] → 照 _template 一屏屏画
 └─⑤ 定档即写 changelog + 同步 DESIGN-REF（不腐化）
```

> 文件清单与契约细节见 `README.md`;架构与 Flutter 落地映射见 `docs/PROTOTYPE-ARCH.md`。
