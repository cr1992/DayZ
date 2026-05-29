#!/usr/bin/env bash
# spec-kit · whitelist_core.sh —— 与 agent 无关的「写白名单」判定核心 + 工具。
#
# 它把「定位仓库根 / 路径归一化（含相对路径按 cwd 锚定、新建文件祖先物理化）/ glob 匹配 /
# test 自动放行 / 无白名单则全放行」收成单一真相；各 agent 适配器只翻译自家 I/O 后调它，
# 不再各写一套 glob（避免双源真理）。
#
# 用法（CLI）:
#   whitelist_core.sh <path> [<path> ...]   判定多个「agent 原样路径」
#       退出码 0=全部允许；10=至少一个越界（把【全部越界的相对仓库根路径】逐行打到 stdout）；
#               2=用法/环境错误（仅指「未给路径参数」；错误信息走 stderr）。
#       ★ 锁定：仓库根无 .spec-task-whitelist ⇒ rc=0 全允许（功能未启用＝零打扰），**绝不**用 rc=2 表达「未启用」。
#   whitelist_core.sh --json-escape <str>   打印 JSON 安全转义后的 str（反斜杠/双引号/控制字符）
#   whitelist_core.sh --selftest            对称回归自检；rc=0 通过 / rc=1 失败
#
# 也可 `source` 本文件复用函数（如 git 兜底闸）：wl_glob_match / wl_json_escape / wl_rel / wl_is_allowed。
# 兼容：纯 bash 3.2 + POSIX 工具（git/sed/tr/dirname/basename），macOS(BSD)/Linux 通用。
set -u

# ---- glob 匹配（'**' = 任意层级目录，含 0 层；bash 3.2 case glob，'*' 本就跨 '/'）----
wl_glob_match() {
  pattern="$1"; target="$2"
  case "$pattern" in
    *'/**/'*)
      head="${pattern%%'/**/'*}"; tail="${pattern#*'/**/'}"
      wl_glob_match "$head/$tail" "$target" && return 0      # 0 层
      wl_glob_match "$head/*/$tail" "$target" && return 0    # ≥1 层
      return 1 ;;
    *'**'*)
      one="${pattern%%'**'*}*${pattern#*'**'}"
      wl_glob_match "$one" "$target" && return 0
      return 1 ;;
    *)
      case "$target" in $pattern) return 0 ;; *) return 1 ;; esac ;;
  esac
}

# ---- JSON 字符串转义（纯 sed/tr，不用 awk；控制字符含换行/制表一律压成空格，保证单行合法）----
wl_json_escape() {
  printf '%s' "$1" | LC_ALL=C tr '\000-\037' ' ' | LC_ALL=C sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# ---- 路径归一化为「相对仓库根」----
# 依赖全局 ROOT / ROOT_P（由 wl_init 设置）。处理：① 相对路径按进程 cwd 锚定；
# ② symlink 根（/tmp vs /private/tmp）；③ 目标/父目录尚不存在的新建文件（物理化最近已存在祖先）。
wl_rel() {
  p="$1"
  case "$p" in
    /*)  : ;;                          # 绝对路径
    ./*) p="$PWD/${p#./}" ;;           # ./foo → cwd 锚定
    *)   p="$PWD/$p" ;;                # 相对 cwd → 拼绝对（gap-cwd-1）
  esac
  rest=""; anc="$p"
  while [ "$anc" != "/" ] && [ "$anc" != "." ] && [ ! -e "$anc" ]; do
    rest="$(basename "$anc")${rest:+/$rest}"
    anc="$(dirname "$anc")"
  done
  ancp="$(cd "$anc" 2>/dev/null && pwd -P || printf '%s' "$anc")"
  full="$ancp${rest:+/$rest}"
  case "$full" in
    "$ROOT_P"/*) printf '%s' "${full#"$ROOT_P"/}" ;;
    "$ROOT"/*)   printf '%s' "${full#"$ROOT"/}" ;;
    *)           printf '%s' "$1" ;;   # 仓库外 → 原样（必落到清单外）
  esac
}

# ---- 单个相对路径是否允许：test 自动放行 OR 命中白名单某行 ----
wl_is_allowed() {
  rel="$1"; wl="$2"
  wl_glob_match "test/**/*_test.dart" "$rel" && return 0
  [ -f "$wl" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    pat="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$pat" ] && continue
    case "$pat" in '#'*) continue ;; esac
    wl_glob_match "$pat" "$rel" && return 0
  done < "$wl"
  return 1
}

# ---- 定位仓库根（非 git 仓亦不报错：回落 pwd → 配合「无白名单=放行」，绝不 rc=2）----
wl_init() {
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  ROOT_P="$(cd "$ROOT" 2>/dev/null && pwd -P || printf '%s' "$ROOT")"
}

# ---- CLI: 判定多路径 ----
wl_cmd_check() {
  [ "$#" -ge 1 ] || { echo "whitelist_core.sh: 未给路径参数" >&2; exit 2; }
  wl_init
  WL="$ROOT/.spec-task-whitelist"
  [ -f "$WL" ] || exit 0          # ★ 无白名单 → 全允许（锁定）
  viol=0
  for raw in "$@"; do
    rel="$(wl_rel "$raw")"
    if wl_is_allowed "$rel" "$WL"; then :; else printf '%s\n' "$rel"; viol=1; fi
  done
  [ "$viol" -eq 0 ] && exit 0 || exit 10
}

# ---- CLI: 对称回归自检（不依赖当前仓库）----
wl_cmd_selftest() {
  self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  td="$(mktemp -d)"; trap 'rm -rf "$td"' EXIT
  (
    cd "$td" || exit 1
    git init -q 2>/dev/null || true
    bash "$self" "lib/x.dart" >/dev/null 2>&1; ra=$?            # A 无白名单 → 0
    printf 'lib/data/**\n' > .spec-task-whitelist
    ob="$(bash "$self" "lib/ui/x.dart" 2>/dev/null)"; rb=$?     # B 越界 → 10 + 打印路径
    bash "$self" "lib/data/x.dart" >/dev/null 2>&1; rc=$?       # C 在内 → 0
    bash "$self" "test/data/x_test.dart" >/dev/null 2>&1; rd=$? # D 测试 → 0
    om="$(bash "$self" "lib/data/ok.dart" "lib/ui/bad.dart" 2>/dev/null)"; rm=$?  # E 多路径一越界
    [ "$ra" = 0 ] && [ "$rb" = 10 ] && [ "$ob" = "lib/ui/x.dart" ] \
      && [ "$rc" = 0 ] && [ "$rd" = 0 ] && [ "$rm" = 10 ] && [ "$om" = "lib/ui/bad.dart" ]
  )
}

# ---- 主入口（仅在直接执行时跑；被 source 时只暴露函数）----
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  case "${1:-}" in
    --json-escape) shift; wl_json_escape "${1:-}" ;;
    --selftest)    if wl_cmd_selftest; then echo "[whitelist_core] selftest 通过"; exit 0; else echo "[whitelist_core] selftest 失败" >&2; exit 1; fi ;;
    *)             wl_cmd_check "$@" ;;
  esac
fi
