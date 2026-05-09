// ============================================
// YTB - Supabase + Cards Rotativos + Destaque
// Cola este ficheiro em assets/js/ytb-public.js
// ============================================

const SUPABASE_URL = 'https://nhshnplaiolxwcfuijfo.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oc2hucGxhaW9seHdjZnVpamZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NDQxNTAsImV4cCI6MjA4OTQyMDE1MH0.uyZiDun8495sjnHA6Wsk-Hou-3lubbNJfQqSYbMLSek'; // Vai a Supabase > Settings > API > anon public

// Cliente Supabase (carregado via CDN no HTML)
const supa = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ============================================
// 1. CARREGAR ATLETAS PÚBLICOS
// ============================================
async function carregarAtletas() {
  try {
    const { data, error } = await supa
      .from('atletas')
      .select('*')
      .eq('visivel_publico', true)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return data || [];
  } catch (e) {
    console.error('Erro ao carregar atletas:', e);
    return [];
  }
}

// ============================================
// 2. CALCULAR IDADE
// ============================================
function calcularIdade(dataNasc) {
  if (!dataNasc) return null;
  const nasc = new Date(dataNasc);
  const hoje = new Date();
  let idade = hoje.getFullYear() - nasc.getFullYear();
  const m = hoje.getMonth() - nasc.getMonth();
  if (m < 0 || (m === 0 && hoje.getDate() < nasc.getDate())) idade--;
  return idade;
}

function formatarData(dataIso) {
  if (!dataIso) return '';
  const d = new Date(dataIso);
  const dia = String(d.getDate()).padStart(2,'0');
  const mes = String(d.getMonth()+1).padStart(2,'0');
  return `${dia}/${mes}/${d.getFullYear()}`;
}

// ============================================
// 3. RENDERIZAR CARDS ROTATIVOS
// ============================================
function renderCards(atletas) {
  const container = document.getElementById('atletas-carousel');
  if (!container) return;

  if (!atletas.length) {
    container.innerHTML = '<p style="text-align:center;color:#666;padding:40px;">Em breve, novos atletas.</p>';
    return;
  }

  container.innerHTML = atletas.map((a, i) => {
    const idade = calcularIdade(a.data_nascimento);
    const palmares = (a.palmares || []).slice(0, 2);
    const historico = (a.historico_clubes || []).slice(0, 4);
    
    return `
      <div class="atleta-slide" data-index="${i}">
        <div class="atleta-card-pub">
          <div class="atleta-foto">
            ${a.foto_url 
              ? `<img src="${a.foto_url}" alt="${a.nome_curto}" loading="lazy">`
              : `<div class="atleta-avatar">${(a.nome_curto || '?')[0]}</div>`
            }
            ${a.plano === 'ytb_acompanhado' 
              ? '<div class="atleta-badge">YTB Acompanhado</div>' 
              : ''}
          </div>
          <div class="atleta-info">
            <div class="atleta-nome-curto">${a.nome_curto || a.nome}</div>
            <div class="atleta-nome-completo">${a.nome}</div>
            <div class="atleta-meta">
              ${idade ? idade + ' anos · ' : ''}${a.posicao_principal || ''}${a.pe_dominante ? ' · ' + (a.pe_dominante === 'D' ? 'Pé Direito' : a.pe_dominante === 'E' ? 'Pé Esquerdo' : 'Ambidestro') : ''}
            </div>
            ${a.data_nascimento ? `<div class="atleta-nasc">📅 ${formatarData(a.data_nascimento)}</div>` : ''}
            <div class="atleta-clube">${a.clube_actual || ''} · ${a.escalao_actual || ''}</div>
            
            ${historico.length > 1 ? `
              <div class="atleta-historico">
                <div class="atleta-label">Histórico</div>
                <div class="atleta-clubes-lista">
                  ${historico.map(h => `<span>${h.clube}</span>`).join(' → ')}
                </div>
              </div>
            ` : ''}
            
            ${palmares.length ? `
              <div class="atleta-palmares">
                <div class="atleta-label">🏆 Palmarés</div>
                ${palmares.map(p => `
                  <div class="palmares-item">
                    <strong>${p.titulo}</strong>${p.ano ? ' · ' + p.ano : ''}
                  </div>
                `).join('')}
              </div>
            ` : ''}
          </div>
        </div>
      </div>
    `;
  }).join('');

  // Marca o primeiro como activo
  const slides = container.querySelectorAll('.atleta-slide');
  if (slides.length) slides[0].classList.add('active');

  // Inicia rotação
  iniciarRotacao(slides);

  // Render dots
  renderDots(slides.length);
}

