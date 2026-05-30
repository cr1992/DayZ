---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-30
文档状态：草稿
---

# auto-save-draft（自动保存 + 草稿恢复 · 数据层与协调器）

## 背景

v6 第 7.3 节定调：自动保存与草稿恢复**共用同一张表（editing_session 单行模型）**——保存到表 = 草稿恢复的免费副产品。本里程碑落地保存机制、生命周期钩子、启动检测与协调器；UI 部分（顶部非阻断提示条、设置项「恢复未完成的编辑」）待设计稿，**仅在协调器中预留 status 输出供 UI 消费**。

整体依赖 **M0**（项目壳）、**M2 T11**（EditingSessionRepo 已暴露 CRUD）、**M2 T8**（EntryRepo 已有 update API 写入 content_json）。编辑器选型**已定 = 方案 A（AppFlowy Editor）**（@Ray 2026-05-29 拍板，见 `specs/README.md` 顶部 / `archive/2026-05-29-editor-research`）；**本里程碑提供编辑器中立接口**，把 AppFlowy 编辑器 onChanged 接到 DraftCoordinator.onChanged 的编辑页集成归后续 spec（待 UI 设计稿）。

## 范围外

- 顶部「未保存草稿」提示条 UI / 设置项 UI —— 待设计稿。
- 真正的富文本编辑器接入（已定 = 方案 A AppFlowy Editor）—— 编辑页/工具栏与本协调器对接归后续 spec（待 UI 设计稿）。
- 多草稿并行（v6 4.7 已定调为非目标）。
- 撤销 / 重做（v6 7.4 复用编辑器内置 history，与本里程碑解耦）。

## 功能需求

### R1 · 防抖保存触发（1.5s）
系统 MUST 提供 `Debouncer(duration: 1500ms)` 工具类，编辑器调用 `debouncer.fire(payload)` 后若 1500ms 内无新调用则触发保存。
- 前提：协调器已就绪
- 操作：连续 fire 三次（间隔 500ms），第三次后停顿
- 结果：仅触发一次保存，时间窗为「最后一次 fire + 1500ms」

### R2 · 生命周期 paused / inactive 触发可观察强制保存
系统 MUST 监听 `AppLifecycleState.paused` 与 `inactive`，触发立即强制保存（绕过防抖窗口），并 MUST 暴露本次保存的 `pendingFlush` Future 供测试与应用内可控路径 await。

Flutter 的 `AppLifecycleListener` 生命周期回调是同步 `void`，框架不会等待应用返回的 Future；本 spec **不承诺** OS / Flutter 在后台切换前等待写盘完成。系统 MUST 做到：
- `LifecycleBridge.handleLifecycleState(state) -> Future<void>` 是可 await 的测试/手动入口；对 paused / inactive 必须 await `DraftCoordinator.forceFlush()`。
- `AppLifecycleListener` 的 `void` 回调必须同步创建并保存 `pendingFlush`，不得丢弃 Future；失败必须进入可观察错误状态 / 日志。
- 应用内可控路径（退出编辑页、切换编辑目标、正式提交前）MUST 直接 await `forceFlush()` 或 `handleLifecycleState(...)`，不得 fire-and-forget。
- 前提：编辑现场有未提交变化
- 操作：触发 paused
- 结果：同一同步回调 turn 内创建 `pendingFlush`；await 该 Future 后，editing_session 已写入最新草稿。若进程在 `pendingFlush` 完成前被系统冻结 / 杀死，只保证不留下半截 JSON，不保证最新变化已落盘。

### R3 · DraftCoordinator 统一保存协调器
系统 MUST 提供 `DraftCoordinator`，封装：
- `onChanged({targetId?, draftJson, isNew, cursorPos?})` —— 编辑器变化时调用；内部走防抖
- `forceFlush() -> Future<void>` —— 强制保存；应用内可控路径 MUST await，系统生命周期桥接必须保存 returned Future
- `clear()` —— 退出且已正式提交时调（清 editing_session 那一行）
- `startupCheck() -> Future<DraftRecoveryStatus>` —— 启动时读 editing_session 判断状态
- `DraftRecoveryStatus { hasResidual: bool, targetId: String?, isNew: bool, lastUpdated: DateTime? }`

「单行模型」严格保留——切换编辑目标前 MUST 先 forceFlush + clear，**不允许两个 onChanged 调用对不同 targetId 同时未 flush**。

### R4 · 原子化写盘
EditingSessionRepo.upsert MUST 是原子的（Drift 事务）；写盘失败 MUST 不留半截 JSON。
- 前提：磁盘故障 / 进程崩溃
- 操作：写到一半中断
- 结果：表中或仍是上一份完整 JSON、或为空，**不出现部分 JSON**

