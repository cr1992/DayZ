#!/usr/bin/env bash
# spec-kit · lint_acceptance_commands.sh
#
# 用途：检查 tasks.md / verification.md 的验收命令是否「正向 grep 被改源文件」
#       （把字面量写进文件即 exit 0，可被 AI 糊弄，违反 P3 抗规避规则）。
# 用法：lint_acceptance_commands.sh [SPECS_DIR]   （默认 ./specs，或环境变量 SPECS_DIR）
# 退出码：0=无违规；1=有违规（路径:行号: 说明 + 末尾计数）；2=用法/环境错误。
# 强制规范：P3「验收命令的抗规避规则」——验收须运行测试断言行为，不得 grep 被改文件自身。
# 启发式（尽量精准、避免误伤散文）：
#   · 只把「真正的命令文本」纳入检查——``` 围栏内整行，或非围栏行里**反引号命令 span** 内的内容；
#     散文里提到「grep」（如「改为测试而非 grep 源文件」）不在命令 span 内，不算。
#   · 放行：`! grep`（缺失守卫）、`grep -v`（过滤）、含 `TODO(` / `FIXME(` 的行（跨 spec 协调标记守卫，规范允许）。
#   · 先剔除引号内子串，再在命令文本里找源码扩展名 token，故 grep 的「模式」不会被误判为文件目标。
# 范围：默认跳过 archive/（已归档只读、冻结，其历史写法不参与 lint）。
# 兼容：纯 bash + awk(LC_ALL=C)，macOS(BSD)/Linux 通用，无 rg/python 依赖。
set -euo pipefail
export LC_ALL=C

SPECS_DIR="${1:-${SPECS_DIR:-./specs}}"
SPECS_DIR="${SPECS_DIR%/}"
[ -d "$SPECS_DIR" ] || { echo "用法错误：目录不存在: $SPECS_DIR" >&2; exit 2; }

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT

find "$SPECS_DIR" -type f \( -name 'tasks.md' -o -name 'verification.md' \) -not -path '*/archive/*' | while IFS= read -r f; do
  awk -v F="${f#./}" '
    BEGIN { infence = 0 }
    {
      line = $0
      if (line ~ /^[[:space:]]*(```|~~~)/) { infence = !infence; next }
      # 命令文本 cmd：围栏内取整行；否则只取反引号 span 内的内容
      if (infence) {
        cmd = line
      } else {
        cmd = ""; s = line
        while (match(s, /`[^`]*`/)) {
          cmd = cmd " " substr(s, RSTART + 1, RLENGTH - 2)
          s = substr(s, RSTART + RLENGTH)
        }
      }
      if (index(cmd, "grep") == 0) next
      if (cmd ~ /![[:space:]]*grep/) next          # 缺失守卫 ! grep
      if (cmd ~ /grep[[:space:]]+-v/) next          # 过滤 grep -v
      if (line ~ /TODO\(|FIXME\(/) next             # 跨 spec 协调标记守卫（规范允许）
      g = cmd
      gsub(/\047[^\047]*\047/, "", g)               # 剔除 \047...\047 (单引号串)
      gsub(/"[^"]*"/, "", g)                        # 剔除 "..." (双引号串)
      if (g ~ /[A-Za-z0-9_.\/~-]+\.(dart|ts|tsx|js|jsx|css|scss|sass|yaml|yml|sql|go|py|kt|kts|swift|java|rb|rs|cpp|cc|hpp|json|xml|gradle|plist|pbxproj)([^A-Za-z0-9]|$)/) {
        printf "%s:%d: 验收用 grep 被改源文件（正向存在性），应改为运行测试断言行为（P3 抗规避）\n", F, NR
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
