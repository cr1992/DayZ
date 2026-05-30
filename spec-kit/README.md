# spec-kit

> 一套**零依赖、跨平台（macOS/Linux）**的 spec 护栏。把"写 spec 的纪律"从荣誉制升级成**硬闸**——
> 因为荣誉制对人不可靠、对 LLM 更不成立：模型不会因为你在文档里写了"必须"就真的遵守。
> 于是我们用 git pre-commit 与 Claude Code PreToolUse 钩子，在**提交时**和**写文件时**机械地拦住违规。

## 这是什么 / 解决什么

LLM 驱动开发的最大风险是「跑偏」：验收命令写成 `grep 某文件` 而非跑测试（规避而非验证）、
spec 里塞了死链、RFC2119 关键词大小写乱用导致约束模糊、README 索引与目录状态漂移、
AI 顺手改了本任务不该动的文件。spec-kit 用硬闸把这些机械可检的问题挡在门外，
让人审专注在真正需要判断力的地方（如 SHALL/SHOULD 分级是否合理）。

- **死链闸**：spec 里相对链接指向不存在的文件/目录 → 拒绝。
- **验收命令抗规避闸**：tasks/verification 的验收里用正向 `grep` 源码文件冒充验收 → 拒绝（应跑测试断言行为）。
- **关键词闸**：requirement 里把 `must/should/shall/may` 写成小写/变形 → 提示大写（只查拼写大小写，不判语义）。
- **索引一致性闸**：`specs/README.md` 与 active/archive/contracts 目录、依赖列、执行顺序快照不一致 → 拒绝。
- **白名单闸**：Claude Code 写到「本任务可改文件清单」之外 → **默认 deny 阻断**并把原因反馈模型（让 AI 不跑偏）。

## 目录说明

```
spec-kit/
├── spec-guide.md                          # spec 写作规范（P1/P2/P3… 条款，闸引用其编号）
├── scripts/
│   ├── check_dead_links.sh                # 死链闸
│   ├── check_specs_index.sh               # README 索引一致性闸
│   ├── lint_acceptance_commands.sh        # 验收命令抗规避闸（规范 P3）
│   ├── lint_keywords.sh                   # RFC2119 关键词大小写 + 存在性闸
│   ├── lint_whitelist_scope.sh            # 通用 git 兜底闸：暂存文件 ⊆ .spec-task-whitelist
│   └── archive_spec.sh                    # 功能归档：移目录 + 改 README 索引 + 全仓库改引用 + 查死链
├── hooks/
│   ├── pre-commit                         # git 提交闸：暂存的 specs/**/*.md 跑文档 lint
│   ├── whitelist_core.sh                  # 写时白名单判定核心（各 agent 适配器共用：归一化/glob/test放行/json_escape）
│   ├── claude-pretooluse-whitelist.sh     # Claude  PreToolUse 写时白名单适配器
│   ├── gemini-beforetool-whitelist.sh     # Gemini  BeforeTool 写时白名单适配器
│   ├── codex-pretooluse-whitelist.sh      # Codex   PreToolUse 写时白名单适配器
│   └── kiro-pretooluse-whitelist.sh       # Kiro    preToolUse 写时白名单适配器
├── install.sh                             # 一键安装（幂等、不覆盖既有 hook、--with-<agent>/--with-backstop 可选）
├── docs/
│   ├── DESIGN.md                          # 设计与决策记录：整体设计 + 决策 why + 实操发现的问题 + 多-agent 适配（概览）
│   └── multi-agent-adapters.md            # 多-agent 写时闸适配·实现级详细设计（Codex/Kiro/Gemini）
└── README.md                              # 本文件
```

约定：所有脚本默认作用于**当前工作目录下的 `specs/`**，可用第一个参数或环境变量 `SPECS_DIR` 覆盖。
退出码统一：`0`=通过，`1`=发现违规（逐条打印 `相对路径:行号: 说明` 并附违规计数），`2`=用法/环境错误。

## 安装

