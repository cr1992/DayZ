#!/usr/bin/env bash
#
# patrol_test.sh · DayZ Patrol E2E 运行入口（flaky 防护 + 零执行守卫）
#
# 作者：@Ray
# 关联 spec：specs/active/e2e-harness/（T3 / T8 / R4 / R7 / R8）
#
# 为什么不裸调 `patrol test`：patrol_cli 有两类已知 flaky + 一类静默假阳性，裸调会
# 偶发「假崩」（CI 杀手）或「假绿」（0 用例却 all pass）。本封装确定性地做四件事：
#
#   R4-a 禁启动遥测：写 ~/.config/patrol_cli/analytics.json {"enabled":false} +
#        导出 PATROL_ANALYTICS_ENABLED=false，避开 google-analytics 偶发 TLS handshake 崩 CLI。
#   R4-b 网络抖动 retry：native assets（sqlite3mc 的 iOS dylib / android .so）从零重下、
#        Android kotlin-compiler-embeddable 的 Maven handshake 中途断、以及 Android 首跑偶发
#        app-service 时序 Total:0 —— 命中可重试模式时重跑（最多 PATROL_MAX_RETRIES 次）。
#   R7   零执行守卫：解析 patrol 输出的 `Total: N`，N 缺失或为 0 → 判失败（非零退出），
#        把「全 pass 但零执行」挡在 CI 闸外。**真实的用例断言失败不重试**（避免重试掩盖真 bug）。
#   R8   测试隔离 + 产物清理：iOS 无 Android 的 clearPackageData，故跑前（及绿后）
#        `xcrun simctl uninstall <ios-sim> com.dayz` 清 app 容器——清掉上次留下的真加密 DB/媒体，
#        每次跑干净起步（红跑保留现场供 post-mortem，下次跑前再清）；并修剪旧 build/ios_results_*.xcresult。
#        仅在目标是 iOS 模拟器时生效（Android 走自身 clearPackageData）；PATROL_NO_RESET=1 可关。
#
# 跑法（device flag 之外的参数原样透传给 `patrol test`）：
#   bash scripts/patrol_test.sh -d <ios-sim-id>
#   bash scripts/patrol_test.sh -d <ios-sim-id> --target patrol_test/patrol_smoke_test.dart
#   PATROL_MAX_RETRIES=5 bash scripts/patrol_test.sh -d <android-emulator-id>
#
# 自检（不跑 patrol，只验解析/守卫逻辑）：
#   bash scripts/patrol_test.sh --selftest
#
# 退出码：
#   0  patrol 成功且确实跑了 ≥1 个用例（Total ≥ 1, Failed = 0）
#   1  patrol 失败 / 重试用尽 / 零执行守卫拦截（Total 缺失或为 0）/ 自检不通过
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MAX_RETRIES="${PATROL_MAX_RETRIES:-3}"

# 命中其一即「基建/网络抖动」候选。仅在**没有真实断言失败**（Failed=0 或缺失）时才据此重试——
# 真实用例断言失败（Failed≥1）在决策树里先被拦掉、绝不重试，故这里即便措辞偏宽也不会掩盖真 bug。
# 刻意只收编译/下载/依赖解析这类构建期短语，不收裸 "TLS"/"timed out"/"Connection reset"（易撞用例自身输出）。
RETRYABLE_RE='Building native assets failed|Connection closed while receiving data|Could not (resolve|download|GET|HEAD)|kotlin-compiler-embeddable|Read timed out|SocketException|handshake failed|Failed to (download|resolve)|sqlite3mc.*(download|fetch)'

# ---------------------------------------------------------------------------
# R4-a · 禁启动遥测 handshake（盘 + env 双关）
# ---------------------------------------------------------------------------
disable_analytics() {
  local cfg_dir="${XDG_CONFIG_HOME:-$HOME/.config}/patrol_cli"
  local cfg="$cfg_dir/analytics.json"
  mkdir -p "$cfg_dir"
  # 已显式 enabled:false 则不动；否则覆盖为最小关闭配置（analytics 关闭时无其它状态需保留）。
  if ! { [[ -f "$cfg" ]] && grep -Eq '"enabled"[[:space:]]*:[[:space:]]*false' "$cfg"; }; then
    printf '{"enabled": false}\n' > "$cfg"
  fi
  export PATROL_ANALYTICS_ENABLED=false
}

