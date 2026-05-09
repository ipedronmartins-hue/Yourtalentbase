// ═══════════════════════════════════════════════════════
// YTB ELITE COACH · CENÁRIOS DATA
// Coordenadas: SVG 500×740 (vertical, ataque para CIMA)
// y=0 → baliza adversária (cima)
// y=740 → baliza própria (baixo)
// ═══════════════════════════════════════════════════════

const CENARIOS = [
  {
    id: 'C01',
    titulo: 'Receber entre linhas pressionado',
    posicao: 'Médio',
    debilidade: 'Decisão sob pressão',
    icon: '🧠',
    cor: '#D4AF37',
    nivel: 'Sub-13+',
    situacao: 'Recebes de costas para a baliza adversária. Tens um adversário a marcar-te de perto. Médio companheiro aproxima-se.',
    duracao: 4500,
    frames: [
      // T0: posição inicial
      { t: 0, players: {
        meu: { x: 250, y: 380, team: 'us', label: 'TU', highlight: true },
        adv: { x: 250, y: 350, team: 'them' },
        apoio: { x: 180, y: 480, team: 'us', label: 'Médio' },
        lateral: { x: 100, y: 350, team: 'us', label: 'Lateral' },
        avante: { x: 250, y: 200, team: 'us', label: 'Avante' }
      }, ball: { owner: 'meu' }, indica: 'Bola chega-te. Adversário nas costas.' },
      // T1500: bola chega
      { t: 1500, players: {
        meu: { x: 250, y: 380, team: 'us', highlight: true },
        adv: { x: 250, y: 360, team: 'them' },
        apoio: { x: 200, y: 460, team: 'us' },
        lateral: { x: 100, y: 350, team: 'us' },
        avante: { x: 250, y: 200, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      // T4500: pause na pose final, esperando decisão
      { t: 4500, players: {
        meu: { x: 250, y: 380, team: 'us', highlight: true },
        adv: { x: 250, y: 360, team: 'them' },
        apoio: { x: 200, y: 460, team: 'us' },
        lateral: { x: 100, y: 350, team: 'us' },
        avante: { x: 250, y: 200, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      {
        id: 'A',
        texto: 'Viras e arriscas',
        certa: false,
        feedback: 'Viraste sob pressão. Perdeste tempo, espaço e bola. O adversário antecipou.',
        consequencia: 'perda'
      },
      {
        id: 'B',
        texto: 'Jogo de primeira no apoio',
        certa: true,
        feedback: 'De primeira, mantiveste a posse. Sem dar tempo ao adversário. Triângulo limpo com o médio companheiro.',
        consequencia: 'sucesso'
      },
      {
        id: 'C',
        texto: 'Protejo e atraso',
        certa: false,
        feedback: 'Atrasaste a equipa. Fizeste a defesa adversária recompor-se. Linha de progressão fechada.',
        consequencia: 'neutro'
      }
    ],
    treino: ['Passe de 1 toque', 'Decisão em 1 segundo', 'Scanning antes de receber'],
    dica: '👁 Olha para os lados ANTES de a bola chegar. Decisão tem de estar tomada.'
  },

  {
    id: 'C02',
    titulo: 'Saída de bola com pressão alta',
    posicao: 'Central / GR',
    debilidade: 'Leitura de jogo',
    icon: '⚽',
    cor: '#4A9FE8',
    nivel: 'Sub-13+',
    situacao: 'GR tem bola. Centrais abertos. Adversário pressiona alto com 2 atacantes.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        gr: { x: 250, y: 680, team: 'us', label: 'GR', highlight: true },
        dc1: { x: 180, y: 600, team: 'us', label: 'DC' },
        dc2: { x: 320, y: 600, team: 'us', label: 'DC' },
        latL: { x: 80, y: 530, team: 'us', label: 'Lat' },
        latR: { x: 420, y: 530, team: 'us', label: 'Lat' },
        adv1: { x: 200, y: 540, team: 'them' },
        adv2: { x: 300, y: 540, team: 'them' },
        med: { x: 250, y: 470, team: 'us', label: 'Méd' }
      }, ball: { owner: 'gr' }, indica: 'GR com bola. 2 atacantes a pressionar.' },
      { t: 1500, players: {
        gr: { x: 250, y: 680, team: 'us', highlight: true },
        dc1: { x: 180, y: 600, team: 'us' },
        dc2: { x: 320, y: 600, team: 'us' },
        latL: { x: 80, y: 540, team: 'us' },
        latR: { x: 420, y: 540, team: 'us' },
        adv1: { x: 210, y: 580, team: 'them' },
        adv2: { x: 290, y: 580, team: 'them' },
        med: { x: 250, y: 460, team: 'us' }
      }, ball: { owner: 'gr' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        gr: { x: 250, y: 680, team: 'us', highlight: true },
        dc1: { x: 180, y: 600, team: 'us' },
        dc2: { x: 320, y: 600, team: 'us' },
        latL: { x: 80, y: 540, team: 'us' },
        latR: { x: 420, y: 540, team: 'us' },
        adv1: { x: 210, y: 580, team: 'them' },
        adv2: { x: 290, y: 580, team: 'them' },
        med: { x: 250, y: 460, team: 'us' }
      }, ball: { owner: 'gr' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Insistir curto entre centrais', certa: false,
        feedback: 'Forçaste curto sem linha de passe limpa. Adversário recupera próximo da baliza.',
        consequencia: 'perda' },
      { id: 'B', texto: 'Bater longo para o avante', certa: false,
        feedback: 'Bola longa sem critério. 80% das bolas longas em formação são perdidas. Cedeste posse.',
        consequencia: 'neutro' },
      { id: 'C', texto: 'Abrir no lateral livre', certa: true,
        feedback: 'Lateral estava livre. Saída limpa pelo corredor. Equipa progride com posse.',
        consequencia: 'sucesso' }
    ],
    treino: ['Passe sob pressão', 'Orientação corporal', 'Visualizar opções antes de receber'],
    dica: '🎯 Quando pressionado, procura o jogador MAIS LIVRE, não o mais próximo.'
  },

  {
    id: 'C03',
    titulo: 'Extremo em 1x1 na ala',
    posicao: 'Extremo',
    debilidade: 'Decisão ofensiva',
    icon: '🏃',
    cor: '#E05050',
    nivel: 'Sub-12+',
    situacao: 'Recebes na ala isolado. Lateral adversário pela frente. Espaço para acelerar.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        meu: { x: 80, y: 350, team: 'us', label: 'TU', highlight: true },
        adv: { x: 100, y: 280, team: 'them' },
        avante: { x: 250, y: 200, team: 'us', label: 'Av' },
        med: { x: 250, y: 400, team: 'us', label: 'Méd' }
      }, ball: { owner: 'meu' }, indica: 'Recebes na ala. 1x1 com lateral.' },
      { t: 1500, players: {
        meu: { x: 80, y: 320, team: 'us', highlight: true },
        adv: { x: 100, y: 280, team: 'them' },
        avante: { x: 240, y: 180, team: 'us' },
        med: { x: 250, y: 380, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        meu: { x: 80, y: 320, team: 'us', highlight: true },
        adv: { x: 100, y: 280, team: 'them' },
        avante: { x: 240, y: 180, team: 'us' },
        med: { x: 250, y: 380, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Drible: ir para cima do defesa', certa: true,
        feedback: 'Ir para cima cria desequilíbrio. Defesa adversária tem de ajustar. Geras superioridade.',
        consequencia: 'sucesso' },
      { id: 'B', texto: 'Cruzar logo', certa: false,
        feedback: 'Cruzaste sem desequilíbrio criado. Defesa organizada. Cruzamento previsível.',
        consequencia: 'neutro' },
      { id: 'C', texto: 'Atrasar para o médio', certa: false,
        feedback: 'Atrasaste. Perdeste vantagem do isolamento. Defesa recompôs-se.',
        consequencia: 'neutro' }
    ],
    treino: ['Drible em espaço curto', 'Explosão no primeiro passo', 'Mudança de direção'],
    dica: '⚡ Isolado na ala? Vai para cima. É o teu momento.'
  },

  {
    id: 'C04',
    titulo: 'Finalização à entrada da área',
    posicao: 'Avançado',
    debilidade: 'Timing de remate',
    icon: '🎯',
    cor: '#4AE87A',
    nivel: 'Sub-12+',
    situacao: 'Bola chega-te à entrada da área, em jeito. Defesa adversária próxima. Espaço pequeno.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        meu: { x: 250, y: 200, team: 'us', label: 'TU', highlight: true },
        adv: { x: 220, y: 240, team: 'them' },
        passador: { x: 350, y: 280, team: 'us', label: 'Apoio' }
      }, ball: { owner: 'passador' }, indica: 'Apoio com bola. Vai chegar-te.' },
      { t: 1200, players: {
        meu: { x: 250, y: 200, team: 'us', highlight: true },
        adv: { x: 220, y: 230, team: 'them' },
        passador: { x: 350, y: 280, team: 'us' }
      }, ball: { x: 300, y: 245 }, indica: 'Bola a chegar...' },
      { t: 2200, players: {
        meu: { x: 250, y: 200, team: 'us', highlight: true },
        adv: { x: 230, y: 220, team: 'them' },
        passador: { x: 350, y: 280, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        meu: { x: 250, y: 200, team: 'us', highlight: true },
        adv: { x: 230, y: 220, team: 'them' },
        passador: { x: 350, y: 280, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Rematar de primeira', certa: true,
        feedback: 'Remate de primeira surpreendeu o GR. Defesa não conseguiu bloquear. Perigo real.',
        consequencia: 'sucesso' },
      { id: 'B', texto: 'Dominar e ajeitar', certa: false,
        feedback: 'Perdeste timing. Defesa fechou o ângulo. Remate bloqueado.',
        consequencia: 'neutro' },
      { id: 'C', texto: 'Passar para apoio', certa: false,
        feedback: 'Devolveste a bola a posição mais distante da baliza. Oportunidade desperdiçada.',
        consequencia: 'neutro' }
    ],
    treino: ['Remate de primeira', 'Coordenação ao remate', 'Decisão rápida na área'],
    dica: '🎯 Na área, a primeira intenção é sempre rematar. Ajeitar é perder oportunidade.'
  },

  {
    id: 'C05',
    titulo: 'Transição defensiva',
    posicao: 'Todos',
    debilidade: 'Reação à perda',
    icon: '🔁',
    cor: '#E05050',
    nivel: 'Sub-13+',
    situacao: 'Acabaste de perder a bola no meio-campo. Adversário tem 2 segundos para organizar contra-ataque.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        meu: { x: 250, y: 380, team: 'us', label: 'TU', highlight: true },
        adv1: { x: 240, y: 360, team: 'them' },
        adv2: { x: 320, y: 320, team: 'them' },
        adv3: { x: 180, y: 280, team: 'them' },
        meu2: { x: 350, y: 450, team: 'us' },
        meu3: { x: 150, y: 450, team: 'us' }
      }, ball: { owner: 'adv1' }, indica: 'Acabaste de perder a bola.' },
      { t: 1500, players: {
        meu: { x: 250, y: 380, team: 'us', highlight: true },
        adv1: { x: 240, y: 340, team: 'them' },
        adv2: { x: 320, y: 280, team: 'them' },
        adv3: { x: 180, y: 250, team: 'them' },
        meu2: { x: 350, y: 450, team: 'us' },
        meu3: { x: 150, y: 450, team: 'us' }
      }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        meu: { x: 250, y: 380, team: 'us', highlight: true },
        adv1: { x: 240, y: 340, team: 'them' },
        adv2: { x: 320, y: 280, team: 'them' },
        adv3: { x: 180, y: 250, team: 'them' },
        meu2: { x: 350, y: 450, team: 'us' },
        meu3: { x: 150, y: 450, team: 'us' }
      }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Pressionar imediatamente o portador', certa: true,
        feedback: 'Pressão imediata travou o contra-ataque. Adversário forçou passe errado. Recuperaste a bola em zona alta.',
        consequencia: 'sucesso' },
      { id: 'B', texto: 'Recuar para zona defensiva', certa: false,
        feedback: 'Recuaste. Deste tempo ao adversário organizar. Contra-ataque chega à tua área.',
        consequencia: 'perda' },
      { id: 'C', texto: 'Ficar parado a olhar', certa: false,
        feedback: 'Não reagiste. Adversário avançou 30m sem oposição. Equipa em desvantagem numérica.',
        consequencia: 'perda' }
    ],
    treino: ['Reação rápida pós-perda (5 segundos)', 'Sprint curto', 'Pressão coordenada'],
    dica: '⚡ Os 5 segundos após a perda são DECISIVOS. Pressão total.'
  },

  {
    id: 'C06',
    titulo: 'Defesa em inferioridade (2v1)',
    posicao: 'Defesa',
    debilidade: 'Posicionamento defensivo',
    icon: '🧱',
    cor: '#4A9FE8',
    nivel: 'Sub-12+',
    situacao: 'Sozinho contra 2 atacantes. Eles aproximam-se da tua área.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        meu: { x: 250, y: 480, team: 'us', label: 'TU', highlight: true },
        adv1: { x: 220, y: 380, team: 'them' },
        adv2: { x: 320, y: 400, team: 'them' }
      }, ball: { owner: 'adv1' }, indica: '2 contra 1. Eles chegam.' },
      { t: 1500, players: {
        meu: { x: 250, y: 480, team: 'us', highlight: true },
        adv1: { x: 230, y: 410, team: 'them' },
        adv2: { x: 330, y: 420, team: 'them' }
      }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        meu: { x: 250, y: 480, team: 'us', highlight: true },
        adv1: { x: 230, y: 410, team: 'them' },
        adv2: { x: 330, y: 420, team: 'them' }
      }, ball: { owner: 'adv1' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Atacar o portador da bola', certa: false,
        feedback: 'Foste ao portador. Ele passou para o companheiro livre. Golo iminente.',
        consequencia: 'perda' },
      { id: 'B', texto: 'Fechar a linha de passe', certa: true,
        feedback: 'Fechaste a linha de passe entre os dois. Forçaste o portador a decidir sozinho. Ganhaste tempo para o apoio chegar.',
        consequencia: 'sucesso' },
      { id: 'C', texto: 'Recuar para a linha', certa: false,
        feedback: 'Recuaste demasiado. Atacantes ganharam espaço para acelerar. Situação piorou.',
        consequencia: 'neutro' }
    ],
    treino: ['Leitura defensiva', 'Posicionamento entre atacantes', 'Ganhar tempo'],
    dica: '🛡 Em 2v1, a tua missão é GANHAR TEMPO. Não é roubar a bola — é atrasar.'
  },

  {
    id: 'C07',
    titulo: 'Médio a sair de pressão',
    posicao: 'Médio',
    debilidade: 'Controlo + decisão',
    icon: '🔄',
    cor: '#D4AF37',
    nivel: 'Sub-13+',
    situacao: 'Recebes no meio-campo com adversário a 2m. Tens 1 segundo para decidir.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        meu: { x: 250, y: 400, team: 'us', label: 'TU', highlight: true },
        adv: { x: 250, y: 370, team: 'them' },
        passador: { x: 250, y: 550, team: 'us', label: 'DC' },
        apoio: { x: 380, y: 380, team: 'us', label: 'Apoio' },
        avante: { x: 250, y: 200, team: 'us', label: 'Av' }
      }, ball: { owner: 'passador' }, indica: 'Bola a chegar do central.' },
      { t: 1200, players: {
        meu: { x: 250, y: 400, team: 'us', highlight: true },
        adv: { x: 250, y: 370, team: 'them' },
        passador: { x: 250, y: 550, team: 'us' },
        apoio: { x: 380, y: 380, team: 'us' },
        avante: { x: 250, y: 200, team: 'us' }
      }, ball: { x: 250, y: 470 }, indica: 'Adversário a chegar...' },
      { t: 2200, players: {
        meu: { x: 250, y: 400, team: 'us', highlight: true },
        adv: { x: 250, y: 370, team: 'them' },
        passador: { x: 250, y: 550, team: 'us' },
        apoio: { x: 380, y: 380, team: 'us' },
        avante: { x: 250, y: 200, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        meu: { x: 250, y: 400, team: 'us', highlight: true },
        adv: { x: 250, y: 370, team: 'them' },
        passador: { x: 250, y: 550, team: 'us' },
        apoio: { x: 380, y: 380, team: 'us' },
        avante: { x: 250, y: 200, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Rodar e tentar virar', certa: false,
        feedback: 'Rodaste sem espaço. Adversário antecipou e roubou. Bola perdida em zona perigosa.',
        consequencia: 'perda' },
      { id: 'B', texto: 'Toque de primeira no apoio livre', certa: true,
        feedback: 'Primeiro toque seguro. Bola circulou. Mantiveste posse e equipa progrediu.',
        consequencia: 'sucesso' },
      { id: 'C', texto: 'Tentar conduzir', certa: false,
        feedback: 'Conduziste com adversário em cima. Perdeste bola após 2 metros.',
        consequencia: 'perda' }
    ],
    treino: ['Controlo orientado', 'Jogo a 2 toques', 'Decisão pré-receção'],
    dica: '🎯 Pressionado? PRIMEIRO TOQUE SAFE. Heroísmo é para outro dia.'
  },

  {
    id: 'C08',
    titulo: 'Cruzamento na ala',
    posicao: 'Extremo / Lateral',
    debilidade: 'Qualidade de decisão',
    icon: '📐',
    cor: '#4A9FE8',
    nivel: 'Sub-13+',
    situacao: 'Chegas à linha de fundo com bola. Vês a área. Tens de decidir.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        meu: { x: 80, y: 220, team: 'us', label: 'TU', highlight: true },
        adv: { x: 130, y: 230, team: 'them' },
        av1: { x: 220, y: 150, team: 'us', label: 'Av' },
        av2: { x: 290, y: 100, team: 'us', label: 'Av' },
        med: { x: 280, y: 280, team: 'us', label: 'Méd' }
      }, ball: { owner: 'meu' }, indica: 'Tens bola na linha de fundo.' },
      { t: 1500, players: {
        meu: { x: 80, y: 220, team: 'us', highlight: true },
        adv: { x: 130, y: 230, team: 'them' },
        av1: { x: 230, y: 140, team: 'us' },
        av2: { x: 300, y: 95, team: 'us' },
        med: { x: 290, y: 270, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        meu: { x: 80, y: 220, team: 'us', highlight: true },
        adv: { x: 130, y: 230, team: 'them' },
        av1: { x: 230, y: 140, team: 'us' },
        av2: { x: 300, y: 95, team: 'us' },
        med: { x: 290, y: 270, team: 'us' }
      }, ball: { owner: 'meu' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Cruzar imediatamente', certa: false,
        feedback: 'Cruzaste sem alvo definido. Bola sem destino. Defesa afastou facilmente.',
        consequencia: 'neutro' },
      { id: 'B', texto: 'Esperar apoio chegar', certa: true,
        feedback: 'Esperaste 1 segundo. Apoio chegou. Cruzamento com 2 alvos na área. Probabilidade de golo subiu 3x.',
        consequencia: 'sucesso' },
      { id: 'C', texto: 'Cortar para dentro', certa: false,
        feedback: 'Cortaste mas defesa estava organizada. Espaço fechado. Sem ângulo de remate.',
        consequencia: 'neutro' }
    ],
    treino: ['Cruzamento com alvo', 'Leitura ofensiva', 'Paciência na decisão'],
    dica: '⏱ Cruzar não é sempre primeira opção. Espera 1s, vê quem está na área.'
  },

  {
    id: 'C09',
    titulo: 'Desmarcação em profundidade',
    posicao: 'Avançado / Extremo',
    debilidade: 'Timing de movimento',
    icon: '🚀',
    cor: '#4AE87A',
    nivel: 'Sub-12+',
    situacao: 'Defesa adversária subida, espaço nas costas. Médio com bola olha para ti.',
    duracao: 5000,
    frames: [
      { t: 0, players: {
        meu: { x: 250, y: 280, team: 'us', label: 'TU', highlight: true },
        passador: { x: 250, y: 480, team: 'us', label: 'Méd' },
        dc1: { x: 200, y: 200, team: 'them' },
        dc2: { x: 300, y: 200, team: 'them' }
      }, ball: { owner: 'passador' }, indica: 'Defesa subida. Espaço nas costas.' },
      { t: 1800, players: {
        meu: { x: 250, y: 250, team: 'us', highlight: true },
        passador: { x: 250, y: 470, team: 'us' },
        dc1: { x: 200, y: 200, team: 'them' },
        dc2: { x: 300, y: 200, team: 'them' }
      }, ball: { owner: 'passador' }, indica: 'O QUE FAZES?' },
      { t: 5000, players: {
        meu: { x: 250, y: 250, team: 'us', highlight: true },
        passador: { x: 250, y: 470, team: 'us' },
        dc1: { x: 200, y: 200, team: 'them' },
        dc2: { x: 300, y: 200, team: 'them' }
      }, ball: { owner: 'passador' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Arrancar imediatamente', certa: false,
        feedback: 'Arrancaste cedo demais. Defesa ajustou. Fora-de-jogo marcado.',
        consequencia: 'neutro' },
      { id: 'B', texto: 'Esperar momento certo, arrancar com bola', certa: true,
        feedback: 'Timing perfeito. Sincronizaste com o passe. Saíste em rutura, bola direta para a baliza.',
        consequencia: 'sucesso' },
      { id: 'C', texto: 'Não fazer movimento', certa: false,
        feedback: 'Ficaste estático. Médio teve de jogar atrás. Oportunidade desperdiçada.',
        consequencia: 'neutro' }
    ],
    treino: ['Timing de corrida', 'Leitura linha defensiva', 'Sincronização com passador'],
    dica: '⏱ Desmarcação = sincronização. Move quando o passe sai, não antes.'
  },

  {
    id: 'C10',
    titulo: 'Apoio ao portador',
    posicao: 'Todos',
    debilidade: 'Inteligência sem bola',
    icon: '🧠',
    cor: '#D4AF37',
    nivel: 'Sub-12+',
    situacao: 'Companheiro tem bola, está pressionado. Tu estás a 15m, posição neutra.',
    duracao: 4500,
    frames: [
      { t: 0, players: {
        meu: { x: 380, y: 400, team: 'us', label: 'TU', highlight: true },
        portador: { x: 250, y: 400, team: 'us', label: 'Colega' },
        adv1: { x: 250, y: 370, team: 'them' },
        adv2: { x: 320, y: 350, team: 'them' }
      }, ball: { owner: 'portador' }, indica: 'Colega com bola, pressionado.' },
      { t: 1500, players: {
        meu: { x: 380, y: 400, team: 'us', highlight: true },
        portador: { x: 250, y: 400, team: 'us' },
        adv1: { x: 250, y: 380, team: 'them' },
        adv2: { x: 320, y: 360, team: 'them' }
      }, ball: { owner: 'portador' }, indica: 'O QUE FAZES?' },
      { t: 4500, players: {
        meu: { x: 380, y: 400, team: 'us', highlight: true },
        portador: { x: 250, y: 400, team: 'us' },
        adv1: { x: 250, y: 380, team: 'them' },
        adv2: { x: 320, y: 360, team: 'them' }
      }, ball: { owner: 'portador' }, indica: 'O QUE FAZES?' }
    ],
    opcoes: [
      { id: 'A', texto: 'Aproximar e dar linha de passe', certa: true,
        feedback: 'Aproximaste e ofereceste solução. Colega tabelou contigo. Saída limpa da pressão.',
        consequencia: 'sucesso' },
      { id: 'B', texto: 'Ficar parado a observar', certa: false,
        feedback: 'Ficaste estático. Colega isolado. Bola perdida sob pressão.',
        consequencia: 'perda' },
      { id: 'C', texto: 'Afastar para dar profundidade', certa: false,
        feedback: 'Afastaste demais. Linha de passe muito longa. Adversário interceptou.',
        consequencia: 'perda' }
    ],
    treino: ['Movimentação sem bola', 'Apoio curto (5-10m)', 'Leitura da pressão'],
    dica: '🧭 Companheiro pressionado? APROXIMA. Não fiques à espera.'
  }
];
