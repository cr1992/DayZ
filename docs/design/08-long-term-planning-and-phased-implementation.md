## 11. 远期能力（预留，暂不实现）

- **同步**：Supabase（最快验证）/ PowerSync / ElectricSQL（SQLite↔Postgres 双向）/ CRDT（Automerge、Yjs，富文本并发合并最佳但成本高）。富文本 JSON 并发冲突合并是难点，故预留 CRDT。**注意 CRDT 路径受编辑器选型决定**（TipTap/ProseMirror ↔ Yjs 原生咬合；AppFlowy 走自有 Rust 同步），见第 4 节对比表。
- **端到端加密**：复用第 9 节 Argon2id 派生模块，服务器只存密文。**Argon2id 移动端参数需实测调参**，并预研期先验证 Dart 侧库（多为 FFI 绑定）的维护活跃度。
- **全文搜索**：FTS 索引本地、明文、不上传，已天然兼容加密。**⚠️ 中文非轻活**：默认 fts5 tokenizer 对中文几乎不可用（“上海”搜不出”在上海吃饭”），须改用 **ICU 或 trigram tokenizer**——别当成”接个 FTS 就好”。

数据模型已预留：稳定 UUID、`created_at`/`updated_at`、软删除墓碑、`sync_status`、`server_rev`，确保后期加同步无需痛苦迁移。

-----

## 12. 分阶段计划

**阶段一 · MVP 主干**

- 数据层（Drift + SQLCipher）+ schema + Repository 封装
- 本机随机密钥 + Keystore 无感解锁 + Argon2id 派生模块
- 时间线（虚拟滚动 + 分组吸顶 + 游标分页）
- 往年今日
- 媒体存储（文件系统 + 元数据 + 加密）
- 编辑器先用简易版/纯文本占位
- 自动保存与草稿恢复（`editing_session` 单行 + paused 钩子）
- 缩略图缓存层（生成/加密/失效/滚动节流）
- 备份：**全量单文件快照**（`.mydiary` 加密包）+ 还原（覆盖式，缩略图懒生成）+ JSON 备份

**阶段二 · 编辑器与体验**

- 编辑器预研选型（A/B）并集成 + JSON 契约定稿 + Flutter 只读渲染器
- 撤销/重做接入（复用编辑器 history；WebView 方案需桥接按钮状态）
- 原生相册/相机选图链路
- 位置、天气、标签、收藏
- 给人看的归档：PDF / HTML
- 每日本地通知（往年今日）
- 文件类型关联（双击备份包唤起 App 还原）
- **持久备份目标 + media 增量**（先确立持久目标概念，再做增量与备份瘦身）

**阶段三 · 远期**

- 同步层选型与实现 + E2E 加密（复用派生模块）
- 全文搜索（FTS，中文需 ICU/trigram tokenizer）
- 桌面端评估（如需）
- 按需将图片处理/PDF 渲染下放 Rust

-----

