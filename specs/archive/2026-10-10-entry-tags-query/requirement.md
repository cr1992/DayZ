---
作者：@Ray
创建日期：2026-10-10
最后更新：2026-10-10
文档状态：定稿
---

# entry-tags-query（条目标签批量查询）

## 背景

设计稿里时间线卡片、往年今日卡片都画了标签行，`DayzEntryCard` 也已支持 `tags`，但数据层只有逐条的 `TagRepo.listForEntry(entryId)`：时间线 `TimelineEntry.tags`、往年今日 `EntryCardVM.tags` 因此**永远为空**。逐条调 `listForEntry` 会在每页 / 每次加载里产生 N 次（甚至 2N 次）查询，不能放进列表取数路径。

`data-layer` 已于 2026-05-30 归档（见 [archive/2026-05-30-data-layer](../../archive/2026-05-30-data-layer/)），按「归档后返工 → 新建精简档」立本 spec（修复自 `data-layer`）。2026-10-09 拍板：先立这张，不在各屏 spec 里各自绕。

阅读屏（`reader-screen`）已在 `DataLayerReaderRepository` 里经 `listForEntry` 自取单条目标签，单条目场景无 N+1 问题，本 spec 不动它。

## 范围外

- 阅读屏取标签路径 MUST NOT 改动（已自取，单条目无 N+1）。
- 搜索屏 / 收藏屏 / 日历等尚未接真库的屏 MUST NOT 在本 spec 里接线；它们落地时直接复用 R1 的接口。
- 标签的增删改 UI、标签颜色 / 排序偏好 MUST NOT 在本 spec 里做。
- MUST NOT 改 schema、加索引或迁移（`entry_tags` 主键 `(entry_id, tag_id)` 已覆盖按条目 id 的查找）。

## 需求

### R1 · 按条目 id 集批量取标签
When 调用方以一组条目 id 请求标签, the 数据层 SHALL 返回「条目 id → 标签列表」映射。
- 前提：库内若干条目挂有若干标签，其中部分标签已软删除。
- 操作：以条目 id 集合（可含重复、可含不存在 / 无标签的 id）调用批量查询。
- 结果：每个请求过的 id（去重后）都在映射里有键；值只含**未软删除**的标签，同一条目内按标签名升序；无标签或不存在的 id 映射为空列表；输入为空集合时返回空映射。

### R2 · 查询次数与条目数无关
The 数据层 SHALL 以**单条 JOIN 查询**完成一批条目的标签读取，查询次数 MUST NOT 随条目数线性增长。
- 前提：一次请求含 N 个条目 id（N 不超过单块上限）。
- 操作：调用批量查询。
- 结果：数据库只收到 1 条 SELECT（空输入时 0 条）。If 条目 id 数超过 SQLite 绑定变量的安全上限, then 数据层 SHALL 按固定块大小分块、每块 1 条查询，结果与不分块一致。

### R3 · 时间线卡片显示标签
When 时间线加载一页条目（首屏、翻页、刷新）, the 时间线 SHALL 把该页每个条目的未删除标签名（按名称升序）填入对应 `TimelineEntry.tags`。
- 前提：生产组合根的时间线仓（`TimelineRepositoryAdapter`）具备标签批量查询能力。
- 操作：`loadInitial` / `loadMore` / `refresh`。
- 结果：卡片数据带标签名；每次页加载对标签只发起**恰好 1 次**批量请求，请求的 id 集合等于该页条目 id 集合；渲染 / 滚动构建卡片时 MUST NOT 再查标签。

### R4 · 时间线仓不支持标签时降级
Where 注入时间线的仓不具备标签批量查询能力（如测试假仓）, the 时间线 SHALL 照常分页与分组，`TimelineEntry.tags` 为空列表。

### R5 · 往年今日卡片显示标签
When 往年今日以生产数据端口加载某月日的条目, the 往年今日 SHALL 把每个条目的未删除标签名（按名称升序）填入对应 `EntryCardVM.tags`，整次加载对标签只发起**恰好 1 次**批量请求。
- 前提：`DataLayerOnThisDayRepository` 由组合根注入了标签仓。
- 操作：`OnThisDayController.load`。
- 结果：VM 卡片带标签名；未注入标签仓的端口（测试假实现 / 旧调用方）行为不变，标签为空。

## 专项维度逐维表态

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 只读既有本地表，不涉及密钥、加密或外发 |
| 权限 | 否 | 无系统权限申请 |
| 无障碍 | 否 | 不改任何 widget；标签渲染沿用 `DayzEntryCard` 既有语义 |
| 性能 | 否 | 「不逐条查」以查询次数这一可判定行为在 R2 / R3 / R5 内单任务验证，无可度量时延 NF |
| 多端兼容 | 否 | 纯 Dart 数据层与控制器改动，无平台分支 |

跨多模块：否（改动全在同一 Flutter 包 `lib/` 内，见 design「文件变更」）→ 精简档。
