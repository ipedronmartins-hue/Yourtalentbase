/* ================================================================
   YOURTALENTBASE · home.js
   Landing page — athlete profiles, inscription form, interactions
================================================================ */
(function() {
'use strict';

const SB_URL = 'https://nhshnplaiolxwcfuijfo.supabase.co';
const SB_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oc2hucGxhaW9seHdjZnVpamZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NDQxNTAsImV4cCI6MjA4OTQyMDE1MH0.uyZiDun8495sjnHA6Wsk-Hou-3lubbNJfQqSYbMLSek';
const db = supabase.createClient(SB_URL, SB_KEY);

/* ── ATHLETE DATA ───────────────────────────────────────────── */
const ATLETAS = {
  guilherme: {
    nome:'Neto', completo:'Guilherme Branco Gaspar Neto', nivel:'A',
    nascimento:'2007 · 17 anos', escalao:'Sub-19 · II Divisão · 2025/26',
    clube:'Gondomar SC', foto:'guilherme.jpg', fotoPos:'center 20%',
    posicao:'Médio', pe:'Esquerdo',
    stats:[{n:'16',l:'Jogos'},{n:'1313',l:'Min'},{n:'1',l:'Golos'}],
    tags:['Médio','Capitão','🇵🇹'],
    bio:'Médio com dupla nacionalidade portuguesa e brasileira, capitão do Gondomar SC Sub-19. Formado no Boavista, Rio Ave e Leixões. Liderança natural, visão de jogo acima da média e experiência acumulada em competições distritais e nacionais.',
    hist:[
      {e:'2025/26',c:'Gondomar SC',esc:'Sub-19',j:16,g:1},
      {e:'2024/25',c:'Gondomar SC',esc:'Sub-19',j:18,g:2},
      {e:'2023/24',c:'Leixões SC', esc:'Sub-19',j:14,g:0},
    ],
    palmares:[],
    zz:'https://www.zerozero.pt/jogador/guilherme-neto/916200',
  },
  vasco: {
    nome:'Coutinho', completo:'Vasco Coutinho Martins', nivel:'A',
    nascimento:'2014 · 11 anos', escalao:'Sub-13 · 2ª Divisão · 2025/26',
    clube:'Gondomar SC', foto:'vasco.jpg', fotoPos:'center center',
    posicao:'MDC', pe:'Direito',
    stats:[{n:'18',l:'Jogos'},{n:'593',l:'Min'},{n:'2',l:'Golos'}],
    tags:['MDC','2× Campeão Elite','🇵🇹'],
    bio:'Médio defensivo de 11 anos formado no Gondomar SC. Bicampeão Distrital na Divisão Elite — Sub-10 e Sub-11. Leitura de jogo excecional para a idade, com capacidade de controlo do ritmo e distribuição limpa. O nº10 fala por si.',
    hist:[
      {e:'2025/26',c:'Gondomar SC',esc:'Sub-13',j:18,g:2},
      {e:'2024/25',c:'Gondomar SC',esc:'Sub-11',j:24,g:3},
      {e:'2023/24',c:'Gondomar SC',esc:'Sub-10',j:20,g:4},
    ],
    palmares:[
      'Campeão Distrital Sub-10 · Divisão Elite',
      'Campeão Distrital Sub-11 · Divisão Elite',
    ],
    zz:'https://www.zerozero.pt/jogador/vasco-coutinho/1100918',
  },
  duarte: {
    nome:'Du', completo:'Duarte Filipe Simões Almeida', nivel:'A',
    nascimento:'2 Mai 2013 · 12 anos', escalao:'Sub-15 · AF Braga · 2025/26',
    clube:'FC Famalicão', foto:'duarte.jpg', fotoPos:'center 35%',
    posicao:'GR', pe:'Direito',
    stats:[{n:'12',l:'Jogos'},{n:'1080',l:'Min'},{n:'—',l:'GR'}],
    tags:['Guarda-Redes','EIR relevante'],
    bio:'Guarda-redes de 12 anos que joga dois escalões acima da sua faixa etária no FC Famalicão Sub-15. Maturidade e presença na baliza invulgares. EIR potencialmente significativo — nascido no segundo semestre.',
    hist:[
      {e:'2025/26',c:'FC Famalicão',esc:'Sub-15',j:12,g:null},
      {e:'2024/25',c:'FC Famalicão',esc:'Sub-13',j:16,g:null},
    ],
    palmares:[],
    zz:'https://www.zerozero.pt/jogador/duarte-almeida/930968',
  },
  jorginho: {
    nome:'Jorginho', completo:'Jorge Manuel Lourenço Ribeiro', nivel:'C',
    nascimento:'2013 · 12 anos', escalao:'Sub-13 · 1ª Divisão · 2025/26',
    clube:'Sousense', foto:'jorginho.jpg', fotoPos:'center 15%',
    posicao:'Médio', pe:'Direito',
    stats:[{n:'20',l:'Jogos'},{n:'998',l:'Min'},{n:'—',l:'Ast'}],
    tags:['Médio','Titular Indiscutível'],
    bio:'Médio versátil com formação no Gondomar SC desde Sub-9, transferido para a Sousense em 2025/26 onde se afirmou como titular indiscutível. 20 jogos e 998 minutos — dos registos mais sólidos do escalão. Irmão do também agenciado Bruninho.',
    hist:[
      {e:'2025/26',c:'Sousense',    esc:'Sub-13',j:20,g:0},
      {e:'2024/25',c:'Gondomar SC', esc:'Sub-11',j:27,g:3},
    ],
    palmares:[],
    zz:'https://www.zerozero.pt/jogador/jorge-ribeiro/1101258',
  },
  bruninho: {
    nome:'Bruninho', completo:'Bruno Jorge Lourenço Ribeiro', nivel:'C',
    nascimento:'29 Jul 2014 · 11 anos', escalao:'Sub-12 · AF Porto · 2025/26',
    clube:'EAS V.N. Gaia', foto:'bruninho.jpg', fotoPos:'center 10%',
    posicao:'Médio', pe:'Direito',
    stats:[{n:'14',l:'Jogos'},{n:'1',l:'Golo'},{n:'2',l:'Ast'}],
    tags:['Médio','EIR relevante'],
    bio:'Médio de 11 anos com formação no Gondomar SC desde Sub-9. Transferido para o EAS V.N. Gaia em 2025/26. Nascido em julho — EIR relevante. Perfil criativo com 1 golo e 2 assistências. Irmão do também agenciado Jorginho.',
    hist:[
      {e:'2025/26',c:'EAS V.N. Gaia',esc:'Sub-12',j:14,g:1},
      {e:'2024/25',c:'Gondomar SC',   esc:'Sub-11',j:27,g:3},
    ],
    palmares:[],
    zz:'https://www.zerozero.pt/jogador/bruno-ribeiro/1063304',
  },
};

const NIVEL_CORES = { A:{bg:'rgba(212,175,55,.15)',border:'var(--gold)',color:'var(--gold)'}, B:{bg:'rgba(59,130,246,.15)',border:'#60a5fa',color:'#60a5fa'}, C:{bg:'rgba(0,212,106,.15)',border:'var(--green)',color:'var(--green)'}, D:{bg:'rgba(160,160,160,.1)',border:'var(--muted)',color:'var(--muted)'} };

/* ── OPEN ATHLETE PROFILE ───────────────────────────────────── */
function abrirPerfil(id) {
  const a = ATLETAS[id]; if (!a) return;
  // nivel confidencial — não exibir publicamente
  let h = '';

  h += `<div class="p-foto" style="background-image:url('${a.foto}');background-position:${a.fotoPos};background-size:cover;">
    <div class="a-badge"><span style="width:4px;height:4px;border-radius:50%;background:var(--gold);display:inline-block;margin-right:4px;"></span>Agenciado YTB</div>
  </div>`;

  h += `<div style="margin-bottom:var(--space-5);">
    <div class="eyebrow">${a.escalao}</div>
    <div class="p-nome">${a.nome}</div>
    <div class="p-sub">${a.completo} · ${a.nascimento}</div>
  </div>`;

  h += `<div class="p-stats-grid">`;
  a.stats.forEach(s => { h += `<div class="p-stat-box"><div class="p-stat-n">${s.n}</div><div class="p-stat-l">${s.l}</div></div>`; });
  h += `</div>`;

  h += `<div class="p-bio">${a.bio}</div>`;

  if (a.hist?.length) {
    h += `<div class="eyebrow" style="margin-bottom:var(--space-3);">Historial</div>
    <div class="p-hist">`;
    a.hist.forEach(hr => {
      h += `<div class="h-row">
        <span style="color:var(--gold);font-weight:600;">${hr.e}</span>
        <span>${hr.c} · ${hr.esc}</span>
        <span style="color:var(--muted);">${hr.j ? hr.j+'j' : ''}${hr.g != null ? ' · '+hr.g+'g' : ''}</span>
      </div>`;
    });
    h += `</div>`;
  }

  if (a.palmares?.length) {
    h += `<div style="margin:var(--space-5) 0;">`;
    a.palmares.forEach(p => { h += `<div style="font-size:12px;color:var(--gold);margin-bottom:6px;display:flex;align-items:center;gap:8px;"><span>🏆</span><span>${p}</span></div>`; });
    h += `</div>`;
  }

  if (a.zz) {
    h += `<a href="${a.zz}" target="_blank" rel="noopener" style="display:inline-flex;align-items:center;gap:8px;font-size:12px;color:#3b82f6;border:1px solid rgba(59,130,246,.3);padding:9px 16px;border-radius:var(--r-md);margin-top:var(--space-4);">🔗 Ver no ZeroZero</a>`;
  }

  YTB.el('perfilContent').innerHTML = h;
  const ov = YTB.el('ovPerfil');
  ov.classList.add('open');
  document.body.style.overflow = 'hidden';
  window.scrollTo(0, 0);
}

/* ── FORM INSCRICAO ─────────────────────────────────────────── */
async function submitForm() {
  const btn  = YTB.el('btnSubmit');
  const errEl= YTB.el('fErr');
  const nome     = (YTB.el('f-nome').value||'').trim();
  const idade    = (YTB.el('f-idade').value||'').trim();
  const contacto = (YTB.el('f-contacto').value||'').trim();
  const auth = YTB.el('f-auth').checked;

  errEl.style.display = 'none';
  if (!nome || !contacto) {
    errEl.textContent = 'Preenche nome e contacto.'; errEl.style.display = 'block'; return;
  }
  if (!auth) {
    errEl.textContent = 'Aceita a autorização para continuar.'; errEl.style.display = 'block'; return;
  }

  YTB.btnLoad(btn, true, 'A enviar...');
  try {
    await db.from('sugestoes').insert([{
      nome, idade: parseInt(idade)||null,
      clube: YTB.el('f-clube').value||'',
      escalao: YTB.el('f-escalao').value||'',
      posicao: YTB.el('f-posicao').value||'',
      contacto,
      zerozero: YTB.el('f-zerozero').value||'',
      estado: 'pendente',
    }]);
    YTB.btnLoad(btn, false, '✓ Enviado!');
    btn.style.background = 'var(--green)'; btn.style.color = '#000';
    YTB.toast('Inscrição enviada! Respondemos em 48h.', 'success');
    setTimeout(() => { YTB.closeOverlay('ovInscricao'); btn.style.background=''; btn.style.color=''; btn.innerHTML='➤ Enviar Inscrição'; }, 2000);
  } catch(e) {
    YTB.btnLoad(btn, false, '➤ Enviar Inscrição');
    errEl.textContent = 'Erro ao enviar. Tenta novamente ou contacta yourtalentbase@gmail.com';
    errEl.style.display = 'block';
  }
}

/* ── DRAG SCROLL ────────────────────────────────────────────── */
function dragScroll(el) {
  if (!el) return;
  let drag = false, sx = 0, sl = 0;
  el.addEventListener('mousedown', e => { drag=true; sx=e.pageX-el.offsetLeft; sl=el.scrollLeft; el.style.cursor='grabbing'; });
  document.addEventListener('mouseup', () => { drag=false; if(el) el.style.cursor='grab'; });
  el.addEventListener('mousemove', e => { if(!drag) return; e.preventDefault(); el.scrollLeft = sl-(e.pageX-el.offsetLeft-sx)*1.5; });
}

/* ── EVENT DELEGATION ───────────────────────────────────────── */
document.addEventListener('click', function(e) {
  const t = e.target;

  // Athlete cards
  const card = t.closest('[data-atleta]');
  if (card && !t.closest('.overlay-full') && !t.closest('.overlay')) {
    abrirPerfil(card.dataset.atleta); return;
  }

  // Close perfil
  if (t.id === 'btnPerfilBack') {
    YTB.el('ovPerfil').classList.remove('open');
    document.body.style.overflow = ''; return;
  }

  // Inscricao triggers
  if (['btnHeroInscricao','btnCtaInscricao','btnCardInscricao','btnPlanoBase','btnAtletaCta'].includes(t.id)) {
    YTB.openOverlay('ovInscricao'); return;
  }

  // Scout Report
  if (['btnNavScout','btnPlanoScout'].includes(t.id)) {
    window.location.href = 'scout-report.html'; return;
  }

  if (t.id === 'btnPlanoClube') {
    window.open('https://wa.me/351913695846?text=Olá%2C%20gostaria%20de%20saber%20mais%20sobre%20o%20plano%20Clube%20Parceiro%20da%20YourTalentBase', '_blank'); return;
  }

  // Form submit
  if (t.id === 'btnSubmit') { submitForm(); return; }
});

/* ── INIT ───────────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
  dragScroll(YTB.el('atletasRow'));
});

})();
