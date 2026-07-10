# YTB_CONSTITUTION.md
**A Constituição da YourTalentBase** · v1.0 · ratificada após as quatro sessões de auditoria estratégica
*Este documento prevalece sobre qualquer pedido de funcionalidade. Se uma funcionalidade o violar, o desenvolvimento para, o conflito é explicado, e propõe-se alternativa antes de escrever código.*

---

## VISÃO

O futebol de formação — e o desporto jovem em geral — não tem memória. A YTB existe para ser essa memória: **cada criança que joga merece um registo da sua história**, para que o percurso de um jovem atleta nunca mais dependa de quem estava a ver naquele dia.

## MISSÃO

Construir o registo longitudinal, verificado e multi-observador do desenvolvimento de jovens atletas — um passaporte que **pertence ao atleta**, o acompanha entre clubes e épocas, e transforma instantes e achismo em trajetória e prova.

## PRINCÍPIOS (a tese, em sete leis)

1. **O registo pertence à criança.** Não ao clube, não à academia, não à plataforma. Muda de clube, o percurso vai com ela. Um percurso não se grava para trás — é isso que o torna valioso.
2. **A divergência é sinal, não ruído.** Cada avaliação é um testemunho com proveniência (quem, quando, em que contexto). Dois observadores a discordar são dados, não erro. Convergência gera confiança; divergência gera valor.
3. **Desenvolver antes de detetar.** Quem floresce tarde não é pior — é mais tarde. A plataforma existe para dar hipóteses justas, não para etiquetar cedo.
4. **Contexto antes de números.** Nenhum valor aparece nu: sempre com idade relativa, número de observadores e trajetória. Um número sem contexto é um instante disfarçado de verdade.
5. **Quem alimenta o sistema recebe do sistema.** Nenhum círculo fica aberto: o treinador que avalia recebe retorno; a família que executa recebe novidade; o miúdo que treina recebe celebração e caminho seguinte.
6. **O consentimento é o alvará, e o controlo é da família.** Consentir é por âmbitos, versionado, revogável a qualquer momento — e o interruptor da exposição está na mão de quem tem a guarda, nunca só do admin.
7. **Proveniência em tudo, sempre.** Todo o facto relevante do percurso é um evento imutável no livro-razão, registado na mesma transação em que acontece. O que não está no livro, não aconteceu.

## REGRAS DE PRODUTO

- **O cliente é a entidade** (academia, escola, clube). **A família é funil, gratuita** — paga, no máximo, extras pontuais de orgulho (anuário, relatório de época). Subscrição familiar para *ver* o próprio filho: proibida — envenena o moat (só as infâncias de quem paga ficariam registadas).
- **O relatório à família é a peça central de valor**: onde está bem, onde está mal, o que treinar. Tudo o resto serve isto.
- **Um produto, vários rostos.** Não há apps separadas por persona. O mesmo passaporte com hierarquias distintas: Família (Treino → O que mudou → Relatório → Percurso), Scout (Dados → Contexto → Evolução), Treinador (Avaliar → Retorno → Planeamento).
- **O miúdo tem lugar.** Dentro da sessão da família, sem conta própria: identidade, sequência, celebração, plano seguinte.
- **Superfície mínima: 7 ecrãs nucleares** (entrada, montra, onboarding, acesso família, passaporte, pro-treinador, admin). Módulos fora do loop nuclear (avaliar→detetar→prescrever→executar→registar) ficam em arquivo.
- **Linguagem por rosto.** Jargão de analista nunca chega a um pai ou a um miúdo.
- **A avaliação de campo custa ≤30 segundos por atleta.** O que exigir mais, não sobrevive ao relvado.

## REGRAS TÉCNICAS

