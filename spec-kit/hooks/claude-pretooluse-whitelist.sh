#!/usr/bin/env bash
# spec-kit · Claude Code PreToolUse 白名单闸（薄适配器）
#
# 用途：Claude 写文件前(matcher: Edit|MultiEdit|Write|NotebookEdit)校验目标路径是否在
#       「当前任务可改文件」清单 .spec-task-whitelist 内；越界写默认 deny 并把原因反馈模型。
# 用法：注册为 Claude Code PreToolUse hook；从 stdin 读 hook 输入 JSON，向 stdout 输出决策 JSON。
# 退出码：恒为 0（决策由 JSON 表达）。
# 设计：判定逻辑全在同目录 whitelist_core.sh（与其它 agent 共用同一份 glob/归一化）；本适配器只
#       「取路径 → 调 core → 按 rc 翻成 Claude 决策」。deny/warn 是本适配器对 rc=10 的呈现策略，core 不感知。
# 实测：PreToolUse 的 systemMessage 只给用户看、模型不可见，warn 拦不住模型；故默认 deny
#       （reason/additionalContext 进模型上下文）。想只提示不阻断：把 DECISION 改成 "warn"。
# 注意：不使用 set -e —— 需显式按 core 退出码分支（命令替换里 core 退出 10 会被 set -e 误杀）。
set -u

DECISION="deny"   # deny=阻断越界写并把原因反馈模型（默认）；warn=仅提示、放行
CORE="$(cd "$(dirname "$0")" && pwd)/whitelist_core.sh"

emit_allow() { printf '{"continue": true}\n'; }
emit_deny()  { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s","additionalContext":"%s"}}\n' "$1" "$1"; }
emit_warn()  { printf '{"continue": true, "systemMessage": "%s", "hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$1" "$1"; }
emit_block() { if [ "$DECISION" = "deny" ]; then emit_deny "$1"; else emit_warn "$1"; fi; }

INPUT="$(cat || true)"
[ -z "$INPUT" ] && { emit_allow; exit 0; }   # 未触发/空输入 → 放行

# 取被写路径：Write/Edit/MultiEdit 用 file_path；NotebookEdit 用 notebook_path。
file_path=""
if command -v jq >/dev/null 2>&1; then
  file_path="$(printf '%s' "$INPUT" | jq -r '(.tool_input.file_path // .tool_input.notebook_path) // empty' 2>/dev/null || true)"
fi
if [ -z "$file_path" ]; then
  file_path="$(printf '%s' "$INPUT" | tr ',' '\n' | grep -E '"(file_path|notebook_path)"' | head -n 1 \
    | sed -E -e 's/.*"(file_path|notebook_path)"[[:space:]]*:[[:space:]]*"//' -e 's/".*//' 2>/dev/null || true)"
fi
# 非文件类工具 / 取不到路径 → 放行（Claude matcher 较宽，部分匹配工具本无路径）。
[ -z "$file_path" ] && { emit_allow; exit 0; }

# core 缺失 → 保守 deny（坏掉的闸宁可拦+提示，不静默放行）。
if [ ! -f "$CORE" ]; then
  emit_block "[spec-kit] 白名单核心 whitelist_core.sh 缺失，无法校验写入边界，已保守拦截。请检查 spec-kit 安装。"
  exit 0
fi

offenders="$(bash "$CORE" "$file_path" 2>/dev/null)"; rc=$?
case "$rc" in
  0)  emit_allow ;;
  10) bad="$(bash "$CORE" --json-escape "$offenders" 2>/dev/null)"
      emit_block "[spec-kit] 写入目标 '$bad' 不在 .spec-task-whitelist 内（也非 test/**/*_test.dart）。本任务理应只改清单内文件，请确认是否越界。" ;;
  *)  emit_block "[spec-kit] 白名单核心异常(rc=$rc)，已保守拦截。" ;;
esac
exit 0
