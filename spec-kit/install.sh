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
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"           # .../spec-kit
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

GIT_DIR="$(git rev-parse --git-dir 2>/dev/null)"
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
    echo "已安装：${HOOK_DST}（新建）"
    return
  fi

  # 已存在 hook：检查是否已含 spec-kit 区块（幂等）
  if grep -q "$BEGIN_MARK" "$HOOK_DST" 2>/dev/null; then
    echo "已就绪：$HOOK_DST 已含 spec-kit 区块，跳过（幂等）。"
    return
  fi

  # 用户已有自定义 hook：备份 + 追加调用块，绝不覆盖
  backup="$HOOK_DST.bak.$(date +%Y%m%d%H%M%S)"
  cp "$HOOK_DST" "$backup"
  {
    echo ""
    make_block
  } >> "$HOOK_DST"
  chmod +x "$HOOK_DST"
  echo "已追加：${HOOK_DST}（保留你原有 hook；备份在 ${backup}）"
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
        "matcher": "Write|Edit",
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

  # 幂等：已存在同 command 的 Write|Edit PreToolUse hook 则不重复加
  if jq -e --arg c "$cmd" '
        (.hooks.PreToolUse // [])
        | any(.[]?; (.matcher == "Write|Edit")
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
        "matcher": "Write|Edit",
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
cat <<EOF

------------------------------------------------------------------
已安装：
  • pre-commit 闸 -> $HOOK_DST
    提交 specs/**/*.md 时自动跑 死链/验收命令/RFC2119 三道 lint。
EOF
if [ "$WITH_CLAUDE" -eq 1 ]; then
  echo "  • Claude PreToolUse 白名单 hook -> $ROOT/.claude/settings.json"
fi
cat <<EOF

怎么用：
  • 正常 git commit 即触发 spec lint；违规会被拒绝并打印 路径:行号。
  • 应急跳过一次：SKIP_SPEC_LINT=1 git commit ...
  • 白名单闸：在仓库根放 .spec-task-whitelist（每行一个允许改的路径 glob），
    Claude 写清单外文件时会提示（试点默认 warn 不阻断）。无该文件则不启用。

怎么卸：
  • pre-commit：编辑 ${HOOK_DST}，删除 "$BEGIN_MARK" 到
    "$END_MARK" 之间的区块即可（若为本 kit 新建的 hook，可整文件删除）。
  • Claude hook：从 $ROOT/.claude/settings.json 的 hooks.PreToolUse 中移除对应项。
------------------------------------------------------------------
EOF
