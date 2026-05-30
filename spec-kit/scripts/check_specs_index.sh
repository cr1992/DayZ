#!/usr/bin/env bash
# spec-kit · check_specs_index.sh
#
# 用途：检查 specs/README.md 与 active/archive/contracts 目录的一致性，防止手写索引漂移。
# 用法：check_specs_index.sh [SPECS_DIR]      （默认 ./specs，亦可用环境变量 SPECS_DIR 覆盖）
# 退出码：0=通过；1=发现违规（逐条打印 路径:行号: 说明 + 末尾计数）；2=用法/环境错误。
# 强制规范：README 是功能生命周期与跨 spec 依赖的唯一来源；执行顺序是派生快照，不能引用已归档项继续排队。
# 兼容：纯 bash + awk/sed/find/grep，macOS(BSD) 与 Linux 通用；不依赖 rg/python/readlink -f。
set -euo pipefail
export LC_ALL=C

SPECS_DIR="${1:-${SPECS_DIR:-./specs}}"
SPECS_DIR="${SPECS_DIR%/}"
[ -d "$SPECS_DIR" ] || { echo "用法错误：目录不存在: $SPECS_DIR" >&2; exit 2; }

README="$SPECS_DIR/README.md"
[ -f "$README" ] || { echo "用法错误：缺少 $README" >&2; exit 2; }

tmp="$(mktemp)"
active_rows="$(mktemp)"
archive_rows="$(mktemp)"
active_dirs="$(mktemp)"
archive_dirs="$(mktemp)"
archive_pairs="$(mktemp)"
contract_ids="$(mktemp)"
valid_ids="$(mktemp)"
active_table_ids="$(mktemp)"
archive_table_dirs="$(mktemp)"
archive_table_ids="$(mktemp)"
trap 'rm -f "$tmp" "$active_rows" "$archive_rows" "$active_dirs" "$archive_dirs" "$archive_pairs" "$contract_ids" "$valid_ids" "$active_table_ids" "$archive_table_dirs" "$archive_table_ids"' EXIT

relpath() {
  case "$1" in
    ./*) printf '%s\n' "${1#./}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

err() {
  # $1 path, $2 line, $3 message
  printf '%s:%s: %s\n' "$(relpath "$1")" "$2" "$3" >> "$tmp"
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s\n' "$s"
}

archive_stable_id() {
  printf '%s\n' "$1" | sed -E \
    -e 's/^cancelled-[0-9]{4}-[0-9]{2}-[0-9]{2}-//' \
    -e 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//'
}

contains_line() {
  # $1 needle, $2 file
  grep -Fxq "$1" "$2" 2>/dev/null
}

has_acceptance_review_row() {
  # $1 stable spec ID, $2 acceptance-review.md
  local pattern
  pattern="$(escape_ere "$1")"
  grep -Eq "^[[:space:]]*\|[[:space:]]*\`${pattern}\`[[:space:]]*\|" "$2" 2>/dev/null
}

archive_has_open_review_markers() {
  # $1 archive spec directory. Returns 0 if old/incomplete task evidence exists.
  local md
  while IFS= read -r md; do
    if awk '
      /^[[:space:]]*-[[:space:]]*\[[ -]\]/ { found = 1 }
      /待确认/ { found = 1 }
      /人工：[[:space:]]*—/ { found = 1 }
      /自动：[[:space:]]*—/ { found = 1 }
      END { exit found ? 0 : 1 }
    ' "$md"; then
      return 0
    fi
  done < <(find "$1" -type f -name '*.md')
  return 1
}

escape_ere() {
  printf '%s\n' "$1" | sed -E 's/[][(){}.^$*+?|\\/]/\\&/g'
}

normalize_dep_id() {
  local raw s base
  raw="$1"
  s="$(printf '%s\n' "$raw" | sed -E \
    -e 's/\[([^]]+)\]\([^)]+\)/\1/g' \
    -e 's/`//g' \
    -e 's/<[^>]*>//g' \
    -e 's/^[[:space:]]+//' \
    -e 's/[[:space:]]+$//' \
    -e 's/[^A-Za-z0-9_.\/-].*$//')"
  s="${s#./}"
  s="${s%/}"
  case "$s" in
    active/*)
      s="${s#active/}"
      s="${s%%/*}"
      ;;
    archive/*)
      base="${s#archive/}"
      base="${base%%/*}"
      s="$(archive_stable_id "$base")"
      ;;
    contracts/*)
      s="${s#contracts/}"
      s="${s%%/*}"
      ;;
  esac
  printf '%s\n' "$s"
}

extract_link_target() {
  printf '%s\n' "$1" | sed -nE 's/.*\[[^]]+\]\(([^)]+)\).*/\1/p'
}

