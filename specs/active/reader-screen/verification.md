---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：reader-screen

> 落「能由本屏 / 本组件 widget test 独立验证」的部分。验收口径对齐方法论 [`docs/design/10`](../../../docs/design/10-ui-restore-and-design-sync.md) §4（②样式参数闸 + ③布局几何闸分治）/§11：可自动化的尽量 widget test 断言可观测值（样式参数 / 布局几何 / Semantics / 命中盒 / Repo 调用），栅格观感走 golden；视觉模型 / 人眼仅做标红终审。参数 / 几何抽取 harness 与对设计稿源屏 `reader.html` 比框 / SSIM 兜底属 `design-sync-automation`（跨 spec 依赖，本 spec 不重造），故本表的几何 / 样式断言一律用 Flutter 原生 `tester.getRect` / 解析渲染后 widget 属性自验。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 推入 + 返回 | go_router 推 `Routes.reader`（带 entryId）；点返回钮 | Cupertino 系转场入场；pop 退回上一屏 | R1 | 自动 |
| default 长篇版式 | pump 全字段视图模型 | read-hero/kicker/h1/r-meta/r-body/九宫格/r-tags 顺序正确、不溢出 | R3 | 自动 |
| text 纯文字篇（空字段折叠） | pump 无封面 / 无 weather / 无地点 / 无九宫格的视图模型 | 对应元素 `find` 不到、无空槽撑出间距 | R2 | 自动 |
| 封面 / 九宫格异步加载 | 假缩略图：未就绪 / 就绪两态 | 未就绪显占位 + 调 `warmup`；就绪显 provider | R4 | 自动 |
| 九宫格就地展开 | 点第 9 格 `+N` 蒙层 | 露出全部图、路由栈深度不变（不导航） | R5 | 自动 |
| 收藏星 toggle 同步 | 点顶栏星 / 菜单收藏项 | 星态切换 + toast；顶栏星与菜单项一致；`EntryRepo` 更新 favorite | R6 | 自动 |
| ⋯ 动作菜单 | 点 ⋯ 钮 | 弹「编辑 / 分享 / 移到日记本 / 收藏 / —分隔— / 删除(danger)」六项；编辑导航 `Routes.editor` | R7 | 自动 |
| 删除 = 软删 + 撤销 | ⋯→删除→确认「移到回收站」 | `EntryRepo.softDelete`（非硬删）+ toast 撤销→恢复（清 deleted_at）+ pop | R8 | 自动 |
| 移到日记本 | ⋯→移到日记本→选目标 | `JournalRepo` 列表（色点 + 篇数 + 当前打勾）；`EntryRepo` 更新 journalId + toast「已移到「X」」 | R9 | 自动 |
| 找不到态 | entryId 无对应数据 | 渲染 `DayzEmptyState`（文案引 AppStrings） | R2 | 自动 |

## 专项检查
> 对应 requirement 的 NF 编号。

### 无障碍（NF3）
- [ ] 返回钮 / 收藏星 / ⋯ 钮 / 九宫格 `+N` / sheet 行命中目标 ≥ 44×44 — 自动：`flutter test test/ui/reader/reader_screen_test.dart`（`tester.getRect` 断尺寸）
- [ ] 收藏星 / ⋯ / 返回有 Semantics 标签（来自 `AppStrings`）— 自动：同上（`find.bySemanticsLabel(AppStrings.xxx)`）
- [ ] 收藏星暴露选中态（toggled / pressed）— 自动：同上（断言 Semantics 选中态随 favorite 翻转）
- [ ] 正文 / 标题 / 元数据对底对比度 ≥ WCAG AA — 由 `design-tokens-theme` NF1 在 token 层保证；本屏只引 `context.dayz.*`，**本项核验「屏内无硬编码色 / 字号 / 间距，一律取 token」** — 自动：`flutter test test/ui/reader/reader_screen_test.dart` + `flutter test test/ui/reader/reader_body_test.dart`（解析渲染后样式断言取值来自当前 ThemeData/DayzColors，而非屏内常量）
- [ ] reduce-motion（`MediaQueryData(disableAnimations:true)`）下九宫格展开 / 图渐显时长为 0 — 自动：`flutter test test/ui/reader/reader_image_test.dart`（注入 disableAnimations 断言时长 0，经 `dayzMotionDuration`）

### Repository 边界（NF1，硬红线专项）
- [ ] 视图模型 / controller / 屏体不 import `lib/data/` Drift 句柄 / 表 / DAO，取数 / 写入只经 `EntryRepo`/`MediaRepo`/`JournalRepo`/`TagRepo` — 自动：`flutter test test/ui/reader/reader_view_data_test.dart` + `reader_controller_test.dart`（**行为核验**：测试仅注入 Repo **接口**的假实现即可驱动全部取数 / 写入分支并通过 → 证明屏对 Drift 零依赖；不 grep 被改文件自身）

### 媒体红线（NF2，专项）
- [ ] 封面 / 九宫格加载不触发同步 / 全量缩略图重建，只经 `ThumbnailCache.warmup` — 自动：`flutter test test/ui/reader/reader_image_test.dart`（假缓存记录：仅 `warmup` 被调、无任何同步重建入口被调）

### 多端兼容（NF5）
- [ ] iOS 13+ 真机 / 模拟器：`CupertinoPageRoute` 边缘返回手势生效；中英混排正文 CJK 系统字回退正常；九宫格图占位 / 解码观感可接受 — 人工（@Ray）
- [ ] Android 8+ 真机 / 模拟器：系统返回退回；正文 CJK 回退（多落 Noto）观感可接受；九宫格占位 / 解码观感可接受 — 人工（@Ray）

> 数据迁移 / 回滚：本屏不新增 / 改 DB schema（favorite / journalId / `deleted_at` 字段均由 data-layer 既有 schema 提供，本屏只调 Repo 方法）→ 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（reader demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）
- [ ] reader 屏 golden（default / text 两态）无破坏 — 自动：`flutter test test/ui/reader/reader_screen_golden_test.dart` + 人工复核（@Ray）（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（推入/返回）、R2（数据驱动/空字段折叠）、R3（版式/排版角色）、R4（媒体异步缩略图）、R5（九宫格展开）、R6（收藏同步）、R7（动作菜单）、R8（软删+撤销）、R9（移本）、NF1（Repository 边界专项）、NF2（媒体红线专项）、NF3（无障碍专项）、NF4（文案/intl，在 T2 任务内验，端到端「找不到态文案引 AppStrings」复盖）、NF5（多端专项）均有对应场景 / 专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze / golden）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/reader/        # view_data/meta/image/body/controller/screen/golden
flutter test test/demo/             # reader demo + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`*_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；真正需预批的非 `_test.dart` 共享基建——`test/ui/reader/fakes/fake_repos.dart`（内存假 Repo，含抛错分支）、`test/ui/reader/fakes/fake_thumbnail_cache.dart`（记录 warmup / 检测同步重建）、`test/ui/reader/golden/`（golden 基线）——已在 T1/T3/T5/T6 的 inline `验收基建` 字段预批（执行协议第 2 条）。参数 / 几何抽取 harness 与对设计稿源屏比框 / SSIM 属 `design-sync-automation`，本 spec 不重造。
