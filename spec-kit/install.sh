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

WITH_CLAUDE=0
for arg in "$@"; do
  case "$arg" in
    --with-claude) WITH_CLAUDE=1 ;;
    -h|--help)
      echo "用法: bash spec-kit/install.sh [--with-claude]"
      echo "  --with-claude  额外注册 Claude Code PreToolUse 白名单 hook"
      exit 0
      ;;
    *)
      echo "未知参数: $arg" >&2
      echo "用法: bash spec-kit/install.sh [--with-claude]" >&2
      exit 2
      ;;
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

# --- 执行 -----------------------------------------------------------------
echo "== spec-kit 安装 =="
echo "仓库根: $ROOT"
echo "kit 目录: $KIT_DIR"
echo ""

install_precommit
if [ "$WITH_CLAUDE" -eq 1 ]; then
  install_claude
fi

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
if [ "$WITH_CLAUDE" -eq 1 ]; then
  echo "  • Claude PreToolUse 白名单 hook -> $ROOT/.claude/settings.json"
fi
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
