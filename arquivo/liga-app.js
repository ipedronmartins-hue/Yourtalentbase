// ═══════════════════════════════════════════════════════
// YTB LEAGUE · APP LOGIC
// ═══════════════════════════════════════════════════════

// ─── SUPABASE CONFIG ───────────────────────────────────
const SB_URL = 'https://nhshnplaiolxwcfuijfo.supabase.co';
const SB_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oc2hucGxhaW9seHdjZnVpamZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIxMzIxNjcsImV4cCI6MjA1NzcwODE2N30.UVQzFOmh90R-eaSltz3HMfktVKxJArHRZACKfRcjuwc';

// ─── STATE GLOBAL ──────────────────────────────────────
const S = {
  // Onboarding
  escalao: null,
  nome: '',
  idade: null,
  clube: '',
  emailEncarregado: '',
  consentParental: false,
  posicaoPreferida: null,
  qIndex: 0,           // pergunta actual (skip q1_pos pois já foi feito)
  respostas: {},       // {q_id: opcao_id ou similar}
  scoreInscricao: 0,
  foco: null,

  // Plantel & táctica
  codigo: null,
  jogadorId: null,
  nomeEquipa: '',
  plantel: [],          // array de 11 jogadores
  formacao: '4-3-3',
  estilo: 'equilibrado',

  // Stats
  pontosSemana: 0,
  pontosTotal: 0,
  vitorias: 0,
  jogosJogados: 0,

  // Jogo activo (Fase 2)
  gameIndex: 0,
  gameScore: 0,
  gameGolosPro: 0,
  gameGolosContra: 0,
  gameDecisoes: [],
  gameAdversario: null,
  gameDataInicio: null,
};

// Lista de perguntas (sem q1 que é o selector visual de posição)
const QUESTOES_LISTA = QUESTIONARIO.filter(q => q.id !== 'q1_pos');

// ─── HELPERS ────────────────────────────────────────────
function el(id) { return document.getElementById(id); }

function showScreen(id) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const target = el('screen-' + id);
  if (target) target.classList.add('active');
  window.scrollTo(0, 0);
}

