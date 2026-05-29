#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DayZ 设计稿 → 单文件 standalone HTML 构建器。

产出「双击即开、完全离线、首屏快」的单文件 HTML。两种模式自动判别:

A) 纯内联(设计规范页等自包含页):
   <link>CSS / <script src> / <img> / CSS url() 全部内联(图转 data:、大图先重压缩)，
   递归把静态 <iframe src=*.html> 内联进 srcdoc。

B) 原型打包(DayZ 页面设计:app.js 运行时动态建
   iframe.src="screens/{id}.html?state=..&theme=..&mode=.."):
   - 跟随跳转壳到真入口；
   - 把每个 screens/*.html 内联成自包含 HTML，存进 window.__DZ_SCREENS__（query 处烘焙占位）；
   - 注入 shim：拦 iframe src setter + MutationObserver，把运行时 iframe 改写成对应 srcdoc。

首屏提速(两条都在构建期完成，产物零外部请求):
   - 字体子集化内联：扫描全部可见文字 → 向 Google Fonts 请求仅含这些字的超小 woff2 子集
     → base64 内联为 @font-face；字体只存一份(window.__DZ_FONTS__)，各屏运行时注入，避免重复。
   - 大图重压缩：>200KB 的位图用 sips 降采样+转 JPEG，再 base64。
   字体抓取需联网(仅构建时)；产物本身完全离线。抓取失败则回退在线 <link>(产物仍需联网显示字体)。

用法:
  python3 build-standalone.py <入口html> <输出html>
"""
import sys, os, re, base64, mimetypes, json, subprocess, shutil, tempfile, urllib.parse
import html as _html

mimetypes.add_type("font/woff2", ".woff2")
mimetypes.add_type("font/woff", ".woff")
mimetypes.add_type("image/svg+xml", ".svg")

QUERY_PLACEHOLDER = "__DZ_QUERY__"
FONT_TOKEN = "<!--__DZ_FONTS__-->"
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

_GF_URLS = []        # 收集到的 Google Fonts css2 链接(各文档相同)
_DL_CACHE = {}       # url -> bytes / text，避免重复下载

SHIM_JS = r"""
(function(){
  function screens(){ return window.__DZ_SCREENS__ || {}; }
  function docFor(id, q){
    var tpl = screens()[id];
    if (tpl == null) return null;
    var fonts = window.__DZ_FONTS__ || "";
    return tpl.split("__DZ_QUERY__").join(q || "").split("<!--__DZ_FONTS__-->").join(fonts);
  }
  function parse(src){
    var m = String(src || "").match(/(?:^|\/)screens\/([^\/?#]+)\.html(\?[^"'#]*)?/);
    return m ? { id: m[1], q: m[2] || "" } : null;
  }
  function rewrite(f){
    if (!f || f.tagName !== "IFRAME") return;
    var src = f.getAttribute && f.getAttribute("src");
    if (!src) return;
    var p = parse(src); if (!p) return;
    var d = docFor(p.id, p.q); if (d == null) return;
    f.removeAttribute("src");
    f.setAttribute("srcdoc", d);
  }
  try {
    var desc = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, "src");
    if (desc && desc.set) {
      Object.defineProperty(HTMLIFrameElement.prototype, "src", {
        configurable: true, enumerable: desc.enumerable,
        get: function(){ return desc.get.call(this); },
        set: function(v){
          var p = parse(v);
          if (p) { var d = docFor(p.id, p.q); if (d != null) { this.srcdoc = d; return; } }
          desc.set.call(this, v);
        }
      });
    }
  } catch (e) {}
  function scanAll(){ try { document.querySelectorAll("iframe[src]").forEach(rewrite); } catch (e) {} }
  var mo = new MutationObserver(function(muts){
    muts.forEach(function(mu){
      if (mu.type === "attributes") rewrite(mu.target);
      (mu.addedNodes || []).forEach(function(n){
        if (n.nodeType !== 1) return;
        if (n.tagName === "IFRAME") rewrite(n);
        if (n.querySelectorAll) n.querySelectorAll("iframe[src]").forEach(rewrite);
      });
    });
  });
  function start(){
    mo.observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ["src"] });
    scanAll();
  }
  if (document.documentElement) start();
  else document.addEventListener("DOMContentLoaded", start);
})();
"""


# ---------------- 基础工具 ----------------

def is_external(u):
    u = (u or "").strip()
    return (not u) or u.startswith(("http://", "https://", "//", "data:", "#",
                                    "mailto:", "tel:", "javascript:", "blob:", "about:")) or u.startswith("/")


def resolve(base_dir, url):
    url = url.split("?")[0].split("#")[0]
    return os.path.normpath(os.path.join(base_dir, url))


def _img_bytes(path):
    """读图;大位图用 sips 降采样+转 JPEG。返回 (bytes, mime)。"""
    try:
        size = os.path.getsize(path)
    except OSError:
        size = 0
    ext = path.lower().rsplit(".", 1)[-1] if "." in path else ""
    if ext in ("png", "jpg", "jpeg") and size > 200 * 1024 and shutil.which("sips"):
        tmp = tempfile.mktemp(suffix=".jpg")
        try:
            r = subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "72",
                                "-Z", "1200", path, "--out", tmp],
                               capture_output=True, timeout=60)
            if r.returncode == 0 and os.path.isfile(tmp):
                b = open(tmp, "rb").read()
                if b and len(b) < size:
                    return b, "image/jpeg"
        except Exception:
            pass
        finally:
            if os.path.exists(tmp):
                try: os.remove(tmp)
                except OSError: pass
    return open(path, "rb").read(), (mimetypes.guess_type(path)[0] or "application/octet-stream")


def data_uri(path):
    b, mime = _img_bytes(path)
    return "data:%s;base64,%s" % (mime, base64.b64encode(b).decode("ascii"))


def inline_css_urls(css, css_dir):
    def repl(m):
        raw = m.group(1).strip().strip('\'"')
        if is_external(raw):
            return m.group(0)
        p = resolve(css_dir, raw)
        if os.path.isfile(p):
            try:
                return "url('%s')" % data_uri(p)
            except Exception:
                return m.group(0)
        return m.group(0)
    return re.sub(r"url\(\s*([^)]+?)\s*\)", repl, css)


# ---------------- HTML 内联 ----------------

def inline_html(path, _seen=None):
    if _seen is None:
        _seen = set()
    path = os.path.normpath(path)
    base_dir = os.path.dirname(path)
    with open(path, "r", encoding="utf-8") as f:
        doc = f.read()

    # 1) <link>: Google Fonts → 占位/删除；本地 stylesheet → 内联
    def link_repl(m):
        tag = m.group(0)
        hm = re.search(r'href\s*=\s*["\']([^"\']+)["\']', tag, re.I)
        href = hm.group(1) if hm else ""
        if "fonts.googleapis.com/css" in href:
            _GF_URLS.append(href)
            return FONT_TOKEN
        if "fonts.gstatic.com" in href or "fonts.googleapis.com" in href:
            return ""  # preconnect / dns-prefetch
        if "stylesheet" not in tag.lower() or not href or is_external(href):
            return tag
        p = resolve(base_dir, href)
        if not os.path.isfile(p):
            return tag
        css = open(p, "r", encoding="utf-8").read()
        return "<style>\n%s\n</style>" % inline_css_urls(css, os.path.dirname(p))
    doc = re.sub(r"<link\b[^>]*>", link_repl, doc, flags=re.I)
    # 去重：同一文档多个 Google Fonts link 只留一个占位
    if doc.count(FONT_TOKEN) > 1:
        first = doc.find(FONT_TOKEN)
        doc = doc[:first + len(FONT_TOKEN)] + doc[first + len(FONT_TOKEN):].replace(FONT_TOKEN, "")

    # 2) <script src="local"></script> → 内联（只从开标签取属性，丢弃原闭合）
    def script_repl(m):
        attrs_raw = m.group(1)
        sm = re.search(r'src\s*=\s*["\']([^"\']+)["\']', attrs_raw, re.I)
        if not sm or is_external(sm.group(1)):
            return m.group(0)
        p = resolve(base_dir, sm.group(1))
        if not os.path.isfile(p):
            return m.group(0)
        js = open(p, "r", encoding="utf-8").read().replace("</script", "<\\/script")
        attrs = re.sub(r'\ssrc\s*=\s*["\'][^"\']+["\']', "", attrs_raw, flags=re.I).rstrip(" /")
        return "<script%s>\n%s\n</script>" % (attrs, js)
    doc = re.sub(r"<script\b([^>]*)>\s*</script>", script_repl, doc, flags=re.I)

    # 3) <iframe src="local.html"> → srcdoc（递归内联静态 iframe）
    def iframe_repl(m):
        tag = m.group(0)
        sm = re.search(r'src\s*=\s*["\']([^"\']+)["\']', tag, re.I)
        if not sm or is_external(sm.group(1)):
            return tag
        p = resolve(base_dir, sm.group(1))
        if not (os.path.isfile(p) and p.lower().endswith((".html", ".htm"))) or p in _seen:
            return tag
        inner = inline_html(p, _seen | {p})
        notag = re.sub(r'\ssrc\s*=\s*["\'][^"\']+["\']', "", tag, flags=re.I)
        notag = re.sub(r"\s*/?>$", "", notag.strip())
        return '%s srcdoc="%s">' % (notag, _html.escape(inner, quote=True))
    doc = re.sub(r"<iframe\b[^>]*>", iframe_repl, doc, flags=re.I)

    # 4) src/href/poster 本地资源 → data:
    def attr_repl(m):
        whole, attr, url = m.group(0), m.group(1), m.group(2)
        if is_external(url):
            return whole
        p = resolve(base_dir, url)
        if os.path.isfile(p):
            try:
                return '%s="%s"' % (attr, data_uri(p))
            except Exception:
                return whole
        return whole
    doc = re.sub(r'\b(src|href|poster)\s*=\s*["\']([^"\']+)["\']', attr_repl, doc)

    # 5) <style>…</style> 内 url()
    doc = re.sub(r"<style([^>]*)>(.*?)</style>",
                 lambda m: "<style%s>%s</style>" % (m.group(1), inline_css_urls(m.group(2), base_dir)),
                 doc, flags=re.I | re.S)
    return doc