extract_link_label() {
  printf '%s\n' "$1" | sed -nE 's/.*\[([^]]+)\]\([^)]+\).*/\1/p'
}

clean_target() {
  local target="$1"
  target="${target#<}"
  target="${target%>}"
  target="${target%% *}"
  target="${target%%#*}"
  target="${target%%\?*}"
  target="${target#./}"
  target="${target%/}"
  printf '%s\n' "$target"
}

extract_table_rows() {
  # $1 section title, $2 output file, $3 kind(active/archive)
  local section="$1" outfile="$2" kind="$3"
  awk -v section="$section" -v outfile="$outfile" -v kind="$kind" -v errfile="$tmp" -v readme="$(relpath "$README")" '
    function trim(s) {
      gsub(/^[[:space:]]+/, "", s)
      gsub(/[[:space:]]+$/, "", s)
      return s
    }
    function split_cells(row, arr,  n, i) {
      sub(/^[[:space:]]*\|/, "", row)
      sub(/\|[[:space:]]*$/, "", row)
      n = split(row, arr, /\|/)
      for (i = 1; i <= n; i++) arr[i] = trim(arr[i])
      return n
    }
    function is_separator(arr, n,  i) {
      for (i = 1; i <= n; i++) {
        if (arr[i] !~ /^:?-+:?$/) return 0
      }
      return 1
    }
    function report(msg) {
      printf "%s:%d: %s\n", readme, NR, msg >> errfile
    }
    BEGIN { insec = 0; header_seen = 0; rows = 0; feature_i = deps_i = status_i = result_i = 0 }
    /^##[[:space:]]+/ {
      if (insec && header_seen) exit
      insec = ($0 == "## " section)
      next
    }
    insec && /^[[:space:]]*\|/ {
      n = split_cells($0, c)
      if (!header_seen) {
        header_seen = 1
        for (i = 1; i <= n; i++) {
          if (c[i] == "功能") feature_i = i
          if (c[i] == "依赖") deps_i = i
          if (c[i] == "状态") status_i = i
          if (c[i] == "结果") result_i = i
        }
        if (!feature_i) report("`## " section "` 表缺少 `功能` 列")
        if (kind == "active" && !deps_i) report("`## " section "` 表缺少 `依赖` 列")
        if (kind == "active" && !status_i) report("`## " section "` 表缺少 `状态` 列")
        if (kind == "archive" && !result_i) report("`## " section "` 表缺少 `结果` 列")
        next
      }
      if (is_separator(c, n)) next
      rows++
      if (kind == "active") {
        printf "%d\t%s\t%s\t%s\n", NR, c[feature_i], c[deps_i], c[status_i] >> outfile
      } else {
        printf "%d\t%s\t%s\n", NR, c[feature_i], c[result_i] >> outfile
      }
      next
    }
    END {
      if (!header_seen) {
        printf "%s:1: 缺少 `## %s` 表格\n", readme, section >> errfile
      }
    }
  ' "$README"
}

# 冲突标记：只扫 specs 下 Markdown，避免把其它许可证分隔线误判。
while IFS= read -r md; do
  awk -v F="$(relpath "$md")" '/^(<<<<<<<|=======|>>>>>>>)($|[[:space:]])/ {
    printf "%s:%d: 残留 git 冲突标记\n", F, NR
  }' "$md" >> "$tmp"
done < <(find "$SPECS_DIR" -type f -name '*.md')

# README 二级标题不应重复；重复通常代表手工合并/剪贴漂移。
awk -v F="$(relpath "$README")" '
  /^##[[:space:]]+/ {
    h = $0
    sub(/[[:space:]]+$/, "", h)
    seen[h]++
    first[h] = first[h] ? first[h] : NR
    if (seen[h] == 2) {
      printf "%s:%d: 重复二级标题 `%s`（首次出现于第 %d 行）\n", F, NR, h, first[h]
    }
  }
' "$README" >> "$tmp"

