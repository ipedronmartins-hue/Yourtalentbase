# YTB — Guia de Funcionalidades

*Referência viva, tal como a `YTB_CONSTITUTION.md`. Não é marketing — é "carregas aqui, acontece isto", ponto a ponto, para quem usa a plataforma no dia a dia. Atualiza-se sempre que uma funcionalidade muda; uma entrada desatualizada é pior do que nenhuma, por isso a última coluna de cada secção diz a migração/commit onde a coisa nasceu, para se poder verificar contra o código quando houver dúvida.*

---

## Treinador — `ytb-pro-treinador.html`

### Aba Atletas
Lista dos atletas inscritos por ti (`fonte_email` = o teu email). Tocar num atleta seleciona-o e leva-te à aba Avaliar.

**Inscrever atleta** (botão no topo): abre um formulário — nome, data de nascimento, posição, clube, associação, esquema tático (opcional), link ZeroZero (obrigatório, é a verificação de identidade), email do encarregado. Ao submeter, o atleta entra em produção com estado `pendente`, à espera de aprovação do admin. *Desde a v053: o email do encarregado é validado a sério (precisa de domínio e terminação, tipo `nome@gmail.com`) — antes só verificava se havia um "@" nalgum lado.*

### Aba Avaliar
O ecrã principal, pensado para durar ≤30 segundos por atleta.

**As 5 áreas** (Técnica, Decisão, Tática, Físico, Mental): um toque de 1 a 5 em cada. 1 = prioridade (é uma fraqueza a trabalhar); 5 = forte. Cada área tem um botão "Detalhar" opcional com critérios mais finos — só abre se quiseres ir mais fundo, não é obrigatório.

**Seletor Período** *(v055, pedido real do Mister Nuno Teles, Sub-17 em pré-época)*
- **Época** (opção por omissão): o plano gerado é a "missão caseira" de sempre — **3 exercícios por sessão**, corta automaticamente aos **~12 minutos**. Pensado para o atleta treinar sozinho em casa, entre sessões do clube, sem ocupar muito tempo.
- **Pré-época**: sessão a sério — **5 a 6 exercícios por sessão**, **sem corte de tempo**. Para quando o atleta já treina como o escalão exige (ex.: um Sub-17 em pré-época faz sessões bem mais longas e densas do que um miúdo a treinar sozinho em casa).
- O que NÃO muda entre os dois: a barreira de segurança por idade (um exercício só entra se for adequado à idade do atleta) e o teto de intensidade por maturação continuam sempre ativos — o período escolhe *volume*, nunca contorna *segurança*.
- A escolha é feita **antes** de carregar em "Concluir avaliação" — depois disso o plano já foi gerado e gravado com essa configuração.

**Seletor "Dirigir o plano gerado"** *(v(chips), pedido do fundador após feedback do CoachBase)*
- **Automático** (omissão): os exercícios seguem as fraquezas que acabaste de avaliar, com um mínimo garantido de exercícios físicos (a intensidade é sempre prioritária, mesmo no automático).
- **Físico / Técnica individual / Tático-decisão**: escolhes tu o foco — a maioria dos exercícios vem desse domínio, mas 1-2 das fraquezas avaliadas ficam lá na mesma, em minoria, para não desaparecerem do radar. A tua escolha manda sobre o automatismo — inclui sobrepor-se ao mínimo de físico do modo automático, porque tu sabes coisas que a avaliação não capta (há jogo amanhã? o clube já martelou físico esta semana?).

**Botão "Concluir avaliação e gerar treino"**: grava a avaliação e o plano na base de dados (fica para sempre no histórico, com data), atualiza o rating automático do atleta (média das 5 áreas → nota A+ a D), e envia um magic link por email à família com o plano novo. Se o atleta não tiver email de encarregado, o plano fica gravado mas ninguém é avisado — vês um aviso a dizer isso.

**Classificação YTB** *(v051 — secção opcional, colapsada por omissão, nunca compete com os 30 segundos)*
- **Rating geral**: ajuste manual por cima do que a avaliação já calculou automaticamente.
- **Estatuto**: 👀 Observado / 📈 Em Crescimento / 💎 Hidden Gem / ★ YTB Acompanhado.
- **3 áreas de excelência**: Técnico / Tático / Físico / Mental — o que este atleta faz particularmente bem.
- **"Gerar avaliação contextual (IA)"**: pede à IA um parágrafo (80-120 palavras) que interpreta o desempenho do atleta *tendo em conta o contexto* (divisão, posição na equipa, golos vs. golos da equipa) — nunca inventa números que não tenhas preenchido no "Contexto competitivo", e diz explicitamente quando falta informação para uma leitura completa. Fica gravado no histórico, não se apaga.
- Isto está restrito aos **teus** atletas — não consegues classificar nem gerar avaliação contextual de um atleta que não seja teu (testado explicitamente).

### Aba Retorno
Não é uma lista, é uma fila de prioridade — quem precisa de ti primeiro, não quem mexeu por último. Para cada atleta: treinos desde o plano, treinos no total, % de confiança dos dados, a citação mais recente do atleta em texto livre, e uma recomendação ("Reavaliar" / "Rever o objetivo" / "Falar com a família") calculada a partir de sinais reais — dias sem avaliação, dificuldade reportada no último jogo, plano sem execuções. Ver a resposta anterior deste guia sobre "que feedback dá o atleta" para os três formulários que alimentam isto.

