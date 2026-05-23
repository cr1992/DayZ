## 3. 数据存储层（定稿）

### 3.1 选型结论与理由

主库 **Drift**（SQLite 之上的类型安全 ORM），不选 NoSQL（Isar/ObjectBox/Hive）的原因：

- **招牌功能全是关系型查询**：游标分页、`month/day` 匹配往年今日、标签多对多 join、按条件筛选导出——SQL 的主场，NoSQL 要绕。
- **稳定性压倒性能**：日记是低频写入，不需要 NoSQL 的高吞吐；而 Isar/Hive 曾被原作者搁置转社区维护，存放用户多年人生的 App 不宜押注维护状态不明的库。ObjectBox 性能最强但非完全开源、不支持 Web，定位偏 IoT/POS 高频写入，与需求错位。
- **生态与演进**：Drift 文档完善、内置 migration 机制；远期 PowerSync 可与 Drift 配合做离线同步，为同步留好平滑路径，届时无需换库。

**关于”写 SQL 复杂”的澄清**：Drift 提供 Dart 风格查询 API（`select/where/orderBy/limit` 方法链，编译期检查 + 自动补全），90% 查询无需手写 SQL；表结构也用 Dart 类定义。本方案中的 `CREATE TABLE` 仅用于表达设计意图，实际由 Drift 生成。落地时所有数据库操作集中封装在 Repository 层，页面代码只调用如 `repo.onThisDay(5, 23)` 这样的方法，看不到查询细节。

### 3.2 三层存储职责

- **日记本体**（条目、媒体元数据、标签、关系、搜索）→ **Drift / SQLite（SQLCipher 加密）**
- **敏感小数据**（本机数据库密钥、备份相关口令）→ **flutter_secure_storage**（钥匙串/Keystore）
- **普通设置**（主题、排序、上次打开的笔记本）→ **shared_preferences**

> 关于 MMKV：它是高性能键值存储，等同”强化版 shared_preferences”，**没有查询能力，不能替代数据库**。仅可用于设置存储层，但日记本体场景下 shared_preferences 已足够，无引入必要。

-----

## 5. 数据库 Schema（定稿）

原则：**按”将来一定要做同步和加密”设计，但只预留字段不实现同步。**

关键决策：

- **主键 TEXT UUID（推荐 UUID v7，时间有序、索引友好）**，避免多设备冲突，且为备份还原提供去重判断依据。
- **区分”日记发生时刻”与”行创建时刻”**：`entry_dt_utc`（可编辑/回填）≠ `created_at`（不可变）。**回填/编辑 `entry_dt_utc` 或 `entry_tz` 时，`local_year/month/day` 三个冗余字段必须同步重算**（不只是首次写入时算好，编辑路径别漏，否则往年今日/分组会错位）。
- **时区三件套**：UTC 瞬间 + IANA 时区 + 本地年月日拆字段冗余（写入算好，查询命中索引）。
- **内容存两份**：`content_json`（编辑器 JSON）+ `content_plain`（纯文本，供搜索/预览/标题）。
- **媒体存文件系统**，库内只存相对路径 + 宽高。
- **全部软删除**（`deleted_at`）：既是同步墓碑，也是**增量备份能捕获”删除”的前提**。

