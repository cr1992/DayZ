#!/usr/bin/env bash
set -euo pipefail
#
# spec-kit · install.sh
#
# 用途：在目标 git 仓库根运行，安装 spec-kit 的两个集成入口（pre-commit 执行点承载死链/验收/关键词三道 lint）：
#         ① pre-commit hook  -> .git/hooks/pre-commit（spec markdown 三道 lint）
#         ② --with-claude    -> .claude/settings.json 注册 PreToolUse 白名单 hook
# 用法：在你的仓库根执行 `bash spec-kit/install.sh [--with-claude]`
# 退出码：0=安装成功；2=环境错误（非 git 仓库 / 找不到 kit 文件）。
# 特性：幂等可重跑；**不覆盖**用户已有的 pre-commit（备份 .bak 后追加调用本 kit）。
# 强制规范：把"硬闸"落到本地 git 与 Claude Code，使 spec 约束对人和 LLM 都生效。

WITH_CLAUDE=0; WITH_GEMINI=0; WITH_CODEX=0; WITH_KIRO=0; WITH_BACKSTOP=0
print_usage() {
  cat <<'USAGE'
用法: bash spec-kit/install.sh [选项...]
  （无选项）         只装 git pre-commit 三道闸（死链/验收/关键词，与 agent 无关）
  --with-claude     注册 Claude Code PreToolUse 写时白名单 hook
  --with-gemini     注册 Gemini CLI BeforeTool 写时白名单 hook (.gemini/settings.json)
  --with-codex      注册 Codex CLI PreToolUse 写时白名单 hook (项目级 .codex/config.toml)
  --with-kiro       注册 Kiro preToolUse 写时白名单 hook (合并进现有 .kiro/agents/*.json)
  --with-all-agents 上面四个 agent 一起装
  --with-backstop   装通用 git 兜底闸（暂存文件 ⊆ .spec-task-whitelist，补 shell 绕过/无 hook 的 agent）
USAGE
}
for arg in "$@"; do
  case "$arg" in
    --with-claude)     WITH_CLAUDE=1 ;;
    --with-gemini)     WITH_GEMINI=1 ;;
    --with-codex)      WITH_CODEX=1 ;;
    --with-kiro)       WITH_KIRO=1 ;;
    --with-all-agents) WITH_CLAUDE=1; WITH_GEMINI=1; WITH_CODEX=1; WITH_KIRO=1 ;;
    --with-backstop)   WITH_BACKSTOP=1 ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "未知参数: $arg" >&2; print_usage >&2; exit 2 ;;
  esac
done

# --- 定位 kit 自身与目标仓库根 -------------------------------------------
KIT_DIR="$(cd "$(dirname "$0")" && pwd -P)"        # .../spec-kit（物理路径：避免 macOS /tmp 等 symlink 前缀与 ROOT 不等）
HOOKS_SRC="$KIT_DIR/hooks"
SCRIPTS_SRC="$KIT_DIR/scripts"

if [ ! -d "$HOOKS_SRC" ] || [ ! -f "$HOOKS_SRC/pre-commit" ]; then
  echo "错误：找不到 kit hooks（$HOOKS_SRC/pre-commit）。" >&2
  exit 2
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  echo "错误：当前目录不在 git 仓库内，请在仓库根运行。" >&2
  exit 2
fi
# 物理化，和 KIT_DIR 同口径（否则 symlink 路径下 case "$ROOT"/* 判不出 kit 在仓库内）。
ROOT="$(cd "$ROOT" && pwd -P)"

# 用 --git-common-dir（非 --git-dir）：git 从**公共** git 目录的 hooks/ 执行 hook；
# 在 git worktree 里 --git-dir 指向 per-worktree 的 .git/worktrees/<name>（hook 装那里 git 不会跑），
# 而 --git-common-dir 始终指向公共 .git（worktree 与主仓库共享 hooks）。普通仓库下两者一致。
GIT_DIR="$(git rev-parse --git-common-dir 2>/dev/null)"
case "$GIT_DIR" in
  /*) : ;;                       # 已是绝对路径
  *)  GIT_DIR="$ROOT/$GIT_DIR" ;; # 相对 → 拼到 root
esac
HOOK_DST="$GIT_DIR/hooks/pre-commit"
mkdir -p "$GIT_DIR/hooks"

# spec-kit 调用块的稳定标记，便于幂等检测与卸载
BEGIN_MARK="# >>> spec-kit pre-commit >>>"
END_MARK="# <<< spec-kit pre-commit <<<"

# 计算 hook 内引用 kit scripts 的稳定路径（相对仓库根，安装位置无关）
# 若 kit 就在仓库内，记录相对路径；否则记绝对路径。
case "$SCRIPTS_SRC" in
  "$ROOT"/*) SCRIPTS_REF="\$ROOT/${SCRIPTS_SRC#"$ROOT"/}" ;;
  *)         SCRIPTS_REF="$SCRIPTS_SRC" ;;
esac

# spec-kit 注入到 .git/hooks/pre-commit 的调用块
make_block() {
  cat <<EOF
$BEGIN_MARK
# 由 spec-kit/install.sh 安装/维护。删除本 BEGIN..END 区块即卸载本闸。
ROOT="\$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPEC_KIT_SCRIPTS="$SCRIPTS_REF" \\
  bash "$SCRIPTS_REF/../hooks/pre-commit" || exit \$?
$END_MARK
EOF
}

# 判断既有 hook 的 shebang 是否为 POSIX shell（能安全承载本 kit 的 bash 调用块）。
# 识别 #!/usr/bin/env bash 形式；非 shell（python/ruby/node/perl/fish/csh…）或无 shebang → 假。
hook_is_shell() {
  local first="$1" interp
  case "$first" in
    '#!'*) : ;;
    *) return 1 ;;                         # 无 shebang：不敢断定，按非 shell 处理
  esac
  case "$first" in
    *'env '*) interp="$(printf '%s' "$first" | sed -e 's/.*env[[:space:]]\{1,\}//' -e 's/[[:space:]].*//')" ;;
    *)        interp="${first##*/}"; interp="${interp%% *}" ;;
  esac
  case "$interp" in
    sh|bash|dash|ash|ksh|zsh) return 0 ;;
    *) return 1 ;;
  esac
}

