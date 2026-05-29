---
作者：@Ray
创建日期：2026-05-29
---

# 任务列表：vendored 第三方包本地改动留痕

## 依赖速览
> 以各任务 inline「依赖」字段为准。
T1（标记） + T2（脚本，并行） → T3（CHANGELOG 台账依赖 T1 的 ID） → T4（约定） → T5（对账验收）

-----

- [x] T1 · 回填历史改动的成对标记

**依赖：** 无 ｜ **关联需求：** R1, R4 ｜ **依据设计：** D1, D2, D4 ｜ **可改文件：** `packages/appflowy-editor/lib/**`（仅加注释，不改逻辑）

### 背景
用干净基线（`~/.pub-cache/hosted/pub.dev/appflowy_editor-6.2.0/lib`）`diff -rq` 比对 vendored 源码，定位全部本地改动，逐个分配稳定 ID 并补成对标记。纯 `dart format` 风格差异不分配 ID。

### 实施
1. `diff -rq` 干净基线与 `packages/appflowy-editor/lib`，得到差异文件清单。
2. 对每个有逻辑改动的文件分配 ID：P001 图片插入聚焦、P002 选区折叠无 delta 移动、P003 退格前置非文本节点、P004 onFocusReceived 兼容。
3. 在改动区间首尾加 `// >>> DAYZ-PATCH[Pxxx]: 原因` … `// <<< DAYZ-PATCH[Pxxx]`。

### 验收标准（做完即止）
- 4 个 patch（P001-P004）均有成对标记，P002 三处共用一个 ID（自动）。
- 仅加注释，未改任何逻辑（自动：注释外的代码与改前一致）。

### 禁止
- 不改任何业务逻辑；不给纯 format 差异分配 ID。

### 验收方式
- 自动：
  ```bash
  bash scripts/check_patches.sh   # 第 [1/3] 段「所有标记成对闭合」通过
  ```

### 验收记录
```
日期：2026-05-29
自动：check_patches.sh 第[1/3]段「所有标记成对闭合」通过；P001-P004 标记成对（P002 三处共用）
人工：—（无）
```

-----

- [x] T2 · 编写对账脚本 check_patches.sh

**依赖：** 无 ｜ **关联需求：** R3 ｜ **依据设计：** D3 ｜ **可改文件：** `scripts/check_patches.sh`

### 背景
脚本三段：成对校验（栈式括号匹配）、代码 ID 必在 CHANGELOG（漏记 exit 1）、CHANGELOG 有但代码无（告警 exit 0）。

### 实施
1. 扫描 `packages/appflowy-editor/lib`，收集 `>>>`/`<<<` 标记，按文件做栈式匹配。
2. 提取代码 ID 集合与 CHANGELOG ID 集合。
3. 三段判定与退出码：成对错误/漏记 → exit 1；有记录无标记 → 告警 exit 0。

### 验收标准（做完即止）
- 当前仓库运行退出 0（自动）。
- 删一条 CHANGELOG 记录 → exit 1（自动）。
- 未闭合标记 → exit 1（自动）。
- CHANGELOG 多一个代码无标记的 ID → 告警且 exit 0（自动）。

### 验收方式
- 自动：
  ```bash
  bash scripts/check_patches.sh; test $? -eq 0
  ```

### 验收记录
```
日期：2026-05-29
自动：退出 0；删 P003 记录→exit 1；删 P004 闭合标记→exit 1；加 P099→WARN+exit 0，均符合预期
人工：—（无）
```

-----

- [x] T3 · 扩展 CHANGELOG 为 Patch 台账并回填定位

**依赖：** T1 ｜ **关联需求：** R2, R4 ｜ **依据设计：** D1, D4 ｜ **可改文件：** `packages/CHANGELOG.md`

### 背景
为每个 patch ID 补：ID + 文件定位（路径 + 函数/符号）+ 原因 + 关联 + upstream issue；并在头部记录基线版本 6.2.0 与留痕约定。

### 实施
1. 头部加留痕约定说明与基线版本号。
2. 新增「Patch 台账（按 ID）」段，P001-P004 各一条带定位。
3. 旧的按日期变更历史补 patch ID 交叉引用（含修正旧版误记的提交号）。

### 验收标准（做完即止）
- 代码中每个 patch ID 在 CHANGELOG 均有一条带文件定位的记录（自动）。

### 验收方式
- 自动：
  ```bash
  bash scripts/check_patches.sh   # 第 [2/3]、[3/3] 段均 OK
  ```

### 验收记录
```
日期：2026-05-29
自动：check_patches.sh 第[2/3]「均已登记」、第[3/3]「都有对应代码标记」均通过
人工：—（无）
```

-----

- [x] T4 · AGENTS.md 补 vendored 包改动约定

**依赖：** T1, T2, T3 ｜ **关联需求：** R5 ｜ **依据设计：** D3 ｜ **可改文件：** `AGENTS.md`

### 背景
在「本项目专有约定」加一条：改 `packages/` 下 vendored 包 MUST 打 DAYZ-PATCH 成对标记 + 记 `packages/CHANGELOG.md` + 跑 `check_patches.sh`。

### 实施
- 在专有约定的「本地 Package 修改规范」处补充三件套要求与脚本命令。

### 验收标准（做完即止）
- AGENTS.md 含「DAYZ-PATCH」「check_patches.sh」字样（自动）。

### 验收方式
- 自动：
  ```bash
  grep -q 'DAYZ-PATCH' AGENTS.md && grep -q 'check_patches.sh' AGENTS.md
  ```

### 验收记录
```
日期：2026-05-29
自动：grep 命中 DAYZ-PATCH 与 check_patches.sh
人工：—（无）
```

-----

- [x] T5 · 端到端对账验收

**依赖：** T1, T2, T3 ｜ **关联需求：** R3, R4 ｜ **依据设计：** D3 ｜ **可改文件：** （无新增，仅运行验收）

### 背景
跑通整套机制：正常退出 0；故意制造漏记/不成对能 exit 1。

### 实施
1. `bash scripts/check_patches.sh` 应 exit 0。
2. 临时删一条 CHANGELOG 记录或一处闭合标记，确认 exit 1，随后还原。

### 验收标准（做完即止）
- 正常状态 exit 0（自动）。
- 故意删一条 CHANGELOG 记录后 exit 1（自动）。

### 验收方式
- 自动：
  ```bash
  # 1) 正常通过
  bash scripts/check_patches.sh; test $? -eq 0
  # 2) 故意删 P003 记录应报错（在副本上验证，不污染源文件）
  cp packages/CHANGELOG.md /tmp/CL.bak
  grep -v 'P003' packages/CHANGELOG.md > /tmp/cl.tmp && mv /tmp/cl.tmp packages/CHANGELOG.md
  bash scripts/check_patches.sh; test $? -eq 1 && echo "FAIL-CASE OK"
  cp /tmp/CL.bak packages/CHANGELOG.md   # 还原
  bash scripts/check_patches.sh; test $? -eq 0
  ```

### 验收记录
```
日期：2026-05-29
自动：正常 exit 0；删 P003 后 exit 1（FAIL-CASE OK）；还原后 exit 0
人工：—（无）
```
