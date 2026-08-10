// ═══════════════════════════════════════════════════════
// YTB ELITE COACH · DATA
// Coordenadas: SVG 500×740 (vertical, ataque para CIMA)
// ═══════════════════════════════════════════════════════

// Linguagem comum de desenvolvimento (mesma dos 5 domínios do pentagrama
// em passaporte.html: Técnica/Decisão/Tática/Físico/Mental). Cada
// "debilidade" dos cenários já é um conceito rico e específico (usado
// também para recomendar cenários ao atleta) — este mapeamento não a
// substitui, só traduz para o vocabulário comum, para que um resultado
// do Elite Coach possa um dia contar como evidência no mesmo domínio
// que uma avaliação do treinador ou um treino registado pela família.
var DEBILIDADE_PARA_DOMINIO={
  '1×1 defensivo':'tecnica', 'Controlo do pé fraco':'tecnica', 'Primeiro toque sob pressão':'tecnica',
  'Proteção de bola':'tecnica', 'Timing de remate':'tecnica',
  'Controlo + decisão':'decisao', 'Decisão ofensiva':'decisao', 'Decisão sair/ficar':'decisao',
  'Decisão sob pressão':'decisao', 'Leitura de jogo':'decisao', 'Qualidade de decisão':'decisao',
  'Tomada de decisão':'decisao',
  'Inteligência sem bola':'tatica', 'Leitura da cobertura defensiva':'tatica', 'Posicionamento':'tatica',
  'Reação à perda':'tatica', 'Timing de movimento':'tatica',
  'Concentração após erro':'mental', 'Concentração':'mental', 'Controlo emocional':'mental',
  'Reação emocional à substituição':'mental', 'Reação à adversidade':'mental'
};

