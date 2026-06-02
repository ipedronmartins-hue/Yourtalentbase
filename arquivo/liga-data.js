// ═══════════════════════════════════════════════════════
// YTB LEAGUE · DATA
// Questionário, nomes, formações, cenários de jogo
// ═══════════════════════════════════════════════════════

// ─── ESCALÕES ──────────────────────────────────────────
const ESCALOES = [
  { id: 'sub9', nome: 'Sub-9', idade_min: 7, idade_max: 9 },
  { id: 'sub10', nome: 'Sub-10', idade_min: 8, idade_max: 10 },
  { id: 'sub11', nome: 'Sub-11', idade_min: 9, idade_max: 11 },
  { id: 'sub12', nome: 'Sub-12', idade_min: 10, idade_max: 12 },
  { id: 'sub13', nome: 'Sub-13', idade_min: 11, idade_max: 13 },
  { id: 'sub14', nome: 'Sub-14', idade_min: 12, idade_max: 14 },
  { id: 'sub15', nome: 'Sub-15', idade_min: 13, idade_max: 15 },
  { id: 'sub16', nome: 'Sub-16', idade_min: 14, idade_max: 16 },
  { id: 'sub17', nome: 'Sub-17', idade_min: 15, idade_max: 17 },
  { id: 'sub19', nome: 'Sub-19', idade_min: 16, idade_max: 19 }
];

// ─── POSIÇÕES NO CAMPO ─────────────────────────────────
const POSICOES = [
  { id: 'GR', nome: 'Guarda-Redes', x: 250, y: 670 },
  { id: 'DC', nome: 'Defesa Central', x: 200, y: 580 },
  { id: 'LD', nome: 'Lateral Direito', x: 400, y: 550 },
  { id: 'LE', nome: 'Lateral Esquerdo', x: 100, y: 550 },
  { id: 'MD', nome: 'Médio Defensivo', x: 250, y: 460 },
  { id: 'MC', nome: 'Médio Centro', x: 250, y: 380 },
  { id: 'MO', nome: 'Médio Ofensivo', x: 250, y: 290 },
  { id: 'ED', nome: 'Extremo Direito', x: 400, y: 250 },
  { id: 'EE', nome: 'Extremo Esquerdo', x: 100, y: 250 },
  { id: 'PL', nome: 'Ponta-de-Lança', x: 250, y: 150 }
];

// ─── QUESTIONÁRIO INICIAL (6 perguntas) ────────────────
// 4 cenários tácticos + 1 comportamento + 1 auto-avaliação
const QUESTIONARIO = [
  {
    id: 'q1_pos',
    tipo: 'posicao',  // selector visual
    pergunta: 'Onde gostas mais de jogar?',
    sub: 'Toca no campo na posição preferida'
  },
  {
    id: 'q2_pressao',
    tipo: 'cenario',
    pergunta: 'Recebes a bola de costas para a baliza. Tens um adversário em cima.',
    sub: 'O que fazes?',
    opcoes: [
      { id: 'A', texto: 'Viro e arrisco', score: 0 },
      { id: 'B', texto: 'Jogo de primeira no apoio', score: 10 },
      { id: 'C', texto: 'Protejo e atraso', score: 5 }
    ]
  },
  {
    id: 'q3_1v1',
    tipo: 'cenario',
    pergunta: 'Estás isolado no 1×1 contra o lateral, na faixa.',
    sub: 'O que fazes?',
    opcoes: [
      { id: 'A', texto: 'Vou para cima dele', score: 10 },
      { id: 'B', texto: 'Cruzo logo', score: 5 },
      { id: 'C', texto: 'Atraso para o médio', score: 0 }
    ]
  },
  {
    id: 'q4_perda',
    tipo: 'cenario',
    pergunta: 'Acabaste de perder a bola no miolo.',
    sub: 'O que fazes?',
    opcoes: [
      { id: 'A', texto: 'Pressiono imediatamente', score: 10 },
      { id: 'B', texto: 'Recuo para a defesa', score: 5 },
      { id: 'C', texto: 'Espero ver o que acontece', score: 0 }
    ]
  },
  {
    id: 'q5_mental',
    tipo: 'comportamento',
    pergunta: 'A tua equipa está a perder 0-2 ao intervalo.',
    sub: 'O que fazes?',
    opcoes: [
      { id: 'A', texto: 'Falo com os colegas a virar o jogo', score: 10 },
      { id: 'B', texto: 'Foco-me só no meu jogo', score: 5 },
      { id: 'C', texto: 'Fico chateado e desligo', score: 0 }
    ]
  },
  {
    id: 'q6_foco',
    tipo: 'foco',
    pergunta: 'O que mais sentes que precisas de melhorar?',
    sub: 'A IA usa isto para criar a tua equipa',
    opcoes: [
      { id: 'tecnica', texto: 'Técnica · passe · drible', icon: '⚽' },
      { id: 'fisico', texto: 'Físico · velocidade', icon: '💨' },
      { id: 'tactica', texto: 'Decisão · leitura de jogo', icon: '🧠' },
      { id: 'mental', texto: 'Confiança · liderança', icon: '🔥' }
    ]
  }
];

