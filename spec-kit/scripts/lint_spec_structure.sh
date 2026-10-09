#!/usr/bin/env bash
# spec-kit · lint_spec_structure.sh
#
# 用途：校验 spec 文档的**结构合规**——补上关键词/验收命令/索引三闸都不查的那层。
#       专治「内容看着对、结构照感觉编」：tasks 用 `## T` 标题而非 `- [ ]` 复选框、
#       缺 inline 可追溯字段、缺 `## 文件变更`/`## 已知风险`/`## 非功能需求` 等。
# 用法：lint_spec_structure.sh [SPECS_DIR]   （默认 ./specs，或环境变量 SPECS_DIR）
# 退出码：0=无违规；1=有（path:行号: 说明 + 末尾计数）；2=用法/环境错误。
# 档判定：同目录有 verification.md → 标准档（须 ## 非功能需求 + verification 元数据/H1）；否则精简档。
# 范围：跳过 archive/（已归档冻结）。代码围栏 ``` 内的行**不计**（防示例里的 magic string 糊弄）。
#
# 本闸是**高信号粗闸**——只查段落/字段/复选框的「存在性 ≥1」。**刻意不查**：
#   · 段落非空（`## 文件变更` 可以是空标题）；· 每任务字段两两配齐；· 复选框占比；· 完成度。
# 即：一个 `## T` 反模式 tasks 只要掺 1 行复选框 + 各 inline 字段各 1 次即可洗白本闸。
# 这些细粒度判定留 CI / 后续迭代 / 人审。本闸的目标是拦住「结构整体跑偏」（如全 0），不是拦细节。
# 设计依据：spec-kit/spec-guide.md（P1/P3 + 标准档段）；不查 `## 架构`（标准档可选，ui-i18n-migration 合法无此段）、
#           不查 verification 的任何 H2（ui-i18n-migration 的 verification 为零-## 简化清单，合规）。
set -euo pipefail
export LC_ALL=C

SPECS_DIR="${1:-${SPECS_DIR:-./specs}}"
SPECS_DIR="${SPECS_DIR%/}"
[ -d "$SPECS_DIR" ] || { echo "用法错误：目录不存在: $SPECS_DIR" >&2; exit 2; }

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT

# 公共 awk 前导：跳过代码围栏 + 记首行/作者（YAML 元数据）。各 check 在 body 里 set 标志、END 里报缺。
# 注意：复选框等带反斜杠的正则**写成 awk 字面量**（/.../），不走 awk -v（-v 会做反斜杠转义把 \[ 吃成 [，导致 0 命中全量误报）。

