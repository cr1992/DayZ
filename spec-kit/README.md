# spec-kit

> 一套**零依赖、跨平台（macOS/Linux）**的 spec 护栏。把"写 spec 的纪律"从荣誉制升级成**硬闸**——
> 因为荣誉制对人不可靠、对 LLM 更不成立：模型不会因为你在文档里写了"必须"就真的遵守。
> 于是我们用 git pre-commit 与 Claude Code PreToolUse 钩子，在**提交时**和**写文件时**机械地拦住违规。

## 这是什么 / 解决什么

LLM 驱动开发的最大风险是「跑偏」：验收命令写成 `grep 某文件` 而非跑测试（规避而非验证）、
spec 里塞了死链、RFC2119 关键词大小写乱用导致约束模糊、AI 顺手改了本任务不该动的文件。
spec-kit 用四道闸把这些机械可检的问题挡在门外，让人审专注在真正需要判断力的地方（如 SHALL/SHOULD 分级是否合理）。

- **死链闸**：spec 里相对链接指向不存在的文件/目录 → 拒绝。
- **验收命令抗规避闸**：tasks/verification 的验收里用正向 `grep` 源码文件冒充验收 → 拒绝（应跑测试断言行为）。
- **关键词闸**：requirement 里把 `must/should/shall/may` 写成小写/变形 → 提示大写（只查拼写大小写，不判语义）。
- **白名单闸**：Claude Code 写到「本任务可改文件清单」之外 → 提示（试点默认不阻断）。

## 目录说明

```
spec-kit/
├── spec-guide.md                       # spec 写作规范（P1/P2/P3… 条款，闸引用其编号）
├── scripts/
│   ├── check_dead_links.sh             # 死链闸
│   ├── lint_acceptance_commands.sh     # 验收命令抗规避闸（规范 P3）
│   ├── lint_keywords.sh                # RFC2119 关键词大小写闸
│   └── archive_spec.sh                 # 功能归档：移目录 + 改 README 索引 + 全仓库改引用 + 查死链
├── hooks/
│   ├── pre-commit                      # git 提交闸：暂存的 specs/**/*.md 跑三道 lint
│   └── claude-pretooluse-whitelist.sh  # Claude Code PreToolUse 白名单闸
├── install.sh                          # 一键安装（幂等、不覆盖既有 hook、--with-claude 可选）
└── README.md                           # 本文件
```

约定：所有脚本默认作用于**当前工作目录下的 `specs/`**，可用第一个参数或环境变量 `SPECS_DIR` 覆盖。
退出码统一：`0`=通过，`1`=发现违规（逐条打印 `相对路径:行号: 说明` 并附违规计数），`2`=用法/环境错误。

## 安装

把 `spec-kit/` 放进你的仓库（或作为子模块/vendored 目录），在**仓库根**运行：

```bash
bash spec-kit/install.sh              # 只装 git pre-commit 闸
bash spec-kit/install.sh --with-claude # 额外注册 Claude Code PreToolUse 白名单闸
```

安装行为：

- **幂等**：可反复运行；已装则跳过，不重复追加。
- **不覆盖你已有的 pre-commit**：若 `.git/hooks/pre-commit` 已存在，先备份成 `.bak.<时间戳>`，再把 spec-kit 的调用**追加**进去（包在 `# >>> spec-kit pre-commit >>>` 标记之间）。
- `--with-claude`：把 PreToolUse hook 合并进 `.claude/settings.json`（有 `jq` 自动合并；无 `jq` 则打印需手动粘贴的 JSON 片段）。

安装脚本结尾会打印「已装什么 / 怎么用 / 怎么卸」。卸载就是删掉那对标记之间的区块（或本 kit 新建的整个 hook 文件）。

## 四道闸各做什么

### 1. 死链闸 — `scripts/check_dead_links.sh [SPECS_DIR]`
扫描 `SPECS_DIR` 下所有 `.md` 的 Markdown 相对链接 `[文字](相对路径)`（忽略 `http(s)://`、`mailto:`、`#锚点`），
按链接所在 md 文件解析相对路径；目标文件或目录不存在即违规。
```bash
bash spec-kit/scripts/check_dead_links.sh            # 查 ./specs
bash spec-kit/scripts/check_dead_links.sh path/to/specs
```

### 2. 验收命令抗规避闸 — `scripts/lint_acceptance_commands.sh [SPECS_DIR]`
只看 `tasks.md` / `verification.md`。在「### 验收方式」/验收命令区里，若用**正向** `grep`（排除 `! grep` 与 `grep -v`）
去匹配某个**源码文件路径**（`.dart/.ts/.tsx/.js/.css/.yaml/.sql/.go/.py/.kt/.swift` 等）当作验收 → 违规：
这是"看代码里有没有这行字"而非"验证行为"，属规范 **P3 抗规避**禁止项，应改为跑测试断言行为。
`! grep`（缺失守卫，断言某内容**不该**出现）放行。启发式从严避免误伤，宁可少报。

### 3. 关键词闸 — `scripts/lint_keywords.sh [SPECS_DIR]`
只看 `requirement.md`。校验 RFC2119 关键词（must / should / shall / may / must not …）的
**存在性与大小写**：出现独立小写/变形写法 → 提示应大写。
**只查拼写大小写，不判语义**——`SHALL` 与 `SHOULD` 的分级是否用对属于人审范畴，本闸不碰。

### 4. 白名单闸 — `hooks/claude-pretooluse-whitelist.sh`
Claude Code 的 `PreToolUse`（matcher `Write|Edit`）钩子。从 stdin 读 hook 输入 JSON，取 `tool_input.file_path`
（优先 `jq`，无 `jq` 用 `grep/sed` 降级提取），对照仓库根 `.spec-task-whitelist`：命中清单内、或 `test/**/*_test.dart`
则放行；命中清单外则提示。**试点默认 `decision=warn`（不阻断）**——脚本顶部把 `DECISION` 改成 `deny` 即变强阻断。
**无 `.spec-task-whitelist` 文件时直接放行**（功能默认关闭，零打扰）。

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
    bash spec-kit/scripts/lint_acceptance_commands.sh specs
    bash spec-kit/scripts/lint_keywords.sh specs
```

任一非 0 即让该步骤失败。CI 与本地 pre-commit 用同一批脚本，行为一致。
（白名单闸是 Claude Code 写时钩子，不在 CI 跑。）

## 按你的技术栈裁剪

这套闸对栈基本无感，但有两处可按需调整：

- **验收命令闸的源码后缀**：`lint_acceptance_commands.sh` 里的扩展名清单
  （`.dart/.ts/.tsx/...`）就是"什么算源码文件"。换栈时增删后缀即可，例如纯 Rust 项目加 `.rs`、去掉前端那几个。
- **白名单的自动放行规则**：`claude-pretooluse-whitelist.sh` 默认自动放行 `test/**/*_test.dart`（Dart 约定）。
  其它栈把它改成你的测试约定，如 `**/*_test.go`、`**/test_*.py`、`**/*.spec.ts`。

死链闸与关键词闸与栈无关，无需改动。改完用 `bash -n 脚本` 自检语法。