// ─── NOMES ENGRAÇADOS PARA COLEGAS FICTÍCIOS ──────────
// Mistura de alcunhas reais portuguesas + criativas
const NOMES_FUNNY = {
  GR: ['Mãos de Aço', 'Gato', 'Pegão', 'O Polvo', 'Reflexo'],
  DC: ['Muralha', 'Granito', 'O Touro', 'Cabeção', 'Tanque'],
  LD: ['Foguete', 'Vento', 'Hélice', 'Foguetão', 'Asa'],
  LE: ['Trovão', 'Relâmpago', 'Furacão', 'Tornado', 'Bólide'],
  MD: ['Cérebro', 'O Capitão', 'Trinco', 'Patrão', 'O Sábio'],
  MC: ['Maestro', 'Picasso', 'Mozart', 'Génio', 'Visionário'],
  MO: ['Mago', 'Magneto', 'Stilo', 'Camaleão', 'Surpresa'],
  ED: ['Drible', 'Bicicleta', 'Tornado D', 'Mascarado', 'Foguete D'],
  EE: ['Galáctico', 'Sombra', 'Fantasma', 'Bisturi', 'Tornado E'],
  PL: ['Killer', 'Pistola', 'Tiro Certo', 'Mata-Mata', 'Bisturi']
};

// ─── FORMAÇÕES ─────────────────────────────────────────
const FORMACOES = {
  '4-3-3': {
    nome: '4-3-3',
    descricao: 'Equilibrado · ofensivo · 3 atacantes',
    posicoes: [
      { pos: 'GR', x: 250, y: 670 },
      { pos: 'LD', x: 400, y: 560 },
      { pos: 'DC', x: 310, y: 580 },
      { pos: 'DC', x: 190, y: 580 },
      { pos: 'LE', x: 100, y: 560 },
      { pos: 'MD', x: 250, y: 470 },
      { pos: 'MC', x: 170, y: 400 },
      { pos: 'MC', x: 330, y: 400 },
      { pos: 'ED', x: 400, y: 250 },
      { pos: 'PL', x: 250, y: 180 },
      { pos: 'EE', x: 100, y: 250 }
    ]
  },
  '4-4-2': {
    nome: '4-4-2',
    descricao: 'Clássico · sólido · 2 atacantes',
    posicoes: [
      { pos: 'GR', x: 250, y: 670 },
      { pos: 'LD', x: 400, y: 560 },
      { pos: 'DC', x: 310, y: 580 },
      { pos: 'DC', x: 190, y: 580 },
      { pos: 'LE', x: 100, y: 560 },
      { pos: 'MD', x: 400, y: 420 },
      { pos: 'MC', x: 310, y: 420 },
      { pos: 'MC', x: 190, y: 420 },
      { pos: 'ME', x: 100, y: 420 },
      { pos: 'PL', x: 310, y: 200 },
      { pos: 'PL', x: 190, y: 200 }
    ]
  },
  '4-2-3-1': {
    nome: '4-2-3-1',
    descricao: 'Moderno · meio forte · 1 avançado',
    posicoes: [
      { pos: 'GR', x: 250, y: 670 },
      { pos: 'LD', x: 400, y: 560 },
      { pos: 'DC', x: 310, y: 580 },
      { pos: 'DC', x: 190, y: 580 },
      { pos: 'LE', x: 100, y: 560 },
      { pos: 'MD', x: 310, y: 470 },
      { pos: 'MD', x: 190, y: 470 },
      { pos: 'MO', x: 400, y: 320 },
      { pos: 'MO', x: 250, y: 290 },
      { pos: 'MO', x: 100, y: 320 },
      { pos: 'PL', x: 250, y: 170 }
    ]
  }
};

// ─── ESTILOS DE JOGO ───────────────────────────────────
const ESTILOS = [
  { id: 'defensivo', nome: 'Defensivo', icon: '🛡️', desc: 'Bloco baixinho, contra-ataque' },
  { id: 'equilibrado', nome: 'Equilibrado', icon: '⚖️', desc: 'Joga conforme o momento' },
  { id: 'ofensivo', nome: 'Ofensivo', icon: '🔥', desc: 'Pressing alto, posse, ataque' }
];

