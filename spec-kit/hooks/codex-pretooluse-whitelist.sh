#!/usr/bin/env bash
# spec-kit · OpenAI Codex CLI PreToolUse 白名单适配器（薄）
#
# 注册：项目级 .codex/config.toml 的 [[hooks.PreToolUse]]，matcher "^(apply_patch|Edit|Write|MultiEdit)$"。
# allow = exit 0 且 stdout 空（Codex 不识别 {"continue":true}）。
# deny  = exit 0 + {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":..}}（reason 回传模型）。
#
# ★ 致命陷阱：Codex「非 2 的非零退出 = hook 失败但放行(fail-OPEN)」。故：
#   ① 不用 set -e / pipefail；② 每种异常都翻成显式 deny；③ JSON 转义只用 sed/tr 不用 awk；
#   ④ 本脚本须为纯净 UTF-8（控制字节会让 bash 报错非零退出 → fail-OPEN）。
# 路径不在独立字段：apply_patch 的 tool_input.command 是字符串，路径埋在
#   "*** Add/Update/Delete File: <p>" / "*** Move to: <p>" 头行（相对 cwd，可多文件）。
set -u
CORE="$(cd "$(dirname "$0")" && pwd)/whitelist_core.sh"
deny()  { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"; exit 0; }
allow() { exit 0; }

INPUT="$(cat || true)"
[ -z "$INPUT" ] && allow

command -v jq >/dev/null 2>&1 || deny "[spec-kit] 未找到 jq，无法解析 Codex 写入输入，已保守拦截（fail-closed）。"

extract() {
  cmd="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
  # apply_patch 信封头行（一次可多文件；Move to 是重命名目的地，必纳入）
  printf '%s\n' "$cmd" \
    | grep -E '^\*\*\* (Add|Update|Delete) File:|^\*\*\* Move to:' \
    | sed -E 's/^\*\*\* (Add File|Update File|Delete File|Move to):[[:space:]]*//' \
    | sed -E 's/[[:space:]]+$//' | grep -v '^$'
  # 防御性：Edit/Write 变体可能给独立字段
  printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null
}
paths=(); while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && paths+=("$p"); done <<EOF
$(extract)
EOF

# 写工具触发但解析不到路径＝不可信 → fail-closed deny（绝不靠裸退出隐式放行）。
[ "${#paths[@]}" -eq 0 ] && deny "[spec-kit] 无法从写工具(apply_patch/Edit/Write)解析出目标路径，已保守拦截（fail-closed）。"
[ -f "$CORE" ] || deny "[spec-kit] 白名单核心 whitelist_core.sh 缺失，已保守拦截。"

offenders="$(bash "$CORE" "${paths[@]}" 2>/dev/null)"; rc=$?
case "$rc" in
  0)  allow ;;
  10) first="$(printf '%s' "$offenders" | head -n 1)"
      bad="$(bash "$CORE" --json-escape "$first" 2>/dev/null)"
      deny "[spec-kit] 写入目标 '$bad' 不在 .spec-task-whitelist 内（也非 test/**/*_test.dart）。本任务理应只改清单内文件，请确认是否越界。" ;;
  *)  deny "[spec-kit] 白名单核心异常(rc=$rc)，已保守拦截。" ;;
esac
