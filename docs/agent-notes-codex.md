# Agent 备忘 · Codex 沙箱专项

> 从 `AGENTS.md` 拆出。只在 **Codex 沙箱**（受限文件系统）里跑本仓库时才相关；Claude Code / 本机终端不受这些限制，不必读。
> 这些都是环境问题，不是依赖解析或业务代码问题——**不要先改源码排查**。

- **Flutter SDK cache 沙箱权限**：`flutter pub get` / `flutter test` / `flutter build ...` / `flutter run` 等命令都可能先执行 SDK 内部 `update_engine_version.sh`，写 `/opt/homebrew/Caskroom/flutter/.../bin/cache/engine.stamp.tmp.*`、`engine.realm` 等工作区外缓存；若报 `Operation not permitted`，按审批机制对**同一条** Flutter 命令提升权限重跑；不要在普通沙箱里反复重试。
- **build_runner 权限**：普通沙箱曾出现 `dart run build_runner ...` 无输出卡住；需要 codegen 时优先用已批准的提升权限运行。若已卡住，先终止卡住的 `dart.*build_runner` 进程，再 `dart run build_runner clean` 后重跑。
- **Git index 写入权限**：`git add` / `git commit` / 部分 `git update-index` 会创建或更新 `.git/index.lock`；若报 `Operation not permitted`，对该 git 命令请求提升权限重跑。`git status` / `git diff` 等只读检查不需要升权。
- **iOS 构建排障权限**：`flutter build ios` / `flutter run` 会写 Flutter SDK cache、Xcode DerivedData、CoreSimulator 等工作区外目录；若出现 `Operation not permitted`，或 Xcode Pods embed framework 脚本偶发 `Killed: 9`，先提升权限单独重跑一次确认。若提升权限能过、用户终端仍失败，再清 DerivedData/Pods 缓存排查。
