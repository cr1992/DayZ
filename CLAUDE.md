# CLAUDE.md

本仓库的协作规范、规则与上下文指引统一维护在 [`AGENTS.md`](./AGENTS.md)。

## Debug Home demo 入口模式
真 UI 层已接管应用冷启动入口（通过 `MaterialApp.router` + `appRouter` 进入外壳 Timeline 页面）。先前作为入口的 `DebugHome` 已降级为具名路由 `Routes.debugHome`。在开发调试或真机走查时，依然可以通过该路由路径进入 `DebugHome`。新加的 demo 页面仍按原样追加到 `demo_entry.dart` 的 `demos` 列表末尾。