# 收集目录真相。
if [ -d "$SPECS_DIR/active" ]; then
  while IFS= read -r d; do
    rest="${d#"$SPECS_DIR/active/"}"
    case "$rest" in */*) continue ;; esac
    [ -n "$rest" ] && printf '%s\n' "$rest" >> "$active_dirs"
  done < <(find "$SPECS_DIR/active" -type d ! -path "$SPECS_DIR/active")
fi
sort -u "$active_dirs" -o "$active_dirs"

if [ -d "$SPECS_DIR/archive" ]; then
  while IFS= read -r d; do
    rest="${d#"$SPECS_DIR/archive/"}"
    case "$rest" in */*) continue ;; esac
    [ -n "$rest" ] || continue
    printf '%s\n' "$rest" >> "$archive_dirs"
    printf '%s\t%s\n' "$(archive_stable_id "$rest")" "$rest" >> "$archive_pairs"
  done < <(find "$SPECS_DIR/archive" -type d ! -path "$SPECS_DIR/archive")
fi
sort -u "$archive_dirs" -o "$archive_dirs"
sort -u "$archive_pairs" -o "$archive_pairs"

if [ -d "$SPECS_DIR/contracts" ]; then
  while IFS= read -r d; do
    rest="${d#"$SPECS_DIR/contracts/"}"
    case "$rest" in */*) continue ;; esac
    [ -n "$rest" ] && printf '%s\n' "$rest" >> "$contract_ids"
  done < <(find "$SPECS_DIR/contracts" -type d ! -path "$SPECS_DIR/contracts")
fi
sort -u "$contract_ids" -o "$contract_ids"

{
  cat "$active_dirs"
  cut -f1 "$archive_pairs" 2>/dev/null || true
  cat "$contract_ids"
} | sed '/^$/d' | sort -u > "$valid_ids"

extract_table_rows "进行中" "$active_rows" "active"
extract_table_rows "已归档" "$archive_rows" "archive"

TAB="$(printf '\t')"

# 校验 active 表。
while IFS="$TAB" read -r line feature deps status; do
  [ -n "${line:-}" ] || continue
  target="$(clean_target "$(extract_link_target "$feature")")"
  label="$(extract_link_label "$feature")"
  if [ -z "$target" ] || [ -z "$label" ]; then
    err "$README" "$line" "进行中表的功能列必须是 Markdown 链接 '[spec-id](active/spec-id/)'"
    continue
  fi
  case "$target" in
    active/*)
      id="${target#active/}"
      id="${id%%/*}"
      ;;
    *)
      err "$README" "$line" "进行中表链接必须指向 active/<spec-id>/，当前为 '$target'"
      continue
      ;;
  esac
  printf '%s\n' "$id" >> "$active_table_ids"
  [ "$label" = "$id" ] || err "$README" "$line" "功能链接文字 '$label' 应等于 spec ID '$id'"
  [ -d "$SPECS_DIR/active/$id" ] || err "$README" "$line" "进行中表引用 '$id'，但目录 active/$id/ 不存在"
  status_trimmed="$(trim "$status")"
  case "$status_trimmed" in
    已完成*|已废弃*|已取消*)
      err "$README" "$line" "进行中表不应保留终态状态 '$status_trimmed'；终态 spec 应移入已归档表"
      ;;
  esac

  deps_clean="$(printf '%s\n' "$deps" | sed -E 's/<br[[:space:]]*\/?>/,/g; s/[，、;；]/,/g')"
  IFS=',' read -r -a dep_items <<< "$deps_clean"
  for dep_raw in "${dep_items[@]}"; do
    dep="$(normalize_dep_id "$dep_raw")"
    case "$dep" in
      ""|"无"|"-"|"—"|"N/A"|"n/a") continue ;;
    esac
    if [ "$dep" = "$id" ]; then
      err "$README" "$line" "依赖列包含自身 '$dep'"
    elif ! contains_line "$dep" "$valid_ids"; then
      err "$README" "$line" "依赖 '$dep' 无法解析为 active/archive/contracts 中的有效 spec ID"
    fi
  done
done < "$active_rows"
sort -u "$active_table_ids" -o "$active_table_ids"

# 校验 archive 表。
while IFS="$TAB" read -r line feature result; do
  [ -n "${line:-}" ] || continue
  target="$(clean_target "$(extract_link_target "$feature")")"
  label="$(extract_link_label "$feature")"
  if [ -z "$target" ] || [ -z "$label" ]; then
    err "$README" "$line" "已归档表的功能列必须是 Markdown 链接 '[spec-id](archive/YYYY-MM-DD-spec-id/)'"
    continue
  fi
  case "$target" in
    archive/*)
      archive_dir="${target#archive/}"
      archive_dir="${archive_dir%%/*}"
      ;;
    *)
      err "$README" "$line" "已归档表链接必须指向 archive/<date-spec-id>/，当前为 '$target'"
      continue
      ;;
  esac
  stable="$(archive_stable_id "$archive_dir")"
  printf '%s\n' "$archive_dir" >> "$archive_table_dirs"
  printf '%s\n' "$stable" >> "$archive_table_ids"
  [ "$label" = "$stable" ] || err "$README" "$line" "归档链接文字 '$label' 应等于稳定 spec ID '$stable'"
  [ -d "$SPECS_DIR/archive/$archive_dir" ] || err "$README" "$line" "已归档表引用 '$archive_dir'，但目录 archive/$archive_dir/ 不存在"
  [ -n "$(trim "$result")" ] || err "$README" "$line" "已归档表结果列不能为空"
done < "$archive_rows"
sort -u "$archive_table_dirs" -o "$archive_table_dirs"
sort -u "$archive_table_ids" -o "$archive_table_ids"

# 表与目录双向一致。
while IFS= read -r id; do
  [ -n "$id" ] || continue
  contains_line "$id" "$active_table_ids" || err "$README" 1 "目录 active/$id/ 存在，但未登记在 '## 进行中' 表"
done < "$active_dirs"

while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  contains_line "$dir" "$archive_table_dirs" || err "$README" 1 "目录 archive/$dir/ 存在，但未登记在 '## 已归档' 表"
done < "$archive_dirs"

while IFS= read -r id; do
  [ -n "$id" ] || continue
  if contains_line "$id" "$archive_table_ids"; then
    err "$README" 1 "spec ID '$id' 同时出现在进行中与已归档表；稳定 ID 必须唯一"
  fi
done < "$active_table_ids"

sort "$active_table_ids" | uniq -d | while IFS= read -r dup; do
  [ -n "$dup" ] && err "$README" 1 "进行中表重复登记 spec ID '$dup'"
done
sort "$archive_table_ids" | uniq -d | while IFS= read -r dup; do
  [ -n "$dup" ] && err "$README" 1 "已归档表重复登记 spec ID '$dup'"
done

# 归档复验台账：防止「已归档但未 review」。
ACCEPTANCE_REVIEW="$SPECS_DIR/archive/acceptance-review.md"
while IFS="$TAB" read -r stable archive_dir; do
  [ -n "$stable" ] || continue
  if [ -f "$ACCEPTANCE_REVIEW" ]; then
    if ! has_acceptance_review_row "$stable" "$ACCEPTANCE_REVIEW"; then
      err "$ACCEPTANCE_REVIEW" 1 "归档复验台账缺少 spec '$stable' 的结论表行；已归档 spec 必须被 review 收口"
    fi
  elif archive_has_open_review_markers "$SPECS_DIR/archive/$archive_dir"; then
    err "$README" 1 "archive/$archive_dir/ 残留未完成/待确认验收痕迹，但缺少 archive/acceptance-review.md 台账收口"
  fi
done < "$archive_pairs"

# 执行顺序是派生快照：编号步骤里不应再排已归档 spec。
awk '
  /^##[[:space:]]*执行顺序/ { insec = 1; next }
  /^##[[:space:]]+/ { if (insec) exit }
  insec && /^[[:space:]]*[0-9]+[.)]/ { print NR "\t" $0 }
' "$README" | while IFS="$TAB" read -r line text; do
  [ -n "${line:-}" ] || continue
  while IFS="$(printf '\t')" read -r stable archive_dir; do
    [ -n "$stable" ] || continue
    pattern="$(escape_ere "$stable")"
    if printf '%s\n' "$text" | grep -Eq "(^|[^A-Za-z0-9_-])${pattern}([^A-Za-z0-9_-]|$)"; then
      err "$README" "$line" "执行顺序编号步骤引用已归档 spec '$stable'（archive/$archive_dir/）；派生快照已过期"
    fi
  done < "$archive_pairs"
done

if [ -s "$tmp" ]; then
  cat "$tmp"
  printf '违规计数: %s\n' "$(wc -l < "$tmp" | tr -d ' ')"
  exit 1
fi

exit 0
