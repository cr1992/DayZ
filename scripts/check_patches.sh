#!/usr/bin/env bash
#
# check_patches.sh · DayZ vendored 第三方包改动留痕对账
#
# 作者：@Ray
# 关联 spec：specs/active/appflowy-patch-tracking/
#
# 校验三件事：
#   1) 代码内 DAYZ-PATCH 标记成对：每个 `>>> DAYZ-PATCH[Pxxx]` 必有对应的
#      `<<< DAYZ-PATCH[Pxxx]`，且按 ID 统计开/闭数量一致。
#   2) 代码里出现的每个 patch ID 必须在 packages/CHANGELOG.md 有记录；
#      否则视为「漏记」→ 报错并 exit 1。
#   3) CHANGELOG 记录了但代码里找不到标记的 patch ID → 告警（不算错）。
#      含义：该 patch 已被上游升级冲掉需重贴，或已合并入上游可废弃。exit 0。
#
# 退出码：
#   0  对账通过（可能含告警）
#   1  发现成对错误或漏记
#
set -uo pipefail

# 定位仓库根目录（脚本位于 <root>/scripts/）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 扫描范围与对账对象
SCAN_DIR="$ROOT_DIR/packages/appflowy-editor/lib"
CHANGELOG="$ROOT_DIR/packages/CHANGELOG.md"

PATCH_RE='DAYZ-PATCH\[P[0-9]+\]'

err=0

if [[ ! -d "$SCAN_DIR" ]]; then
  echo "ERROR: 扫描目录不存在: $SCAN_DIR" >&2
  exit 1
fi
if [[ ! -f "$CHANGELOG" ]]; then
  echo "ERROR: CHANGELOG 不存在: $CHANGELOG" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1) 成对校验：逐文件、按出现顺序压栈，并统计每个 ID 的开/闭数量
# ---------------------------------------------------------------------------
echo "== [1/3] 校验 DAYZ-PATCH 标记成对 =="

# 收集所有标记行：file:lineno:OPEN|CLOSE:ID
marker_lines="$(grep -rnoE "(>>>|<<<) ${PATCH_RE}" "$SCAN_DIR" 2>/dev/null || true)"

if [[ -n "$marker_lines" ]]; then
  # 逐文件做括号匹配（栈），保证 >>> 与 <<< 同 ID 且嵌套正确
  files="$(printf '%s\n' "$marker_lines" | sed -E 's/^([^:]+):.*/\1/' | sort -u)"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    stack=()
    while IFS= read -r line; do
      kind=""
      id="$(printf '%s' "$line" | grep -oE 'P[0-9]+' | head -1)"
      if printf '%s' "$line" | grep -q '>>>'; then
        kind="OPEN"
      elif printf '%s' "$line" | grep -q '<<<'; then
        kind="CLOSE"
      fi
      # grep -n 输出为 `LINENO:content`，取前导行号
      lineno="${line%%:*}"
      if [[ "$kind" == "OPEN" ]]; then
        stack+=("$id:$lineno")
      elif [[ "$kind" == "CLOSE" ]]; then
        if [[ ${#stack[@]} -eq 0 ]]; then
          echo "  ERROR: $f:$lineno 出现 <<< [$id] 但没有未闭合的 >>>" >&2
          err=1
        else
          top="${stack[${#stack[@]}-1]}"
          top_id="${top%%:*}"
          top_ln="${top##*:}"
          unset 'stack[${#stack[@]}-1]'
          if [[ "$top_id" != "$id" ]]; then
            echo "  ERROR: $f:$lineno 闭合 [$id] 与最近的开标记 [$top_id]($f:$top_ln) ID 不一致" >&2
            err=1
          fi
        fi
      fi
    done < <(grep -nE "(>>>|<<<) ${PATCH_RE}" "$f")
    if [[ ${#stack[@]} -ne 0 ]]; then
      for rem in "${stack[@]}"; do
        echo "  ERROR: $f:${rem##*:} 的 >>> [${rem%%:*}] 没有对应的 <<<" >&2
        err=1
      done
    fi
  done <<< "$files"
fi

if [[ $err -eq 0 ]]; then
  echo "  OK: 所有标记成对闭合"
fi

# ---------------------------------------------------------------------------
# 收集 ID 集合
# ---------------------------------------------------------------------------
# 代码中出现的 patch ID（去重）
code_ids="$(grep -rohE "$PATCH_RE" "$SCAN_DIR" 2>/dev/null \
  | grep -oE 'P[0-9]+' | sort -u || true)"

# CHANGELOG 中登记的 patch ID（去重）。约定写法：`Patch: Pxxx` 或行内出现 [Pxxx]/Pxxx
changelog_ids="$(grep -oE 'P[0-9]+' "$CHANGELOG" 2>/dev/null | sort -u || true)"

# ---------------------------------------------------------------------------
# 2) 代码每个 ID 必在 CHANGELOG，否则漏记 → exit 1
# ---------------------------------------------------------------------------
echo "== [2/3] 校验代码 patch 均已记入 CHANGELOG =="
missing=0
if [[ -n "$code_ids" ]]; then
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    if ! printf '%s\n' "$changelog_ids" | grep -qx "$id"; then
      echo "  ERROR: 代码存在标记 [$id] 但 packages/CHANGELOG.md 无记录（漏记）" >&2
      missing=1
      err=1
    fi
  done <<< "$code_ids"
fi
if [[ $missing -eq 0 ]]; then
  echo "  OK: 代码中的 patch 均已登记"
fi

# ---------------------------------------------------------------------------
# 3) CHANGELOG 有但代码无标记 → 告警（exit 0）
# ---------------------------------------------------------------------------
echo "== [3/3] 检查 CHANGELOG 记录是否仍有对应代码标记 =="
warned=0
if [[ -n "$changelog_ids" ]]; then
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    if ! printf '%s\n' "$code_ids" | grep -qx "$id"; then
      echo "  WARN: CHANGELOG 记录 [$id] 在代码中找不到标记" >&2
      echo "        → 可能被上游升级冲掉（需按 design.md SOP 重贴）或已合并上游可废弃。" >&2
      warned=1
    fi
  done <<< "$changelog_ids"
fi
if [[ $warned -eq 0 ]]; then
  echo "  OK: 每条 CHANGELOG 记录都有对应代码标记"
fi

echo "----------------------------------------"
if [[ $err -ne 0 ]]; then
  echo "对账失败：存在成对错误或漏记。" >&2
  exit 1
fi
echo "对账通过。"
exit 0
