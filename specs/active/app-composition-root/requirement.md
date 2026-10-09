---
作者：@Ray
创建日期：2026-10-09
---

# app-composition-root

## 背景
各屏 spec 只交付「可注入 Repo 的页面组件」，`ui-shell-navigation` 只交付路由表与外壳，二者之间的**生产装配**无人认领：`main.dart` 打开的数据库只喂给草稿协调器；`Routes.timeline` 等全部挂 `PlaceholderScreen`；抽屉日记本列表与「新建日记本」只活在内存；`EntryRepo.timeline` 不支持按日记本过滤，月计数 / 有条目日（timeline-screen D4）无数据源。结果是时间线页已写完、测试全绿，冷启动却仍是占位屏。本 spec 专管这层装配，让已交付的屏挂上真实加密库。

## 范围外
- 主密码解锁 UI / 锁屏流程 MUST NOT 在本 spec 实现（归后续 settings / lock-screen spec，见 design 已知风险）。
- 各屏页面内部交互（顶栏按钮、日历面板、卡片）MUST NOT 在本 spec 改，归各屏 spec（时间线归 timeline-screen T5/T7）。
- 阅读 / 编辑 / 搜索等未交付屏 MUST NOT 在本 spec 内实现，仍挂占位，随各屏 spec 交付后按本 spec 的装配方式接入。

## 需求

### R1 · 单库装配
The 应用 SHALL 在进程内只打开一次 `AppDatabase`，草稿协调器与全部 Repo 共用该实例，并经组合根向 UI 树提供。

### R2 · 时间线挂真实数据
When 应用冷启动且数据库可用, the 应用 SHALL 在 `Routes.timeline` 渲染 `TimelinePage`，数据来自加密库中的条目。
- 前提：库内有 N 条未删除条目
- 操作：冷启动
- 结果：时间线按月分组展示这些条目；空库时展示时间线空态，不再展示「待页面级 spec 实现」占位

### R3 · 日记本来自数据库
The 抽屉日记本列表 SHALL 来自 `JournalRepo`（含每本未删除条目篇数）；When 用户在「新建日记本」表单提交, the 应用 SHALL 将其写入数据库并刷新抽屉列表。

### R4 · 按日记本过滤与月度计数走 SQL
When 当前日记本切换, the 时间线 SHALL 只展示该日记本的条目（「全部」= 不过滤），过滤 MUST 在数据库查询层完成而非逐页拉全量再筛；月份篇数与日历「有条目日」SHALL 来自数据库按月计数查询（落实 timeline-screen D4）。

### R5 · 顶栏单一归属
Where 页面自带 sliver 顶栏（当前为时间线）, the 外壳 SHALL NOT 再叠加自己的顶栏；其余仍挂占位的路由保持外壳顶栏不变。

### R6 · 真机示例数据入口
Where 处于 debug 构建, the Debug Home SHALL 提供向真实加密库写入一批跨多月示例条目、以及清空示例条目的入口，供编辑器交付前真机走查时间线。

### 专项维度表态

| 专项维度 | 命中？ | 依据 |
|---|---|---|
| 安全 | 否 | 不改密钥派生 / 加密方案，只复用既有 `AppDatabase.open(KeyProvider)`；解锁 UI 列范围外 |
| 权限 | 否 | 不申请任何系统权限 |
| 无障碍 | 否 | 不新增交互控件（示例数据入口为 debug 工具） |
| 性能 | 否 | 无新增可度量阈值；R4 的「SQL 层过滤」是正确性约束 |
| 多端兼容 | 否 | 纯 Dart 装配，无平台分支 |

跨多模块：否（文件变更全在 `dayz` 单包内 `lib/` 与 `test/`、`integration_test/`）。→ 精简档。
