# 10 · UI 还原与设计稿同步

> 状态：方法论（决策骨架定稿；细节随对应 spec 落地与迭代）
> 作者：@Ray
> 定位：回答两个工程问题——(A) 怎么把 `ui-design/` 的 HTML 设计稿用 Flutter 还原；(B) 设计稿**持续迭代**，怎么不被移动靶拖垮。
> 配套真源：视觉 token/组件以 `ui-design/current/docs/DESIGN-REF.md` 为准；HTML→Flutter 机制映射见 `ui-design/current/docs/PROTOTYPE-ARCH.md §6`；spec 执行协议见 `docs/spec-guide-ai.md`。
> 本文是 UI 系列 spec（`design-tokens-theme` / `ui-kit-components` / `ui-shell-navigation` / `design-sync-automation` + 各页面级 spec）的**总纲**，只给方法与指针，不冻结会变的清单。

> **会变的东西一律以设计稿为准、本文不枚举**：有哪些屏、屏清单、组件个数、token 数值——指向真源 `ui-design/current/pages/screens/`、`DESIGN-REF.md §3`、`design-system/assets/tokens.css`，本文不复述、不追着设计稿改。

-----

## 0. 两个核心判断（先记这两句，其余都是展开）

1. **「还原」不是把 HTML 翻译成 Flutter，而是自底向上重建三层**：token/主题层 → 通用组件层 → 屏幕层。下层是上层的硬依赖，反过来不成立。先做屏 = 把颜色/字号硬编码散进各屏 × 各主题，直接踩「一律走 ThemeExtension token、不在屏里硬编码」的红线。
2. **「同步」要按层差速，不能整体自动化**：HTML 原型（iframe + postMessage + URL state）和 Flutter（Sliver/Navigator/Riverpod）是两套渲染范式，`PROTOTYPE-ARCH §6` 给的是「等价做法」而非可转译代码。**只有 token 层能机械再生**；组件/布局层只能靠 diff 信号 + 参数对齐驱动可控的跟进，并用「钉住设计稿版本」切断移动靶。

-----

## A. 如何还原

## 1. 分层还原策略（自底向上，建造顺序 = 依赖顺序）

```
┌─ 屏幕层 (各屏 + 状态/转场/抽屉/FAB/吸顶/无限滚动)     ← 最后，最不可机械同步
│   依赖 ↓
├─ 通用组件层 (按钮/卡片/工具栏/抽屉/FAB/顶栏 …)        ← 中间，半机械
│   依赖 ↓
└─ token/主题层 (DayzColors ThemeExtension + 静态常量 + 字体) ← 最先，唯一可机械再生
```

| 层 | 产物 | 性质 |
|---|---|---|
| **token/主题层** | `lib/ui/theme/`：生成的 `dayz_tokens.g.dart` + 手写 `DayzColors`(ThemeExtension)/静态间距圆角动效类/字体/text-theme | 唯一可机械再生 |
| **通用组件层** | `lib/ui/widgets/*.dart`：DESIGN-REF §3 登记过的可复用 widget + 跨屏共用外壳（如毛玻璃顶栏） | 半机械 |
| **屏幕层** | `lib/ui/<feature>/<feature>_page.dart` + 各自 `demo.dart` | 最不可机械同步 |

**红线（建造顺序的硬约束）**：

- **先立视觉底座，不在屏里硬编码。** 颜色/字号/间距/圆角/阴影/动效一律走 token（`ThemeExtension` + 静态常量），屏与组件只引用、不写死。
- **组件层准入门槛**：只实现 `DESIGN-REF.md §3` 登记过的组件（有类名 + 最小 HTML 才算可复用），不凭空造 widget。**有多少组件、叫什么，以 DESIGN-REF §3 为准**，本文不枚举。

## 2. token → ThemeExtension（同步策略的支点）

`tokens.css` 有**三条独立变化轴**，按变化频率分治，不要全塞进一个巨型 ThemeData：

| 轴 | 内容 | 落地位置 |
|---|---|---|
| 全局常量（与 theme/mode 无关） | 间距、圆角、动效、字体栈 | **静态类**（进 ThemeExtension 会被按主题复制多遍、徒增漂移面） |
| 中性色 + 阴影（仅随 mode） | bg/surface/ink/hairline/overlay/danger/favorite/shadow… | `DayzColors` 字段 |
| 强调色（随 theme×mode） | accent 族 | `DayzColors` 字段 |

