---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
---

# observability（可观测性 · 日志基建）

## 背景

应用代码尚未铺开，当前没有任何日志库，`lib/demo/` 下只有零散 `debugPrint`。但多个已立 spec 已经隐式依赖"记日志"与"脱敏"能力：`auto-save-draft` R5 要求保存失败超阈值 MUST 记录日志；`media-storage` NF5 要求任何对外暴露的 API（含异常 message / 日志）MUST 使用相对路径、不出现绝对路径；`key-management` NF1 要求密钥不入日志。这些约束散落在各 spec，却没有一个统一的承载者。

本 spec 立一个**零依赖的横切诊断底座** `lib/observability/`（第八个模块目录，定位比 `lib/security/` 更横切——谁都可依赖它、它不依赖任何业务模块）：以 dart.dev 官方 `logging` 包为薄内核，自建 `AppLogger` 门面集中管控**级别、脱敏、输出目标**，作为全模块共用的记日志入口与脱敏真源。

经 @Ray 拍板的上层取舍（2026-05-30）：① 日志**必须支持落盘**；② 落盘本里程碑走**脱敏明文**，静止态加密做成后置可插拔扩展点（见 design D3 与 NF6 升级路径，理由：日志已被门面强制脱敏、存应用私有沙箱、不进备份，敏感度远低于始终加密的 db/media 本体，且让底座零依赖、不被 P0 的 `key-management` 阻塞）；③ 全局未捕获异常钩子（崩溃栈落盘）范围外、后续单列 spec；④ 落盘容量基线 1 MiB × 3 ≈ 3 MiB；⑤ release 默认级别 INFO。

## 范围外

- **静止态加密落盘**：本里程碑只交付脱敏明文落盘 + 预留 `LogSink` 加密扩展点；`EncryptedFileSink` 实现与其所需 `getLogKey()` 入口属后续衍生 spec。`getLogKey()` 实现 MUST 归 `key-management`（D7 已框定 `key-management` 独占 `lib/security/{hkdf,key_provider}.dart` 写权），本 spec MUST NOT 改动 `lib/security/`。
- **生产 main.dart 门面接线**：何时在真实 App 启动流程里调 `attachFileSink()`（让生产环境落盘）属后续"生产接线 spec"。本里程碑门面零配置默认可用（仅 console），file sink 仅在 Debug Home（T8）装配；下游 import 门面即得 console 日志，**生产落盘须等接线 spec 显式 attach**（见 design D10，不留隐含缺口）。
- **全局未捕获异常钩子**（`FlutterError.onError` / `PlatformDispatcher.onError` 接入 + 崩溃栈脱敏落盘）：崩溃栈最易夹带敏感片段，脱敏口径需单独认真设计，后续单列 spec。
- **App 内"导出 / 分享日志"入口**：导出会让脱敏日志离开沙箱，与隐私优先 / 不进备份的基调有张力；本 spec 只在 Debug Home 内查看，不提供导出。
- **远程上报 / 遥测**：见 NF5，硬禁（MUST NOT）。
- **终端用户可见的日志查看 UI**：待设计稿；本 spec 仅提供 Debug Home 开发入口。
- **各业务模块在哪些点打什么日志**：由各模块自身 spec 决定，本 spec 只提供门面与规约。
- **结构化日志上报到分析平台 / 审计日志 / 用户行为埋点**：不做。

## 功能需求

### R1 · AppLogger 门面与分级
系统 SHALL 提供单一日志门面 `AppLogger`，以 dart.dev `logging` 包为薄内核，集中管控级别、脱敏与输出目标（sink 列表）。门面 SHALL 暴露分级 API（FINE / INFO / WARNING / SEVERE，**每个级别均有惰性闭包重载** `logFine(() => '...')`）及 `isLoggable(level)` 守卫；默认级别按 `kReleaseMode` 分流（release = INFO，debug = FINE），并 SHALL 支持运行时调级别。门面 MUST NOT 暴露吞任意对象的 `log(Object)` 这类口子（防 `logging` 包 `toString` 绕过脱敏）。完整公开 API 签名、event 码类型（自由 `String`）、时间戳来源（门面盖戳 + 可注入时钟）以 design「门面对外 API 契约」为准。门面零配置默认可用（构造即挂 ConsoleSink）。
- 前提：App 启动；`AppLogger` 零配置默认可用（无需显式 init 即可记 console 日志）
- 操作：调用方在不同级别记一条日志
- 结果：≥ 当前生效级别的记录被分发到所有已注册 sink；< 生效级别的记录被丢弃；调用方无需关心 sink 细节

