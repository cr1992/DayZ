#!/usr/bin/env bash
# spec-kit · Gemini CLI BeforeTool 白名单适配器（薄）
#
# 注册：.gemini/settings.json 的 hooks.BeforeTool，matcher "^(write_file|replace)$"。
# allow = exit 0 且 stdout 空（Gemini 的 continue:true 语义是「不终止 agent loop」、非「放行此工具」，故不用它）。
# deny  = exit 0 + {"decision":"deny","reason":..,"systemMessage":..}（reason 回传模型、systemMessage 给用户）。
# 判定全在同目录 whitelist_core.sh。Gemini「其它非零退出=warning+继续」≈ fail-open，故异常一律显式 deny。
set -u
CORE="$(cd "$(dirname "$0")" && pwd)/whitelist_core.sh"
deny()  { printf '{"decision":"deny","reason":"%s","systemMessage":"%s"}\n' "$1" "$1"; exit 0; }
allow() { exit 0; }   # stdout 空

INPUT="$(cat || true)"
[ -z "$INPUT" ] && allow            # 空输入＝hook 未真正触发 → 放行

extract() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r '[.tool_input.file_path,.tool_input.path,.tool_input.absolute_path]|map(select(.!=null))|.[]' 2>/dev/null
  else
    printf '%s' "$INPUT" | tr ',' '\n' | grep -E '"(file_path|path|absolute_path)"' \
      | sed -E -e 's/.*"(file_path|path|absolute_path)"[[:space:]]*:[[:space:]]*"//' -e 's/".*//'
  fi
}
paths=(); while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && paths+=("$p"); done <<EOF
$(extract)
EOF

# matcher 已锚 write_file|replace：hook 触发即写工具。取不到路径＝schema 漂移/解析 bug → fail-closed。
[ "${#paths[@]}" -eq 0 ] && deny "[spec-kit] 无法从写工具输入解析出目标路径（schema 可能漂移），已保守拦截。请确认 spec-kit 版本与 Gemini 工具输入格式。"
[ -f "$CORE" ] || deny "[spec-kit] 白名单核心 whitelist_core.sh 缺失，无法校验，已保守拦截。请检查 spec-kit 安装。"

offenders="$(bash "$CORE" "${paths[@]}" 2>/dev/null)"; rc=$?
case "$rc" in
  0)  allow ;;
  10) first="$(printf '%s' "$offenders" | head -n 1)"
      bad="$(bash "$CORE" --json-escape "$first" 2>/dev/null)"
      deny "[spec-kit] 写入目标 '$bad' 不在 .spec-task-whitelist 内（也非 test/**/*_test.dart）。本任务理应只改清单内文件，请确认是否越界。" ;;
  *)  deny "[spec-kit] 白名单核心异常(rc=$rc)，已保守拦截。" ;;
esac