// ============================================
// 4. ROTAÇÃO AUTOMÁTICA
// ============================================
let rotacaoTimer = null;
let rotacaoIndex = 0;
let rotacaoPausada = false;

function iniciarRotacao(slides) {
  if (rotacaoTimer) clearInterval(rotacaoTimer);
  if (slides.length < 2) return;

  rotacaoTimer = setInterval(() => {
    if (rotacaoPausada) return;
    proximoSlide(slides);
  }, 5000);
}

function proximoSlide(slides) {
  slides[rotacaoIndex].classList.remove('active');
  rotacaoIndex = (rotacaoIndex + 1) % slides.length;
  slides[rotacaoIndex].classList.add('active');
  atualizarDots();
}

function irParaSlide(idx, slides) {
  slides[rotacaoIndex].classList.remove('active');
  rotacaoIndex = idx;
  slides[rotacaoIndex].classList.add('active');
  atualizarDots();
}

function renderDots(total) {
  const dots = document.getElementById('atletas-dots');
  if (!dots) return;
  dots.innerHTML = Array.from({length: total}).map((_, i) => 
    `<button class="dot ${i === 0 ? 'active' : ''}" data-i="${i}" aria-label="Ver atleta ${i+1}"></button>`
  ).join('');

  const slides = document.querySelectorAll('.atleta-slide');
  dots.querySelectorAll('.dot').forEach(d => {
    d.addEventListener('click', () => irParaSlide(parseInt(d.dataset.i), slides));
  });
}

function atualizarDots() {
  const dots = document.getElementById('atletas-dots');
  if (!dots) return;
  dots.querySelectorAll('.dot').forEach((d, i) => {
    d.classList.toggle('active', i === rotacaoIndex);
  });
}

// Pausar em hover/touch
document.addEventListener('DOMContentLoaded', () => {
  const carousel = document.getElementById('atletas-carousel');
  if (carousel) {
    carousel.addEventListener('mouseenter', () => rotacaoPausada = true);
    carousel.addEventListener('mouseleave', () => rotacaoPausada = false);
    let touchTimer = null;
    carousel.addEventListener('touchstart', () => {
      rotacaoPausada = true;
      if (touchTimer) clearTimeout(touchTimer);
      touchTimer = setTimeout(() => { rotacaoPausada = false; }, 4000);
    }, {passive: true});
  }
});

// ============================================
// 5. ATLETA EM DESTAQUE
// ============================================
async function carregarDestaque() {
  // Por agora hardcoded - Du com vídeo
  // No futuro vem de uma tabela 'destaques' no Supabase
  const destaque = {
    nome: 'Duarte Almeida',
    nome_curto: 'Du',
    posicao: 'Guarda-Redes',
    clube: 'FC Famalicão · Sub-15',
    descricao: 'Esta semana o Du fez duas defesas que valeram pontos à equipa. 12 anos a jogar dois escalões acima.',
    video1: '/videos/du-defesa-1.mp4',
    video2: '/videos/du-defesa-2.mp4',
    foto_fallback: '/duarte.jpg'
  };

  const container = document.getElementById('atleta-destaque');
  if (!container) return;

  container.innerHTML = `
    <div class="destaque-eyebrow">★ Atleta em Destaque</div>
    <div class="destaque-grid">
      <div class="destaque-video-wrap">
        <video 
          id="destaque-video"
          autoplay muted loop playsinline
          poster="${destaque.foto_fallback}"
          preload="metadata">
          <source src="${destaque.video1}" type="video/mp4">
        </video>
        <div class="video-controls">
          <button class="vid-btn active" data-vid="1">Defesa 1</button>
          <button class="vid-btn" data-vid="2">Defesa 2</button>
        </div>
      </div>
      <div class="destaque-info">
        <div class="destaque-nome">${destaque.nome_curto}</div>
        <div class="destaque-completo">${destaque.nome}</div>
        <div class="destaque-meta">${destaque.posicao} · ${destaque.clube}</div>
        <div class="destaque-quote">"${destaque.descricao}"</div>
      </div>
    </div>
  `;

  // Botões de troca de vídeo
  const video = document.getElementById('destaque-video');
  const source = video?.querySelector('source');
  document.querySelectorAll('.vid-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.vid-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const vid = btn.dataset.vid === '1' ? destaque.video1 : destaque.video2;
      source.src = vid;
      video.load();
      video.play();
    });
  });
}

// ============================================
// INIT
// ============================================
document.addEventListener('DOMContentLoaded', async () => {
  const atletas = await carregarAtletas();
  renderCards(atletas);
  carregarDestaque();
});
