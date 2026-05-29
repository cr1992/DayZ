---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# 验证：data-layer

> 跨任务质量校验。命中：加密（NF3）、性能（NF1, NF2, NF3）、多端（NF4）、类型安全（NF5）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 全新启动建库 | 全新安装 → 启动 | db 文件创建、6 张常规表 + entries_fts 虚拟表 + 全部索引存在 | R1, R2 | 自动 |
| 加密验证 | 打开后 hexdump 首 16 字节 | 不含 `SQLite format 3\0` 明文 magic | R2 | 自动 |
| 时间线分页 | 插入 50 条，分两页取 | 两页合计 50 条不重不漏，顺序正确 | R5, NF1 | 自动 |
| 往年今日 | 插入跨年 3 条同月日，查询 | 按 local_year desc 返回 3 条 | R5, NF2 | 自动 |
| 时区重算 | 创建条目后编辑 entry_tz | 三冗余字段同步重算 | R4 | 自动 |
| 软删除 | softDelete 后 list | 不返回该行 | R6 | 自动 |
| rekey + 重开 | rekey 新密钥 → 重新打开 | 新密钥成功 / 旧密钥失败 | R8 | 自动 |

## 专项检查

### 性能（NF1, NF2, NF3）
- [ ] 时间线分页查询 EXPLAIN QUERY PLAN 命中 `idx_entries_timeline` — 自动：`flutter test test/data/explain_test.dart::timeline`
- [ ] 往年今日 EXPLAIN QUERY PLAN 命中 `idx_entries_monthday` — 自动：`flutter test test/data/explain_test.dart::on_this_day`
- [ ] 10000 条 entries 库时间线单次 30 条查询 < 100ms（中端真机）— 人工（@Ray），数据来源 T14 demo 内的基准模式
- [ ] 加密相比明文开销不显著（同基准 < 1.5× 明文耗时）— 人工（@Ray），可选

### 加密（NF3 of M1 + R2）
- [ ] db 文件首 16 字节不含明文 magic — 自动 hexdump
- [ ] 错误密钥触发 `WrongKeyException` — 自动
- [ ] db 操作过程无任何明文密钥落盘（包括 WAL / journal 文件）— 人工（@Ray）目视审计

### 多端（NF4）
- [ ] iOS 真机能打开加密 db 并完成 CRUD — 人工（@Ray），通过 T14 demo 验证
- [ ] Android 真机同上 — 人工（@Ray）
- [ ] db 路径在两端均为 `<app_documents>/db/main.sqlite`（相对路径一致）— 自动

### 类型安全（NF5）
- [ ] Repository 公开 API 无 `Map<String, dynamic>` / `dynamic` 出现 — 自动：`grep -n 'dynamic\|Map<String' lib/data/repositories/`
- [ ] 时间字段统一 `DateTime`（UTC） — 自动 grep / 单测

## 回归检查

- [ ] M1 verification 中的 `grep TODO(data-layer-integration) lib/security/rekey_service.dart` 现在应**无匹配**（被 T13 替换）— 自动
- [ ] M1 模块单元测试仍通过 — 自动：`flutter test test/security/`
- [ ] Debug Home 中 Security demo 仍可演示，且新增了 Data demo — 人工（@Ray）

## 验证命令（汇总自动项）

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
! grep -RIn 'TODO(data-layer-integration)' lib/security/
```
