# 跨平台日记 App · 技术方案

> 版本：v0.6
> 主战场：移动端（iOS / Android），团队主力技术栈：Flutter / Dart
> 参考对标：Day One
> 交付方式：方案定稿后交由 AI 编码实现，故需求需明确、可执行
> 
> **v0.6 相对 v0.5 的变更**（基于二轮 review 的三点收尾）：① 修正 8.2 单文件快照与 8.3 增量比对模型的内部矛盾——MVP 仅做全量单文件导出，media 增量降级为”需先有持久备份目标”的阶段二能力；② `editing_session` 拍板为**单行模型**（同一时刻一个编辑现场，多草稿并行列为非目标）；③ 统一缩略图未就绪时的显示口径为**纯占位（绝不滚动中解原图）**，并补滚动节流。
> **v0.5 相对 v0.4 的变更**：新增缩略图缓存层（schema + 9.4 重写，含还原期懒生成、失效重建）；9.7 补媒体密钥归属与「主密码不保护照片」文案定调；第 4 节对比表增「导出/同步影响」、预研验收设一票否决 + 时间盒；8.5 PDF 因编辑器而异；8.3 media 增量清单唯一真相来源 + 孤儿清理；中文 FTS 分词与 Argon2 调参风险标记；回填须重算 local 日期；「禁止外传」改 UX 护栏。
> **v0.4 相对 v0.3 的变更**：新增 7.3「自动保存与草稿恢复」、7.4「撤销与重做」；schema 新增 `editing_session` 表。
> **v0.3 相对 v0.2 的变更**：第 9 节加密补全闭环——新增「跨设备导入流程」（9.6）与「可选加密：模式矩阵与状态切换」（9.7）。
> **v0.2 相对 v0.1 的变更**：数据存储层定稿（Drift 体系）；新增完整「备份架构」；新增「加密方案」（SQLCipher + 混合密钥）。

-----

## 设计文档索引

- [01-产品定位与架构总览](./design/01-product-positioning-and-architecture-overview.md)
- [02-数据存储与Schema](./design/02-data-storage-and-schema.md)
- [03-富文本编辑器预研](./design/03-rich-text-editor-research.md)
- [04-核心业务功能](./design/04-core-business-features.md)
- [05-备份与还原架构](./design/05-backup-and-restore-architecture.md)
- [06-加密与安全策略](./design/06-encryption-and-security-policy.md)
- [07-静态资源管理方案](./design/07-static-resource-management-scheme.md)
- [08-远期规划与分阶段实施](./design/08-long-term-planning-and-phased-implementation.md)
- [09-文件与数据库写入原子性约定](./design/09-file-db-write-atomicity.md)