function showToast(msg, duration) {
  duration = duration || 2200;
  const t = el('toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(window.__toastTimer);
  window.__toastTimer = setTimeout(() => t.classList.remove('show'), duration);
}

function genCodigo() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'YTB-';
  for (let i = 0; i < 4; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function renderSteps(containerId, total, current) {
  const c = el(containerId);
  if (!c) return;
  let html = '';
  for (let i = 0; i < total; i++) {
    let cls = 'step-dot';
    if (i < current) cls += ' done';
    if (i === current) cls += ' current';
    html += `<div class="${cls}"></div>`;
  }
  c.innerHTML = html;
}

// ─── SUPABASE ──────────────────────────────────────────
async function sbInsert(table, data) {
  try {
    const r = await fetch(SB_URL + '/rest/v1/' + table, {
      method: 'POST',
      headers: {
        'apikey': SB_KEY,
        'Authorization': 'Bearer ' + SB_KEY,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify(data)
    });
    if (!r.ok) {
      console.error('SB insert err:', await r.text());
      return null;
    }
    return await r.json();
  } catch (e) { console.error('SB err:', e); return null; }
}

async function sbSelect(table, filter) {
  try {
    const r = await fetch(SB_URL + '/rest/v1/' + table + (filter ? '?' + filter : ''), {
      headers: { 'apikey': SB_KEY, 'Authorization': 'Bearer ' + SB_KEY }
    });
    if (!r.ok) return null;
    return await r.json();
  } catch (e) { return null; }
}

async function sbUpdate(table, id, data) {
  try {
    const r = await fetch(SB_URL + '/rest/v1/' + table + '?id=eq.' + id, {
      method: 'PATCH',
      headers: {
        'apikey': SB_KEY,
        'Authorization': 'Bearer ' + SB_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });
    return r.ok;
  } catch (e) { return false; }
}

// ═══════════════════════════════════════════════════════
// ONBOARDING
// ═══════════════════════════════════════════════════════

function startOnboarding() {
  // Renderizar grid de escalões
  const grid = el('escalaoGrid');
  grid.innerHTML = ESCALOES.map(e =>
    `<button class="scale-btn" data-escalao="${e.id}" onclick="selectEscalao('${e.id}', this)">${e.nome}<br><span style="font-size:9px;color:var(--slate)">${e.idade_min}-${e.idade_max} anos</span></button>`
  ).join('');
  renderSteps('steps-onb-1', 6, 0);
  showScreen('escalao');
}

function selectEscalao(id, btn) {
  S.escalao = id;
  document.querySelectorAll('.scale-btn').forEach(b => b.classList.remove('selected'));
  btn.classList.add('selected');
  el('btnEscalaoNext').disabled = false;
}

function nextFromEscalao() {
  if (!S.escalao) return;
  renderSteps('steps-onb-2', 6, 1);
  showScreen('dados');
  setTimeout(() => el('nomeJogador').focus(), 200);
}

function nextFromDados() {
  const n = el('nomeJogador').value.trim();
  const i = parseInt(el('idadeJogador').value);
  const c = el('clubeJogador').value.trim();
  if (!n || !i || i < 6 || i > 22) {
    el('errDados').style.display = 'block';
    return;
  }
  el('errDados').style.display = 'none';
  S.nome = n;
  S.idade = i;
  S.clube = c;

  // Se < 16, exigir parental. Se >= 16, salta para posição.
  if (i < 16) {
    renderSteps('steps-onb-3', 6, 2);
    showScreen('parental');
  } else {
    renderSteps('steps-onb-4', 6, 3);
    showScreen('posicao');
    renderPosSelector();
  }
}

function toggleCheck(id) {
  el(id).classList.toggle('checked');
}

function nextFromParental() {
  const c1 = el('check1').classList.contains('checked');
  const c2 = el('check2').classList.contains('checked');
  const em = el('emailEncarregado').value.trim();
  if (!c1 || !c2 || !em.includes('@')) {
    el('errParental').style.display = 'block';
    return;
  }
  el('errParental').style.display = 'none';
  S.emailEncarregado = em;
  S.consentParental = true;
  renderSteps('steps-onb-4', 6, 3);
  showScreen('posicao');
  renderPosSelector();
}

function goBackFromPosicao() {
  if (S.idade < 16) showScreen('parental');
  else showScreen('dados');
}

// ─── SELECTOR DE POSIÇÃO ───────────────────────────────
function renderPosSelector() {
  const svg = el('posPitchSvg');
  let html = '';
  // Campo de fundo
  html += `<defs><pattern id="grass" x="0" y="0" width="50" height="50" patternUnits="userSpaceOnUse"><rect width="50" height="50" fill="#1F4A28"/></pattern></defs>`;
  // Riscas
  for (let i = 0; i < 8; i++) {
    html += `<rect x="30" y="${30 + i * 85}" width="440" height="85" fill="${i % 2 === 0 ? '#1F4A28' : '#1A3D22'}"/>`;
  }
  // Linhas do campo
  html += `<rect x="30" y="30" width="440" height="680" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<line x1="30" y1="370" x2="470" y2="370" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<circle cx="250" cy="370" r="55" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  // Áreas
  html += `<rect x="120" y="30" width="260" height="115" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<rect x="180" y="30" width="140" height="50" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<rect x="120" y="595" width="260" height="115" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<rect x="180" y="660" width="140" height="50" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;

  // Posições clicáveis
  POSICOES.forEach(p => {
    html += `
      <g class="pos-dot ${S.posicaoPreferida === p.id ? 'selected' : ''}" data-pos="${p.id}" onclick="selectPosicao('${p.id}')">
        <circle cx="${p.x}" cy="${p.y}" r="28" fill="${S.posicaoPreferida === p.id ? '#D4AF37' : 'rgba(212,175,55,.7)'}" stroke="#000" stroke-width="2"/>
        <text x="${p.x}" y="${p.y + 4}" class="pos-label" fill="#000">${p.id}</text>
      </g>`;
  });
  svg.innerHTML = html;
}

function selectPosicao(id) {
  S.posicaoPreferida = id;
  S.respostas['q1_pos'] = id;
  const p = POSICOES.find(pp => pp.id === id);
  el('posSelectedLabel').textContent = '✓ ' + (p ? p.nome : id);
  el('btnPosicaoNext').disabled = false;
  renderPosSelector();
}

function nextFromPosicao() {
  if (!S.posicaoPreferida) return;
  S.qIndex = 0;
  renderSteps('steps-onb-5', 6, 4);
  showScreen('questionario');
  renderQuestion();
}

// ─── QUESTIONÁRIO ──────────────────────────────────────
function renderQuestion() {
  const q = QUESTOES_LISTA[S.qIndex];
  el('qLabel').textContent = `Pergunta ${S.qIndex + 1} de ${QUESTOES_LISTA.length}`;
  const c = el('questionContainer');
  el('btnQNext').disabled = !(S.respostas[q.id]);
  el('btnQPrev').style.display = S.qIndex > 0 ? 'flex' : 'none';

  if (q.tipo === 'cenario' || q.tipo === 'comportamento') {
    let html = `
      <div class="cenario-card">
        <div class="cenario-num">Situação · ${S.qIndex + 1}</div>
        <div class="cenario-q">${q.pergunta}</div>
        <div class="cenario-sub">${q.sub}</div>
        <div class="opcoes-grid">`;
    q.opcoes.forEach(opt => {
      const sel = S.respostas[q.id] === opt.id ? 'selected' : '';
      html += `
        <button class="opcao-btn ${sel}" onclick="selectOpcao('${q.id}', '${opt.id}')">
          <div class="opcao-letra">${opt.id}</div>
          <div>${opt.texto}</div>
        </button>`;
    });
    html += `</div></div>`;
    c.innerHTML = html;
  } else if (q.tipo === 'foco') {
    let html = `
      <div class="cenario-card">
        <div class="cenario-num">Auto-avaliação</div>
        <div class="cenario-q">${q.pergunta}</div>
        <div class="cenario-sub">${q.sub}</div>
        <div class="foco-grid">`;
    q.opcoes.forEach(opt => {
      const sel = S.respostas[q.id] === opt.id ? 'selected' : '';
      html += `
        <button class="foco-btn ${sel}" onclick="selectFoco('${q.id}', '${opt.id}')">
          <div class="icon">${opt.icon}</div>
          <div class="label">${opt.texto}</div>
        </button>`;
    });
    html += `</div></div>`;
    c.innerHTML = html;
  }
}

function selectOpcao(qId, optId) {
  S.respostas[qId] = optId;
  renderQuestion();
}

function selectFoco(qId, optId) {
  S.respostas[qId] = optId;
  S.foco = optId;
  renderQuestion();
}

function prevQuestion() {
  if (S.qIndex > 0) {
    S.qIndex--;
    renderQuestion();
  }
}

function nextQuestion() {
  const q = QUESTOES_LISTA[S.qIndex];
  if (!S.respostas[q.id]) return;

  if (S.qIndex < QUESTOES_LISTA.length - 1) {
    S.qIndex++;
    renderQuestion();
  } else {
    // Acabou — calcular score e gerar plantel
    calcularScore();
    showScreen('loading');
    setTimeout(() => gerarPlantel(), 1800);
    setTimeout(() => {
      renderSteps('steps-onb-5', 6, 5);
      showScreen('reveal');
      renderPlantel('plantelSvg', true);
    }, 2800);
  }
}

function calcularScore() {
  let score = 0;
  let count = 0;
  QUESTOES_LISTA.forEach(q => {
    const resp = S.respostas[q.id];
    if (resp && q.opcoes) {
      const opt = q.opcoes.find(o => o.id === resp);
      if (opt && typeof opt.score === 'number') {
        score += opt.score;
        count++;
      }
    }
  });
  // Normalizar para 0-100 (max é count*10)
  const max = count * 10;
  S.scoreInscricao = max > 0 ? Math.round((score / max) * 100) : 50;
}

// ═══════════════════════════════════════════════════════
// PLANTEL — gerar e renderizar
// ═══════════════════════════════════════════════════════

function gerarPlantel() {
  const formacao = FORMACOES[S.formacao];
  const plantel = [];

  // Encontra a posição preferida do jogador real
  let posJogadorReal = formacao.posicoes.find(p => p.pos === S.posicaoPreferida);
  if (!posJogadorReal) {
    // Se a posição preferida não existe nesta formação, escolhe a primeira
    posJogadorReal = formacao.posicoes[Math.floor(Math.random() * formacao.posicoes.length)];
  }

  // Coloca o jogador real
  let posJogadorRealUsada = false;
  formacao.posicoes.forEach((p, i) => {
    if (p === posJogadorReal && !posJogadorRealUsada) {
      plantel.push({
        nome: S.nome,
        pos: p.pos,
        x: p.x,
        y: p.y,
        eu: true,
        atributo: Math.min(99, 50 + Math.round(S.scoreInscricao / 2))
      });
      posJogadorRealUsada = true;
    } else {
      // Colega fictício
      const nomes = NOMES_FUNNY[p.pos] || ['Jogador'];
      const nome = nomes[Math.floor(Math.random() * nomes.length)];
      plantel.push({
        nome: nome,
        pos: p.pos,
        x: p.x,
        y: p.y,
        eu: false,
        atributo: 50 + Math.floor(Math.random() * 30)
      });
    }
  });

  S.plantel = plantel;
}

function renderPlantel(svgId, animate) {
  const svg = el(svgId);
  if (!svg) return;
  let html = '';

  // Campo
  for (let i = 0; i < 8; i++) {
    html += `<rect x="30" y="${30 + i * 85}" width="440" height="85" fill="${i % 2 === 0 ? '#1F4A28' : '#1A3D22'}"/>`;
  }
  html += `<rect x="30" y="30" width="440" height="680" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<line x1="30" y1="370" x2="470" y2="370" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<circle cx="250" cy="370" r="55" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<rect x="120" y="30" width="260" height="115" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<rect x="180" y="30" width="140" height="50" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<rect x="120" y="595" width="260" height="115" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;
  html += `<rect x="180" y="660" width="140" height="50" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="2"/>`;

  // Jogadores
  S.plantel.forEach((j, idx) => {
    const cls = j.eu ? 'player-card you' : 'player-card';
    const fill = j.eu ? '#D4AF37' : '#fff';
    const txtColor = j.eu ? '#000' : '#000';
    const animDelay = animate ? `style="animation:fadeInUp .35s ${idx * 70}ms both"` : '';
    html += `
      <g class="${cls}" ${animDelay}>
        <circle cx="${j.x}" cy="${j.y}" r="22" fill="${fill}" stroke="#000" stroke-width="2.5" class="player-circle"/>
        <text x="${j.x}" y="${j.y + 4}" class="player-label" fill="${txtColor}">${j.pos}</text>
        <text x="${j.x}" y="${j.y + 38}" class="player-name" fill="#fff">${j.nome.length > 12 ? j.nome.substring(0, 11) + '…' : j.nome}</text>
      </g>`;
  });
  if (animate) {
    html += `<style>@keyframes fadeInUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}</style>`;
  }
  svg.innerHTML = html;
}

// ═══════════════════════════════════════════════════════
// FINALIZAR INSCRIÇÃO
// ═══════════════════════════════════════════════════════

async function finalizarInscricao() {
  const nomeEq = el('nomeEquipa').value.trim();
  if (!nomeEq) {
    showToast('Dá um nome à equipa!');
    el('nomeEquipa').focus();
    return;
  }
  S.nomeEquipa = nomeEq;
  S.codigo = genCodigo();

  // Guardar no Supabase
  const data = {
    codigo: S.codigo,
    nome: S.nome,
    idade: S.idade,
    escalao: S.escalao,
    posicao_preferida: S.posicaoPreferida,
    clube: S.clube,
    email_encarregado: S.emailEncarregado || null,
    consentimento_parental: S.consentParental,
    score_inscricao: S.scoreInscricao,
    respostas_questionario: S.respostas,
    plantel: S.plantel,
    nome_equipa: S.nomeEquipa,
    formacao: S.formacao,
    estilo: S.estilo,
    pontos_semana: 0,
    pontos_total: 0,
    vitorias_total: 0,
    jogos_jogados: 0
  };

  showToast('A guardar...', 1500);
  const result = await sbInsert('liga_jogadores', data);
  if (result && result[0]) {
    S.jogadorId = result[0].id;
  }
  // Mesmo se Supabase falhar (RLS, etc), guardamos local e seguimos
  guardarLocal();

  el('confirmEquipaNome').textContent = S.nomeEquipa;
  el('confirmCodigo').textContent = S.codigo;
  showScreen('confirm');
}

function guardarLocal() {
  const local = {
    codigo: S.codigo,
    jogadorId: S.jogadorId,
    nome: S.nome,
    idade: S.idade,
    escalao: S.escalao,
    posicaoPreferida: S.posicaoPreferida,
    clube: S.clube,
    nomeEquipa: S.nomeEquipa,
    plantel: S.plantel,
    formacao: S.formacao,
    estilo: S.estilo,
    pontosSemana: S.pontosSemana,
    pontosTotal: S.pontosTotal,
    vitorias: S.vitorias,
    jogosJogados: S.jogosJogados
  };
  localStorage.setItem('ytb-liga-local', JSON.stringify(local));
}

function carregarLocal() {
  const raw = localStorage.getItem('ytb-liga-local');
  if (!raw) return false;
  try {
    const d = JSON.parse(raw);
    Object.assign(S, d);
    return true;
  } catch (e) { return false; }
}

// ═══════════════════════════════════════════════════════
// LOGIN POR CÓDIGO
// ═══════════════════════════════════════════════════════

function showLogin() {
  el('loginCode').value = '';
  el('loginErr').style.display = 'none';
  showScreen('login');
  setTimeout(() => el('loginCode').focus(), 200);
}

async function tryLogin() {
  const code = el('loginCode').value.trim().toUpperCase();
  if (!code || !code.startsWith('YTB-')) {
    el('loginErr').style.display = 'block';
    return;
  }
  el('loginErr').style.display = 'none';
  showToast('A verificar...', 1500);

  const result = await sbSelect('liga_jogadores', 'codigo=eq.' + encodeURIComponent(code));
  if (result && result.length > 0) {
    const j = result[0];
    S.codigo = j.codigo;
    S.jogadorId = j.id;
    S.nome = j.nome;
    S.idade = j.idade;
    S.escalao = j.escalao;
    S.posicaoPreferida = j.posicao_preferida;
    S.clube = j.clube;
    S.nomeEquipa = j.nome_equipa;
    S.plantel = j.plantel || [];
    S.formacao = j.formacao || '4-3-3';
    S.estilo = j.estilo || 'equilibrado';
    S.pontosSemana = j.pontos_semana || 0;
    S.pontosTotal = j.pontos_total || 0;
    S.vitorias = j.vitorias_total || 0;
    S.jogosJogados = j.jogos_jogados || 0;
    guardarLocal();
    goToDashboard();
  } else {
    el('loginErr').style.display = 'block';
  }
}

// ═══════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════

function goToDashboard() {
  el('dashGreeting').innerHTML = `Olá, <span>${S.nome}</span>`;
  el('dashEquipaNome').textContent = S.nomeEquipa + ' · ' + (S.formacao || '4-3-3');
  el('statSemana').textContent = S.pontosSemana || 0;
  el('statTotal').textContent = S.pontosTotal || 0;
  el('statVitorias').textContent = S.vitorias || 0;
  updateNextGame();
  showScreen('dashboard');
}

function getNextGameInfo() {
  // Jogos: Quarta, Sexta, Domingo, todos às 21h
  const now = new Date();
  const dow = now.getDay(); // 0=Dom, 1=Seg, ..., 6=Sab
  const hour = now.getHours();

  // dias com jogo (0=Dom, 3=Qua, 5=Sex)
  const gameDays = [0, 3, 5];
  // dia da semana actual: vê se ainda há jogo hoje
  let hoje = gameDays.includes(dow) && hour < 21;
  if (hoje) {
    const next = new Date(now);
    next.setHours(21, 0, 0, 0);
    return { dia: dow, label: 'Hoje', time: next, podeJogar: false };
  }
  // Encontra o próximo dia
  let daysAhead = 7;
  for (let gd of gameDays) {
    let diff = (gd - dow + 7) % 7;
    if (diff === 0) diff = 7;
    if (diff < daysAhead) daysAhead = diff;
  }
  const next = new Date(now);
  next.setDate(now.getDate() + daysAhead);
  next.setHours(21, 0, 0, 0);
  const diaNomes = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
  return { dia: next.getDay(), label: diaNomes[next.getDay()], time: next, podeJogar: false };
}

function isGameWindowOpen() {
  // Janela: das 21:00 ate 22:30 nos dias de jogo
  const now = new Date();
  const dow = now.getDay();
  const h = now.getHours();
  const m = now.getMinutes();
  const gameDays = [0, 3, 5];
  if (!gameDays.includes(dow)) return false;
  if (h === 21) return true;
  if (h === 22 && m <= 30) return true;
  return false;
}

function updateNextGame() {
  const info = getNextGameInfo();
  const open = isGameWindowOpen();
  const hoje = info.label === 'Hoje' || open;

  if (open) {
    el('nextGameTag').textContent = '⚽ Jogo a decorrer';
    el('nextGameTitle').textContent = 'Está na hora! Joga agora.';
    el('nextGameTime').textContent = 'Janela aberta até às 22:30';
    el('nextGameCountdown').innerHTML = '';
    el('btnNextGameAction').textContent = '⚽ Jogar agora';
    el('btnNextGameAction').style.background = 'var(--green)';
    return;
  }

  el('nextGameTitle').textContent = info.label + ', 21h00';
  el('nextGameTime').textContent = formatDate(info.time);
  el('btnNextGameAction').textContent = '📋 Preparar táctica';
  el('btnNextGameAction').style.background = '';

  // Countdown
  renderCountdown(info.time);
  if (window.__cdTimer) clearInterval(window.__cdTimer);
  window.__cdTimer = setInterval(() => renderCountdown(info.time), 60000);
}

function renderCountdown(targetDate) {
  const now = new Date();
  let diff = targetDate - now;
  if (diff < 0) diff = 0;
  const days = Math.floor(diff / (24 * 3600 * 1000));
  const hours = Math.floor((diff % (24 * 3600 * 1000)) / (3600 * 1000));
  const mins = Math.floor((diff % (3600 * 1000)) / 60000);

  el('nextGameCountdown').innerHTML = `
    <div class="countdown-unit"><div class="countdown-num">${days}</div><div class="countdown-lbl">dias</div></div>
    <div class="countdown-unit"><div class="countdown-num">${hours}</div><div class="countdown-lbl">horas</div></div>
    <div class="countdown-unit"><div class="countdown-num">${mins}</div><div class="countdown-lbl">min</div></div>
  `;
}

function formatDate(d) {
  return d.toLocaleDateString('pt-PT', { day: '2-digit', month: 'long' });
}

function actionNextGame() {
  if (isGameWindowOpen()) {
    iniciarPreJogo();
  } else {
    showScreen('tactica');
    renderTactica();
  }
}

function showRanking() {
  showToast('Ranking em breve! 🏆');
}

// ═══════════════════════════════════════════════════════
// PLANTEL VIEW (vindo do dashboard)
// ═══════════════════════════════════════════════════════

function abrirPlantelView() {
  el('plantelViewName').innerHTML = S.nomeEquipa.length > 14 ? S.nomeEquipa.substring(0, 13) + '…' : S.nomeEquipa;
  el('plantelViewFormation').textContent = S.formacao + ' · ' + (S.estilo[0].toUpperCase() + S.estilo.slice(1));
  showScreen('plantel-view');
  renderPlantel('plantelViewSvg', false);
}

// ═══════════════════════════════════════════════════════
// TÁCTICA
// ═══════════════════════════════════════════════════════

function renderTactica() {
  // Formações
  let html = '';
  Object.keys(FORMACOES).forEach(key => {
    const sel = S.formacao === key ? 'selected' : '';
    html += `<button class="tactica-btn ${sel}" onclick="selectFormacao('${key}')">
      <span class="icon">⚽</span>
      ${key}
    </button>`;
  });
  el('formationRow').innerHTML = html;

  // Estilos
  html = '';
  ESTILOS.forEach(e => {
    const sel = S.estilo === e.id ? 'selected' : '';
    html += `<button class="tactica-btn ${sel}" onclick="selectEstilo('${e.id}')">
      <span class="icon">${e.icon}</span>
      ${e.nome}
    </button>`;
  });
  el('estiloRow').innerHTML = html;

  renderTacticaPreview();
}

function selectFormacao(key) {
  S.formacao = key;
  // Regenerar plantel para a nova formação (mantendo o jogador real na posição preferida)
  gerarPlantel();
  renderTactica();
  guardarLocal();
}

function selectEstilo(id) {
  S.estilo = id;
  renderTactica();
  guardarLocal();
}

function renderTacticaPreview() {
  renderPlantel('tacticaPreviewSvg', false);
}

async function saveTactica() {
  showToast('Táctica guardada ✓');
  guardarLocal();
  if (S.jogadorId) {
    await sbUpdate('liga_jogadores', S.jogadorId, {
      formacao: S.formacao,
      estilo: S.estilo,
      plantel: S.plantel
    });
  }
  setTimeout(() => goToDashboard(), 800);
}

// ═══════════════════════════════════════════════════════
// PRÉ-JOGO (Fase 2)
// ═══════════════════════════════════════════════════════

function iniciarPreJogo() {
  // Gerar adversário IA aleatório
  const advNome = NOMES_EQUIPAS_IA[Math.floor(Math.random() * NOMES_EQUIPAS_IA.length)];
  const formAdv = Object.keys(FORMACOES)[Math.floor(Math.random() * Object.keys(FORMACOES).length)];
  const estilosLista = ['defensivo', 'equilibrado', 'ofensivo'];
  const estiloAdv = estilosLista[Math.floor(Math.random() * estilosLista.length)];

  S.gameAdversario = {
    nome: advNome,
    formacao: formAdv,
    estilo: estiloAdv
  };

  const fraseTemplate = FRASES_IA_PREJOGO[Math.floor(Math.random() * FRASES_IA_PREJOGO.length)];
  const frase = fraseTemplate
    .replace('{ADV}', advNome)
    .replace('{VOCE}', S.nomeEquipa)
    .replace('{FORM}', formAdv)
    .replace('{ESTILO}', estiloAdv);

  el('advName').textContent = advNome;
  el('advMsg').textContent = '"' + frase + '"';
  el('prejogoFormacao').textContent = S.formacao;
  el('prejogoEstilo').textContent = (S.estilo[0].toUpperCase() + S.estilo.slice(1));
  el('prejogoData').textContent = formatDate(new Date());

  showScreen('prejogo');
}

// ═══════════════════════════════════════════════════════
// MOTOR DE JOGO (Fase 2)
// ═══════════════════════════════════════════════════════

function startGame() {
  S.gameIndex = 0;
  S.gameScore = 0;
  S.gameGolosPro = 0;
  S.gameGolosContra = 0;
  S.gameDecisoes = [];
  S.gameDataInicio = new Date();
  showScreen('game');
  renderGameStep();
}

function renderGameStep() {
  const c = CENARIOS_JOGO[S.gameIndex];
  el('gameMinute').textContent = c.minuto + "'";
  el('gameProgress').textContent = (S.gameIndex + 1) + '/' + CENARIOS_JOGO.length;
  el('gameScoreA').textContent = S.gameGolosPro;
  el('gameScoreB').textContent = S.gameGolosContra;
  el('gameSitTag').textContent = 'Decisão · ' + (c.fase === 'inicio' ? 'Início' : c.fase === 'meio' ? 'Meio' : 'Fim');
  el('gameSitTitle').textContent = c.situacao;
  el('gameSitContext').textContent = c.contexto;

  // Renderizar opções
  let html = '';
  c.opcoes.forEach(opt => {
    html += `<button class="opcao-btn" onclick="escolherOpcao('${opt.id}')">
      <div class="opcao-letra">${opt.id}</div>
      <div>${opt.texto}</div>
    </button>`;
  });
  el('gameOptions').innerHTML = html;
  el('gameFeedback').classList.remove('show');
  el('gameNextRow').style.display = 'none';
}

function escolherOpcao(optId) {
  const c = CENARIOS_JOGO[S.gameIndex];
  const opt = c.opcoes.find(o => o.id === optId);
  if (!opt) return;

  // Desactivar botões
  document.querySelectorAll('#gameOptions .opcao-btn').forEach(b => b.style.pointerEvents = 'none');

  // Acumular pontos
  S.gameScore += opt.pts;
  S.gameDecisoes.push({ id: c.id, opcao: optId, pts: opt.pts });

  // Verificar se houve golo (acertos altos podem dar golo na fase final)
  if (opt.pts >= 8 && (c.fase === 'meio' || c.fase === 'fim') && Math.random() < 0.4) {
    S.gameGolosPro++;
    el('gameScoreA').textContent = S.gameGolosPro;
  } else if (opt.pts <= -4) {
    // Erros graves podem dar golo do adversário
    if (Math.random() < 0.45) {
      S.gameGolosContra++;
      el('gameScoreB').textContent = S.gameGolosContra;
    }
  }

  // Mostrar feedback
  const fb = el('gameFeedback');
  el('gameFeedbackTag').className = 'game-feedback-tag ' + opt.tipo;
  el('gameFeedbackTag').textContent = opt.tipo === 'acerto' ? '✓ Boa escolha' : opt.tipo === 'erro' ? '✗ Erro táctico' : '○ Decisão neutra';
  el('gameFeedbackText').textContent = opt.fb;
  el('gameFeedbackPts').textContent = (opt.pts >= 0 ? '+' : '') + opt.pts + ' pts';
  fb.classList.add('show');

  // Mostrar botão "próxima"
  el('gameNextRow').style.display = 'flex';
  if (S.gameIndex === CENARIOS_JOGO.length - 1) {
    el('btnGameNext').textContent = 'Ver resultado →';
  } else {
    el('btnGameNext').textContent = 'Próxima jogada →';
  }
}

function nextGameStep() {
  if (S.gameIndex < CENARIOS_JOGO.length - 1) {
    S.gameIndex++;
    renderGameStep();
  } else {
    finalizarJogo();
  }
}

// ═══════════════════════════════════════════════════════
// FINALIZAR JOGO + RESULTADO
// ═══════════════════════════════════════════════════════

function calcularBonusTactica() {
  // Sistema simplificado: matchups formação vs formação + estilo vs estilo
  const adv = S.gameAdversario;
  if (!adv) return 0;

  let bonus = 0;

  // Matchup de formação
  const matchups = {
    '4-3-3-vs-4-4-2': 3,
    '4-4-2-vs-4-3-3': -2,
    '4-2-3-1-vs-4-4-2': 4,
    '4-4-2-vs-4-2-3-1': -3,
    '4-3-3-vs-4-2-3-1': 2,
    '4-2-3-1-vs-4-3-3': -1
  };
  const key = S.formacao + '-vs-' + adv.formacao;
  if (matchups[key] !== undefined) bonus += matchups[key];

  // Matchup de estilo
  if (S.estilo === 'defensivo' && adv.estilo === 'ofensivo') bonus += 4;
  if (S.estilo === 'ofensivo' && adv.estilo === 'defensivo') bonus -= 2;
  if (S.estilo === 'ofensivo' && adv.estilo === 'ofensivo') bonus += 1;
  if (S.estilo === 'equilibrado') bonus += 1;

  return bonus;
}

function finalizarJogo() {
  const bonusTactica = calcularBonusTactica();
  const totalPts = S.gameScore + bonusTactica;

  // Determinar resultado
  let resultado, golosPro, golosContra, pontosLiga, emoji;
  if (totalPts >= 50) {
    resultado = 'vitoria';
    golosPro = Math.max(2, S.gameGolosPro);
    golosContra = S.gameGolosContra;
    pontosLiga = 3;
    emoji = '🏆';
  } else if (totalPts >= 35) {
    resultado = 'vitoria';
    golosPro = Math.max(1, S.gameGolosPro);
    golosContra = Math.min(0, S.gameGolosContra);
    pontosLiga = 3;
    emoji = '🏆';
  } else if (totalPts >= 20) {
    resultado = 'empate';
    golosPro = Math.max(1, S.gameGolosPro);
    golosContra = Math.max(1, S.gameGolosContra);
    pontosLiga = 1;
    emoji = '🤝';
  } else if (totalPts >= 5) {
    resultado = 'derrota';
    golosPro = S.gameGolosPro;
    golosContra = Math.max(1, S.gameGolosContra);
    pontosLiga = 0;
    emoji = '😞';
  } else {
    resultado = 'derrota';
    golosPro = S.gameGolosPro;
    golosContra = Math.max(2, S.gameGolosContra);
    pontosLiga = 0;
    emoji = '😞';
  }

  // Garantir lógica: se vitória, golosPro > golosContra
  if (resultado === 'vitoria' && golosPro <= golosContra) golosPro = golosContra + 1;
  if (resultado === 'derrota' && golosContra <= golosPro) golosContra = golosPro + 1;
  if (resultado === 'empate') golosContra = golosPro;

  S.gameGolosPro = golosPro;
  S.gameGolosContra = golosContra;

  // Actualizar stats
  S.pontosSemana += pontosLiga;
  S.pontosTotal += pontosLiga;
  S.jogosJogados++;
  if (resultado === 'vitoria') S.vitorias++;

  // Renderizar resultado
  el('resultadoEmoji').textContent = emoji;
  el('resultadoTitle').textContent = resultado === 'vitoria' ? 'VITÓRIA' : resultado === 'empate' ? 'EMPATE' : 'DERROTA';
  el('resultadoTitle').className = 'resultado-title ' + resultado;
  el('resultadoScore').textContent = golosPro + ' — ' + golosContra;
  el('rsPontosDecisao').textContent = S.gameScore + ' pts';
  el('rsBonus').textContent = (bonusTactica >= 0 ? '+' : '') + bonusTactica;
  el('rsTotal').textContent = totalPts;
  el('rsLiga').textContent = '+' + pontosLiga;

  // Treino gerado
  const treino = gerarTreino(S.posicaoPreferida, resultado, S.gameDecisoes);
  el('treinoConteudo').innerHTML = treino;

  // Guardar no Supabase
  guardarJogoSupabase(resultado, golosPro, golosContra, pontosLiga, bonusTactica, totalPts);
  guardarLocal();

  showScreen('resultado');
}

function gerarTreino(pos, resultado, decisoes) {
  // Treinos personalizados por posição
  const treinos = {
    'GR': {
      'vitoria': '<strong>Reflexos:</strong> hoje fizeste boas defesas. Mantém o trabalho.<br><br><strong>Esta semana:</strong> 3× 15min de saídas de pé + 10min com bola alta.',
      'empate': '<strong>Saída de bola:</strong> trabalha o passe curto sob pressão.<br><br><strong>Esta semana:</strong> 3× 12min de saídas curtas com pressão + 10min de reflexos.',
      'derrota': '<strong>Posicionamento:</strong> nos lances de erro, ficaste mal colocado.<br><br><strong>Esta semana:</strong> 3× 15min de posicionamento + 10min de cruzamentos.'
    },
    'DC': {
      'vitoria': '<strong>Marcação:</strong> hoje fizeste a malta sentir-se segura.<br><br><strong>Esta semana:</strong> 3× 15min de marcação individual + 10min de cabeceamento.',
      'empate': '<strong>Saída de bola:</strong> trabalha o passe longo para o avante.<br><br><strong>Esta semana:</strong> 3× 12min de saídas curtas e longas + 10min de duelos.',
      'derrota': '<strong>Coberturas:</strong> faltaram dobras hoje. Comunica mais.<br><br><strong>Esta semana:</strong> 3× 15min de coberturas + 10min de marcação.'
    },
    'LD': { 'vitoria':'<strong>Subida na faixa:</strong> hoje atacaste bem a faixa. Continua.<br><br><strong>Esta semana:</strong> 3× 15min de cruzamentos + 10min de 1v1.', 'empate':'<strong>Decisão na faixa:</strong> escolhe melhor quando cruzar.<br><br><strong>Esta semana:</strong> 3× 12min de cruzamentos com decisão + 10min de coberturas.', 'derrota':'<strong>Equilíbrio defensivo:</strong> ficaste alto e abriste buraco.<br><br><strong>Esta semana:</strong> 3× 15min de transições + 10min de dobras.' },
    'LE': { 'vitoria':'<strong>Subida na faixa:</strong> hoje atacaste bem a faixa. Continua.<br><br><strong>Esta semana:</strong> 3× 15min de cruzamentos + 10min de 1v1.', 'empate':'<strong>Decisão na faixa:</strong> escolhe melhor quando cruzar.<br><br><strong>Esta semana:</strong> 3× 12min de cruzamentos com decisão + 10min de coberturas.', 'derrota':'<strong>Equilíbrio defensivo:</strong> ficaste alto e abriste buraco.<br><br><strong>Esta semana:</strong> 3× 15min de transições + 10min de dobras.' },
    'MD': { 'vitoria':'<strong>Coberturas:</strong> deste equilíbrio à malta hoje.<br><br><strong>Esta semana:</strong> 3× 15min de coberturas + 10min de passe curto.', 'empate':'<strong>Decisão sob pressão:</strong> trabalha o jogo de primeira.<br><br><strong>Esta semana:</strong> 3× 12min de circulação rápida + 10min de roubos.', 'derrota':'<strong>Pressão:</strong> demoraste a sair à pressão. Antecipa mais.<br><br><strong>Esta semana:</strong> 3× 15min de pressão + 10min de coberturas.' },
    'MC': { 'vitoria':'<strong>Visão de jogo:</strong> hoje viste o passe.<br><br><strong>Esta semana:</strong> 3× 15min de passe vertical + 10min de remate.', 'empate':'<strong>Iniciativa:</strong> arrisca mais o passe que rasga.<br><br><strong>Esta semana:</strong> 3× 12min de passe em rutura + 10min de finalização.', 'derrota':'<strong>Decisão:</strong> hoje atrasaste muitas bolas. Joga vertical.<br><br><strong>Esta semana:</strong> 3× 15min de passe vertical + 10min de pressão.' },
    'MO': { 'vitoria':'<strong>Drible no buraco:</strong> hoje rasgaste a defesa.<br><br><strong>Esta semana:</strong> 3× 15min de drible no buraco + 10min de finalização.', 'empate':'<strong>Buscar a bola:</strong> aparece mais entre linhas.<br><br><strong>Esta semana:</strong> 3× 12min de receção entre linhas + 10min de remate.', 'derrota':'<strong>Trabalho defensivo:</strong> precisas de morder mais sem bola.<br><br><strong>Esta semana:</strong> 3× 15min de pressão + 10min de transições.' },
    'ED': { 'vitoria':'<strong>1v1 na faixa:</strong> hoje fizeste a diferença.<br><br><strong>Esta semana:</strong> 3× 15min de drible + 10min de cruzamentos.', 'empate':'<strong>Final do drible:</strong> melhora a decisão antes de cruzar.<br><br><strong>Esta semana:</strong> 3× 12min de 1v1 + 10min de cruzamentos.', 'derrota':'<strong>Decisão:</strong> escolheste mal várias vezes. Levanta a cabeça.<br><br><strong>Esta semana:</strong> 3× 15min de drible com decisão.' },
    'EE': { 'vitoria':'<strong>1v1 na faixa:</strong> hoje fizeste a diferença.<br><br><strong>Esta semana:</strong> 3× 15min de drible + 10min de cruzamentos.', 'empate':'<strong>Final do drible:</strong> melhora a decisão antes de cruzar.<br><br><strong>Esta semana:</strong> 3× 12min de 1v1 + 10min de cruzamentos.', 'derrota':'<strong>Decisão:</strong> escolheste mal várias vezes. Levanta a cabeça.<br><br><strong>Esta semana:</strong> 3× 15min de drible com decisão.' },
    'PL': { 'vitoria':'<strong>Finalização:</strong> hoje meteste a bola onde tinha de ir.<br><br><strong>Esta semana:</strong> 3× 15min de remate + 10min de jogo de costas.', 'empate':'<strong>Movimentação:</strong> aparece mais nas zonas de finalização.<br><br><strong>Esta semana:</strong> 3× 12min de desmarcações + 10min de remate.', 'derrota':'<strong>Confiança no remate:</strong> hesitaste em momentos chave.<br><br><strong>Esta semana:</strong> 3× 15min de remate + 10min de cabeceamento.' }
  };

  const fallback = '<strong>Trabalho geral:</strong> mais técnica, mais decisão, mais foco.<br><br><strong>Esta semana:</strong> 3× 15min de jogo reduzido + 10min de técnica individual.';
  return (treinos[pos] && treinos[pos][resultado]) || fallback;
}

async function guardarJogoSupabase(resultado, golosPro, golosContra, pontosLiga, bonus, total) {
  // Calcular semana ISO
  const now = new Date();
  const onejan = new Date(now.getFullYear(), 0, 1);
  const semana = Math.ceil((((now - onejan) / 86400000) + onejan.getDay() + 1) / 7);

  const dow = now.getDay();
  const dia = dow === 3 ? 'qua' : dow === 5 ? 'sex' : 'dom';

  if (S.jogadorId) {
    await sbInsert('liga_jogos', {
      jogador_id: S.jogadorId,
      semana: semana,
      dia: dia,
      formacao_jogador: S.formacao,
      formacao_ia: S.gameAdversario ? S.gameAdversario.formacao : null,
      estilo_jogador: S.estilo,
      decisoes: S.gameDecisoes,
      pontos_decisao: S.gameScore,
      golos_pro: golosPro,
      golos_contra: golosContra,
      resultado: resultado,
      pontos_ganhos: pontosLiga
    });

    await sbUpdate('liga_jogadores', S.jogadorId, {
      pontos_semana: S.pontosSemana,
      pontos_total: S.pontosTotal,
      vitorias_total: S.vitorias,
      jogos_jogados: S.jogosJogados,
      last_active_at: now.toISOString()
    });
  }
}

// ═══════════════════════════════════════════════════════
// INIT
// ═══════════════════════════════════════════════════════

// Listener para "Voltar" do dashboard.plantel-view
window.addEventListener('DOMContentLoaded', function() {
  // Bindings extras
  el('loginCode').addEventListener('keydown', e => { if (e.key === 'Enter') tryLogin(); });
  el('nomeJogador').addEventListener('keydown', e => { if (e.key === 'Enter') el('idadeJogador').focus(); });

  // Hook do botão "A minha equipa" no dashboard
  document.querySelectorAll('.dash-action').forEach(b => {
    const onclick = b.getAttribute('onclick') || '';
    if (onclick.includes('plantel-view')) {
      b.removeAttribute('onclick');
      b.addEventListener('click', abrirPlantelView);
    }
  });

  // Service Worker
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw-liga.js').catch(() => {});
  }

  // Detectar se já tem conta local
  if (carregarLocal() && S.codigo) {
    goToDashboard();
  } else {
    showScreen('welcome');
  }
});