// ─── 10 CENÁRIOS DE DECISÃO ──────────────────────────────
const CENARIOS = [
  {
    id: 'C01', titulo: 'Receber entre linhas pressionado', posicao: 'Médio',
    debilidade: 'Decisão sob pressão', icon: '🧠', cor: '#D4AF37', nivel: 'Sub-13+',
    situacao: 'Recebes de costas para a baliza adversária. Adversário a marcar de perto. Médio companheiro aproxima-se.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 380, team: 'us', label: 'TU', highlight: true }, adv: { x: 250, y: 350, team: 'them' }, apoio: { x: 180, y: 480, team: 'us', label: 'Méd' }, lateral: { x: 100, y: 350, team: 'us', label: 'Lat' }, avante: { x: 250, y: 200, team: 'us', label: 'Av' } }, ball: { owner: 'meu' }, indica: 'Bola chega-te. Adversário nas costas.' },
      { t: 1500, players: { meu: { x: 250, y: 380, team: 'us', highlight: true }, adv: { x: 250, y: 360, team: 'them' }, apoio: { x: 200, y: 460, team: 'us' }, lateral: { x: 100, y: 350, team: 'us' }, avante: { x: 250, y: 200, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 380, team: 'us', highlight: true }, adv: { x: 250, y: 360, team: 'them' }, apoio: { x: 200, y: 460, team: 'us' }, lateral: { x: 100, y: 350, team: 'us' }, avante: { x: 250, y: 200, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Viras e arriscas', certa: false, feedback: 'Viraste sob pressão. Perdeste tempo, espaço e bola.', consequencia: 'perda' },
      { id: 'B', texto: 'Jogo de primeira no apoio', certa: true, feedback: 'De primeira, mantiveste a posse. Triângulo limpo.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Protejo e atraso', certa: false, feedback: 'Atrasaste a equipa. Defesa adversária recompôs-se.', consequencia: 'neutro' }
    ],
    treino: ['Passe de 1 toque', 'Decisão em 1 segundo', 'Scanning antes de receber'],
    dica: 'Olha para os lados ANTES de a bola chegar. Decisão tem de estar tomada.'
  },
  {
    id: 'C02', titulo: 'Saída de bola com pressão alta', posicao: 'Central / GR',
    debilidade: 'Leitura de jogo', icon: '⚽', cor: '#4A9FE8', nivel: 'Sub-13+',
    situacao: 'GR com bola. Centrais abertos. Adversário pressiona alto com 2 atacantes.',
    duracao: 4500,
    frames: [
      { t: 0, players: { gr: { x: 250, y: 680, team: 'us', label: 'GR', highlight: true }, dc1: { x: 180, y: 600, team: 'us', label: 'DC' }, dc2: { x: 320, y: 600, team: 'us', label: 'DC' }, latL: { x: 80, y: 530, team: 'us', label: 'Lat' }, latR: { x: 420, y: 530, team: 'us', label: 'Lat' }, adv1: { x: 200, y: 540, team: 'them' }, adv2: { x: 300, y: 540, team: 'them' }, med: { x: 250, y: 470, team: 'us', label: 'Méd' } }, ball: { owner: 'gr' }, indica: 'GR com bola. 2 atacantes pressionam.' },
      { t: 1500, players: { gr: { x: 250, y: 680, team: 'us', highlight: true }, dc1: { x: 180, y: 600, team: 'us' }, dc2: { x: 320, y: 600, team: 'us' }, latL: { x: 80, y: 540, team: 'us' }, latR: { x: 420, y: 540, team: 'us' }, adv1: { x: 210, y: 580, team: 'them' }, adv2: { x: 290, y: 580, team: 'them' }, med: { x: 250, y: 460, team: 'us' } }, ball: { owner: 'gr' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { gr: { x: 250, y: 680, team: 'us', highlight: true }, dc1: { x: 180, y: 600, team: 'us' }, dc2: { x: 320, y: 600, team: 'us' }, latL: { x: 80, y: 540, team: 'us' }, latR: { x: 420, y: 540, team: 'us' }, adv1: { x: 210, y: 580, team: 'them' }, adv2: { x: 290, y: 580, team: 'them' }, med: { x: 250, y: 460, team: 'us' } }, ball: { owner: 'gr' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Insistir curto entre centrais', certa: false, feedback: 'Forçaste curto sem linha. Adversário recupera próximo da baliza.', consequencia: 'perda' },
      { id: 'B', texto: 'Bater longo para o avante', certa: false, feedback: 'Bola longa sem critério. Cedeste posse.', consequencia: 'neutro' },
      { id: 'C', texto: 'Abrir no lateral livre', certa: true, feedback: 'Lateral livre. Saída limpa pelo corredor.', consequencia: 'sucesso' }
    ],
    treino: ['Passe sob pressão', 'Orientação corporal'],
    dica: 'Quando pressionado, procura o jogador MAIS LIVRE.'
  },
  {
    id: 'C03', titulo: 'Extremo em 1×1 na ala', posicao: 'Extremo',
    debilidade: 'Decisão ofensiva', icon: '🏃', cor: '#E05050', nivel: 'Sub-12+',
    situacao: 'Recebes na ala isolado. Lateral adversário pela frente.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 80, y: 350, team: 'us', label: 'TU', highlight: true }, adv: { x: 100, y: 280, team: 'them' }, avante: { x: 250, y: 200, team: 'us', label: 'Av' }, med: { x: 250, y: 400, team: 'us', label: 'Méd' } }, ball: { owner: 'meu' }, indica: 'Recebes na ala. 1×1 com lateral.' },
      { t: 1500, players: { meu: { x: 80, y: 320, team: 'us', highlight: true }, adv: { x: 100, y: 280, team: 'them' }, avante: { x: 240, y: 180, team: 'us' }, med: { x: 250, y: 380, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 80, y: 320, team: 'us', highlight: true }, adv: { x: 100, y: 280, team: 'them' }, avante: { x: 240, y: 180, team: 'us' }, med: { x: 250, y: 380, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Vou para cima do defesa', certa: true, feedback: 'Geras desequilíbrio. Defesa tem de ajustar.', consequencia: 'sucesso' },
      { id: 'B', texto: 'Cruzar logo', certa: false, feedback: 'Sem desequilíbrio. Cruzamento previsível.', consequencia: 'neutro' },
      { id: 'C', texto: 'Atrasar para o médio', certa: false, feedback: 'Perdeste vantagem do isolamento.', consequencia: 'neutro' }
    ],
    treino: ['Drible em espaço curto', 'Explosão no primeiro passo'],
    dica: 'Isolado na ala? Vai para cima. É o teu momento.'
  },
  {
    id: 'C04', titulo: 'Finalização à entrada da área', posicao: 'Avançado',
    debilidade: 'Timing de remate', icon: '🎯', cor: '#4AE87A', nivel: 'Sub-12+',
    situacao: 'Bola chega à entrada da área. Defesa próxima. Espaço pequeno.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 200, team: 'us', label: 'TU', highlight: true }, adv: { x: 220, y: 240, team: 'them' }, passador: { x: 350, y: 280, team: 'us', label: 'Apoio' } }, ball: { owner: 'passador' }, indica: 'Apoio com bola. Vai chegar-te.' },
      { t: 1200, players: { meu: { x: 250, y: 200, team: 'us', highlight: true }, adv: { x: 220, y: 230, team: 'them' }, passador: { x: 350, y: 280, team: 'us' } }, ball: { x: 300, y: 245 }, indica: 'Bola a chegar...' },
      { t: 2200, players: { meu: { x: 250, y: 200, team: 'us', highlight: true }, adv: { x: 230, y: 220, team: 'them' }, passador: { x: 350, y: 280, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 200, team: 'us', highlight: true }, adv: { x: 230, y: 220, team: 'them' }, passador: { x: 350, y: 280, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Rematar de primeira', certa: true, feedback: 'Surpreendeste o GR. Perigo real.', consequencia: 'sucesso' },
      { id: 'B', texto: 'Dominar e ajeitar', certa: false, feedback: 'Defesa fechou o ângulo. Remate bloqueado.', consequencia: 'neutro' },
      { id: 'C', texto: 'Passar para apoio', certa: false, feedback: 'Bola distante da baliza. Oportunidade desperdiçada.', consequencia: 'neutro' }
    ],
    treino: ['Remate de primeira', 'Coordenação ao remate'],
    dica: 'Na área, primeira intenção é sempre rematar.'
  },
  {
    id: 'C05', titulo: 'Transição defensiva', posicao: 'Todos',
    debilidade: 'Reação à perda', icon: '🔁', cor: '#E05050', nivel: 'Sub-13+',
    situacao: 'Acabaste de perder a bola no meio-campo. Adversário tem 2 segundos para organizar.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 380, team: 'us', label: 'TU', highlight: true }, adv1: { x: 240, y: 360, team: 'them' }, adv2: { x: 320, y: 320, team: 'them' }, adv3: { x: 180, y: 280, team: 'them' }, meu2: { x: 350, y: 450, team: 'us' }, meu3: { x: 150, y: 450, team: 'us' } }, ball: { owner: 'adv1' }, indica: 'Acabaste de perder a bola.' },
      { t: 1500, players: { meu: { x: 250, y: 380, team: 'us', highlight: true }, adv1: { x: 240, y: 340, team: 'them' }, adv2: { x: 320, y: 280, team: 'them' }, adv3: { x: 180, y: 250, team: 'them' }, meu2: { x: 350, y: 450, team: 'us' }, meu3: { x: 150, y: 450, team: 'us' } }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 380, team: 'us', highlight: true }, adv1: { x: 240, y: 340, team: 'them' }, adv2: { x: 320, y: 280, team: 'them' }, adv3: { x: 180, y: 250, team: 'them' }, meu2: { x: 350, y: 450, team: 'us' }, meu3: { x: 150, y: 450, team: 'us' } }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Pressionar imediatamente', certa: true, feedback: 'Travaste o contra-ataque. Recuperaste em zona alta.', consequencia: 'sucesso' },
      { id: 'B', texto: 'Recuar para defesa', certa: false, feedback: 'Deste tempo ao adversário. Contra-ataque chega.', consequencia: 'perda' },
      { id: 'C', texto: 'Ficar parado a olhar', certa: false, feedback: 'Adversário avançou 30m sem oposição.', consequencia: 'perda' }
    ],
    treino: ['Reação rápida pós-perda', 'Sprint curto'],
    dica: 'Os 5 segundos após a perda são DECISIVOS.'
  },
  {
    id: 'C06', titulo: 'Defesa em inferioridade (2v1)', posicao: 'Defesa',
    debilidade: 'Posicionamento', icon: '🧱', cor: '#4A9FE8', nivel: 'Sub-12+',
    situacao: 'Sozinho contra 2 atacantes. Eles aproximam-se da tua área.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 480, team: 'us', label: 'TU', highlight: true }, adv1: { x: 220, y: 380, team: 'them' }, adv2: { x: 320, y: 400, team: 'them' } }, ball: { owner: 'adv1' }, indica: '2 contra 1. Eles chegam.' },
      { t: 1500, players: { meu: { x: 250, y: 480, team: 'us', highlight: true }, adv1: { x: 230, y: 410, team: 'them' }, adv2: { x: 330, y: 420, team: 'them' } }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 480, team: 'us', highlight: true }, adv1: { x: 230, y: 410, team: 'them' }, adv2: { x: 330, y: 420, team: 'them' } }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Atacar o portador', certa: false, feedback: 'Foste ao portador. Passou para o livre. Golo.', consequencia: 'perda' },
      { id: 'B', texto: 'Fechar a linha de passe', certa: true, feedback: 'Forçaste o portador a decidir sozinho. Ganhaste tempo.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Recuar para a linha', certa: false, feedback: 'Atacantes ganharam espaço. Situação piorou.', consequencia: 'neutro' }
    ],
    treino: ['Leitura defensiva', 'Posicionamento entre atacantes'],
    dica: 'Em 2v1, missão é GANHAR TEMPO. Não roubar a bola.'
  },
  {
    id: 'C07', titulo: 'Médio a sair de pressão', posicao: 'Médio',
    debilidade: 'Controlo + decisão', icon: '🔄', cor: '#D4AF37', nivel: 'Sub-13+',
    situacao: 'Recebes no meio-campo com adversário a 2m.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 400, team: 'us', label: 'TU', highlight: true }, adv: { x: 250, y: 370, team: 'them' }, passador: { x: 250, y: 550, team: 'us', label: 'DC' }, apoio: { x: 380, y: 380, team: 'us', label: 'Apoio' }, avante: { x: 250, y: 200, team: 'us', label: 'Av' } }, ball: { owner: 'passador' }, indica: 'Bola a chegar do central.' },
      { t: 1200, players: { meu: { x: 250, y: 400, team: 'us', highlight: true }, adv: { x: 250, y: 370, team: 'them' }, passador: { x: 250, y: 550, team: 'us' }, apoio: { x: 380, y: 380, team: 'us' }, avante: { x: 250, y: 200, team: 'us' } }, ball: { x: 250, y: 470 }, indica: 'Adversário a chegar...' },
      { t: 2200, players: { meu: { x: 250, y: 400, team: 'us', highlight: true }, adv: { x: 250, y: 370, team: 'them' }, passador: { x: 250, y: 550, team: 'us' }, apoio: { x: 380, y: 380, team: 'us' }, avante: { x: 250, y: 200, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 400, team: 'us', highlight: true }, adv: { x: 250, y: 370, team: 'them' }, passador: { x: 250, y: 550, team: 'us' }, apoio: { x: 380, y: 380, team: 'us' }, avante: { x: 250, y: 200, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Rodar e tentar virar', certa: false, feedback: 'Adversário antecipou e roubou.', consequencia: 'perda' },
      { id: 'B', texto: 'Toque de primeira no apoio', certa: true, feedback: 'Mantiveste posse. Equipa progrediu.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Tentar conduzir', certa: false, feedback: 'Perdeste bola após 2 metros.', consequencia: 'perda' }
    ],
    treino: ['Controlo orientado', 'Jogo a 2 toques'],
    dica: 'Pressionado? PRIMEIRO TOQUE SAFE.'
  },
  {
    id: 'C08', titulo: 'Cruzamento na ala', posicao: 'Extremo / Lateral',
    debilidade: 'Qualidade de decisão', icon: '📐', cor: '#4A9FE8', nivel: 'Sub-13+',
    situacao: 'Chegas à linha de fundo com bola. Vês a área. Tens de decidir.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 80, y: 220, team: 'us', label: 'TU', highlight: true }, adv: { x: 130, y: 230, team: 'them' }, av1: { x: 220, y: 150, team: 'us', label: 'Av' }, av2: { x: 290, y: 100, team: 'us', label: 'Av' }, med: { x: 280, y: 280, team: 'us', label: 'Méd' } }, ball: { owner: 'meu' }, indica: 'Tens bola na linha de fundo.' },
      { t: 1500, players: { meu: { x: 80, y: 220, team: 'us', highlight: true }, adv: { x: 130, y: 230, team: 'them' }, av1: { x: 230, y: 140, team: 'us' }, av2: { x: 300, y: 95, team: 'us' }, med: { x: 290, y: 270, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 80, y: 220, team: 'us', highlight: true }, adv: { x: 130, y: 230, team: 'them' }, av1: { x: 230, y: 140, team: 'us' }, av2: { x: 300, y: 95, team: 'us' }, med: { x: 290, y: 270, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Cruzar imediatamente', certa: false, feedback: 'Sem alvo definido. Defesa afastou.', consequencia: 'neutro' },
      { id: 'B', texto: 'Esperar apoio chegar', certa: true, feedback: 'Cruzamento com 2 alvos. Probabilidade de golo subiu 3x.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Cortar para dentro', certa: false, feedback: 'Defesa organizada. Sem ângulo.', consequencia: 'neutro' }
    ],
    treino: ['Cruzamento com alvo', 'Leitura ofensiva'],
    dica: 'Cruzar não é sempre primeira opção. Espera 1s.'
  },
  {
    id: 'C09', titulo: 'Desmarcação em profundidade', posicao: 'Avançado',
    debilidade: 'Timing de movimento', icon: '🚀', cor: '#4AE87A', nivel: 'Sub-12+',
    situacao: 'Defesa adversária subida. Espaço nas costas. Médio com bola.',
    duracao: 5000,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 280, team: 'us', label: 'TU', highlight: true }, passador: { x: 250, y: 480, team: 'us', label: 'Méd' }, dc1: { x: 200, y: 200, team: 'them' }, dc2: { x: 300, y: 200, team: 'them' } }, ball: { owner: 'passador' }, indica: 'Defesa subida. Espaço nas costas.' },
      { t: 1800, players: { meu: { x: 250, y: 250, team: 'us', highlight: true }, passador: { x: 250, y: 470, team: 'us' }, dc1: { x: 200, y: 200, team: 'them' }, dc2: { x: 300, y: 200, team: 'them' } }, ball: { owner: 'passador' }, indica: 'O QUE FAZES?' },
      { t: 5000, players: { meu: { x: 250, y: 250, team: 'us', highlight: true }, passador: { x: 250, y: 470, team: 'us' }, dc1: { x: 200, y: 200, team: 'them' }, dc2: { x: 300, y: 200, team: 'them' } }, ball: { owner: 'passador' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Arrancar imediatamente', certa: false, feedback: 'Cedo demais. Fora-de-jogo.', consequencia: 'neutro' },
      { id: 'B', texto: 'Esperar momento certo', certa: true, feedback: 'Timing perfeito. Sincronizaste com o passe.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Não fazer movimento', certa: false, feedback: 'Médio teve de jogar atrás. Oportunidade desperdiçada.', consequencia: 'neutro' }
    ],
    treino: ['Timing de corrida', 'Leitura linha defensiva'],
    dica: 'Desmarcação = sincronização. Move quando o passe sai.'
  },
  {
    id: 'C10', titulo: 'Apoio ao portador', posicao: 'Todos',
    debilidade: 'Inteligência sem bola', icon: '🧭', cor: '#D4AF37', nivel: 'Sub-12+',
    situacao: 'Companheiro tem bola, está pressionado. Tu estás a 15m.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 380, y: 400, team: 'us', label: 'TU', highlight: true }, portador: { x: 250, y: 400, team: 'us', label: 'Colega' }, adv1: { x: 250, y: 370, team: 'them' }, adv2: { x: 320, y: 350, team: 'them' } }, ball: { owner: 'portador' }, indica: 'Colega com bola, pressionado.' },
      { t: 1500, players: { meu: { x: 380, y: 400, team: 'us', highlight: true }, portador: { x: 250, y: 400, team: 'us' }, adv1: { x: 250, y: 380, team: 'them' }, adv2: { x: 320, y: 360, team: 'them' } }, ball: { owner: 'portador' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 380, y: 400, team: 'us', highlight: true }, portador: { x: 250, y: 400, team: 'us' }, adv1: { x: 250, y: 380, team: 'them' }, adv2: { x: 320, y: 360, team: 'them' } }, ball: { owner: 'portador' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Aproximar e dar linha', certa: true, feedback: 'Tabelaste com colega. Saída limpa da pressão.', consequencia: 'sucesso' },
      { id: 'B', texto: 'Ficar parado', certa: false, feedback: 'Colega isolado. Bola perdida.', consequencia: 'perda' },
      { id: 'C', texto: 'Afastar para profundidade', certa: false, feedback: 'Linha de passe muito longa. Interceptado.', consequencia: 'perda' }
    ],
    treino: ['Movimentação sem bola', 'Apoio curto (5-10m)'],
    dica: 'Companheiro pressionado? APROXIMA.'
  },
  {
    id: 'C11', titulo: 'GR · Cruzamento na tua área', posicao: 'Guarda-Redes',
    debilidade: 'Decisão sair/ficar', icon: '🧤', cor: '#4A9FE8', nivel: 'Sub-11+',
    situacao: 'Cruzamento tenso da direita. Bola vai cair à zona do penálti. Tens um central na disputa e um avançado adversário a atacar a bola.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 80, team: 'us', label: 'TU', highlight: true }, central: { x: 220, y: 160, team: 'us', label: 'Cent' }, avanc: { x: 260, y: 170, team: 'them' }, cruzador: { x: 420, y: 220, team: 'them' } }, ball: { owner: 'cruzador' }, indica: 'Cruzamento a sair da direita.' },
      { t: 1500, players: { meu: { x: 250, y: 80, team: 'us', highlight: true }, central: { x: 230, y: 150, team: 'us' }, avanc: { x: 250, y: 155, team: 'them' }, cruzador: { x: 420, y: 220, team: 'them' } }, ball: { x: 330, y: 180 }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 80, team: 'us', highlight: true }, central: { x: 230, y: 150, team: 'us' }, avanc: { x: 250, y: 155, team: 'them' }, cruzador: { x: 420, y: 220, team: 'them' } }, ball: { x: 300, y: 165 }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Saio a soco com decisão', certa: true, feedback: 'Saída forte, bola afastada. Comunicaste "MINHA!" e a defesa confiou.', consequencia: 'sucesso' },
      { id: 'B', texto: 'Fico na linha à espera', certa: false, feedback: 'Bola caiu na zona morta. Avançado cabeceou sozinho.', consequencia: 'perda' },
      { id: 'C', texto: 'Saio mas hesito a meio', certa: false, feedback: 'O pior dos dois mundos: nem na baliza nem na bola.', consequencia: 'perda' }
    ],
    treino: ['Saídas a cruzamento com tráfego', 'Comunicação em voz alta', 'Leitura da trajetória cedo'],
    dica: 'Decide CEDO e grita a decisão. Sair a meio-gás é pior do que ficar.'
  },
  {
    id: 'C12', titulo: 'GR · Construção sob pressão', posicao: 'Guarda-Redes',
    debilidade: 'Decisão sob pressão', icon: '🧤', cor: '#4A9FE8', nivel: 'Sub-13+',
    situacao: 'Recebes atrasado do central. Avançado adversário pressiona-te em curva, a fechar o passe de volta. Lateral esquerdo livre na ala. Médio pede entre linhas.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 90, team: 'us', label: 'TU', highlight: true }, central: { x: 330, y: 170, team: 'us', label: 'Cent' }, press: { x: 300, y: 140, team: 'them' }, lateral: { x: 90, y: 230, team: 'us', label: 'Lat' }, medio: { x: 230, y: 280, team: 'us', label: 'Méd' } }, ball: { owner: 'meu' }, indica: 'Avançado vem em curva sobre ti.' },
      { t: 1500, players: { meu: { x: 250, y: 90, team: 'us', highlight: true }, central: { x: 330, y: 170, team: 'us' }, press: { x: 280, y: 120, team: 'them' }, lateral: { x: 90, y: 230, team: 'us' }, medio: { x: 230, y: 280, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 90, team: 'us', highlight: true }, central: { x: 330, y: 170, team: 'us' }, press: { x: 280, y: 120, team: 'them' }, lateral: { x: 90, y: 230, team: 'us' }, medio: { x: 230, y: 280, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Devolver ao central', certa: false, feedback: 'O avançado fechava exatamente essa linha. Quase autogolo.', consequencia: 'perda' },
      { id: 'B', texto: 'Abrir no lateral livre', certa: true, feedback: 'Leste a curva da pressão e saíste pelo lado livre. Construção limpa.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Pontapé longo imediato', certa: false, feedback: 'Aliviou o perigo mas devolveu a posse. Solução de emergência, não de equipa.', consequencia: 'neutro' }
    ],
    treino: ['Receção orientada de GR', 'Leitura da curva de pressão', 'Passe tenso de primeira'],
    dica: 'A curva da pressão DIZ-TE o lado livre. Lê o corpo do avançado, não a bola.'
  },
  {
    id: 'C13', titulo: 'Lateral · 1×1 contra extremo rápido', posicao: 'Defesa',
    debilidade: '1×1 defensivo', icon: '🛡️', cor: '#C0C0C0', nivel: 'Sub-12+',
    situacao: 'Extremo adversário recebe isolado contra ti na ala. É mais rápido que tu. Não tens cobertura imediata — o central está longe.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 120, y: 250, team: 'us', label: 'TU', highlight: true }, extremo: { x: 110, y: 330, team: 'them', label: 'Ext' }, central: { x: 280, y: 200, team: 'us', label: 'Cent' } }, ball: { owner: 'extremo' }, indica: 'Extremo isolado contra ti.' },
      { t: 1500, players: { meu: { x: 120, y: 250, team: 'us', highlight: true }, extremo: { x: 115, y: 310, team: 'them' }, central: { x: 270, y: 210, team: 'us' } }, ball: { owner: 'extremo' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 120, y: 250, team: 'us', highlight: true }, extremo: { x: 115, y: 310, team: 'them' }, central: { x: 270, y: 210, team: 'us' } }, ball: { owner: 'extremo' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Atacar a bola já', certa: false, feedback: 'Entrada precipitada contra um mais rápido. Passou por ti — autoestrada para a baliza.', consequencia: 'perda' },
      { id: 'B', texto: 'Temporizar e encaminhar para a linha', certa: true, feedback: 'Recuaste em diagonal, deste tempo à cobertura e fechaste o interior. O extremo ficou sem espaço útil.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Recuar até à área', certa: false, feedback: 'Recuaste demasiado. Ofereceste 20 metros e o cruzamento saiu confortável.', consequencia: 'neutro' }
    ],
    treino: ['Temporização defensiva 1v1', 'Orientação corporal (fechar interior)', 'Recuperação em diagonal'],
    dica: 'Contra um mais rápido, o teu aliado é o TEMPO. Não ganhas a corrida — ganhas o ângulo.'
  },
  {
    id: 'C14', titulo: 'Central · Profundidade nas costas', posicao: 'Defesa',
    debilidade: 'Posicionamento', icon: '🛡️', cor: '#C0C0C0', nivel: 'Sub-13+',
    situacao: 'A tua equipa está subida. O médio adversário tem a bola sem pressão e o avançado deles arranca para as tuas costas.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 220, y: 230, team: 'us', label: 'TU', highlight: true }, par: { x: 320, y: 230, team: 'us', label: 'Cent2' }, avanc: { x: 250, y: 250, team: 'them', label: 'Av' }, medio: { x: 250, y: 400, team: 'them' } }, ball: { owner: 'medio' }, indica: 'Médio deles com bola, sem pressão.' },
      { t: 1500, players: { meu: { x: 220, y: 230, team: 'us', highlight: true }, par: { x: 320, y: 230, team: 'us' }, avanc: { x: 240, y: 215, team: 'them' }, medio: { x: 250, y: 400, team: 'them' } }, ball: { owner: 'medio' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 220, y: 230, team: 'us', highlight: true }, par: { x: 320, y: 230, team: 'us' }, avanc: { x: 240, y: 215, team: 'them' }, medio: { x: 250, y: 400, team: 'them' } }, ball: { owner: 'medio' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Cair uns metros antes do passe', certa: true, feedback: 'Bola sem pressão = linha desce. Mataste a profundidade antes de ela existir.', consequencia: 'sucesso' },
      { id: 'B', texto: 'Manter a linha e jogar ao fora-de-jogo', certa: false, feedback: 'Sem pressão na bola, o passe sai medido. Fora-de-jogo falhou por meio metro.', consequencia: 'perda' },
      { id: 'C', texto: 'Colar ao avançado', certa: false, feedback: 'Ele prendeu-te, rodou no arranque e ganhou-te as costas.', consequencia: 'perda' }
    ],
    treino: ['Regra bola pressionada/não pressionada', 'Basculação da linha defensiva', 'Leitura do passe longo'],
    dica: 'Bola SEM pressão → a linha DESCE. Bola pressionada → a linha sobe. É a regra de ouro.'
  },
  {
    id: 'C15', titulo: 'Falhaste um golo cantado. E agora?', posicao: 'Todos',
    debilidade: 'Reação à adversidade', icon: '🧠', cor: '#A78BFA', nivel: 'Sub-9+',
    situacao: 'Acabaste de falhar uma ocasião flagrante. Ouves o banco e alguns colegas reagirem. O jogo recomeça já — a equipa adversária vai repor de baliza.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 160, team: 'us', label: 'TU', highlight: true }, gr: { x: 250, y: 70, team: 'them', label: 'GR' }, colega: { x: 150, y: 240, team: 'us' } }, ball: { owner: 'gr' }, indica: 'A bola saiu por cima. Falhaste.' },
      { t: 1500, players: { meu: { x: 250, y: 160, team: 'us', highlight: true }, gr: { x: 250, y: 70, team: 'them' }, colega: { x: 150, y: 240, team: 'us' } }, ball: { owner: 'gr' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 160, team: 'us', highlight: true }, gr: { x: 250, y: 70, team: 'them' }, colega: { x: 150, y: 240, team: 'us' } }, ball: { owner: 'gr' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Baixar a cabeça e evitar a bola uns minutos', certa: false, feedback: 'Desapareceste do jogo 10 minutos. A equipa jogou com menos um.', consequencia: 'perda' },
      { id: 'B', texto: 'Reset: próxima ação, pressionar a reposição', certa: true, feedback: 'A melhor resposta a um falhanço é a ação seguinte. Pressionaste, recuperaste e voltaste ao jogo.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Discutir com quem comentou', certa: false, feedback: 'Perdeste o foco e ganhaste um conflito. O jogo continuou sem ti.', consequencia: 'perda' }
    ],
    treino: ['Rotina de reset (respirar + próxima tarefa)', 'Treinar finalização com consequência', 'Linguagem corporal pós-erro'],
    dica: 'Os melhores falham MUITO — e a resposta deles mede-se na jogada seguinte, não no falhanço.'
  },
  {
    id: 'C16', titulo: 'Adversário provoca-te depois da falta', posicao: 'Todos',
    debilidade: 'Controlo emocional', icon: '🧠', cor: '#A78BFA', nivel: 'Sub-11+',
    situacao: 'Sofreste uma falta dura. O árbitro marcou, mas o adversário levanta-se e provoca-te à frente de todos. Sentes o sangue a subir.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 300, team: 'us', label: 'TU', highlight: true }, adv: { x: 270, y: 290, team: 'them', label: 'Adv' }, arb: { x: 320, y: 330, team: 'us', label: 'Árb' } }, ball: { x: 250, y: 310 }, indica: 'Falta sofrida. Ele provoca-te.' },
      { t: 1500, players: { meu: { x: 250, y: 300, team: 'us', highlight: true }, adv: { x: 268, y: 292, team: 'them' }, arb: { x: 315, y: 325, team: 'us' } }, ball: { x: 250, y: 310 }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 300, team: 'us', highlight: true }, adv: { x: 268, y: 292, team: 'them' }, arb: { x: 315, y: 325, team: 'us' } }, ball: { x: 250, y: 310 }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Responder à letra', certa: false, feedback: 'O árbitro só viu a TUA reação. Amarelo para ti — exatamente o que ele queria.', consequencia: 'perda' },
      { id: 'B', texto: 'Levantar, pegar na bola, marcar rápido', certa: true, feedback: 'Resposta de jogador inteligente: usaste a provocação como combustível e a falta como vantagem.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Ficar no chão a pedir cartão', certa: false, feedback: 'Teatro não joga. Enquanto reclamavas, a tua equipa perdeu a vantagem da reposição rápida.', consequencia: 'neutro' }
    ],
    treino: ['Gatilhos emocionais e resposta-padrão', 'Reposição rápida após falta', 'Conversa com treinador sobre provocações'],
    dica: 'Quem te provoca quer ALUGAR a tua cabeça de graça. Não assines o contrato.'
  },
  {
    id: 'C17', titulo: 'Canto contra · A tua marcação', posicao: 'Todos',
    debilidade: 'Concentração', icon: '🚩', cor: '#FFA500', nivel: 'Sub-12+',
    situacao: 'Canto contra a tua equipa. Marcas o nº 9 deles — o mais forte no jogo aéreo. A bola vai ser batida e ele começa a afastar-se de ti em passos curtos.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 230, y: 140, team: 'us', label: 'TU', highlight: true }, n9: { x: 245, y: 150, team: 'them', label: '9' }, gr: { x: 250, y: 75, team: 'us', label: 'GR' }, batedor: { x: 440, y: 90, team: 'them' } }, ball: { owner: 'batedor' }, indica: 'Canto contra. Marcas o 9.' },
      { t: 1500, players: { meu: { x: 230, y: 140, team: 'us', highlight: true }, n9: { x: 265, y: 165, team: 'them' }, gr: { x: 250, y: 75, team: 'us' }, batedor: { x: 440, y: 90, team: 'them' } }, ball: { owner: 'batedor' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 230, y: 140, team: 'us', highlight: true }, n9: { x: 265, y: 165, team: 'them' }, gr: { x: 250, y: 75, team: 'us' }, batedor: { x: 440, y: 90, team: 'them' } }, ball: { owner: 'batedor' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Olhar só para a bola', certa: false, feedback: 'Quando a bola entrou, o 9 já tinha 3 metros de balanço. Golo dele, marcação tua.', consequencia: 'perda' },
      { id: 'B', texto: 'Contacto + bola e homem no campo de visão', certa: true, feedback: 'Mão no contacto, corpo orientado para veres bola E homem. Atacaste a bola primeiro.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Agarrar a camisola', certa: false, feedback: 'O árbitro estava a olhar. Penálti. Caro demais.', consequencia: 'perda' }
    ],
    treino: ['Marcação homem-a-homem em bola parada', 'Orientação corporal bola+homem', 'Duelo aéreo com contacto legal'],
    dica: 'Em bola parada, quem perde o homem de vista por 1 segundo perde o lance. Bola E homem, sempre.'
  },
  {
    id: 'C18', titulo: '2 contra 1 · Decidir o último passe', posicao: 'Todos',
    debilidade: 'Tomada de decisão', icon: '⭐', cor: '#00D46A', nivel: 'Sub-9+',
    situacao: 'Contra-ataque! Levas a bola em velocidade, só tens um defesa pela frente e um colega livre ao teu lado. O guarda-redes fica na baliza.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 200, y: 280, team: 'us', label: 'TU', highlight: true }, colega: { x: 320, y: 270, team: 'us', label: 'Colega' }, def: { x: 260, y: 190, team: 'them', label: 'Def' }, gr: { x: 250, y: 75, team: 'them', label: 'GR' } }, ball: { owner: 'meu' }, indica: '2 contra 1! Tu e o colega.' },
      { t: 1500, players: { meu: { x: 210, y: 240, team: 'us', highlight: true }, colega: { x: 320, y: 230, team: 'us' }, def: { x: 255, y: 185, team: 'them' }, gr: { x: 250, y: 75, team: 'them' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 210, y: 240, team: 'us', highlight: true }, colega: { x: 320, y: 230, team: 'us' }, def: { x: 255, y: 185, team: 'them' }, gr: { x: 250, y: 75, team: 'them' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Passar já ao colega', certa: false, feedback: 'Passaste cedo demais — o defesa nem teve de escolher, foi direto ao teu colega.', consequencia: 'neutro' },
      { id: 'B', texto: 'Conduzir até fixar o defesa, depois decidir', certa: true, feedback: 'Conduziste até ele TER de vir a ti — e o passe saiu no momento certo. Colega isolado para o golo.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Rematar de longe', certa: false, feedback: 'Tinhas superioridade e escolheste a opção mais difícil. O GR agradeceu.', consequencia: 'neutro' }
    ],
    treino: ['2v1 em campo reduzido', 'Fixar o defesa antes do passe', 'Decisão com cabeça levantada'],
    dica: 'No 2v1, a bola FIXA o defesa. Obriga-o a escolher-te — e nesse momento o teu colega fica livre.'
  },
  {
    id: 'C19', titulo: 'Receção de pé fraco sob marcação', posicao: 'Extremo / Lateral',
    debilidade: 'Controlo do pé fraco', icon: '🦶', cor: '#4AE87A', nivel: 'Sub-11+',
    situacao: 'Recebes na ala pelo teu pé fraco. O lateral adversário fecha o corredor forte, obrigando-te a decidir com o pé que treinas menos.',
    duracao: 4200,
    frames: [
      { t: 0, players: { meu: { x: 120, y: 400, team: 'us', label: 'TU', highlight: true }, adv: { x: 90, y: 380, team: 'them', label: 'Adv' }, apoio: { x: 220, y: 460, team: 'us', label: 'Méd' }, lateral: { x: 80, y: 520, team: 'us', label: 'Lat' }, avante: { x: 200, y: 220, team: 'us', label: 'Av' } }, ball: { owner: 'meu' }, indica: 'Bola chega ao pé fraco. Adversário fecha o lado forte.' },
      { t: 1500, players: { meu: { x: 120, y: 400, team: 'us', highlight: true }, adv: { x: 95, y: 385, team: 'them' }, apoio: { x: 220, y: 460, team: 'us' }, lateral: { x: 80, y: 520, team: 'us' }, avante: { x: 200, y: 220, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4200, players: { meu: { x: 120, y: 400, team: 'us', highlight: true }, adv: { x: 95, y: 385, team: 'them' }, apoio: { x: 220, y: 460, team: 'us' }, lateral: { x: 80, y: 520, team: 'us' }, avante: { x: 200, y: 220, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Forças o corte para o pé forte', certa: false, feedback: 'Perdeste tempo a trocar de pé — o adversário reajustou e cortou a bola.', consequencia: 'perda' },
      { id: 'B', texto: 'Jogas de primeira com o pé fraco para o apoio', certa: true, feedback: 'De primeira, sem hesitar — o pé fraco não te travou. Bola limpa no apoio.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Proteges a bola e esperas ajuda', certa: false, feedback: 'Atrasaste demasiado — a linha adversária teve tempo de fechar o espaço.', consequencia: 'neutro' }
    ],
    treino: ['Passe de pé fraco contra a parede', '1 toque só com o pé não-dominante', 'Receção orientada para o corredor livre'],
    dica: 'O pé fraco não precisa de ser perfeito — só precisa de ser rápido. Um toque simples vale mais que uma jogada bonita atrasada.'
  },
  {
    id: 'C20', titulo: 'Amortecimento aéreo em zona de pressão', posicao: 'Médio',
    debilidade: 'Primeiro toque sob pressão', icon: '⚡', cor: '#D4AF37', nivel: 'Sub-12+',
    situacao: 'Bola longa cai perto de ti, no meio-campo, com dois adversários a fechar. Tens meio segundo para decidir o amortecimento.',
    duracao: 4200,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 380, team: 'us', label: 'TU', highlight: true }, adv1: { x: 220, y: 350, team: 'them', label: 'Adv' }, adv2: { x: 290, y: 400, team: 'them', label: 'Adv' }, apoio: { x: 180, y: 460, team: 'us', label: 'Méd' }, lateral: { x: 400, y: 420, team: 'us', label: 'Lat' } }, ball: { x: 250, y: 200 }, indica: 'Bola longa a cair. Dois adversários a fechar.' },
      { t: 1500, players: { meu: { x: 250, y: 380, team: 'us', highlight: true }, adv1: { x: 225, y: 360, team: 'them' }, adv2: { x: 285, y: 390, team: 'them' }, apoio: { x: 190, y: 450, team: 'us' }, lateral: { x: 390, y: 415, team: 'us' } }, ball: { x: 250, y: 340 }, indica: 'O QUE FAZES?' },
      { t: 4200, players: { meu: { x: 250, y: 380, team: 'us', highlight: true }, adv1: { x: 225, y: 360, team: 'them' }, adv2: { x: 285, y: 390, team: 'them' }, apoio: { x: 190, y: 450, team: 'us' }, lateral: { x: 390, y: 415, team: 'us' } }, ball: { x: 250, y: 340 }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Amorteces para a frente e viras', certa: false, feedback: 'O toque longo deu tempo aos dois adversários para recuperarem e cortarem.', consequencia: 'perda' },
      { id: 'B', texto: 'Amorteces de lado, para fora da pressão', certa: true, feedback: 'Saíste da pressão com um toque curto e limpo — bola controlada, jogo continua.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Deixas a bola quicar antes de tocar', certa: false, feedback: 'O ressalto deu tempo aos dois adversários a fecharem-te de vez.', consequencia: 'neutro' }
    ],
    treino: ['Amortecimento de bola lançada, 1 toque', 'Controlo orientado sob pressão de 2 adversários', 'Receção de costas com viragem rápida'],
    dica: 'O primeiro toque decide o resto da jogada. Amortece SEMPRE para longe da pressão, nunca para o meio dela.'
  },
  {
    id: 'C21', titulo: 'Proteger bola de costas para a baliza', posicao: 'Avançado',
    debilidade: 'Proteção de bola', icon: '💪', cor: '#FF8C42', nivel: 'Sub-12+',
    situacao: 'Recebes de costas para a baliza adversária, marcado de perto. Não tens espaço para te virares.',
    duracao: 4200,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 250, team: 'us', label: 'TU', highlight: true }, adv: { x: 250, y: 220, team: 'them', label: 'Adv' }, apoio: { x: 180, y: 320, team: 'us', label: 'Méd' }, lateral: { x: 350, y: 340, team: 'us', label: 'Lat' } }, ball: { owner: 'meu' }, indica: 'Recebes de costas. Adversário colado.' },
      { t: 1500, players: { meu: { x: 250, y: 250, team: 'us', highlight: true }, adv: { x: 250, y: 228, team: 'them' }, apoio: { x: 195, y: 330, team: 'us' }, lateral: { x: 340, y: 335, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4200, players: { meu: { x: 250, y: 250, team: 'us', highlight: true }, adv: { x: 250, y: 228, team: 'them' }, apoio: { x: 195, y: 330, team: 'us' }, lateral: { x: 340, y: 335, team: 'us' } }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Tentas virar-te à força', certa: false, feedback: 'O adversário estava mais forte no duelo — perdeste a bola a tentar virar.', consequencia: 'perda' },
      { id: 'B', texto: 'Proteges com o corpo e devolves ao apoio', certa: true, feedback: 'Protegeste bem e devolveste simples — a equipa manteve a posse e reorganizou.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Tentas um passe longo sem olhar', certa: false, feedback: 'Sem visão do que estava atrás de ti, o passe saiu sem destino certo.', consequencia: 'neutro' }
    ],
    treino: ['Proteção de bola com o corpo entre a bola e o adversário', 'Jogo de costas com 1 toque de saída', 'Domínio orientado sob marcação de perto'],
    dica: 'Nem sempre é para virar. Às vezes a melhor decisão é devolver simples e deixar a equipa reorganizar o ataque.'
  },
  {
    id: 'C22', titulo: 'Substituído a meio do jogo', posicao: 'Todos',
    debilidade: 'Reação emocional à substituição', icon: '🚶', cor: '#A78BFA', nivel: 'Sub-11+',
    situacao: 'O treinador chama o teu número aos 55 minutos. Estavas a jogar bem e não percebes porquê.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 300, team: 'us', label: 'TU', highlight: true }, treinador: { x: 60, y: 500, team: 'us', label: 'Mister' }, colega: { x: 340, y: 280, team: 'us', label: 'Colega' } }, ball: { x: 340, y: 260 }, indica: 'O treinador chama o teu número.' },
      { t: 1500, players: { meu: { x: 250, y: 300, team: 'us', highlight: true }, treinador: { x: 60, y: 500, team: 'us' }, colega: { x: 340, y: 280, team: 'us' } }, ball: { x: 340, y: 260 }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 300, team: 'us', highlight: true }, treinador: { x: 60, y: 500, team: 'us' }, colega: { x: 340, y: 280, team: 'us' } }, ball: { x: 340, y: 260 }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Sais devagar, a mostrar que discordas', certa: false, feedback: 'O treinador viu — e essa atitude conta mais do que pensas na próxima escolha dele.', consequencia: 'perda' },
      { id: 'B', texto: 'Sais a aplaudir os colegas, sais rápido', certa: true, feedback: 'Saíste como profissional. O treinador reparou, e os colegas sentiram o teu apoio.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Sais em silêncio, sem olhar para ninguém', certa: false, feedback: 'Ninguém percebeu o que sentias — nem o treinador, nem a equipa.', consequencia: 'neutro' }
    ],
    treino: ['Conversa com o treinador sobre o motivo da substituição', 'Rotina pessoal para os minutos fora do jogo', 'Apoio ativo ao banco quando não jogas'],
    dica: 'Como sais do campo diz mais sobre ti do que qualquer jogada. O treinador está sempre a decidir quem entra a seguir.'
  },
  {
    id: 'C23', titulo: 'Erraste o passe, a equipa sofreu', posicao: 'Todos',
    debilidade: 'Concentração após erro', icon: '😔', cor: '#A78BFA', nivel: 'Sub-11+',
    situacao: 'O teu passe atrasado foi intercetado. Trinta segundos depois, a equipa adversária marca. Sentes o peso do erro.',
    duracao: 4500,
    frames: [
      { t: 0, players: { meu: { x: 250, y: 350, team: 'us', label: 'TU', highlight: true }, colega: { x: 180, y: 300, team: 'us', label: 'Colega' }, adv: { x: 300, y: 200, team: 'them', label: 'Adv' } }, ball: { x: 300, y: 100 }, indica: 'Golo sofrido depois do teu erro.' },
      { t: 1500, players: { meu: { x: 250, y: 350, team: 'us', highlight: true }, colega: { x: 200, y: 320, team: 'us' }, adv: { x: 300, y: 200, team: 'them' } }, ball: { x: 250, y: 350 }, indica: 'O QUE FAZES?' },
      { t: 4500, players: { meu: { x: 250, y: 350, team: 'us', highlight: true }, colega: { x: 200, y: 320, team: 'us' }, adv: { x: 300, y: 200, team: 'them' } }, ball: { x: 250, y: 350 }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Ficas a pensar no erro nas jogadas seguintes', certa: false, feedback: 'A cabeça ficou no golo sofrido — e o segundo erro veio a seguir, ainda pior.', consequencia: 'perda' },
      { id: 'B', texto: 'Pedes a bola já a seguir, sem medo', certa: true, feedback: 'Voltaste a pedir bola de imediato — a equipa sentiu que não te escondeste do erro.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Jogas só passes seguros o resto do jogo', certa: false, feedback: 'Deixaste de arriscar — a equipa perdeu a tua criatividade pelo resto da partida.', consequencia: 'neutro' }
    ],
    treino: ['Rotina de reset de 5 segundos após erro', 'Pedir bola logo a seguir a uma falha', 'Análise de vídeo sem julgamento, só correção'],
    dica: 'Um erro é um passe. O que decide o jogo é o passe seguinte, não o que já foi.'
  },
  {
    id: 'C24', titulo: 'Cobertura quando o companheiro é ultrapassado', posicao: 'Defesa',
    debilidade: 'Leitura da cobertura defensiva', icon: '🧲', cor: '#4A9FE8', nivel: 'Sub-12+',
    situacao: 'O teu central companheiro foi batido no 1×1. O atacante avança para a área. Tens de decidir a cobertura.',
    duracao: 4200,
    frames: [
      { t: 0, players: { meu: { x: 320, y: 550, team: 'us', label: 'TU', highlight: true }, central: { x: 200, y: 480, team: 'us', label: 'DC' }, atacante: { x: 210, y: 420, team: 'them', label: 'Av' }, gr: { x: 250, y: 690, team: 'us', label: 'GR' } }, ball: { owner: 'atacante' }, indica: 'O teu colega foi batido. Atacante avança.' },
      { t: 1500, players: { meu: { x: 290, y: 520, team: 'us', highlight: true }, central: { x: 220, y: 460, team: 'us' }, atacante: { x: 240, y: 460, team: 'them' }, gr: { x: 250, y: 690, team: 'us' } }, ball: { owner: 'atacante' }, indica: 'O QUE FAZES?' },
      { t: 4200, players: { meu: { x: 290, y: 520, team: 'us', highlight: true }, central: { x: 220, y: 460, team: 'us' }, atacante: { x: 240, y: 460, team: 'them' }, gr: { x: 250, y: 690, team: 'us' } }, ball: { owner: 'atacante' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Avanças a dobrar em cima do atacante', certa: false, feedback: 'Deixaste o teu próprio marcado livre — o passe lateral custou o golo.', consequencia: 'perda' },
      { id: 'B', texto: 'Fechas a linha de passe e reduzes o espaço da baliza', certa: true, feedback: 'Cobertura inteligente — obrigaste o atacante para fora, sem deixar ninguém livre.', consequencia: 'sucesso' },
      { id: 'C', texto: 'Ficas parado a gritar instruções', certa: false, feedback: 'A comunicação chegou tarde — o atacante já tinha entrado na área.', consequencia: 'neutro' }
    ],
    treino: ['Cobertura defensiva 2x1 em campo reduzido', 'Leitura de quando dobrar vs. quando fechar espaço', 'Comunicação defensiva sob pressão'],
    dica: 'Dobrar sem necessidade cria um buraco novo. A primeira pergunta é sempre: "se eu sair, quem fica livre?"'
  }
];