PRECOMMIT_INSTALLED=0   # 供收尾说明判断是否真的装上了 pre-commit 闸

install_precommit() {
  if [ ! -e "$HOOK_DST" ]; then
    # 全新安装：写一个最小 wrapper（shebang + 调用块）
    {
      echo "#!/usr/bin/env bash"
      echo "set -euo pipefail"
      echo ""
      make_block
    } > "$HOOK_DST"
    chmod +x "$HOOK_DST"
    PRECOMMIT_INSTALLED=1
    echo "已安装：${HOOK_DST}（新建）"
    return
  fi

  # 已存在 hook：检查是否已含 spec-kit 区块（幂等）
  if grep -q "$BEGIN_MARK" "$HOOK_DST" 2>/dev/null; then
    PRECOMMIT_INSTALLED=1
    echo "已就绪：$HOOK_DST 已含 spec-kit 区块，跳过（幂等）。"
    return
  fi

  # 既有自定义 hook：先备份，绝不覆盖。
  backup="$HOOK_DST.bak.$(date +%Y%m%d%H%M%S)"
  cp "$HOOK_DST" "$backup"

  local first_line
  first_line="$(head -n 1 "$HOOK_DST" 2>/dev/null || true)"

  if ! hook_is_shell "$first_line"; then
    # 非 shell 解释器或无 shebang：追加 bash 会把它变成语法错误的混合体 → 停手不改。
    echo "" >&2
    echo "⚠ 既有 ${HOOK_DST} 不是 shell 脚本（首行：${first_line:-<无 shebang>}）。" >&2
    echo "  追加 bash 会损坏它，spec-kit 已停手（原文件保持不变，备份在 ${backup}）。" >&2
    echo "  请二选一手工接入 spec-kit 闸：" >&2
    echo "    A) 在该 hook 内用其语言调用：bash \"$SCRIPTS_REF/../hooks/pre-commit\"" >&2
    echo "    B) pre-commit 不装，改在 CI 跑三道 lint（见 README「接 CI」）。" >&2
    return
  fi

  # shell hook：把 spec-kit 块插到 shebang 之后——确保它先于既有 hook 里可能存在的提前
  # `exit 0` 运行（否则块被追加在 exit 之后会被静默跳过，闸形同虚设）。
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/spec-kit-hook.XXXXXX")"
  {
    head -n 1 "$HOOK_DST"
    echo ""
    make_block
    echo ""
    tail -n +2 "$HOOK_DST"
  } > "$tmp" && mv "$tmp" "$HOOK_DST"
  chmod +x "$HOOK_DST"
  PRECOMMIT_INSTALLED=1
  echo "已插入：${HOOK_DST}（spec-kit 闸置于 shebang 之后、先于你原有逻辑运行；备份在 ${backup}）"
}

