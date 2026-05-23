# Specs 索引

> 本文件是功能生命周期的**唯一来源**。tasks 完成情况驱动状态更新；归档后将该行移入「已归档」表。

## 进行中

| 功能 | 优先级 | 状态 | 负责人 | 创建 |
|------|--------|------|--------|------|
| [editor-research](active/editor-research/) | P1 | 草稿 | @Ray | 2026-05-23 |
| [key-management](active/key-management/) | P1 | 草稿 | @Ray | 2026-05-23 |
| [data-layer](active/data-layer/) | P1 | 草稿 | @Ray | 2026-05-23 |
| [media-storage](active/media-storage/) | P1 | 草稿 | @Ray | 2026-05-23 |
| [auto-save-draft](active/auto-save-draft/) | P1 | 草稿 | @Ray | 2026-05-23 |
| [thumbnail-cache](active/thumbnail-cache/) | P1 | 草稿 | @Ray | 2026-05-23 |
| [backup-full-snapshot](active/backup-full-snapshot/) | P1 | 草稿 | @Ray | 2026-05-23 |

## 已归档

| 功能 | 结果 | 归档日期 |
|------|------|----------|
| [app-scaffold](archive/2026-05-23-app-scaffold/) | 已完成 | 2026-05-23 |

## 待 UI 设计稿后再立 spec

下列功能或包含 UI、或强依赖编辑器选型，**待设计稿/选型结论到位后**再补需求/设计/任务文档：

- **时间线**（虚拟滚动 + 分组吸顶 + 游标分页）
- **往年今日**入口与浏览
- **富文本编辑器**（方案 A AppFlowy / 方案 B WebView+TipTap 预研后选型）
- **JSON 文档契约**（与编辑器选型一并定稿）
- **撤销/重做**（接编辑器内置 history，受选型影响）
- **自动保存草稿恢复 UI**（提示条、设置项「恢复未完成的编辑」）
- **缩略图未就绪占位**（灰块 / blurhash）
- **备份导出 / 还原向导**（含口令输入、二次确认、进度条、文件类型关联）
- **设置页**（加密模式切换 / 主密码 / 文案说明等）
- **原生相册 / 相机选图链路**
- **PDF / HTML 归档**（依赖编辑器选型）
- **每日本地通知**（往年今日）
- **持久备份目标 + media 增量**（阶段二）

补 spec 时直接在 `active/` 下新建对应目录，并在本表添加一行。