把 `spec-kit/` 放进你的仓库（或作为子模块/vendored 目录），在**仓库根**运行：

```bash
bash spec-kit/install.sh                 # 只装 git pre-commit 文档闸
bash spec-kit/install.sh --with-claude    # + Claude 写时白名单 hook（默认 deny + 原因回传模型）
bash spec-kit/install.sh --with-gemini    # + Gemini（--with-codex / --with-kiro 同理）
bash spec-kit/install.sh --with-all-agents --with-backstop   # 四 agent 全装 + 通用 git 兜底闸
```

> 也可不先 vendored，直接在线一行装（见上层 railkit）：
> `curl -fsSL https://raw.githubusercontent.com/cr1992/railkit/main/bootstrap.sh | bash -s -- spec-kit --with-claude`

安装行为：

- **幂等**：可反复运行；已装则跳过，不重复追加（各 agent 配置按 matcher+command 去重）。
- **不覆盖你已有的 pre-commit**：若 `.git/hooks/pre-commit` 已存在，先备份成 `.bak.<时间戳>`，再把 spec-kit 调用块（包在 `# >>> spec-kit pre-commit >>>` 标记之间）**插到 shebang 之后**——让 spec-kit 闸**先于**你原有逻辑里可能的提前 `exit 0` 运行，避免被静默跳过。worktree 下用 `--git-common-dir` 定位 hooks（否则装错目录、闸失效）。
- **非 shell 的既有 hook 会停手**：若既有 pre-commit 的 shebang 不是 sh/bash/zsh（如 python/ruby/node），追加 bash 会损坏它，故 spec-kit **拒绝自动改写**、保留原文件并打印手工接入指引。
- **写时白名单各 agent 接入**（可选、互不影响、都默认 deny）：`--with-claude`→`.claude/settings.json`、`--with-gemini`→`.gemini/settings.json`、`--with-codex`→项目级 `.codex/config.toml`（需信任）、`--with-kiro`→合并进现有 `.kiro/agents/*.json`（不新建孤儿 agent）。Codex/Kiro/Gemini 装后建议在真实 agent 各 live 核一次（见 `docs/multi-agent-adapters.md` §7）。
- `--with-backstop`：装通用 git 兜底闸（`lint_whitelist_scope.sh`，暂存文件 ⊆ 白名单），补写时 hook 漏掉的 shell 重定向写 / 无 hook 的 agent。

安装脚本结尾会打印「已装什么 / 怎么用 / 怎么卸」。卸载就是删掉那对标记之间的区块（或本 kit 新建的整个 hook 文件）。

## 硬闸各做什么

### 1. 死链闸 — `scripts/check_dead_links.sh [SPECS_DIR]`
扫描 `SPECS_DIR` 下所有 `.md` 的 Markdown 相对链接 `[文字](相对路径)`（忽略 `http(s)://`、`mailto:`、`#锚点`），
按链接所在 md 文件解析相对路径；目标文件或目录不存在即违规。
代码围栏（```` ``` ````…）与行内 code（`` `…` ``）里的示例链接不算真链接、已跳过（与另两道 lint 行为一致）。
（已知局限：只查内联式链接，不解析引用式 `[文字][ref]` + `[ref]: 路径`。）
```bash
bash spec-kit/scripts/check_dead_links.sh            # 查 ./specs
bash spec-kit/scripts/check_dead_links.sh path/to/specs
```

### 2. 索引一致性闸 — `scripts/check_specs_index.sh [SPECS_DIR]`
检查 `SPECS_DIR/README.md` 与 `active/`、`archive/`、`contracts/` 的结构一致性，防止手写索引与真实目录漂移。
默认检查：
- Markdown 冲突标记残留。
- README 二级标题重复（常见于合并冲突或手工剪贴后残留重复分区）。
- `## 进行中` 表必须有 `功能`/`依赖`/`状态` 列，且每个功能链接指向真实 `active/<spec-id>/`。
- `## 已归档` 表必须有 `功能`/`结果` 列，且每个功能链接指向真实 `archive/<date-spec-id>/`。
- active/archive 表与目录双向一致；同一稳定 spec ID 不得同时出现在 active 与 archive。
- `依赖` 列中的前置 ID 必须能解析为 active、archive 或 contracts 中的有效 ID（支持逗号/中文逗号分隔，支持链接、`active/foo/`、`archive/YYYY-MM-DD-foo/`、`contracts/bar/`，也支持备注括号）。
- 若存在 `archive/acceptance-review.md`，其结论表必须覆盖每个已归档稳定 spec ID；若不存在该台账，归档 spec 不得残留未完成 / 待确认验收痕迹。这个检查用于防止「已归档但未 review」。
- `## 执行顺序` 的编号步骤不得继续引用已归档 spec；这是派生快照过期的高信号。