// ─── CENÁRIOS DE JOGO (FASE 2 — MOTOR) ─────────────────
// 10 momentos sequenciais com decisões A/B/C
// Cada um adaptado ao minuto, contexto, com pontos
const CENARIOS_JOGO = [
  {
    id: 'L01', minuto: 8, fase: 'inicio',
    situacao: 'Saída de bola contra pressão alta',
    contexto: 'O bloco deles morde com 2 atacantes nos centrais.',
    opcoes: [
      { id: 'A', texto: 'GR bate longo para o PL', pts: -2, fb: 'Bola perdida no ar.', tipo: 'erro' },
      { id: 'B', texto: 'Abre no LD livre na faixa', pts: 8, fb: 'Saída limpa pelo corredor.', tipo: 'acerto' },
      { id: 'C', texto: 'Insiste curto entre centrais', pts: -4, fb: 'Pressão recupera bola perto da área.', tipo: 'erro' }
    ]
  },
  {
    id: 'L02', minuto: 18, fase: 'inicio',
    situacao: 'Recebes entre linhas pressionado',
    contexto: 'O MD deles vem por trás. Tens 1 segundo.',
    opcoes: [
      { id: 'A', texto: 'Roda e tenta virar', pts: -3, fb: 'Bola roubada, contra-ataque deles.', tipo: 'erro' },
      { id: 'B', texto: 'Toque de primeira no MC', pts: 8, fb: 'Mantém-se a posse, equipa progride.', tipo: 'acerto' },
      { id: 'C', texto: 'Tenta conduzir', pts: -2, fb: 'Conduzes 2m, perdes.', tipo: 'erro' }
    ]
  },
  {
    id: 'L03', minuto: 26, fase: 'meio',
    situacao: 'Transição rápida após recuperação',
    contexto: 'Acabaste de recuperar no miolo. O bloco deles ainda não está organizado.',
    opcoes: [
      { id: 'A', texto: 'Passe vertical para o PL em rutura', pts: 10, fb: 'PL recebe sozinho! Ocasião clara.', tipo: 'acerto' },
      { id: 'B', texto: 'Segura a bola e organiza', pts: 0, fb: 'Defesa adversária recompõe-se. Oportunidade perdida.', tipo: 'neutro' },
      { id: 'C', texto: 'Passa para o lateral', pts: 2, fb: 'Lateral progride mas jogada lenta.', tipo: 'neutro' }
    ]
  },
  {
    id: 'L04', minuto: 34, fase: 'meio',
    situacao: 'Extremo isolado na faixa',
    contexto: 'O ED tem espaço, 1×1 com o LE deles.',
    opcoes: [
      { id: 'A', texto: 'Vai para cima do defesa', pts: 8, fb: 'Desequilíbrio. Defesa tem de ajustar.', tipo: 'acerto' },
      { id: 'B', texto: 'Cruza imediatamente', pts: 2, fb: 'Cruzamento previsível. Defesa afasta.', tipo: 'neutro' },
      { id: 'C', texto: 'Atrasa para o MC', pts: 0, fb: 'Perdeste a vantagem do isolamento.', tipo: 'neutro' }
    ]
  },
  {
    id: 'L05', minuto: 43, fase: 'meio',
    situacao: 'Canto a favor — primeira parte termina em 2 minutos',
    contexto: 'Tens canto à esquerda. O resultado está em 0-0.',
    opcoes: [
      { id: 'A', texto: 'Cruzamento à primeira', pts: 5, fb: 'Boa bola, mas defesa afasta.', tipo: 'acerto' },
      { id: 'B', texto: 'Esquema curto', pts: 8, fb: 'Surpresa! Cruzamento da curva, perigo real.', tipo: 'acerto' },
      { id: 'C', texto: 'Bater à área para cabecear', pts: 3, fb: 'Bola alta, mas defesa ganha o lance.', tipo: 'neutro' }
    ]
  },
  {
    id: 'L06', minuto: 56, fase: 'fim',
    situacao: 'Defesa em inferioridade — eles têm 2v1 a chegar',
    contexto: 'O DC está sozinho contra 2 atacantes. Aproximam-se da grande área.',
    opcoes: [
      { id: 'A', texto: 'Atacar o portador', pts: -5, fb: 'Passou para o livre. Golo deles!', tipo: 'erro' },
      { id: 'B', texto: 'Fechar a linha de passe', pts: 8, fb: 'Forçaste o portador a decidir. Ganhaste tempo.', tipo: 'acerto' },
      { id: 'C', texto: 'Recuar para a linha', pts: -2, fb: 'Atacantes ganharam espaço.', tipo: 'erro' }
    ]
  },
  {
    id: 'L07', minuto: 64, fase: 'fim',
    situacao: 'Substituição estratégica',
    contexto: 'Estás 1-0 a ganhar. Faltam 25 minutos. O PL está cansado.',
    opcoes: [
      { id: 'A', texto: 'Tira o PL, mete um MC defensivo', pts: 5, fb: 'Fechas o jogo. Bloco baixinho.', tipo: 'acerto' },
      { id: 'B', texto: 'Tira o PL, mete outro PL fresco', pts: 7, fb: 'Mantens a ameaça ofensiva.', tipo: 'acerto' },
      { id: 'C', texto: 'Não mexes', pts: 0, fb: 'PL cansa-se, perde lances.', tipo: 'neutro' }
    ]
  },
  {
    id: 'L08', minuto: 73, fase: 'fim',
    situacao: 'O adversário pressiona com bloco alto',
    contexto: 'Estão a 1-0 a perder. Vêm com tudo para cima. A tua malta está sob pressão.',
    opcoes: [
      { id: 'A', texto: 'Aguentar bloco baixinho e contra-atacar', pts: 8, fb: 'Saída perfeita. Quase fizeste o 2-0.', tipo: 'acerto' },
      { id: 'B', texto: 'Subir a linha para empurrá-los', pts: -3, fb: 'Buraco nas costas. Eles aproveitam.', tipo: 'erro' },
      { id: 'C', texto: 'Insistir em ter bola no miolo', pts: -1, fb: 'Perdes bolas no miolo. Pressão sobe.', tipo: 'neutro' }
    ]
  },
  {
    id: 'L09', minuto: 81, fase: 'fim',
    situacao: 'Livre directo a 22m da baliza adversária',
    contexto: 'O empate seria mau resultado. Tens um livre interessante.',
    opcoes: [
      { id: 'A', texto: 'Remate directo', pts: 6, fb: 'Bola na barreira, mas grande oportunidade.', tipo: 'acerto' },
      { id: 'B', texto: 'Passar para o PL que enfia em rutura', pts: 9, fb: 'PL fica frente à baliza! Quase golo.', tipo: 'acerto' },
      { id: 'C', texto: 'Cruzar para a área', pts: 3, fb: 'Cruzamento previsível, defesa afasta.', tipo: 'neutro' }
    ]
  },
  {
    id: 'L10', minuto: 89, fase: 'fim',
    situacao: 'Falta perigosa contra a tua equipa',
    contexto: 'Última jogada do jogo. Falta a 25m da tua baliza. Eles vão tentar.',
    opcoes: [
      { id: 'A', texto: 'Barreira de 4, GR ao 1º poste', pts: 7, fb: 'Cobertura sólida. GR defende.', tipo: 'acerto' },
      { id: 'B', texto: 'Barreira de 3, GR central', pts: 3, fb: 'Margem para o remate, mas GR esticou-se.', tipo: 'neutro' },
      { id: 'C', texto: 'Sem barreira, marcação na área', pts: -3, fb: 'Remate sem oposição. Quase 2-0!', tipo: 'erro' }
    ]
  }
];

