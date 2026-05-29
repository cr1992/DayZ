/* ============================================================
   DayZ · 单屏脚本（运行在每个 screens/*.html 内部）
   注入 iOS chrome · 多状态显隐 · 交互 · postMessage 导航
   ============================================================ */
(function () {
  "use strict";
  var r = document.documentElement;
  var state = r.getAttribute("data-state") || "default";

  /* iOS chrome */
  var CHROME = '<div class="dynamic-island"></div>' +
    '<div class="status-bar"><span class="time">9:41</span><span class="stat">' +
    '<svg viewBox="0 0 18 14" fill="currentColor"><rect x="0" y="9" width="3" height="5" rx="1"/><rect x="5" y="6" width="3" height="8" rx="1"/><rect x="10" y="3" width="3" height="11" rx="1"/><rect x="15" y="0" width="3" height="14" rx="1"/></svg>' +
    '<svg viewBox="0 0 16 12" fill="currentColor"><path d="M8 2.4c2.5 0 4.8.9 6.5 2.5l-1.3 1.4A7.6 7.6 0 0 0 8 4.3c-2 0-3.8.7-5.2 2L1.5 4.9A9.4 9.4 0 0 1 8 2.4z"/><path d="M8 6.1c1.5 0 2.9.6 3.9 1.5l-1.3 1.4A3.6 3.6 0 0 0 8 8c-1 0-2 .4-2.6 1L4 7.6A5.5 5.5 0 0 1 8 6.1z"/><circle cx="8" cy="10.4" r="1.3"/></svg>' +
    '<svg viewBox="0 0 28 14" fill="none"><rect x="0.6" y="0.6" width="22.8" height="12.8" rx="3.4" stroke="currentColor" stroke-opacity="0.4"/><rect x="2.2" y="2.2" width="17.6" height="9.6" rx="2" fill="currentColor"/><path d="M25 4.6c1.3.3 1.3 4.8 0 5.1z" fill="currentColor" fill-opacity="0.5"/></svg>' +
    '</span></div><div class="home-indicator"></div>';
  document.body.insertAdjacentHTML("afterbegin", CHROME);

  /* 多状态显隐 */
  document.querySelectorAll("[data-when]").forEach(function (el) {
    if (el.dataset.when.split(/\s+/).indexOf(state) !== -1) el.classList.add("show");
  });
  /* 时间线「抽屉打开」状态 */
  if (state === "drawer") {
    var ds = document.querySelector(".drawer-stage");
    if (ds) ds.classList.add("open");
  }

  /* 父级主题下发 */
  window.addEventListener("message", function (e) {
    var d = e.data || {};
    if (d.type === "theme") {
      if (d.theme) r.setAttribute("data-theme", d.theme);
      if (d.mode) r.setAttribute("data-mode", d.mode);
    }
  });
  var post = function (m) { try { parent.postMessage(m, "*"); } catch (_) {} };
  /* 就绪后向父级要一次主题（避免初始不同步）*/
  post({ type: "ready" });

  /* ---------- 点击交互 ---------- */
  document.addEventListener("click", function (e) {
    /* 导航（交给父级路由）*/
    if (e.target.closest("[data-nav-back]")) { post({ type: "back" }); return; }
    var navEl = e.target.closest("[data-nav]");
    if (navEl) { post({ type: "nav", to: navEl.dataset.nav }); return; }

    /* 抽屉 */
    var opener = e.target.closest("[data-drawer-open]");
    if (opener) { opener.closest(".drawer-stage").classList.add("open"); return; }
    if (e.target.closest(".scrim") || e.target.closest("[data-drawer-close]")) {
      var st = e.target.closest(".drawer-stage"); if (st) st.classList.remove("open"); return;
    }

    /* 通用演示交互 */
    var seg = e.target.closest(".segmented button");
    if (seg) { seg.parentElement.querySelectorAll("button").forEach(function (b) { b.setAttribute("aria-selected", "false"); }); seg.setAttribute("aria-selected", "true"); return; }
    var mood = e.target.closest(".mood");
    if (mood) { mood.parentElement.querySelectorAll(".mood").forEach(function (m) { m.classList.remove("sel"); }); mood.classList.add("sel"); return; }
    var tb = e.target.closest(".toolbar .tb");
    if (tb && tb.dataset.toggle !== undefined) { tb.classList.toggle("on"); return; }
    var chip = e.target.closest(".compose-meta .chip-btn");
    if (chip) { chip.classList.toggle("on"); return; }
    var dwi = e.target.closest(".dw-item");
    if (dwi && !dwi.hasAttribute("data-nav")) { dwi.closest(".dw-section").querySelectorAll(".dw-item").forEach(function (i) { i.classList.remove("on"); }); dwi.classList.add("on"); return; }
    var todo = e.target.closest(".cb-todo");
    if (todo) { todo.classList.toggle("done"); return; }
  });

  /* ---------- 顶栏内联展开搜索 ---------- */
  (function () {
    var top = document.querySelector(".app-top");
    var opener = document.querySelector("[data-search-open]");
    if (!top || !opener) return;
    var form = top.querySelector(".topsearch");
    var input = form && form.querySelector("input");
    var openIt = function () { top.classList.add("searching"); if (input) setTimeout(function () { input.focus(); }, 60); };
    var closeIt = function () { top.classList.remove("searching"); if (input) input.value = ""; };
    opener.addEventListener("click", function (e) { e.preventDefault(); e.stopPropagation(); openIt(); });
    if (form) {
      var cancel = form.querySelector("[data-search-close]");
      if (cancel) cancel.addEventListener("click", function (e) { e.preventDefault(); closeIt(); });
      if (input) input.addEventListener("keydown", function (e) {
        if (e.key === "Enter") { e.preventDefault(); post({ type: "nav", to: "search" }); setTimeout(closeIt, 50); }
      });
    }
  })();

  /* ---------- FAB 速拨：轻点起草(导航) · 长按展开 ---------- */
  var wrap = document.querySelector(".fab-wrap");
  if (wrap) {
    var main = wrap.querySelector(".fab-main");
    var timer = null, longPressed = false;
    var open = function () { wrap.classList.add("open"); wrap.classList.remove("pressing"); };
    var close = function () { wrap.classList.remove("open"); };
    main.addEventListener("pointerdown", function (e) {
      e.preventDefault(); longPressed = false;
      if (wrap.classList.contains("open")) return;
      wrap.classList.add("pressing");
      timer = setTimeout(function () { longPressed = true; open(); }, 340);
    });
    main.addEventListener("pointerup", function () {
      clearTimeout(timer); wrap.classList.remove("pressing");
      if (longPressed) return;
      if (wrap.classList.contains("open")) close();
      else post({ type: "nav", to: "editor" });
    });
    main.addEventListener("pointercancel", function () { clearTimeout(timer); wrap.classList.remove("pressing"); });
    main.addEventListener("pointerleave", function () { if (!longPressed) clearTimeout(timer); });
    var fs = wrap.querySelector(".fab-scrim"); if (fs) fs.addEventListener("click", close);
    wrap.querySelectorAll(".fab-action").forEach(function (a) {
      a.addEventListener("click", function () { close(); post({ type: "nav", to: "editor" }); });
    });
  }
})();