```sql
CREATE TABLE journals (
  id          TEXT PRIMARY KEY NOT NULL,
  name        TEXT NOT NULL,
  color       TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  deleted_at  INTEGER
);

CREATE TABLE entries (
  id            TEXT PRIMARY KEY NOT NULL,      -- UUID v7
  journal_id    TEXT REFERENCES journals(id),
  content_json  TEXT NOT NULL DEFAULT '',       -- 编辑器文档 JSON
  content_plain TEXT NOT NULL DEFAULT '',       -- 抽取的纯文本

  entry_dt_utc  INTEGER NOT NULL,               -- epoch 毫秒, UTC, 排序/同步
  entry_tz      TEXT    NOT NULL,               -- IANA, 如 'Asia/Shanghai'
  local_year    INTEGER NOT NULL,
  local_month   INTEGER NOT NULL,               -- 1-12  ┐ 往年今日/分组
  local_day     INTEGER NOT NULL,               -- 1-31  ┘ 写入时算好

  lat           REAL,
  lng           REAL,
  place_name    TEXT,
  weather_code  TEXT,
  weather_temp  REAL,

  is_favorite   INTEGER NOT NULL DEFAULT 0,

  created_at    INTEGER NOT NULL,               -- 行创建, 不可变
  updated_at    INTEGER NOT NULL,               -- 最近一次本地编辑（增量备份水位线依据）
  deleted_at    INTEGER,                        -- NULL = 存活（软删除墓碑）
  sync_status   INTEGER NOT NULL DEFAULT 0,
  server_rev    TEXT
);

CREATE TABLE media (
  id          TEXT PRIMARY KEY NOT NULL,        -- 被文档 JSON 引用
  entry_id    TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  kind        TEXT NOT NULL,                    -- image/audio/video
  rel_path    TEXT NOT NULL,                    -- 原文件相对路径（密文，设备密钥）
  mime        TEXT,
  width       INTEGER,                          -- 原图宽高，占位防滚动跳动
  height      INTEGER,
  duration_ms INTEGER,
  file_size   INTEGER,

  -- 缩略图缓存层（派生数据，不进备份，见 9.4）
  thumb_path  TEXT,                             -- 缩略图相对路径（密文）；NULL=未生成
  thumb_w     INTEGER,
  thumb_h     INTEGER,
  thumb_src_updated_at INTEGER,                 -- 生成缩略图时所依据的原图 updated_at
                                                -- 与原图当前 updated_at 不一致 = 缩略图过期需重建

  updated_at  INTEGER NOT NULL,                 -- 原文件最近变更（缩略图失效判断依据）
  created_at  INTEGER NOT NULL,
  deleted_at  INTEGER
);

CREATE TABLE tags (
  id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL,
  created_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE TABLE entry_tags (
  entry_id TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  tag_id   TEXT NOT NULL REFERENCES tags(id)    ON DELETE CASCADE,
  PRIMARY KEY (entry_id, tag_id)
);

CREATE INDEX idx_entries_timeline ON entries(entry_dt_utc DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_entries_monthday ON entries(local_month, local_day) WHERE deleted_at IS NULL;
CREATE INDEX idx_entries_updated  ON entries(updated_at);          -- 增量备份用
CREATE INDEX idx_entries_sync     ON entries(sync_status);
CREATE INDEX idx_media_entry      ON media(entry_id);
CREATE INDEX idx_entrytags_tag    ON entry_tags(tag_id);

CREATE VIRTUAL TABLE entries_fts USING fts5(content_plain);       -- 本地, 永不上传
-- ⚠️ 默认 tokenizer 对中文几乎不可用（"上海"搜不出"在上海吃饭"）；
--    真做搜索时须改用 ICU 或 trigram tokenizer，详见第 11 节。

-- 编辑现场（自动保存暂存 + 崩溃恢复依据，见 7.3）
-- 【单行模型·定稿】固定单行（同一时刻只允许一个编辑现场）。多草稿并行列为非目标。
CREATE TABLE editing_session (
  id          TEXT PRIMARY KEY NOT NULL,        -- 固定常量主键（如 'current'），全表至多一行
  target_id   TEXT,                             -- 正在编辑的 entry id；NULL = 新建中
  draft_json  TEXT,                             -- 未提交的文档 JSON
  cursor_pos  INTEGER,                          -- 光标位置（可选）
  is_new      INTEGER NOT NULL DEFAULT 0,       -- 是否新建中
  updated_at  INTEGER NOT NULL
);
-- 残留行 = 上次异常退出；正常保存退出时清空本表
-- 切换编辑目标前必须先完成当前保存（覆盖该单行），不保留多份并行草稿
```

### 招牌功能查询验证

```sql
-- 时间线游标分页（(时刻,id) 元组游标，避免同时刻漏/重）
SELECT * FROM entries
WHERE deleted_at IS NULL AND (entry_dt_utc, id) < (?, ?)
ORDER BY entry_dt_utc DESC, id DESC LIMIT 30;

-- 往年今日
SELECT * FROM entries
WHERE deleted_at IS NULL AND local_month = ? AND local_day = ?
ORDER BY local_year DESC;
```

### 实战避坑

- **媒体存相对路径，不存绝对路径**：iOS 沙盒容器 UUID 重装/恢复后会变，绝对路径会全部失效致”图片集体丢失”。运行时用”当前媒体目录 + rel_path”拼接。
- **`entries_fts` 只存本地、不参与备份/同步**：天然兼容加密——上传/备份的是密文，本机解密后维护明文索引。
- 不把图片塞进 SQLite blob；标题取 `content_plain` 第一行。

-----

