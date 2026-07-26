# YTB — O que está por fazer

*Backlog vivo, ao lado da `YTB_CONSTITUTION.md` e do `YTB_GUIA_FUNCIONALIDADES.md`. Regra de ouro deste ficheiro: **nada aqui se implementa durante a execução do piloto GFA** — exceto correções de segurança, privacidade e conformidade, que entram sempre imediatamente (regra operacional da Emenda I). Cada entrada diz de onde veio, para não se perder o "porquê" daqui a três meses.*

**Estado:** piloto GFA a arrancar. Última atualização: julho 2026.

---

## 🔴 Prioridade 1 — decide-se durante o piloto, constrói-se logo a seguir

### 1.1 · Avisos do treinador → família/atleta
**De onde veio:** o fundador reparou que não existe nenhuma comunicação entre o treinador e os atletas dele. Confirmado no código e na base de dados: não há absolutamente nada.

**O que é:** o treinador envia uma nota curta ligada a contexto (treino de amanhã cancelado, parabéns pelo jogo, ajusta isto na próxima sessão). Aparece na sessão da família, fica no livro-razão com data e proveniência.

**O que NÃO é, e porquê:** não é chat aberto nem canal privado adulto↔menor. Comunicação não supervisionada entre um adulto e uma criança é o padrão que se evita em desporto jovem, por princípio. A arquitetura já protege isto sozinha — o atleta não tem conta própria, usa a sessão da família (Constituição: "o miúdo tem lugar dentro da sessão da família") — logo qualquer aviso é sempre visível ao encarregado, por construção. Manter **unidirecional** (treinador → família) na v1; se um dia houver resposta, tem de ser sempre no mesmo fio visível à família, nunca num canal separado.

**Fecha um círculo da Regra de Ouro:** Princípio 5 — "a família que executa recebe novidade." Está declarado na Constituição e nunca foi construído.

**Esboço técnico:** tabela `treinador_avisos` (atleta_id, treinador_email, texto, criado_em, lido_em) + RPC `ytb_treinador_aviso_enviar` restrita aos atletas do próprio treinador (mesmo padrão de `ytb_treinador_atleta_classificar`) + evento no livro-razão + badge na sessão da família. RLS deny-by-default como sempre.

---

### 1.2 · Grelha do Diretor Técnico
**De onde veio:** convergência independente entre duas auditorias (Claude e ChatGPT) que não se viram uma à outra — ambas apontaram a mesma funcionalidade em falta. É o sinal mais forte que esta plataforma recebeu sobre o que construir a seguir.

**O que é:** uma vista para quem coordena vários escalões — 120 atletas numa grelha, quem não é avaliado há 60 dias, quem estagnou, quem entra em pico de maturação, onde dois treinadores divergem sobre o mesmo atleta.

**Porque importa:** é o que faz um Diretor de Formação dizer "sem isto não volto ao Excel". Aborrecido de construir, difícil de copiar, e é o argumento comercial para a camada B2B.

---

### 1.3 · Tendências em vez de números
**De onde veio:** proposta do ChatGPT, refinada em conjunto e aceite por unanimidade das três partes.

**O que é:** substituir a exibição de valores numéricos (ex: "Development Score: 73") por tendência (⬆ a subir / ➡ estável / ⬇ precisa de atenção), por competência.

**Nuance apanhada na discussão, e que não se pode esquecer:** tendência exige avaliações repetidas. Com uma só avaliação não há tendência — há primeira observação, e o estado vazio tem de dizer isso honestamente em vez de inventar uma seta.

**Porque importa:** um número comparável entre crianças, sem contexto, viola o "nunca expor notas de menores" da Constituição na prática social, mesmo que tecnicamente seja privado. Um treinador dizer "subiu 9 pontos" no balneário é diferente de dizer "está a evoluir bem".

---

## 🟡 Prioridade 2 — depende dos resultados do piloto

### 2.1 · Volume e intensidade quantificados no treino
**De onde veio:** pergunta direta do fundador sobre número de repetições e formas de quantificar volume/intensidade.

**Dois níveis, e a distinção importa:**
- *Já possível hoje, sem código*: escrever "4x12" ou "6 sprints × 2 séries" na descrição do exercício. Funciona, é texto.
- *O que falta a sério*: o atleta **reportar o que fez de facto** — séries completas, reps, carga, RPE (esforço percebido) — estruturado e comparável ao longo do tempo.

**O que muda:** a forma do exercício (deixa de ser nome+descrição+tempo, ganha reps/séries/carga-alvo) e o formulário de feedback do atleta (deixa de ser só emoji+texto, ganha "quanto fizeste"). É estrutural, não é um seletor.

**Porque vale a pena:** dados de treino quantificados ao longo de épocas são precisamente o tipo de histórico que ninguém consegue copiar — alimenta o Development Score e os relatórios com substância a sério.

---

