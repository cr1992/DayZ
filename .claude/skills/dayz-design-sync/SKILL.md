---
name: dayz-design-sync
description: DayZ 项目专用——把 UI 设计稿同步进仓库 `ui-design/`,产出可双击、完全离线、首屏秒开的单文件 standalone HTML(`dayz-prototype.html` 原型 + `dayz-design-spec.html` 规范页,纯英文名)。源支持 claude.ai design 分享链接(https://api.anthropic.com/v1/design/h/...,实际下发 .tar.gz)或本地导出目录。流程:拉取/解包 → 先归档后覆盖 current/ → build-standalone.py 内联成单文件(iframe→srcdoc shim + 字体子集化内联 + 大图重压)→ headless 验证 → git 对比(不自动提交)。设计反复迭代,本 skill 为重复 re-sync 而设。触发词:同步设计稿 / sync design / 更新设计稿 / 设计稿更新了 / 拉新设计 / 从分享链接同步。
---

# DayZ Design Sync(DayZ 项目专用)

把 DayZ 的 UI 设计稿同步进仓库,产出**可双击、离线、秒开的单文件 HTML**作为成品。设计稿是参考资料,**不进 Flutter 构建产物**;设计稿是 source of truth,`ui-design/` 跟随它增/改/删。

## 何时用

用户说「同步设计稿 / sync design / 更新 ui-design / 设计稿更新了 / 拉新设计 / 从分享链接同步」,或直接甩来 `https://api.anthropic.com/v1/design/h/<handle>` 链接。

## 目录约定(目标)

| 路径 | 角色 |
|---|---|
| `ui-design/dayz-prototype.html` | **成品**:6 屏交互原型,自包含单文件,双击即开、完全离线、无需服务器(**纯英文名**,避免 file:// 中文转义) |
| `ui-design/dayz-design-spec.html` | **成品**:设计规范页(色板/字体/token),自包含单文件 |
| `ui-design/current/` | 原始多文件源(同步落点;供编辑/diff/重建) |
| `ui-design/_archive/<UTC时间戳>/` | 历史版本(每次同步前归档上一版) |
| `ui-design/build-standalone.py` | 内联构建器(见下「构建器要点」) |
| `ui-design/OPEN.md` | 给人看的「怎么打开」说明 |

> **成品文件名规定为纯英文**(`dayz-prototype.html` / `dayz-design-spec.html`):中文名经 `file://` 会被 percent-encode,既难读也偶发兼容问题。重命名须同步改 OPEN.md 与本表。

> **为什么是 `ui-design/`**:`docs/design/` 已被冻结技术决策(`0X-*.md`)占用;`assets/` 会被 Flutter 打进 App。设计稿是参考稿,独立顶层目录最干净。**别**加进 `pubspec.yaml` 的 `flutter: assets:`。

## 本机三个硬前置(不绕过会失败)

1. **网络要禁沙箱**:本机 Bash 默认在沙箱里,**无外网**,`curl` 会返回 `HTTP 000`。拉分享链接的 `curl`、跑 headless Chrome 验证,都必须用 Bash 工具的 `dangerouslyDisableSandbox: true`。
2. **RTK 钩子吞输出**:本机装了 RTK,`rsync`/`diff`/`find`/`git status` 会被截短成 `ok` 一行。要看清单/差异时命令前加 `rtk proxy`。
3. **工具结果回显延迟**:本会话偶发命令真跑了、文件真落了,但 stdout 批量延迟回显。对策:**把结果写进 `/tmp/*.txt` 再 Read**;side effect(文件已写/已建)始终可信,别因没看到回显就重试刷屏。

## 同步流程

### 1. 拉取 + 探明格式(禁沙箱)

```bash
curl -fsS -L -o /tmp/dayz-design.bin \
  "https://api.anthropic.com/v1/design/h/<handle>" \
  -w "HTTP=%{http_code} type=%{content_type} size=%{size_download}\n"
file /tmp/dayz-design.bin                 # 期望 gzip compressed data
tar -tzf /tmp/dayz-design.bin | head -60  # 看清单
```

- `HTTP=404 not found` → handle 失效/未发布/私有/拷错,**停下找用户**确认,或改源 B。
- **实测包结构**:顶层 `dayz/`,真正设计稿在 **`dayz/project/`**;`dayz/chats/`、`dayz/project/screenshots/`、`dayz/project/.thumbnail` 是过程产物,**不同步**。
- 若 `file` 显示是 JSON/文本而非 gzip:端点格式变了,先 `head -c 500` 摸清再调。

解包:`mkdir -p /tmp/dz-src && tar -xzf /tmp/dayz-design.bin -C /tmp/dz-src`,源根 = `/tmp/dz-src/dayz/project/`。

**源 B(本地导出)**:源根就是用户给的目录,跳过 curl。

### 2. 先归档,再覆盖

```bash
cd <repo-root>
TS=$(date -u +%Y%m%dT%H%M%SZ)
if [ -d ui-design/current ] && [ -n "$(ls -A ui-design/current 2>/dev/null)" ]; then
  mkdir -p ui-design/_archive && cp -R ui-design/current "ui-design/_archive/${TS}"
fi
mkdir -p ui-design/current
```

### 3. 同步源 → current/(排除过程产物)

```bash
rtk proxy rsync -a --delete \
  --exclude='screenshots/' --exclude='.thumbnail' --exclude='.DS_Store' \
  /tmp/dz-src/dayz/project/ ui-design/current/
rtk proxy diff -rq /tmp/dz-src/dayz/project/ ui-design/current/ || true   # 复核
```

`--delete` 让 current/ 严格镜像最新设计(旧版已归档)。

### 4. 构建两个单文件 standalone(字体子集化需联网 → 禁沙箱)

```bash
cd ui-design
python3 build-standalone.py current/index.html dayz-prototype.html                         # 原型(自动跟随跳转壳到真入口)
python3 build-standalone.py "current/DayZ 设计规范/DayZ 设计规范.html" dayz-design-spec.html  # 规范页
```

每条都应打印两行 OK:`外部字体请求残留: 0 (完全离线 ✓)` 和 `自检: 无残留相对引用 ✓`。
- 若打印「N 处相对引用未内联」→ 有新资源加载方式没覆盖(见构建器要点),排查。
- 若打印「回退在线 link」→ 字体子集抓取失败(没联网/被沙箱挡/Google 改了接口),产物仍需联网才显示设计字体。**构建这步要禁沙箱**(`dangerouslyDisableSandbox: true`),否则没外网必然回退。

### 5. headless 验证(必做,别假设成功 —— 禁沙箱)

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
URL=$(python3 -c "import pathlib;print(pathlib.Path('$PWD/dayz-prototype.html').as_uri())")
"$CHROME" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=10000 \
  --run-all-compositor-stages-before-draw \
  --screenshot=/tmp/dz-shot.png --window-size=1440,940 "$URL"
```

验证两点:① 截图非空白(原型真渲染);② DOM 里运行时 iframe 已被改写成 srcdoc:
```bash
"$CHROME" --headless=new --no-sandbox --virtual-time-budget=6000 --dump-dom "$URL" > /tmp/dz-dom.html 2>/dev/null
grep -c 'srcdoc=' /tmp/dz-dom.html              # 应 >0(shim 生效)
grep -c 'src="screens/' /tmp/dz-dom.html        # 应 =0(无未改写残留)
```
回显延迟时把截图 `SendUserFile` 给用户肉眼确认。

### 6. git 对比 + 摘要(不自动 commit)

```bash
rtk proxy git status --short ui-design/
rtk proxy git diff --stat -- ui-design/current/
```
给用户:改了/新增/删了哪些、standalone 验证结果。等用户拍板再谈 commit。

### 7. 清理

```bash
rm -f /tmp/dayz-design.bin /tmp/dz-shot.png /tmp/dz-dom.html && rm -rf /tmp/dz-src
```

> ⚠️ 清理别用 `rm -f /tmp/dz-*.txt` 这种通配,会把你正在写、待 Read 的报告文件自己删掉(踩过)。删具体文件名。

## 构建器要点(`build-standalone.py`)

- **纯内联模式**(规范页等自包含页):`<link>`CSS、`<script src>`、`<img>`、CSS `url()` 全内联,递归把静态 `<iframe src=*.html>` 内联进 srcdoc。
- **原型打包模式**(DayZ 页面设计:`app.js` 运行时动态建 `iframe.src="screens/{id}.html?state=..&theme=..&mode=.."`):把每个 `screens/*.html` 内联成自包含 HTML 打包进 `window.__DZ_SCREENS__`,注入 **iframe src setter 拦截 + MutationObserver shim**,把运行时 iframe 的 `src` 改写成自包含 `srcdoc`(屏顶引导脚本读 `location.search`,shim 短路成构建期 query)。**对设计师 app.js 零侵入**——只依赖「`screens/{id}.html` + query」这一稳定约定。
- **字体子集化内联(首屏提速关键)**:扫描所有可见文字 → 向 Google Fonts `css2?...&text=<用到的字>` 请求超小子集 → 把返回 CSS 里的 gstatic woff2 逐个 base64 内联为 `@font-face`。字体只存 1 份(`window.__DZ_FONTS__`):父页直接内联,各屏 srcdoc 里留 `<!--__DZ_FONTS__-->` 占位由 shim 运行时注入,**避免 6 屏 × 字体的 N 倍膨胀**。失败(没网/被沙箱挡)自动回退在线 `<link>` 并打印提示。早期「首次慢」就是没做这步、要在线下中文字体所致。
- **大图重压**:`>200KB` 的 png/jpg 用 macOS `sips` 降采样(长边≤1200)+ 转 JPEG 再 base64,原型从 8.9M 降到 ~5.3M。
- 入口给跳转壳(`index.html`)会自动跟随 meta-refresh / `location.replace` 到真入口。
- 自动判别两模式:入口同级有 `screens/` 且引用 `app.js` → 原型打包,否则纯内联。
- **若设计大改了加载方式**(改用 `fetch` 拉屏 / ES module / 改了 screens 路径约定),shim 可能失效:headless 验证会暴露(屏白屏 / `src="screens/` 残留),届时按新约定扩展 shim。
- **若 Google Fonts 接口/字族变化**导致回退在线 link:检查 `build_font_style`(text= 拼接、gstatic url 正则)。设计字符数 >1800 会主动回退(子集 URL 过长)。

## 红线 / 注意

- **始终用中文**回复。**未经用户明确许可严禁 `git commit` / push**,只展示 status/diff。作者署名 `@Ray`。
- 只动 `ui-design/`。确认它没进 `pubspec.yaml` 的 `flutter: assets:`。
- `_archive/` 体积会涨,默认保留(便于 `diff -rq` 比两版);用户嫌大再商量留最近 N 版或 `.gitignore`。
- **不替设计师改设计内容**;本 skill 只做搬运 + 单文件可预览化。
- **交付物是单文件 standalone,不要 preview.sh / 本地服务器**(用户明确要求)。
- 格式以**实际拉到的**为准(端点理论下发 gzip tar,变了先摸清再解包)。

## 维护

目标目录、`build-standalone.py`、`OPEN.md` 绑定 DayZ;拉取/归档/diff/内联/shim 的骨架是通用方法学。哪天 DayZ 用真 UI 层取代设计稿参考,或目标目录迁移,回来改「目录约定」「构建器要点」即可。
