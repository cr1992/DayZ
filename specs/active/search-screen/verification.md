---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：草稿
---

# 验证：search-screen

> 本屏验证以「能由本屏 widget test 独立验证」为主：样式参数闸（解析渲染后样式 == 设计稿、读 token）、布局几何闸（`tester.getRect`/`getSize` 断顺序/包含/不溢出 + fixed-geometry 元素尺寸；content-driven 文本块不硬断块高）、无障碍专项。参数/几何抽取 harness 与区域化 SSIM 兜底属 `design-sync-automation`（跨 spec），**本屏不重造**——需"对设计稿源屏比框"的栅格观感项标注依赖它、不阻塞本屏放行。对比度真源沿用 `design-tokens-theme` 的 `test/ui/theme/contrast_xfail.yaml`（单一来源，不另立）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 五态机走查 | 空输入 → 键入 → 防抖到期 → 查询返回 | idle→typing→querying→results/empty 依次切；异常 → error | R1 | 自动 |
| 防抖 + 旧查询丢弃 | 防抖窗口内连键 `梅`→`梅子`→`梅子酱`，旧查询注入更长延迟 | 只对 `梅子酱` 发一次有效查询；旧结果不覆盖 | R2 | 自动 |
| 命中词高亮 | results 态某卡片标题/摘要含查询词 | 命中 `TextSpan` 背景==`accentSoft2`、前景==`accentInk`，文本拼回原文 | R3 | 自动 |
| 计数判空切态 | 查询返回 count>0 / count==0 | count>0 渲 N 张卡片且计数 N==卡片数；count==0 渲空态且标题含查询词 | R4 | 自动 |
| idle 建议 | 进屏、空输入 | 见「最近搜索」+「标签」分组；点建议/标签回填并触发查询 | R5 | 自动 |
| 取消返回 | 点「取消」 | 当前路由出栈，回来源页 | R6 | 自动 |
| 进入阅读页 | 点结果卡片 | 路由变 `Routes.reader`，携 entryId | R7 | 自动 |
| error 重试 | 查询抛错 → 点「重试」 | error 态显错误文案+重试钮（不崩）；重试以同词回 querying | R8 | 自动 |
| Debug Home 入口 | 从 demo 列表进入 search demo | demo 用假数据可触达六态 | R9 | 自动 + 人工 |

## 专项检查

### 无障碍（NF1）
- [ ] 取消钮/输入框/结果卡片/空态/重试钮均有 `Semantics` 标签（取 `AppLocalizations`）— 自动：`flutter test test/ui/search/search_a11y_test.dart`（`find.bySemanticsLabel(l10n.xxx)` 命中）
- [ ] 取消钮 / 建议行 / 标签 chip / 筛选去除叉 `.x` / 卡片可点区命中盒 ≥ 44×44 — 自动：同上（`tester.getSize`）
- [ ] reduce-motion：`MediaQueryData(disableAnimations: true)` 下输入光标闪烁/切态过渡时长 == 0（经 `dayzMotionDuration`）— 自动：同上（注入 MediaQuery 断言时长）
- [ ] 高亮文字（`accentInk` on `accentSoft2`）对比度 ≥ WCAG AA — 自动：复用 `design-tokens-theme` 的 `test/ui/theme/contrast_test.dart` + `contrast_xfail.yaml`（单一真源，本屏不另立阈值；该对组若落入 tokens-theme 已登记的 expected-fail 则按其阻塞口径报 @Ray，不在本屏静默通过）

### 样式参数闸（NF4 · 确定性）
> 解析渲染后样式 == 设计稿（`search.html` 关联 `spec.css` 的解析后值），读 token、断值；**不** grep 屏源。
- [ ] `.search-input` 容器底色 == `context.dayz.bg2`、圆角 == `DayzRadii` 全圆角（`--r-full`）— 自动：`flutter test test/ui/search/search_page_test.dart`（解析 `DayzSearchField` 渲染装饰断值）
- [ ] `.search-cancel` 文字色 == `context.dayz.accentInk` — 自动：同上
- [ ] `.search-stat` 计数文本色 == `context.dayz.ink3`、`b` 段 == `context.dayz.ink2` — 自动：同上
- [ ] 命中 `.hl` span 背景 == `context.dayz.accentSoft2`、前景 == `context.dayz.accentInk` — 自动：同上（解析 `Text.rich` 命中 span 样式，R3/D4）
> `.hl` 的 3px 圆角 + `0 2px` padding 在纯 `TextSpan.backgroundColor` 不可得（D4 降级为直角无内边距）→ 圆角/padding 像素差进 ④ 栅格观感 advisory，不阻塞。