> 有几套主题、几种纸色、每个值是多少，**以 `tokens.css` 为准**，本文不冻结数量与数值。`DayzColors` 只承载纯数据字段；`lerp`/`copyWith`/语义 getter 等行为代码手写、放 base 文件，**不进生成文件**。用法约定 `context.dayz.<token>`。

**代码生成是同步策略唯一的真自动化环**：写 `bin/gen_tokens.dart` 解析 `design-system/assets/tokens.css` → 生成 `lib/ui/theme/dayz_tokens.g.dart`，并接进 `dayz-design-sync` 流程——每次同步设计稿后重新生成 + diff 校验，保证 `.g.dart` 与 `tokens.css` 永不漂移。

- **规范源唯一**：只认 `design-system/assets/tokens.css`；`pages/` 与 `prototype-kit/` 下的同名 `tokens.css` 是同源副本，不当真源（同步后须 `diff -q` 三份，分叉即告警——上游可能让 prototype-kit 先行试色，current/ 会忠实镜像分叉，而脚本只读 design-system 那份）。
- 转换规则是确定性的（hex/rgba → `Color`、多层 `box-shadow → List<BoxShadow>`、`--sp-* / --r-*` → 对应常量名）。
- ⚠️ **解析器鲁棒性是命门，是 `design-tokens-theme` 的硬验收项**：`box-shadow` 值里 `rgba()` 内部也有逗号，裸 `split(',')` 会拆错；alpha 取整策略要固定。解析器一脆，脚本会**静默产错值**而「diff 为空」检查照样通过——「零漂移」承诺就成空话。
- **屏内私有视觉值不在 tokens.css**（如顶栏毛玻璃的不透明度/`saturate` 系数等屏内实测值）：这类值从对应屏的 CSS 核定，由 §4 的参数抽取覆盖；token 生成器只管 token，兜不住这类屏内值。

**字体**：打包两套小体积 Latin 品牌字（衬线 + 无衬线，确认 SIL OFL 许可后入 `pubspec.yaml`），**绝不打包 CJK web 字体**，中文靠 `fontFamilyFallback` 落系统字。注意 Flutter 对可变字体字重轴支持有限，多数情况要切静态字重 ttf（至少 regular + semibold）；CJK 行高放宽并配 `TextLeadingDistribution.even`。具体字体名/字重/行高**以 DESIGN-REF §2 与 `tokens.css` 为准**。

**i18n 取向**：见 `docs/design/11-internationalization-and-localization.md` 与 `i18n-localization` spec（gen-l10n + arb + 中英双语）。这是影响每屏 `Text` 怎么写的横切约束，独立成 spec 承载，不在本层处理。

## 3. 逐屏映射不在本文

每屏「HTML 机制 → Flutter widget」的具体配方，归各**页面级 spec** 的 `design.md` + `PROTOTYPE-ARCH.md §6`，**本文不做逐屏 walkthrough**。仅提两条**跨屏通用**的方法点，避免在每个屏里各自踩坑：

- **跨屏共用的外壳抽成组件**（典型如毛玻璃顶栏、FAB、抽屉）：在组件层落一次、各屏共享，不在屏里各写一份。共用件清单以 DESIGN-REF §3/§4 为准。
- **网页取巧效果先查 Flutter 对应/降级**：原型里若有 Flutter 难做或代价过高的网页专属效果（如多层投影、`saturate` 玻璃、inset 阴影），按 `PROTOTYPE-ARCH §6` 注明的等价做法或降级方案处理，不照搬 DOM。难度评估是工程判断，不引设计稿原文。
- **重活、加密、文件 IO 的既有红线对 UI 同样生效**：列表滚动禁止同步重建缩略图（缩略图只暴露异步 warmup）、媒体 key 独立于主密码（媒体相关 UI 须如实说明「主密码锁不住照片」）、DB 恒加密无关闭入口——细节见 `docs/design/05/06/09` 与对应底层 spec，UI 层只是不许写出违反它们的路径。

> 复杂屏（如时间线这类带吸顶/无限滚动/日历跳转的屏，**以设计稿为准**）的细节属于其页面级 spec，集中处理；本文不预设有哪几屏、各屏长什么样。

-----

## B. 设计稿持续迭代，如何保持同步

## 4. 验证：四闸从硬到软——视觉对比也尽量做成确定性

**关键认知：跨引擎「截图比像素」必挂，但「视觉对比」≠「比像素」。把视觉对比拆成「样式参数」+「布局几何」两层后，绝大部分可做成确定性断言；真正模糊的只剩残余的栅格观感。**