### R5 · 失败静默重试
保存失败 MUST 静默重试（不弹窗打断书写）；重试次数 MUST ≤ 3 次；超过阈值 MUST 记录日志并丢到「保存异常」状态供 UI 消费（不在本里程碑显示）。
- 前提：磁盘满 / db 锁
- 操作：触发保存
- 结果：3 次重试后异常事件入队；用户继续输入不受打断

### R6 · 内容无变化跳过
保存前 MUST 比较新 draftJson 与上次已写入的 hash，无变化时跳过实际写盘。
- 前提：上次 draftJson hash = X
- 操作：再次 fire 同样的 draftJson
- 结果：实际不写 db；防抖窗内 fire 次数不变

### R7 · 启动检测残留
系统 MUST 在 `DraftCoordinator.startupCheck` 中读 editing_session 那一行：存在则 `hasResidual = true`；不存在则 false（性能约束见 NF4）。

### R8 · 编辑器中立接口
DraftCoordinator MUST 与具体编辑器解耦——只接受 `(targetId, draftJson, isNew, cursorPos)` 入参；不预设 AppFlowy / TipTap / TextField。选型已定 A（AppFlowy Editor），由后续编辑页集成 spec 把 AppFlowy 编辑器 onChanged 接到 DraftCoordinator.onChanged。

### R9 · WebView 方案预留通道（方案 A 下不适用，保留为远期 B 兜底）
> **选型已定（v0.7）**：MR 结论选 **方案 A（AppFlowy Editor，纯 Dart，无 WebView）**——见 `docs/design/03` 第 4 节末「选型补丁」与 `specs/active/editor-json-contract`。本项目无 WebView 桥，本需求**当前不适用**。
>
> 本需求的实质约束（DraftCoordinator 能接收来自**任意来源**的 onChanged、不预设来源）已被 **R8（编辑器中立接口）完全覆盖**——R8 的中立 payload 接口对 AppFlowy onChanged 与（假设的）WebView 桥推送一视同仁。故 R9 不引入任何额外接口或任务，仅作为**远期方案 B 兜底**保留：若将来弃 A 改 B，WebView 桥推送的 onChanged 可直接复用 R8 接口，无需改 DraftCoordinator。
>
> 验证归属：R9 无独立验收，由 R8 的「来源无关」验收覆盖（见 verification 单行模型/中立接口检查）。

## 非功能需求

### NF1 · 数据完整性
任何已进入 EditingSessionRepo 写盘事务的场景 MUST 保证 editing_session 表中是「完整可解析 JSON 或空」二选一。本 NF 在 verification 中以集成测试覆盖。

系统 paused / inactive 若在 `pendingFlush` 完成前被 OS 冻结或杀死，最新变化 MAY 尚未落盘；但表内已有内容仍 MUST 保持完整 JSON 或空，不得出现部分 JSON。

### NF2 · 性能 - 防抖窗口准确性
连续 fire 测试中，最后一次 fire 到实际保存调用之间间隔误差 MUST 在 1450-1700ms 内。

### NF3 · 性能 - 生命周期触发与 pending flush
`AppLifecycleListener` 收到 paused / inactive 后，`LifecycleBridge` MUST 在同一同步回调 turn 内创建 `pendingFlush` 并触发 `forceFlush()`；在应用仍存活的前提下，`pendingFlush` 从触发到 EditingSessionRepo.upsert 完成 MUST < 100ms（中端真机，单条 draft < 100 KiB）。

### NF4 · 性能 - 启动检测不阻塞主线程
`DraftCoordinator.startupCheck`（一次 db 查询）MUST 不阻塞主线程超过 50ms。本 NF 约束 R7 的启动检测，在 verification 中以性能检查覆盖。

## 专项维度逐维表态

> §0 选档：本表「性能」命中 → 升标准档（已含 NF / verification.md / 文件头 / README 索引）。

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 草稿写入复用 data-layer 既有加密 db，本 spec 不引入新的口令/密钥/敏感数据处理。 |
| 权限 | 否 | 不访问相册/相机/通知等系统权限，仅读写应用内 editing_session 表。 |
| 无障碍 | 否 | 本里程碑无 UI（提示条/设置项归后续 UI spec），无可聚焦/朗读控件可约束。 |
| 性能 | 是 | NF2 防抖窗口准确性、NF3 生命周期触发 + pending flush < 100ms、NF4 startupCheck 不阻塞主线程 > 50ms 均为可度量性能硬约束。 |
| 多端兼容 | 否 | 纯 Dart 逻辑层（Debouncer / 协调器 / 生命周期桥），无平台分叉代码；T7 真机跑测属验证手段非兼容性需求。 |