- **Livro-razão primeiro:** todo o facto longitudinalmente relevante emite evento em `atleta_eventos`, na mesma transação da escrita de domínio. Sem exceções, sem "depois logo se emite".
- **Escrita só por RPC** `security definer` com verificação de papel no servidor. O cliente nunca escreve diretamente em tabelas. Leituras diretas só sob policies explícitas e versionadas no repositório.
- **RLS deny-by-default** em todas as tabelas; toda a policy vive no repositório.
- **Esquema reprodutível:** migrações numeradas e imutáveis, aplicadas por ordem; nenhuma alteração de esquema fora delas. **Staging antes de produção, sempre** — produção tem dados de crianças reais.
- **Imutabilidade do livro:** `atleta_eventos` sem UPDATE/DELETE concedidos; correções são novos eventos.
- **Sem framework de frontend até ao gatilho** (primeiro contrato B2B pago ou primeira contratação técnica). Até lá: páginas leves + núcleo partilhado. Nada de microserviços, filas, ou engenharia especulativa.
- **Segredos nunca no cliente.** IA e chaves só server-side (Edge Functions) quando existirem.
- **Validação antes de apresentação:** nenhuma peça se declara pronta sem correr verde em ambiente local (SQL em Postgres real; JS em Node; isolamento entre famílias testado explicitamente).
- **Identidade visual:** o dourado é reservado (selo/verificação/marcos). Botões e ação são off-white sobre escuro.

## O QUE NUNCA FAZEMOS

1. **Nunca** expor publicamente notas ou classificações de menores (A+…D ou equivalentes). A montra mostra percurso, nunca veredicto.
2. **Nunca** vender acesso a menores — a empresários, agentes ou quem for. Monetiza-se o serviço de desenvolvimento; **nunca** a criança como mercadoria. Esta linha é a marca.
3. **Nunca** prometer no ecrã o que o sistema não faz (ex.: "podes revogar" sem revogação construída).
4. **Nunca** links de acesso com token/PIN embebido para dados de menores — a chave é a sessão autenticada.
5. **Nunca** escrever no domínio sem emitir o evento correspondente.
6. **Nunca** o cliente a escrever diretamente numa tabela.
7. **Nunca** aplicar SQL em produção sem passar por staging.
8. **Nunca** funcionalidade nova enquanto existir um círculo aberto para alguém que alimenta o sistema (a Regra de Ouro).
9. **Nunca** reescrever o que está correto — a fundação foi auditada e aprovada; corrige-se a sequência, não se recomeça.
10. **Nunca** deixar a verificação de identidade depender para sempre de um terceiro (ZeroZero é andaime, não alicerce).

## ORDEM CORRETA DE DESENVOLVIMENTO

**Fase 0 — BLINDAGEM** (Mandato 1): esquema reprodutível, migrações, staging, consentimento v2, legado eliminado, escritas por RPC, eventos completos, permissões auditáveis. *O alvará.*
**Fase 1 — FECHAR OS CÍRCULOS** (Mandato 2): digest do treinador, feedback visível, avisos à família, "o que mudou", lugar do miúdo, sequências, celebrações, plano seguinte automático. *O produto respira sozinho.*
**Fase 2 — ACADEMIA** (Mandato 3): conta de organização, marca própria, inscrição em lote, operação para grupos, piloto GFA autónomo. *O cliente existe.*
**Fase 3 — UX** (Mandato 4): cada rosto reorganizado para o seu dono; jargão e secções vazias eliminados. *Cada um sente que foi feito para si.*
**Fase 4 — DIFERENCIAÇÃO** (Mandato 5): camada de confiança, contexto em todos os indicadores, exportação do passaporte, painéis de coordenador e DT. *O moat acumula.*

**Protocolo de validação constitucional:** antes de qualquer funcionalidade nova — (1) verificar contra "O que nunca fazemos"; (2) verificar a Regra de Ouro (há círculos abertos?); (3) verificar a fase (pertence ao mandato atual?); (4) em conflito: parar, explicar, propor alternativa. Só depois, código.

*Emendas a esta Constituição exigem decisão explícita do fundador, registada neste ficheiro com data e motivo.*