| 闸 | 查什么 | 怎么查 | 性质 |
|---|---|---|---|
| **① token 值闸** | Flutter token 常量 == `tokens.css` 值 | `gen_tokens.dart` 生成 + diff 校验 | 确定性 |
| **② 样式参数闸** | 每元素**解析后样式** == 设计稿（color/font/radius/padding/shadow + **截断/行钳制**：`text-overflow`/`-webkit-line-clamp` ↔ `maxLines`/`overflow`/`softWrap`） | `getComputedStyle` 抽取 → widget test 断言 | 确定性 |
| **③ 布局几何闸** | **顺序/包含/不溢出**（全元素）+ **位置/尺寸**（仅 fixed-geometry 元素硬断言） | `getBoundingClientRect` vs `RenderObject` 几何 | 确定性\*（文本块尺寸除外） |
| **④ 栅格观感闸** | 真实像素观感（渐变、多层影、saturate 玻璃、抗锯齿） | golden（回归锁）+ 区域化 SSIM/pixelmatch（确定性分数）+ 视觉模型（可选，仅边界判定） | 半确定性 |

②③ 是确定性主闸，由**同一次浏览器抽取**产出（`getComputedStyle` 喂 ②、`getBoundingClientRect` 喂 ③、截图喂 ④），且**抽自源屏 `pages/screens/<id>.html`，不抽 assembled 的 `dayz-prototype.html`**——后者是构建产物，会引入「源屏改了没重建 → 抽到旧值」的时序坑与「元素在 iframe 里、`getComputedStyle` 要钻 `contentDocument`」的穿透坑；直接跑源屏两坑全免。抽取拿的是**解析后**的最终值（CSS 级联 / `var(--*)` 已全解析成 px/rgb），反查回 token 落成参数清单 fixture，顺带抓出「设计稿用了不在 token 里的硬编码值」标红给设计侧。

**为什么参数/几何闸强**：确定性、CI 秒级、不请视觉模型；且它顺便是**最精确的 diff 信号**——设计把某元素 padding 从一档改成另一档，参数清单重抽后对应 widget test 立刻红，精确到字段，比「html 文件变了」强得多。这也正是 `spec-guide-ai.md`「禁止假装能测的 grep」红线的**正面践行**——参数/几何是真断言，不是假 grep。

**③ 必须按元素分治，否则重蹈 golden 覆辙**：

- **fixed-geometry**（图标、chip、FAB、固定尺寸卡、分隔线…）：硬断言尺寸 + 相对位置（≤1–2px 容差，有亚像素舍入物理依据）。
- **content-driven**（正文、标题、可换行文本块…）：**只断顺序 + 包含 + 不溢出，不硬断块高**。原因：即便 ② 已钉死 font-size/line-height/font-weight，HTML（浏览器 line-breaker）与 Flutter（minikin）对同段文本换行结果仍可能不同，CJK/中英混排尤甚；叠加 §2「CJK 走系统字回退」，抽取端与 test 端非同机时回退字体不同→字宽不同→换行点不同→块高不同，硬断块高会天天 flaky 或逼人把容差放大到漏掉真溢出。相邻间距对 content-driven 邻居取 `gap = next.top − prev.bottom`，与未断言的块高解耦。
- **映射表是漂移源，须显式守**：HTML 类名 ↔ Flutter widget key 的映射（DOM 与 widget 树不同构，粒度人工选定）。每条映射挂 `geometry: fixed | content` 标签，与映射表同处登记。**铁规则**：源屏出现映射表里没有的新类名 → 不许被 ③ 当「全过」静默跳过，而是强制按 §8 ② 实质变更处理（新增 sync 任务卡 + 补映射），否则 ③ 的确定性退化成「对已知元素确定、对新元素假阴性」。
- **②/③ 的缝须堵**：纯靠「不断块高」会漏「截断/行钳制不一致」这类真 bug（样式全对、只是该截没截）——它③抓不到，故**截断/钳制族必须进 ② 的参数 schema**（见上表）。补上后 ③ 的残留才只剩「纯换行差异导致的高度噪声」这一类非 bug。

**④ 栅格观感（半确定性，模糊面已很小）**：golden 作确定性回归锁；用 ③ 的布局框把两端截图裁成对应区域逐区算 SSIM/pixelmatch/pHash（区域化避开跨引擎字体栅格化噪声）；视觉模型降为**可选**，只判分数处于边界又难定阈值的残余项，甚至可省——低分区域直接进 SYNC_REPORT 标红。

