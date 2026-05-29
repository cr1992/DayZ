/* ============================================================
   Prototype Kit · 外壳脚本（viewer）—— 与业务解耦的通用外壳
   主题/明暗(下发各 iframe) · 原型 iframe 路由栈 · 无限画布浏览 · 左侧索引
   ★ 复用时：只改下方 SCREENS[]，并替换 tokens.css + 写 screens/*.html
   ============================================================ */
(function () {
  "use strict";
  var root = document.documentElement;
  var KEY = "protokit-pages-pref";
  var load = function () { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { return {}; } };
  var save = function (p) { try { localStorage.setItem(KEY, JSON.stringify(p)); } catch (e) {} };

  var pref = load();
  var theme = pref.theme || "purple";
  var mode = pref.mode || "light";
  var present = pref.present === "canvas" ? "canvas" : "proto";

  /* 屏幕清单 + 状态 —— ★ 唯一的业务耦合点。每屏一项：
     {id:文件名, idx:序号, name:中文名, label:副标题, proto:原型默认态, states:[{k,n}…]} */
  var SCREENS = [
    { id: "home", idx: "01", name: "首页", label: "Home · 列表", proto: "default",
      states: [{ k: "default", n: "默认" }, { k: "empty", n: "空状态" }] },
    { id: "detail", idx: "02", name: "详情", label: "Detail", proto: "default",
      states: [{ k: "default", n: "默认" }] }
  ];
  var byId = {}; SCREENS.forEach(function (s) { byId[s.id] = s; });
  var srcOf = function (id, state) {
    return "screens/" + id + ".html?state=" + state + "&theme=" + theme + "&mode=" + mode;
  };

  var ws = document.getElementById("workspace");
  var protoHost = document.getElementById("protoHost");
  var protoStack = document.getElementById("protoStack");
  var board = document.getElementById("board");
  var rail = document.getElementById("canvasRail");

  /* ---------- 主题 / 明暗 ---------- */
  function persist() { save({ theme: theme, mode: mode, present: present }); }
  function broadcastTheme() {
    document.querySelectorAll(".workspace iframe").forEach(function (f) {
      try { f.contentWindow.postMessage({ type: "theme", theme: theme, mode: mode }, "*"); } catch (e) {}
    });
  }
  function applyTheme() {
    root.setAttribute("data-theme", theme);
    root.setAttribute("data-mode", mode);
    document.querySelectorAll(".swatch-btn").forEach(function (b) { b.setAttribute("aria-pressed", String(b.dataset.set === theme)); });
    var mt = document.getElementById("modeToggle");
    if (mt) mt.querySelector(".lbl").textContent = mode === "light" ? "浅色" : "深色";
    broadcastTheme();
    persist();
  }

  /* ---------- 原型路由栈（页面缓存 · 预热 → 跳转秒开）---------- */
  var stack = [];
  var pageCache = {};
  var ztop = 0;
  function getPage(id) {
    if (pageCache[id]) return pageCache[id];
    var page = document.createElement("div");
    page.className = "proto-page is-parked";
    page.dataset.screen = id;
    var f = document.createElement("iframe");
    f.src = srcOf(id, byId[id].proto);
    f.setAttribute("title", byId[id] ? byId[id].name : id);
    page.appendChild(f);
    protoStack.appendChild(page);
    pageCache[id] = page;
    return page;
  }
  function pushScreen(id, animate) {
    if (!byId[id]) return;
    var prev = stack.length ? pageCache[stack[stack.length - 1]] : null;
    var page = getPage(id);
    page.style.zIndex = ++ztop;
    page.classList.remove("is-parked", "is-leaving", "is-behind");
    stack.push(id);
    if (animate === false) { if (prev) prev.classList.add("is-behind"); return; }
    page.classList.add("is-entering");
    void page.offsetWidth;
    requestAnimationFrame(function () {
      page.classList.remove("is-entering");
      if (prev) prev.classList.add("is-behind");
    });
  }
  function popScreen() {
    if (stack.length <= 1) return;
    var topId = stack.pop();
    var page = pageCache[topId];
    var prev = pageCache[stack[stack.length - 1]];
    if (prev) prev.classList.remove("is-behind");
    page.classList.add("is-leaving");
    setTimeout(function () {
      if (stack.indexOf(topId) === -1) { page.classList.add("is-parked"); page.classList.remove("is-leaving"); }
    }, 420);
  }
  var protoBuilt = false;
  function buildProto() {
    if (protoBuilt) return;
    pushScreen("timeline", false);
    protoBuilt = true;
    /* 空闲时预热其余屏 → 后续跳转无加载等待 */
    var warm = function () { SCREENS.forEach(function (s) { if (s.id !== "timeline") getPage(s.id); }); };
    if (window.requestIdleCallback) requestIdleCallback(warm, { timeout: 1500 }); else setTimeout(warm, 500);
  }

  /* 来自 iframe 的导航消息 */
  window.addEventListener("message", function (e) {
    var d = e.data || {};
    if (d.type === "nav") { if (present === "proto") pushScreen(d.to, true); }
    else if (d.type === "back") { if (present === "proto") popScreen(); }
    else if (d.type === "ready") { try { e.source.postMessage({ type: "theme", theme: theme, mode: mode }, "*"); } catch (_) {} }
  });

  /* ---------- 画布（无限画布 · 平移缩放浏览 · 卡片可交互）---------- */
  var world = document.getElementById("canvasWorld");
  var view = { x: 0, y: 0, k: 0.6 };
  var MIN_K = 0.2, MAX_K = 2, GRID = 26;
  var pctEl = null, canvasBuilt = false;

  function applyView() {
    world.style.transform = "translate(" + view.x + "px," + view.y + "px) scale(" + view.k + ")";
    board.style.backgroundSize = (GRID * view.k) + "px " + (GRID * view.k) + "px";
    board.style.backgroundPosition = view.x + "px " + view.y + "px";
    if (pctEl) pctEl.textContent = Math.round(view.k * 100) + "%";
    updateRailActive();
  }
  function clampK(k) { return Math.max(MIN_K, Math.min(MAX_K, k)); }
  function zoomAt(cx, cy, nk) {
    nk = clampK(nk);
    var wx = (cx - view.x) / view.k, wy = (cy - view.y) / view.k;
    view.k = nk; view.x = cx - wx * nk; view.y = cy - wy * nk;
    applyView();
  }
  function resetView() {
    var r = board.getBoundingClientRect();
    var contentW = world.scrollWidth || 1000;
    var k = clampK(Math.min(0.62, (r.width - 96) / contentW));
    view.k = k;
    view.x = Math.max(32, (r.width - contentW * k) / 2);
    view.y = 36;
    applyView();
  }
  function zoomStep(f) { var r = board.getBoundingClientRect(); zoomAt(r.width / 2, r.height / 2, view.k * f); }

  function buildCanvas() {
    if (canvasBuilt) { return; }
    rail.innerHTML = '<div class="rail-title">页面 · ' + SCREENS.length + "</div>";
    SCREENS.forEach(function (s) {
      var it = document.createElement("div");
      it.className = "rail-item";
      it.innerHTML = '<span class="ri-idx">' + s.idx + '</span><span class="ri-nm">' + s.name + "</span>";
      it.addEventListener("click", function () { focusSection(s.id); });
      it.dataset.sec = s.id;
      rail.appendChild(it);

      var sec = document.createElement("section");
      sec.className = "cv-section";
      sec.id = "sec-" + s.id;
      var cards = s.states.map(function (st) {
        return '<div class="cv-card"><div class="cv-cap">' + st.n + '</div>' +
          '<div class="cv-frame"><iframe loading="lazy" src="' + srcOf(s.id, st.k) + '" title="' + s.name + " · " + st.n + '"></iframe></div></div>';
      }).join("");
      sec.innerHTML = '<div class="cv-head"><span class="idx">' + s.idx + '</span><span class="nm">' + s.name + '</span><span class="lbl">' + s.label + '</span></div><div class="cv-row">' + cards + "</div>";
      world.appendChild(sec);
    });
    buildZoomCtl();
    bindCanvasInput();
    canvasBuilt = true;
    requestAnimationFrame(resetView);
  }

  function buildZoomCtl() {
    var z = document.createElement("div");
    z.className = "cv-zoom";
    z.innerHTML =
      '<button data-z="out" title="缩小 · −"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M5 12h14"/></svg></button>' +
      '<span class="pct" data-z="reset" title="重置视图 · 0">60%</span>' +
      '<button data-z="in" title="放大 · +"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg></button>';
    board.appendChild(z);
    pctEl = z.querySelector(".pct");
    z.addEventListener("click", function (e) {
      var t = e.target.closest("[data-z]"); if (!t) return;
      var r = board.getBoundingClientRect(), cx = r.width / 2, cy = r.height / 2;
      if (t.dataset.z === "in") zoomAt(cx, cy, view.k * 1.25);
      else if (t.dataset.z === "out") zoomAt(cx, cy, view.k / 1.25);
      else resetView();
    });
  }

  /* 空格临时平移（卡片可交互，故空白拖拽 / 滚轮 / 空格+拖拽 都能平移）*/
  var spaceHeld = false;
  function setSpace(on) {
    if (spaceHeld === on) return;
    spaceHeld = on;
    if (present === "canvas") board.classList.toggle("space-pan", on);
  }

  function bindCanvasInput() {
    board.addEventListener("wheel", function (e) {
      e.preventDefault();
      var r = board.getBoundingClientRect();
      if (e.ctrlKey || e.metaKey) {
        zoomAt(e.clientX - r.left, e.clientY - r.top, view.k * Math.exp(-e.deltaY * 0.0016));
      } else {
        view.x -= e.deltaX; view.y -= e.deltaY; applyView();
      }
    }, { passive: false });

    var drag = false, sx = 0, sy = 0, ox = 0, oy = 0;
    board.addEventListener("pointerdown", function (e) {
      if (e.button !== 0) return;
      if (e.target.closest(".cv-zoom")) return; /* 缩放控件不触发平移 */
      var onCard = !!e.target.closest(".cv-card");
      if (!(spaceHeld || !onCard)) return; /* 卡片上不按空格 → 交给 iframe 交互 */
      drag = true; sx = e.clientX; sy = e.clientY; ox = view.x; oy = view.y;
      board.classList.add("is-panning");
      try { board.setPointerCapture(e.pointerId); } catch (_) {}
    });
    board.addEventListener("pointermove", function (e) {
      if (!drag) return;
      view.x = ox + (e.clientX - sx); view.y = oy + (e.clientY - sy);
      applyView();
    });
    function end() { if (!drag) return; drag = false; board.classList.remove("is-panning"); }
    board.addEventListener("pointerup", end);
    board.addEventListener("pointercancel", end);
    window.addEventListener("resize", function () { if (present === "canvas") updateRailActive(); });
  }

  /* 空格平移 + 缩放快捷键（仅画布、焦点不在输入框）*/
  document.addEventListener("keydown", function (e) {
    if (present !== "canvas") return;
    var t = e.target || {};
    if (/^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName || "") || t.isContentEditable) return;
    if (e.code === "Space") { e.preventDefault(); setSpace(true); return; }
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    if (e.key === "=" || e.key === "+") { e.preventDefault(); zoomStep(1.25); }
    else if (e.key === "-" || e.key === "_") { e.preventDefault(); zoomStep(1 / 1.25); }
    else if (e.key === "0") { e.preventDefault(); resetView(); }
  });
  document.addEventListener("keyup", function (e) { if (e.code === "Space") setSpace(false); });

  function focusSection(id) {
    var sec = document.getElementById("sec-" + id);
    if (!sec) return;
    var r = board.getBoundingClientRect();
    var cx = sec.offsetLeft + sec.offsetWidth / 2;
    view.x = r.width / 2 - cx * view.k;
    view.y = 48 - sec.offsetTop * view.k;
    applyView();
    setActiveRail(id);
  }
  function setActiveRail(id) {
    rail.querySelectorAll(".rail-item").forEach(function (el) { el.classList.toggle("on", el.dataset.sec === id); });
  }
  function updateRailActive() {
    var best = SCREENS[0].id, bestTop = -Infinity;
    SCREENS.forEach(function (s) {
      var sec = document.getElementById("sec-" + s.id);
      if (!sec) return;
      var st = view.y + sec.offsetTop * view.k;
      if (st <= 160 && st > bestTop) { bestTop = st; best = s.id; }
    });
    setActiveRail(best);
  }

  /* ---------- 呈现模式 ---------- */
  function applyPresent() {
    ws.classList.toggle("mode-canvas", present === "canvas");
    ws.classList.toggle("mode-proto", present === "proto");
    document.querySelectorAll(".seg-present button[data-present]").forEach(function (b) { b.setAttribute("aria-selected", String(b.dataset.present === present)); });
    if (present === "canvas") { buildCanvas(); updateRailActive(); }
    else { buildProto(); }
    persist();
  }

  /* ---------- 顶栏点击 ---------- */
  document.addEventListener("click", function (e) {
    var sw = e.target.closest(".swatch-btn");
    if (sw) { theme = sw.dataset.set; applyTheme(); return; }
    if (e.target.closest("#modeToggle")) { mode = mode === "light" ? "dark" : "light"; applyTheme(); return; }
    var pb = e.target.closest(".seg-present button[data-present]");
    if (pb) { present = pb.dataset.present; applyPresent(); return; }
  });

  /* ---------- 初始化 ---------- */
  applyTheme();
  applyPresent();
})();
