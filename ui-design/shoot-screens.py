#!/usr/bin/env python3
"""
shoot-screens.py — 把 DayZ 原型屏渲成「真机竖版」展示截图(README / 界面一览用)。

为什么单独写它(而不是用设计师 docs/screenshots/ 的 shots.json + html-to-image):
  - 设计师那套走 html-to-image 抓「屏」DOM,**捕获不到 iframe**,且屏按预览视口(~908px)
    铺满 → 出 924×540 的「宽屏拉伸」图;状态还要靠注入 prep 手切,易出「默认态+目标态
    同时显示」的叠加 bug(04-editor 双标题就是这么来的)。
  - 这里把每屏塞进一个 393×852、overflow:hidden 的 iframe 容器,再用 headless Chrome 截图,
    得到的就是真机竖版比例;主题 / 明暗 / 状态全靠屏自己的 ?theme=&mode=&state= URL 参数 +
    screen.js 驱动(和交互原型同一条路),**不注入 prep**,也就没有状态叠加、动画冻结的坑。

用法(仅 macOS,依赖 Google Chrome + sips):
  python3 ui-design/shoot-screens.py                 # 按下方 SHOTS 出全部(当前默认全雾紫)
  python3 ui-design/shoot-screens.py timeline editor # 只出指定几屏(按 out 或 screen 名)
  python3 ui-design/shoot-screens.py --theme sage    # 强制把所有屏覆盖成某主题色
  python3 ui-design/shoot-screens.py --width 786     # 自定义输出宽(默认缩到 600;0=不缩放)
  python3 ui-design/shoot-screens.py --out /tmp/out  # 改输出目录(默认 ui-design/screenshots)

Chrome 路径可用环境变量 CHROME 覆盖。要改出哪些屏 → 直接编辑下方 SHOTS;
屏 id 与可用 state 见 ui-design/current/pages/screens/ 和 pages/assets/app.js 的 SCREENS。
"""
import os
import sys
import shutil
import tempfile
import subprocess
import urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
SCREENS = os.path.join(HERE, "current", "pages", "screens")
DEFAULT_OUT = os.path.join(HERE, "screenshots")
CHROME = os.environ.get(
    "CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
)

# 设备视口(iPhone 逻辑像素)+ 2x 高清渲染
VW, VH, SCALE = 393, 852, 2

# 要出的屏:out=输出文件名 / screen=屏 id / theme=主题色 / mode=明暗 / state=状态
#   theme: purple | amber | sage      mode: light | dark
#   state: 见各屏在 app.js 里登记的 states(如 editor 的 rich、search 的 results)
SHOTS = [
    # 时间线作「同一屏 · 浅/深」对照(代表性首页);其余屏统一浅色,主题色全雾紫。
    {"out": "timeline",      "screen": "timeline",  "theme": "purple", "mode": "light", "state": "default"},
    {"out": "timeline-dark", "screen": "timeline",  "theme": "purple", "mode": "dark",  "state": "default"},
    {"out": "reader",        "screen": "reader",    "theme": "purple", "mode": "light", "state": "default"},
    {"out": "onthisday",     "screen": "onthisday", "theme": "purple", "mode": "light", "state": "default"},
    {"out": "editor",        "screen": "editor",    "theme": "purple", "mode": "light", "state": "rich"},
    {"out": "settings",      "screen": "settings",  "theme": "purple", "mode": "light", "state": "default"},
]

# 393×852、overflow:hidden 的手机容器——iframe 把屏裁成真机比例(与交互原型的 iPhone 外框同理)
WRAPPER = (
    '<!doctype html><html><head><meta charset="utf-8"><style>'
    "html,body{{margin:0;padding:0;width:{w}px;height:{h}px;overflow:hidden;background:transparent}}"
    "iframe{{width:{w}px;height:{h}px;border:0;display:block}}"
    "</style></head><body><script>"
    "var src=new URLSearchParams(location.search).get('src');"
    "var f=document.createElement('iframe');f.setAttribute('scrolling','no');f.src=src;"
    "document.body.appendChild(f);"
    "</script></body></html>"
).format(w=VW, h=VH)


def parse_args(argv):
    opts = {"theme": None, "out": DEFAULT_OUT, "width": 600, "only": []}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("-h", "--help"):
            print(__doc__)
            sys.exit(0)
        elif a == "--theme":
            opts["theme"] = argv[i + 1]; i += 2
        elif a == "--out":
            opts["out"] = argv[i + 1]; i += 2
        elif a == "--width":
            opts["width"] = int(argv[i + 1]); i += 2
        elif a == "--no-resize":
            opts["width"] = 0; i += 1
        elif a.startswith("-"):
            print("未知参数:", a, "(--help 看用法)"); sys.exit(2)
        else:
            opts["only"].append(a); i += 1
    return opts


def main():
    o = parse_args(sys.argv[1:])

    if not os.path.exists(CHROME):
        print("找不到 Chrome:", CHROME, "— 用环境变量 CHROME 指定路径")
        return 1
    has_sips = shutil.which("sips") is not None
    if o["width"] and not has_sips:
        print("警告:找不到 sips,跳过缩放,直接输出 %dx 原图" % SCALE)

    shots = [s for s in SHOTS if not o["only"] or s["out"] in o["only"] or s["screen"] in o["only"]]
    if not shots:
        print("没有匹配的屏:", o["only"]); return 2

    os.makedirs(o["out"], exist_ok=True)
    fd, wrapper_path = tempfile.mkstemp(suffix=".html")
    with os.fdopen(fd, "w") as f:
        f.write(WRAPPER)
    wrapper_uri = "file://" + urllib.parse.quote(wrapper_path)

    rc = 0
    try:
        for s in shots:
            theme = o["theme"] or s["theme"]
            inner = "file://{dir}/{scr}.html?theme={t}&mode={m}&state={st}".format(
                dir=urllib.parse.quote(SCREENS), scr=s["screen"],
                t=theme, m=s["mode"], st=s["state"])
            url = wrapper_uri + "?src=" + urllib.parse.quote(inner, safe="")
            png = os.path.join(o["out"], s["out"] + ".png")
            cmd = [
                CHROME, "--headless=new", "--hide-scrollbars",
                "--force-device-scale-factor=%d" % SCALE,
                "--window-size=%d,%d" % (VW, VH),
                "--virtual-time-budget=6000", "--allow-file-access-from-files",
                "--screenshot=" + png, url,
            ]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=90)
            if o["width"] and has_sips and os.path.exists(png):
                subprocess.run(["sips", "--resampleWidth", str(o["width"]), png],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            ok = os.path.exists(png) and os.path.getsize(png) > 0
            if not ok:
                rc = 1
            print("  %s %-10s %s/%s/%s%s" % (
                "OK " if ok else "ERR", s["out"], theme, s["mode"], s["state"],
                "" if ok else "  ← 未生成"))
    finally:
        os.unlink(wrapper_path)

    print("→ 输出:", o["out"])
    return rc


if __name__ == "__main__":
    sys.exit(main())
