---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-29
文档状态：草稿
---

# key-management（密钥管理）

## 背景

日记是用户的隐私核心，方案 v6 第 9 节定调「混合密钥 + 默认加密」：本机走设备随机密钥（无感解锁），备份走用户口令派生密钥（跨设备可恢复），未来 E2E 同步复用同一派生模块。所有后续模块（data-layer 的 SQLCipher、media-storage 的媒体加密、backup-full-snapshot 的备份口令派生）都依赖本里程碑提供的统一密钥入口与派生算法；因此必须先于 db 与媒体落地。

## 范围外

- 主密码 / 备份口令的 UI（设置页、输入框、错误提示）——待设计稿。
- 文件类型关联与备份包格式细节——属 backup-full-snapshot。
- 端到端同步加密——远期。
- 已设主密码状态下的「忘记密码 = 数据丢失」的用户教育文案——待设计稿。

## 功能需求

### R1 · 设备随机密钥生命周期
系统 MUST 在首次启动时生成 256-bit CSPRNG 随机密钥，存入系统钥匙串 / Keystore；后续启动 SHALL 自动读取，用户无感。
- 前提：全新安装、无任何旧密钥
- 操作：App 首次启动初始化数据层
- 结果：secure storage 中存在 `device_db_key` 条目；下次冷启动读取成功，无任何用户交互

### R2 · Argon2id 派生模块
系统 MUST 提供独立的 KDF 模块，签名为 `deriveKey(password, salt, params) -> bytes`，参数封装为 `KdfParams { mCostKiB, tCost, parallelism, outputLen, version }`，便于备份口令派生与远期 E2E 复用同一实现。
- 前提：调用方传入合法的 password / salt / params
- 操作：调用 `deriveKey`
- 结果：返回固定长度（默认 32 字节）密钥；相同输入必得相同输出（确定性）

### R3 · 应用主密码（可选）
用户 MAY 在功能上启用主密码（UI 在后续 spec 中接入）；启用后系统 SHALL 用 Argon2id 从主密码派生本机库密钥，启动时要求用户输入口令解锁；切换 / 修改密码 MUST 走 SQLCipher rekey（仅 db 重加密，媒体不动）。
- 前提：当前为「无主密码」模式，库以设备随机密钥加密
- 操作：用户启用主密码 X
- 结果：库经 rekey 后以 Argon2id(X) 派生密钥加密；模式状态持久化；下次冷启动需输入 X

### R4 · rekey 事务安全
rekey 操作 MUST 后台执行（isolate）+ 进度提示；MUST 事务安全，中途崩溃不得使库变成新旧密钥都打不开的砖头；失败 MUST 整体回滚。
- 前提：库正常打开，准备 rekey
- 操作：rekey 过程中 kill 进程
- 结果：重启后库仍可用旧密钥（或新密钥，二选一确定态）打开，绝不出现两把密钥都打不开的中间态

### R5 · 备份口令派生接口
系统 SHALL 暴露 `deriveBackupKey(password, salt) -> bytes` 接口，内部复用 R2 的 Argon2id 模块；备份口令可与主密码相同（用户选择），但调用层不预设关联。
- 前提：用户输入备份口令 P
- 操作：调用 `deriveBackupKey(P, salt)`
- 结果：返回备份加密用的对称密钥；相同输入必得相同输出

## 非功能需求

### NF1 · 密钥不落明文
任何派生 / 随机密钥 MUST 不以明文形式写入磁盘文件、日志、临时文件。明文仅在内存中存在；变量在使用后 SHOULD 主动清零（best-effort）。

### NF2 · Argon2id 移动端性能
v0 基线参数：m_cost = 64 MiB、t_cost = 3、parallelism = 1、outputLen = 32。
在中端设备（iPhone 11 / Pixel 4 同级）上单次 `deriveKey` MUST 在 1.5s 内完成；在低端设备（4GB RAM 同级）上 MUST 不发生 OOM。实测耗时与内存峰值 MUST 记录在 design.md 的 D3 决策备注或本里程碑的验收记录中。

### NF3 · 多端兼容
SHALL 在 iOS 13+ 与 Android 8+ 上正常工作。在 secure storage 或 Argon2 FFI 不可用的极端设备上 MUST 给出明确错误（不可静默退化为明文存储）。

### NF4 · 派生算法可演进
`KdfParams` MUST 含 `version` 字段；未来调参时旧密钥派生路径 MUST 仍可工作（按存储的 version 选择参数），新派生使用新版本。即不得「升级一次参数就让所有旧备份打不开」。

## 专项维度逐维表态（选档依据）

> 按规范 §0「逐维表态」对 5 个专项维度各显式表态一次，任一为「是」即升标准档。本 spec 命中安全/性能/多端，已为**标准档**（含 NF1-NF4、verification.md、文件头文档状态、README 索引）。

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 是 | 全 spec 核心即密钥生成/存储/派生，NF1 要求密钥不落明文、不入日志（见 R1/R2/NF1）。 |
| 权限 | 否 | 不引入用户角色 / 访问控制；secure storage 由系统钥匙串托管，本 spec 不做权限分级。 |
| 无障碍 | 否 | 本 spec 无 UI（主密码 / 备份口令输入 UI 属范围外、待设计稿），无障碍随后续 UI spec 评估。 |
| 性能 | 是 | NF2 给出 Argon2id 单次派生 < 1.5s 与低端机不 OOM 的可度量阈值，需真机实测（T3）。 |
| 多端兼容 | 是 | NF3 要求 iOS 13+ / Android 8+ 正常工作，secure storage 或 Argon2 FFI 不可用时给明确错误。 |
