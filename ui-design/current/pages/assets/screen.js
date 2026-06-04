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
      if (d.bg !== undefined) { if (d.bg && d.bg !== "pure") r.setAttribute("data-bg", d.bg); else r.removeAttribute("data-bg"); }
      if (d.paperSeed) r.style.setProperty("--paper-seed", d.paperSeed);
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

    /* 相册：点「+N」展开全部（阅读页；信息流里因外层 data-nav 已先行导航） */
    var more = e.target.closest(".gallery .ph.more");
    if (more) { more.closest(".gallery").classList.add("expanded"); return; }

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
    if (dwi && !dwi.hasAttribute("data-nav")) {
      var sec = dwi.closest(".dw-section");
      sec.querySelectorAll(".dw-item").forEach(function (i) { i.classList.remove("on"); });
      dwi.classList.add("on");
      /* 切换日记本：通知屏内刷新列表（不在顶栏展示日记本名称） */
      var label = sec.querySelector(".dw-label");
      if (label && /日记本/.test(label.textContent)) {
        var nameEl = dwi.querySelector(".name");
        var jName = nameEl ? nameEl.textContent.trim() : "";
        document.dispatchEvent(new CustomEvent("dayz:journalchange", { detail: { name: jName } }));
      }
      /* 抽屉的选择类操作（切日记本 / 切浏览视图）选完即关闭抽屉 */
      var stage = dwi.closest(".drawer-stage");
      if (stage) setTimeout(function () { stage.classList.remove("open"); }, 90);
      return;
    }
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
    var fs = document.querySelector(".fab-scrim"); if (fs) fs.addEventListener("click", close);
    wrap.querySelectorAll(".fab-action").forEach(function (a) {
      a.addEventListener("click", function () { close(); post({ type: "nav", to: "editor" }); });
    });
  }

  /* ============================================================
     共享交互：收藏 toggle · 条目动作菜单 · 删除确认 · 移到日记本 · 新建日记本
     依赖 toast.js（DZ.toast）+ sheet.js（DZ.sheet），由各屏按需引入。
     菜单项业务文案在此集中，复用于阅读页 / 往年今日等。
     ============================================================ */
  var ICON = {
    edit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/></svg>',
    share: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15V3"/><path d="m8 7 4-4 4 4"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/></svg>',
    image: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3.5" y="4.5" width="17" height="15" rx="2.5"/><circle cx="9" cy="10" r="1.7"/><path d="m4.5 18 4.8-4.4a2 2 0 0 1 2.7 0L20 19.5"/></svg>',
    move: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7a2 2 0 0 1 2-2h4l2 2.2h6a2 2 0 0 1 2 2V17a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M12 11v5m0-5-2 2m2-2 2 2"/></svg>',
    star: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.5L14.47 8.6 21.04 9.06 16 13.3 17.58 19.69 12 16.2 6.42 19.69 8.01 13.3 2.97 9.06 9.53 8.6Z"/></svg>',
    starFill: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.5L14.47 8.6 21.04 9.06 16 13.3 17.58 19.69 12 16.2 6.42 19.69 8.01 13.3 2.97 9.06 9.53 8.6Z"/></svg>',
    trash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13"/></svg>'
  };
  /* 可移动到的日记本（对应 DB journal：名称 + 色点）*/
  var JOURNALS = [
    { name: "工作", color: "#786CAD", count: 64 },
    { name: "旅行", color: "#5C8A68", count: 37 },
    { name: "灵感", color: "#C8993E", count: 22 }
  ];

  function sb(name) { return '<span class="sw" style="background:' + name + '"></span>'; }

  /* 收藏星：依据 .on 切换实心金 / 空心线 */
  function paintFav(btn) {
    var on = btn.classList.contains("on");
    btn.innerHTML = on ? ICON.starFill : ICON.star;
    btn.style.color = on ? "var(--favorite)" : "var(--ink-3)";
    btn.setAttribute("aria-pressed", on ? "true" : "false");
  }
  document.querySelectorAll("[data-fav-toggle]").forEach(paintFav);

  /* 移到日记本：单选选择器 */
  function openMoveSheet(current) {
    if (!window.DZ || !DZ.sheet) return;
    DZ.sheet({
      title: "移到日记本",
      items: JOURNALS.map(function (j) {
        return { label: j.name, desc: j.count + " 篇", swatch: j.color, selected: j.name === current,
          onTap: function () { if (DZ.toast) DZ.toast({ text: "已移到「" + j.name + "」", tone: "ok" }); } };
      })
    });
  }

  /* 删除确认 → 移到回收站（带撤销）*/
  function confirmDelete(opts) {
    opts = opts || {};
    if (!window.DZ || !DZ.confirm) return;
    DZ.confirm({
      title: "删除这篇日记？",
      desc: "将移到回收站，30 天内可恢复。",
      confirmLabel: "移到回收站",
      icon: ICON.trash,
      onConfirm: function () {
        if (DZ.toast) DZ.toast({ text: "已移到回收站", tone: "danger", action: "撤销",
          onAction: function () { DZ.toast({ text: "已恢复", tone: "ok" }); } });
        if (opts.after) setTimeout(opts.after, 1100);
      }
    });
  }

  /* 条目动作菜单（阅读页 / 卡片 ⋯）*/
  function openEntryMenu(trigger) {
    if (!window.DZ || !DZ.sheet) return;
    var faved = trigger.getAttribute("data-faved") === "true";
    var inJournal = trigger.getAttribute("data-journal") || "";
    DZ.sheet({
      title: "更多",
      items: [
        { label: "编辑", icon: ICON.edit, onTap: function () { post({ type: "nav", to: "editor" }); } },
        { label: "分享", icon: ICON.share, onTap: function () { if (DZ.toast) DZ.toast("已生成分享链接"); } },
        { label: "移到日记本", icon: ICON.move, onTap: function () { setTimeout(function () { openMoveSheet(inJournal); }, 280); } },
        { label: faved ? "取消收藏" : "收藏", icon: faved ? ICON.starFill : ICON.star,
          onTap: function () {
            faved = !faved; trigger.setAttribute("data-faved", faved ? "true" : "false");
            var favBtn = document.querySelector("[data-fav-toggle]");
            if (favBtn) { favBtn.classList.toggle("on", faved); paintFav(favBtn); }
            if (DZ.toast) DZ.toast(faved ? { text: "已收藏", tone: "fav" } : "已取消收藏");
          } },
        { sep: true },
        { label: "删除", icon: ICON.trash, tone: "danger",
          onTap: function () { setTimeout(function () { confirmDelete({ after: function () { post({ type: "back" }); } }); }, 280); } }
      ]
    });
  }

  /* 新建日记本：命名 + 选色 */
  var NEW_COLORS = ["#786CAD", "#5C8A68", "#C8993E", "#B05C77", "#4F86A8", "#9A6A4B"];
  function openNewJournal() {
    if (!window.DZ || !DZ.sheet) return;
    var body = document.createElement("div");
    body.innerHTML =
      '<div class="field"><label>名称</label><input class="input nj-name" placeholder="例如：读书、健身、远行" autocomplete="off"></div>' +
      '<div class="nj-colorlab">封面色</div><div class="nj-colors">' +
      NEW_COLORS.map(function (c, i) { return '<button type="button" class="nj-color' + (i === 0 ? " on" : "") + '" data-c="' + c + '" style="background:' + c + '"></button>'; }).join("") +
      '</div>';
    var picked = NEW_COLORS[0];
    body.querySelector(".nj-colors").addEventListener("click", function (e) {
      var b = e.target.closest(".nj-color"); if (!b) return;
      body.querySelectorAll(".nj-color").forEach(function (x) { x.classList.remove("on"); });
      b.classList.add("on"); picked = b.getAttribute("data-c");
    });
    var ref = DZ.sheet({
      title: "新建日记本",
      content: body,
      primary: { label: "创建", disabled: true, onTap: function () {
        var name = (body.querySelector(".nj-name").value || "").trim();
        if (!name) return false;           /* 空名不提交（按钮本就禁用，双保险）*/
        addJournalToDrawer(name, picked);
        if (DZ.toast) DZ.toast({ text: "已创建「" + name + "」", tone: "ok" });
      } }
    });
    /* 名称为空 → 「创建」置灰（禁用态）；输入即时解锁 */
    var nameInput = body.querySelector(".nj-name");
    var createBtn = body.closest(".sheet") && body.closest(".sheet").querySelector(".sheet-foot .btn-primary");
    if (nameInput && createBtn) {
      nameInput.addEventListener("input", function () {
        createBtn.disabled = !nameInput.value.trim();
      });
    }
    setTimeout(function () { var i = body.querySelector(".nj-name"); if (i) i.focus(); }, 260);
    return ref;
  }
  function addJournalToDrawer(name, color) {
    var sec = document.querySelector(".dw-section");   /* 首个 = 日记本组 */
    if (!sec) return;
    var item = document.createElement("div");
    item.className = "dw-item";
    item.innerHTML = '<span class="dw-dot" style="background:' + color + '"></span><span class="name">' + name + '</span><span class="count">0</span>';
    sec.appendChild(item);
  }

  document.addEventListener("click", function (e) {
    var fav = e.target.closest("[data-fav-toggle]");
    if (fav) {
      fav.classList.toggle("on"); paintFav(fav);
      var mt = document.querySelector("[data-entry-menu]");
      if (mt) mt.setAttribute("data-faved", fav.classList.contains("on") ? "true" : "false");
      if (window.DZ && DZ.toast) DZ.toast(fav.classList.contains("on") ? { text: "已收藏", tone: "fav" } : "已取消收藏");
      return;
    }
    var menu = e.target.closest("[data-entry-menu]");
    if (menu) { openEntryMenu(menu); return; }
    var del = e.target.closest("[data-delete]");
    if (del) { confirmDelete({ after: del.dataset.delete === "back" ? function () { post({ type: "back" }); } : null }); return; }
    var nj = e.target.closest("[data-new-journal]");
    if (nj) { e.stopPropagation(); openNewJournal(); return; }
    var otd = e.target.closest("[data-otd-menu]");
    if (otd) {
      if (!window.DZ || !DZ.sheet) return;
      DZ.sheet({ title: "往年今日", items: [
        { label: "生成回忆卡片", desc: "把这一天做成一张可分享的卡片图", icon: ICON.image, onTap: function () { post({ type: "nav", to: "memory" }); } },
        { label: "分享这一天", icon: ICON.share, onTap: function () { if (DZ.toast) DZ.toast("已生成分享链接"); } }
      ] });
      return;
    }
    /* 设置：主题色选择器 */
    var tp = e.target.closest("[data-theme-picker]");
    if (tp) {
      if (!window.DZ || !DZ.sheet) return;
      var curT = r.getAttribute("data-theme") || "purple";
      var THEMES = [
        { k: "purple", n: "雾紫", c: "#786CAD" },
        { k: "amber", n: "暖黄", c: "#C8993E" },
        { k: "sage", n: "雾绿", c: "#5C8A68" }
      ];
      DZ.sheet({ title: "主题色", desc: "整套强调色随之切换", items: THEMES.map(function (t) {
        return { label: t.n, swatch: t.c, selected: t.k === curT, onTap: function () {
          r.setAttribute("data-theme", t.k);
          post({ type: "settheme", theme: t.k });
          var v = tp.querySelector(".val"); if (v) v.innerHTML = '<span class="dw-dot" style="background:var(--accent);width:13px;height:13px"></span>' + t.n;
        } };
      }) });
      return;
    }
    /* 设置：外观模式选择器（浅 / 深 / 跟随系统）*/
    var mp = e.target.closest("[data-mode-picker]");
    if (mp) {
      if (!window.DZ || !DZ.sheet) return;
      var curApp = mp.getAttribute("data-appearance") || "light";
      var MODES = [
        { k: "light", n: "浅色" },
        { k: "dark", n: "深色" },
        { k: "system", n: "跟随系统" }
      ];
      var sun = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4.2"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5 5l1.4 1.4M17.6 17.6 19 19M19 5l-1.4 1.4M6.4 17.6 5 19"/></svg>';
      var moon = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.5A8 8 0 0 1 9.5 4a7 7 0 1 0 10.5 10.5z"/></svg>';
      var auto = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 0 0 18z" fill="currentColor" stroke="none"/></svg>';
      var ICOM = { light: sun, dark: moon, system: auto };
      DZ.sheet({ title: "外观模式", items: MODES.map(function (m) {
        return { label: m.n, icon: ICOM[m.k], selected: m.k === curApp, onTap: function () {
          mp.setAttribute("data-appearance", m.k);
          post({ type: "setmode", appearance: m.k });
          var sub = mp.querySelector(".tx span"); if (sub) sub.textContent = m.n;
          var v = mp.querySelector(".val .mv"); if (v) v.textContent = m.n;
        } };
      }) });
      return;
    }
  });

  /* ---------- 覆盖式顶栏：实测高度 → --top-h；滚动 → .scrolled 毛玻璃浮起 ---------- */
  (function () {
    var pg = document.querySelector(".pg");
    var scroll = document.querySelector(".app-scroll");
    var bar = document.querySelector(".pg > .app-top, .pg > .search-head");
    if (!pg || !scroll || !bar) return;
    var measure = function () { pg.style.setProperty("--top-h", bar.offsetHeight + "px"); };
    measure();
    window.addEventListener("resize", measure);
    if (window.ResizeObserver) { try { new ResizeObserver(measure).observe(bar); } catch (_) {} }
    var onScroll = function () { pg.classList.toggle("scrolled", scroll.scrollTop > 2); };
    onScroll();
    scroll.addEventListener("scroll", onScroll, { passive: true });
  })();
})();
