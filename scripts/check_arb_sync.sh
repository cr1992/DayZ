#!/usr/bin/env bash
# arb key 对齐校验：比对 app_zh.arb 与 app_en.arb 的消息 key 集合。
# 排除 @@locale 与 @ 前缀元数据 key，一致 exit 0，缺漏/孤儿 exit 1。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

ZH_ARB="${1:-${PROJECT_ROOT}/lib/l10n/arb/app_zh.arb}"
EN_ARB="${2:-${PROJECT_ROOT}/lib/l10n/arb/app_en.arb}"

if [[ ! -f "$ZH_ARB" ]]; then
  echo "ERROR: zh arb not found: $ZH_ARB" >&2
  exit 2
fi
if [[ ! -f "$EN_ARB" ]]; then
  echo "ERROR: en arb not found: $EN_ARB" >&2
  exit 2
fi

# 提取消息 key（排除 @@locale 和 @xxx 元数据）
extract_keys() {
  python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
keys = sorted(k for k in data if not k.startswith('@'))
print('\n'.join(keys))
" "$1"
}

ZH_KEYS=$(extract_keys "$ZH_ARB")
EN_KEYS=$(extract_keys "$EN_ARB")

# 求对称差
ONLY_ZH=$(comm -23 <(echo "$ZH_KEYS") <(echo "$EN_KEYS"))
ONLY_EN=$(comm -13 <(echo "$ZH_KEYS") <(echo "$EN_KEYS"))

EXIT=0

if [[ -n "$ONLY_ZH" ]]; then
  echo "Keys only in zh (missing in en):"
  echo "$ONLY_ZH" | sed 's/^/  - /'
  EXIT=1
fi

if [[ -n "$ONLY_EN" ]]; then
  echo "Keys only in en (missing in zh):"
  echo "$ONLY_EN" | sed 's/^/  - /'
  EXIT=1
fi

if [[ $EXIT -eq 0 ]]; then
  echo "arb key sync OK — $(echo "$ZH_KEYS" | wc -l | tr -d ' ') keys aligned."
fi

exit $EXIT
