#!/usr/bin/env bash
set -euo pipefail
#
# spec-kit · Claude Code PreToolUse 白名单闸
#
# 用途：在 Claude Code 写文件前(匹配 Write|Edit)校验目标路径是否在「当前任务可改文件」
#       清单内。spec 把"本任务只准改这些文件"写进 .spec-task-whitelist，本钩子据此提醒
#       越界写入——防止 LLM 顺手改了不该动的代码却无人察觉。
# 用法：注册为 Claude Code PreToolUse hook(matcher: "Write|Edit")。
#       从 stdin 读 hook 输入 JSON，向 stdout 输出 hook 决策 JSON。
#       白名单文件：<repo根>/.spec-task-whitelist，每行一个允许的路径 glob，'#' 开头为注释。
# 退出码：恒为 0（决策通过 JSON 的 decision 字段表达，非退出码）。
# 强制规范：spec「本任务可改文件」边界（防越界写）。**试点默认 warn，不阻断**。
# 启发式/降级：file_path 优先用 jq 解析；无 jq 时用 grep/sed 提取，足够覆盖 Claude 的输入形态。
# 改成强阻断：把下方 DECISION 变量从 "warn" 改成 "deny" 即可（届时越界写将被拒绝）。

DECISION="warn"   # warn=仅提示放行；deny=阻断（试点阶段默认 warn）

# --- 读取 hook 输入 -------------------------------------------------------
INPUT="$(cat || true)"

# 未启用：拿不到输入则静默放行
if [ -z "$INPUT" ]; then
  printf '{"continue": true}\n'
  exit 0
fi

# --- 提取 tool_input.file_path -------------------------------------------
file_path=""
if command -v jq >/dev/null 2>&1; then
  file_path="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
fi
if [ -z "$file_path" ]; then
  # 降级：从 "file_path"："..." 里抠值（容忍空格；取首个匹配）。
  # 仅处理无转义引号的常规路径，足够 Claude Code 的实际输入。
  # grep 无命中会退出 1，叠加 pipefail/set -e 会误杀脚本 → 整体 || true 兜底。
  file_path="$(printf '%s' "$INPUT" \
    | tr ',' '\n' \
    | grep '"file_path"' \
    | head -n 1 \
    | sed -e 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' -e 's/".*//' || true)"
fi

# 没有 file_path（非文件类工具或解析失败）→ 放行
if [ -z "$file_path" ]; then
  printf '{"continue": true}\n'
  exit 0
fi

# --- 定位仓库根与白名单 ---------------------------------------------------
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WHITELIST="$ROOT/.spec-task-whitelist"

# 未启用：无白名单文件 → 直接放行（功能默认关闭，零打扰）
if [ ! -f "$WHITELIST" ]; then
  printf '{"continue": true}\n'
  exit 0
fi

# 物理根（解开 symlink，如 macOS /tmp -> /private/tmp），兼容两种绝对路径形态
ROOT_P="$(cd "$ROOT" 2>/dev/null && pwd -P || printf '%s' "$ROOT")"

# --- 把 file_path 归一成"相对仓库根"形式，便于 glob 匹配 ------------------
rel="$file_path"
case "$rel" in
  "$ROOT"/*)   rel="${rel#"$ROOT"/}" ;;    # 绝对路径在 repo 内 → 去掉根前缀
  "$ROOT_P"/*) rel="${rel#"$ROOT_P"/}" ;;  # 物理根前缀（symlink 解开后）
  ./*)         rel="${rel#./}" ;;          # ./foo → foo
  /*)
    # 绝对路径但前缀不直接匹配（如 macOS /tmp 与 /private/tmp 不一致）：
    # 把所在目录物理化后再剥根。目录不存在则保持原样（视作 repo 外）。
    d="$(dirname "$file_path")"
    b="$(basename "$file_path")"
    if dp="$(cd "$d" 2>/dev/null && pwd -P)"; then
      cand="$dp/$b"
      case "$cand" in
        "$ROOT_P"/*) rel="${cand#"$ROOT_P"/}" ;;
        "$ROOT"/*)   rel="${cand#"$ROOT"/}" ;;
      esac
    fi
    ;;
esac

# --- glob 匹配 ------------------------------------------------------------
# 约定：白名单一行一个 glob，相对仓库根；'**' 表示任意层级目录（含 0 层）。
# 实现：在 shell 的 case glob 里 '*' 本就匹配 '/'，故把 '**' 统一当作"任意字符"。
#   - 含 '/**/'(目录递归段) 的模式，分别尝试展开成 '/' 与 '/*/'，覆盖"0 层目录"与"≥1 层"。
#   - 其余 '**' 直接退化成 '*'。
#   - case 模式必须**不加引号**才能让 '*'/'?' 生效（bash 3.2 兼容）。
glob_match() {
  pattern="$1"; target="$2"

  case "$pattern" in
    *'/**/'*)
      # a/**/b -> 同时试 a/b（0 层）与 a/*/b（≥1 层，*跨 / 等价递归）
      head="${pattern%%'/**/'*}"
      tail="${pattern#*'/**/'}"
      glob_match "$head/$tail" "$target" && return 0
      glob_match "$head/*/$tail" "$target" && return 0
      return 1
      ;;
    *'**'*)
      # 其余位置的 '**' 退化成单个 '*'
      one="${pattern%%'**'*}*${pattern#*'**'}"
      glob_match "$one" "$target" && return 0
      return 1
      ;;
    *)
      case "$target" in
        $pattern) return 0 ;;
        *)        return 1 ;;
      esac
      ;;
  esac
}

allowed=0

# 1) 自动放行：测试文件 test/**/*_test.dart
if glob_match "test/**/*_test.dart" "$rel"; then
  allowed=1
fi

# 2) 白名单逐行匹配
if [ "$allowed" -eq 0 ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # 去首尾空白
    pat="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$pat" ] && continue
    case "$pat" in '#'*) continue ;; esac   # 注释行
    if glob_match "$pat" "$rel"; then
      allowed=1
      break
    fi
  done < "$WHITELIST"
fi

# --- 输出决策 -------------------------------------------------------------
if [ "$allowed" -eq 1 ]; then
  printf '{"continue": true}\n'
  exit 0
fi

# 命中白名单之外。先把路径转义成 JSON 安全（反斜杠、双引号），文本里用单引号包路径。
rel_json="$(printf '%s' "$rel" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
reason="[spec-kit] 写入目标 '$rel_json' 不在 .spec-task-whitelist 内（也非 test/**/*_test.dart）。本任务理应只改清单内文件，请确认是否越界。"

if [ "$DECISION" = "deny" ]; then
  # 强阻断：PreToolUse permissionDecision=deny
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
else
  # 试点默认：仅提示放行（不阻断）
  printf '{"continue": true, "systemMessage": "%s"}\n' "$reason"
fi
exit 0
