#!/usr/bin/env node
// Verifica que toda a navegação interna (href="x.html", location.href=...)
// nas páginas vivas aponta para ficheiros que existem — apanha o tipo de bug
// encontrado várias vezes esta sessão (auth.html/admin360.html a apontar
// para ferramentas erradas ou páginas mortas).
'use strict';
const fs = require('fs');
const path = require('path');
const LIVE_PAGES = require('./live-pages');

const ROOT = path.join(__dirname, '..');
let erros = 0, verificados = 0;

// href="x.html" / href='x.html' / location.href='x.html' / location.href="x.html"
const RE = /(?:href\s*=\s*|location\.href\s*=\s*|window\.location\.href\s*=\s*)['"]([^'"]+\.html(?:[?#][^'"]*)?)['"]/g;

function resolveAlvo(alvo) {
  const semQuery = alvo.split(/[?#]/)[0];
  if (/^https?:\/\//i.test(semQuery)) return null; // externo, não verificar
  const limpo = semQuery.replace(/^\//, '');
  return limpo;
}

for (const page of LIVE_PAGES) {
  const file = path.join(ROOT, page);
  if (!fs.existsSync(file)) continue; // já reportado por check-syntax.js
  const html = fs.readFileSync(file, 'utf8');
  let m;
  const vistos = new Set();
  while ((m = RE.exec(html))) {
    const alvo = resolveAlvo(m[1]);
    if (!alvo || vistos.has(alvo)) continue;
    vistos.add(alvo);
    verificados++;
    const alvoPath = path.join(ROOT, alvo);
    if (!fs.existsSync(alvoPath)) {
      console.log(`✗ ${page} → "${m[1]}" (ficheiro "${alvo}" não existe)`);
      erros++;
    }
  }
}

if (erros) {
  console.log(`\n${erros} link(s) partido(s) em ${verificados} verificados.`);
  process.exit(1);
} else {
  console.log(`Todos os ${verificados} links internos das páginas vivas apontam para ficheiros existentes.`);
}
