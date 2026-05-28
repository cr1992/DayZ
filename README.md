# DayZ

本地优先、注重隐私的跨平台日记 App，用 Flutter / Dart 写。

数据存在本机、默认加密,不依赖云端账号。

## 目标功能

下面是产品要做的事,大部分还在 spec/设计阶段、尚未落码(见「当前状态」):

- 图文混排的日记编辑,按时间线浏览
- 「往年今日」回看
- 本机数据库加密(SQLCipher),密钥来自设备随机 key 或用户主密码
- 备份与还原,可导出归档文件

## 技术栈

- Flutter / Dart(stable 渠道最新版)
- Drift(SQLite)+ SQLCipher 加密
- 编辑器选型 A:AppFlowy Editor(纯 Dart),以仓库内 fork `packages/appflowy-editor/` 为准
- 媒体走本地文件系统 + 独立的缩略图缓存层

## 当前状态

这是一个 **spec 驱动** 的项目,**应用代码基本还没写**:`lib/` 下 `backup/ data/ drafts/ media/ security/ thumbnails/ ui/` 七个模块目前只有占位文件,真正有代码的是 `lib/main.dart`、`lib/app.dart` 和 `lib/demo/`。架构和模块边界目前活在文档里,不在源码里。

UI 设计稿未定,App 启动直接进 Debug Home(`lib/demo/`),真机调试走各模块挂的 demo 页。

## 常用命令

```bash
flutter pub get      # 装依赖(含对 appflowy_editor 的本地 path override)
flutter run          # 真机/模拟器 debug 运行,启动进入 Debug Home
flutter test         # 跑测试
flutter analyze      # 静态分析 / lint
dart format .        # 格式化
```

改了 `packages/` 下的 vendored 源码,提交前必须跑(须退出 0):

```bash
bash scripts/check_patches.sh
```

## 文档

接到任务、想动手前先读这些:

- [`AGENTS.md`](./AGENTS.md) — 协作规范与红线(唯一规范源)
- [`CLAUDE.md`](./CLAUDE.md) — 仓库现状、架构大图、命令导航
- [`docs/spec-guide-ai.md`](./docs/spec-guide-ai.md) — 怎么写和执行 spec
- [`specs/README.md`](./specs/README.md) — 有哪些功能、状态、依赖(功能生命周期唯一真相)
- [`docs/README.md`](./docs/README.md) — 冻结的技术决策(选型 / Schema / 加密 / 备份)

新增功能或重大改动**先开 spec**,不在源码里直接发挥。

## 维护者

`@Ray`