def inline_screen(path):
    """内联 screens/*.html，并把引导脚本对 location.search 的读取短路成构建期 query。"""
    doc = inline_html(path)
    inject = '<script>window.__DZ_Q__="%s";</script>' % QUERY_PLACEHOLDER
    if re.search(r"<head[^>]*>", doc, re.I):
        doc = re.sub(r"(<head[^>]*>)", lambda m: m.group(1) + inject, doc, count=1, flags=re.I)
    else:
        doc = inject + doc
    return doc.replace("location.search", "(window.__DZ_Q__||location.search)")


# ---------------- 字体子集化内联 ----------------

def _curl_text(url):
    if url in _DL_CACHE:
        return _DL_CACHE[url]
    try:
        r = subprocess.run(["curl", "-fsSL", "-A", UA, url], capture_output=True, timeout=40)
        out = r.stdout.decode("utf-8", "replace") if r.returncode == 0 else ""
    except Exception:
        out = ""
    _DL_CACHE[url] = out
    return out


def _curl_bin(url):
    if url in _DL_CACHE:
        return _DL_CACHE[url]
    try:
        r = subprocess.run(["curl", "-fsSL", "-A", UA, url], capture_output=True, timeout=40)
        out = r.stdout if r.returncode == 0 else b""
    except Exception:
        out = b""
    _DL_CACHE[url] = out
    return out


