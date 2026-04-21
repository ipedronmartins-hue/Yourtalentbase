/* ================================================================
   YOURTALENTBASE · sw-scout.js
   Service Worker — Scout Report PWA
================================================================ */

var CACHE = 'ytb-scout-v1';
var ASSETS = [
  '/scout-report.html',
  '/assets/css/global.css',
  '/manifest-scout.json',
];

/* ── INSTALL — pré-cache assets estáticos ────────────────────── */
self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE).then(function(cache) {
      return cache.addAll(ASSETS);
    })
  );
  self.skipWaiting();
});

/* ── ACTIVATE — limpar caches antigas ───────────────────────── */
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE; })
            .map(function(k) { return caches.delete(k); })
      );
    })
  );
  self.clients.claim();
});

/* ── FETCH — cache-first para assets, network-first para API ── */
self.addEventListener('fetch', function(e) {
  var url = new URL(e.request.url);

  // API calls — sempre network, sem cache
  if (url.pathname.startsWith('/api/')) {
    e.respondWith(fetch(e.request));
    return;
  }

  // Supabase — sempre network
  if (url.hostname.includes('supabase.co')) {
    e.respondWith(fetch(e.request));
    return;
  }

  // Assets estáticos — cache-first com fallback network
  e.respondWith(
    caches.match(e.request).then(function(cached) {
      if (cached) return cached;
      return fetch(e.request).then(function(response) {
        // Cache novos assets estáticos dinamicamente
        if (response.ok && e.request.method === 'GET') {
          var clone = response.clone();
          caches.open(CACHE).then(function(cache) { cache.put(e.request, clone); });
        }
        return response;
      }).catch(function() {
        // Offline fallback — serve scout-report.html para navegação
        if (e.request.mode === 'navigate') {
          return caches.match('/scout-report.html');
        }
      });
    })
  );
});
