<p align="center">
  <img src="ui-design/current/pages/assets/img/sea.png" width="100%" alt="DayZ">
</p>

<h1 align="center">DayZ</h1>
<p align="center"><b>温润安静的日记</b></p>
<p align="center">
  你的文字，只留在你手里。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/license-MPL--2.0-blue" alt="License">
  <img src="https://img.shields.io/badge/stage-设计中-orange" alt="Stage">
</p>

---

## 为什么做 DayZ

市面上的日记 App 不少，但大多要么把数据存到云上、要么功能简陋、要么界面冰冷。

DayZ 想做的很简单：**一本安安静静、放在你手边的日记本**。

打开它，是暖白的纸、衬线的字、不打扰的安静。你写下的每一行，都只留在你自己手里。

- 📖 像翻一本真正的日记——按时间线慢慢往下，照片与文字铺在一起
- 🎨 三套主题色随心换：雾紫的沉思、暖黄的日光、雾绿的平和，还有同样温暖的深色模式
- ✍️ 想怎么写就怎么写：标题、清单、引用、照片，图文随意混排
- 🕰️ 「往年今日」轻轻回看——这一天，去年的你在做什么？
- 🔒 数据只在你手机里，默认上锁，随时能整本带走

## 看看它长什么样

设计稿已经做好了，不用下载也能直接在浏览器里翻——

**▶ 在线预览**（点开即看）

- [**交互原型 →**](https://cr1992.github.io/DayZ/ui-design/dayz-prototype.html) — 6 屏：时间线 / 阅读 / 编辑 / 往年今日 / 搜索 / 设置；可随手切主题色、切明暗、切「原型（点进点出）/ 画布（各屏多状态铺开）」两种看法。
- [**设计规范 →**](https://cr1992.github.io/DayZ/ui-design/dayz-design-spec.html) — 色板 / 字体 / 间距 / 组件一览。

> 在线版部署在 GitHub Pages，跟随 `main` 自动更新，首屏加载稍等一两秒。打不开时可用 githack 镜像：[原型](https://raw.githack.com/cr1992/DayZ/main/ui-design/dayz-prototype.html) · [规范](https://raw.githack.com/cr1992/DayZ/main/ui-design/dayz-design-spec.html)。

**想离线看，或拷给别人**：把仓库下载到本地，**双击** `ui-design/` 下的 `dayz-prototype.html` / `dayz-design-spec.html` 即可——完全离线、秒开，单个文件拷走也能直接看。

<!-- ─────────────────────────────────────────────────────────────
     界面宣传图占位区（设计师出图后取消注释、把图片放进 docs/screenshots/）
     建议 4 张：时间线（亮）/ 阅读（亮）/ 编辑（暗）/ 往年今日，宽度各 24%
<p align="center">
  <img src="docs/screenshots/timeline-light.png" width="24%" alt="时间线">
  <img src="docs/screenshots/reader-light.png"   width="24%" alt="阅读">
  <img src="docs/screenshots/editor-dark.png"    width="24%" alt="编辑 · 深色">
  <img src="docs/screenshots/onthisday.png"      width="24%" alt="往年今日">
</p>
────────────────────────────────────────────────────────────── -->

## 设计语言

DayZ 的整套视觉只为一件事服务：**让你愿意安安静静地写下去**。所以它温润、克制、有纸感——少即是多，没有多余的图标、渐变和噪音。

| | |
|:---|:---|
| **纸感配色** | 暖白底色（`#FAF7F1`），像摊开的纸；深色模式是暖炭黑（`#1A1813`），不是冷冰冰的纯黑 |
| **有温度的字** | 正文用衬线体（Newsreader），带一点手写本的味道；界面用无衬线体（Hanken Grotesk），干净不抢戏；中文一律用系统原生字体，零下载 |
| **呼吸感** | 毛玻璃顶栏、暖色投影、克制的微动效——不张扬，但活着 |
| **一切可换** | 三套主题色是三套完整色板，整体一键切换，亮色暗色各有一套 |

<details>
<summary><b>三套主题色一览</b></summary>

| 主题 | 亮色强调 | 暗色强调 | 感觉 |
|:---:|:---:|:---:|:---|
| 🟣 雾紫 Lavender | `#786CAD` | `#ABA0D9` | 安静、沉思 |
| 🟡 暖黄 Honey | `#C8993E` | `#DEB75C` | 温暖、日光 |
| 🟢 雾绿 Sage | `#5C8A68` | `#8FBA9B` | 自然、平和 |

</details>

## 安静的技术

好看之外，DayZ 在你看不见的地方也下了功夫。说人话就是：

- **只在你手里** — 日记只存在你自己的手机里，不上传任何服务器，不注册、不联网也能写。
- **像保险箱一样锁着** — 数据库始终加密（SQLCipher），就算手机丢了，别人也打不开你的日记。
- **照片有自己的锁** — 图片单独加密保管，和文字分开存放。
- **写一次，两端都有** — iOS 和 Android 同一套体验，同一份代码（Flutter）。
- **随时能带走** — 一键备份导出，数据永远是你的，想搬到哪都行。

> 想看技术细节？展开文末 **🔧 开发者信息**，或翻 [`docs/README.md`](./docs/README.md)（冻结的技术决策：选型 / 加密 / 备份）与 [`specs/README.md`](./specs/README.md)（功能规划与进度）。

## 当前进度

DayZ 目前处于**设计与架构阶段**——界面设计稿已完成六屏原型（见上方「看看它长什么样」），代码架构文档已就位，应用代码正待落地。

## 想参与？

欢迎关注和 star ⭐️。项目以 spec 驱动开发，所有需求和设计决策都有文档记录：

- 功能规划与状态 → [`specs/README.md`](./specs/README.md)
- 技术决策与架构 → [`docs/README.md`](./docs/README.md)

---

<details>
<summary><b>🔧 开发者信息</b>（点击展开）</summary>

### 技术栈

- **Flutter / Dart**（stable 最新版）— 一套代码，iOS + Android
- **Drift（SQLite）+ SQLCipher** — 本地数据库，始终加密
- **AppFlowy Editor** — 开源富文本编辑器（仓库内 fork，`packages/appflowy-editor/`）
- 媒体走本地文件系统 + 独立缩略图缓存

### 常用命令

```bash
flutter pub get      # 安装依赖
flutter run          # 运行（进入 Debug Home）
flutter test         # 跑测试
flutter analyze      # 静态分析
dart format .        # 格式化
```

改了 `packages/` 下的 vendored 源码，提交前必须跑：

```bash
bash scripts/check_patches.sh   # 须退出 0
```

### 项目规范

接到任务前先读：

- [`AGENTS.md`](./AGENTS.md) — 协作规范
- [`CLAUDE.md`](./CLAUDE.md) — 仓库现状与架构
- [`spec-kit/spec-guide.md`](./spec-kit/spec-guide.md) — spec 执行协议
- [`docs/spec-guide-ai.md`](./docs/spec-guide-ai.md) — DayZ 专项 overlay

新增功能或重大改动**先开 spec**，不在源码里直接做。

</details>

## License

本仓库为**混合授权**：

- **原创代码** — [Mozilla Public License 2.0](./LICENSE)（文件级弱传染）
- **`packages/appflowy-editor/`** — 上游 [AppFlowy Editor](https://github.com/AppFlowy-IO/appflowy-editor) fork，保留原双授权（AGPL-3.0 / MPL-2.0），本项目按 MPL-2.0 使用

## 维护者

`@Ray`
