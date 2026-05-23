---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# 验证：auto-save-draft

> 跨任务质量校验。命中：数据完整性（NF1）、防抖准确性（NF2）、生命周期同步（NF3）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 防抖保存 | 输入 → 停顿 1.5s | editing_session 写入对应 draft | R1 | 自动 |
| 连续输入合并 | 间隔 500ms 输入 3 次 → 停 | 仅一次保存（防抖合并） | R1 | 自动 |
| paused 强制保存 | 输入后立刻切后台 | editing_session 立即写最新 | R2 | 自动 |
| 内容无变化跳过 | 相同 payload 多次 fire | db 写次数为 0 | R6 | 自动 |
| 启动检测 | 残留 editing_session → 启动 | startupCheck.hasResidual=true | R7 | 自动 |
| 启动检测无残留 | 无 editing_session → 启动 | hasResidual=false | R7 | 自动 |
| 切换 target 先 flush | onChanged(A) → onChanged(B) | A 先写盘，B 后写盘 | R3, D3 | 自动 |
| 失败重试 | 模拟 db 失败 3 次 | 第 4 次仍失败时异常入队 | R5 | 自动 |

## 专项检查

### 数据完整性（NF1）
- [ ] 任何崩溃场景下 editing_session JSON 都可 `jsonDecode` — 自动：T6 crash_recovery_test 集成
- [ ] paused 钩子是 await 同步等待（不是 fire-and-forget） — 自动：grep `await coordinator.forceFlush`

### 性能（NF2, NF3）
- [ ] 防抖窗口测试中位耗时 1450-1700ms — 自动：fakeAsync + 真实 Timer 对比
- [ ] paused 钩子到 upsert 完成 < 100ms（中端真机，100 KiB draft） — 人工（@Ray）

### 单行模型不变式
- [ ] editing_session 表始终至多一行 — 自动：T6 中插入多次后查询 count = 1
- [ ] 不存在多 targetId 并发未 flush — 自动：T3 串行队列测试覆盖

## 回归检查

- [ ] M2 EditingSessionRepo 单测仍通过 — 自动：`flutter test test/data/editing_session_repo_test.dart`
- [ ] Debug Home 中 Security / Data / Media demo 仍可演示，Drafts demo 新增 — 人工（@Ray）

## 验证命令（汇总自动项）

```bash
flutter analyze
flutter test test/drafts/
flutter test
```
