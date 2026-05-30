---
name: dayz-design-sync
description: DayZ 项目专用——把 UI 设计稿同步进仓库 `ui-design/`,产出可双击、完全离线、首屏秒开的独立单文件 HTML(`dayz-prototype.html` 原型 + `dayz-design-spec.html` 规范页)。源为 claude.ai design 分享链接(https://api.anthropic.com/v1/design/h/...,下发 .tar.gz)或本地导出目录。核心 SOP:下载解压 → 整体替换 current/ → 构建独立 HTML → 验证能打开。触发词:同步设计稿 / sync design / 更新设计稿 / 设计稿更新了 / 拉新设计 / 从分享链接同步。
---

# DayZ Design Sync(DayZ 项目专用)

把 UI 设计稿同步进 `ui-design/`,产出**可双击、完全离线、首屏秒开的独立单文件 HTML**。设计稿是参考资料,**不进 Flutter 构建**;它是 source of truth,`ui-design/current/` 整体跟随它替换。

## 核心 SOP(四步)

1. **下载解压**分享链接(gzip tar)。
2. 把真源**整体替换**进 `ui-design/current/`(`rsync --delete`,不留历史副本——回溯靠 git)。
3. **构建独立 HTML**(`build-standalone.py` 把 CSS/JS/图片/字体/子屏全内联成单文件)。
4. **验证能正常打开**(headless 渲染 + 样式核对),**发现样式问题必须当场解决**再交付。

## 目录约定

| 路径 | 角色 |
|---|---|
| `ui-design/dayz-prototype.html` | 成品:交互原型,独立单文件,双击即开、完全离线 |
| `ui-design/dayz-design-spec.html` | 成品:设计规范页(色板/字体/token),独立单文件 |
| `ui-design/current/` | 原始多文件源(整体替换的落点) |
| `ui-design/current/docs/screenshots/` | 设计师交付的展示截图 + `shots.json` 镜头清单;被 `current/README.md` 与**仓库根 `README.md`** 引用。**是交付物,sync 时要保留**——别和顶层过程截图 `scraps/` 混淆 |
| `ui-design/build-standalone.py` | 内联构建器 |
| `ui-design/OPEN.md` | 给人看的「怎么打开」说明 |

成品文件名**纯英文**(避免 `file://` 中文转义)。`ui-design/` 独立于 `docs/design/`(冻结决策)和 `assets/`(会进 App 打包),**别**加进 `pubspec.yaml` 的 `flutter: assets:`。

## 本机前置(不绕过会失败)

- **网络要禁沙箱**:本机 Bash 默认无外网,`curl`/headless Chrome/字体子集化都要用 Bash 工具的 `dangerouslyDisableSandbox: true`,否则 `curl` 返回 `HTTP 000`、字体内联会降级。
- **RTK 钩子吞输出**:`rsync`/`diff`/`ls`/`rm`/`git status` 输出会被截短成 `ok` 一行(且可能回显旧缓存)。要看真实清单/确认副作用时命令前加 `rtk proxy`。
- **结果回显偶有延迟**:命令真跑了、文件真落了,但 stdout 延迟。对策:把结果写进 `/tmp/<具体名>.txt` 再 Read;副作用始终可信。清理临时文件**用具体文件名,别用通配**(会误删正在写的报告)。

## 执行

### 1. 下载 + 解压(禁沙箱)

```bash
curl -fsS -L --http1.1 -o /tmp/dayz-design.bin \
  "https://api.anthropic.com/v1/design/h/<handle>" \
  -w "HTTP=%{http_code} type=%{content_type} size=%{size_download}\n"
file /tmp/dayz-design.bin                      # 期望 gzip compressed data
tar -tzf /tmp/dayz-design.bin | head -60       # 看清单,确认结构没变
mkdir -p /tmp/dz-src && tar -xzf /tmp/dayz-design.bin -C /tmp/dz-src
```

- 真源在 **`/tmp/dz-src/dayz/project/`**(tar 顶层是 `dayz/`,业务在 `project/`)。
- 过程产物**不同步**:**项目根**的 `scraps/`(设计过程截图,旧名顶层 `project/screenshots/`)、`.thumbnail`、`dayz/chats/`。
- 交付物**要同步**:`docs/screenshots/`(设计师展示截图 + `shots.json` + `README.md`,喂给 `current/README.md` 与仓库根 README)。**它和顶层过程截图同名但不是一回事**——见第 2 步,exclude 必须**锚定根**,否则会把它一起删掉。
- `HTTP=000 / curl:(16) HTTP2 framing layer` → HTTP/2 协商抖动,加 `--http1.1` 重试(命令里已带)。`HTTP=000` 也可能是没禁沙箱。
- `HTTP=404` → handle 失效/未发布/私有/拷错,**停下找用户**确认。
- `file` 不是 gzip(变 JSON/文本)→ 端点格式变了,先 `head -c 500` 摸清再调脚本。
- **源 B(本地导出)**:源根就是用户给的目录,跳过 curl。

### 2. 整体替换 current/(禁沙箱跑 rsync 看清单)

```bash
cd <repo-root>
rsync -ai --delete \
  --exclude='/scraps/' --exclude='/screenshots/' --exclude='.thumbnail' --exclude='.DS_Store' \
  /tmp/dz-src/dayz/project/ ui-design/current/
```

`--delete` 让 `current/` 严格镜像最新设计(改名/删除的旧文件一并清掉,不留残留、不归档)。`-i` 出 itemize 清单(`+++++++` 全新 / `..t` 仅时间戳即内容未变 / `*deleting` 删),RTK 会截短,**重定向到 `/tmp/dz-rsync.txt` 再 Read** 看真清单。

**过程截图的 exclude 必须用根锚定 `/`**(`/scraps/`、`/screenshots/`)——它们只在**项目根**:`scraps/` 是过程图(旧名顶层 `screenshots/`),要排掉;而 `docs/screenshots/` 是**交付物**,要留。**不锚定的 `--exclude='screenshots/'` 会匹配任意层级、把 `docs/screenshots/` 一起删——踩过,丢的就是设计师交付的展示截图。** `.thumbnail`/`.DS_Store` 保持不锚定(到处都排)。**新增 exclude 时同步更新这里,并先想清楚要不要锚定。**

### 3. 构建独立 HTML(禁沙箱——字体子集化要联网)

```bash
cd ui-design
python3 build-standalone.py current/index.html dayz-prototype.html                      # 原型(自动跟随跳转壳到真入口)
python3 build-standalone.py current/design-system/design-system.html dayz-design-spec.html  # 规范页
```

> 入口路径以**实际源**为准:跳转壳 `current/index.html` → 真入口(现为 `current/pages/index.html`);规范页现为 `current/design-system/design-system.html`。结构变了就改这两条命令。

每条须打印 `外部字体请求残留: 0 (完全离线 ✓)` + `自检: 无残留相对引用 ✓`,退出码 0。
- **build 输入字节没变就别白重建**:若第 2 步 itemize 显示改的全是 `..t`(仅时间戳)、真正新增的只有 `docs/screenshots/`(它**不参与** build),则独立 HTML 是同一产物。抽查 `shasum` 确认 `current/` 关键源(`index.html`、`pages/index.html`、`design-system/design-system.html`、`pages/screens/*`、`app.js`)与解压源一致后,**跳过重建,只跑第 4 步验证既有产物健康**——重建要联网做字体子集化,无谓重跑是浪费。
- **退出码 3 + 「回退在线 link」**:字体没全内联(个别 woff2 网络抖动,常见)。脚本已带重试,**直接重跑一次**通常即成。确无外网、只要能跑的产物时设 `DZ_ALLOW_ONLINE_FONTS=1` 放行。
- **「N 处相对引用未内联」**:有新资源加载方式没覆盖,见「构建器要点」。

### 4. 验证能打开(必做,别假设成功——禁沙箱)

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
URL=$(python3 -c "import pathlib;print(pathlib.Path('$PWD/dayz-prototype.html').as_uri())")
"$CHROME" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=12000 \
  --run-all-compositor-stages-before-draw --screenshot=/tmp/dz-shot.png --window-size=1440,940 "$URL"
"$CHROME" --headless=new --no-sandbox --virtual-time-budget=12000 --dump-dom "$URL" > /tmp/dz-dom.html 2>/dev/null
```

核对(原型):
- 截图非空白、样式正确(把截图 `SendUserFile` 给用户肉眼确认,尤其字体/配色/布局)。
- `grep -c 'srcdoc' /tmp/dz-dom.html` >0(shim 把运行时 iframe 改写成功)。
- `grep -c 'src="screens/' /tmp/dz-dom.html` =0(无未改写残留 → 不会白屏)。
- `grep -c 'fonts.gstatic.com' /tmp/dz-dom.html` =0(完全离线)。
- 屏文案确实渲染进 DOM(grep 一句已知文案)。

规范页同理:截图正确 + 色板/token 文案渲染 + 零外部字体。

**样式问题处置纪律**:headless 或用户反馈发现任何样式不对(字体没生效、配色错、布局塌、图丢、子屏白屏),**当轮定位并修掉**——改构建器或排查源,重建后重新验证,不把已知样式问题留给用户。

### 5. 清理 + 交付

```bash
rm -f /tmp/dayz-design.bin /tmp/dz-shot.png /tmp/dz-dom.html && rm -rf /tmp/dz-src
rtk proxy git status --short ui-design/
```
给用户:改/增/删了什么 + 验证结论。**未经明确许可不 `git commit`/push**,作者署名 `@Ray`。

## 构建器要点(`build-standalone.py`)

- **两模式自动判别**:入口同级有 `screens/` 且引用 `app.js` → 原型打包;否则纯内联。跳转壳(meta-refresh / `location.replace`)自动跟随到真入口。
- **纯内联**:`<link>`CSS、`<script src>`、`<img>`、CSS `url()` 全内联,静态 `<iframe src=*.html>` 递归内联进 srcdoc。
- **原型打包**:`app.js` 运行时建 `iframe.src="screens/{id}.html?query"`。把各 `screens/*.html` 内联进 `window.__DZ_SCREENS__`,注入 **iframe src setter 拦截 + MutationObserver shim**,把运行时 iframe 改写成自包含 `srcdoc`(屏引导脚本读 `location.search`,shim 短路成构建期 query)。对设计师 `app.js` **零侵入**,只依赖「`screens/{id}.html` + query」这一约定。
- **字体子集化**(首屏快的关键 & 离线的前提):扫所有可见文字 → 向 Google Fonts `css2?...&text=<用到的字>` 拉超小子集 → gstatic woff2 逐个 base64 内联为 `@font-face`。字体只存 1 份(`window.__DZ_FONTS__`,父页内联、各屏 srcdoc 留 `<!--__DZ_FONTS__-->` 占位由 shim 注入,避免 N 倍膨胀)。`_curl_bin` 带 3 次重试;全内联失败则退出码 3。
- **大图重压**:`>200KB` 的 png/jpg 用 `sips` 降采样(长边≤1200)+ 转 JPEG 再 base64。
- **失效信号 → 改哪**:屏白屏 / `src="screens/` 残留(设计改用 fetch/ESM 或改了 screens 约定)→ 扩展 shim;字体回退在线(Google 接口/字族变了、或字符数 >1800)→ 查 `build_font_style`。

## 维护

目录约定、`build-standalone.py`、`OPEN.md` 绑定 DayZ;下载/替换/内联/shim 的骨架是通用方法学。哪天 DayZ 用真 UI 层取代设计稿参考,或目录迁移,回来改「目录约定」「构建器要点」即可。