// ─── ADVERSÁRIOS IA (nomes engraçados para equipas fictícias) ──
const NOMES_EQUIPAS_IA = [
  'Os Tigres do Asfalto', 'Bola Mágica FC', 'União Pampilhosa',
  'Os Foguetes do Norte', 'CD Adro da Igreja', 'Os Lobos da Charneca',
  'Atlético do Bairro', 'Os Pumas Veteranos', 'CF Garopaba',
  'Sporting do Bairro', 'Os Touros Indomáveis', 'Real Calçada'
];

// ─── COMENTÁRIO IA PRÉ-JOGO (template) ─────────────────
const FRASES_IA_PREJOGO = [
  "Vais jogar contra {ADV}. Para te bater, eu jogaria {FORM} com bloco {ESTILO}. Vou tentar morder na faixa direita. Mesmo assim, vou-te ganhar.",
  "Hoje é {ADV}. A minha táctica é {FORM} com pressing alto. A tua malta vai sofrer. Vamos ver se aguentas.",
  "Joga {ADV}. Vou em {FORM}, equilibrado. Mas atenção: vou explorar o buraco entre o teu MD e o DC. Estás avisado.",
  "{ADV} vs {VOCE}. Eu em {FORM}, vou bloco baixinho e contra-ataque. A tua malta vai-se cansar a atacar. Boa sorte.",
  "Hoje vais contra {ADV}. Faço {FORM}, mas vou apertar nas faixas. Se subires os laterais, abro-te a defesa. Vê lá."
];
