#!/usr/bin/env bash
# spec-kit · lint_keywords.sh
#
# 用途：检查 requirement.md 里 RFC2119 关键词是否被写成小写（应大写）。仅查拼写/大小写存在性。
# 用法：lint_keywords.sh [SPECS_DIR]   （默认 ./specs，或环境变量 SPECS_DIR）
# 退出码：0=无；1=有（路径:行号: 说明 + 末尾计数）；2=用法/环境错误。
# 强制规范：RFC2119 关键词规范化。注意：SHALL↔SHOULD 的分级「用对没用对」属语义，本 lint 判不了，须人审。
# 检查范围：must / shall / should 及其否定式（高信号，requirement 中小写几乎必为关键词误写）。
#   不查 may / required / recommended / optional —— 它们是常见英文词，小写多为正常散文，自动标记噪声过大，留人审。
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
    BEGIN { infence = 0 }
    {
      line = $0
      if (line ~ /^[[:space:]]*(```|~~~)/) { infence = !infence; next }
      if (infence) next
      d = line
      gsub(/`[^`]*`/, "", d)                 # 去行内 code
      gsub(/https?:\/\/[^ )]+/, "", d)        # 去 URL
      if (d ~ /(^|[^A-Za-z])(must not|shall not|should not)([^A-Za-z]|$)/) {
        printf "%s:%d: 小写 RFC2119 否定式，应大写为 MUST NOT / SHALL NOT / SHOULD NOT\n", F, NR
        next
      }
      if (d ~ /(^|[^A-Za-z])(must|shall|should)([^A-Za-z]|$)/) {
        printf "%s:%d: 小写 RFC2119 关键词，应大写为 MUST / SHALL / SHOULD\n", F, NR
      }
    }
  ' "$f" >> "$tmp"
done

if [ -s "$tmp" ]; then
  cat "$tmp"
  printf '违规计数: %s\n' "$(wc -l < "$tmp" | tr -d ' ')"
  exit 1
fi
exit 0