def collect_chars(docs):
    s = set()
    for d in docs:
        t = re.sub(r"<script\b[^>]*>.*?</script>", " ", d, flags=re.I | re.S)
        t = re.sub(r"<style\b[^>]*>.*?</style>", " ", t, flags=re.I | re.S)
        t = re.sub(r"<!--.*?-->", " ", t, flags=re.S)
        t = re.sub(r"<[^>]+>", " ", t)
        t = _html.unescape(t)
        for ch in t:
            if ord(ch) >= 32 and not ch.isspace():
                s.add(ch)
    # 安全兜底常用字符集
    s.update("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
             "·—…、。，！？：；“”‘’（）《》〈〉「」%#@/+-.,:;!?'\"()[]&*~ ")
    s.discard("\n"); s.discard("\t")
    return "".join(sorted(s))


def build_font_style(docs):
    """返回内联 @font-face 的 <style>；失败回退在线 <link>；无字体则空串。"""
    if not _GF_URLS:
        return ""
    orig = _GF_URLS[0]
    fallback = '<link rel="stylesheet" href="%s">' % orig
    chars = collect_chars(docs)
    if len(chars) > 1800:        # text= 过长则放弃子集，回退在线
        print("字体字符数 %d 过多，回退在线 <link>" % len(chars), file=sys.stderr)
        return fallback
    base = re.sub(r"&?(text|display)=[^&]*", "", orig).rstrip("&")
    sep = "&" if "?" in base else "?"
    url = base + sep + "display=swap&text=" + urllib.parse.quote(chars, safe="")
    css = _curl_text(url)
    if not css or "@font-face" not in css:
        print("字体子集抓取失败，回退在线 <link>（产物仍需联网显示字体）", file=sys.stderr)
        return fallback

    def repl(m):
        u = m.group(1)
        data = _curl_bin(u)
        if not data:
            return m.group(0)
        return "url(data:font/woff2;base64,%s) format('woff2')" % base64.b64encode(data).decode("ascii")
    css = re.sub(r"url\((https://fonts\.gstatic\.com/[^)\s]+)\)(\s*format\([^)]*\))?", repl, css)
    if "fonts.gstatic.com" in css:   # 仍有没下成功的，回退
        print("部分字体文件未能内联，回退在线 <link>", file=sys.stderr)
        return fallback
    return "<style>\n%s\n</style>" % css


