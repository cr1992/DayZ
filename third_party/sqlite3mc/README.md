# third_party/sqlite3mc

预编译的 **SQLite3MultipleCiphers**（sqlite3mc）原生库，由仓库提交，供 `package:sqlite3`
的 native-assets build hook 在构建时**本地读取**，而非从 GitHub release 下载。

## 为什么提交进仓库

- App 的加密 DB 依赖 sqlite3mc 的 SQLCipher 兼容模式（`lib/data/database.dart`
  里 `PRAGMA cipher = 'sqlcipher'`），所以**必须**用 sqlite3mc，不能退回 plain sqlite3。
- 上游 `package:sqlite3` 默认在每次构建时从
  `github.com/simolus3/sqlite3.dart/releases` 下载该库。这有两个坑：
  1. **网络不稳**：部分网络/CI（尤其国内访问 github）经常
     `Connection terminated during handshake` / `Transferred a partial file`，构建直接失败。
  2. **缓存恒不命中**：hook 的下载缓存目录名是 `download-${Object.hash(...)}`，而 Dart 的
     `Object.hash` 带**每进程随机种子**，跨构建进程乱跳，导致即便下过也几乎每次重下
     （`--deterministic` 可固定，但透不进 Xcode 的 native-assets 脚本阶段）。
- 把官方预编译库提交进来后，**任意机器 clone 下来都能离线构建运行**，不碰 github。

## pubspec 接线

`pubspec.yaml`：

```yaml
hooks:
  user_defines:
    sqlite3:
      source: test-sqlite3mc      # sqlite3 hook 中「从本地 directory 读取」的 source（仍校验官方 sha256）
      directory: third_party/sqlite3mc/
```

> 注：`source` 是**全局**的——凡是构建的平台都从本目录读，所以本目录必须含该平台的库，
> 否则该平台构建失败。当前覆盖 **iOS + Android**（见下）。新增平台（如 macOS 桌面/`flutter test`
> 的 `libsqlite3mc.arm64.macos.dylib`）需把对应库补进来。

## 内容（release `sqlite3-3.3.2`，官方 sha256）

| 平台 | 文件 | sha256 |
|---|---|---|
| iOS 模拟器 arm64 | `libsqlite3mc.arm64.ios_sim.dylib` | `b8b6bcd0598215352509ea3c028a725bdeb471ce6af02c558a80dc7c697e534f` |
| iOS 模拟器 x64   | `libsqlite3mc.x64.ios_sim.dylib`   | `3560109f7a765fd9c2858bf7f6cbaf9c18d867d9cbf714adbe8ae4927622997c` |
| iOS 真机 arm64   | `libsqlite3mc.arm64.ios.dylib`     | `dd226453470cf63e305223f67d786d2c2b6bac9203d4624a9684dc946fdd180c` |
| Android arm64-v8a   | `libsqlite3mc.arm64.android.so` | `afa71a5887080ee77ab3115971b33fa156dfeaf54858bbb162723e64b0438f81` |
| Android armeabi-v7a | `libsqlite3mc.arm.android.so`   | `ab8113d67b0805c40c1e2f8cf53b5dbb75ba38415747f834097553ad406ba21d` |
| Android x86_64      | `libsqlite3mc.x64.android.so`   | `5c2330f06ad063055ea26fa04da1a35b53ec61cac2890787fc4a551431341d16` |
| Android x86         | `libsqlite3mc.ia32.android.so`  | `1255471a06a22c4d554f64364fd52bfafcb0f26ae5b76d03fcbb639229669850` |

来源 URL 形如
`https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.2/<文件名>`。
权威 sha256 见上游包 `lib/src/hook/asset_hashes.dart`。

## 升级 / 刷新（当 `pubspec.lock` 里 sqlite3 版本变更时）

1. 在 `~/.pub-cache/.../sqlite3-<新版本>/lib/src/hook/asset_hashes.dart` 读取新版各文件 sha256；
2. 从 `releases/download/sqlite3-<新版本>/` 重新下载本目录列出的文件；
3. 逐个核对 sha256 后覆盖提交，并更新上表与 README 顶部版本号。

`source: test-sqlite3mc` 是上游标注「测试用」的 source，但它正是「从本地目录读取并校验官方
哈希」的入口，长期可用；版本固定在 `pubspec.lock`，升级时按上面流程同步即可。

## 授权

这些是 [utelle/SQLite3MultipleCiphers](https://github.com/utelle/SQLite3MultipleCiphers)
的预编译产物（SQLite 公有领域 + multiple-ciphers 代码 MIT），经由
[simolus3/sqlite3.dart](https://github.com/simolus3/sqlite3.dart) 的 release 分发。
原样提交，不修改、不重新授权。
