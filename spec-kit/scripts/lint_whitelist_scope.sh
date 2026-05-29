#!/usr/bin/env bash
# spec-kit · lint_whitelist_scope.sh —— 通用 git 兜底闸（与 agent 无关，D7）。
#
# 用途：提交时校验【暂存的源码文件】是否都 ⊆ .spec-task-whitelist（test/**/*_test.dart 豁免）。
#       补所有写时 hook 的共同盲区：① 经 shell 重定向写（echo > x / sed -i）绕过写工具 matcher；
#       ② Codex hook 崩溃 fail-open；③ 将来没有写时 hook 的 agent。不认 agent、只认 git。
# 用法：作为 pre-commit 的一段调用，或手动 `bash spec-kit/scripts/lint_whitelist_scope.sh`。
# 退出码：0=全部在白名单内 / 无白名单（功能关闭）/ 无暂存改动；1=有越界（逐条打印 + 计数）。
# 范围：「源码」= 所有暂存的新增/改动/复制文件，**不按扩展名预筛**（白名单已声明可改文件全集，
#       预筛只会漏放 pubspec.lock / Podfile 这类无扩展名却常被越界改的文件）；test/**/*_test.dart 豁免。
# 设计：判定复用同仓 hooks/whitelist_core.sh 的 wl_is_allowed（同一份 glob，杜绝双源真理）。
set -u

if [ "${SKIP_SPEC_LINT:-0}" = "1" ]; then exit 0; fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WL="$ROOT/.spec-task-whitelist"
[ -f "$WL" ] || exit 0          # 无白名单 → 功能关闭

DIR="$(cd "$(dirname "$0")" && pwd)"
CORE="$DIR/../hooks/whitelist_core.sh"
if [ ! -f "$CORE" ]; then
  echo "[spec-kit] 兜底闸：缺 hooks/whitelist_core.sh，跳过（请检查安装）。" >&2
  exit 0
fi
# shellcheck disable=SC1090
. "$CORE"                       # source 复用 wl_glob_match / wl_is_allowed（不触发 core 的 main）

cd "$ROOT" || exit 0
staged="$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)"
[ -n "$staged" ] || exit 0

bad=""; n=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in .spec-task-whitelist) continue ;; esac   # 闸的控制文件本身：提交豁免
  if wl_is_allowed "$f" "$WL"; then :; else bad="$bad  - $f"$'\n'; n=$((n+1)); fi
done <<EOF
$staged
EOF

if [ "$n" -gt 0 ]; then
  echo "[spec-kit] 兜底闸：以下暂存文件不在 .spec-task-whitelist 内（test/**/*_test.dart 除外）：" >&2
  printf '%s' "$bad" >&2
  echo "[spec-kit] 越界计数: ${n}。请把它们加入白名单、或确认是否越界。应急跳过：SKIP_SPEC_LINT=1 git commit ..." >&2
  exit 1
fi
exit 0
