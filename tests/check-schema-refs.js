#!/usr/bin/env node
// Heurística (não um parser SQL completo) que cruza os nomes de tabela e
// coluna usados em .from()/.select()/.eq()/.insert()/.update() nas páginas
// vivas contra o esquema reconstruído a partir das migrações locais.
//
// AVISO IMPORTANTE (ver memória ytb-estado-mandatos, migração 022): já se
// confirmou pelo menos uma vez que uma migração local descrevia uma tabela
// com colunas DIFERENTES das reais em produção (drift anterior à disciplina
// de migrações). Este script só apanha inconsistências entre o CÓDIGO e as
// MIGRAÇÕES LOCAIS — não substitui verificar contra produção
// (information_schema.columns) antes de mexer numa tabela antiga. Serve
// para apanhar o erro mais comum (typo/coluna renomeada e o código não
// seguiu), não para validar contra a verdade absoluta.
'use strict';
const fs = require('fs');
const path = require('path');
const LIVE_PAGES = require('./live-pages');

const ROOT = path.join(__dirname, '..');
const MIGRATIONS_DIR = path.join(ROOT, 'supabase', 'migrations');

const CONSTRAINT_KEYWORDS = /^(unique|primary|check|foreign|constraint|exclude)\b/i;

function extrairBlocoParenteses(texto, inicioAbre) {
  let profundidade = 0, i = inicioAbre;
  for (; i < texto.length; i++) {
    if (texto[i] === '(') profundidade++;
    else if (texto[i] === ')') {
      profundidade--;
      if (profundidade === 0) return texto.slice(inicioAbre + 1, i);
    }
  }
  return texto.slice(inicioAbre + 1);
}

function splitTopLevel(corpo) {
  const partes = [];
  let profundidade = 0, atual = '';
  for (const ch of corpo) {
    if (ch === '(') profundidade++;
    if (ch === ')') profundidade--;
    if (ch === ',' && profundidade === 0) { partes.push(atual); atual = ''; continue; }
    atual += ch;
  }
  if (atual.trim()) partes.push(atual);
  return partes;
}

function construirEsquema() {
  const esquema = {}; // { tabela: Set(colunas) }
  const ficheiros = fs.readdirSync(MIGRATIONS_DIR).filter(f => f.endsWith('.sql')).sort();
  for (const f of ficheiros) {
    const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, f), 'utf8');

    const reCreate = /create table if not exists public\.(\w+)\s*\(/gi;
    let m;
    while ((m = reCreate.exec(sql))) {
      const tabela = m[1];
      const abre = sql.indexOf('(', m.index + m[0].length - 1);
      const corpo = extrairBlocoParenteses(sql, abre);
      esquema[tabela] = esquema[tabela] || new Set();
      for (const parte of splitTopLevel(corpo)) {
        const p = parte.trim();
        if (!p || CONSTRAINT_KEYWORDS.test(p)) continue;
        const nomeCol = p.split(/\s+/)[0];
        if (/^\w+$/.test(nomeCol)) esquema[tabela].add(nomeCol);
      }
    }

    const reAlter = /alter table public\.(\w+) add column if not exists (\w+)/gi;
    while ((m = reAlter.exec(sql))) {
      esquema[m[1]] = esquema[m[1]] || new Set();
      esquema[m[1]].add(m[2]);
    }
  }
  return esquema;
}

function extrairColunas(chain) {
  const cols = new Set();
  let m;
  const reSelect = /\.select\(\s*['"`]([^'"`]*)['"`]/;
  const sel = chain.match(reSelect);
  if (sel && sel[1].trim() !== '*') {
    sel[1].split(',').forEach(c => {
      const nome = c.trim().split(/[:(!]/)[0].trim(); // ignora relações embutidas/alias
      if (/^\w+$/.test(nome)) cols.add(nome);
    });
  }
  const reCond = /\.(?:eq|neq|gt|gte|lt|lte|order|not|ilike|like)\(\s*['"`](\w+)['"`]/g;
  while ((m = reCond.exec(chain))) cols.add(m[1]);

  const reWrite = /\.(?:insert|update)\(\s*\{([^}]*)\}/;
  const w = chain.match(reWrite);
  if (w) {
    const reKey = /(?:^|[{,]\s*)['"`]?(\w+)['"`]?\s*:/g;
    while ((m = reKey.exec(w[1]))) cols.add(m[1]);
  }
  return cols;
}

const esquema = construirEsquema();
let avisos = 0;

for (const page of LIVE_PAGES) {
  const file = path.join(ROOT, page);
  if (!fs.existsSync(file)) continue;
  const html = fs.readFileSync(file, 'utf8');
  const reFrom = /\.from\(\s*['"`](\w+)['"`]\s*\)/g;
  const posicoesFrom = [];
  let m;
  while ((m = reFrom.exec(html))) posicoesFrom.push({ index: m.index, tabela: m[1] });

  for (let idx = 0; idx < posicoesFrom.length; idx++) {
    const { index, tabela } = posicoesFrom[idx];
    if (!esquema[tabela]) continue; // tabela não reconhecida nas migrações (RPC/view?) — não avaliar
    // a janela termina no que vier primeiro: um ';', uma linha em branco,
    // ou o início da próxima chamada .from() — evita "vazar" para a
    // chamada seguinte quando duas ficam próximas (ex: vários .from()
    // seguidos numa função de carregamento)
    const limiteProximoFrom = idx + 1 < posicoesFrom.length ? posicoesFrom[idx + 1].index : html.length;
    const bruto = html.slice(index, Math.min(index + 600, limiteProximoFrom));
    const janela = bruto.split(/;\r?\n|\n\s*\n/)[0];
    const cols = extrairColunas(janela);
    for (const col of cols) {
      if (!esquema[tabela].has(col)) {
        console.log(`? ${page}: .from('${tabela}') usa coluna "${col}" não encontrada nas migrações locais para essa tabela`);
        avisos++;
      }
    }
  }
}

if (avisos) {
  console.log(`\n${avisos} referência(s) de coluna a confirmar (heurística — pode ter falsos positivos; ver aviso no topo do ficheiro).`);
  process.exit(1);
} else {
  console.log('Nenhuma referência de coluna suspeita encontrada (heurística contra as migrações locais).');
}
