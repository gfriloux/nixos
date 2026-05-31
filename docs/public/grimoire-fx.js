/* ============================================================================
   KURI · grimoire-fx.js — machine-spirit effects for the Starlight codex
   ----------------------------------------------------------------------------
   Load via the `head` array in astro.config.mjs:
       { tag: 'script', attrs: { src: '/grimoire-fx.js', defer: true } }
   Place this file at  docs/public/grimoire-fx.js  (so it serves at /grimoire-fx.js).
   Pure vanilla, no deps. Companion to grimoire.css.

   Provides:
     · Gold motes (incense-ash) + candlelight breathing + gilded sheen dials
     · Scroll-reveal + h2 ink-draw  (classes added by JS, so content is never
       hidden without JS — and revealed immediately when all fits the viewport)
     · Console Cogitator — a floating panel of "Rites" to toggle effects, incl.
       a Lumen/Umbra rite that drives Starlight's OWN theme (no second toggle).
   Survives Astro view-transition navigation (astro:page-load).
   "The Omnissiah provides. The localStorage persists."
   ========================================================================= */
(function () {
  "use strict";
  var root = document.documentElement;
  var reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  var FX_KEY = "kuri-fx", T_KEY = "starlight-theme"; // Starlight's own theme key

  /* ---- effect dials ---- */
  function loadFx() {
    var d = { sheen: true, candle: true, motes: !reduce };
    try { return Object.assign(d, JSON.parse(localStorage.getItem(FX_KEY) || "{}")); }
    catch (e) { return d; }
  }
  var fx = loadFx();
  function saveFx() { try { localStorage.setItem(FX_KEY, JSON.stringify(fx)); } catch (e) {} }
  function applyFx() {
    root.style.setProperty("--gm-fx-candle", fx.candle ? "1" : "0");
    root.style.setProperty("--gm-fx-motes", fx.motes ? "1" : "0");
    root.classList.toggle("gm-no-sheen", !fx.sheen);
    var motes = document.querySelector(".gm-motes");
    if (motes) motes.style.display = fx.motes ? "" : "none";
  }

  /* ---- theme (defer to Starlight) ---- */
  function curTheme() { return root.dataset.theme === "light" ? "light" : "dark"; }
  function setTheme(t) {
    root.dataset.theme = t;
    try { localStorage.setItem(T_KEY, t); } catch (e) {}
    // keep Starlight's <starlight-theme-select> in sync if present
    var sel = document.querySelector("starlight-theme-select select");
    if (sel) { sel.value = t; sel.dispatchEvent(new Event("change", { bubbles: true })); }
    syncConsole();
  }

  /* ============================ global-once setup ====================== */
  var setup = false;
  function setupOnce() {
    if (setup) return; setup = true;
    applyFx();
    buildMotes();
    injectConsole();
  }

  /* ---- gold motes (incense-ash drifting up) ---- */
  function buildMotes() {
    if (reduce || document.querySelector(".gm-motes")) return;
    var layer = document.createElement("div");
    layer.className = "gm-motes";
    for (var i = 0; i < 18; i++) {
      var m = document.createElement("div"), s = 2 + Math.random() * 2.5;
      m.className = "gm-mote";
      m.style.left = (Math.random() * 100) + "%";
      m.style.width = m.style.height = s.toFixed(1) + "px";
      m.style.animationDuration = (15 + Math.random() * 14).toFixed(1) + "s";
      m.style.animationDelay = (-Math.random() * 26).toFixed(1) + "s";
      m.style.opacity = (0.25 + Math.random() * 0.5).toFixed(2);
      layer.appendChild(m);
    }
    document.body.appendChild(layer);
    if (!fx.motes) layer.style.display = "none";
  }

  /* ============================ per-page setup ========================= */
  function setupPage() { armReveal(); }

  /* ---- scroll reveal + h2 ink-draw (manual rect check — bulletproof) ---- */
  function armReveal() {
    var sel = ".sl-markdown-content h2, .sl-markdown-content h3, .sl-markdown-content .card," +
              ".starlight-aside, .expressive-code, .sl-markdown-content table, .pagination-links";
    var targets = Array.prototype.slice.call(document.querySelectorAll(sel));
    if (!targets.length) return;
    if (reduce) { targets.forEach(function (t) { t.classList.add("gm-in"); }); return; }
    targets.forEach(function (t) { t.classList.add("gm-reveal"); });
    function check() {
      var vh = window.innerHeight || document.documentElement.clientHeight;
      for (var i = targets.length - 1; i >= 0; i--) {
        var t = targets[i];
        if (t.classList.contains("gm-in")) { targets.splice(i, 1); continue; }
        var r = t.getBoundingClientRect();
        if (r.top < vh * 0.92 && r.bottom > 0) t.classList.add("gm-in");
      }
    }
    check();
    window.addEventListener("scroll", check, { passive: true });
    window.addEventListener("resize", check);
    setTimeout(check, 250); setTimeout(check, 800);
  }

  /* ---- Console Cogitator (Rites) ---- */
  var GEAR =
    '<svg viewBox="0 0 100 100" fill="none" aria-hidden="true">' +
    '<g class="gm-ring"><path d="M52.79,10.10 L56.95,3.52 L63.91,5.11 L64.80,12.84 L69.83,15.26 L76.43,11.13 L82.01,15.59 L79.46,22.94 L82.94,27.30 L90.67,26.45 L93.77,32.88 L88.28,38.40 L89.52,43.84 L96.86,46.43 L96.86,53.57 L89.52,56.16 L88.28,61.60 L93.77,67.12 L90.67,73.55 L82.94,72.70 L79.46,77.06 L82.01,84.41 L76.43,88.87 L69.83,84.74 L64.80,87.16 L63.91,94.89 L56.95,96.48 L52.79,89.90 L47.21,89.90 L43.05,96.48 L36.09,94.89 L35.20,87.16 L30.17,84.74 L23.57,88.87 L17.99,84.41 L20.54,77.06 L17.06,72.70 L9.33,73.55 L6.23,67.12 L11.72,61.60 L10.48,56.16 L3.14,53.57 L3.14,46.43 L10.48,43.84 L11.72,38.40 L6.23,32.88 L9.33,26.45 L17.06,27.30 L20.54,22.94 L17.99,15.59 L23.57,11.13 L30.17,15.26 L35.20,12.84 L36.09,5.11 L43.05,3.52 L47.21,10.10 Z" stroke="currentColor" stroke-width="3" stroke-linejoin="round"/></g>' +
    '<circle cx="50" cy="50" r="30" stroke="currentColor" stroke-width="2.4"/>' +
    '<circle cx="50" cy="50" r="6" fill="currentColor"/></svg>';

  var RITES = [
    { key: "_theme", label: "Lumen / Umbra", sub: "Day-rite or night-rite" },
    { key: "sheen",  label: "Gilded Sheen",  sub: "Aurum-light on the titles" },
    { key: "candle", label: "Candlelight",   sub: "The sanctum breathes" },
    { key: "motes",  label: "Incense-ash",   sub: "Motes of sacred dust" }
  ];

  function injectConsole() {
    if (document.getElementById("gm-console-btn")) return;
    var btn = document.createElement("button");
    btn.id = "gm-console-btn"; btn.type = "button";
    btn.setAttribute("aria-label", "Console Cogitator"); btn.title = "Invoke the Rites";
    btn.innerHTML = GEAR;
    document.body.appendChild(btn);

    var panel = document.createElement("div");
    panel.id = "gm-console"; panel.hidden = true;
    panel.innerHTML = '<div class="gm-c-head">Console Cogitator <span class="led"></span></div>' +
      '<div class="gm-c-body">' + RITES.map(function (r) {
        var on = r.key === "_theme" ? (curTheme() === "dark") : !!fx[r.key];
        return '<div class="gm-field"><div class="gm-field-label">Rite<b>' + r.label + "</b><span>" + r.sub + "</span></div>" +
          '<div class="gm-toggle' + (on ? " is-on" : "") + '" data-rite="' + r.key + '" role="switch"></div></div>';
      }).join("") + "</div>";
    document.body.appendChild(panel);

    btn.addEventListener("click", function () { panel.hidden = !panel.hidden; });
    document.addEventListener("click", function (e) {
      if (!panel.hidden && !panel.contains(e.target) && !btn.contains(e.target)) panel.hidden = true;
    });
    panel.querySelectorAll("[data-rite]").forEach(function (t) {
      t.addEventListener("click", function () {
        var key = t.dataset.rite;
        if (key === "_theme") { setTheme(curTheme() === "dark" ? "light" : "dark"); return; }
        t.classList.toggle("is-on");
        fx[key] = t.classList.contains("is-on");
        applyFx(); saveFx();
      });
    });
  }
  function syncConsole() {
    var t = document.querySelector('[data-rite="_theme"]');
    if (t) t.classList.toggle("is-on", curTheme() === "dark");
  }

  /* ============================ boot ================================== */
  function boot() { setupOnce(); setupPage(); }
  if (document.readyState !== "loading") boot();
  else document.addEventListener("DOMContentLoaded", boot);
  // Astro view-transition navigation: re-arm reveal on new content.
  document.addEventListener("astro:page-load", function () { setupOnce(); setupPage(); });
})();