# ---------------- 入口判定 / 组装 ----------------

def resolve_entry(path):
    """跟随跳转壳(meta-refresh / location.replace)到真入口。"""
    path = os.path.normpath(path)
    for _ in range(6):
        try:
            txt = open(path, "r", encoding="utf-8").read()
        except Exception:
            break
        m = re.search(r'location\.replace\(\s*["\']([^"\']+)["\']', txt) \
            or re.search(r'location\.href\s*=\s*["\']([^"\']+)["\']', txt)
        if not m:
            m = re.search(r'<meta[^>]+http-equiv=["\']?refresh["\']?[^>]*?url=([^"\'>;\s]+)', txt, re.I)
        if not (m and len(txt) < 2000):
            break
        nxt = os.path.normpath(os.path.join(os.path.dirname(path), m.group(1).strip()))
        if os.path.isfile(nxt) and nxt != path:
            path = nxt
            continue
        break
    return path


def is_prototype(entry_real):
    base = os.path.dirname(entry_real)
    if not os.path.isdir(os.path.join(base, "screens")):
        return False
    return bool(re.search(r'src\s*=\s*["\'][^"\']*app\.js', open(entry_real, "r", encoding="utf-8").read()))


def assemble_prototype(parent, screens, font_style, out):
    payload = json.dumps(screens, ensure_ascii=False).replace("</", "<\\/")
    fonts_js = json.dumps(font_style, ensure_ascii=False).replace("</", "<\\/")
    inject = "<script>\n%swindow.__DZ_SCREENS__=%s;\nwindow.__DZ_FONTS__=%s;\n</script>" % (
        SHIM_JS, payload, fonts_js)
    if re.search(r"<head[^>]*>", parent, re.I):
        parent = re.sub(r"(<head[^>]*>)", lambda m: m.group(1) + "\n" + inject, parent, count=1, flags=re.I)
    else:
        parent = inject + parent
    with open(out, "w", encoding="utf-8") as f:
        f.write(parent)


def selfcheck(out):
    txt = open(out, "r", encoding="utf-8").read()
    scan = re.sub(r"<script\b[^>]*>.*?</script>", "", txt, flags=re.I | re.S)
    left = sorted(set(re.findall(
        r'(?:src|href|poster)\s*=\s*"(?!data:|https?:|//|#|mailto:|tel:|about:)([^"]+)"', scan)))
    ext = len(re.findall(r"fonts\.(?:googleapis|gstatic)\.com", txt))
    return len(txt), left, ext


def main():
    if len(sys.argv) != 3:
        print("用法: build-standalone.py <入口html> <输出html>", file=sys.stderr)
        sys.exit(2)
    src, out = sys.argv[1], sys.argv[2]
    real = resolve_entry(src)
    if real != os.path.normpath(src):
        print("入口跟随: %s → %s" % (src, real))

    if is_prototype(real):
        parent = inline_html(real)
        sdir = os.path.join(os.path.dirname(real), "screens")
        screens = {}
        for fn in sorted(os.listdir(sdir)):
            if fn.lower().endswith((".html", ".htm")):
                screens[os.path.splitext(fn)[0]] = inline_screen(os.path.join(sdir, fn))
        font_style = build_font_style([parent] + list(screens.values()))
        parent = parent.replace(FONT_TOKEN, font_style)           # 父页直接内联(1 份)
        # 各屏保留 FONT_TOKEN，运行时由 shim 注入 window.__DZ_FONTS__（字体只存 1 份，避免 N 倍膨胀）
        assemble_prototype(parent, screens, font_style, out)
        mode = "原型打包(%d 屏)" % len(screens)
    else:
        doc = inline_html(real)
        font_style = build_font_style([doc])
        doc = doc.replace(FONT_TOKEN, font_style)
        with open(out, "w", encoding="utf-8") as f:
            f.write(doc)
        mode = "纯内联"

    size, left, ext = selfcheck(out)
    print("OK [%s] → %s  (%.2f MB)" % (mode, out, size / 1048576))
    print("外部字体请求残留: %d %s" % (ext, "(完全离线 ✓)" if ext == 0 else "(回退在线 link)"))
    if left:
        print("提醒: %d 处相对引用未内联: %s" % (len(left), ", ".join(left[:15])), file=sys.stderr)
    else:
        print("自检: 无残留相对引用 ✓")


if __name__ == "__main__":
    main()