### Aba Objetivo
Mostra o plano gerado na tua sessão atual (se acabaste de avaliar) **e sempre**, por baixo, o "📜 Histórico de treinos prescritos" — todas as prescrições anteriores, com data, nº de semanas, fraquezas trabalhadas, e um botão "Ver plano" que expande os exercícios completos. *Corrigido na v(fix histórico): antes, esta aba só mostrava alguma coisa se tivesses acabado de avaliar nesta sessão do browser — o histórico já estava gravado, só não aparecia se saísses e voltasses sem reavaliar.*

### Aba Comissões
Mostra o que a tua conta gerou em comissões (modelo de negócio B2B, ainda em validação com o piloto).

---

## Família / Atleta — `passaporte.html`

### Navegação
Estilo Windows Phone 8 (Pivot): títulos grandes no topo, deslizas com o dedo para os lados para mudar de secção — **Esta semana · Atualizar dados · O Passaporte · Privacidade**. Uma dica "↔ desliza para os lados" aparece na primeira visita de cada sessão.

### Esta semana
- **Missões**: os exercícios que o treinador prescreveu, com cronómetro embutido por exercício. No fim de cada sessão: "Como correu?" — 5 emojis (confiança 1-5) + texto livre opcional.
- **Houve jogo? / jogos por responder**: check-in rápido ligado ao objetivo do plano ("sentiste dificuldade em [verbo do objetivo]?"), e resposta completa a jogos marcados no calendário (como correu, golos, assistências, minutos, nota livre).

### Atualizar dados
- **Identidade**: nome completo, último apelido, dia/mês/ano de nascimento, sexo. *(v051/052 — antes só o admin escrevia isto; a data de nascimento define o escalão e a leitura de maturação, por isso há um aviso a dizer isso no formulário.)*
- **Clube/equipa/escalão/associação, posição, pé dominante, links ZeroZero e Joga+.**
- **Contacto do encarregado** (nome + WhatsApp).
- **Estatísticas da época atual**: golos, jogos, assistências, minutos. Botão "Fechar a época" arquiva estes números no percurso (carreira) e prepara o cartão para a época seguinte, sem perder nada.
- **O percurso dele (carreira)**: até 3+ épocas anteriores, com clube, escalão, divisão, classificação, golos/jogos/assistências/minutos e títulos.
- **Biometria**: altura, peso, tamanho de pé — cada registo fica no histórico, não substitui o anterior.
- **Altura dos pais**: alimenta a estimativa de altura adulta (maturação) — é estimativa, não diagnóstico, e só a família e o admin veem este dado (é categoria especial, RGPD).

### O Passaporte
A vista "de sempre" — identidade, indicadores, Development Score (tendência, não nota pública), timeline de eventos, marcos, carreira. **Development Score** entra em modo "🏖️ Época em pausa" durante férias oficiais — o relógio para, o score não desce por não haver treinos do clube.

### Relatório do mês
Um toque abre `relatorio.html?atleta=X` — documento A4, pronto a imprimir/guardar em PDF: o que o atleta fez, o que o treinador observou (separado do que a família declarou), evolução biométrica, marcos do mês, e um rodapé de proveniência (nº de factos, desde quando, quantos observadores). Pensado para ser mostrado fora da plataforma.

### Privacidade
Interruptores por âmbito (foto, vídeo, visibilidade pública/B2B) — a família decide, revogável a qualquer momento.

---

## Admin — `admin360.html`

### Zona Decidir
Fila de aprovação: atletas pendentes, pedidos de contacto, treinadores por aprovar.

### Zona Pessoas
- **Por Treinador** (pastas): um atleta por pasta, agrupados pelo email de quem o inseriu — inclui as tuas próprias inscrições, marcadas a azul "· TU (ADMIN)".
- **Atletas** (lista completa, com pesquisa/filtro por estado, incluindo `suspenso`).
- **Suspender/reativar acesso** (botão ⏸/▶️ em cada atleta): bloqueia o acesso da família ao passaporte sem apagar nada — reversível. Pensado para pagamento em falta.
- **Contas**: gestão de papéis e bloqueio de contas (treinador/scout/família/clube).

### Zona Piloto
Painel de Saúde do Piloto — não é um dashboard de métricas, é a resposta a "está a criar hábito ou a morrer?": Círculos Fechados da semana (treinador alimentou → família respondeu → atleta participou → sistema devolveu valor), 4 blocos de recorrência, alertas automáticos (X dias sem avaliação, atletas sem contacto há 14+ dias), e a lista nominal de quem precisa de atenção.

### Zona Negócio
Clubes, relatórios, comissões previstas/pendentes.

---

## Por documentar (âmbito ainda não coberto com o mesmo nível de detalhe)

Scout (`scouts.html`), Clube (`clube.html`) e CoachBase (`coachbase.html`, sessões de equipa) existem e funcionam, mas não foram auditados linha a linha nesta sessão — antes de os descrever aqui ponto a ponto, prefiro verificar contra o código atual do que arriscar um "carregas aqui, acontece aquilo" errado. Ficam para a próxima vaga deste guia.

## Como manter isto vivo

Sempre que uma funcionalidade nova ou alterada tocar num botão/seletor visível ao utilizador, a entrada correspondente atualiza-se no mesmo commit que muda o código — não depois, não "quando houver tempo". Um guia desatualizado é uma promessa que a Constituição já proíbe ("nunca prometer no ecrã o que o sistema não faz") aplicada à documentação.
