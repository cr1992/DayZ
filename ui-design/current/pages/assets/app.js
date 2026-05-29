/* ============================================================
   DayZ · 外壳脚本（viewer）
   主题/明暗(下发各 iframe) · 原型 iframe 路由栈 · 静态画布 · 左侧索引
   ============================================================ */
(function () {
  "use strict";
  var root = document.documentElement;
  var KEY = "dayz-pages-pref";
  var load = function () { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { return {}; } };
  var save = function (p) { try { localStorage.setItem(KEY, JSON.stringify(p)); } catch (e) {} };

  var pref = load();
  var theme = pref.theme || "purple";
  var mode = pref.mode || "light";
  var present = pref.present === "canvas" ? "canvas" : "proto";

  /* 屏幕清单 + 状态 */
  var SCREENS = [
    { id: "timeline", idx: "01", name: "时间线", label: "Timeline · 首页", proto: "default",
      states: [{ k: "default", n: "默认" }, { k: "drawer", n: "抽屉打开" }, { k: "empty", n: "空状态" }] },
    { id: "reader", idx: "02", name: "阅读页", label: "Entry · 全文", proto: "default",
      states: [{ k: "default", n: "含封面" }, { k: "text", n: "纯文字" }] },
    { id: "editor", idx: "03", name: "编辑页", label: "Compose · AppFlowy", proto: "writing",
      states: [{ k: "empty", n: "空白新建" }, { k: "writing", n: "书写中" }, { k: "rich", n: "富格式" }] },
    { id: "onthisday", idx: "04", name: "往年今日", label: "On This Day", proto: "default",
      states: [{ k: "default", n: "有内容" }, { k: "empty", n: "空" }] },
    { id: "search", idx: "05", name: "搜索", label: "Search", proto: "results",
      states: [{ k: "typing", n: "输入中" }, { k: "results", n: "有结果" }, { k: "empty", n: "无结果" }] },
    { id: "settings", idx: "06", name: "设置", label: "Settings", proto: "default",
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

  /* ---------- 画布（静态多状态）---------- */
  var canvasBuilt = false;
  function buildCanvas() {
    if (canvasBuilt) return;
    rail.innerHTML = '<div class="rail-title">页面 · ' + SCREENS.length + "</div>";
    SCREENS.forEach(function (s) {
      var it = document.createElement("div");
      it.className = "rail-item";
      it.innerHTML = '<span class="ri-idx">' + s.idx + '</span><span class="ri-nm">' + s.name + "</span>";
      it.addEventListener("click", function () { scrollToSection(s.id); });
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
      board.appendChild(sec);
    });
    board.addEventListener("scroll", updateRailActive);
    canvasBuilt = true;
  }
  function scrollToSection(id) {
    var sec = document.getElementById("sec-" + id);
    if (sec) board.scrollTo({ top: Math.max(0, sec.offsetTop - 24), behavior: "smooth" });
    setActiveRail(id);
  }
  function setActiveRail(id) {
    rail.querySelectorAll(".rail-item").forEach(function (el) { el.classList.toggle("on", el.dataset.sec === id); });
  }
  function updateRailActive() {
    var top = board.scrollTop + 60, best = SCREENS[0].id, bd = Infinity;
    SCREENS.forEach(function (s) {
      var sec = document.getElementById("sec-" + s.id);
      if (!sec) return;
      var d = Math.abs(sec.offsetTop - top);
      if (sec.offsetTop <= top + 40 && d < bd) { bd = d; best = s.id; }
    });
    setActiveRail(best);
  }

  /* ---------- 呈现模式 ---------- */
  function applyPresent() {
    ws.classList.toggle("mode-canvas", present === "canvas");
    ws.classList.toggle("mode-proto", present === "proto");
    document.querySelectorAll(".seg-present button").forEach(function (b) { b.setAttribute("aria-selected", String(b.dataset.present === present)); });
    if (present === "canvas") { buildCanvas(); updateRailActive(); }
    else { buildProto(); }
    persist();
  }

  /* ---------- 顶栏点击 ---------- */
  document.addEventListener("click", function (e) {
    var sw = e.target.closest(".swatch-btn");
    if (sw) { theme = sw.dataset.set; applyTheme(); return; }
    if (e.target.closest("#modeToggle")) { mode = mode === "light" ? "dark" : "light"; applyTheme(); return; }
    var pb = e.target.closest(".seg-present button");
    if (pb) { present = pb.dataset.present; applyPresent(); return; }
  });

  /* ---------- 初始化 ---------- */
  applyTheme();
  applyPresent();
})();