```bash
bash spec-kit/scripts/check_specs_index.sh            # 查 ./specs
bash spec-kit/scripts/check_specs_index.sh path/to/specs
```

### 3. 验收命令抗规避闸 — `scripts/lint_acceptance_commands.sh [SPECS_DIR]`
只看 `tasks.md` / `verification.md`。**作用域**：`tasks.md` 仅在标题含「验收 / 验证」的小节内判定（如 `### 验收方式`），
散文段（背景 / 概述 / 实施）里提到 `grep` 不算验收命令、不误报；`verification.md` 整篇皆为验证，全程判定。
在作用域内若用**正向** `grep`（排除 `! grep` 与 `grep -v`）去匹配某个**源码文件路径**
（`.dart/.ts/.tsx/.js/.css/.yaml/.sql/.go/.py/.kt/.swift` 等）当作验收 → 违规：
这是"看代码里有没有这行字"而非"验证行为"，属规范 **P3 抗规避**禁止项，应改为跑测试断言行为。
`! grep`（缺失守卫，断言某内容**不该**出现）放行。启发式从严避免误伤，宁可少报。
（已知局限：标题只要含「验收/验证」子串即开启作用域，如「## 不要用 grep 做验收」会误开——实际标题用模板写法即可避开。）

### 4. 关键词闸 — `scripts/lint_keywords.sh [SPECS_DIR]`
只看 `requirement.md`。校验 RFC2119 关键词（must / should / shall / may / must not …）的**存在性与大小写**：
- **大小写**：出现独立小写/变形写法（must/shall/should 及否定式）→ 提示应大写。
- **存在性**：全篇无任何大写 RFC2119 关键词（MUST/SHALL/SHOULD/MAY）→ 报缺失，requirement 须用规范关键词描述系统行为。
**只查拼写大小写与存在性，不判语义**——`SHALL` 与 `SHOULD` 的分级是否用对属于人审范畴，本闸不碰。

### 5. 写时白名单闸（多 agent）— `hooks/whitelist_core.sh` + 各 agent 适配器
判定逻辑（定位仓库根 / 路径归一化含相对路径按 cwd 锚定 + 新建文件祖先物理化 / glob 匹配 / `test/**/*_test.dart` 自动放行 /
**无 `.spec-task-whitelist` 则全放行** / `json_escape`）全在与 agent 无关的 **`whitelist_core.sh`**；每个 agent 一个**薄适配器**只翻译自家 I/O：
- `claude-pretooluse-whitelist.sh`（Claude `PreToolUse`，取 `tool_input.file_path`/`notebook_path`）
- `gemini-beforetool-whitelist.sh`（Gemini `BeforeTool`，取 `tool_input.file_path`）
- `codex-pretooluse-whitelist.sh`（Codex `PreToolUse`，解析 `apply_patch` 信封头行取多路径；不用 set -e 防 fail-open）
- `kiro-pretooluse-whitelist.sh`（Kiro `preToolUse`，取 `operations[].path`，`exit 2 + stderr` 表达 deny）