check_requirement() { # $1=file $2=dam(标准/精简)
  awk -v F="${1#./}" -v dam="$2" '
    NR==1 { first=$0 }
    NR<=6 && /^作者：/ { author=1 }
    { if ($0 ~ /^(```|~~~)/) { infence=!infence; next } ; if (infence) next }
    /^# /            { h1=1 }
    /^## 背景/        { bg=1 }
    /^## 范围外/       { scope=1 }
    /^## (功能需求|需求)/ { needs=1 }
    /^## 非功能需求/    { nf=1 }
    END {
      if (first != "---" || !author) printf "%s:1: requirement 缺 YAML 前置 metadata（首行须 `---` 且前 6 行含 `作者：`）\n", F
      if (!h1)    printf "%s:1: requirement 缺一级标题 `# {功能名}`\n", F
      if (!bg)    printf "%s:1: requirement 缺 `## 背景` 段\n", F
      if (!scope) printf "%s:1: requirement 缺 `## 范围外` 段\n", F
      if (!needs) printf "%s:1: requirement 缺 `## 需求` 或 `## 功能需求` 段\n", F
      if (dam == "标准" && !nf) printf "%s:1: 标准档 requirement 缺 `## 非功能需求` 段（标准档必含 NF）\n", F
    }
  ' "$1"
}

check_design() { # $1=file
  awk -v F="${1#./}" '
    NR==1 { first=$0 }
    NR<=6 && /^作者：/ { author=1 }
    { if ($0 ~ /^(```|~~~)/) { infence=!infence; next } ; if (infence) next }
    /^# 设计：/   { h1=1 }
    /^## 技术决策/ { dec=1 }
    /^## 文件变更/ { fc=1 }
    /^## 已知风险/ { risk=1 }
    END {
      if (first != "---" || !author) printf "%s:1: design 缺 YAML 前置 metadata（首行须 `---` 且前 6 行含 `作者：`）\n", F
      if (!h1)   printf "%s:1: design 缺一级标题 `# 设计：{功能名}`\n", F
      if (!dec)  printf "%s:1: design 缺 `## 技术决策` 段\n", F
      if (!fc)   printf "%s:1: design 缺 `## 文件变更` 段（任务「可改文件」白名单的唯一来源与上界）\n", F
      if (!risk) printf "%s:1: design 缺 `## 已知风险` 段\n", F
    }
  ' "$1"
}

check_tasks() { # $1=file
  awk -v F="${1#./}" '
    NR==1 { first=$0 }
    NR<=6 && /^作者：/ { author=1 }
    { if ($0 ~ /^(```|~~~)/) { infence=!infence; next } ; if (infence) next }
    /^# 任务列表：/         { h1=1 }
    /^- \[[ x-]\] T[0-9]+ / { cb=1 }
    /关联需求/              { rel=1 }
    /依据设计/              { dep=1 }
    /可改文件/              { files=1 }
    /^### 验收方式/         { vmeth=1 }
    END {
      if (first != "---" || !author) printf "%s:1: tasks 缺 YAML 前置 metadata（首行须 `---` 且前 6 行含 `作者：`）\n", F
      if (!h1)    printf "%s:1: tasks 缺一级标题 `# 任务列表：{功能名}`\n", F
      if (!cb)    printf "%s:1: tasks 无任何复选框任务行 `- [ ] T{n} · ...`（任务须用复选框，禁用 `## T{n}` 标题反模式）\n", F
      if (!rel)   printf "%s:1: tasks 缺 inline 字段 `关联需求`（需求↔任务可追溯性）\n", F
      if (!dep)   printf "%s:1: tasks 缺 inline 字段 `依据设计`（设计↔任务可追溯性）\n", F
      if (!files) printf "%s:1: tasks 缺 inline 字段 `可改文件`（任务文件白名单）\n", F
      if (!vmeth) printf "%s:1: tasks 无任何 `### 验收方式` 子段\n", F
    }
  ' "$1"
}

check_verification() { # $1=file （仅标准档调用）
  awk -v F="${1#./}" '
    NR==1 { first=$0 }
    NR<=6 && /^作者：/ { author=1 }
    { if ($0 ~ /^(```|~~~)/) { infence=!infence; next } ; if (infence) next }
    /^# 验证：/ { h1=1 }
    END {
      if (first != "---" || !author) printf "%s:1: verification 缺 YAML 前置 metadata（首行须 `---` 且前 6 行含 `作者：`）\n", F
      if (!h1) printf "%s:1: verification 缺一级标题 `# 验证：{功能名}`\n", F
    }
  ' "$1"
}

while IFS= read -r reqf; do
  [ -n "$reqf" ] || continue
  d="$(dirname "$reqf")"
  dam="精简"; [ -f "$d/verification.md" ] && dam="标准"
  check_requirement "$d/requirement.md" "$dam" >> "$tmp"
  [ -f "$d/design.md" ] && check_design "$d/design.md" >> "$tmp"
  [ -f "$d/tasks.md" ]  && check_tasks  "$d/tasks.md"  >> "$tmp"
  [ "$dam" = "标准" ] && check_verification "$d/verification.md" >> "$tmp"
done < <(find "$SPECS_DIR" -type f -name 'requirement.md' -not -path '*/archive/*')

if [ -s "$tmp" ]; then
  sort "$tmp"
  printf '违规计数: %s\n' "$(wc -l < "$tmp" | tr -d ' ')"
  exit 1
fi
exit 0
