---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# design-sync-automation（设计稿同步 SOP · AI 工作流）

## 背景

设计稿持续迭代，「设计 → Flutter」**不可整体机械同步**（HTML 与 Flutter 两套范式，`PROTOTYPE-ARCH §6` 是等价做法非可转译代码）。本 spec 把 [`docs/design/10-ui-restore-and-design-sync.md`](../../../docs/design/10-ui-restore-and-design-sync.md) §4–§9 的同步 SOP **工件化为 AI 工作流**，使常见小改全自动、结构性大改才进 spec，且不预设人工环节。

核心认知（doc 10 §5）：**「还原」与「同步」是同一个「屏幕对齐工作流」**——把某屏 Flutter 实现驱动到与其 HTML 源一致，只差种子（空 vs 已有+diff）与触发（手动 vs diff）。

**分两期**（doc 10 §9）：
- **期一（本 spec 主交付）**：token 重生管线集成 + Phase 1 diff 路由 + `screens.yaml` 登记 + pinned-hash 巡检 + 维护态泳道/三档分流 + 验证分级与 `element-map`/Phase 4 的**设计定稿**（决策落地、骨架就位）。
- **期二（设计在此定，实现随首屏落）**：Phase 3 屏对齐 + Phase 4 参数/几何/SSIM 验证 harness 的**实现**——依赖首个页面级 spect（`timeline-screen` 等）与 `ui-shell-navigation` 存在后才有可对齐的 widget。

## 范围外

- `gen_tokens.dart` 本体 —— 归 `design-tokens-theme`；本 spec 只**调用 + hook 化**（同源校验前置 + 不漂移 CI）。
- 各屏 widget / `element-map.yaml` 具体内容 / golden 基线 —— 随各页面级 spec 落（本 spec 定**格式与契约**）。
- `AppStrings` / i18n 文件 —— 归 `ui-kit-components` 及各屏。
- 设计稿源同步本身（拉取/解压/`rsync --delete`/重建 standalone）—— 已由 `dayz-design-sync` skill 解决；本 spec 从「`current/` 已是最新」起步。

## 功能需求

### R1 · diff 路由（Phase 1，确定性）
给定 `git diff ui-design/current/` 的变更文件集，工作流 SHALL 确定性地分类路由，无 agent 判断；若 `docs/CHANGELOG.md` 有 diff，工作流 SHALL 把它作为**语义预检输入**读入 `SYNC_REPORT`，用于快速定位本轮定档意图与可能档位，但最终路由 / 屏清单 / 结构判断仍以 `pages/assets/app.js`、`pages/screens/*.html`、`DESIGN-REF.md` 与 `screens.yaml` 为准。
| diff 命中 | 路由 |
|---|---|
| `design-system/assets/tokens.css` | → Phase 2 token 重生（全屏覆盖）|
| `pages/screens/<id>.html` | → Phase 3 该屏 |
| `pages/assets/screen.{css,js}` | → Phase 3 **扇出 `screens.yaml` 登记的全部屏**（共享层）|
| `pages/assets/timeline.{css,js}` | → 仅 timeline |
| `pages/assets/app.js` | → 屏清单 / 路由登记复核（新屏、删屏、状态顺序变化）|
| `docs/CHANGELOG.md` | → changelog 语义预检（不单独改 widget）|
| `DESIGN-REF.md §3` | → `ui-kit-components` 增量 |
- 结果：输出「受影响屏/组件清单」，同输入同输出（NF2）。

### R2 · token 重生集成（Phase 2，确定性）
When `tokens.css` 在 diff 中，工作流 SHALL 依次：① 跑 `check_tokens_sync.sh`（三份同源，分叉则中止）→ ② `dart run bin/gen_tokens.dart` → ③ 跑主题层回归（lerp / 确定性 diff 为空 / 对比度）。
- **对比度回归须区分**（否则三条已知 todo 把每次 token 同步长期堵死）：已登记 expected-fail（`design-tokens-theme` NF1 / `ui-design/DESIGN-FEEDBACK.md` 的 sage/amber/ink-3 三条，xfail allowlist）→ 同步语境 **advisory**（报 @Ray、**不 wedge** 管线）；allowlist 外的**新**对比度回归 → **block**。
- 结果：`dayz_tokens.g.dart` 与 `tokens.css` 不漂移；非 xfail 的步骤失败则该轮中止并报告。

### R3 · 屏幕登记表 `screens.yaml`（全局轻量）
系统 SHALL 维护 `specs/active/design-sync-automation/screens.yaml`：每屏一条 `{id, pinned: <ui-design commit hash>, lane: <维护态>, map: <element-map 路径指针>}`，屏 id 集合 MUST 与 `ui-design/current/pages/assets/app.js` 的 `SCREENS[]` 中产品屏保持一致（模板 `_template` 不登记）。
- `pinned` 是工作流每次跑的**输入锚**（diff 基线），不是文档摆设。
- MUST NOT 把映射表 / param fixture / golden 等重 churn 数据塞进本表（它们活在 per-feature 测试树）。

### R4 · 元素映射 + geometry 登记（per-screen）
每屏 SHALL 在 `test/ui/<feature>/element-map.yaml` 登记元素映射，每条目：`{class: <DESIGN-REF 稳定类名>, key: <Flutter widget key>, geometry: fixed|content, asserts: [...]}`。
- `geometry` 必填：`fixed` → 硬断言 size+pos；`content` → 只断 order/contains/no-overflow（**不断块高**，NF1）。