命中清单内、或 `test/**/*_test.dart` 则放行；命中清单外则按 `DECISION` 处置（核心退出码 0=放行 / 10=越界并逐行打越界路径 / 2=环境错）。
**默认 `DECISION=deny`（真阻断）**：越界写被拦下，并把原因经 `permissionDecisionReason`/`additionalContext`
**反馈给模型**，模型据此停手/改道/请示——这才挡得住 AI 跑偏。
（关键事实：PreToolUse 的 `systemMessage` 只给**用户**看、**模型不可见**，所以 `warn` 模式拦不住模型；warn 已改为
同时用 `additionalContext` 把提示注入模型上下文，但仍放行。要真约束模型就用默认的 deny。脚本顶部 `DECISION` 可切回 `warn`。）
**无 `.spec-task-whitelist` 文件时直接放行**（功能默认关闭，零打扰）。

> 前提：白名单本身要正确——每个任务的「可改文件」应 ⊆ 该 spec 的 design `## 文件变更`（见 spec-guide P2）。
> deny 只保证「不写白名单外」，保证不了「白名单没越出设计」；后者是 AI 跑偏的头号结构性来源，靠 spec 规则 + 人审兜。

> 配套：`scripts/archive_spec.sh <功能名> [--cancelled]` 三步原子归档一个功能（移动 `specs/active/<功能名>`
> 到 `specs/archive/<日期>-<功能名>`、改 README 索引表、全仓库修正引用、跑死链闸）。无法可靠定位 README 表结构时
> 它会 fail-safe：只做移动并打印精确的手工步骤，宁可让你补也不破坏文档。

## 白名单约定（`.spec-task-whitelist`）

在**仓库根**放一个 `.spec-task-whitelist` 文件，记录**当前任务**允许改的文件（"可改文件 + 预批例外"）。
每行一个相对仓库根的路径 glob，`#` 开头为注释，空行忽略。`**` 表示任意层级目录。例：

```
# 本任务（auto-save-draft）可改文件
lib/features/draft/**
lib/data/draft_repository.dart
# 预批例外：允许动这个共享常量
lib/core/constants.dart
```

`test/**/*_test.dart` 始终自动放行（写测试不受限）。每开新任务，更新这份清单即可。

## 接 CI

闸即普通脚本、退出码标准（0/1/2），直接在 CI 跑即可（无需安装 git hook）：

```yaml
# GitHub Actions 示例
- name: spec lint
  run: |
    bash spec-kit/scripts/check_dead_links.sh specs
    bash spec-kit/scripts/check_specs_index.sh specs
    bash spec-kit/scripts/lint_acceptance_commands.sh specs
    bash spec-kit/scripts/lint_keywords.sh specs
```

任一非 0 即让该步骤失败。CI 与本地 pre-commit 用同一批脚本，但**作用范围有意分工**：
- **本地 pre-commit**：只查本次提交涉及的文件，且关键词/验收闸校验的是**暂存内容**（物化暂存 blob，不受未暂存改动影响）、死链闸查工作树——快、精准、拦本次引入的新违规。
- **CI**：对整个 `specs/` 全量扫描——兜底历史遗留与漏网，是最终真相。

（白名单闸是 Claude Code 写时钩子，不在 CI 跑。）

## 按你的技术栈裁剪

这套闸对栈基本无感，但有两处可按需调整：

- **验收命令闸的源码后缀**：`lint_acceptance_commands.sh` 里的扩展名清单
  （`.dart/.ts/.tsx/...`）就是"什么算源码文件"。换栈时增删后缀即可，例如纯 Rust 项目加 `.rs`、去掉前端那几个。
- **白名单的自动放行规则**：`claude-pretooluse-whitelist.sh` 默认自动放行 `test/**/*_test.dart`（Dart 约定）。
  其它栈把它改成你的测试约定，如 `**/*_test.go`、`**/test_*.py`、`**/*.spec.ts`。

死链闸、索引一致性闸与关键词闸与栈无关，无需改动。改完用 `bash -n 脚本` 自检语法。

## 脚本自测

涉及硬闸行为变更时，必须用故障夹具证明坏样本会失败、好样本会通过。当前内置自测：

```bash
bash test/scripts/check_specs_index_test.sh
```