**诚实边界**：跨引擎整屏像素级精确匹配确实不可能，所以不比整屏像素，而是 ②样式 + ③几何（确定性）扛主力、④ 用 golden + 区域化 SSIM 兜栅格、视觉模型只收边角。模棱两可的项进 SYNC_REPORT 标红、不静默放过。细节实现交给 `design-sync-automation` spec。

## 5. 还原 = 同步，同一个工作流

两件事本质相同——**把某屏的 Flutter 实现驱动到与它的 HTML 源一致**，只差种子与触发：

| | 还原（初次） | 同步（迭代） |
|---|---|---|
| 种子 | 该屏 Flutter 还是空的 | 已有实现 + 一段 diff |
| 触发 | 手动跑一次 | `git diff ui-design/current/` 非空自动触发 |
| 工作流 | **同一个「屏幕对齐工作流」** | **同一个** |

## 6. 同步工作流设计（AI 工作流，不预设人工）【待 design-sync-automation 细化】

```
Phase 1  Detect & Route  ── 解析 git diff，按文件路径分类路由（确定性，无 agent）
Phase 2  Token Regen     ── gen_tokens.dart + 三份 tokens.css 同源校验 + 对比度/lerp 回归（确定性）
Phase 3  Screen Align    ── 受影响屏逐个对齐：读新 HTML + §6 映射 + 现 widget → 改 widget（worktree 隔离避免并行冲突）
Phase 4  Verify          ── ①②③ 硬闸（任一红 → build fail）；③ 按 fixed/content-driven 分治 → ④ round-budget best-effort（golden + 区域化 SSIM，残余低分标红不阻塞）→ 自修复循环
Phase 5  Pin & Report    ── 更新各屏 pinned hash（screens.yaml）+ 产出 SYNC_REPORT.md
```

**Phase 1 路由按文件路径即模块边界做确定性映射**（确切路由表以 spec 为准）：`tokens.css` 变 → Phase 2 token 重生（全屏覆盖）；单个 `screens/<id>.html` 变 → 仅该屏；**共享层资源（顶栏/抽屉/FAB 等所在的 `screen.{css,js}`）变 → 扇出到全部屏**（易被低估的盲点）；DESIGN-REF §3 变 → `ui-kit-components` 增量。

**把「人工」换成 AI 的关键**：Phase 3 每屏一个 agent（输入 = 新 HTML + §6 映射 + 现 widget + ui-kit + tokens，输出 = patch，worktree 隔离）；Phase 4 两级闸——①②③ 硬闸（任一红即 build fail），④ round-budget best-effort（到轮次上限仍低分的区域写进 SYNC_REPORT 标红、不阻塞）。

> **同步落地时同 commit 修订 `spec-guide-ai.md`**：该文件原有「视觉/真机/人因走人工核查项」默认，本方案把视觉项从 default-人工升级为 **default-①②③ 确定性闸 + ④ golden/SSIM 自动验，视觉模型/人眼仅做标红终审且不阻塞**。其「禁止假装能测的 grep」红线**保留不变**——参数/几何断言正是它的正面践行。`AGENTS.md` 不需动（其验收段只转引 spec-guide）。〔按段落定位、勿用行号——编辑会移动行号。〕

## 7. 生命周期：屏幕是活的，不归档【待 design-sync-automation 细化】

区分两种生命周期：

| | 生命周期 | 归宿 |
|---|---|---|
| **「建某屏 v1」这个工程** | 有限，会完成 | 完成后归档（历史记录「v1 建好并对齐 @hash」） |
| **某屏这块屏幕本身** | 永远活着，跟随设计 | **永不归档**，由常驻同步机制 + 活的 test/registry 维护 |

落地：屏幕 spec 不进「已归档」，转入新泳道 **「已交付·随设计维护」**（对现有二态的小扩展，落 `design-sync-automation` 时同 commit 改 `spec-guide` / `specs/README.md`）。**关键**：对齐状态——pinned hash、参数清单 fixture、golden 基线——全部活在**代码/测试树**（`test/ui/<feature>/`）和一份常驻**屏幕登记表** `specs/active/design-sync-automation/screens.yaml`，不塞进会被归档的 spec 正文，所以没有任何东西需要「从归档捞回来」。两个「归档」都不是恢复入口：`specs/archive/` = 已完成 spec（不复活）；设计稿旧版 = git 历史（正常流程不需要——永远对齐 current，用 pinned hash 算增量）。

