#!/usr/bin/env bash
set -euo pipefail
# -----------------------------------------------------------------------------
# archive_spec.sh — 把一个进行中的 spec 三步原子归档（在 repo 根运行）。
#
# 用途：① 物理搬目录 active/<name> -> archive/<YYYY-MM-DD>-<name>（--cancelled
#         则前缀 cancelled-）；② 把 specs/README.md「进行中」表里该功能行剪到
#         「已归档」表（填结果 / 归档日期）；③ 把该行链接及全仓库其余对
#         active/<name> 的引用一并改到新归档路径；④ 跑 check_dead_links.sh，
#         发现死链则非 0 退出并提示。
# 用法：  archive_spec.sh <功能名> [--cancelled]
#         （SPECS_DIR 默认 ./specs，可由环境变量覆盖；须在 repo 根运行。）
# 退出码：0=归档完成且无死链；1=违规/无法可靠改 README（fail-safe，打印手工步骤）；
#         2=用法或环境错误（参数缺失 / 源目录不存在 / 目标已存在等）。
# 强制规范：specs/README.md 是功能生命周期的唯一来源；归档须保持其与磁盘、
#         与全仓库引用三者一致，且不得遗留死链（见 spec-guide「归档」一节）。
# 注意：README 表结构若无法可靠定位，仅完成①后打印精确手工 ②③ 步骤并以退出码 1
#         提醒（宁可让人补，也不乱改破坏 README）。日期用 `date +%F`。
# -----------------------------------------------------------------------------

# ---- 0. 解析参数 -------------------------------------------------------------
NAME=""
CANCELLED=0
for arg in "$@"; do
  case "$arg" in
    --cancelled) CANCELLED=1 ;;
    -h|--help)
      sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 2 ;;
    --*)
      printf '错误：未知选项 %s\n' "$arg" >&2
      exit 2 ;;
    *)
      if [ -z "$NAME" ]; then
        NAME="$arg"
      else
        printf '错误：多余的参数 %s（一次只能归档一个功能）\n' "$arg" >&2
        exit 2
      fi
      ;;
  esac
done

if [ -z "$NAME" ]; then
  printf '用法：archive_spec.sh <功能名> [--cancelled]\n' >&2
  exit 2
fi