# --- Claude PreToolUse hook 注册 -----------------------------------------
CLAUDE_HOOK_SRC="$HOOKS_SRC/claude-pretooluse-whitelist.sh"
case "$CLAUDE_HOOK_SRC" in
  "$ROOT"/*) CLAUDE_HOOK_REF="\$CLAUDE_PROJECT_DIR/${CLAUDE_HOOK_SRC#"$ROOT"/}" ;;
  *)         CLAUDE_HOOK_REF="$CLAUDE_HOOK_SRC" ;;
esac

claude_hook_json_snippet() {
  cat <<EOF
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \\"$CLAUDE_HOOK_REF\\""
          }
        ]
      }
    ]
  }
}
EOF
}

install_claude() {
  local settings="$ROOT/.claude/settings.json"
  mkdir -p "$ROOT/.claude"

  if ! command -v jq >/dev/null 2>&1; then
    echo ""
    echo "未检测到 jq：请手动把下面片段合并进 $settings 的 hooks.PreToolUse："
    echo "----------------------------------------------------------------"
    claude_hook_json_snippet
    echo "----------------------------------------------------------------"
    return
  fi

  local cmd="bash \"$CLAUDE_HOOK_REF\""

  if [ ! -f "$settings" ]; then
    printf '%s\n' '{}' > "$settings"
  fi

  # 幂等：已存在同 matcher + 同 command 的 PreToolUse hook 则不重复加
  if jq -e --arg c "$cmd" '
        (.hooks.PreToolUse // [])
        | any(.[]?; (.matcher == "Edit|MultiEdit|Write|NotebookEdit")
              and ((.hooks // []) | any(.[]?; .command == $c)))
      ' "$settings" >/dev/null 2>&1; then
    echo "已就绪：Claude PreToolUse 白名单 hook 已在 ${settings}（幂等）。"
    return
  fi

  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/spec-kit.XXXXXX")"
  jq --arg c "$cmd" '
    .hooks = (.hooks // {})
    | .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{
        "matcher": "Edit|MultiEdit|Write|NotebookEdit",
        "hooks": [ { "type": "command", "command": $c } ]
      }])
  ' "$settings" > "$tmp" && mv "$tmp" "$settings"
  echo "已注册：Claude PreToolUse 白名单 hook -> $settings"
}

# --- 其它 agent 写时 hook（绝对路径；各 agent 无统一 project-dir 变量，按机器安装，移动仓库后重跑即可）---
GEMINI_HOOK="$HOOKS_SRC/gemini-beforetool-whitelist.sh"
CODEX_HOOK="$HOOKS_SRC/codex-pretooluse-whitelist.sh"
KIRO_HOOK="$HOOKS_SRC/kiro-pretooluse-whitelist.sh"

install_gemini() {
  local settings="$ROOT/.gemini/settings.json"; mkdir -p "$ROOT/.gemini"
  local cmd="bash \"$GEMINI_HOOK\""
  if ! command -v jq >/dev/null 2>&1; then
    echo ""; echo "未检测到 jq：请手动把下面合并进 $settings 的 hooks.BeforeTool："
    printf '{ "hooks": { "BeforeTool": [ { "matcher": "^(write_file|replace)$", "hooks": [ { "type": "command", "command": "%s" } ] } ] } }\n' "$cmd"
    return
  fi
  [ -f "$settings" ] || printf '%s\n' '{}' > "$settings"
  if jq -e --arg c "$cmd" '(.hooks.BeforeTool // []) | any(.[]?; (.matcher=="^(write_file|replace)$") and ((.hooks//[])|any(.[]?;.command==$c)))' "$settings" >/dev/null 2>&1; then
    echo "已就绪：Gemini BeforeTool 白名单 hook 已在 ${settings}（幂等）。"; return
  fi
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/spec-kit.XXXXXX")"
  jq --arg c "$cmd" '.hooks=(.hooks//{}) | .hooks.BeforeTool=((.hooks.BeforeTool//[])+[{"matcher":"^(write_file|replace)$","hooks":[{"type":"command","command":$c}]}])' "$settings" > "$tmp" && mv "$tmp" "$settings"
  echo "已注册：Gemini BeforeTool 白名单 hook -> $settings"
}

install_codex() {
  local cfg="$ROOT/.codex/config.toml"; mkdir -p "$ROOT/.codex"
  local B="# >>> spec-kit codex >>>" E="# <<< spec-kit codex <<<"
  if [ -f "$cfg" ] && grep -qF "$B" "$cfg" 2>/dev/null; then
    echo "已就绪：Codex PreToolUse hook 已在 ${cfg}（幂等）。"; return
  fi
  # 确保 [features] hooks=true（TOML 无 jq：仅在「无 hooks=true」时处理，已有 [features] 表则提示手工以免重复表头）
  if [ -f "$cfg" ] && grep -qE '^[[:space:]]*hooks[[:space:]]*=[[:space:]]*true' "$cfg"; then
    :
  elif [ -f "$cfg" ] && grep -qE '^\[features\]' "$cfg"; then
    echo "⚠ ${cfg} 已有 [features] 表但未见 hooks = true，请手动在其下加一行：hooks = true" >&2
  else
    { echo "[features]"; echo "hooks = true"; } >> "$cfg"
  fi
  cat >> "$cfg" <<EOF

$B
[[hooks.PreToolUse]]
matcher = "^(apply_patch|Edit|Write|MultiEdit)\$"

[[hooks.PreToolUse.hooks]]
type = "command"
command = 'bash "$CODEX_HOOK"'
$E
EOF
  echo "已注册：Codex PreToolUse 白名单 hook -> $cfg"
  echo "  注意：CI/非交互需在 requirements.toml 信任本 hook 或加 --dangerously-bypass-hook-trust；请在真实 Codex 验证对 apply_patch 触发。" >&2
}

install_kiro() {
  if ! command -v jq >/dev/null 2>&1; then echo "未检测到 jq：Kiro 接入需 jq，已跳过。" >&2; return; fi
  local cmd="bash \"$KIRO_HOOK\"" found=0 a tmp
  for a in "$ROOT"/.kiro/agents/*.json; do
    [ -f "$a" ] || continue
    found=1
    if jq -e --arg c "$cmd" '(.hooks.preToolUse // []) | any(.[]?; (.matcher=="fs_write") and (.command==$c))' "$a" >/dev/null 2>&1; then
      echo "已就绪：Kiro preToolUse 已在 $a（幂等）。"; continue
    fi
    tmp="$(mktemp "${TMPDIR:-/tmp}/spec-kit.XXXXXX")"
    jq --arg c "$cmd" '.hooks=(.hooks//{}) | .hooks.preToolUse=((.hooks.preToolUse//[])+[{"matcher":"fs_write","command":$c,"timeout_ms":5000}])' "$a" > "$tmp" && mv "$tmp" "$a"
    echo "已注册：Kiro preToolUse 白名单 hook -> $a"
  done
  if [ "$found" -eq 0 ]; then
    echo "⚠ 未找到 .kiro/agents/*.json：Kiro hook 只在被激活的 agent 上生效，故不新建孤儿 agent。" >&2
    echo "  请在你的 Kiro agent 配置 hooks.preToolUse 手动加：{\"matcher\":\"fs_write\",\"command\":\"$cmd\",\"timeout_ms\":5000}" >&2
  else
    echo "  注意：装完请用真实 Kiro run 确认 hook 真触发（fs_write schema 需 live 核）。" >&2
  fi
}

# --- 通用 git 兜底闸（D7：暂存文件 ⊆ 白名单）---
BACKSTOP_BEGIN="# >>> spec-kit backstop >>>"
BACKSTOP_END="# <<< spec-kit backstop <<<"
make_backstop_block() {
  cat <<EOF
$BACKSTOP_BEGIN
# 由 spec-kit/install.sh --with-backstop 安装。删除本 BEGIN..END 区块即卸载。
ROOT="\$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
bash "$SCRIPTS_REF/lint_whitelist_scope.sh" || exit \$?
$BACKSTOP_END
EOF
}
install_backstop() {
  if [ -e "$HOOK_DST" ] && grep -qF "$BACKSTOP_BEGIN" "$HOOK_DST" 2>/dev/null; then
    echo "已就绪：兜底闸已在 $HOOK_DST（幂等）。"; return
  fi
  if [ ! -e "$HOOK_DST" ]; then
    { echo "#!/usr/bin/env bash"; echo "set -euo pipefail"; echo ""; make_backstop_block; } > "$HOOK_DST"
    chmod +x "$HOOK_DST"; echo "已安装兜底闸：$HOOK_DST（新建）"; return
  fi
  local first; first="$(head -n 1 "$HOOK_DST" 2>/dev/null || true)"
  if ! hook_is_shell "$first"; then
    echo "⚠ 既有 $HOOK_DST 非 shell，兜底闸未装，请手工调用 lint_whitelist_scope.sh。" >&2; return
  fi
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/spec-kit-bk.XXXXXX")"
  { head -n 1 "$HOOK_DST"; echo ""; make_backstop_block; echo ""; tail -n +2 "$HOOK_DST"; } > "$tmp" && mv "$tmp" "$HOOK_DST"
  chmod +x "$HOOK_DST"; echo "已插入兜底闸：$HOOK_DST"
}

# --- 执行 -----------------------------------------------------------------
echo "== spec-kit 安装 =="
echo "仓库根: $ROOT"
echo "kit 目录: $KIT_DIR"
echo ""

install_precommit
if [ "$WITH_CLAUDE"   -eq 1 ]; then install_claude;   fi
if [ "$WITH_GEMINI"   -eq 1 ]; then install_gemini;   fi
if [ "$WITH_CODEX"    -eq 1 ]; then install_codex;    fi
if [ "$WITH_KIRO"     -eq 1 ]; then install_kiro;     fi
if [ "$WITH_BACKSTOP" -eq 1 ]; then install_backstop; fi

# --- 收尾说明 -------------------------------------------------------------
echo ""
echo "------------------------------------------------------------------"
if [ "$PRECOMMIT_INSTALLED" -eq 1 ]; then
  echo "已安装："
  echo "  • pre-commit 闸 -> $HOOK_DST"
  echo "    提交 specs/**/*.md 时自动跑 死链/验收命令/RFC2119 三道 lint。"
