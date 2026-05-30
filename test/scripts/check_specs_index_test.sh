#!/usr/bin/env bash
# check_specs_index.sh 的测试：用临时 specs 夹具验证归档复验台账硬闸。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
CHECK_SCRIPT="${PROJECT_ROOT}/spec-kit/scripts/check_specs_index.sh"

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

PASS=0
FAIL=0

write_readme() {
  local specs_dir="$1"
  cat > "${specs_dir}/README.md" <<'EOF'
# Specs 索引

## 进行中

| 功能 | 优先级 | 状态 | 依赖 | 负责人 | 创建 |
|------|--------|------|------|--------|------|

## 执行顺序

无。

## 已归档

| 功能 | 结果 | 归档日期 |
|------|------|----------|
| [alpha](archive/2026-05-30-alpha/) | 已完成 | 2026-05-30 |
| [beta](archive/2026-05-30-beta/) | 已完成 | 2026-05-30 |
EOF
}

write_archive_spec() {
  local specs_dir="$1"
  local archive_dir="$2"
  local open_marker="${3:-no}"

  mkdir -p "${specs_dir}/archive/${archive_dir}"
  cat > "${specs_dir}/archive/${archive_dir}/requirement.md" <<'EOF'
---
作者：@Ray
创建日期：2026-05-30
---

# Fixture

## 需求

### R1 · Fixture
The system SHALL provide a fixture.
EOF

  if [ "$open_marker" = "yes" ]; then
    cat > "${specs_dir}/archive/${archive_dir}/tasks.md" <<'EOF'
---
作者：@Ray
创建日期：2026-05-30
---

# 任务列表：Fixture

- [-] T1 · Fixture

### 验收记录
```
日期：—
自动：—
人工：待确认（核查人 @Ray）
```
EOF
  else
    cat > "${specs_dir}/archive/${archive_dir}/tasks.md" <<'EOF'
---
作者：@Ray
创建日期：2026-05-30
---

# 任务列表：Fixture

- [x] T1 · Fixture

### 验收记录
```
日期：2026-05-30
自动：PASS
人工：N/A
```
EOF
  fi
}

write_acceptance_review() {
  local specs_dir="$1"
  local include_beta="${2:-yes}"

  cat > "${specs_dir}/archive/acceptance-review.md" <<EOF
---
作者：@Ray
创建日期：2026-05-30
---

# 归档验收说明

## 结论

| spec | 归档结论 | 说明 |
|---|---|---|
| \`alpha\` | 通过 | fixture |
EOF

  if [ "$include_beta" = "yes" ]; then
    cat >> "${specs_dir}/archive/acceptance-review.md" <<'EOF'
| `beta` | 通过 | fixture |
EOF
  fi
}

make_specs_fixture() {
  local name="$1"
  local specs_dir="${TMPDIR_TEST}/${name}/specs"
  mkdir -p "${specs_dir}/active" "${specs_dir}/archive"
  write_readme "$specs_dir"
  write_archive_spec "$specs_dir" "2026-05-30-alpha" "${2:-no}"
  write_archive_spec "$specs_dir" "2026-05-30-beta" "${3:-no}"
  printf '%s\n' "$specs_dir"
}

assert_pass() {
  local label="$1"
  local specs_dir="$2"

  if bash "$CHECK_SCRIPT" "$specs_dir" > /dev/null 2>&1; then
    echo "PASS: $label"
    ((PASS+=1))
  else
    echo "FAIL: $label 应 exit 0"
    bash "$CHECK_SCRIPT" "$specs_dir" || true
    ((FAIL+=1))
  fi
}

assert_fail_contains() {
  local label="$1"
  local specs_dir="$2"
  local expected="$3"
  local output
  local status=0

  output="$(bash "$CHECK_SCRIPT" "$specs_dir" 2>&1)" || status=$?
  if [ "$status" -eq 0 ]; then
    echo "FAIL: $label 应 exit 非零，实际 exit 0"
    ((FAIL+=1))
    return
  fi
  if printf '%s\n' "$output" | grep -q "$expected"; then
    echo "PASS: $label"
    ((PASS+=1))
  else
    echo "FAIL: $label 输出未包含 '$expected'"
    printf '%s\n' "$output"
    ((FAIL+=1))
  fi
}

# Case 1: 台账结论表覆盖全部归档 spec -> 通过。
SPECS_OK="$(make_specs_fixture ok)"
write_acceptance_review "$SPECS_OK" yes
assert_pass "acceptance-review 覆盖全部归档 spec" "$SPECS_OK"

# Case 2: 台账存在但漏掉一个归档 spec -> 失败。
SPECS_MISSING_ROW="$(make_specs_fixture missing-row)"
write_acceptance_review "$SPECS_MISSING_ROW" no
assert_fail_contains "acceptance-review 漏掉 beta 会失败" "$SPECS_MISSING_ROW" "beta"

# Case 3: 没有台账且归档 tasks 残留待确认/未完成痕迹 -> 失败。
SPECS_OPEN_MARKER="$(make_specs_fixture open-marker yes no)"
assert_fail_contains "缺少台账且归档残留待确认会失败" "$SPECS_OPEN_MARKER" "acceptance-review.md"

# Case 4: 没有台账且归档 tasks 已干净 -> 通过，兼容未采用终局复验台账的仓库。
SPECS_NO_REVIEW_CLEAN="$(make_specs_fixture no-review-clean)"
assert_pass "无 acceptance-review 且归档任务干净时兼容通过" "$SPECS_NO_REVIEW_CLEAN"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
