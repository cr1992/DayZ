---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：定稿
---

# 设计：design-tokens-theme

> 视觉与映射依据：[`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §2（token→ThemeExtension）、`ui-design/current/docs/DESIGN-REF.md` §2（token 全表）、`ui-design/current/design-system/assets/tokens.css`（数值真源）。

## 技术决策

### D1 · token 落地结构（三轴拆分）
- **状态：** 采纳
- **背景：** `tokens.css` 含三类变化轴：全局常量（与主题无关）、中性色+阴影（仅随 mode）、强调色（随 theme×mode）。
- **选项：** (A) 全塞一个巨型 `ThemeData`；(B) 三轴拆分——常量进静态类、随主题变的进 `DayzColors extends ThemeExtension`；(C) 全进 `ThemeExtension`（含常量）。
- **选择：** B。常量 → `abstract final class DayzSpacing/DayzRadii/DayzMotion/DayzFonts`；中性色+阴影+强调色 → `DayzColors` 字段（light/dark 共性 + 三主题强调色 = 六套实例）。
- **理由：** 常量入 ThemeExtension 会被复制 6 遍、徒增漂移面；拆开后 6 套实例只装「会变的」。
- **代价：** 取常量与取主题色路径不同（`DayzSpacing.s4` vs `context.dayz.accent`），但语义清晰、可接受。

### D2 · 代码生成 vs 手抄
- **状态：** 采纳
- **背景：** 6×~24 色值 + 多层阴影手抄必漂移、无单一真源；token 又是最高频微调层。
- **选项：** (A) 手抄；(B) 正则解析生成；(C) 稳健解析生成（`package:csslib` 或带括号配对的 tokenizer）+ 行为手写。
- **选择：** C。`gen_tokens.dart` 解析 `tokens.css` → 只产**纯数据**字段（六套 `DayzColors` 常量 + 静态类）到 `dayz_tokens.g.dart`；`lerp`/`copyWith`/helper getter 手写在 `dayz_colors.dart`。
- **理由：** 裸 `split(',')` 会拆错 `box-shadow` 里 `rgba()` 内部的逗号（这是 gen 的命门，见 R5/NF3）；`csslib` 或括号配对 tokenizer 能正确切分。行为代码手写避免被生成覆盖。
- **代价：** 引 `csslib`（dev_dependency）+ 维护一个生成器；换来零漂移与解析鲁棒，值。

### D3 · 字体方案
- **状态：** 采纳
- **背景：** 基调要 Latin 品牌字 + 原生 CJK，且 Flutter 对可变字体字重轴支持有限。
- **选项：** (A) 打包含 CJK 的全字族；(B) 打包 Latin 静态字重 + CJK 系统回退；(C) 全 CDN（仅原型用）。
- **选择：** B。打包 `Newsreader`、`Hanken Grotesk` 的静态字重——CSS 实际用到 **400/500/600**（500 ~20 次、600 ~85 次），**粗体切换按钮另需 700**；`Newsreader` **italic 400/500**（引用块 `font-style:italic` 落衬线语境，CDN 已加载 ital 轴），故 italic 为应打包项、非"视需"。`pubspec.yaml` 声明；CJK 经 `fontFamilyFallback`（衬线 `Songti SC`/`STSong`/`Noto Serif CJK SC`，无衬线 `PingFang SC`/`Noto Sans CJK SC`）。许可：两款均 SIL OFL 1.1（已核实，见 T5），可商用嵌入。
- **理由：** 体积小、零 CJK 下载；与原型 `tokens.css` 字体栈一致。
- **代价：** Android 多无 Songti，衬线中文落系统 Noto Serif CJK，观感略异——克制取舍，可接受（NF2 真机各验一次）。

### D4 · i18n 取向
- **状态：** 采纳（@Ray 2026-05-29）
- **背景：** 本地优先个人日记、中文为主兼顾英文；全部 active spec 现无 i18n。是结构性决定（影响每屏 `Text` 怎么写），须在本层拍板，否则 6 屏写完再抽是大返工。
- **选项：** (A) MVP 即引 `flutter_localizations` + arb 全量；(B) 不引 localizations，UI 文案集中到约定常量、结构 i18n-ready，日后一次抽 arb；(C) 文案完全散落硬编码。
- **选择：** B，**且加两条硬约束使「集中」可验收（这是 B 区别于 C 的实质，不写死则 B 名存实亡）**：
  1. **文案集中可验收**：单个 `abstract final class AppStrings`（与 D1 的 `DayzSpacing` 静态类同构）持 `static const` 中文字面量；`lib/ui/` 下用户可见 widget 字面量 MUST 引 `AppStrings`、屏内**禁裸中文**；widget 测试用 `find.text(AppStrings.xxx)` 而非裸中文（既防测试脆、又自带「只引常量」的回归护栏）。settings 屏两条合规红线文案（「主密码锁不住照片」、「已加密」只读）也纳入 `AppStrings`，红线文案就有单一可审计落点。
  2. **日期/数字走 `package:intl`**：月份头 / reader 头 / onthisday 年份段是日期格式化高频区，`AppStrings` 覆盖不到、最易散落返工。`intl` 是 Flutter SDK 传递依赖（无需新增 pubspec 条目）；MUST NOT 自拼 `'2026年5月'` / `'3 条'`。
- **强烈建议**：间距/对齐用 `EdgeInsetsDirectional` + `start/end`（零成本 RTL-ready）。
- **理由：** 个人日记单用户 MVP 无多语言切换需求；集中 + intl 把返工面收敛到一处，保留升级路径，又避开 A 的过度工程。
- **代价：** 仍非真 i18n，日后上多语言（RTL 完整支持/复数/英文 arb，均范围外）需一次抽离，但因集中、成本可控。
- ⚠️ **本 spec 只确立约定与决策，不创建空 `AppStrings` 文件**（无屏时建空文件是 scope creep）；`AppStrings` 文件 + 「只引常量」回归 lint/test 随 `ui-kit-components` / 各屏 spec 落地并强制。

### D5 · 同源校验落点
- **状态：** 采纳
- **背景：** 三份 tokens.css 是上游设计稿经 `rsync --delete` 镜像带来的副本；上游若让某份先行试新色会分叉，而 gen 只读 design-system 那份。
- **选择：** 本 spec 交付 `scripts/check_tokens_sync.sh`（gen 的**前置 guard**：分叉则拒绝生成）；其 CI/PreToolUse hook 化归 `design-sync-automation`。
- **代价：** 校验逻辑暂以脚本存在、未进 CI，靠 gen 流程调用；hook 化是后续事。

## 架构

```mermaid
graph TD
  T[ui-design/current/design-system/assets/tokens.css 真源] --> G[bin/gen_tokens.dart]
  P[ui-design/current/ pages / prototype-kit 副本] -. check_tokens_sync.sh 同源校验 .-> G
  G --> GG[lib/ui/theme/dayz_tokens.g.dart · 纯数据×6]
  GG --> C[dayz_colors.dart · 手写 lerp/copyWith/helper]
  F[dayz_fonts.dart + dayz_text_theme.dart] --> TH
  C --> TH[dayz_theme.dart · 6 套 ThemeData + context.dayz]
  TH --> M[MaterialApp.theme/darkTheme + ThemeExtension]
  TH --> DEMO[theme_gallery_demo · Debug Home 主题画廊]
```

## 文件变更

- `bin/gen_tokens.dart`                    新建（解析器 + 代码生成）
- `lib/ui/theme/dayz_tokens.g.dart`        新建（**生成物**：六套 `DayzColors` 常量 + 静态类）
- `lib/ui/theme/dayz_colors.dart`          新建（`DayzColors` 类 + `lerp/copyWith` + `glassSurface`/`fabGradient` helper + `context.dayz` 扩展）
- `lib/ui/theme/dayz_fonts.dart`           新建（字体栈静态类）
- `lib/ui/theme/dayz_text_theme.dart`      新建（`.t-*` 排版类 → `TextTheme`/`TextStyle`）
- `lib/ui/theme/dayz_theme.dart`           新建（六套 `ThemeData` 装配）
- `lib/demo/theme_gallery_demo.dart`       新建（主题画廊 demo）
- `lib/demo/demo_entry.dart`               修改（**仅末尾追加一行**，不插中间、不改 `DemoEntry` 字段）
- `pubspec.yaml`                           修改（`fonts:` 声明 + `csslib` dev_dependency + 字体资源）
- `assets/fonts/`                          新增（Newsreader / Hanken Grotesk 静态字重 ttf）
- `scripts/check_tokens_sync.sh`           新建（三份 tokens.css 同源校验）
- `test/ui/theme/contrast_xfail.yaml`      新建（对比度 expected-fail 机器真源；contrast_test 与 design-sync 共读、单一来源）
- `CLAUDE.md`                              修改（「常用命令」段补 `dart run bin/gen_tokens.dart` + `bash scripts/check_tokens_sync.sh`，与 T1 同 commit——CLAUDE.md 维护契约要求慢变量级新命令同 commit 落档，活先例 `check_patches.sh`）

## 已知风险

- **对比度三处 expected-fail（NF1，预登记，验证遇到时阻塞放行、停下报 @Ray 调 token，本 spec 不擅自改 `tokens.css`）**：
  1. **sage 按钮白字 on accent = 3.97**（< 4.5，`.btn-primary` 15px/600 非大字不可豁免）→ 设计侧建议 sage `--accent` 向 `--accent-strong` 加深 / `on-accent` 改深墨。
  2. **amber accent 当聚焦框/选中边/选中图标贴 bg = 2.43**（< 3.0，`.input:focus`/`.opt.on`/`.mood.sel`）→ amber light `--accent` 加深到 ≥3.0（≈现 `--accent-strong`）。
  3. **ink-3 当真实辅助文本 = 2.77**（< 4.5，`.entry .date .m`/`.tl-month .c`/`.field .help`/空态 meta）→ `--ink-3` 加深，或这些场景改用 `--ink-2`（5.5 ✓）；纯 placeholder 保留豁免。
  - （purple 4.32 / sage 3.71 的「accent 当文字」不暴露——设计着色文字走 accent-ink 落 soft 底，三套 ≥5.0；dark 全套 ≥6.5 健康。）
- **字体许可**：`Newsreader`（productiontype/Newsreader）/ `Hanken Grotesk`（marcologous/hanken-grotesk）均 **SIL OFL 1.1**（已核实，可商用嵌入、App 本体无需开源、子集化属允许 modification）。合规三件事：① 每款 `OFL.txt` 打进 `assets/fonts/`；② App 内致谢页经 `LicenseRegistry`/`showLicensePage` 注册 OFL（注册落点可随 `ui-shell-navigation`/app-shell，本 spec 先打入 OFL.txt）；③ 不单独售卖字体文件。
- **合成色不生成**：`glassSurface`（毛玻璃顶栏）与 `fabGradient` 由手写 helper 承载、不进生成器；**系数以 screen.css 实际玻璃面规则为准、T2 实现时查证**——实测玻璃面是 `color-mix(in srgb, var(--bg) 80%, …)` + `saturate(1.5) blur(20px)`（doc 10 §2 PoC 的 `surface 0.82` 只是示意，非真值；82% 出现在 spec.css 另一处、配 blur 1.4/16px，勿混用）。
- 无持久化 schema 变更 → 无数据迁移/回滚要素。
