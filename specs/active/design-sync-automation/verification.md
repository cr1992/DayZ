---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：design-sync-automation

> 本 spec 跨两期：**期一（M1）可验项**列下；**期二项**（Phase 3/4 harness）须首屏存在才可跑，标「期二·deferred」，待实现时填。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| Phase 1 路由 | 喂各类 diff fixture | 输出受影响屏/组件清单、同输入同输出 | R1, NF2 | 自动（期一）|
| 实质变更检测 | 喂新类名/缺geometry/新data-when/DOM重排 fixture | 各自命中实质档；纯 ignore 类不命中 | R5, NF2 | 自动（期一）|
| Phase 2 token 重生 | tokens.css 变 fixture | check_sync→gen→回归；不漂移 | R2 | 自动（期一）|
| 对比度 xfail 区分 | 模拟 xfail 三条红 / allowlist 外新红 | 三条 advisory 不 wedge；新红 block | R2 | 自动（期一）|
| pinned 巡检 | pinned 落后+源屏diff非空 / pinned=HEAD | 前者报待同步、后者不报 | R3, R8 | 自动（期一）|
| 维护态泳道 override | 读 overlay + AGENTS 指针 | 屏 spec 入「已交付·随设计维护」、不归档；未碰 vendored spec-kit | R7, R8 | 自动(死链+git diff)+人工(@Ray) |
| 屏对齐自修复 | 改源屏→工作流对齐 | 闸①②③绿→合并；红耗尽→build fail | R6, NF1 | **期二·deferred** |
| cap 有界 | 注入不收敛屏 | 轮次≤cap 后升实质档/人工，不空转 | R6, NF3 | **期二·deferred** |

## 专项检查

### 确定性（NF2）
- [ ] Phase 1 路由 + 三检测器对同一 fixture **多次运行输出一致**（可脚本复算）— 自动：`flutter test test/sync/route_detect_test.dart`（期一）
- [ ] 三档分流由检测器布尔确定性派生（无 agent 介入分流）— 自动：同上（期一）

### 验证分级（NF1）
- [ ] 闸①②③ 任一红 → 该屏 build fail（硬闸）— **期二·deferred**（须 harness）
- [ ] 闸④ 低分 → SYNC_REPORT 标红、不阻塞（advisory）— **期二·deferred**
- [ ] 闸③ 对 content-driven 只断 order/contains/no-overflow、不断块高（minik 换行差异不触发失败）— **期二·deferred**

### 有界资源（NF3）
- [ ] 自修复循环每屏 ≤ cap=min(3,budget)，耗尽即升实质档/人工 — **期二·deferred**

> 数据迁移 / 回滚：无持久化 schema 变更或数据格式演进 → 整段省略（不涉及）。
> 安全/权限/无障碍/性能/多端：requirement 逐维表态均「否」，无对应专项（本 spec 调度其他 spec 的无障碍等验证，不自产）。

## 回归检查
- [ ] `specs/` 死链检查通过（T4 改了 overlay/README/通用源）— 自动：`bash spec-kit/scripts/check_dead_links.sh`（回归）
- [ ] 未改动 vendored `spec-kit/spec-guide.md`（override 走 DayZ-own overlay + AGENTS 指针）— 自动：`git diff --quiet spec-kit/spec-guide.md`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1/R5（路由+检测）、R2（token+xfail）、R3/R8（巡检+泳道）、R7（三档）、NF2（确定性）有**期一**验证覆盖；R6/NF1/NF3 有**期二·deferred**验证占位（标记明确、不冒充已覆盖）；R4（element-map 格式）由各页面级 spec 落 element-map 时验，本 spec 只定契约——无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（死链/通用源不变式）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项·期一）
```bash
flutter test test/sync/          # 路由/检测器/Phase2 token/xfail
bash test/sync/check_ui_sync_test.sh
bash spec-kit/scripts/check_dead_links.sh
# 期二（首屏落地后补）：闸①②③/④ harness + 自修复 cap 测试
```

> 共享测试基建说明：`test/sync/*_test.dart` 由白名单 hook 对 `test/**/*_test.dart` 无条件放行；非 `_test.dart` 的 `test/sync/fixtures/` 与 `test/sync/check_ui_sync_test.sh` 需预批，已在 T1/T2/T3 的 inline `验收基建` 字段列出（执行协议第 2 条）。
