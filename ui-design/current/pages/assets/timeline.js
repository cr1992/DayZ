/* ============================================================
   DayZ · 时间线专属逻辑（仅 timeline.html 加载，在 screen.js 之后）
   1) 日记「索引」（哪些月/日有条目）—— 对应 Flutter 侧一条轻量的
      按月计数查询；详情仍走游标分页。
   2) 向上无限滚动：滚到底按需追加更早月份（最新在最上）。
   3) 日期快速跳转：点月份头 → 日历面板（月格/年格）→ 跳到该月/该日。
   ============================================================ */
(function () {
  "use strict";
  var scroll = document.querySelector(".app-scroll");
  var list = document.querySelector('[data-when="default drawer"]');
  if (!scroll || !list) return;

  var WD = ["一", "二", "三", "四", "五", "六", "日"];   // 周一起始
  var MO = ["1月","2月","3月","4月","5月","6月","7月","8月","9月","10月","11月","12月"];
  var TODAY = { y: 2026, m: 5, d: 29 };

  /* ---------- 生成素材池（克制、生活化）---------- */
  var TITLES = ["午后的长散步","读完一本旧书","厨房里的小实验","给老朋友写信","整理旧照片",
    "清晨第一杯咖啡","一次临时的远行","关于专注这件事","窗外的玉兰开了","深夜随手记",
    "周末逛了趟市集","把阳台收拾干净","重听一张旧唱片","学着慢下来","记一场及时雨"];
  var EXCERPTS = [
    "走了很久，把一周攒下的念头都走散了。回来时天刚擦黑，心里却很亮。",
    "翻到一半忽然舍不得读完，便合上книга，留着明天。好东西总要省着。",
    "照方子试了第一次，咸淡还没拿准，但厨房里的香气是真的。",
    "提笔才发现，想说的话比能写下的多得多。先寄出去再说。",
    "一张一张看过去，时间忽然变得很具体。原来那年我们都还很年轻。",
    "没有特别的事，只是想把这样平常的一天，认认真真地留下来。",
    "临时起意坐了最早的一班车，去看一片没去过的海。",
    "把手机搁远一点，一件事做到底，比同时开五个头更让人安心。"];
  var TAGS = ["生活","随想","家","旅行","工作","灵感","读书","食物"];
  var MOODS = ["平静","愉快","想念","专注","疲惫","满足"];
  var PLACES = ["永康路","杭州","家","图书馆","海边","巷口的咖啡馆"];
  var PHOTOS = ["bookstore.png", "plum.png", "sea.png"];

  // 简单可重复伪随机
  function rng(seed) { var s = seed % 2147483647; if (s <= 0) s += 2147483646; return function () { s = s * 16807 % 2147483647; return (s - 1) / 2147483646; }; }
  function daysInMonth(y, m) { return new Date(y, m, 0).getDate(); }
  function firstWD(y, m) { var d = new Date(y, m - 1, 1).getDay(); return (d + 6) % 7; } // 周一=0

  /* ---------- 月份索引（最新→最旧）---------- */
  // 头两个月已写死在 HTML 里；其余按需生成。days = 有条目的日。
  var MONTHS = [
    { y: 2026, m: 5, count: 12, days: [29, 28, 27], dom: true },
    { y: 2026, m: 4, count: 9,  days: [30], dom: true }
  ];
  // 生成 2026-03 → 2025-01
  (function build() {
    var y = 2026, m = 3;
    for (var i = 0; i < 15; i++) {
      var rnd = rng(y * 100 + m);
      var dim = daysInMonth(y, m);
      var n = 2 + Math.floor(rnd() * 3);          // 2~4 条
      var days = [];
      while (days.length < n) { var d = 1 + Math.floor(rnd() * dim); if (days.indexOf(d) === -1) days.push(d); }
      days.sort(function (a, b) { return b - a; });
      MONTHS.push({ y: y, m: m, count: n, days: days });
      m--; if (m === 0) { m = 12; y--; }
    }
  })();

  function findMonth(y, m) { for (var i = 0; i < MONTHS.length; i++) if (MONTHS[i].y === y && MONTHS[i].m === m) return i; return -1; }

  /* ---------- 渲染一个生成月份的 DOM ---------- */
  function entryHTML(y, m, d, rnd) {
    var wd = ["日","一","二","三","四","五","六"][new Date(y, m - 1, d).getDay()];
    var t = TITLES[Math.floor(rnd() * TITLES.length)];
    var ex = EXCERPTS[Math.floor(rnd() * EXCERPTS.length)];
    var tag = TAGS[Math.floor(rnd() * TAGS.length)];
    var hasPhoto = rnd() < 0.34;
    var star = rnd() < 0.16;
    var metaMood = rnd() < 0.5;
    var meta = metaMood
      ? '<span class="meta"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 10h.01M15 10h.01"/><path d="M8.5 14.5c1.4 1.7 5.6 1.7 7 0"/></svg>' + MOODS[Math.floor(rnd() * MOODS.length)] + '</span>'
      : '<span class="meta"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s7-5.4 7-11a7 7 0 1 0-14 0c0 5.6 7 11 7 11z"/><circle cx="12" cy="10" r="2.4"/></svg>' + PLACES[Math.floor(rnd() * PLACES.length)] + '</span>';
    var photo = hasPhoto ? '<div class="photo"><img src="../assets/img/' + PHOTOS[Math.floor(rnd() * PHOTOS.length)] + '" alt=""></div>' : '';
    var starEl = star ? '<span class="star"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.5L14.47 8.6 21.04 9.06 16 13.3 17.58 19.69 12 16.2 6.42 19.69 8.01 13.3 2.97 9.06 9.53 8.6Z"/></svg></span>' : '';
    return '<div class="entry" data-date="' + y + '-' + m + '-' + d + '">' +
      '<div class="date"><div class="d">' + d + '</div><div class="m">' + ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"][m - 1] + '</div><div class="w">周' + wd + '</div></div>' +
      '<div class="card" data-nav="reader" style="cursor:pointer">' + photo +
      '<div class="body"><div class="head"><h4>' + t + '</h4>' + starEl + '</div>' +
      '<p class="excerpt">' + ex + '</p>' +
      '<div class="foot"><span class="tag"># ' + tag + '</span>' + meta + '</div></div></div></div>';
  }

  function renderMonth(mo) {
    var rnd = rng(mo.y * 100 + mo.m + 7);
    var head = '<button class="tl-month" data-cal-open data-ym="' + mo.y + '-' + mo.m + '" aria-expanded="false">' +
      '<span class="y">' + MO[mo.m - 1] + '</span><span class="c">' + mo.y + ' · ' + mo.count + ' 篇</span>' +
      '<svg class="tl-cal" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3.5" y="4.5" width="17" height="16" rx="3"/><path d="M3.5 9h17M8 3v3M16 3v3"/></svg></button>';
    var entries = mo.days.map(function (d) { return entryHTML(mo.y, mo.m, d, rnd); }).join("");
    var frag = document.createElement("div");
    frag.innerHTML = head + '<div class="timeline">' + entries + '</div>';
    while (frag.firstChild) list.insertBefore(frag.firstChild, loader);
  }

  /* ---------- 无限滚动：底部加载器 + 按需追加 ---------- */
  var loader = document.createElement("div");
  loader.className = "tl-loader";
  loader.innerHTML = '<span class="spin"></span><span>载入更早的日记…</span>';
  list.appendChild(loader);

  var rendered = 2;                 // 已在 DOM 的月份数（头两个写死）
  function loadMore(n) {
    var added = 0;
    while (rendered < MONTHS.length && added < n) { renderMonth(MONTHS[rendered]); rendered++; added++; }
    if (rendered >= MONTHS.length) { loader.classList.add("done"); loader.innerHTML = '<span>已经到最早的一篇了</span>'; }
    if (typeof updateStuck === "function") updateStuck();
    return added;
  }
  function ensureRendered(idx) { if (idx >= rendered) loadMore(idx - rendered + 1); }

  loadMore(3);                      // 先垫几个月，让页面可向下滚

  /* ---------- 吸顶月份判定：标记当前真正停靠在顶栏下的那一个（.stuck）---------- */
  function updateStuck() {
    var th = topH() + 1, stuck = null;
    var ms = list.querySelectorAll(".tl-month");
    ms.forEach(function (m) { if (m.getBoundingClientRect().top <= th) stuck = m; });
    ms.forEach(function (m) { m.classList.toggle("stuck", m === stuck); });
  }

  var ticking = false;
  scroll.addEventListener("scroll", function () {
    if (ticking) return; ticking = true;
    requestAnimationFrame(function () {
      ticking = false;
      updateStuck();
      if (loader.classList.contains("done")) return;
      if (scroll.scrollTop + scroll.clientHeight > scroll.scrollHeight - 600) loadMore(2);
    });
  }, { passive: true });
  updateStuck();

  /* ---------- 跳转 ----------
     ⚠️ Flutter 痛点（见 PROTOTYPE-ARCH §6）：本原型靠「先补渲染目标月、再按 offsetTop 滚动」
     来跳到任意（含未加载的远期）日期。Flutter 里「pinned 吸顶头」(SliverPersistentHeader)
     与「按 index 跳到任意项」(scrollable_positioned_list) 不易兼得。
     → 退步方案：日历跳转只定位到「月」(section 头)，不强求精确到日；月级精度即够用，
       同时保住完美吸顶头。真到 Flutter 阶段按此降级。 */
  function topH() { return parseInt(getComputedStyle(document.querySelector(".pg")).getPropertyValue("--top-h")) || 96; }
  function jumpToMonth(y, m, day) {
    var idx = findMonth(y, m); if (idx === -1) return;
    ensureRendered(idx);
    requestAnimationFrame(function () {
      var target = null;
      if (day) target = list.querySelector('.entry[data-date="' + y + '-' + m + '-' + day + '"]');
      if (!target) target = list.querySelector('.tl-month[data-ym="' + y + '-' + m + '"]');
      if (!target) return;
      var y0 = target.offsetTop - topH() - 6;
      scroll.scrollTo({ top: Math.max(0, y0), behavior: "smooth" });
    });
  }

  /* ---------- 日历面板 ---------- */
  var pg = document.querySelector(".pg");
  var scrim = document.createElement("div"); scrim.className = "cal-scrim"; scrim.setAttribute("data-cal-close", "");
  var panel = document.createElement("div"); panel.className = "cal-panel"; panel.setAttribute("role", "dialog"); panel.setAttribute("aria-label", "跳转到日期");
  pg.appendChild(scrim); pg.appendChild(panel);

  var view = { y: TODAY.y, m: TODAY.m, mode: "month" };
  var activeHeader = null;

  function chevron(dir) {
    return dir === "left"
      ? '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 5-7 7 7 7"/></svg>'
      : '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 5 7 7-7 7"/></svg>';
  }
  function caret() { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>'; }

  function render() {
    if (view.mode === "month") renderMonthView(); else renderYearView();
  }

  function renderMonthView() {
    var mo = MONTHS[findMonth(view.y, view.m)];
    var dayset = mo ? mo.days : [];
    var pad = firstWD(view.y, view.m), dim = daysInMonth(view.y, view.m);
    var cells = "";
    for (var i = 0; i < pad; i++) cells += '<button class="cal-day pad" tabindex="-1"></button>';
    for (var d = 1; d <= dim; d++) {
      var has = dayset.indexOf(d) !== -1;
      var isToday = view.y === TODAY.y && view.m === TODAY.m && d === TODAY.d;
      cells += '<button class="cal-day' + (has ? " has" : "") + (isToday ? " today" : "") + '"' +
        (has ? ' data-day="' + d + '"' : ' disabled') + '>' + d + '</button>';
    }
    panel.innerHTML =
      '<div class="cal-head">' +
        '<button class="cal-nav" data-prev aria-label="上个月">' + chevron("left") + '</button>' +
        '<button class="cal-title" data-toyear>' + view.y + ' 年 ' + MO[view.m - 1] + caret() + '</button>' +
        '<button class="cal-nav" data-next aria-label="下个月">' + chevron("right") + '</button>' +
      '</div>' +
      '<div class="cal-wd">' + WD.map(function (w) { return '<span>' + w + '</span>'; }).join("") + '</div>' +
      '<div class="cal-grid">' + cells + '</div>' +
      '<div class="cal-foot"><button class="cal-today-btn" data-today>回到今天</button></div>';
  }

  function renderYearView() {
    var cells = "";
    for (var m = 1; m <= 12; m++) {
      var mo = MONTHS[findMonth(view.y, m)];
      var has = !!mo, cur = (view.y === TODAY.y && m === TODAY.m);
      cells += '<button class="cal-mo' + (has ? " has" : "") + (cur ? " cur" : "") + '"' +
        (has ? ' data-month="' + m + '"' : ' disabled') + '>' + MO[m - 1] +
        '<span class="n">' + (has ? mo.count + " 篇" : "—") + '</span></button>';
    }
    panel.innerHTML =
      '<div class="cal-head">' +
        '<button class="cal-nav" data-prevy aria-label="上一年">' + chevron("left") + '</button>' +
        '<button class="cal-title" data-tomonth>' + view.y + ' 年' + caret() + '</button>' +
        '<button class="cal-nav" data-nexty aria-label="下一年">' + chevron("right") + '</button>' +
      '</div>' +
      '<div class="cal-months">' + cells + '</div>';
  }

  function openCal(header) {
    activeHeader = header;
    var ym = header.getAttribute("data-ym").split("-");
    view.y = +ym[0]; view.m = +ym[1]; view.mode = "month";
    render();
    pg.classList.add("cal-open");
    header.setAttribute("aria-expanded", "true");
  }
  function closeCal() {
    pg.classList.remove("cal-open");
    if (activeHeader) activeHeader.setAttribute("aria-expanded", "false");
    activeHeader = null;
  }

  // 事件委托
  document.addEventListener("click", function (e) {
    var opener = e.target.closest("[data-cal-open]");
    if (opener) { e.preventDefault(); if (activeHeader === opener) closeCal(); else openCal(opener); return; }
    if (e.target.closest("[data-cal-close]")) { closeCal(); return; }
    if (!e.target.closest(".cal-panel")) return;

    if (e.target.closest("[data-prev]")) { view.m--; if (view.m === 0) { view.m = 12; view.y--; } render(); return; }
    if (e.target.closest("[data-next]")) { view.m++; if (view.m === 13) { view.m = 1; view.y++; } render(); return; }
    if (e.target.closest("[data-prevy]")) { view.y--; render(); return; }
    if (e.target.closest("[data-nexty]")) { view.y++; render(); return; }
    if (e.target.closest("[data-toyear]")) { view.mode = "year"; render(); return; }
    if (e.target.closest("[data-tomonth]")) { view.mode = "month"; render(); return; }
    if (e.target.closest("[data-today]")) { view.y = TODAY.y; view.m = TODAY.m; closeCal(); jumpToMonth(TODAY.y, TODAY.m, TODAY.d); return; }
    var mo = e.target.closest("[data-month]");
    if (mo) { var m = +mo.getAttribute("data-month"); closeCal(); jumpToMonth(view.y, m); return; }
    var dd = e.target.closest("[data-day]");
    if (dd) { var d = +dd.getAttribute("data-day"); closeCal(); jumpToMonth(view.y, view.m, d); return; }
  });

  /* ---------- 切换日记本 → 刷新列表（screen.js 派发 dayz:journalchange）----------
     原型里用一次淡入重演来模拟「按所选日记本重新查询并铺列表」；
     Flutter 侧对应 journal 变更后列表 rebuild + FadeTransition / AnimatedSwitcher。 */
  document.addEventListener("dayz:journalchange", function () {
    closeCal();
    scroll.scrollTo({ top: 0, behavior: "auto" });
    list.classList.remove("tl-refreshing");
    void list.offsetWidth;                 // 强制回流以重启动画
    list.classList.add("tl-refreshing");
    updateStuck();
  });
  list.addEventListener("animationend", function (e) {
    if (e.target === list) list.classList.remove("tl-refreshing");
  });
})();
