// ═══════════════════════════════════════════════════════
// YTB ELITE COACH · DATA
// Coordenadas: SVG 500×740 (vertical, ataque para CIMA)
// ═══════════════════════════════════════════════════════

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
  }
];

// ─── 12 SIMULAÇÕES TÁTICAS ──────────────────────────────
// Animações sem decisão: mostram padrões com pop-ups de dicas durante e relatório no fim
const SIMULACOES = [
  {
    id: 'S01', titulo: 'Saída de pressão alta · 4-3-3 vs 4-4-2',
    icon: '🛡️', cor: '#4A9FE8', nivel: 'Sub-13+',
    contexto: 'O adversário pressiona alto com 2 atacantes. Vamos sair limpo pelo lateral.',
    duracao: 6000,
    frames: [
      { t: 0, players: { gr: { x: 250, y: 690, team: 'us', label: 'GR' }, dcL: { x: 170, y: 600, team: 'us', label: 'DC' }, dcR: { x: 330, y: 600, team: 'us', label: 'DC' }, latL: { x: 70, y: 530, team: 'us', label: 'LE' }, latR: { x: 430, y: 530, team: 'us', label: 'LD' }, mc: { x: 250, y: 460, team: 'us', label: 'MC' }, av1: { x: 200, y: 540, team: 'them' }, av2: { x: 300, y: 540, team: 'them' } }, ball: { owner: 'gr' } },
      { t: 1500, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 130, y: 590, team: 'us' }, dcR: { x: 370, y: 590, team: 'us' }, latL: { x: 70, y: 510, team: 'us' }, latR: { x: 430, y: 510, team: 'us', highlight: true }, mc: { x: 250, y: 460, team: 'us' }, av1: { x: 180, y: 560, team: 'them' }, av2: { x: 300, y: 560, team: 'them' } }, ball: { owner: 'gr' }, dica: 'Centrais abrem. Lateral livre na ala direita.' },
      { t: 3000, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 130, y: 590, team: 'us' }, dcR: { x: 370, y: 590, team: 'us' }, latL: { x: 70, y: 510, team: 'us' }, latR: { x: 430, y: 510, team: 'us', highlight: true }, mc: { x: 250, y: 460, team: 'us' }, av1: { x: 180, y: 560, team: 'them' }, av2: { x: 300, y: 560, team: 'them' } }, ball: { x: 430, y: 510 }, dica: 'GR vê o lateral livre e bate longo no espaço.' },
      { t: 4500, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 130, y: 590, team: 'us' }, dcR: { x: 370, y: 590, team: 'us' }, latL: { x: 70, y: 510, team: 'us' }, latR: { x: 430, y: 510, team: 'us', highlight: true }, mc: { x: 280, y: 420, team: 'us' }, av1: { x: 180, y: 560, team: 'them' }, av2: { x: 300, y: 560, team: 'them' } }, ball: { owner: 'latR' }, dica: 'Lateral domina, médio aproxima para apoio.' },
      { t: 6000, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 130, y: 590, team: 'us' }, dcR: { x: 370, y: 590, team: 'us' }, latL: { x: 70, y: 510, team: 'us' }, latR: { x: 430, y: 470, team: 'us', highlight: true }, mc: { x: 320, y: 380, team: 'us' }, av1: { x: 180, y: 560, team: 'them' }, av2: { x: 300, y: 560, team: 'them' } }, ball: { owner: 'latR' }, dica: 'Saída limpa. Equipa progride com posse.' }
    ],
    relatorio: 'Saída de pressão pelo corredor livre. Princípio: adversário com 2 atacantes não consegue cobrir todas as opções. Sai pelo lado oposto à pressão.',
    dicas: ['GR observa antes de jogar — ler onde está a pressão', 'Centrais abrem para criar opções amplas', 'Lateral livre é sempre prioridade na construção'],
    treino: ['Saída desde GR contra 2 atacantes', 'Comunicação entre defesas']
  },
  {
    id: 'S02', titulo: 'Transição rápida após recuperação',
    icon: '⚡', cor: '#E05050', nivel: 'Sub-13+',
    contexto: 'Recuperaste a bola no meio-campo. Adversário está fora de posição.',
    duracao: 6000,
    frames: [
      { t: 0, players: { mc: { x: 250, y: 380, team: 'us', label: 'MC', highlight: true }, latR: { x: 420, y: 350, team: 'us', label: 'LD' }, av: { x: 250, y: 250, team: 'us', label: 'AV' }, ext: { x: 80, y: 280, team: 'us', label: 'EE' }, adv1: { x: 250, y: 320, team: 'them' }, adv2: { x: 200, y: 250, team: 'them' }, adv3: { x: 320, y: 200, team: 'them' } }, ball: { owner: 'mc' } },
      { t: 1500, players: { mc: { x: 250, y: 380, team: 'us', highlight: true }, latR: { x: 420, y: 320, team: 'us' }, av: { x: 250, y: 220, team: 'us' }, ext: { x: 80, y: 260, team: 'us' }, adv1: { x: 250, y: 320, team: 'them' }, adv2: { x: 200, y: 250, team: 'them' }, adv3: { x: 320, y: 200, team: 'them' } }, ball: { owner: 'mc' }, dica: 'Recuperaste! Procura linha vertical rápida.' },
      { t: 3000, players: { mc: { x: 250, y: 380, team: 'us', highlight: true }, latR: { x: 420, y: 280, team: 'us' }, av: { x: 250, y: 180, team: 'us' }, ext: { x: 80, y: 240, team: 'us' }, adv1: { x: 250, y: 320, team: 'them' }, adv2: { x: 200, y: 250, team: 'them' }, adv3: { x: 320, y: 200, team: 'them' } }, ball: { x: 250, y: 280 }, dica: 'Passe vertical para o avante em rutura.' },
      { t: 4500, players: { mc: { x: 250, y: 380, team: 'us' }, latR: { x: 420, y: 250, team: 'us' }, av: { x: 250, y: 180, team: 'us', highlight: true }, ext: { x: 80, y: 220, team: 'us' }, adv1: { x: 250, y: 320, team: 'them' }, adv2: { x: 200, y: 250, team: 'them' }, adv3: { x: 320, y: 220, team: 'them' } }, ball: { owner: 'av' }, dica: 'Avante recebe entre linhas com espaço.' },
      { t: 6000, players: { mc: { x: 250, y: 380, team: 'us' }, latR: { x: 420, y: 200, team: 'us' }, av: { x: 250, y: 130, team: 'us', highlight: true }, ext: { x: 100, y: 180, team: 'us' }, adv1: { x: 250, y: 320, team: 'them' }, adv2: { x: 200, y: 280, team: 'them' }, adv3: { x: 320, y: 240, team: 'them' } }, ball: { owner: 'av' }, dica: 'Defesa em desvantagem. Finaliza ou serve.' }
    ],
    relatorio: 'Transição ofensiva rápida explora o desequilíbrio adversário. 3 segundos após recuperação são ouro.',
    dicas: ['Após recuperar, vertical primeiro lateral depois', 'Avante deve atacar espaço não a bola', 'Lateral acompanha em segunda linha'],
    treino: ['Drill 3v2 com transição', 'Sprint após recuperação simulada']
  },
  {
    id: 'S03', titulo: 'Construção contra bloco médio',
    icon: '🎯', cor: '#D4AF37', nivel: 'Sub-13+',
    contexto: 'Adversário em bloco médio organizado. Como progredir com posse?',
    duracao: 6000,
    frames: [
      { t: 0, players: { gr: { x: 250, y: 690, team: 'us', label: 'GR' }, dcL: { x: 180, y: 600, team: 'us', label: 'DC' }, dcR: { x: 320, y: 600, team: 'us', label: 'DC' }, mc: { x: 250, y: 480, team: 'us', label: 'MC' }, latR: { x: 420, y: 500, team: 'us', label: 'LD' }, latL: { x: 80, y: 500, team: 'us', label: 'LE' }, adv1: { x: 200, y: 400, team: 'them' }, adv2: { x: 300, y: 400, team: 'them' }, adv3: { x: 250, y: 350, team: 'them' } }, ball: { owner: 'dcR' } },
      { t: 1500, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 180, y: 600, team: 'us' }, dcR: { x: 320, y: 600, team: 'us', highlight: true }, mc: { x: 250, y: 480, team: 'us' }, latR: { x: 420, y: 470, team: 'us' }, latL: { x: 80, y: 500, team: 'us' }, adv1: { x: 200, y: 400, team: 'them' }, adv2: { x: 300, y: 400, team: 'them' }, adv3: { x: 250, y: 350, team: 'them' } }, ball: { owner: 'dcR' }, dica: 'Central com bola. Procurar linha entre 2 adversários.' },
      { t: 3000, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 180, y: 600, team: 'us' }, dcR: { x: 320, y: 600, team: 'us' }, mc: { x: 270, y: 460, team: 'us', highlight: true }, latR: { x: 420, y: 450, team: 'us' }, latL: { x: 80, y: 500, team: 'us' }, adv1: { x: 200, y: 400, team: 'them' }, adv2: { x: 300, y: 400, team: 'them' }, adv3: { x: 250, y: 350, team: 'them' } }, ball: { x: 270, y: 480 }, dica: 'Passe entre linhas para o médio.' },
      { t: 4500, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 180, y: 600, team: 'us' }, dcR: { x: 320, y: 600, team: 'us' }, mc: { x: 270, y: 460, team: 'us', highlight: true }, latR: { x: 420, y: 400, team: 'us' }, latL: { x: 80, y: 500, team: 'us' }, adv1: { x: 220, y: 430, team: 'them' }, adv2: { x: 320, y: 430, team: 'them' }, adv3: { x: 270, y: 380, team: 'them' } }, ball: { owner: 'mc' }, dica: 'Médio rodou, defesa fechou. Procurar lateral livre.' },
      { t: 6000, players: { gr: { x: 250, y: 690, team: 'us' }, dcL: { x: 180, y: 600, team: 'us' }, dcR: { x: 320, y: 600, team: 'us' }, mc: { x: 270, y: 460, team: 'us' }, latR: { x: 420, y: 380, team: 'us', highlight: true }, latL: { x: 80, y: 500, team: 'us' }, adv1: { x: 220, y: 430, team: 'them' }, adv2: { x: 320, y: 430, team: 'them' }, adv3: { x: 270, y: 380, team: 'them' } }, ball: { owner: 'latR' }, dica: 'Lateral progride em zona ofensiva.' }
    ],
    relatorio: 'Construção paciente com central → médio → lateral. Princípio: passar entre linhas para fixar pressão e libertar zona oposta.',
    dicas: ['Central deve procurar passe vertical antes do horizontal', 'Médio rodar com primeiro toque', 'Lateral é a saída quando o meio fica fechado'],
    treino: ['Posse 4v4+1 em zona reduzida', 'Passe entre linhas com pressão']
  },
  {
    id: 'S04', titulo: 'Pressing alto coordenado',
    icon: '🔥', cor: '#E05050', nivel: 'Sub-15+',
    contexto: 'Equipa em bloco alto. Como pressionar coordenado para roubar bola?',
    duracao: 6000,
    frames: [
      { t: 0, players: { av: { x: 250, y: 250, team: 'us', label: 'AV' }, extL: { x: 130, y: 280, team: 'us', label: 'EE' }, extR: { x: 370, y: 280, team: 'us', label: 'ED' }, mcL: { x: 200, y: 380, team: 'us', label: 'MC' }, mcR: { x: 300, y: 380, team: 'us', label: 'MC' }, dc: { x: 250, y: 580, team: 'them' }, latL: { x: 130, y: 600, team: 'them' }, latR: { x: 370, y: 600, team: 'them' } }, ball: { owner: 'dc' } },
      { t: 1500, players: { av: { x: 250, y: 320, team: 'us', label: 'AV', highlight: true }, extL: { x: 150, y: 350, team: 'us' }, extR: { x: 350, y: 350, team: 'us' }, mcL: { x: 200, y: 380, team: 'us' }, mcR: { x: 300, y: 380, team: 'us' }, dc: { x: 250, y: 580, team: 'them' }, latL: { x: 130, y: 600, team: 'them' }, latR: { x: 370, y: 600, team: 'them' } }, ball: { owner: 'dc' }, dica: 'Avante pressiona o central. Extremos fecham laterais.' },
      { t: 3000, players: { av: { x: 250, y: 380, team: 'us', highlight: true }, extL: { x: 150, y: 410, team: 'us' }, extR: { x: 350, y: 410, team: 'us' }, mcL: { x: 200, y: 400, team: 'us' }, mcR: { x: 300, y: 400, team: 'us' }, dc: { x: 250, y: 550, team: 'them' }, latL: { x: 130, y: 580, team: 'them' }, latR: { x: 370, y: 580, team: 'them' } }, ball: { owner: 'dc' }, dica: 'Central forçado a tomar decisão sob pressão.' },
      { t: 4500, players: { av: { x: 250, y: 420, team: 'us', highlight: true }, extL: { x: 130, y: 480, team: 'us' }, extR: { x: 370, y: 480, team: 'us' }, mcL: { x: 200, y: 420, team: 'us' }, mcR: { x: 300, y: 420, team: 'us' }, dc: { x: 250, y: 550, team: 'them' }, latL: { x: 130, y: 580, team: 'them' }, latR: { x: 370, y: 580, team: 'them' } }, ball: { x: 130, y: 580 }, dica: 'Central passa para lateral pressionado. Bola perdida.' },
      { t: 6000, players: { av: { x: 250, y: 420, team: 'us' }, extL: { x: 130, y: 580, team: 'us', highlight: true }, extR: { x: 370, y: 480, team: 'us' }, mcL: { x: 200, y: 450, team: 'us' }, mcR: { x: 300, y: 420, team: 'us' }, dc: { x: 250, y: 550, team: 'them' }, latL: { x: 130, y: 580, team: 'them' }, latR: { x: 370, y: 580, team: 'them' } }, ball: { owner: 'extL' }, dica: 'Recuperação alta. Posse em zona perigosa.' }
    ],
    relatorio: 'Pressing coordenado em "armadilha lateral". Avante força o passe no lateral, extremo intercepta.',
    dicas: ['Avante NUNCA pressiona sozinho', 'Extremos fecham linhas externas', 'Médios cobrem o meio para evitar passe interior'],
    treino: ['Pressing 4v4 com gatilhos', 'Coordenação entre linhas']
  },
  {
    id: 'S05', titulo: 'Defesa contra cruzamento',
    icon: '🧱', cor: '#4A9FE8', nivel: 'Sub-12+',
    contexto: 'Adversário cruzou da ala. Como defender a área?',
    duracao: 5500,
    frames: [
      { t: 0, players: { gr: { x: 250, y: 700, team: 'us', label: 'GR' }, dc1: { x: 200, y: 640, team: 'us', label: 'DC' }, dc2: { x: 300, y: 640, team: 'us', label: 'DC' }, latL: { x: 100, y: 600, team: 'us' }, latR: { x: 400, y: 600, team: 'us' }, adv1: { x: 220, y: 580, team: 'them' }, adv2: { x: 280, y: 600, team: 'them' }, cruzador: { x: 80, y: 530, team: 'them' } }, ball: { owner: 'cruzador' } },
      { t: 1500, players: { gr: { x: 250, y: 700, team: 'us' }, dc1: { x: 220, y: 630, team: 'us', highlight: true }, dc2: { x: 280, y: 630, team: 'us', highlight: true }, latL: { x: 100, y: 600, team: 'us' }, latR: { x: 400, y: 600, team: 'us' }, adv1: { x: 220, y: 590, team: 'them' }, adv2: { x: 280, y: 610, team: 'them' }, cruzador: { x: 80, y: 530, team: 'them' } }, ball: { owner: 'cruzador' }, dica: 'Centrais marcam atacantes corpo a corpo.' },
      { t: 3000, players: { gr: { x: 250, y: 700, team: 'us' }, dc1: { x: 220, y: 620, team: 'us', highlight: true }, dc2: { x: 280, y: 620, team: 'us' }, latL: { x: 100, y: 580, team: 'us' }, latR: { x: 400, y: 580, team: 'us' }, adv1: { x: 220, y: 600, team: 'them' }, adv2: { x: 280, y: 615, team: 'them' }, cruzador: { x: 80, y: 530, team: 'them' } }, ball: { x: 200, y: 580 }, dica: 'Bola cruzada. Central ataca o ponto.' },
      { t: 4500, players: { gr: { x: 250, y: 700, team: 'us' }, dc1: { x: 200, y: 580, team: 'us', highlight: true }, dc2: { x: 280, y: 620, team: 'us' }, latL: { x: 100, y: 580, team: 'us' }, latR: { x: 400, y: 580, team: 'us' }, adv1: { x: 220, y: 600, team: 'them' }, adv2: { x: 280, y: 615, team: 'them' }, cruzador: { x: 80, y: 530, team: 'them' } }, ball: { x: 200, y: 570 }, dica: 'Central afasta de cabeça antes do atacante.' },
      { t: 5500, players: { gr: { x: 250, y: 700, team: 'us' }, dc1: { x: 200, y: 580, team: 'us', highlight: true }, dc2: { x: 280, y: 620, team: 'us' }, latL: { x: 100, y: 580, team: 'us' }, latR: { x: 400, y: 580, team: 'us' }, adv1: { x: 220, y: 600, team: 'them' }, adv2: { x: 280, y: 615, team: 'them' }, cruzador: { x: 80, y: 530, team: 'them' } }, ball: { x: 350, y: 450 }, dica: 'Bola afastada. Equipa reorganiza-se.' }
    ],
    relatorio: 'Defesa do cruzamento depende de antecipação e contacto. Central deve atacar a bola, nunca ficar à espera.',
    dicas: ['Atacar o ponto, não esperar a bola', 'Marcação corpo a corpo no cruzamento', 'Reorganizar imediatamente após afastar'],
    treino: ['Cabeceamento defensivo', 'Marcação na área']
  },
  {
    id: 'S06', titulo: 'Posse em zona reduzida',
    icon: '🎯', cor: '#D4AF37', nivel: 'Sub-13+',
    contexto: 'Equipa controla a posse num espaço apertado. Como manter o ritmo?',
    duracao: 6000,
    frames: [
      { t: 0, players: { mcL: { x: 200, y: 420, team: 'us', label: 'MC' }, mcR: { x: 300, y: 420, team: 'us', label: 'MC' }, mo: { x: 250, y: 350, team: 'us', label: 'MO' }, av: { x: 250, y: 250, team: 'us', label: 'AV' }, adv1: { x: 230, y: 380, team: 'them' }, adv2: { x: 280, y: 380, team: 'them' }, adv3: { x: 250, y: 300, team: 'them' } }, ball: { owner: 'mcL' } },
      { t: 1500, players: { mcL: { x: 200, y: 420, team: 'us', highlight: true }, mcR: { x: 320, y: 420, team: 'us' }, mo: { x: 240, y: 360, team: 'us' }, av: { x: 250, y: 250, team: 'us' }, adv1: { x: 230, y: 380, team: 'them' }, adv2: { x: 280, y: 380, team: 'them' }, adv3: { x: 250, y: 300, team: 'them' } }, ball: { owner: 'mcL' }, dica: 'Médio com bola. Triângulo formado com colegas.' },
      { t: 3000, players: { mcL: { x: 200, y: 420, team: 'us' }, mcR: { x: 320, y: 420, team: 'us', highlight: true }, mo: { x: 240, y: 360, team: 'us' }, av: { x: 250, y: 250, team: 'us' }, adv1: { x: 230, y: 380, team: 'them' }, adv2: { x: 280, y: 380, team: 'them' }, adv3: { x: 250, y: 300, team: 'them' } }, ball: { x: 320, y: 420 }, dica: 'Passe horizontal para fugir da pressão.' },
      { t: 4500, players: { mcL: { x: 200, y: 420, team: 'us' }, mcR: { x: 320, y: 420, team: 'us' }, mo: { x: 270, y: 350, team: 'us', highlight: true }, av: { x: 250, y: 250, team: 'us' }, adv1: { x: 250, y: 400, team: 'them' }, adv2: { x: 300, y: 380, team: 'them' }, adv3: { x: 270, y: 310, team: 'them' } }, ball: { x: 270, y: 350 }, dica: 'Passe vertical para o médio ofensivo entre linhas.' },
      { t: 6000, players: { mcL: { x: 200, y: 420, team: 'us' }, mcR: { x: 320, y: 420, team: 'us' }, mo: { x: 270, y: 350, team: 'us' }, av: { x: 250, y: 220, team: 'us', highlight: true }, adv1: { x: 250, y: 400, team: 'them' }, adv2: { x: 300, y: 380, team: 'them' }, adv3: { x: 270, y: 320, team: 'them' } }, ball: { owner: 'av' }, dica: 'Avante recebe em zona avançada. Posse com progressão.' }
    ],
    relatorio: 'Posse em zona reduzida exige movimento constante. Triângulos sempre disponíveis. Pacientemente progride entre linhas.',
    dicas: ['Sempre 3 opções de passe', 'Toque rápido para fugir da pressão', 'Vertical quando o defesa fixa'],
    treino: ['Rondo 4v2', 'Posse 5v5+2 em quadrado pequeno']
  },
  {
    id: 'S07', titulo: 'Escanteio ofensivo · Esquema curto',
    icon: '⚓', cor: '#9F7AEA', nivel: 'Sub-13+',
    contexto: 'Canto ofensivo. Esquema treinado de bola curta.',
    duracao: 5500,
    frames: [
      { t: 0, players: { batedor: { x: 30, y: 60, team: 'us', label: 'Bat' }, apoio: { x: 110, y: 110, team: 'us', label: 'Méd' }, av1: { x: 220, y: 80, team: 'us', label: 'Av' }, av2: { x: 300, y: 100, team: 'us', label: 'Av' }, dc: { x: 320, y: 200, team: 'us', label: 'DC' }, gr: { x: 250, y: 30, team: 'them', label: 'GR' }, df1: { x: 220, y: 80, team: 'them' }, df2: { x: 290, y: 90, team: 'them' } }, ball: { owner: 'batedor' } },
      { t: 1500, players: { batedor: { x: 30, y: 60, team: 'us', highlight: true }, apoio: { x: 110, y: 110, team: 'us' }, av1: { x: 220, y: 80, team: 'us' }, av2: { x: 300, y: 100, team: 'us' }, dc: { x: 320, y: 200, team: 'us' }, gr: { x: 250, y: 30, team: 'them' }, df1: { x: 220, y: 80, team: 'them' }, df2: { x: 290, y: 90, team: 'them' } }, ball: { owner: 'batedor' }, dica: 'Bola curta para o apoio que aproxima.' },
      { t: 3000, players: { batedor: { x: 30, y: 60, team: 'us' }, apoio: { x: 110, y: 110, team: 'us', highlight: true }, av1: { x: 220, y: 80, team: 'us' }, av2: { x: 300, y: 100, team: 'us' }, dc: { x: 320, y: 200, team: 'us' }, gr: { x: 250, y: 30, team: 'them' }, df1: { x: 220, y: 80, team: 'them' }, df2: { x: 290, y: 90, team: 'them' } }, ball: { owner: 'apoio' }, dica: 'Apoio ganha 1v1 e ganha ângulo de cruzamento.' },
      { t: 4200, players: { batedor: { x: 30, y: 60, team: 'us' }, apoio: { x: 150, y: 130, team: 'us', highlight: true }, av1: { x: 220, y: 80, team: 'us' }, av2: { x: 300, y: 100, team: 'us' }, dc: { x: 320, y: 200, team: 'us' }, gr: { x: 250, y: 30, team: 'them' }, df1: { x: 220, y: 80, team: 'them' }, df2: { x: 290, y: 90, team: 'them' } }, ball: { x: 250, y: 90 }, dica: 'Cruzamento rasteiro no ponto de baliza.' },
      { t: 5500, players: { batedor: { x: 30, y: 60, team: 'us' }, apoio: { x: 150, y: 130, team: 'us' }, av1: { x: 250, y: 60, team: 'us', highlight: true }, av2: { x: 300, y: 100, team: 'us' }, dc: { x: 320, y: 200, team: 'us' }, gr: { x: 250, y: 30, team: 'them' }, df1: { x: 220, y: 90, team: 'them' }, df2: { x: 290, y: 90, team: 'them' } }, ball: { owner: 'av1' }, dica: 'Avante chega à frente do defesa e remata.' }
    ],
    relatorio: 'Esquema curto evita o cruzamento aéreo previsível. Apoio ganha ângulo, cruzamento rasteiro à entrada do ponto.',
    dicas: ['Surpresa: maioria espera cruzamento direto', 'Apoio deve ter qualidade de cruzamento rasteiro', 'Avante chega lançado, não parado'],
    treino: ['Esquemas de bola parada coordenados', 'Cruzamento rasteiro com precisão']
  },
  {
    id: 'S08', titulo: 'Inferioridade numérica defensiva (3v2)',
    icon: '🛡️', cor: '#4A9FE8', nivel: 'Sub-13+',
    contexto: '3 atacantes contra 2 defesas. Ganhar tempo é prioridade.',
    duracao: 5500,
    frames: [
      { t: 0, players: { dc1: { x: 200, y: 500, team: 'us', label: 'DC' }, dc2: { x: 300, y: 500, team: 'us', label: 'DC' }, adv1: { x: 200, y: 380, team: 'them' }, adv2: { x: 300, y: 380, team: 'them' }, adv3: { x: 250, y: 350, team: 'them' } }, ball: { owner: 'adv3' } },
      { t: 1500, players: { dc1: { x: 220, y: 480, team: 'us', highlight: true }, dc2: { x: 280, y: 480, team: 'us' }, adv1: { x: 200, y: 410, team: 'them' }, adv2: { x: 300, y: 410, team: 'them' }, adv3: { x: 250, y: 380, team: 'them' } }, ball: { owner: 'adv3' }, dica: 'Defesas recuam mantendo distância. Não atacar.' },
      { t: 3000, players: { dc1: { x: 230, y: 470, team: 'us', highlight: true }, dc2: { x: 280, y: 480, team: 'us' }, adv1: { x: 200, y: 440, team: 'them' }, adv2: { x: 300, y: 440, team: 'them' }, adv3: { x: 250, y: 410, team: 'them' } }, ball: { owner: 'adv3' }, dica: 'Próximo de defesa direita, vai ter de decidir.' },
      { t: 4500, players: { dc1: { x: 230, y: 470, team: 'us' }, dc2: { x: 280, y: 480, team: 'us', highlight: true }, adv1: { x: 200, y: 460, team: 'them' }, adv2: { x: 300, y: 460, team: 'them' }, adv3: { x: 250, y: 430, team: 'them' } }, ball: { owner: 'adv3' }, dica: 'Defesa direita força o passe lateral.' },
      { t: 5500, players: { dc1: { x: 250, y: 470, team: 'us' }, dc2: { x: 320, y: 460, team: 'us' }, adv1: { x: 200, y: 460, team: 'them' }, adv2: { x: 300, y: 460, team: 'them', highlight: true }, adv3: { x: 250, y: 430, team: 'them' } }, ball: { x: 320, y: 460 }, dica: 'Passe interceptado. Tempo ganho permitiu apoio chegar.' }
    ],
    relatorio: 'Em inferioridade, missão é ATRASAR. Recuar mantendo a equipa entre bola e baliza. Forçar passe lateral, nunca atacar o portador.',
    dicas: ['Recuar é a primeira opção', 'Atacar bola só com apoio', 'Forçar passe lateral, evitar passe vertical'],
    treino: ['2v3 defensivo com objectivo de atrasar', 'Cobertura entre defensores']
  },
  {
    id: 'S09', titulo: 'Profundidade na ala',
    icon: '🚀', cor: '#4AE87A', nivel: 'Sub-12+',
    contexto: 'Lateral em projecção ofensiva. Como criar profundidade?',
    duracao: 5500,
    frames: [
      { t: 0, players: { mc: { x: 250, y: 480, team: 'us', label: 'MC' }, latR: { x: 420, y: 380, team: 'us', label: 'LD' }, extR: { x: 380, y: 280, team: 'us', label: 'ED' }, av: { x: 250, y: 230, team: 'us', label: 'AV' }, df: { x: 380, y: 320, team: 'them' } }, ball: { owner: 'mc' } },
      { t: 1500, players: { mc: { x: 250, y: 480, team: 'us' }, latR: { x: 420, y: 350, team: 'us' }, extR: { x: 320, y: 250, team: 'us', highlight: true }, av: { x: 250, y: 230, team: 'us' }, df: { x: 380, y: 320, team: 'them' } }, ball: { owner: 'mc' }, dica: 'Extremo corta para dentro, abre espaço para o lateral.' },
      { t: 3000, players: { mc: { x: 250, y: 480, team: 'us' }, latR: { x: 420, y: 280, team: 'us', highlight: true }, extR: { x: 320, y: 250, team: 'us' }, av: { x: 250, y: 200, team: 'us' }, df: { x: 380, y: 320, team: 'them' } }, ball: { x: 420, y: 280 }, dica: 'Passe vertical para o lateral em rutura.' },
      { t: 4500, players: { mc: { x: 250, y: 480, team: 'us' }, latR: { x: 420, y: 230, team: 'us', highlight: true }, extR: { x: 280, y: 230, team: 'us' }, av: { x: 250, y: 180, team: 'us' }, df: { x: 380, y: 270, team: 'them' } }, ball: { owner: 'latR' }, dica: 'Lateral progride com bola, defesa em desvantagem.' },
      { t: 5500, players: { mc: { x: 250, y: 480, team: 'us' }, latR: { x: 420, y: 180, team: 'us', highlight: true }, extR: { x: 280, y: 200, team: 'us' }, av: { x: 250, y: 150, team: 'us' }, df: { x: 380, y: 230, team: 'them' } }, ball: { owner: 'latR' }, dica: 'Lateral chega à linha. Cruzamento iminente.' }
    ],
    relatorio: 'Lateral cria profundidade quando o extremo abre espaço cortando para dentro. Movimento de "permuta".',
    dicas: ['Extremo corta para dentro = lateral sobe', 'Passe vertical no momento certo', 'Sincronização é essencial'],
    treino: ['Permutas extremo-lateral', 'Passes em rutura']
  },
  {
    id: 'S10', titulo: 'Bloco baixo defensivo',
    icon: '🔒', cor: '#4A9FE8', nivel: 'Sub-15+',
    contexto: 'A defender vantagem. Como organizar bloco baixo eficaz?',
    duracao: 6000,
    frames: [
      { t: 0, players: { gr: { x: 250, y: 700, team: 'us', label: 'GR' }, dc1: { x: 200, y: 620, team: 'us' }, dc2: { x: 300, y: 620, team: 'us' }, latL: { x: 100, y: 600, team: 'us' }, latR: { x: 400, y: 600, team: 'us' }, mc1: { x: 200, y: 540, team: 'us' }, mc2: { x: 300, y: 540, team: 'us' }, mo: { x: 250, y: 480, team: 'us' }, adv1: { x: 250, y: 420, team: 'them' } }, ball: { owner: 'adv1' } },
      { t: 2000, players: { gr: { x: 250, y: 700, team: 'us' }, dc1: { x: 200, y: 620, team: 'us', highlight: true }, dc2: { x: 300, y: 620, team: 'us', highlight: true }, latL: { x: 130, y: 590, team: 'us' }, latR: { x: 370, y: 590, team: 'us' }, mc1: { x: 220, y: 530, team: 'us' }, mc2: { x: 290, y: 530, team: 'us' }, mo: { x: 250, y: 480, team: 'us' }, adv1: { x: 250, y: 440, team: 'them' } }, ball: { owner: 'adv1' }, dica: 'Linhas curtas: 8m entre defesa e meio-campo.' },
      { t: 4000, players: { gr: { x: 250, y: 700, team: 'us' }, dc1: { x: 200, y: 620, team: 'us', highlight: true }, dc2: { x: 300, y: 620, team: 'us', highlight: true }, latL: { x: 130, y: 590, team: 'us' }, latR: { x: 370, y: 590, team: 'us' }, mc1: { x: 220, y: 530, team: 'us' }, mc2: { x: 290, y: 530, team: 'us' }, mo: { x: 250, y: 480, team: 'us' }, adv1: { x: 250, y: 470, team: 'them', highlight: true } }, ball: { owner: 'adv1' }, dica: 'Adversário aproxima. Bloco mantém forma compacta.' },
      { t: 6000, players: { gr: { x: 250, y: 700, team: 'us' }, dc1: { x: 200, y: 620, team: 'us', highlight: true }, dc2: { x: 300, y: 620, team: 'us', highlight: true }, latL: { x: 130, y: 590, team: 'us' }, latR: { x: 370, y: 590, team: 'us' }, mc1: { x: 220, y: 530, team: 'us' }, mc2: { x: 290, y: 530, team: 'us' }, mo: { x: 250, y: 480, team: 'us' }, adv1: { x: 250, y: 480, team: 'them' } }, ball: { x: 320, y: 510 }, dica: 'Bloco força jogo lateral. Sem espaços interiores.' }
    ],
    relatorio: 'Bloco baixo eficaz: linhas curtas (8m), centro fechado, força jogo para fora. Paciência e disciplina colectiva.',
    dicas: ['Linhas próximas: máximo 10m entre linhas', 'Centro fechado, ala aberta', 'Não atacar bola, esperar erro adversário'],
    treino: ['Bloco baixo 11v11 simulado', 'Manter linhas com bola em movimento']
  },
  {
    id: 'S11', titulo: 'Combinação ofensiva (1-2)',
    icon: '⚡', cor: '#D4AF37', nivel: 'Sub-12+',
    contexto: 'Combinação simples para ultrapassar 1 adversário.',
    duracao: 5500,
    frames: [
      { t: 0, players: { p1: { x: 200, y: 350, team: 'us', label: 'A' }, p2: { x: 320, y: 320, team: 'us', label: 'B' }, adv: { x: 250, y: 300, team: 'them' } }, ball: { owner: 'p1' } },
      { t: 1500, players: { p1: { x: 200, y: 350, team: 'us', highlight: true }, p2: { x: 320, y: 320, team: 'us' }, adv: { x: 230, y: 320, team: 'them' } }, ball: { owner: 'p1' }, dica: 'A com bola, B oferece linha de passe.' },
      { t: 2500, players: { p1: { x: 200, y: 350, team: 'us' }, p2: { x: 320, y: 320, team: 'us', highlight: true }, adv: { x: 230, y: 320, team: 'them' } }, ball: { x: 320, y: 320 }, dica: 'Passe para B (curto).' },
      { t: 3500, players: { p1: { x: 240, y: 280, team: 'us', highlight: true }, p2: { x: 320, y: 320, team: 'us' }, adv: { x: 230, y: 320, team: 'them' } }, ball: { owner: 'p2' }, dica: 'A acelera para o espaço atrás do adversário.' },
      { t: 4500, players: { p1: { x: 280, y: 240, team: 'us', highlight: true }, p2: { x: 320, y: 320, team: 'us' }, adv: { x: 230, y: 320, team: 'them' } }, ball: { x: 290, y: 260 }, dica: 'B devolve na profundidade.' },
      { t: 5500, players: { p1: { x: 290, y: 220, team: 'us', highlight: true }, p2: { x: 320, y: 320, team: 'us' }, adv: { x: 230, y: 320, team: 'them' } }, ball: { owner: 'p1' }, dica: 'A recebe sozinho. Adversário ultrapassado.' }
    ],
    relatorio: 'Combinação 1-2 é a forma mais simples de ultrapassar 1 adversário. Cuidado: timing é tudo.',
    dicas: ['B deve estar 5-7m da bola', 'A acelera assim que dá passe', 'Devolução na profundidade, não nos pés'],
    treino: ['Combinação 1-2 com cone (adversário fictício)', 'Combinação 1-2 com defensor activo']
  },
  {
    id: 'S12', titulo: 'Saída a três contra pressão',
    icon: '📐', cor: '#9F7AEA', nivel: 'Sub-15+',
    contexto: '3 jogadores formam triângulo para construir contra pressing alto.',
    duracao: 6000,
    frames: [
      { t: 0, players: { dc1: { x: 180, y: 600, team: 'us', label: 'DC' }, dc2: { x: 320, y: 600, team: 'us', label: 'DC' }, mc: { x: 250, y: 520, team: 'us', label: 'MC' }, av1: { x: 200, y: 540, team: 'them' }, av2: { x: 300, y: 540, team: 'them' } }, ball: { owner: 'dc1' } },
      { t: 1500, players: { dc1: { x: 160, y: 590, team: 'us', highlight: true }, dc2: { x: 340, y: 590, team: 'us' }, mc: { x: 250, y: 510, team: 'us' }, av1: { x: 200, y: 550, team: 'them' }, av2: { x: 300, y: 540, team: 'them' } }, ball: { owner: 'dc1' }, dica: 'Centrais abrem para criar largura.' },
      { t: 3000, players: { dc1: { x: 160, y: 590, team: 'us' }, dc2: { x: 340, y: 590, team: 'us' }, mc: { x: 250, y: 510, team: 'us', highlight: true }, av1: { x: 220, y: 555, team: 'them' }, av2: { x: 300, y: 540, team: 'them' } }, ball: { x: 250, y: 510 }, dica: 'Médio entra entre as linhas adversárias.' },
      { t: 4500, players: { dc1: { x: 160, y: 590, team: 'us' }, dc2: { x: 340, y: 590, team: 'us' }, mc: { x: 250, y: 510, team: 'us', highlight: true }, av1: { x: 230, y: 540, team: 'them' }, av2: { x: 290, y: 540, team: 'them' } }, ball: { owner: 'mc' }, dica: 'Médio rodou de primeira. Frente livre.' },
      { t: 6000, players: { dc1: { x: 160, y: 590, team: 'us' }, dc2: { x: 340, y: 590, team: 'us' }, mc: { x: 270, y: 460, team: 'us', highlight: true }, av1: { x: 230, y: 540, team: 'them' }, av2: { x: 290, y: 540, team: 'them' } }, ball: { owner: 'mc' }, dica: 'Equipa progride com posse. Pressing batido.' }
    ],
    relatorio: 'Triângulo defensivo (2 centrais + médio) bate pressing alto se houver paciência e timing.',
    dicas: ['Centrais separam-se ao máximo', 'Médio fica entre linhas adversárias', 'Médio rodar de primeira ao receber'],
    treino: ['Saída a três contra 2 atacantes', 'Posicionamento entre linhas']
  }
];