### 2.2 · Módulos que não falam com o passaporte (silos)
**De onde veio:** achado mais afiado da auditoria do ChatGPT, confirmado por leitura do código.

**O problema:** o CoachBase monta sessões de equipa sem nunca ler as avaliações dos atletas dessa equipa. O Elite Coach gera cenários sem olhar para a debilidade "decisão" que a avaliação já detetou. Só a prescrição individual lê mesmo a avaliação.

**A correção:** os módulos passam a **perguntar ao passaporte** em vez de inventar. Exemplo concreto: "tenho 6 atletas nesta sessão, 4 têm receção como debilidade, 2 têm decisão — sugiro esta sessão."

---

### 2.3 · Conta de academia (camada B2B)
**De onde veio:** a Constituição diz "o cliente é a entidade", mas o rosto-academia nunca foi construído — é o único rosto que passa recibos e não existe.

**O que falta:** inscrição em lote de atletas, painel de coordenador, faturação, marca da academia nos artefactos que chegam aos pais (o relatório mensal já suporta isto parcialmente).

---

## 🟢 Prioridade 3 — quando houver escala para justificar

### 3.1 · Métrica emocional do piloto (a pergunta do ChatGPT)
"Se amanhã a YTB deixasse de existir, do que sentirias mais falta?" — texto livre, sem opções.

**Decisão tomada:** com 3-5 treinadores, isto faz-se **em conversa, não em formulário** — um campo de texto produz duas linhas educadas; a mesma pergunta ao vivo produz a resposta verdadeira. Vira software quando houver ~20 treinadores e a conversa deixar de escalar.

### 3.2 · Dosagem das Missões
**Recomendação LTAD que ficou registada e não foi aplicada:** 2 missões/semana de 15-25 min, nunca no dia anterior ao jogo, e o streak a contar **semanas cumpridas em vez de dias consecutivos** (streak diário numa criança de 11 anos é dark pattern, não é motivação). O calendário de jogos já existe na base de dados e não está ligado à prescrição — ligar.

### 3.3 · Limpeza de superfície
A Constituição manda 7 ecrãs nucleares; o repositório tem ~35 páginas HTML, das quais ~11 são duplicados, stubs ou vestígios de renomeações (pro-pai, ytb-pro-pai-familia, tacticslab, scouting360 antigas, painel, plataforma). Mover para `arquivo/`. Custo: 1 hora. Ganho: honestidade estrutural.

### 3.4 · Push notifications
Backend construído nas migrações 032–033, **sem nenhuma UI de ativação**. Código morto em produção. Decisão binária: ou se constrói a UI numa tarde, ou se dropam as migrações.

### 3.5 · Pivot WP8 nas páginas públicas
O componente partilhado (`assets/js/ytb-pivot.js`) já existe e funciona nas páginas do piloto. As páginas públicas (index, montra) ficaram de fora deliberadamente: não têm estrutura de secções, são narrativa vertical — convertê-las é um projeto de desenho, não um patch.

### 3.6 · Documentar Scout, Clube e CoachBase no guia
O `YTB_GUIA_FUNCIONALIDADES.md` cobre Treinador, Família e Admin ponto a ponto. Estes três ficaram por documentar com o mesmo detalhe — não foram auditados linha a linha, e um "carregas aqui, acontece aquilo" errado é pior do que uma lacuna assumida.

---

## 🔵 Dívida técnica reconhecida

- **`ytb_admin_aval_contextual` tem o nome errado.** Desde a v051 também é usada pelo treinador, não só pelo admin. Não foi renomeada para evitar tocar no `admin360.html` numa sessão já longa. Renomear quando houver uma vaga de arrumação.
- **Sem staging real.** Todas as migrações desta fase foram aplicadas diretamente a produção, testadas com `BEGIN`/`ROLLBACK` transacional. Não é staging. Exige decisão do fundador: branch de desenvolvimento Supabase (pago por hora) ou aceitar o dry-run como suficiente. **Deixa de ser aceitável adiar no dia em que a base tiver 40 famílias reais que não são a tua.**
- **Prompt do scout visível no cliente.** A chave da API está bem guardada server-side, mas o prompt está no código-fonte da página — qualquer concorrente o lê. Baixo impacto hoje; relevante quando a IA for diferenciador a sério.

---

## ⚫️ Fora de âmbito — decidido e registado para não voltar à mesa

- **Marketplace de reservas de treino** (estilo app da SIFA: escolher treinador, marcar 1h, pagar €25). É outra categoria de produto — resolve "como compro uma hora", a YTB resolve "o que provamos que essa hora produziu". Não compete; a longo prazo, integrar sessões de parceiros no livro-razão é mais barato do que construir booking próprio.
- **Expandir para outros desportos agora.** O núcleo conceptual serve (basquetebol, andebol, natação, música), e a Emenda I já garante que o núcleo é universal. Mas o foco absoluto continua no futebol até haver domínio claro — a expansão é consequência de ter ganho, não estratégia para ganhar.
