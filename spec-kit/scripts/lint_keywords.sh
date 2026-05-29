#!/usr/bin/env bash
# spec-kit · lint_keywords.sh
#
# 用途：检查 requirement.md 的 RFC2119 关键词——①大小写规范化（小写应大写）②存在性（全篇须至少出现一个大写关键词）。
# 用法：lint_keywords.sh [SPECS_DIR]   （默认 ./specs，或环境变量 SPECS_DIR）
# 退出码：0=无；1=有（路径:行号: 说明 + 末尾计数）；2=用法/环境错误。
# 强制规范：RFC2119 关键词规范化 + 存在性。注意：SHALL↔SHOULD 的分级「用对没用对」属语义，本 lint 判不了，须人审。
# 大小写检查范围：must / shall / should 及其否定式（高信号，requirement 中小写几乎必为关键词误写）。
#   不查小写 may / required / recommended / optional —— 它们是常见英文词，小写多为正常散文，自动标记噪声过大，留人审。
# 存在性检查范围：MUST / SHALL / SHOULD / MAY 及其否定式（含 MAY，任一大写出现即满足存在性）。
# 范围：默认跳过 archive/（已归档只读、冻结，不参与 lint）。
# 兼容：纯 bash + awk(LC_ALL=C，避免 BSD awk 遇中文多字节崩溃；ASCII 大小写判定不受影响)。
set -euo pipefail
export LC_ALL=C

SPECS_DIR="${1:-${SPECS_DIR:-./specs}}"
SPECS_DIR="${SPECS_DIR%/}"
[ -d "$SPECS_DIR" ] || { echo "用法错误：目录不存在: $SPECS_DIR" >&2; exit 2; }

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT

find "$SPECS_DIR" -type f -name 'requirement.md' -not -path '*/archive/*' | while IFS= read -r f; do
  awk -v F="${f#./}" '
    BEGIN { infence = 0; seen_kw = 0 }
    {
      line = $0
      if (line ~ /^[[:space:]]*(```|~~~)/) { infence = !infence; next }
      if (infence) next
      d = line
      gsub(/`[^`]*`/, "", d)                 # 去行内 code
      gsub(/https?:\/\/[^ )]+/, "", d)        # 去 URL
      # 存在性：记下是否出现过合法的大写 RFC2119 关键词（含 MAY）
      if (d ~ /(^|[^A-Za-z])(MUST NOT|SHALL NOT|SHOULD NOT|MUST|SHALL|SHOULD|MAY)([^A-Za-z]|$)/) seen_kw = 1
      if (d ~ /(^|[^A-Za-z])(must not|shall not|should not)([^A-Za-z]|$)/) {
        printf "%s:%d: 小写 RFC2119 否定式，应大写为 MUST NOT / SHALL NOT / SHOULD NOT\n", F, NR
        next
      }
      if (d ~ /(^|[^A-Za-z])(must|shall|should)([^A-Za-z]|$)/) {
        printf "%s:%d: 小写 RFC2119 关键词，应大写为 MUST / SHALL / SHOULD\n", F, NR
      }
    }
    END {
      # 存在性校验：requirement 须用规范关键词描述系统行为，全篇无任何大写 RFC2119 词即违规。
      if (!seen_kw) printf "%s:1: 未出现任何大写 RFC2119 关键词（MUST/SHALL/SHOULD/MAY），需求须用规范关键词描述系统行为（存在性校验）\n", F
    }
  ' "$f" >> "$tmp"
done

if [ -s "$tmp" ]; then
  cat "$tmp"
  printf '违规计数: %s\n' "$(wc -l < "$tmp" | tr -d ' ')"
  exit 1
fi
exit 0
