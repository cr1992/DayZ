---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
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
- [ ] **NF1 真红线主断言**：`redactAbsolutePath`（验值）+ Redactor 对 message / fields 两路径脱敏，输出不含密钥字节 / 正文原文 / 绝对前缀 — 自动：`flutter test test/observability/redaction_test.dart`
- [ ] （**best-effort tripwire，非主闸**）全 `lib/` 粗筛是否有疑似把敏感词打进日志调用 — 半自动：命中**需 @Ray 人工判定**是否真实泄漏（不当硬 fail）。已知局限：grep/rg 无法平衡括号 → 本 spec 力推的惰性闭包 `logFine(() => ...)` 体内拼接为**漏报**、子串可能误伤；故仅作辅助 tripwire，真红线靠上一条 + 落盘端到端行为测：
  ```bash
  # 加词边界减 hotkey/keyboard/mediaKeyId 误伤;路径精确排除脱敏真源;命中=人工核查而非自动 fail
  rg -nE '(print|debugPrint|log[A-Za-z]*)\(.*(\bkey\b|\bpassword\b|\bsecret\b|\btoken\b|\bderived\b|content_json|content_plain)' lib --glob '*.dart' --glob '!lib/observability/redaction.dart' || echo '(无命中=通过)'
  ```
- [ ] 含绝对路径输入经门面落盘后读回不含绝对前缀 — 自动：`flutter test test/observability/rotating_file_sink_test.dart`（端到端：门面 Redactor + file sink 集成，断言落盘文件字节不含 `/var/mobile`/`/data/data` 等绝对前缀，对应 NF1 在落盘路径成立）
- [ ] `lib/observability/` 不 import DB 层（日志写入不进 DB 事务的架构前提） — 自动：`! rg -nE '(package:drift|dayz/data/|\.\./data/)' lib/observability`（覆盖绝对包路径 + 相对 `../data/`，命中即 fail，对应 NF3）
- [ ] `lib/observability/` 无任何遥测 / 网络上报 — 自动：`! rg -niE '(sentry|crashlytics|firebase_crashlytics|HttpClient|http\.(get|post)|\bSocket\b|package:dio)' lib/observability`（`package:dio` 收紧避免 audio/studio 子串误伤，命中即 fail，对应 NF5）
- [ ] 新增运行时依赖仅 `logging`、无遥测包 — 人工(@Ray)：审 `pubspec.yaml` diff，确认本 spec 仅新增 `logging`（对应 NF5）
- [ ] 业务层不绕过门面直接 import `package:logging`（脱敏唯一信任根，D4） — 自动：
  ```bash
  ! { rg -n 'package:logging' lib --glob '*.dart' | rg -v '^lib/observability/'; }
  ```

### 性能（NF2, NF4）
- [ ] 落盘 size 轮转上限：写超阈值后文件数 ≤ 保留份数、每文件 ≤ 软上限、总量 ≤ 硬上限、最旧已删 — 自动：`flutter test test/observability/rotating_file_sink_test.dart`（对应 NF2）
- [ ] 热路径零格式化开销：级别 = INFO 时 `logFine(() => sideEffect())` 不求值（计数器 = 0），级别 = FINE 时求值一次 — 自动：`flutter test test/observability/lazy_level_test.dart`（对应 NF4）

### 兼容性（NF7）
- [ ] iOS 13+ 真机：Debug Home observability 触发日志 + 强制轮转，日志文件生成、轮转份数正确、App 未崩溃 — 人工(@Ray)
- [ ] Android 8+ 真机：同上 — 人工(@Ray)
- [ ] 应用私有诊断目录不可写时按 NF3 降级、不静默崩溃 — 自动 + 人工(@Ray)

### 不进备份（NF6，含跨 spec 联测占位）
- [ ] 日志根目录解析自 ApplicationSupport 下 `logs/`、与备份收录根前缀不重叠 — 自动：`flutter test test/observability/log_paths_test.dart`（本 spec 侧目录隔离断言）
- [ ] **跨 spec 联测占位（待 `backup-full-snapshot` 落地）**：构造备份包后断言其清单不含 `logs/` 任何文件 — 归 `backup-full-snapshot` 的 verification 落地（本 spec 暴露 `logsSubdir` 常量供其收录白名单排除）；此处登记为对下游 backup spec 的约束，backup 落地后联测勾选。

## 回归检查
- [ ] observability 全模块单元测试通过 — 自动：`flutter test test/observability/`
- [ ] 静态分析无新增告警 — 自动：`flutter analyze`
- [ ] 全 App 构建无破坏（iOS + Android 双端） — 自动：`flutter build apk --debug && flutter build ios --debug --no-codesign`
- [ ] Debug Home demos 列表完整、observability 为末位、`DemoEntry` 字段未改 — 自动：`flutter test test/demo/observability_demo_test.dart`（断言 `demos.last` 为 observability 入口、字段未改）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，确保无遗漏。任一项不通过则 verification 未定稿。
- [ ] 正向：R1（门面分发 / 过滤场景）、R2（安全 NF1 脱敏）、R3（落盘场景 + 性能 NF2）、R4（降级场景 + 安全 NF3）、R5（LogSink 契约场景 + D4 边界守卫）、R6（Debug Home 场景 + 兼容性 NF7）、NF1（安全专项）、NF2（性能专项）、NF3（安全专项 + 降级场景）、NF4（性能专项）、NF5（安全专项）、NF6（不进备份专项）、NF7（兼容性专项）均有覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实存在的 R / NF；回归检查（构建 / analyze / demos 完整性）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter pub get
flutter test test/observability/   # 含 NF1 redaction_test、NF2/NF3 rotating_file_sink/sink_failure、NF4 lazy_level 等行为断言
flutter analyze
# 架构 / 上报 缺失守卫（断言"缺失"，命中即 fail，扫业务代码非被改文件自身）
! rg -nE '(package:drift|dayz/data/|\.\./data/)' lib/observability                                  # NF3:不 import DB 层(含相对路径)
! rg -niE '(sentry|crashlytics|firebase_crashlytics|HttpClient|http\.(get|post)|\bSocket\b|package:dio)' lib/observability   # NF5:无遥测/上报
! { rg -n 'package:logging' lib --glob '*.dart' | rg -v '^lib/observability/'; }                    # D4:业务层不绕过门面
# NF1 脱敏:真红线靠上面 redaction_test 行为测;下面全 lib 关键词扫描为 best-effort tripwire(命中人工判定,非自动 fail)
rg -nE '(print|debugPrint|log[A-Za-z]*)\(.*(\bkey\b|\bpassword\b|\bsecret\b|\btoken\b|\bderived\b|content_json|content_plain)' lib --glob '*.dart' --glob '!lib/observability/redaction.dart' || echo '(无命中=通过)'
# spec 链接 / 构建
bash spec-kit/scripts/check_dead_links.sh specs
flutter build apk --debug && flutter build ios --debug --no-codesign
```

> 与 `key-management` 守卫的关系（防漂移）：`key-management/verification.md` 的安全守卫覆盖 `lib/security`（并校验"密钥使用后清零"等正向行为），本 spec 的全 `lib/` 守卫是其覆盖面的扩展、二者互补。本 spec MUST NOT 改动 `key-management/verification.md`；若未来两处守卫正则需统一，由独立维护任务收敛，不在本里程碑跨 spec 改文件。
