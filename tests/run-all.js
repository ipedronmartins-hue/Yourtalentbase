#!/usr/bin/env node
// Corre as verificações estáticas sobre as páginas vivas. Sem framework
// (jest/mocha) — scripts Node simples, consistente com o resto do projeto.
// Uso: node tests/run-all.js
'use strict';
const { execFileSync } = require('child_process');
const path = require('path');

const SCRIPTS = ['check-syntax.js', 'check-links.js', 'check-schema-refs.js'];
let falhou = false;

for (const script of SCRIPTS) {
  console.log(`\n=== ${script} ===`);
  try {
    const out = execFileSync(process.execPath, [path.join(__dirname, script)], { encoding: 'utf8' });
    console.log(out.trim());
  } catch (e) {
    console.log((e.stdout || '').trim());
    falhou = true;
  }
}

console.log('\n' + '='.repeat(40));
console.log(falhou ? 'FALHOU — ver detalhes acima.' : 'Tudo bem — todas as verificações passaram.');
process.exit(falhou ? 1 : 0);
