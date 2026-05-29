---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：定稿
---

# design-tokens-theme（设计 token / 主题层）

## 背景

UI 还原的**视觉底座**：自底向上三层（token → 组件 → 屏）的最底层，其余全部 UI spec 依赖它（见 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §1/§9）。token 又是设计稿**最高频微调**的层，必须做成**从 `tokens.css` 机械再生**，否则手抄 6×~24 个色值必漂移、且无单一真源。本 spec 把这层连同生成管线一次浇死，让上层屏只 `context.dayz.*` 取用、不发明颜色（直接消灭红线「硬编码颜色」的违规面）。

## 范围外

- 通用组件 / 屏幕实现 —— 归 `ui-kit-components` 与各页面级 spec。
- 同步工作流、参数对齐 / 布局几何 / SSIM 验证 harness、三份 tokens.css 同源校验的 **CI/hook 化** —— 归 `design-sync-automation`（本 spec 只交付一次性的同源校验脚本作为 gen 前置 guard）。
- i18n 完整落地（RTL 完整支持、复数规则、英文 arb）—— 本 spec **只拍板取向**（D4：采纳「文案集中 `AppStrings` + 日期/数字走 `intl`」）并确立约定；MUST NOT 在本 spec 引入 `flutter_localizations` 全量或创建空文案文件。
- `color-mix()` / `linear-gradient()` 等 CSS 合成色的解析 —— 由手写 helper（`glassSurface` / `fabGradient`）承载，不进生成器。

## 功能需求

### R1 · 六套主题可用
系统 SHALL 提供 `purple / amber / sage` × `light / dark` 共六套 `ThemeData`，每套挂一个 `DayzColors`（`ThemeExtension`）。
- 前提：App 任意 widget 树内。
- 操作：`Theme.of(context).extension<DayzColors>()`（经 `context.dayz`）。
- 结果：取到该主题×明暗下的全部 token（中性色 / 强调色 7 元组 / 三档阴影），非空。

### R2 · token 机械生成（不手抄）
`bin/gen_tokens.dart` SHALL 解析 `ui-design/current/design-system/assets/tokens.css` 生成 `lib/ui/theme/dayz_tokens.g.dart`（六套 `DayzColors` 常量数据 + 间距/圆角/动效/字体静态类）。
- 前提：`tokens.css` 为某一确定内容。
- 操作：`dart run bin/gen_tokens.dart`。
- 结果：生成的每个值与 `tokens.css` 对应声明**逐项一致**（`#RRGGBB`→`Color(0xFFrrggbb)`、`rgba()`→带 alpha 的 `Color`、多层 `box-shadow`→`List<BoxShadow>`）；**行为代码（`lerp`/`copyWith`/helper getter）手写、不进生成文件**。

### R3 · token 真源唯一 + 三份副本同源
系统 SHALL 只以 `ui-design/current/design-system/assets/tokens.css` 为 token 唯一真源。`ui-design/current/pages/assets/tokens.css` 与 `ui-design/current/prototype-kit/assets/tokens.css` 是同源副本。
- 前提：三份 tokens.css 存在。
- 操作：运行同源校验（`scripts/check_tokens_sync.sh`）。
- 结果：三份内容一致则 exit 0；任一分叉则 exit 非零并指出分叉文件（防「生成器只读 design-system 那份、而原型页引另一份」造成原型与 Flutter 视觉不一致）。

### R4 · 字体策略（克制 · 偏原生）
系统 SHALL 打包 `Newsreader`（衬线）+ `Hanken Grotesk`（无衬线）两套小体积 Latin 品牌字；中文 MUST NOT 打包 web 字体，一律经 `fontFamilyFallback` 落系统字（衬线 Songti SC、无衬线 PingFang SC 等）。
- 前提：渲染含中英混排文本。
- 操作：用 `--font-sans` / `--font-serif` 对应的 `TextStyle`。
- 结果：Latin 字形走品牌字、CJK 字形走系统回退，无大体积 CJK web 字体下载。

### R5 · 解析失败显式报错（不期望行为）
If `tokens.css` 出现 `gen_tokens` 无法确定性解析的值形态（未知函数、畸形 shadow、非法颜色），then `gen_tokens` SHALL 以非零码退出并打印定位，**MUST NOT 静默写出错误值**。
- 理由：生成确定但值错时，「`git diff` 为空」校验照样通过 → 漂移静默逃逸。解析失败必须显形。

### R6 · 排版角色与中文行高
系统 SHALL 提供 DESIGN-REF §2.4 的排版角色（`.t-display`/`.t-h1`/`.t-h2`/`.t-h3`/`.t-body`/`.t-diary`/`.t-caption`/`.t-overline`）对应的 `TextStyle`（标题/日记衬线、UI 无衬线）。
- 前提：渲染对应角色文本。
- 操作：取该角色 `TextStyle`。
- 结果：UI 正文 `height==1.7`、日记/阅读正文 `height==1.85`、`leadingDistribution==TextLeadingDistribution.even`；字族符合 R4。

## 非功能需求

### NF1 · 对比度（按屏内实际渲染的对验，不按裸 token 名）
六套主题下，对**实际渲染**的对分族验收：
- **正文/次要文本** `--ink` / `--ink-2` 对底（`--bg`/`--surface`）MUST ≥ 4.5:1（实测安全：ink-2 light 5.54 / dark 7.16）。
- **着色文字** `--accent-ink` 落 `--accent-soft`/浅底 MUST ≥ 4.5:1（设计里着色文字走 accent-ink，非裸 accent；三套均 ≥5.0）。
- **实色底文字** `--on-accent` 落 `--accent`（按钮文字，如 `.btn-primary` 15px/600 非大字、不可豁免）MUST ≥ 4.5:1。
- **有意义 UI**（聚焦框/选中边/选中图标，如 `.input:focus`/`.opt.on`/`.mood.sel` 直接贴 `--bg`）`--accent` MUST ≥ 3.0:1。
- **占位文本** `--ink-3` 纯 placeholder 可豁免；作真实辅助文本（时间戳/计数/meta/help/空态）时 MUST ≥ 4.5:1（或改用 `--ink-2`）。
> 按上述分族对**六套逐项**跑。已知三处 expected-fail（见 design `## 已知风险`）须显形并阻塞放行（不静默通过）、停下报 @Ray 调 token，**MUST NOT 擅自改 `tokens.css`**（设计稿真源）。`--accent` 当正文/链接文字这条路径设计未走（着色文字一律 accent-ink），故不验 purple 4.32 / sage 3.71。

### NF2 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上字体回退正常：Latin 品牌字与 CJK 系统字各自生效，中文衬线在 Android（多落 Noto Serif CJK）观感可接受。

### NF3 · 生成确定性
`gen_tokens` 对同一 `tokens.css` MUST 产出**逐字节一致**的 `dayz_tokens.g.dart`（无时间戳/随机序），使「生成后 `git diff` 为空」可作为不漂移的 CI 校验。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 纯视觉常量，不碰密钥/数据/IO |
| 权限 | 否 | 不申请任何系统权限 |
| 无障碍 | **是** | 对比度 NF1（WCAG AA）|
| 性能 | 否 | 生成在构建期；运行期纯常量，无可度量运行阈值 |
| 多端兼容 | **是** | 字体回退 NF2（iOS 13+ / Android 8+）|

→ 命中「无障碍 / 多端兼容」→ **标准档**（含 `## 非功能需求` + verification.md + 文件头文档状态 + README 索引）。单模块（Flutter app 内 `lib/`+`bin/`+`scripts/`+`assets/`），不跨模块。