# ---------------------------------------------------------------------------
# R7 · 从一段 patrol 输出里取「最后一个」Total 计数（取末次＝最终汇总，无则空串）
# ---------------------------------------------------------------------------
parse_total() {
  # 入参：日志文件路径。输出：整数计数，或空串（无 Total 行）。
  grep -Eo 'Total:[[:space:]]*[0-9]+' "$1" | grep -Eo '[0-9]+' | tail -1
}

parse_failed() {
  grep -Eo 'Failed:[[:space:]]*[0-9]+' "$1" | grep -Eo '[0-9]+' | tail -1
}

# ---------------------------------------------------------------------------
# 自检：用样例输出喂解析/守卫逻辑，不依赖真机 / 真 patrol
# ---------------------------------------------------------------------------
selftest() {
  local tmp ok=0
  tmp="$(mktemp "${TMPDIR:-/tmp}/patrol_selftest.XXXXXX")"

  printf 'Total: 1\nSuccessful: 1\nFailed: 0\n' > "$tmp"
  [[ "$(parse_total "$tmp")" == "1" ]] || { echo "  FAIL: Total:1 应解析为 1" >&2; ok=1; }
  [[ "$(parse_failed "$tmp")" == "0" ]] || { echo "  FAIL: Failed:0 应解析为 0" >&2; ok=1; }

  printf 'Total: 0\nSuccessful: 0\nFailed: 0\n' > "$tmp"
  [[ "$(parse_total "$tmp")" == "0" ]] || { echo "  FAIL: Total:0 应解析为 0（零执行守卫据此拦截）" >&2; ok=1; }

  printf 'some unrelated build chatter\nno summary here\n' > "$tmp"
  [[ -z "$(parse_total "$tmp")" ]] || { echo "  FAIL: 无 Total 行应得空串（守卫 fail-closed）" >&2; ok=1; }

  # 取「末次」汇总：构建期可能出现中间 Total，最终汇总才算数。
  printf 'Total: 99 (intermediate)\nTotal: 2\nSuccessful: 2\nFailed: 0\n' > "$tmp"
  [[ "$(parse_total "$tmp")" == "2" ]] || { echo "  FAIL: 多个 Total 应取最后一个（2）" >&2; ok=1; }

  rm -f "$tmp"
  if [[ $ok -eq 0 ]]; then echo "selftest OK：解析与零执行守卫逻辑通过"; fi
  return $ok
}

# ---------------------------------------------------------------------------
# R8 · 测试隔离 + 产物清理（仅 iOS 模拟器；Android 走自身 clearPackageData）
# ---------------------------------------------------------------------------
APP_BUNDLE_ID="${PATROL_APP_BUNDLE_ID:-com.dayz}"

# 从透传参数里取 -d/--device 的值；当且仅当它是一台 iOS 模拟器时回显其 id（否则空）。
# 非 mac / 无 xcrun / Android 设备 / 名字对不上 → 空串 → reset/prune 全部 no-op。
detect_ios_sim() {
  command -v xcrun >/dev/null 2>&1 || return 0
  local dev="" prev=""
  for a in "$@"; do
    if [[ "$prev" == "-d" || "$prev" == "--device" ]]; then dev="$a"; fi
    prev="$a"
  done
  [[ -n "$dev" ]] || return 0
  if xcrun simctl list devices 2>/dev/null | grep -q -- "$dev"; then printf '%s' "$dev"; fi
}

# 清 iOS app 容器：清掉上次跑留下的真加密 DB/媒体，保证干净起步。uninstall 对未安装的 app 无害。
reset_ios_app() {
  [[ -n "${IOS_SIM:-}" && -z "${PATROL_NO_RESET:-}" ]] || return 0
  echo "  R8 测试隔离：simctl uninstall ${IOS_SIM} ${APP_BUNDLE_ID}（清容器）" >&2
  xcrun simctl uninstall "$IOS_SIM" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
}