## 8. 改设计的三档响应【待 design-sync-automation 细化】

让**常见的小改全自动、零 spec**，重流程只留给结构性大改：

| 档 | 什么变了（由信号判定） | 怎么处理 | 人工 |
|---|---|---|---|
| **① 微调** | 只动 token 值 / 参数（padding、color、行高、文案、小布局） | 同步工作流**全自动**：重抽参数清单 → 改 widget → 参数闸 + golden 重验 → bump pinned hash → 记 SYNC_REPORT | 0 |
| **② 实质变更** | 新状态 / 新组件 / 区块重排 / 新交互 / DESIGN-REF §3 加条目 | 工作流判定「超出机械再对齐」→ 在该屏**维护态 spec 的 `tasks.md` 追加一张 sync 任务卡** → 工作流起草 + 实现 + 验证 | 0~轻 |
| **③ 大改版** | 整屏被重新构想（信息架构 / 导航变） | 开**新 active spec**，走完整四件套 | 正常 spec 流程 |

**判定与切移动靶的锚 = pinned hash**：每屏的 pinned hash 存 `screens.yaml`，是工作流每次跑的**输入**而非文档摆设；增量 = `git diff <pinned>..HEAD -- <screen>.html` + 参数清单重抽 diff（字段级）。据此分流：只 `tokens.css` 变且该屏 html 无 diff → ①（甚至不碰这屏）；重抽后只有数值变、元素集/结构不变 → ① 机械再对齐；出现新元素 / 新状态 / §3 新组件 / 结构重排（含「③ 映射表里没有的新类名」，强制升 ②）→ ②；信息架构/导航变 → ③。`scripts/check_ui_sync.sh` **反向巡检**哪屏 pinned hash 落后于当前设计且 diff 非空 → 报「待同步」——这是「pinned hash 烂成死数字」的解药，须作为常驻 hook。

-----

## C. 落地

## 9. spec 拆分：三档 + 依赖波次【待立 spec】

| 档 | spec | 拥有什么（概要） | dependsOn |
|---|---|---|---|
| **基础** | `design-tokens-theme` | `gen_tokens.dart` 解析器 + 生成的 token + 手写 `DayzColors` + 字体打包 | — |
| | `i18n-localization` | gen-l10n + arb 生成管线 + 中英双语 + `MaterialApp` 接线 + `LocaleController` | — |
| | `ui-kit-components` | DESIGN-REF §3 登记的可复用 widget + 跨屏外壳 + 多状态画廊（widgetbook，补 Debug Home 单列表覆盖不了的「组件×主题×状态」矩阵） | tokens-theme |
| | `ui-shell-navigation` | 路由 + 抽屉 + FAB + 取代 `DebugHome` 的真外壳 | tokens, ui-kit, data-layer |
| **自动化** | `design-sync-automation` | 同步工作流脚本 + diff 路由器 + 样式/几何 harness + 栅格兜底（golden + 区域化 SSIM） + `screens.yaml` + pinned-hash 巡检 hook + 维护态泳道/三档分流规则 | 分两期 |
| **页面级** | 每屏一个 spec | 各屏 `lib/ui/<feature>/` + 该屏参数 fixture + 测试 + golden 基线 | tokens + ui-kit + shell + 对应底层 spec |

**有哪些页面级 spec、各依赖哪个底层 spec——以 `specs/README.md` 与设计稿当前屏清单为准**，本文不枚举。

**页面级 spec 之间的先后，按页面层级（导航树深度）细排**：外壳 / 入口页先于其下钻的次级页、叶子页；层级以设计稿导航结构（`ui-design/current/`）为准，本文不写死。其上仍叠加「该屏依赖的底层数据 spec 已就绪」这一硬门——两者取较晚者。

```
W0  design-tokens-theme  +  design-sync-automation(期一：token 重生管线 + diff 路由骨架)
W1  ui-kit-components → ui-shell-navigation
W2  各页面级 spec（并行）  +  design-sync-automation(期二：屏级还原 + 验证，等首屏+shell 落后补)
W3  依附件（undo-redo / media-picker / autosave-recovery 等）   W4  后置件
```

**每屏 task 的家 = 该屏自己的 spec 目录**（沿用项目现有约定）；参数 fixture、测试、golden 基线归在该屏名下，由其 `design.md`「文件变更」声明、`tasks.md`「验收基建」预批。同步工作流**不另开 task 库**：检测到某屏 diff 时在该屏维护态 spec 的 `tasks.md` 追加一张 sync 任务卡（或只 bump pinned hash），spec 目录是 task 的唯一持久家，工作流只是执行器。

