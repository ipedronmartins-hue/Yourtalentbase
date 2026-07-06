#!/usr/bin/env node
// Valida a sintaxe de todos os <script> inline nas páginas vivas.
// Formaliza a verificação que foi feita manualmente (Node vm) antes de cada
// commit ao longo de toda a construção da YTB — apanha erros de sintaxe
// antes de chegarem a produção.
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const LIVE_PAGES = require('./live-pages');

const ROOT = path.join(__dirname, '..');
let erros = 0;

for (const page of LIVE_PAGES) {
  const file = path.join(ROOT, page);
  if (!fs.existsSync(file)) {
    console.log(`✗ ${page} — ficheiro não existe`);
    erros++;
    continue;
  }
  const html = fs.readFileSync(file, 'utf8');
  const re = /<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g;
  let m, i = 0, ok = true;
  while ((m = re.exec(html))) {
    const tagOpen = html.slice(m.index, m.index + m[0].indexOf('>') + 1);
    if (/\ssrc=/.test(tagOpen)) continue; // scripts externos, nada para validar
    i++;
    try {
      new vm.Script(m[1], { filename: `${page}#inline${i}` });
    } catch (e) {
      console.log(`✗ ${page} inline script ${i}: ${e.message}`);
      erros++;
      ok = false;
    }
  }
  if (ok) console.log(`✓ ${page} (${i} scripts)`);
}

if (erros) {
  console.log(`\n${erros} erro(s) de sintaxe.`);
  process.exit(1);
} else {
  console.log('\nTodos os scripts inline são sintaticamente válidos.');
}
