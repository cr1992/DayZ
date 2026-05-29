#!/usr/bin/env bash
# spec-kit · check_dead_links.sh
#
# 用途：检查 SPECS_DIR 下所有 Markdown 的相对链接目标是否存在（防归档/重构产生死链）。
# 用法：check_dead_links.sh [SPECS_DIR]      （默认 ./specs，亦可用环境变量 SPECS_DIR 覆盖）
# 退出码：0=无死链；1=发现死链（逐条打印 路径:行号: 说明 + 末尾计数）；2=用法/环境错误。
# 强制规范：归档原子三步之「无死链」；specs 内相对链接有效性。
# 范围：默认跳过 archive/（已归档只读、冻结，不参与扫描；但其它文件指向 archive/ 的链接仍校验存在性）。
# 兼容：纯 bash + POSIX(find/grep/sed/dirname)，macOS(BSD) 与 Linux 通用；不依赖 rg/python/readlink -f。
set -euo pipefail
export LC_ALL=C

SPECS_DIR="${1:-${SPECS_DIR:-./specs}}"
SPECS_DIR="${SPECS_DIR%/}"
[ -d "$SPECS_DIR" ] || { echo "用法错误：目录不存在: $SPECS_DIR" >&2; exit 2; }

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT

find "$SPECS_DIR" -type f -name '*.md' -not -path '*/archive/*' | while IFS= read -r md; do
  dir="$(dirname "$md")"
  # 逐行提取所有 ](target) 链接（含图片 ![](target)）；先经 awk 把代码围栏内与行内 code
  # 的内容清空（保留行号），使 ```fence``` 里的示例链接、`](x)` 不被当成真链接（与另两道 lint 一致）。
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    lineno="${hit%%:*}"
    rest="${hit#*:}"               # ](target)
    target="${rest#](}"; target="${target%)}"
    target="${target#<}"; target="${target%>}"
    target="${target%% *}"         # 去链接标题 ("title")
    target="${target%%#*}"         # 去锚点
    target="${target%%\?*}"        # 去查询串
    [ -n "$target" ] || continue
    case "$target" in
      \#*) continue ;;                                   # 纯锚点
      *://*) continue ;;                                 # scheme://
      //*) continue ;;                                   # 协议相对
      mailto:*|tel:*|data:*|javascript:*) continue ;;
    esac
    case "$target" in
      /*) check="$target" ;;                             # 绝对路径按字面
      *)  check="$dir/$target" ;;                        # 相对所在 md 目录解析（含 ../ 由文件系统折叠）
    esac
    if [ ! -e "$check" ]; then
      printf '%s:%s: 死链 -> %s (目标不存在)\n' "${md#./}" "$lineno" "$target" >> "$tmp"
    fi
  done < <(awk '
    BEGIN { infence = 0 }
    /^[[:space:]]*(```|~~~)/ { infence = !infence; print ""; next }   # 围栏行：清空但保留行号
    { if (infence) { print ""; next }                                  # 围栏内整段不算真链接
      s = $0; gsub(/`[^`]*`/, "", s); print s }                        # 非围栏行去掉行内 code 段
  ' "$md" 2>/dev/null | grep -noE '\]\([^)]*\)' 2>/dev/null || true)
done

if [ -s "$tmp" ]; then
  cat "$tmp"
  printf '违规计数: %s\n' "$(wc -l < "$tmp" | tr -d ' ')"
  exit 1
fi
exit 0