else
  echo "⚠ 未安装 pre-commit 闸：既有 hook 非 shell，已停手（见上方提示）。请改走 CI 或手工接入。"
fi
if [ "$WITH_CLAUDE"   -eq 1 ]; then echo "  • Claude PreToolUse 白名单 hook  -> $ROOT/.claude/settings.json"; fi
if [ "$WITH_GEMINI"   -eq 1 ]; then echo "  • Gemini BeforeTool 白名单 hook  -> $ROOT/.gemini/settings.json"; fi
if [ "$WITH_CODEX"    -eq 1 ]; then echo "  • Codex PreToolUse 白名单 hook   -> $ROOT/.codex/config.toml（项目级，需信任）"; fi
if [ "$WITH_KIRO"     -eq 1 ]; then echo "  • Kiro preToolUse 白名单 hook    -> $ROOT/.kiro/agents/*.json"; fi
if [ "$WITH_BACKSTOP" -eq 1 ]; then echo "  • 通用兜底闸（暂存文件⊆白名单）  -> $HOOK_DST"; fi
cat <<EOF

怎么用：
  • 正常 git commit 即触发 spec lint；违规会被拒绝并打印 路径:行号。
  • 应急跳过一次：SKIP_SPEC_LINT=1 git commit ...
  • 白名单闸：在仓库根放 .spec-task-whitelist（每行一个允许改的路径 glob），
    Claude 写清单外文件时默认 deny 阻断并把原因反馈模型（让 AI 不跑偏）。无该文件则不启用。
    （只提示不阻断：把 hooks/claude-pretooluse-whitelist.sh 顶部 DECISION 改成 warn。）

怎么卸：
  • pre-commit：编辑 ${HOOK_DST}，删除 "$BEGIN_MARK" 到
    "$END_MARK" 之间的区块即可（若为本 kit 新建的 hook，可整文件删除）。
  • Claude hook：从 $ROOT/.claude/settings.json 的 hooks.PreToolUse 中移除对应项。
------------------------------------------------------------------
EOF
