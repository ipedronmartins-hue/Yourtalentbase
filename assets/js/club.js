/* ================================================================
   YOURTALENTBASE · club.js
   Club OS — Presenças, Treinos, Plantel, Financeiro, FPF
================================================================ */
(function() {
'use strict';

/* ── PLANTEL (Mister Teles · Gondomar SC Sub-12) ────────────── */
const PLANTEL = [
  { num:1,  nome:'Enzo Faria',         idade:11, pos:'GR',  posLabel:'Guarda-Redes' },
  { num:22, nome:'Rafael Delindro',    idade:12, pos:'GR',  posLabel:'Guarda-Redes' },
  { num:29, nome:'Diego Barbosa',      idade:11, pos:'GR',  posLabel:'Guarda-Redes' },
  { num:4,  nome:'Duarte Costa',       idade:11, pos:'DEF', posLabel:'Defesa' },
  { num:13, nome:'Guilherme Barbosa',  idade:12, pos:'DEF', posLabel:'Defesa' },
  { num:17, nome:'Santos',             idade:11, pos:'DEF', posLabel:'Defesa' },
  { num:28, nome:'Salvador Neves',     idade:11, pos:'DEF', posLabel:'Defesa' },
  { num:14, nome:'Gonçalo Brito',      idade:12, pos:'DEF', posLabel:'Defesa' },
  { num:5,  nome:'Gabriel Matos',      idade:12, pos:'DEF', posLabel:'Defesa' },
  { num:25, nome:'Rodrigo Rocha',      idade:11, pos:'DEF', posLabel:'Defesa' },
  { num:27, nome:'Fernando Gonçalves', idade:12, pos:'DEF', posLabel:'Defesa' },
  { num:null,nome:'Pedro Sousa',       idade:13, pos:'MED', posLabel:'Médio' },
  { num:8,  nome:'José Sousa',         idade:11, pos:'MED', posLabel:'Médio' },
  { num:11, nome:'Mateus Silva',       idade:11, pos:'MED', posLabel:'Médio' },
  { num:15, nome:'Salvador Pinho',     idade:12, pos:'MED', posLabel:'Médio' },
  { num:20, nome:'João Vieira',        idade:11, pos:'MED', posLabel:'Médio' },
  { num:3,  nome:'Santiago Gonçalves', idade:12, pos:'MED', posLabel:'Médio' },
  { num:10, nome:'Vasco Coutinho',     idade:11, pos:'MED', posLabel:'Médio', agenciado:true },
  { num:7,  nome:'Rodrigo Batista',    idade:12, pos:'AVA', posLabel:'Avançado' },
  { num:9,  nome:'Dinis Soares',       idade:11, pos:'AVA', posLabel:'Avançado' },
  { num:18, nome:'Rafael Rocha',       idade:12, pos:'AVA', posLabel:'Avançado' },
  { num:30, nome:'Dinis Duarte',       idade:11, pos:'AVA', posLabel:'Avançado' },
  { num:47, nome:'Tomás Morais',       idade:11, pos:'AVA', posLabel:'Avançado' },
  { num:6,  nome:'Miguel Gaspar',      idade:11, pos:'AVA', posLabel:'Avançado' },
  { num:90, nome:'Rafael Cerqueira',   idade:null,pos:'AVA',posLabel:'Avançado' },
];

const POS_COLORS = {
  GR:  { bg:'rgba(139,92,246,.12)', border:'rgba(139,92,246,.3)', color:'#a78bfa' },
  DEF: { bg:'rgba(59,130,246,.12)', border:'rgba(59,130,246,.3)', color:'#60a5fa' },
  MED: { bg:'rgba(212,175,55,.10)', border:'rgba(212,175,55,.22)', color:'#D4AF37' },
  AVA: { bg:'rgba(239,68,68,.10)',  border:'rgba(239,68,68,.25)',  color:'#ef4444' },
};

/* ── STATE ───────────────────────────────────────────────────── */
const S = {
  presencas:  {},  // { idx: 'P'|'F'|'L' }
  intensidade:{},  // { idx: 1-5 }
  treinos:    YTB.store.get('ytb_treinos') || [],
  ntIntens:   3,
  ntTipos:    [],
  ntDinam:    [],
};

/* ── UTILS ───────────────────────────────────────────────────── */
function el(id){ return document.getElementById(id); }

/* ── SIDEBAR / MODULE NAVIGATION ────────────────────────────── */
function initNav() {
  const sidebar  = el('sidebar');
  const backdrop = el('sidebarBackdrop');
  const toggle   = el('btnSideToggle');

  toggle?.addEventListener('click', () => {
    sidebar.classList.toggle('open');
    backdrop.classList.toggle('show');
  });
  backdrop?.addEventListener('click', () => {
    sidebar.classList.remove('open');
    backdrop.classList.remove('show');
  });

  document.querySelectorAll('[data-module]').forEach(btn => {
    btn.addEventListener('click', () => {
      const mod = btn.dataset.module;
      switchModule(mod);
      // Close sidebar on mobile
      if (window.innerWidth < 1024) {
        sidebar.classList.remove('open');
        backdrop.classList.remove('show');
      }
    });
  });
}

function switchModule(name) {
  // Nav items
  document.querySelectorAll('.snav-item').forEach(b => {
    b.classList.toggle('active', b.dataset.module === name);
  });
  // Module panels
  document.querySelectorAll('.module').forEach(m => {
    m.classList.toggle('active', m.id === 'mod-'+name);
  });
  // Lazy render
  const renders = { presencas:renderPresencas, treinos:renderTreinos, plantel:renderPlantel, financeiro:renderFinanceiro, fpf:renderFPF };
  renders[name]?.();
}

/* ── PRESENÇAS ───────────────────────────────────────────────── */
function renderPresencas() {
  const list = el('presList'); if (!list) return;
  const hoje = new Date().toISOString().slice(0,10);
  const di = el('presData');
  if (di && !di.value) di.value = hoje;

  let h = '';
  PLANTEL.forEach((a, i) => {
    const estado = S.presencas[i] || '';
    const intens = S.intensidade[i] || 0;
    const pColor = POS_COLORS[a.pos] || POS_COLORS.MED;
    h += `<div class="pres-item">
      <div class="pres-num">${a.num||'—'}</div>
      <div class="player-avatar">${a.nome.charAt(0)}</div>
      <div class="pres-info" style="flex:1;min-width:0;">
        <div class="pres-nome truncate">${a.nome}${a.agenciado?' <span style="font-size:8px;color:#D4AF37;">★</span>':''}</div>
        <div class="pres-pos" style="color:${pColor.color};">${a.posLabel}</div>
      </div>
      <div class="pres-btns">
        <button class="pb ${estado==='P'?'p':''}" data-pidx="${i}" data-pv="P" title="Presente">✓</button>
        <button class="pb ${estado==='F'?'f':''}" data-pidx="${i}" data-pv="F" title="Falta">✕</button>
        <button class="pb ${estado==='L'?'l':''}" data-pidx="${i}" data-pv="L" title="Lesionado">🩹</button>
      </div>
      ${estado==='P' ? `<div class="pres-intens">
        ${[1,2,3,4,5].map(v=>`<button class="pi ${intens===v?'sel':''}" data-iidx="${i}" data-iv="${v}">${v}</button>`).join('')}
      </div>` : '<div style="width:160px;"></div>'}
    </div>`;
  });
  list.innerHTML = h;
  updatePresStats();
}

function updatePresStats() {
  const vals = Object.values(S.presencas);
  const p = vals.filter(v=>v==='P').length;
  const f = vals.filter(v=>v==='F').length;
  const l = vals.filter(v=>v==='L').length;
  const t = PLANTEL.length;
  if(el('presTotal'))     el('presTotal').textContent = t;
  if(el('presPresentes')) el('presPresentes').textContent = p;
  if(el('presFaltas'))    el('presFaltas').textContent = f;
  if(el('presLesionados'))el('presLesionados').textContent = l;
  // Badge no nav
  const badge = el('badgePresencas');
  if (badge) { badge.textContent = f+l > 0 ? f+l : ''; }
}

/* ── TREINOS ─────────────────────────────────────────────────── */
function renderTreinos() {
  const cont = el('treinosContent'); if (!cont) return;
  if (!S.treinos.length) {
    cont.innerHTML = `<div class="empty-state"><div class="empty-state-icon">⏱</div><div class="empty-state-text">Sem treinos registados. Cria o primeiro!</div></div>`;
    return;
  }
  let h = '<div style="display:flex;flex-direction:column;gap:12px;">';
  [...S.treinos].reverse().forEach(t => {
    const tipos = t.tipos?.join(', ') || '—';
    const dinam = t.dinamicas?.join(', ') || '—';
    h += `<div class="card">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px;margin-bottom:12px;">
        <div>
          <div class="eyebrow">${t.data || '—'}</div>
          <div style="font-family:var(--font-display);font-size:20px;font-weight:900;line-height:1.1;margin-top:4px;">${t.objetivo || 'Treino'}</div>
        </div>
        <div style="display:flex;gap:8px;flex-shrink:0;">
          <div class="badge badge-gray">⏱ ${t.duracao||'—'} min</div>
          <div class="badge badge-gold">Intensidade ${t.intensidade}/5</div>
        </div>
      </div>
      ${tipos !== '—' ? `<div style="display:flex;flex-wrap:wrap;gap:5px;margin-bottom:8px;">${t.tipos.map(tp=>`<span class="badge badge-blue">${tp}</span>`).join('')}</div>`:''}
      ${t.notas ? `<div style="font-size:12px;color:var(--muted);font-weight:300;">${t.notas}</div>`:''}
    </div>`;
  });
  h += '</div>';
  cont.innerHTML = h;
}

function salvarTreino() {
  const treino = {
    id: Date.now(),
    data: el('nt-data')?.value || new Date().toISOString().slice(0,10),
    duracao: el('nt-dur')?.value || 90,
    objetivo: el('nt-obj')?.value || '',
    intensidade: S.ntIntens,
    tipos: [...S.ntTipos],
    dinamicas: [...S.ntDinam],
    notas: el('nt-notas')?.value || '',
  };
  S.treinos.push(treino);
  YTB.store.set('ytb_treinos', S.treinos);
  YTB.closeOverlay('ovNovoTreino');
  YTB.toast('Treino guardado!', 'success');
  // Reset
  S.ntTipos = []; S.ntDinam = []; S.ntIntens = 3;
  document.querySelectorAll('.ttag').forEach(b => b.classList.remove('sel'));
  document.querySelectorAll('.intens-btn').forEach(b => b.classList.toggle('sel', b.dataset.val==='3'));
  renderTreinos();
}

/* ── PLANTEL ─────────────────────────────────────────────────── */
function renderPlantel(filtro = '', posFilter = '') {
  const cont = el('plantelContent'); if (!cont) return;
  const grupos = {};
  PLANTEL.forEach((a, i) => {
    if (filtro && !a.nome.toLowerCase().includes(filtro.toLowerCase())) return;
    if (posFilter && a.pos !== posFilter) return;
    if (!grupos[a.pos]) grupos[a.pos] = [];
    grupos[a.pos].push({ ...a, idx:i });
  });
  const posOrder = ['GR','DEF','MED','AVA'];
  const posNames = { GR:'Guarda-Redes', DEF:'Defesa', MED:'Médio', AVA:'Avançado' };
  let h = '';
  posOrder.forEach(pos => {
    if (!grupos[pos]) return;
    const pc = POS_COLORS[pos];
    h += `<div class="plantel-pos-group">
      <div class="plantel-pos-label" style="color:${pc.color};">
        ${posNames[pos]}
        <span class="plantel-pos-badge badge" style="background:${pc.bg};color:${pc.color};border:1px solid ${pc.border};">${grupos[pos].length}</span>
      </div>
      <div>`;
    grupos[pos].forEach(a => {
      const presRate = Math.floor(Math.random()*30+70); // placeholder
      const presColor = presRate >= 80 ? 'var(--green)' : presRate >= 60 ? 'var(--orange)' : 'var(--red)';
      h += `<div class="player-row" data-pidx="${a.idx}">
        <div class="player-num">${a.num||'—'}</div>
        <div class="player-avatar" style="background:linear-gradient(135deg,${pc.bg.replace('.12','.3')},${pc.bg});">${a.nome.charAt(0)}</div>
        <div class="player-info">
          <div class="player-name">${a.nome}${a.agenciado?' <span style="font-size:10px;color:#D4AF37;">★ YTB</span>':''}</div>
          <div class="player-meta">${a.idade ? a.idade+' anos' : '—'} · ${a.posLabel}</div>
        </div>
        <div class="player-pres" style="background:${presColor}22;color:${presColor};border:1px solid ${presColor}44;font-size:9px;font-weight:700;">${presRate}%</div>
      </div>`;
    });
    h += `</div></div>`;
  });
  cont.innerHTML = h || `<div class="empty-state"><div class="empty-state-icon">🔍</div><div class="empty-state-text">Sem resultados.</div></div>`;
}

/* ── FINANCEIRO ──────────────────────────────────────────────── */
const PAGAMENTOS = [
  { nome:'Enzo Faria',        estado:'pago',   valor:25, data:'01 Abr' },
  { nome:'Rafael Delindro',   estado:'pago',   valor:25, data:'02 Abr' },
  { nome:'Diego Barbosa',     estado:'atraso', valor:25, data:null },
  { nome:'Duarte Costa',      estado:'pago',   valor:25, data:'01 Abr' },
  { nome:'Guilherme Barbosa', estado:'pago',   valor:25, data:'03 Abr' },
  { nome:'Santos',            estado:'atraso', valor:25, data:null },
  { nome:'Salvador Neves',    estado:'pago',   valor:25, data:'01 Abr' },
  { nome:'Gonçalo Brito',     estado:'pago',   valor:25, data:'04 Abr' },
  { nome:'Gabriel Matos',     estado:'pago',   valor:25, data:'02 Abr' },
  { nome:'Rodrigo Rocha',     estado:'atraso', valor:25, data:null },
  { nome:'Fernando Gonçalves',estado:'pago',   valor:25, data:'01 Abr' },
];

function renderFinanceiro() {
  const cont = el('financeiroContent'); if (!cont) return;
  const pagos  = PAGAMENTOS.filter(p=>p.estado==='pago').length;
  const atraso = PAGAMENTOS.filter(p=>p.estado==='atraso').length;
  const totalPago  = pagos  * 25;
  const totalDivida= atraso * 25;

  let h = `<div class="fin-summary">
    <div class="fin-card card-gradient">
      <div class="fin-val" style="color:var(--green);">${totalPago}€</div>
      <div class="fin-label">Recebido este mês</div>
    </div>
    <div class="fin-card">
      <div class="fin-val" style="color:var(--red);">${totalDivida}€</div>
      <div class="fin-label">Em atraso</div>
    </div>
    <div class="fin-card">
      <div class="fin-val" style="color:var(--gold);">${pagos}</div>
      <div class="fin-label">Pagaram</div>
    </div>
    <div class="fin-card">
      <div class="fin-val" style="color:var(--orange);">${atraso}</div>
      <div class="fin-label">Em falta</div>
    </div>
  </div>
  <div class="text-2xs text-muted" style="margin-bottom:12px;">Lista de pagamentos · Abril 2026</div>
  <div>`;

  PAGAMENTOS.forEach(p => {
    const ok = p.estado === 'pago';
    h += `<div class="pay-row">
      <div class="player-avatar">${p.nome.charAt(0)}</div>
      <div style="flex:1;">
        <div style="font-size:13px;font-weight:600;">${p.nome}</div>
        <div style="font-size:11px;color:var(--muted);">${ok ? '✓ Pago em '+p.data : '⚠ Aguardado'}</div>
      </div>
      <div style="font-size:14px;font-weight:700;color:${ok?'var(--green)':'var(--red)'};">${p.valor}€</div>
      ${!ok ? `<button class="btn btn-sm" style="background:var(--green-soft);color:var(--green);border:1px solid var(--green-border);margin-left:8px;">Marcar pago</button>` : ''}
    </div>`;
  });
  h += '</div>';
  cont.innerHTML = h;
}

/* ── FPF CERTIFICATION ───────────────────────────────────────── */
function renderFPF() {
  const cont = el('fpfContent'); if (!cont) return;
  const items = [
    { label:'Presenças registadas',      ok:true,  val:'124 / 120 mínimo' },
    { label:'Licença treinador principal',ok:true,  val:'UEFA B · Válida 2026' },
    { label:'Licença adjunto',           ok:false, val:'Em falta' },
    { label:'Documentação de atletas',   ok:'partial', val:'22 / 25 completas' },
    { label:'Exames médicos em dia',     ok:true,  val:'25 / 25' },
    { label:'Plano de treino registado', ok:true,  val:'12 sessões este mês' },
    { label:'Seguro desportivo',         ok:true,  val:'Válido até Dez 2026' },
  ];
  const stars = 4;
  let h = `<div class="card card-gradient" style="margin-bottom:var(--space-5);">
    <div class="eyebrow">Classificação actual</div>
    <div class="fpf-stars">`;
  for (let i=1;i<=5;i++) {
    h += `<span class="fpf-star ${i<=stars?'active':''}">⭐</span>`;
  }
  h += `</div>
    <div style="font-family:var(--font-display);font-size:24px;font-weight:900;color:var(--gold);">${stars}/5 Estrelas</div>
    <div style="font-size:13px;color:var(--muted);margin-top:4px;font-weight:300;">Gondomar SC · Sub-12 · Época 2025/26</div>
    <div class="progress-wrap progress-md" style="margin-top:var(--space-4);">
      <div class="progress-bar" style="width:${stars/5*100}%;"></div>
    </div>
  </div>
  <div class="text-2xs text-muted" style="margin-bottom:var(--space-4);">Checklist de certificação</div>`;

  items.forEach(item => {
    const st = item.ok === true ? 'ok' : item.ok === 'partial' ? 'partial' : 'nok';
    const icon = st==='ok' ? '✓' : st==='partial' ? '!' : '✕';
    h += `<div class="fpf-progress-item">
      <div class="fpf-check ${st}">${icon}</div>
      <div style="flex:1;">
        <div style="font-size:13px;font-weight:600;">${item.label}</div>
        <div style="font-size:11px;color:var(--muted);margin-top:2px;">${item.val}</div>
      </div>
    </div>`;
  });
  cont.innerHTML = h;
}

/* ── CALENDÁRIO ──────────────────────────────────────────────── */
function renderCalendario() {
  const cont = el('calendarioContent'); if (!cont) return;
  const eventos = [
    { data:'22 Abr', titulo:'Treino', tipo:'Treino', local:'Campo 3 · 18h00' },
    { data:'26 Abr', titulo:'Gondomar SC vs FC Porto B', tipo:'Jogo', local:'Estádio Municipal · 10h30' },
    { data:'29 Abr', titulo:'Treino', tipo:'Treino', local:'Campo 3 · 18h00' },
    { data:'3 Mai',  titulo:'Treino', tipo:'Treino', local:'Campo 3 · 18h00' },
    { data:'10 Mai', titulo:'Gondomar SC vs Boavista B', tipo:'Jogo', local:'Deslocação · 11h00' },
  ];
  let h = '<div class="events-list">';
  eventos.forEach(e => {
    const parts = e.data.split(' ');
    const badgeCls = e.tipo === 'Jogo' ? 'badge-gold' : 'badge-blue';
    h += `<div class="event-item card" style="margin-bottom:8px;">
      <div class="event-date" style="min-width:44px;">
        <div class="event-day">${parts[0]}</div>
        <div class="event-month">${parts[1]||''}</div>
      </div>
      <div class="event-info">
        <div class="event-title">${e.titulo}</div>
        <div class="event-sub">${e.local}</div>
      </div>
      <span class="badge ${badgeCls}">${e.tipo}</span>
    </div>`;
  });
  h += '</div>';
  cont.innerHTML = h;
}

/* ── EVENT DELEGATION ─────────────────────────────────────────── */
document.addEventListener('click', function(e) {
  const t = e.target;

  // Presença status
  if (t.dataset.pv && t.dataset.pidx !== undefined) {
    const idx = parseInt(t.dataset.pidx);
    const current = S.presencas[idx];
    S.presencas[idx] = current === t.dataset.pv ? '' : t.dataset.pv;
    renderPresencas();
    return;
  }

  // Intensidade presença
  if (t.dataset.iv && t.dataset.iidx !== undefined) {
    const idx = parseInt(t.dataset.iidx);
    S.intensidade[idx] = parseInt(t.dataset.iv);
    renderPresencas();
    return;
  }

  // Novo treino modal
  if (t.id === 'btnNovoTreino') {
    const hoje = new Date().toISOString().slice(0,10);
    const di = el('nt-data'); if (di) di.value = hoje;
    YTB.openOverlay('ovNovoTreino');
    return;
  }

  // Salvar treino
  if (t.id === 'btnSalvarTreino') { salvarTreino(); return; }

  // Guardar presenças
  if (t.id === 'btnGuardarPres') {
    YTB.toast(`Presenças guardadas! ${Object.values(S.presencas).filter(v=>v==='P').length} presentes.`, 'success');
    return;
  }

  // Treino tipo/dinámica tags
  if (t.classList.contains('ttag')) {
    t.classList.toggle('sel');
    const arr = t.closest('#tipoTags') ? S.ntTipos : S.ntDinam;
    const tag = t.dataset.tag;
    const i = arr.indexOf(tag);
    i >= 0 ? arr.splice(i,1) : arr.push(tag);
    return;
  }

  // Intensidade treino
  if (t.classList.contains('intens-btn') && t.closest('#intensGrid')) {
    S.ntIntens = parseInt(t.dataset.val);
    document.querySelectorAll('.intens-btn').forEach(b => b.classList.toggle('sel', b === t));
    return;
  }

  // Plantel search
  if (t.id === 'searchPlantel' || t.id === 'filterPos') {
    renderPlantel(el('searchPlantel')?.value, el('filterPos')?.value);
    return;
  }
});

// Plantel live search
document.addEventListener('input', function(e) {
  if (e.target.id === 'searchPlantel') {
    renderPlantel(e.target.value, el('filterPos')?.value);
  }
});
document.addEventListener('change', function(e) {
  if (e.target.id === 'filterPos') {
    renderPlantel(el('searchPlantel')?.value, e.target.value);
  }
});

/* ── INIT ────────────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
  initNav();
  // Set today's date
  const di = el('presData');
  if (di) di.value = new Date().toISOString().slice(0,10);
  // Default intensity button
  const def = document.querySelector('.intens-btn[data-val="3"]');
  if (def) def.classList.add('sel');
});

})();
