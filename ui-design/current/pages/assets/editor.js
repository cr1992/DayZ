/* ============================================================
   DayZ · 编辑页屏内脚本（仅 editor.html）
   AppFlowy 风格「键盘位内联面板」二级菜单的原型实现：
   - H / 颜色 / 链接：点击 → 内联面板从工具栏下方升起（替代键盘位）
   - 图片：来源动作菜单（相册 / 拍照）走 DZ.sheet（一次性插入动作，非格式化）
   依赖 sheet.js / toast.js（editor.html 已引入）。screen.js 仍负责 B/I/U/S 等纯 toggle。

   ⚠️ 色板（TEXT_COLORS / HL_COLORS）是编辑器文字色 / 高亮的「设计真源」，
   与原生 buildColorItem 的 textColorOptions / backgroundColorOptions 一一对应。
   改这里 = 改规格，须同步 docs/handoff/editor.md。
   ============================================================ */
(function () {
  "use strict";
  var wrap = document.querySelector(".editor-dock-wrap");
  if (!wrap) return;
  var dock = wrap.querySelector(".toolbar.editor-dock");

  /* ---- 色板（暖调克制；hex 即交付给原生的 font_color / bg_color 值）---- */
  // 文字颜色：默认(墨, 清除) + 6 档暖调彩色
  var TEXT_COLORS = [
    { c: "", name: "默认" },
    { c: "#B5524B", name: "红褐" },
    { c: "#C2772F", name: "暖橙" },
    { c: "#B07D2A", name: "金棕" },
    { c: "#5E7F4E", name: "橄榄" },
    { c: "#4E7A99", name: "雾蓝" },
    { c: "#7A6BA8", name: "雾紫" }
  ];
  // 高亮：无 + 5 档柔和浅染（原生落地用半透明 bg_color，详见 HANDOFF）
  var HL_COLORS = [
    { c: "", name: "无" },
    { c: "#F2E3B0", name: "暖黄" },
    { c: "#D8E6CE", name: "浅绿" },
    { c: "#D2E0EC", name: "浅蓝" },
    { c: "#E2DAEF", name: "浅紫" },
    { c: "#F1DBDE", name: "浅粉" }
  ];

  function buildSwatches(rowEl, palette, defaultGlyph) {
    palette.forEach(function (opt, i) {
      var b = document.createElement("button");
      b.className = "tb-sw" + (i === 0 ? " on" : "");
      b.type = "button";
      b.setAttribute("data-c", opt.c);
      b.setAttribute("aria-label", opt.name);
      b.title = opt.name;
      var dot = document.createElement("span");
      if (!opt.c) {
        dot.className = "dot " + defaultGlyph;
        if (defaultGlyph === "dot-default") dot.textContent = "A";
      } else {
        dot.className = "dot";
        dot.style.background = opt.c;
        dot.style.boxShadow = "none";
      }
      b.appendChild(dot);
      rowEl.appendChild(b);
    });
    rowEl.addEventListener("click", function (e) {
      var sw = e.target.closest(".tb-sw");
      if (!sw) return;
      rowEl.querySelectorAll(".tb-sw").forEach(function (x) { x.classList.remove("on"); });
      sw.classList.add("on");
      paintColorActive();
    });
  }
  var textRow = wrap.querySelector('[data-pal="text"]');
  var hlRow = wrap.querySelector('[data-pal="hl"]');
  if (textRow) buildSwatches(textRow, TEXT_COLORS, "dot-default");
  if (hlRow) buildSwatches(hlRow, HL_COLORS, "dot-none");

  /* ---- 富格式 demo：从同一套色板给正文里的 [data-fc]/[data-hl] 上色 ----
     单一真源（=工具栏色板），画布里的样式示例与实际选色一致，不会漂。
     高亮底色是浅染，固定配深墨文字，浅/深模式都读得清。 */
  document.querySelectorAll('.compose-body [data-fc]').forEach(function (el) {
    var o = TEXT_COLORS[+el.getAttribute('data-fc')];
    if (o && o.c) el.style.color = o.c;
  });
  document.querySelectorAll('.compose-body [data-hl]').forEach(function (el) {
    var o = HL_COLORS[+el.getAttribute('data-hl')];
    if (o && o.c) { el.style.background = o.c; el.style.color = "#2C2823"; }
  });

  /* 颜色按钮在「选了非默认色」时点亮 */
  function paintColorActive() {
    var btn = dock.querySelector('[data-tb="color"]');
    if (!btn) return;
    var t = textRow && textRow.querySelector(".tb-sw.on");
    var h = hlRow && hlRow.querySelector(".tb-sw.on");
    var active = (t && t.getAttribute("data-c")) || (h && h.getAttribute("data-c"));
    btn.classList.toggle("on", !!active);
  }

  /* ---- 面板开关（同一时刻只开一个）---- */
  var openName = null;
  function panelEl(name) { return wrap.querySelector('.tb-panel[data-panel="' + name + '"]'); }
  function closePanel() {
    if (!openName) return;
    var p = panelEl(openName); if (p) p.classList.remove("open");
    // 颜色按钮的 .on 由选色状态决定，标题/链接的 .on 随面板关闭撤掉
    if (openName !== "color") {
      var b = dock.querySelector('[data-tb="' + openName + '"]');
      if (b && openName !== "heading") b.classList.remove("on");
    }
    wrap.classList.remove("panel-open");
    openName = null;
  }
  function openPanel(name) {
    if (openName === name) { closePanel(); return; }
    closePanel();
    var p = panelEl(name); if (!p) return;
    p.classList.add("open");
    wrap.classList.add("panel-open");
    openName = name;
    if (name === "link") {
      var i = p.querySelector("input");
      if (i) setTimeout(function () { i.focus(); }, 90);
    }
  }

  /* ---- 工具栏点击分流 ---- */
  dock.addEventListener("click", function (e) {
    var btn = e.target.closest(".tb");
    if (!btn) return;
    var tb = btn.getAttribute("data-tb");
    if (tb === "heading" || tb === "color" || tb === "link") {
      e.preventDefault();
      openPanel(tb);
      return;
    }
    if (tb === "image") {
      e.preventDefault();
      closePanel();
      openImagePicker();
      return;
    }
    /* 其余按钮（B/I/U/S/列表/引用/分隔线）：关掉面板，toggle 交给 screen.js */
    closePanel();
  });

  /* ---- 标题选择 ---- */
  var headRow = wrap.querySelector(".tb-headings");
  if (headRow) {
    headRow.addEventListener("click", function (e) {
      var opt = e.target.closest(".tb-h-opt");
      if (!opt) return;
      headRow.querySelectorAll(".tb-h-opt").forEach(function (x) { x.classList.remove("on"); });
      opt.classList.add("on");
      /* H 按钮：选中非「正文」时点亮 */
      var hBtn = dock.querySelector('[data-tb="heading"]');
      if (hBtn) hBtn.classList.toggle("on", opt.getAttribute("data-level") !== "p");
      closePanel();
    });
  }

  /* ---- 链接面板：取消 / 完成 ---- */
  var linkPanel = panelEl("link");
  if (linkPanel) {
    var input = linkPanel.querySelector("input");
    linkPanel.addEventListener("click", function (e) {
      if (e.target.closest("[data-link-cancel]")) { closePanel(); return; }
      if (e.target.closest("[data-link-done]")) {
        var v = (input && input.value || "").trim();
        closePanel();
        if (window.DZ && DZ.toast) DZ.toast(v ? "已添加链接" : "已移除链接");
        if (input) input.value = "";
        return;
      }
    });
    if (input) input.addEventListener("keydown", function (e) {
      if (e.key === "Enter") { e.preventDefault(); linkPanel.querySelector("[data-link-done]").click(); }
    });
  }

  /* ---- 图片插入：微信式全屏选择器（相机格 + 多选编号 + 预览 + 原图）---- */
  function openImagePicker() {
    if (!window.DZ || !DZ.picker) return;
    var base = ["../assets/img/plum.png", "../assets/img/sea.png", "../assets/img/bookstore.png"];
    var assets = [];
    for (var i = 0; i < 16; i++) assets.push(base[i % base.length]);
    DZ.picker({
      assets: assets,
      max: 9,
      onDone: function (srcs) { if (DZ.toast) DZ.toast("已插入 " + srcs.length + " 张图片"); },
      onCamera: function () { if (DZ.toast) DZ.toast("打开相机"); }
    });
  }
})();
