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

  /* ---- 元素引用 ---- */
  var fmtTrigger = dock.querySelector('[data-tb="format"]');
  var barBold = dock.querySelector('.tb[aria-label="加粗"]');
  var barItalic = dock.querySelector('.tb[aria-label="斜体"]');
  var barTodo = dock.querySelector('.tb[aria-label="待办清单"]');
  var barBlocks = [].slice.call(dock.querySelectorAll('.tb[data-tb-block]'));
  function barBlockBtn(name) { return dock.querySelector('.tb[data-tb-block="' + name + '"]'); }
  var headRow = wrap.querySelector(".tb-headings");
  var blockRow = wrap.querySelector(".tb-blocks");
  var markRow = wrap.querySelector(".tb-marks");

  /* ---- 面板开关（同一时刻只开一个）---- */
  var openName = null;
  function panelEl(name) { return wrap.querySelector('.tb-panel[data-panel="' + name + '"]'); }
  function closePanel() {
    if (!openName) return;
    var p = panelEl(openName); if (p) p.classList.remove("open");
    // color / format 触发钮的 .on 由内容状态决定（不随关闭撤销）；link 关闭即撤
    if (openName === "link") {
      var b = dock.querySelector('[data-tb="link"]');
      if (b) b.classList.remove("on");
    }
    wrap.classList.remove("panel-open");
    openName = null;
  }
  function openPanel(name) {
    if (openName === name) { closePanel(); return; }
    closePanel();
    var p = panelEl(name); if (!p) return;
    p.classList.add("open");
    p.scrollTop = 0;
    wrap.classList.add("panel-open");
    openName = name;
    if (name === "link") {
      var b = dock.querySelector('[data-tb="link"]'); if (b) b.classList.add("on");
      var i = p.querySelector("input");
      if (i) setTimeout(function () { i.focus(); }, 90);
    }
    if (name === "format") syncMarksFromBar();
  }

  /* ---- 块 / 标题状态（段落与块互斥：heading · ul/ol/todo/quote/code/callout）---- */
  function clearHeadings() { if (headRow) headRow.querySelectorAll(".tb-h-opt").forEach(function (x) { x.classList.remove("on"); }); }
  function setHeadingChoice(level) {
    clearHeadings();
    var o = headRow && headRow.querySelector('[data-level="' + level + '"]'); if (o) o.classList.add("on");
  }
  function clearBlocks() {
    if (blockRow) blockRow.querySelectorAll(".tb-blk").forEach(function (x) { x.classList.remove("on"); });
    barBlocks.forEach(function (x) { x.classList.remove("on"); });
  }
  function activeBlock() {
    var b = blockRow && blockRow.querySelector(".tb-blk.on");
    if (b) return b.getAttribute("data-block");
    var bb = barBlocks.filter(function (x) { return x.classList.contains("on"); })[0];
    return bb ? bb.getAttribute("data-tb-block") : null;
  }
  function paintFormatActive() {
    if (!fmtTrigger) return;
    var hl = headRow && headRow.querySelector(".tb-h-opt.on");
    var headingActive = hl && hl.getAttribute("data-level") !== "p";
    fmtTrigger.classList.toggle("on", !!(headingActive || activeBlock()));
  }
  function setBlock(name) {
    var on = activeBlock() === name;
    clearBlocks(); clearHeadings();
    if (!on) {
      var btn = blockRow && blockRow.querySelector('[data-block="' + name + '"]'); if (btn) btn.classList.add("on");
      var bb = barBlockBtn(name); if (bb) bb.classList.add("on");
    } else {
      setHeadingChoice("p");   // 取消当前块 → 回正文
    }
    paintFormatActive();
  }

  /* ---- 工具栏点击分流 ---- */
  dock.addEventListener("click", function (e) {
    var btn = e.target.closest(".tb");
    if (!btn) return;
    var tb = btn.getAttribute("data-tb");
    if (tb === "format" || tb === "color" || tb === "link") {
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
    if (btn === barBold || btn === barItalic) {
      setTimeout(syncMarksFromBar, 0);
      return;
    }
    var blk = btn.getAttribute("data-tb-block");   // 快捷列表/待办：参与块状态（与面板同步）
    if (blk) {
      e.preventDefault();
      setBlock(blk);
      return;
    }
  });

  /* ---- 标题选择（面板内，选后面板保持打开）---- */
  if (headRow) {
    headRow.addEventListener("click", function (e) {
      var opt = e.target.closest(".tb-h-opt");
      if (!opt) return;
      clearBlocks();
      setHeadingChoice(opt.getAttribute("data-level"));
      paintFormatActive();
    });
  }

  /* ---- 列表与块（radio 互斥；divider 为一次性插入）---- */
  if (blockRow) {
    blockRow.addEventListener("click", function (e) {
      var b = e.target.closest(".tb-blk");
      if (!b) return;
      var name = b.getAttribute("data-block");
      if (name === "divider") { if (window.DZ && DZ.toast) DZ.toast("已插入分隔线"); return; }
      setBlock(name);
      var turnedOn = b.classList.contains("on");
      if (turnedOn && window.DZ && DZ.toast) {
        if (name === "code") DZ.toast("已转为代码块");
        else if (name === "callout") DZ.toast("已插入标注块");
      }
    });
  }

  /* ---- 文字样式（B/I/U/S/行内代码；独立 toggle，bold/italic 与工具栏双向同步）---- */
  function syncMarksFromBar() {
    if (!markRow) return;
    var mb = markRow.querySelector('[data-mark="bold"]'); if (mb && barBold) mb.classList.toggle("on", barBold.classList.contains("on"));
    var mi = markRow.querySelector('[data-mark="italic"]'); if (mi && barItalic) mi.classList.toggle("on", barItalic.classList.contains("on"));
  }
  if (markRow) {
    markRow.addEventListener("click", function (e) {
      var m = e.target.closest(".tb-mark");
      if (!m) return;
      var name = m.getAttribute("data-mark");
      if (name === "link") { openPanel("link"); return; }   // 链接：由面板入口拉起 URL 面板
      m.classList.toggle("on");
      var on = m.classList.contains("on");
      if (name === "bold" && barBold) barBold.classList.toggle("on", on);
      if (name === "italic" && barItalic) barItalic.classList.toggle("on", on);
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