### R5 · 「实质变更」的确定性检测器集
工作流 SHALL 用三个确定性检测器（对 `pinned..HEAD`，无 agent 判断）判定「实质变更」（升实质档：建 sync 卡 + 补映射），任一非空即命中、**MUST NOT 被闸③当「全过」静默跳过**：
1. **未映射类**：`unmapped = extracted − registry − ignore`。`extracted` = 源屏渲染 DOM **全部在场类名**（**非仅 §3 已登记**——否则未登记的全新元素逃过集合差）；`registry` = `element-map.yaml` 已映射类；`ignore` = 显式装饰/wrapper 类白名单。**缺 `geometry` 标签的条目 = 等同未映射、并入 `unmapped`**。
2. **新状态**：源屏 `data-when` 值集 diff 非空。
3. **结构重排**：归一化 DOM 子序 diff 非空（粗粒度，宁可过判——过判 = 多一次关注，安全侧）。
- 注：`extracted`（检测用，全类名）与验证扫描（闸②/③ 只对**已映射类**取 `getComputedStyle`/`getBoundingClientRect`）是同一遍 gstack 抽取的两个产物——未映射的新元素无法验证，故必须先触发实质档补映射。

### R6 · 屏对齐工作流（Phase 3–5）
工作流 SHALL 对每个受影响屏：Phase 3 改 widget（worktree 隔离并行）→ Phase 4 验证（四层闸）→ Phase 5 更新 `pinned` + 产出 `SYNC_REPORT.md`。自修复循环退出 ⟺ **闸①②③ 全绿 ∧ ( 闸④ 各区 SSIM≥阈 ∨ 轮次≥cap )**；`cap = min(3, budget 允许轮数)`（1 初翻 + 2 修复）。
- 闸①②③ 红且轮次耗尽 → 该屏 build fail、`SYNC_REPORT` 标红、不自动合并。
- 闸④ 低分且轮次耗尽 → `SYNC_REPORT` 标红、**不阻塞**（advisory）。

### R7 · 三档分流（确定性判定，档名用语义、不用编号）
工作流 SHALL 按信号分流（doc 10 §8）：
- **微调档**（只 token 值 / 参数变、元素集与结构不变）→ 全自动，不碰 spec。
- **实质档**（R5 三检测器任一命中：未映射类 / 新 `data-when` / 结构重排；或新交互）→ 在该屏维护态 spec `tasks.md` 追加 sync 卡。
- **大改档**（信息架构 / 导航变）→ 开新 active spec。

### R8 · 屏幕维护态生命周期
屏幕级 spec MUST NOT 进「已归档」；交付 v1 后转「已交付·随设计维护」泳道（doc 10 §7）。对齐状态（`pinned`/`element-map`/param fixture/golden）活在 `screens.yaml` + per-feature 测试树，**不入归档**——故无「从归档捞回」。
- `scripts/check_ui_sync.sh` 反向巡检：某屏 `pinned` 落后于当前设计且其源屏 diff 非空 → 报「待同步」。

## 非功能需求

### NF1 · 验证分级（硬闸 vs advisory）
闸①(token值) / 闸②(样式参数) / 闸③(布局几何) MUST 为硬闸（任一红 → build fail）；闸④(栅格观感) MUST 为 round-budget best-effort（低分 → `SYNC_REPORT` 标红、不阻塞）。闸③ 对 `content-driven` 元素 MUST 只断 order/contains/no-overflow、不断块高（否则 minik 换行差异噪声逼循环到 cap、淹没真问题）。

### NF2 · 路由/分流确定性
Phase 1 路由、R5 的三个检测器（类名集合差 / `data-when` 值集 diff / 归一化 DOM 子序 diff）、由此驱动的三档分流判定 MUST 确定性（同输入同输出、无 agent 主观判断），可被脚本复算。

### NF3 · 有界资源
自修复循环每屏 MUST 受 `cap`（默认 3）约束；`cap` 耗尽即升 ②/人工，MUST NOT 无界空转烧 token。

## 专项维度逐维表态（选档依据）

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 只读 git diff + 跑校验/生成，不碰密钥/用户数据 |
| 权限 | 否 | 不申请系统权限 |
| 无障碍 | 否 | 本身是编排工具；对比度等无障碍由 `design-tokens-theme`/各屏 spec 的 NF 承担，本 spec 只调度其验证 |
| 性能 | 否 | 无 App 运行期性能阈值（`cap`/budget 属工具资源约束，见 NF3） |
| 多端兼容 | 否 | 工具链，不直接产 UI |

→ 专项维度均「否」，但本 spec 的**端到端「屏对齐工作流」验收跨任务**——Phase 1 路由 → Phase 2 token 重生 → Phase 3–5 对齐/验证/钉账，须 ≥2 个任务的产物同时在场才跑得通；且 `design-sync.js` 由期一路由任务与期二 harness 任务**共同编辑**——同时命中 spec-guide P1「跨任务校验」准则 ①②（line 108–112，intra-spec 定义）→ **升标准档**（含 verification.md + NF + 文件头状态 + README 索引）。
