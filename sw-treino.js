/* ================================================================
   YOURTALENTBASE · sw-treino.js
   Service Worker — Treino Extra PWA
================================================================ */

var CACHE = 'ytb-treino-v1';
var ASSETS = [
  '/treino.html',
  '/manifest-treino.json',
];

/* ── INSTALL ─────────────────────────────────────────────────── */
self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE).then(function(cache) {
      return cache.addAll(ASSETS);
    })
  );
  self.skipWaiting();
});

/* ── ACTIVATE ───────────────────────────────────────────────── */
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

/* ── FETCH ───────────────────────────────────────────────────── */
self.addEventListener('fetch', function(e) {
  var url = new URL(e.request.url);

  // API calls — sempre network
  if (url.pathname.startsWith('/api/')) {
    e.respondWith(
      fetch(e.request).catch(function() {
        // Se offline durante treino, retorna resposta de erro amigável
        return new Response(JSON.stringify({
          error: 'offline',
          content: [{ text: '{"score":70,"nivel":"Bom","feedback":"Treino guardado localmente. A avaliação IA ficará disponível quando tiveres ligação.","destaque":"Completaste o treino mesmo sem internet!"}' }]
        }), { headers: { 'Content-Type': 'application/json' } });
      })
    );
    return;
  }

  // Supabase — network com fallback silencioso
  if (url.hostname.includes('supabase.co')) {
    e.respondWith(
      fetch(e.request).catch(function() {
        return new Response('{}', { headers: { 'Content-Type': 'application/json' } });
      })
    );
    return;
  }

  // Assets — cache-first
  e.respondWith(
    caches.match(e.request).then(function(cached) {
      if (cached) return cached;
      return fetch(e.request).then(function(response) {
        if (response.ok && e.request.method === 'GET') {
          var clone = response.clone();
          caches.open(CACHE).then(function(cache) { cache.put(e.request, clone); });
        }
        return response;
      }).catch(function() {
        if (e.request.mode === 'navigate') {
          return caches.match('/treino.html');
        }
      });
    })
  );
});
