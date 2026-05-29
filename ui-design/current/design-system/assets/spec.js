/* DayZ 设计规范 —— 主题 / 明暗切换 + 交互演示 */
(function () {
  const root = document.documentElement;
  const KEY = "dayz-spec-pref";

  function load() {
    try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { return {}; }
  }
  function save(p) { try { localStorage.setItem(KEY, JSON.stringify(p)); } catch (e) {} }

  const pref = load();
  let theme = pref.theme || "purple";
  let mode = pref.mode || "light";

  function apply() {
    root.setAttribute("data-theme", theme);
    root.setAttribute("data-mode", mode);
    document.querySelectorAll(".swatch-btn").forEach((b) =>
      b.setAttribute("aria-pressed", String(b.dataset.set === theme))
    );
    const mt = document.getElementById("modeToggle");
    if (mt) mt.querySelector(".lbl").textContent = mode === "light" ? "浅色" : "深色";
    save({ theme, mode });
  }

  document.addEventListener("click", (e) => {
    const sw = e.target.closest(".swatch-btn");
    if (sw) { theme = sw.dataset.set; apply(); return; }
    if (e.target.closest("#modeToggle")) { mode = mode === "light" ? "dark" : "light"; apply(); return; }

    // 演示用交互
    const opt = e.target.closest(".opt");
    if (opt && opt.dataset.toggle !== undefined) { opt.classList.toggle("on"); return; }
    const seg = e.target.closest(".segmented button");
    if (seg) {
      seg.parentElement.querySelectorAll("button").forEach((b) => b.setAttribute("aria-selected", "false"));
      seg.setAttribute("aria-selected", "true");
      return;
    }
    const mood = e.target.closest(".mood");
    if (mood) {
      mood.parentElement.querySelectorAll(".mood").forEach((m) => m.classList.remove("sel"));
      mood.classList.add("sel");
      return;
    }
    const tb = e.target.closest(".toolbar .tb");
    if (tb && tb.dataset.toggle !== undefined) { tb.classList.toggle("on"); return; }

    // 抽屉侧边栏
    if (e.target.closest("[data-drawer-open]")) {
      document.querySelector(".drawer-stage")?.classList.add("open"); return;
    }
    if (e.target.closest(".scrim") || e.target.closest("[data-drawer-close]")) {
      document.querySelector(".drawer-stage")?.classList.remove("open"); return;
    }
    const dwi = e.target.closest(".dw-item");
    if (dwi && !dwi.classList.contains("static")) {
      const group = dwi.closest(".dw-section");
      group?.querySelectorAll(".dw-item").forEach((i) => i.classList.remove("on"));
      dwi.classList.add("on");
      return;
    }
  });

  apply();
})();

/* FAB 速拨：轻点写日记 · 长按展开其它记录方式 */
(function () {
  function showToast(stage, text) {
    let t = stage.querySelector(".fab-toast");
    if (!t) { t = document.createElement("div"); t.className = "fab-toast"; stage.querySelector(".screen").appendChild(t); }
    t.textContent = text;
    t.classList.add("show");
    clearTimeout(t._timer);
    t._timer = setTimeout(() => t.classList.remove("show"), 1500);
  }

  document.querySelectorAll(".fab-wrap").forEach((wrap) => {
    const main = wrap.querySelector(".fab-main");
    const stage = wrap.closest(".device");
    let timer = null, longPressed = false;

    const open = () => { wrap.classList.add("open"); wrap.classList.remove("pressing"); };
    const close = () => wrap.classList.remove("open");

    main.addEventListener("pointerdown", (e) => {
      e.preventDefault();
      longPressed = false;
      if (wrap.classList.contains("open")) return;
      wrap.classList.add("pressing");
      timer = setTimeout(() => { longPressed = true; open(); }, 350);
    });
    const endPress = () => {
      clearTimeout(timer);
      wrap.classList.remove("pressing");
      if (longPressed) return;            // 长按已展开
      if (wrap.classList.contains("open")) { close(); }
      else { showToast(stage, "✎ 新建日记"); }  // 轻点 = 写日记
    };
    main.addEventListener("pointerup", endPress);
    main.addEventListener("pointercancel", () => { clearTimeout(timer); wrap.classList.remove("pressing"); });
    main.addEventListener("pointerleave", () => { if (!longPressed) clearTimeout(timer); });

    wrap.querySelector(".fab-scrim")?.addEventListener("click", close);
    wrap.querySelectorAll(".fab-action").forEach((a) => {
      a.addEventListener("click", () => { showToast(stage, a.dataset.label || "新建"); close(); });
    });
  });
})();
