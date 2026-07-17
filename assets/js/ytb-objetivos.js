/* ═══════════════════════════════════════════════════════════════════
   YTB · OBJETIVOS — a ponte entre debilidades, missões e cenários
   ───────────────────────────────────────────────────────────────────
   O atleta não vê "planos de treino"; vê UM objetivo ("Decidir mais
   rápido sob pressão") e as missões da semana ao serviço dele. Este
   ficheiro é a única fonte do vocabulário de objetivos e do mapa que
   une os 3 vocabulários de debilidade que existem no código:
     1. os 5 buckets vivos do plano do treinador
        (tecnica/fisico/decisao/tatica/mental — ytb-pro-treinador.html)
     2. as strings livres dos CENARIOS do Elite Coach
        ("Decisão sob pressão", "Leitura de jogo", …)
     3. (o vocabulário do pais.html morto ignora-se — página sem entrada)
   Padrão IIFE→global como ytb-export.js. Sem dependências.
   ═══════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  // bucket → objetivo humano. É isto que a família lê. Verbos, não jargão.
  var OBJETIVOS = {
    tecnica: {
      titulo: 'Dominar a bola ao primeiro toque',
      sub: 'Receção, condução e pé fraco — a bola passa a obedecer.',
      verbo: 'controlar a bola sob pressão',
      icon: '⚽'
    },
    decisao: {
      titulo: 'Decidir mais rápido sob pressão',
      sub: 'Ver antes de receber. Escolher em menos de um segundo.',
      verbo: 'decidir depressa quando pressionado',
      icon: '🧠'
    },
    tatica: {
      titulo: 'Ler o jogo e estar no sítio certo',
      sub: 'Posicionamento, timing e jogo sem bola.',
      verbo: 'posicionar-te e ler o jogo',
      icon: '🧭'
    },
    fisico: {
      titulo: 'Mais rápido, mais forte, mais tempo',
      sub: 'Velocidade, agilidade e resistência ao teu ritmo de crescimento.',
      verbo: 'aguentar o ritmo físico do jogo',
      icon: '⚡'
    },
    mental: {
      titulo: 'Confiança e foco nos momentos grandes',
      sub: 'Reagir ao erro, manter a cabeça no jogo.',
      verbo: 'manter a confiança nos momentos difíceis',
      icon: '🔥'
    }
  };

  // string de CENARIOS[].debilidade (elite-coach-data.js) → bucket.
  // Cobertura completa das 18 strings reais (levantadas por script em
  // 2026-07-16); qualquer string nova cai no fallback por palavras-chave.
  var CENARIO_DEB = {
    'Decisão sob pressão': 'decisao',
    'Leitura de jogo': 'tatica',
    'Decisão ofensiva': 'decisao',
    'Timing de remate': 'decisao',
    'Reação à perda': 'mental',
    'Posicionamento': 'tatica',
    'Controlo + decisão': 'tecnica',
    'Qualidade de decisão': 'decisao',
    'Timing de movimento': 'tatica',
    'Inteligência sem bola': 'tatica',
    'Decisão sair/ficar': 'decisao',
    '1×1 defensivo': 'tatica',
    'Reação à adversidade': 'mental',
    'Controlo emocional': 'mental',
    'Concentração': 'mental',
    'Tomada de decisão': 'decisao',
    'Controlo do pé fraco': 'tecnica',
    'Primeiro toque sob pressão': 'tecnica',
    'Proteção de bola': 'tecnica',
    'Reação emocional à substituição': 'mental',
    'Concentração após erro': 'mental',
    'Leitura da cobertura defensiva': 'tatica'
  };

  function bucketDoCenario(debilidadeStr) {
    if (!debilidadeStr) return null;
    if (CENARIO_DEB[debilidadeStr]) return CENARIO_DEB[debilidadeStr];
    var d = debilidadeStr.toLowerCase();
    if (d.indexOf('decis') !== -1) return 'decisao';
    if (d.indexOf('posicion') !== -1 || d.indexOf('leitura') !== -1 || d.indexOf('timing') !== -1 || d.indexOf('sem bola') !== -1) return 'tatica';
    if (d.indexOf('emocional') !== -1 || d.indexOf('concentra') !== -1 || d.indexOf('adversidade') !== -1 || d.indexOf('perda') !== -1 || d.indexOf('mental') !== -1) return 'mental';
    if (d.indexOf('controlo') !== -1 || d.indexOf('toque') !== -1 || d.indexOf('drible') !== -1 || d.indexOf('execu') !== -1) return 'tecnica';
    if (d.indexOf('velocidade') !== -1 || d.indexOf('físic') !== -1 || d.indexOf('fisic') !== -1) return 'fisico';
    return null;
  }

  // debilidades do plano (buckets, na ordem em que o treinador as detetou)
  // → objetivo principal + secundários.
  function objetivoDoPlano(debilidades) {
    var lista = (debilidades || []).filter(function (d) { return OBJETIVOS[d]; });
    if (!lista.length) lista = ['tecnica']; // sem debilidade detetada: técnica é a base de tudo
    var principal = lista[0];
    return {
      bucket: principal,
      objetivo: OBJETIVOS[principal],
      secundarios: lista.slice(1).map(function (b) { return { bucket: b, objetivo: OBJETIVOS[b] }; })
    };
  }

  // bucket → índices (0-based) dos cenários do Elite Coach que servem esse
  // objetivo. Recebe o array CENARIOS (só está carregado no elite-coach) OU
  // usa a tabela estática de ids abaixo quando chamado de outras páginas.
  var CENARIOS_POR_BUCKET = {
    decisao: [0, 2, 3, 7, 10, 11, 17],
    tatica: [1, 5, 8, 9, 12, 13, 23],
    mental: [4, 14, 15, 16, 21, 22],
    tecnica: [6, 18, 19, 20],
    fisico: [] // não há cenário físico — a missão física é a técnica em campo
  };
  function cenariosDoObjetivo(bucket) {
    var idx = CENARIOS_POR_BUCKET[bucket];
    if (idx && idx.length) return idx;
    // objetivo sem cenário próprio: roda pelos de decisão (base cognitiva)
    return CENARIOS_POR_BUCKET.decisao;
  }

  // missão de decisão da semana: determinística por atleta+semana para toda
  // a família ver a mesma, mas rodando semana a semana pelos cenários certos.
  function missaoDecisaoDaSemana(bucket, semanaIdx) {
    var lista = cenariosDoObjetivo(bucket);
    return lista[(semanaIdx || 0) % lista.length]; // índice 0-based no CENARIOS
  }

  window.YTBObjetivos = {
    OBJETIVOS: OBJETIVOS,
    bucketDoCenario: bucketDoCenario,
    objetivoDoPlano: objetivoDoPlano,
    cenariosDoObjetivo: cenariosDoObjetivo,
    missaoDecisaoDaSemana: missaoDecisaoDaSemana
  };
})();