### R2 · 门面强制脱敏与 redactAbsolutePath 真源
系统 SHALL 在 `AppLogger` 门面统一执行脱敏中间件（Redactor）：任何 `LogSink` 收到的都 SHALL 是**已脱敏记录**（一处正确、处处正确）。Redactor SHALL 对 message（自由文本）与 fields（结构化）**分别**脱敏：message 走正则（绝对路径前缀 + 值位敏感模式 `key=`/`secret=` 等），fields 走 key 名 / 字段名匹配（敏感键值置 `***`、`content_json`/`content_plain` → `<redacted:len=N>`）——具体规则见 design D2。系统 SHALL 提供 `redactAbsolutePath(String) -> String` 纯函数作为绝对路径脱敏的**推荐真源**（供 `media-storage` 等复用；是否接入由对侧 spec 决定，接入前不断言两处不漂移）。脱敏的可观测红线见 NF1。
- 前提：调用方记录一条含设备绝对路径 / 结构化字段的日志
- 操作：记录流经门面 Redactor
- 结果：sink 与落盘文件中绝对路径被替换为相对路径或 `<app-private>` 占位；不含任何密钥字节、不含日记正文原文

### R3 · 脱敏明文落盘（RotatingFileSink）
When 启用 file sink 且产生 ≥ 当前级别的日志，the 系统 SHALL 将**脱敏后**记录异步追加落盘到应用私有诊断目录（`getApplicationSupportDirectory()` 下 `logs/`），并按 size 轮转（见 NF2）。落盘文件 SHALL 为 UTF-8、每条记录一行（`\n` 分隔）、文件名 `app.log` / 轮转份 `app.log.1..N`（格式契约见 design）；file sink SHALL 暴露 `flush()` / `close()`（异步落盘可被 await）。落盘目录 SHALL 位于备份扫描范围之外（见 NF6）。file sink 经一次异步 `attachFileSink()` 注册，attach 完成前的日志只走 console（见 R4 / design D10）。本里程碑落盘为脱敏明文。
- 前提：file sink 已 attach、诊断目录可写
- 操作：记若干条 ≥ 生效级别的日志
- 结果：`logs/` 下生成日志文件、内容为脱敏明文、可被开发者直接读取排障

### R4 · 落盘失败降级、不反噬业务、不进 DB 事务
If file sink 的任何 IO / 轮转失败（磁盘满 / 权限 / 目录不可写），then the 系统 SHALL 在 sink 内部捕获并吞掉异常、自动降级为"仅 console 输出"、向 console 发一条降级告警（该告警 MUST NOT 再触发落盘，防递归）并累加一次内部降级计数。`AppLogger` 的任一日志调用 MUST NOT 抛异常——含**未初始化 / file sink attach 完成前**的调用：此时 SHALL 仅走 console、MUST NOT 抛、MUST NOT 丢（见 design D10）。日志写入 MUST NOT 出现在任何 Drift / SQLCipher 事务边界内（咬合 `docs/design/09`：文件 IO 不在 DB 事务内）。可观测约束见 NF3。
- 前提：业务调用方在某流程中记日志，此时 file sink 底层 IO 必失败
- 操作：调用 `AppLogger.log` / `logFine`
- 结果：调用不抛、正常返回；业务后续逻辑照常执行；console 仍有输出且降级计数 +1

### R5 · LogSink 抽象与加密扩展点预留
系统 SHALL 通过 `LogSink` 抽象接口接入输出目标，门面只认该抽象、不 import `lib/security` / `lib/data` / `drift`。本里程碑默认实现为 `ConsoleSink`（零依赖）与脱敏明文 `RotatingFileSink`。`LogSink` 抽象 SHALL 预留加密落盘扩展点，使未来 `EncryptedFileSink` 是**新增实现**（加法）而非内核改写；其实现与 `getLogKey()` 入口属后续 spec（`getLogKey()` 归 `key-management`），本里程碑不实现。
- 前提：门面持有 sink 列表
- 操作：注册 / 替换某个 `LogSink` 实现
- 结果：门面对新 sink 透明工作；加密升级时内核（级别 / 脱敏 / 轮转契约）零改动

### R6 · Debug Home 调试入口
系统 SHALL 在 Debug Home 的 `demos` 列表**末尾追加**一个 observability 入口（不修改 `DemoEntry` 字段），可触发各级别日志、强制轮转、查看 file sink 降级状态，供真机多端核查（NF7）。
- 前提：App 启动进入 Debug Home
- 操作：进入 observability 入口并操作各按钮
- 结果：可观察到不同级别日志的产生 / 过滤、落盘文件随强制轮转变化、降级计数显示

## 非功能需求