## 10. 动 `lib/ui/` 前的红线 / 白名单【引自 AGENTS.md / CLAUDE.md】

`lib/ui/`（及 backup/data/drafts/media/security/thumbnails）目前只有 `.gitkeep`。动它之前：

1. **先有 spec**：四件套已立、档位锁定、`design.md`「文件变更」逐个列出要新建的 `lib/ui/<feature>/*.dart`——这份清单才是任务「可改文件」白名单来源，没 spec 不得写 `lib/ui`。
2. **先立视觉底座**：第一个落 `design-tokens-theme`，其余全 dependsOn 它，不许每屏硬编码颜色/字号。
3. **复用前读设计参考**：`DESIGN-REF.md`（类名 + 最小 HTML + token 全表）、`PROTOTYPE-ARCH.md §6`（机制 → Flutter 映射 + 痛点 + 退步方案）。
4. **守 Repository 边界（硬红线）**：UI 取数只经 `JournalRepo/EntryRepo/MediaRepo/TagRepo/EditingSessionRepo`，禁止 UI 持 Drift 句柄或写 SQL/Drift。
5. **Debug Home 入口**：每个 UI spec 在 `lib/demo/demo_entry.dart` 的 `demos` 末尾**只追加一行**（不插中间、不改 `DemoEntry` 字段），该文件列入对应任务白名单。真外壳取代 `home:DebugHome()` 时，同 commit 改 `lib/app.dart` 与 CLAUDE.md「Debug Home 入口模式」段。
6. **新文件加 MPL-2.0 头注**。
7. **触 `pubspec.yaml`**（路由 / image_picker / svg / 通知 / widgetbook 等共享依赖）须在 `design.md` 文件变更显式列出并经确认。
8. **golden 等验收基建**须在对应任务「验收基建」字段预批，否则撞白名单墙（hook：`spec-kit/hooks/claude-pretooluse-whitelist.sh`）。

## 11. 验收口径

可自动化的尽量 widget test 断言可观测值（②样式参数闸、③布局几何闸、对比度按 ThemeData 算、`SliverAppBar pinned` 行为、滚动后顶栏状态切换、`find.bySemanticsLabel`）；栅格观感走 golden + 区域化 SSIM，视觉模型仅收残余边界——参数/几何断言是真断言，正是「**禁止假装能测的 grep**」的正面践行，不是反例。无障碍至少覆盖：点击目标 ≥ 44px、对比度 ≥ WCAG AA、Semantics 标签、`reduce-motion`（动效尊重系统「减弱动态效果」）。

## 12. 建议第一步

**立 `design-tokens-theme` + `design-sync-automation`（期一）的 spec 四件套**，先做 token/主题层 + `gen_tokens.dart` 生成管线 + 参数对齐 harness 骨架。最高杠杆（全部 UI spec 依赖它）、最低风险（纯数据，不碰布局 / data 接缝），且一次性把同步策略里**唯一真自动化的那一环**打通。验收项必须含：解析器鲁棒性（§2，硬验收项）、三份 tokens.css 同源校验（§2）。

-----

## 关键文件路径速查

- token 规范真源：`ui-design/current/design-system/assets/tokens.css`
- 屏 HTML（有哪些屏以目录为准）：`ui-design/current/pages/screens/`
- 设计参考：`ui-design/current/docs/{DESIGN-REF,PROTOTYPE-ARCH,CHANGELOG,BACKLOG}.md`
- 同步 skill：`.claude/skills/dayz-design-sync/SKILL.md`
- 目标落地目录（待动土）：`lib/ui/`（现仅 `.gitkeep`）

-----

## 维护本文件

- 本文是 UI 系列 spec 的总纲，**只放方法骨架与指针**。会变的清单（屏/组件/token 数值）一律指向设计稿真源，本文不枚举、不追着设计稿改——与最新设计稿没逐项对齐也没关系，方法对就行。
- 对应 spec 立项后，逐节标注的「待 spec 细化」内容下沉到该 spec 的四件套，本文只保留指针与跨 spec 的总判断。
- 验证策略（§4）、生命周期（§7）、三档响应（§8）若在实战中调整，**与 `design-sync-automation` 同步修订**，并联动 `AGENTS.md` / `spec-guide-ai.md` 的相关约定。
- token 结构（§2）只示意分治思路，**数值真源永远是 `tokens.css` + 生成的 `.g.dart`**，本文不复制数值。
