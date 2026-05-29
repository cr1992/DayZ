#!/usr/bin/env bash
# spec-kit · AWS Kiro preToolUse 白名单适配器（薄）
#
# 注册：枚举现有 .kiro/agents/*.json 的 hooks.preToolUse，matcher "fs_write"（字面，Kiro matcher 不支持正则）。
#       不要新建臆造名 agent json——Kiro hook 只在「该 agent 被激活时」生效，新建孤儿 = 静默失效。
# 协议：exit 0=放行；exit 2=阻断且 STDERR 原文回传模型（拒绝理由）。其它非零=warning+放行(fail-open)。
#   故所有异常一律 exit 2（fail-closed）。STDERR 第一行须自足（多行若被截断，关键信息保在首行）。
# 路径：fs_write 的 tool_input.operations[].path（官方未逐字给 fs_write schema，按 fs_read 推断 + 顶层 .path 兜底）。
set -u
CORE="$(cd "$(dirname "$0")" && pwd)/whitelist_core.sh"
block() { >&2 printf '%s\n' "$1"; exit 2; }

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0          # 空输入＝未触发 → 放行

command -v jq >/dev/null 2>&1 || block "[spec-kit] 未找到 jq，无法解析 fs_write 输入，已保守拦截（fail-closed）。请装 jq 或在白名单内作业。"
[ -f "$CORE" ] || block "[spec-kit] 白名单核心 whitelist_core.sh 缺失，已保守拦截。请检查 spec-kit 安装。"

paths_raw="$(printf '%s' "$INPUT" | jq -r '(.tool_input.operations[]?.path // empty),(.tool_input.path // empty)' 2>/dev/null)"; jqrc=$?
[ "$jqrc" -eq 0 ] || block "[spec-kit] 无法解析 fs_write 输入(JSON 异常)，已保守拦截。"
paths=(); while IFS= read -r p || [ -n "$p" ]; do [ -n "$p" ] && paths+=("$p"); done <<EOF
$paths_raw
EOF
[ "${#paths[@]}" -eq 0 ] && block "[spec-kit] 未能从 fs_write 提取被写路径(schema 可能漂移)，已保守拦截。"

offenders="$(bash "$CORE" "${paths[@]}" 2>/dev/null)"; rc=$?
case "$rc" in
  0)  exit 0 ;;
  10) first="$(printf '%s' "$offenders" | head -n 1)"
      block "[spec-kit] 写入越界：'$first' 不在 .spec-task-whitelist 内（test/**/*_test.dart 除外）。请将其加入白名单或停下与用户确认，勿绕路。" ;;
  *)  block "[spec-kit] 白名单核心异常(rc=$rc)，已保守拦截。" ;;
esac
