/* ================================================================
   YOURTALENTBASE · app.js
   Global utilities — included in every page
================================================================ */
(function(YTB) {
  'use strict';

  /* ── DOM helpers ────────────────────────────────── */
  YTB.el  = id  => document.getElementById(id);
  YTB.qs  = sel => document.querySelector(sel);
  YTB.qsa = sel => document.querySelectorAll(sel);

  /* ── Toast ──────────────────────────────────────── */
  YTB.toast = function(msg, type = 'default') {
    let t = YTB.el('ytb-toast');
    if (!t) {
      const wrap = document.createElement('div');
      wrap.className = 'toast-container';
      wrap.innerHTML = '<div id="ytb-toast" class="toast"></div>';
      document.body.appendChild(wrap);
      t = YTB.el('ytb-toast');
    }
    const icons = { success:'✅', error:'❌', warning:'⚠️', default:'' };
    t.textContent = (icons[type] ? icons[type] + ' ' : '') + msg;
    t.classList.add('show');
    clearTimeout(YTB._toastTimer);
    YTB._toastTimer = setTimeout(() => t.classList.remove('show'), 3500);
  };

  /* ── Overlay open/close ─────────────────────────── */
  YTB.openOverlay = function(id) {
    const e = YTB.el(id);
    if (!e) return;
    e.classList.add('open');
    document.body.style.overflow = 'hidden';
  };
  YTB.closeOverlay = function(id) {
    const e = YTB.el(id);
    if (!e) return;
    e.classList.remove('open');
    document.body.style.overflow = '';
  };

  /* ── Spinner button ─────────────────────────────── */
  YTB.btnLoad = function(btn, loading, text) {
    if (!btn) return;
    btn.disabled = loading;
    if (loading) {
      btn._txt = btn.innerHTML;
      btn.innerHTML = `<div class="spinner spinner-sm" style="border-color:rgba(0,0,0,.2);"></div> ${text || 'A processar...'}`;
    } else {
      btn.innerHTML = btn._txt || text || '';
    }
  };

  /* ── Debounce ───────────────────────────────────── */
  YTB.debounce = function(fn, delay = 300) {
    let t;
    return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), delay); };
  };

  /* ── Format time ────────────────────────────────── */
  YTB.fmtTime  = s => `${String(Math.floor(s/60)).padStart(2,'0')}:${String(s%60).padStart(2,'0')}`;
  YTB.fmtDate  = d => new Date(d).toLocaleDateString('pt-PT', { day:'numeric', month:'short', year:'numeric' });
  YTB.fmtMoney = n => n.toFixed(2).replace('.',',') + '€';

  /* ── Local storage ──────────────────────────────── */
  YTB.store = {
    get:    key        => { try { return JSON.parse(localStorage.getItem('ytb_'+key)); } catch(e) { return null; } },
    set:    (key, val) => { localStorage.setItem('ytb_'+key, JSON.stringify(val)); },
    remove: key        => { localStorage.removeItem('ytb_'+key); },
  };

  /* ── Navigation / mobile menu ───────────────────── */
  YTB.initNav = function() {
    const btn  = YTB.el('btnMenu');
    const menu = YTB.el('menuMob');
    const close= YTB.el('btnMenuClose');
    if (!btn || !menu) return;
    btn.addEventListener('click',  () => menu.classList.add('open'));
    close?.addEventListener('click', () => menu.classList.remove('open'));
    // Close on link click
    menu.querySelectorAll('a, button').forEach(el => {
      el.addEventListener('click', () => menu.classList.remove('open'));
    });
    // Nav scroll effect
    const nav = YTB.qs('.nav');
    if (nav) {
      window.addEventListener('scroll', () => {
        nav.classList.toggle('scrolled', window.scrollY > 20);
      }, { passive: true });
    }
  };

  /* ── Confetti ───────────────────────────────────── */
  YTB.confetti = function() {
    const wrap = document.createElement('div');
    wrap.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:9999;overflow:hidden;';
    const colors = ['#D4AF37','#fff','#00D46A','#c084fc','#ff6b6b','#ffd93d'];
    for (let i = 0; i < 70; i++) {
      const d = document.createElement('div');
      const size = Math.random()*9+5;
      d.style.cssText = `position:absolute;top:0;width:${size}px;height:${size}px;left:${Math.random()*100}%;background:${colors[Math.floor(Math.random()*colors.length)]};border-radius:${Math.random()>.5?'50%':'2px'};--r:${Math.random()*720}deg;animation:confetti ${Math.random()*1.5+2.5}s ${Math.random()*1.5}s ease-in forwards;`;
      wrap.appendChild(d);
    }
    document.body.appendChild(wrap);
    setTimeout(() => wrap.remove(), 6000);
  };

  /* ── Global click delegation ────────────────────── */
  document.addEventListener('click', function(e) {
    const t = e.target;
    // Close overlay by data-close attribute
    if (t.dataset.close) { YTB.closeOverlay(t.dataset.close); return; }
    // Close overlay clicking backdrop
    if (t.classList.contains('overlay') && t.classList.contains('open')) {
      YTB.closeOverlay(t.id); return;
    }
  });

  /* ── Init on DOMContentLoaded ───────────────────── */
  document.addEventListener('DOMContentLoaded', () => {
    YTB.initNav();
  });

})(window.YTB = window.YTB || {});