# 修剪旧 xcresult：保留最近 PATROL_KEEP_XCRESULTS 个（默认 3），其余删除。仅 iOS 产物。
prune_xcresults() {
  [[ -n "${IOS_SIM:-}" ]] || return 0
  local keep="${PATROL_KEEP_XCRESULTS:-3}" glob="${PATROL_RESULTS_GLOB:-build/ios_results_*.xcresult}" olds
  # shellcheck disable=SC2086  # 故意让 $glob 走通配展开
  olds="$(ls -dt $glob 2>/dev/null | tail -n "+$((keep + 1))")"
  [[ -n "$olds" ]] || return 0
  echo "  R8 产物清理：修剪旧 xcresult（保留最近 ${keep} 个）" >&2
  printf '%s\n' "$olds" | while IFS= read -r d; do [[ -n "$d" ]] && rm -rf "$d"; done
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--selftest" ]]; then
  selftest
  exit $?
fi

cd "$ROOT_DIR"
disable_analytics

IOS_SIM="${PATROL_FORCE_IOS_SIM:-$(detect_ios_sim "$@")}"   # 空＝非 iOS 模拟器目标，R8 清理全程 no-op

LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/patrol_test.XXXXXX")"
trap 'rm -f "$LOG_FILE"; prune_xcresults' EXIT

reset_ios_app   # 跑前清容器：清掉上次跑残留的真加密 DB/媒体（R8 测试隔离）

attempt=0
while :; do
  attempt=$((attempt + 1))
  echo "== patrol test（第 $attempt/$MAX_RETRIES 次）：patrol test $* =="

  # tee：实时透传给用户 + 落盘供解析。PIPESTATUS[0] = patrol 的真实退出码。
  patrol test "$@" 2>&1 | tee "$LOG_FILE"
  status="${PIPESTATUS[0]}"

  total="$(parse_total "$LOG_FILE")"
  failed="$(parse_failed "$LOG_FILE")"
  reason=""

  # ---- 1) 成功：三证齐全才放行（R7 不轻信 patrol 自报的退出 0）----
  #      patrol 退 0  ＋  Total≥1（确实跑了用例）  ＋  明确 Failed=0（不是「Failed 行缺失被默认成 0」）。
  if [[ "$status" -eq 0 && -n "$total" && "$total" -ge 1 && -n "$failed" && "$failed" -eq 0 ]]; then
    echo "----------------------------------------"
    echo "通过：Total=${total} Failed=${failed}（第 ${attempt} 次）"
    reset_ios_app   # 绿后清容器：机器恢复干净（红跑保留现场，故只在成功时后清）
    exit 0
  fi

  # ---- 2) 真实用例断言失败（Failed≥1）→ 立即判失败，绝不重试 ----
  #      先于 RETRYABLE_RE 判定：真失败的报错文本即便含 "timed out" 之类也不会被误重试掩盖。
  if [[ -n "$failed" && "$failed" -ge 1 ]]; then
    echo "----------------------------------------" >&2
    echo "失败：真实用例断言失败 Failed=${failed}（status=${status}，不重试——重试无法修真 bug）" >&2
    exit 1
  fi

  # ---- 3) 可疑（此时 Failed 必为 0 或缺失）：基建抖动 / 零执行 / 输出截断 → 能重试就重试 ----
  if grep -Eq "$RETRYABLE_RE" "$LOG_FILE"; then
    reason="基建/网络抖动"
  fi
  # status==0 却凑不齐「Total≥1 且 Failed=0」= 静默假阳性 / Android 首跑时序 / 输出截断 → fail-closed 重试。
  if [[ "$status" -eq 0 ]]; then
    reason="零执行守卫(R7)：patrol 退 0 但 Total=${total:-<缺>}/Failed=${failed:-<缺>} 不可信"
    echo "  $reason → 不放行" >&2
  fi

  if [[ -n "$reason" && $attempt -lt $MAX_RETRIES ]]; then
    echo "  可重试（${reason}），重跑……" >&2
    continue
  fi

  echo "----------------------------------------" >&2
  if [[ "$status" -ne 0 ]]; then
    echo "失败：patrol 退出码 ${status}（第 ${attempt} 次；非可重试模式或重试用尽）" >&2
  else
    echo "失败：零执行守卫拦截（Total=${total:-<缺失>} Failed=${failed:-<缺失>}，重试用尽）—— 全 pass 但未确证真跑用例" >&2
  fi
  exit 1
done