### NF1 · 日志绝不含密钥 / 正文 / 绝对路径（脱敏不可绕过）
任何级别、任何 sink（console / 落盘文件）输出的日志 MUST NOT 包含：① 任何派生 / 随机密钥或口令字节；② 日记正文（`content_json` / `content_plain`）原文或片段；③ 设备绝对路径（如 `/var/mobile/...`、`/data/data/...`）。脱敏 MUST 在 `AppLogger` 门面统一执行，任何 `LogSink` 只接收已脱敏记录；绝对路径 MUST 经 `redactAbsolutePath` 脱敏为相对路径或 `<app-private>` 占位（与 `media-storage` NF5 同口径）。
> 度量与守卫见 verification 安全专项：redactAbsolutePath 单测（验值）、Redactor 行为测、全 `lib/` 缺失守卫（扩自 `key-management` 仅覆盖 `lib/security` 的守卫）、落盘集成测。
> 诚实声明：脱敏是 best-effort——类型化门面 + Redactor + 守卫显著抬高门槛，但无法 100% 防"把敏感串硬拼进自由文本 message"的对抗式滥用；本 spec MUST NOT 向用户 / 审计承诺"绝对脱敏"。

### NF2 · 落盘大小有硬上限（轮转）
file sink MUST 实施 size-based 轮转：单文件大小 MUST ≤ 软上限（基线 1 MiB），保留份数 MUST ≤ 固定值（基线 3），日志总占用 MUST ≤ 确定硬上限（基线 ≈ 3 MiB），不得无限增长；超限自动轮转、删最旧。阈值 / 份数 / 总量 MUST 集中为一处常量。

### NF3 · 落盘失败不影响业务、不进 DB 事务
file sink 的任何 IO / 轮转失败 MUST 被内部捕获、降级为仅 console 并发一次降级告警（告警 MUST NOT 再触发落盘），绝不向调用方抛出；`AppLogger` 的任一日志调用 MUST NOT 抛异常。日志写入 MUST NOT 出现在任何 DB 事务边界内，且 `lib/observability/` MUST NOT import `package:drift` / `lib/data`。

### NF4 · 热路径 release 零格式化开销
低于当前生效级别的日志（如 release 默认 INFO 下的 FINE）MUST 在格式化 / 脱敏前被丢弃，其惰性闭包参数 MUST NOT 被求值；热路径（时间线滚动、自动保存防抖、缩略图任务队列）MUST 通过惰性闭包 API 或 `isLoggable` 守卫调用。

### NF5 · 零远程上报
`lib/observability/` MUST NOT 引入任何把日志 / 堆栈 / 事件外传的网络上报（Crashlytics / Sentry / 自建 HTTP 上报一律禁止）；MUST NOT 依赖任何遥测 / 网络上报包；唯一持久化目标是本地文件。本 spec 因日志而引入的新增依赖 MUST 仅为 dart.dev `logging`。

### NF6 · 日志不进备份（+ 加密扩展点预留）
日志文件 MUST NOT 被打进备份包（诊断派生数据，类比缩略图 / FTS，依据 `docs/design/06` §9.4）；日志落盘根目录 MUST 位于备份扫描范围之外（`ApplicationSupport` 下 `logs/`，与 db / media 备份收录根隔离），并 MUST 暴露日志根目录常量供 `backup-full-snapshot` 排除。`LogSink` 抽象 MUST 预留加密落盘扩展点（升级路径见 design D3，本里程碑不实现）。
> 本 spec 只能在本侧断言"日志根目录解析自 ApplicationSupport 且与备份收录根前缀不重叠"；真正的"备份包不含日志"断言归 `backup-full-snapshot` 的 verification（跨 spec 联测占位）。

### NF7 · 多端落盘一致
file sink SHALL 在 iOS 13+ 与 Android 8+ 上均能解析到可写的应用私有诊断目录并成功落盘 + 轮转；目录不可写时按 NF3 降级，不静默崩溃。

## 专项维度逐维表态（选档依据）

> 按规范 §0「逐维表态」对 5 个专项维度各显式表态一次，任一为「是」即升标准档。本 spec 命中 **安全 / 性能 / 多端**，已为**标准档**（含 NF1–NF7、verification.md、文件头文档状态、README 索引）。

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 是 | NF1 脱敏红线（密钥 / 正文 / 绝对路径绝不进日志）、NF5 零远程上报、NF6 不进备份，核心即隐私安全。 |
| 权限 | 否 | 不引入用户角色 / 访问控制；落盘走系统沙箱的应用私有目录，无权限分级。 |
| 无障碍 | 否 | 本 spec 无终端用户 UI（仅 Debug Home 开发入口）；终端可见的日志查看 UI 属范围外、待设计稿。 |
| 性能 | 是 | NF4 给出"热路径低于生效级别零格式化开销"的可度量行为约束，落盘异步不阻塞 UI。 |
| 多端兼容 | 是 | NF7 要求 iOS 13+ / Android 8+ 落盘 + 轮转一致，目录不可写时降级不崩溃。 |
