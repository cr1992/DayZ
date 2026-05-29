# 打开 DayZ 设计稿

这里放 DayZ 的 **UI 设计稿**(视觉/交互参考稿,不是 App 代码,也不进 Flutter 构建产物)。

## 怎么看(双击即可,两个独立单文件)

| 双击这个 | 看到什么 |
|---|---|
| **`dayz-prototype.html`** | 6 屏交互原型:时间线 / 阅读 / 编辑 / 往年今日 / 搜索 / 设置。可切「原型(点进点出)/画布(各屏多状态)」、切主题色、切明暗。 |
| **`dayz-design-spec.html`** | 设计规范:色板 / 字体 / 间距 / 组件 token。 |

两个都是**自包含单文件**:CSS / JS / 图片 / 字体 / 6 个子屏全部内联进去了——**完全离线、首次也秒开、不需要任何本地服务器**。拷给别人一个文件就能看。

> **首屏为何快**:字体已子集化内联(只打包设计稿实际用到的字,zero 外部请求);早期版本首次慢是因为要从 Google 下载中文字体,现已根除。文件名也全英文,避免 `file://` 中文转义。

## 目录说明

| 路径 | 是什么 |
|---|---|
| `dayz-prototype.html` / `dayz-design-spec.html` | **给人看的成品**——双击打开的单文件 |
| `current/` | 设计稿**原始多文件源**(index.html + pages/screens/ + 设计规范 + docs/),供编辑、diff、重建用 |
| `_archive/<UTC时间戳>/` | 历史版本(每次同步前把上一版归档,便于回溯对比) |
| `build-standalone.py` | 把 `current/` 里的源内联成上面两个单文件的构建器 |

> ⚠️ 别双击 `current/index.html` 或 `current/pages/` 里的页面看原型:它靠运行时动态加载子屏,`file://` 下会被浏览器 CORS 拦住而白屏。**预览一律用根目录那两个 `dayz-*.html`**。

## 更新设计稿

设计会反复迭代。要拉最新版,在 Claude Code 里说「**同步设计稿**」并附上最新 design 分享链接
(`https://api.anthropic.com/v1/design/h/...`)——会走 `dayz-design-sync` skill 自动:
拉取 → 归档旧版 → 覆盖 `current/` → 重建两个单文件 → 给 git 改动摘要(**不自动提交**)。

手动重建(字体子集化需联网,仅构建时;产物离线):
```bash
python3 build-standalone.py current/index.html dayz-prototype.html
python3 build-standalone.py "current/DayZ 设计规范/DayZ 设计规范.html" dayz-design-spec.html
```