### 布局几何闸（NF3/D3 · 确定性，文本块除外）
> `tester.getRect`/`getSize` 断顺序/包含/不溢出 + fixed-geometry 尺寸；content-driven 文本块（卡片标题/摘要）不硬断块高（方法论 §4）。
- [ ] results 态：`.search-stat` 计数行在 `ListView` 上方，卡片纵向顺序 == hits 顺序、不溢出视口 — 自动：`flutter test test/ui/search/search_geometry_test.dart`
- [ ] 朴素 `ListView`：**无** `SliverPersistentHeader` 吸顶月份头 / 无日历面板（D3 范围红线）— 自动：`find.byType(SliverPersistentHeader)` 应 0 命中（断"未引入"的可观测结构，非 grep 源码）
- [ ] fixed-geometry：搜索头图标 / 取消钮 / 去除叉 `.x` 尺寸位置（≤1–2px 容差）— 自动：同上
> 跨引擎"对设计稿源屏比框"（用 `getBoundingClientRect` vs `RenderObject` 对齐）属 `design-sync-automation` harness，本屏几何闸用 Flutter 原生 `tester.getRect` 自验、不依赖 harness 就绪。

### 栅格观感（④ · 半确定性，advisory 不阻塞）
- [ ] 六套主题 × results/empty/idle golden 回归锁 — 自动：golden（`design-sync-automation` 期二接入区域化 SSIM；高亮圆角/玻璃等像素差进 SYNC_REPORT 标红，不阻塞本屏放行）— **依赖 `design-sync-automation`**

### Repository 边界（NF2 · 硬红线静态核验）
- [ ] `lib/ui/search/` 下屏与控制器（`search_page.dart`/`search_controller.dart`/`search_state.dart`/`search_highlight.dart`）**不** import `package:drift`、不 import `lib/data` 内部句柄；仅 `search_source.dart` 的 `RepoSearchSource` 接触 Repository 公开 API — 自动：`flutter test test/ui/search/repo_boundary_test.dart`（用 import 图 / 反射或对各文件源做 import 声明断言——断"依赖关系"这一可观测结构，针对的是 import 边界而非被改文件的业务文本，符合抗规避）
- [ ] 屏内无任何 SQL / Drift 查询字符串、无自拼 LIKE/FTS 语句 — 自动：同上边界测试覆盖（LIKE 拼装归 `EntryRepo`，本屏 `SearchSource` 仅持接口）
> 多端兼容（NF3）真机走查（iOS 13+ / Android 8+ 滚动流畅、中英混排高亮换行、安全区让位）— 人工（@Ray），见回归/兼容。

### 兼容性（NF3）
- [ ] iOS 13+ 真机/模拟器：朴素 ListView 滚动流畅、中英混排命中高亮换行正常、`.search-head`/底部安全区让位正确 — 人工（@Ray）
- [ ] Android 8+ 真机/模拟器：同上（CJK 系统字回退观感可接受）— 人工（@Ray）

> 数据迁移 / 回滚：本屏无持久化 schema 变更或数据格式演进（查询入口实现归 data-layer）→ 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（search demo 追加未破坏既有 demo）— 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（五态机）、R2（防抖/丢弃）、R3（高亮）、R4（计数判空）、R5（idle 建议）、R6（取消）、R7（进阅读页）、R8（error/重试）、R9（demo）、NF1（无障碍专项）、NF2（边界静态核验）、NF3（兼容性）、NF4（样式参数闸）均有对应场景/专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze）与 ④ golden（依赖 design-sync-automation）已显式标「回归/advisory」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/search/        # 状态机/防抖/高亮/五态渲染/参数/几何/无障碍/边界
flutter test test/demo/             # search demo + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`test/ui/search/*_test.dart` 由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；真正需预批的非 `_test.dart` 共享基建 = `test/ui/search/fake_search_source.dart`（受控假 `SearchSource`），已在 T1 的 inline `验收基建` 字段预批（执行协议第 2 条）。对比度复用 `design-tokens-theme` 的 `test/ui/theme/contrast_test.dart` + `contrast_xfail.yaml`（其 spec 内已预批，本屏只读、单一真源）。④ golden 基线接入归 `design-sync-automation` 期二，不在本屏建基线。
</content>