# 防御：功能名不应含路径分隔符或空白（避免越权 mv / 注入 sed）。
case "$NAME" in
  */*|*' '*|.|..)
    printf '错误：非法功能名 "%s"（不得含 / 或空白）\n' "$NAME" >&2
    exit 2 ;;
esac

# ---- 1. 定位目录与脚本 -------------------------------------------------------
SPECS_DIR="${SPECS_DIR:-specs}"
# 去掉末尾斜杠，便于拼接（POSIX sed）。
SPECS_DIR="$(printf '%s' "$SPECS_DIR" | sed 's#/*$##')"

ACTIVE_DIR="$SPECS_DIR/active/$NAME"
README="$SPECS_DIR/README.md"

# check_dead_links.sh 与本脚本同目录（POSIX 方式取脚本所在目录，避免 readlink -f）。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEAD_LINKS="$SCRIPT_DIR/check_dead_links.sh"

TODAY="$(date +%F)"
PREFIX=""
[ "$CANCELLED" -eq 1 ] && PREFIX="cancelled-"
ARCHIVED_BASENAME="${PREFIX}${TODAY}-${NAME}"
ARCHIVE_DIR="$SPECS_DIR/archive/$ARCHIVED_BASENAME"

# 表/链接里用到的相对片段（相对 specs/README.md 与相对 repo 根两种写法都要覆盖）。
LINK_OLD_REL="active/$NAME"                 # specs/README.md 内的写法
LINK_NEW_REL="archive/$ARCHIVED_BASENAME"
PATH_OLD_REPO="$SPECS_DIR/active/$NAME"     # repo 根其余引用写法
PATH_NEW_REPO="$SPECS_DIR/archive/$ARCHIVED_BASENAME"

# ---- 2. 环境校验 -------------------------------------------------------------
if [ ! -d "$ACTIVE_DIR" ]; then
  printf '错误：源目录不存在：%s（请在 repo 根运行，或用 SPECS_DIR 覆盖）\n' "$ACTIVE_DIR" >&2
  exit 2
fi
if [ -e "$ARCHIVE_DIR" ]; then
  printf '错误：归档目标已存在：%s（疑似今日已归档过同名功能）\n' "$ARCHIVE_DIR" >&2
  exit 2
fi
mkdir -p "$SPECS_DIR/archive"

# ---- 步骤 ①：物理搬移目录 ----------------------------------------------------
mv "$ACTIVE_DIR" "$ARCHIVE_DIR"
printf '① 已搬移：%s -> %s\n' "$ACTIVE_DIR" "$ARCHIVE_DIR"

# fail-safe：若 README 无法可靠改写，打印精确手工步骤并以退出码 1 提醒（不乱改）。
manual_steps_and_exit() {
  reason="$1"
  cat >&2 <<EOF

==============================================================================
 ②③ 自动改写已跳过：$reason
     目录搬移（①）已完成，但 README 表 / 引用需手工补齐，以免破坏文档。
 请手工执行：
   ② 编辑 ${README}：
      - 从「进行中」表删除该功能整行（含 ${LINK_OLD_REL} 链接的那行）；
      - 在「已归档」表新增一行：
          | [${NAME}](${LINK_NEW_REL}/) | <填结果，如：已完成> | ${TODAY} |
   ③ 把全仓库对旧路径的引用改到新路径：
        ${LINK_OLD_REL}   ->  ${LINK_NEW_REL}    （specs/README.md 内）
        ${PATH_OLD_REPO}  ->  ${PATH_NEW_REPO}   （其余文件内）
      可参考：grep -rl '${PATH_OLD_REPO}' .
   ④ 再跑：${DEAD_LINKS}
==============================================================================
EOF
  exit 1
}

# ---- 步骤 ②：README「进行中」行剪切到「已归档」表 ----------------------------
if [ ! -f "$README" ]; then
  manual_steps_and_exit "找不到 $README"
fi

# 先定位「进行中 / 已归档」两个表头；缺任一或顺序异常则不敢动表（fail-safe）。
IN_PROGRESS_LN="$(awk '/^## .*进行中/{print NR; exit}' "$README" || true)"
ARCHIVED_LN="$(awk '/^## .*已归档/{print NR; exit}' "$README" || true)"
if [ -z "${IN_PROGRESS_LN}" ] || [ -z "${ARCHIVED_LN}" ]; then
  manual_steps_and_exit "${README} 缺少「## 进行中」或「## 已归档」表头，无法可靠剪切"
fi
if [ "${IN_PROGRESS_LN}" -ge "${ARCHIVED_LN}" ]; then
  manual_steps_and_exit "${README}「进行中」表头不在「已归档」之前，结构异常，无法可靠剪切"
fi

# 在「进行中」表区间内定位指向该功能的表行：
#   - 行号严格介于两个表头之间（排除顶部说明文字里的同名引用）；
#   - 行须形似表行（以 | 起头）；
#   - 用 index() 固定字符串匹配 ]( active/<name> ，避免正则元字符问题。
# 这样顶部「见 [foo](active/foo/)」这类说明引用不会被误当成表行；它们由步骤③统一改链。
TARGET_NR="$(awk -v needle="]($LINK_OLD_REL" -v lo="$IN_PROGRESS_LN" -v hi="$ARCHIVED_LN" '
  NR > lo && NR < hi && $0 ~ /^[ \t]*\|/ && index($0, needle) > 0 { print NR }
' "$README" || true)"
ROW_COUNT="$(printf '%s\n' "${TARGET_NR}" | grep -c . || true)"

if [ "${ROW_COUNT}" -ne 1 ]; then
  if [ "${ROW_COUNT}" -eq 0 ]; then
    manual_steps_and_exit "在 ${README}「进行中」表里找不到指向 ${LINK_OLD_REL} 的表行"
  else
    manual_steps_and_exit "在 ${README}「进行中」表里找到 ${ROW_COUNT} 行指向 ${LINK_OLD_REL}，无法唯一定位"
  fi
fi

# 结果文案：取消 -> 已取消；否则 -> 已完成。
RESULT="已完成"
[ "$CANCELLED" -eq 1 ] && RESULT="已取消"

# 构造已归档表的新行（统一格式：| [name](archive/dated/) | 结果 | 归档日期 |）。
NEW_ARCHIVE_ROW="| [$NAME]($LINK_NEW_REL/) | $RESULT | $TODAY |"

# 用 awk 原子重写 README：
#   - 跳过目标进行中行（删除）；
#   - 在「已归档」表头后、其表头与分隔线之后的第一处数据行前插入新行。
# 已归档表结构假定为：`## ...已归档` -> 表头行(|...|) -> 分隔行(|---|) -> 数据行。
# 我们在分隔行之后立刻插入新行（成为已归档表第一条数据），保持表合法。
TMP="$README.archive_spec.tmp.$$"
awk -v target_nr="$TARGET_NR" \
    -v arch_ln="$ARCHIVED_LN" \
    -v newrow="$NEW_ARCHIVE_ROW" '
  BEGIN { inserted = 0; sep_seen = 0 }
  NR == target_nr { next }                 # 删除进行中目标行
  {
    print
    # 进入已归档表后：找到表头分隔行（含 ---- 的 | 行），其后插入新行一次。
    if (!inserted && NR > arch_ln) {
      if ($0 ~ /^\|[ :|-]*-[ :|-]*\|$/) {  # 形如 |------|------|
        print newrow
        inserted = 1
      }
    }
  }
  END {
    if (!inserted) {
      # 没找到分隔行（表为空或异常）——交由外层 fail-safe 处理。
      print "__ARCHIVE_SPEC_NOT_INSERTED__"
    }
  }
' "$README" > "$TMP"

if grep -q '__ARCHIVE_SPEC_NOT_INSERTED__' "$TMP"; then
  rm -f "$TMP"
  manual_steps_and_exit "${README}「已归档」表缺少表头分隔行，无法可靠插入新行"
fi

mv "$TMP" "$README"
printf '② 已更新 %s：进行中行 -> 已归档表（结果：%s，归档日期：%s）\n' "$README" "$RESULT" "$TODAY"

# ---- 步骤 ③：改写引用 --------------------------------------------------------
# ③a：specs/README.md 内刚搬到已归档表那行的链接 active/<name> -> archive/<dated>
#      （上面 NEW_ARCHIVE_ROW 已直接写成新链接，README 自身无需再替换）。
# ③b：全仓库其余对旧路径的引用。优先按 repo 根写法 specs/active/<name> 替换；
#      同时兜底替换裸 active/<name>（仅在确含 specs/ 前缀难判时，逐文件保守处理）。
#
# 用 grep -rl 找出仍含旧 repo 路径的文件（README 已处理，排除之），逐个用 awk 做
# 固定字符串替换（避免 sed -i 跨平台差异与正则元字符问题）。
replace_in_file() {
  f="$1"; from="$2"; to="$3"
  t="$f.archive_spec.tmp.$$"
  awk -v from="$from" -v to="$to" '
    {
      line = $0
      out = ""
      while ((p = index(line, from)) > 0) {
        out = out substr(line, 1, p - 1) to
        line = substr(line, p + length(from))
      }
      print out line
    }
  ' "$f" > "$t" && mv "$t" "$f"
}

CHANGED_COUNT=0
# 找含 repo 根写法引用的文件（排除 .git，排除二进制由 grep -I 处理）。
# grep -rl 没有匹配时退出码非 0，用 || true 吞掉以兼容 set -e。
REFS="$(grep -rlI --exclude-dir=.git -- "$PATH_OLD_REPO" . 2>/dev/null || true)"
if [ -n "$REFS" ]; then
  # 逐行读取文件名（文件名理论上不含换行，spec 仓库可接受该假设）。
  printf '%s\n' "$REFS" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    replace_in_file "$f" "$PATH_OLD_REPO" "$PATH_NEW_REPO"
    printf '③ 已改引用：%s（%s -> %s）\n' "$f" "$PATH_OLD_REPO" "$PATH_NEW_REPO"
  done
  CHANGED_COUNT=1
fi

# specs/README.md 内可能仍有「裸」active/<name>（如顶部说明文字里引用），
# 这些不带 specs/ 前缀，单独保守替换（仅限 README，且替成相对 archive 写法）。
if grep -qI -- "]($LINK_OLD_REL" "$README" 2>/dev/null || grep -qI -- "($LINK_OLD_REL" "$README" 2>/dev/null; then
  replace_in_file "$README" "($LINK_OLD_REL/" "($LINK_NEW_REL/"
  replace_in_file "$README" "($LINK_OLD_REL)" "($LINK_NEW_REL/)"
  printf '③ 已改 %s 内裸 %s 链接 -> %s\n' "$README" "$LINK_OLD_REL" "$LINK_NEW_REL"
fi

[ "$CHANGED_COUNT" -eq 0 ] && printf '③ 未发现 %s 的其余引用，跳过。\n' "$PATH_OLD_REPO"

# ---- 步骤 ④：死链检查 --------------------------------------------------------
if [ ! -x "$DEAD_LINKS" ] && [ ! -f "$DEAD_LINKS" ]; then
  printf '警告：未找到 %s，跳过死链检查（请手工核验）。\n' "$DEAD_LINKS" >&2
  printf '归档完成（①②③ 已做，④ 跳过）：%s\n' "$ARCHIVE_DIR"
  exit 0
fi

printf '④ 运行死链检查：%s %s\n' "$DEAD_LINKS" "$SPECS_DIR"
if bash "$DEAD_LINKS" "$SPECS_DIR"; then
  printf '归档完成且无死链：%s\n' "$ARCHIVE_DIR"
  exit 0
else
  printf '错误：死链检查未通过（见上）。①②③ 已写入，请按报告修复后重跑 ④。\n' >&2
  exit 1
fi
