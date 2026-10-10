---
作者：@Ray
创建日期：2026-10-10
---

# ui-kit-patch（组件层小补）

> 修复自 [ui-kit-components](../../archive/2026-06-06-ui-kit-components/)（归档后返工 → 新建精简档）。

## 背景

`ui-kit-components` 归档后，屏幕 spec 接真数据时陆续暴露出四处组件层缺口，各屏只能绕开或带病上线：

1. `DayzIcons` 没有左箭头，往年今日的返回钮在屏内私有了一份 path（`m15 5-7 7 7 7`），其他屏要用还得各抄一份。
2. `DayzEntryCard` 封面与 `DayzGallery` 格子直接 `Image(image: …)`：解密图源（thumbnail-provider）就绪前没有帧，图位一片空白、出帧时硬切；图源失败时异常冒到框架层、没有兜底。
3. 收藏星在只读态（`onPressed == null`，如往年今日 / 时间线卡片只展示「已收藏」）仍读成「取消收藏」，且标成按钮，读屏用户以为能点。
4. `DayzSheet.actions` 没有标题参数（设计稿 `.sheet-head .t`），`DayzSheetItem` 的图标只收 Material `IconData`，与「图标一律走 `DayzIcons`」的规则冲突。

本 spec 只在组件层补齐这四处，屏幕层自动受益；往年今日顺带删掉私有返回箭头。

## 范围外

- 各屏改用 sheet 标题 / `DayzIcons` 图标：本 spec 只提供能力，屏幕替换归各屏 spec（MUST NOT 在本 spec 里改 `lib/ui/reader`、`lib/ui/timeline`、`lib/ui/search`、`lib/ui/editor` 的调用方）。
- 缩略图未就绪的 blurhash / 渐进加载：本 spec 只做纯色占位 + 淡入。
- `DayzSheet.picker` / `form` / `confirm` 的标题：只给 `actions` 加。
- 移除 `DayzSheetItem.icon`（`IconData`）：保留兼容，存量调用方不改。

## 需求

### R1 · 左箭头图标

`DayzIcons` SHALL 提供左箭头 path，取屏源 `.app-top [data-nav-back]` 的 `m15 5-7 7 7 7`，经 `DayzIcon.path` 渲染。往年今日返回钮 MUST 改用该常量，屏内 MUST NOT 再保留私有箭头 path。
- 前提：往年今日屏渲染。
- 操作：读取返回钮里的 `DayzIcon`。
- 结果：其标记等于 `DayzIcons.chevronLeftPath` 包成的 `<path>`。

### R2 · 图位占位、淡入与失败兜底

卡片封面与相册格子 SHALL 在图源无帧时显示 `accentSoft2` 占位；出第一帧后 SHALL 经 `dayzMotionDuration` 淡入；While 系统开启减少动态效果，淡入时长 SHALL 为 0。If 图源加载失败，then 图位 SHALL 显示同一占位，且 MUST NOT 把异常抛到 build / 框架错误通道。
- 前提：卡片封面或相册格子挂一个可控图源。
- 操作：先不给帧 → 给帧；或直接让图源失败。
- 结果：无帧时图片不可见、占位可见；出帧后不透明度为 1、过渡时长等于 `DayzMotion.dur`（减少动态时为 0）；失败时出现占位且测试框架捕获不到异常。

### R3 · 收藏星只读态语义

Where 收藏星没有点击回调（只读），系统 SHALL 读出状态而非动作：已收藏读「已收藏」，未收藏不出语义节点；两种情况都 MUST NOT 标为按钮、MUST NOT 出 tooltip。可点击态维持原语义（未收藏读「收藏」、已收藏读「取消收藏」，标为按钮）。`DayzEntryCard` 的星位 SHALL 遵循同一规则。新增文案 MUST 同时补 `app_zh.arb` / `app_en.arb`。
- 前提：只读已收藏 / 只读未收藏 / 可点击三种星。
- 操作：读语义树。
- 结果：只读已收藏 → 标签「已收藏」、无按钮标志；只读未收藏 → 无标签；可点击 → 原动作标签 + 按钮标志。

### R4 · 动作弹层标题与图标

`DayzSheet.actions` SHALL 接受可选 `title`，有值时在列表上方按 `.sheet-head .t`（衬线 17px / 600 / ink、居中）渲染并带标题语义；无值时版式不变。`DayzSheetItem` SHALL 支持以 `DayzIcons` 的单 path（`iconPath`）或复合标记（`iconMarkup`）作图标，经 `DayzIcon` 渲染、颜色随条目 tone；原 `IconData icon` 参数 MUST 继续可用。
- 前提：打开带标题、带 `iconPath` / `iconMarkup` / `icon` 条目的动作弹层。
- 操作：读取弹层组件树与语义树。
- 结果：标题文本存在且有标题语义；三种图标条目分别渲染为 `DayzIcon` / `DayzIcon` / `Icon`；不传标题时不出现标题节点。

## 专项维度逐维表态

| 专项维度 | 命中？ | 依据（一句话） |
|---|---|---|
| 安全 | 否 | 纯展示层组件改动，不碰密钥、存储或网络。 |
| 权限 | 否 | 不新增运行时权限。 |
| 无障碍 | 否 | R3 只把收藏星只读态的既有语义从「动作」更正为「状态」，不新增无障碍约束或度量阈值，单任务 widget test 可完整断言（判定存疑见 design「已知风险」）。 |
| 性能 | 否 | 淡入只用 `AnimatedOpacity`，不新增性能阈值。 |
| 多端兼容 | 否 | 纯 Flutter widget，不涉及平台通道或平台差异。 |
