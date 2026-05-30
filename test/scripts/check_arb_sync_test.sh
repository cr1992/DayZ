#!/usr/bin/env bash
# check_arb_sync.sh 的测试：用临时夹具验证一致/缺漏两种情况。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
CHECK_SCRIPT="${PROJECT_ROOT}/scripts/check_arb_sync.sh"

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

PASS=0
FAIL=0

# --- 测试 1：key 一致 → exit 0 ---
cat > "${TMPDIR_TEST}/zh.arb" << 'EOF'
{
  "@@locale": "zh",
  "appTitle": "DayZ",
  "@appTitle": { "description": "标题" },
  "hello": "你好"
}
EOF

cat > "${TMPDIR_TEST}/en.arb" << 'EOF'
{
  "@@locale": "en",
  "appTitle": "DayZ",
  "hello": "Hello"
}
EOF

if bash "$CHECK_SCRIPT" "${TMPDIR_TEST}/zh.arb" "${TMPDIR_TEST}/en.arb" > /dev/null 2>&1; then
  echo "PASS: key 一致 → exit 0"
  ((PASS++))
else
  echo "FAIL: key 一致应 exit 0，实际非零"
  ((FAIL++))
fi

# --- 测试 2：en 缺 key → exit 非零且输出缺失 key ---
cat > "${TMPDIR_TEST}/en_missing.arb" << 'EOF'
{
  "@@locale": "en",
  "appTitle": "DayZ"
}
EOF

OUTPUT=$(bash "$CHECK_SCRIPT" "${TMPDIR_TEST}/zh.arb" "${TMPDIR_TEST}/en_missing.arb" 2>&1 || true)
EXIT_CODE=0
bash "$CHECK_SCRIPT" "${TMPDIR_TEST}/zh.arb" "${TMPDIR_TEST}/en_missing.arb" > /dev/null 2>&1 || EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "PASS: en 缺 key → exit 非零 ($EXIT_CODE)"
  ((PASS++))
else
  echo "FAIL: en 缺 key 应 exit 非零，实际 exit 0"
  ((FAIL++))
fi

if echo "$OUTPUT" | grep -q "hello"; then
  echo "PASS: 输出指出缺失的 key 'hello'"
  ((PASS++))
else
  echo "FAIL: 输出未指出缺失的 key 'hello'"
  ((FAIL++))
fi

# --- 测试 3：zh 缺 key（en 多出 key）→ exit 非零 ---
cat > "${TMPDIR_TEST}/zh_less.arb" << 'EOF'
{
  "@@locale": "zh",
  "appTitle": "DayZ"
}
EOF

cat > "${TMPDIR_TEST}/en_more.arb" << 'EOF'
{
  "@@locale": "en",
  "appTitle": "DayZ",
  "extra": "Extra"
}
EOF

EXIT_CODE=0
bash "$CHECK_SCRIPT" "${TMPDIR_TEST}/zh_less.arb" "${TMPDIR_TEST}/en_more.arb" > /dev/null 2>&1 || EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "PASS: zh 缺 key → exit 非零 ($EXIT_CODE)"
  ((PASS++))
else
  echo "FAIL: zh 缺 key 应 exit 非零，实际 exit 0"
  ((FAIL++))
fi

# --- 汇总 ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
