/* ================================================================
   YOURTALENTBASE · ytb-nota-automatica.js
   Nota automática DETERMINÍSTICA do Scouting360 (zero IA, zero custo).

   Princípios:
   - 4 dimensões: Contexto (40%), Volume (25%), Produção (20%), Trajetória (15%).
   - O Contexto é o fator dominante (decisão do Rocka).
   - NUNCA prejudica um miúdo por falta de dados NOSSOS: quando o nível
     da divisão não está na tabela, o contexto fica NEUTRO (50), não a zero.
   - Produção ajustada à posição: um GR/defesa não é penalizado por não marcar.
   - É uma fórmula transparente: dá para explicar a um pai de onde vem a nota.

   Uso:
     const r = YTB_NOTA.calcular(inscricao);
     // r.dimensoes = {contexto, volume, producao, trajetoria}  (0-100 cada)
     // r.notaFinal = 0-100 ; r.letra = 'A+'|'A'|'B'|'C' ; r.detalhe = {...}
================================================================ */
(function(NS){
'use strict';

// ----------------------------------------------------------------
// 1. TABELA DE NÍVEIS DE DIVISÃO (preenchida PELO ROCKA, ao seu ritmo)
//    Chave: ASSOCIACAO|ESCALAO|DIVISAO (tudo em maiúsculas, sem acentos)
//    Valor: 1 (mais fraco) a 5 (mais forte).
//    O que NÃO estiver aqui → contexto NEUTRO (não penaliza nem premeia).
//
//    Começamos só com o que confirmámos da AF Porto Sub-13.
//    Acrescenta linhas à medida que souberes. NÃO inventes.
// ----------------------------------------------------------------
const NIVEIS_DIVISAO = {
  // AF Porto · Sub-13 (estrutura confirmada: Distrital base < II Div < I Div < Honra/Elite)
  'AF PORTO|SUB-13|II DIVISAO': 2,
  'AF PORTO|SUB-13|I DIVISAO': 3,
  'AF PORTO|SUB-13|DIVISAO DE HONRA': 4,
  'AF PORTO|SUB-13|ELITE': 5,
  'AF PORTO|SUB-13|DISTRITAL': 1,
  // Nacional (qualquer associação/escalão): topo
  'NACIONAL': 5
  // ... Rocka acrescenta o resto (outras associações/escalões) aqui.
};

const NIVEL_NEUTRO = 50;   // 0-100; usado quando não há dado fiável (não prejudica)

// ----------------------------------------------------------------
// 2. POSIÇÕES — para ajustar a Produção (golos/assists) por posição.
//    Peso de produção: quanto a posição "vive" de golos+assists.
//    GR e defesas: baixo (não são penalizados por não marcar — a
//    produção deles é compensada por contexto/volume).
// ----------------------------------------------------------------
const PESO_PRODUCAO_POS = {
  'GR':0.15,'GUARDA-REDES':0.15,
  'DC':0.30,'DEFESA':0.35,'DEFESA CENTRAL':0.30,'LATERAL':0.45,
  'MD':0.45,'MEDIO DEFENSIVO':0.40,'MEDIO':0.60,'MC':0.60,'MEDIO CENTRO':0.55,
  'MO':0.80,'MEDIO OFENSIVO':0.80,
  'EXTREMO':0.90,'ALA':0.90,
  'AV':1.0,'AVANCADO':1.0,'PONTA DE LANCA':1.0,'ATA':1.0
};
function pesoProducao(pos){
  if(!pos) return 0.6; // default médio
  const k = normaliza(pos);
  if(PESO_PRODUCAO_POS[k]!=null) return PESO_PRODUCAO_POS[k];
  // tenta por palavra-chave
  if(/\bGR|GUARDA/.test(k)) return 0.15;
  if(/AVAN|PONTA|\bAV\b/.test(k)) return 1.0;
  if(/EXTREMO|\bALA\b/.test(k)) return 0.9;
  if(/OFENS/.test(k)) return 0.8;
  if(/DEF|\bDC\b|CENTRAL/.test(k)) return 0.32;
  if(/MED|\bMC\b|\bMD\b/.test(k)) return 0.55;
  return 0.6;
}

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------
function normaliza(s){
  return String(s==null?'':s)
    .normalize('NFD').replace(/[\u0300-\u036f]/g,'') // tira acentos
    .toUpperCase().trim().replace(/\s+/g,' ');
}
function num(v){ const n=parseFloat(v); return isFinite(n)?n:0; }
function clamp(v,min,max){ return Math.max(min,Math.min(max,v)); }

// Resolve o nível 1-5 da divisão → escala 0-100. Sem dado → neutro.
function nivelContextoDivisao(assoc, escalao, divisao){
  const a=normaliza(assoc), e=normaliza(escalao), d=normaliza(divisao);
  // match direto
  let chave = a+'|'+e+'|'+d;
  if(NIVEIS_DIVISAO[chave]!=null) return {valor:(NIVEIS_DIVISAO[chave]/5)*100, conhecido:true};
  // "nacional" em qualquer parte do texto da divisão
  if(/NACIONAL/.test(d)) return {valor:(NIVEIS_DIVISAO['NACIONAL']/5)*100, conhecido:true};
  // sem dado fiável → NEUTRO (não prejudica)
  return {valor:NIVEL_NEUTRO, conhecido:false};
}

// Idade-escalão: joga acima do escalão? (sinal forte de maturação precoce)
// escalao tipo "Sub-13" → idade-teto 13. ano_nascimento → idade na época.
function bonusEscalao(ano, escalao){
  const e = normaliza(escalao);
  const m = e.match(/SUB-?(\d+)/);
  if(!m || !ano) return {valor:0, joga_acima:false};
  const tetoEscalao = parseInt(m[1],10);
  const anoNum = num(ano);
  if(!anoNum) return {valor:0, joga_acima:false};
  // época 2025/26: idade de referência = 2025 - ano (aproximação por época)
  const idadeEpoca = 2025 - anoNum;
  // escalão Sub-N: nascido para esse escalão se idadeEpoca <= N e >= N-1
  // se idadeEpoca < tetoEscalao-1 → está a jogar ACIMA (mais novo que o escalão)
  const diff = (tetoEscalao - 1) - idadeEpoca; // >0 = joga acima
  if(diff >= 2) return {valor:20, joga_acima:true};   // 2+ escalões acima
  if(diff === 1) return {valor:12, joga_acima:true};  // 1 escalão acima
  return {valor:0, joga_acima:false};
}

// ----------------------------------------------------------------
// 3. AS 4 DIMENSÕES
// ----------------------------------------------------------------

// CONTEXTO (40%): nível divisão + posição relativa da equipa + jogar acima
function dimContexto(insc){
  const nivel = nivelContextoDivisao(insc.associacao, insc.escalao, insc.divisao);
  // posição relativa: classificação / total de equipas (top = melhor)
  const clas = num(insc.classificacao), tot = num(insc.total_equipas);
  let posRelativa = NIVEL_NEUTRO; let posConhecida=false;
  if(clas>0 && tot>1){
    // 1º lugar → 100 ; último → ~20 (nunca 0, jogar na divisão já conta)
    posRelativa = clamp(100 - ((clas-1)/(tot-1))*80, 20, 100);
    posConhecida=true;
  }
  const bonus = bonusEscalao(insc.ano_nascimento, insc.escalao);
  // combinação: nível da divisão é o que mais pesa dentro do contexto
  // 55% nível divisão + 30% posição relativa + bónus jogar-acima (até 20 add)
  let base = nivel.valor*0.55 + posRelativa*0.30 + 50*0.15; // 0.15 reservado/estável
  base = base + bonus.valor;
  return {
    valor: Math.round(clamp(base,0,100)),
    conhecido: nivel.conhecido || posConhecida,
    detalhe: {
      nivel_divisao: nivel.conhecido ? Math.round(nivel.valor) : 'neutro (sem dado)',
      posicao_relativa: posConhecida ? Math.round(posRelativa) : 'neutro (sem dado)',
      joga_acima_escalao: bonus.joga_acima
    }
  };
}

// VOLUME (25%): minutos + rácio de titularidade
function dimVolume(insc){
  const jogos=num(insc.jogos), tit=num(insc.titular), min=num(insc.minutos);
  if(jogos<=0 && min<=0) return {valor:NIVEL_NEUTRO, conhecido:false, detalhe:{nota:'sem dados de jogo'}};
  // minutos: referência ~1200 min/época = jogador muito utilizado num escalão de formação
  const scoreMin = clamp((min/1200)*100, 0, 100);
  // titularidade
  const ratioTit = jogos>0 ? clamp((tit/jogos)*100,0,100) : 50;
  const valor = Math.round(scoreMin*0.6 + ratioTit*0.4);
  return {valor:clamp(valor,0,100), conhecido:true, detalhe:{minutos:min, titularidade_pct:Math.round(ratioTit)}};
}

// PRODUÇÃO (20%): (golos+assists)/jogo ajustado à posição
function dimProducao(insc){
  const jogos=num(insc.jogos), golos=num(insc.golos), assists=num(insc.assists);
  const peso = pesoProducao(insc.posicao);
  if(jogos<=0) return {valor:NIVEL_NEUTRO, conhecido:false, detalhe:{nota:'sem jogos'}};
  const contribJogo = (golos+assists)/jogos; // ex: 0.5 = 1 contribuição a cada 2 jogos
  // referência: 0.7 contrib/jogo já é muito bom na formação para posições ofensivas
  let scoreBruto = clamp((contribJogo/0.7)*100, 0, 100);
  // ajuste por posição: para posições defensivas, a produção pesa menos no bruto,
  // mas o "que falta" é reposto para neutro (não penaliza por ser defensor)
  const valor = Math.round(scoreBruto*peso + NIVEL_NEUTRO*(1-peso));
  return {valor:clamp(valor,0,100), conhecido:true, detalhe:{contrib_por_jogo:Math.round(contribJogo*100)/100, peso_posicao:peso}};
}

// TRAJETÓRIA (15%): evolução face às épocas anteriores (h1, h2)
function dimTrajetoria(insc){
  const h1 = insc.hist1||{}, h2 = insc.hist2||{};
  // sinais simples: subiu de nível de divisão? mais golos? mudou p/ clube maior?
  // sem histórico → neutro
  const temH1 = h1.divisao || h1.jogos || h1.golos;
  if(!temH1) return {valor:NIVEL_NEUTRO, conhecido:false, detalhe:{nota:'sem histórico'}};
  let score=NIVEL_NEUTRO;
  // nível atual vs nível h1 (se ambos conhecidos)
  const nAtual = nivelContextoDivisao(insc.associacao, insc.escalao, insc.divisao);
  const nH1 = nivelContextoDivisao(insc.associacao, h1.escalao, h1.divisao);
  if(nAtual.conhecido && nH1.conhecido){
    if(nAtual.valor>nH1.valor) score+=20;        // subiu de divisão
    else if(nAtual.valor<nH1.valor) score-=10;   // desceu
  }
  // golos: tendência
  const gAtual=num(insc.golos), gH1=num(h1.golos);
  if(gH1>0 || gAtual>0){ if(gAtual>gH1) score+=10; else if(gAtual<gH1*0.5) score-=5; }
  return {valor:clamp(Math.round(score),0,100), conhecido:true, detalhe:{}};
}

// ----------------------------------------------------------------
// 4. NOTA FINAL
// ----------------------------------------------------------------
const PESOS = {contexto:0.40, volume:0.25, producao:0.20, trajetoria:0.15};

function letra(n){
  if(n>=85) return 'A+';
  if(n>=70) return 'A';
  if(n>=55) return 'B';
  if(n>=40) return 'C';
  return 'D';
}

function calcular(insc){
  insc = insc||{};
  const contexto = dimContexto(insc);
  const volume = dimVolume(insc);
  const producao = dimProducao(insc);
  const trajetoria = dimTrajetoria(insc);

  const notaFinal = Math.round(
    contexto.valor*PESOS.contexto +
    volume.valor*PESOS.volume +
    producao.valor*PESOS.producao +
    trajetoria.valor*PESOS.trajetoria
  );

  // confiança: quantas dimensões assentam em dados reais (não neutro)
  const conhecidas = [contexto,volume,producao,trajetoria].filter(d=>d.conhecido).length;
  const confianca = Math.round((conhecidas/4)*100);

  return {
    dimensoes: {contexto:contexto.valor, volume:volume.valor, producao:producao.valor, trajetoria:trajetoria.valor},
    notaFinal: notaFinal,
    letra: letra(notaFinal),
    confianca: confianca,          // 0-100: quão "cheia" de dados reais é a nota
    detalhe: {contexto:contexto.detalhe, volume:volume.detalhe, producao:producao.detalhe, trajetoria:trajetoria.detalhe},
    pesos: PESOS
  };
}

// API pública
NS.calcular = calcular;
NS.NIVEIS_DIVISAO = NIVEIS_DIVISAO;   // o Rocka pode acrescentar níveis aqui
NS._internas = {dimContexto,dimVolume,dimProducao,dimTrajetoria,nivelContextoDivisao,bonusEscalao,pesoProducao};

})(window.YTB_NOTA = window.YTB_NOTA || {});

// suporte a Node para testes
if(typeof module!=='undefined' && module.exports){ module.exports = window.YTB_NOTA; }
