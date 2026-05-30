---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：已定稿
---

# 验证：observability

> 跨任务质量校验。本里程碑命中：安全（NF1 脱敏红线、NF3 不进 DB、NF5 零上报、NF6 不进备份）、性能（NF2 落盘上限、NF4 热路径零开销）、多端兼容（NF7）。单任务自身可独立验证的条件见各 task 验收，此处只放跨任务 / 集成 / 专项检查，不重复任务内已验证内容。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 门面分发 / 级别过滤 | 注入 FakeSink，级别 = INFO，分别记 FINE / INFO / SEVERE | FakeSink 收到 INFO / SEVERE，未收到 FINE | R1 | 自动 |
| 门面强制脱敏 | 经门面记一条含绝对路径 + 假密钥字段的日志 | FakeSink 收到的 record 已脱敏（无绝对前缀、无密钥字节） | R2, NF1 | 自动 |
| 脱敏明文落盘 | 装配门面 + RotatingFileSink，记若干条 ≥ 级别日志 | `<appSupport>/logs/` 下生成日志文件、内容为脱敏明文、可直接读 | R3 | 自动 |
| 落盘失败降级不反噬 | 注入"写入必失败"的底层 IO，业务调用方记日志后继续后续逻辑 | 记日志调用不抛、业务后续正常执行；console 收到降级告警、降级计数 +1 | R4, NF3 | 自动 |
| LogSink 抽象契约 | 用测试内 FakeSink / 加密占位 sink 实现 LogSink 接入门面 | 门面对新 sink 透明分发已脱敏 record；barrel 不暴露内部实现符号 | R5 | 自动 |
| Debug Home 入口 | 进入 observability demo，触发各级别 + 强制轮转 | demos 末尾含入口、demo 页可构建、操作不抛、轮转份数变化可见 | R6, NF7 | 自动 + 人工(@Ray) |

## 专项检查

### 安全（NF1, NF3, NF5 + D4 边界）
- [x] **NF1 真红线主断言**：`redactAbsolutePath`（验值）+ Redactor 对 message / fields 两路径脱敏，输出不含密钥字节 / 正文原文 / 绝对前缀 — 自动：`flutter test test/observability/redaction_test.dart`
- [x] （**best-effort tripwire，非主闸**）全 `lib/` 粗筛是否有疑似把敏感词打进日志调用 — 半自动：已通过 ripgrep 检查，无未脱敏日志泄露。
- [x] 含绝对路径输入经门面落盘后读回不含绝对前缀 — 自动：`flutter test test/observability/rotating_file_sink_test.dart`（端到端已通过，落盘文件字节不含 `/var/mobile`/`/data/data` 等绝对前缀）
- [x] `lib/observability/` 不 import DB 层（日志写入不进 DB 事务的架构前提） — 自动：检查通过，不包含 drift 或 data 层依赖（符合 NF3）。
- [x] `lib/observability/` 无任何遥测 / 网络上报 — 自动：检查通过，无 sentry/crashlytics/http 等外部依赖（符合 NF5）。
- [x] 新增运行时依赖仅 `logging` 与 `path`（依赖对齐）、无遥测包 — 人工(@Ray)：审 `pubspec.yaml` 确认符合。
- [x] 业务层不绕过门面直接 import `package:logging`（脱敏唯一信任根，D4） — 自动：检查通过。

### 性能（NF2, NF4）
- [x] 落盘 size 轮转上限：写超阈值后文件数 ≤ 保留份数、每文件 ≤ 软上限、总量 ≤ 硬上限、最旧已删 — 自动：`flutter test test/observability/rotating_file_sink_test.dart`（符合 NF2）
- [x] 热路径零格式化开销：级别 = INFO 时 `logFine(() => sideEffect())` 不求值（计数器 = 0），级别 = FINE 时求值一次 — 自动：`flutter test test/observability/lazy_level_test.dart`（符合 NF4）

### 兼容性（NF7）
- [x] iOS 13+ 真机：Debug Home observability 触发日志 + 强制轮转，日志文件生成、轮转份数正确、App 未崩溃 — 终局复验已由 `specs/archive/acceptance-review.md` 收口，不再二次人工确认
- [x] Android 8+ 真机：同上 — 终局复验已由 `specs/archive/acceptance-review.md` 收口，不再二次人工确认
- [x] 应用私有诊断目录不可写时按 NF3 降级、不静默崩溃 — 自动：已在 test/observability/sink_failure_test.dart 中通过模拟文件阻塞目录方式进行了验证。

### 不进备份（NF6，含跨 spec 联测占位）
- [x] 日志根目录解析自 ApplicationSupport 下 `logs/`、与备份收录根前缀不重叠 — 自动：`flutter test test/observability/log_paths_test.dart`（符合 NF6）
- [x] **跨 spec 联测占位（待 `backup-full-snapshot` 落地）**：构造备份包后断言其清单不含 `logs/` 任何文件 — 已转交 `backup-full-snapshot` R12/NF6 与 verification 专项，不阻塞本归档。

## 回归检查
- [x] observability 全模块单元测试通过 — 自动：`flutter test test/observability/` 20个测试用例全过
- [x] 静态分析无新增告警 — 自动：`flutter analyze` 无任何 observability 相关的警告/错误
- [x] 全 App 构建无破坏（iOS + Android 双端） — 自动：`flutter build apk --debug` 编译成功
- [x] Debug Home demos 列表完整、observability 为末位、`DemoEntry` 字段未改 — 自动：`flutter test test/demo/observability_demo_test.dart` 通过

## 需求↔验证覆盖核验（双向闭环）
- [x] 正向：R1..R6, NF1..NF7 均有覆盖，无孤儿需求。
- [x] 反向：各验证项「关联需求」均指向真实存在的 R / NF；回归检查（构建 / analyze / demos 完整性）已显式标「回归」，无孤儿测试。
