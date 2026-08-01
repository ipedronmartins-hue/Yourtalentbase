# Sistema de Design YTB — para reaproveitar noutro projeto

*Extraído do código real (`ytb-tokens.css` + `index.html`), não da memória — por isso os valores aqui batem certo com o que está em produção. Uma correção logo de início: em várias peças que fiz esta sessão (apresentações, gráficos do GFA) usei `#0A0F0A` como o preto de fundo. **Está errado.** O valor real e canónico é `#080C08` — mais escuro, ligeiramente mais verde. Usa este documento, não a minha memória de sessões anteriores.*

---

## 1 · A filosofia (o porquê, antes do quê)

Quatro princípios que gera todas as decisões de design abaixo — leva-os contigo mais do que os valores exatos, porque são eles que geram os valores certos para o próximo projeto:

1. **Poucos tamanhos, hierarquia forte.** O ficheiro de tokens chama-lhe explicitamente "princípio WP8" — em vez de dezenas de tamanhos de fonte a variar meio pixel, seis degraus fixos, com o maior claramente maior que o resto. O olho descansa porque não há ambiguidade sobre o que é mais importante.
2. **A cor de marca é um selo, não uma decoração.** O dourado é *reservado* a verificação e marcos — nunca espalhado como enfeite. É por isso que, quando aparece, significa alguma coisa. Se tudo é dourado, nada é.
3. **Escuro como base, não como tema.** O fundo quase-preto não é "modo escuro" — é a superfície onde os factos se destacam. Texto claro sobre fundo escuro, com um único acento de cor por vez.
4. **Prova antes de alegação.** Visualmente, isto significa: números vêm sempre acompanhados de onde vieram (4 observadores · 26 eventos · 3 épocas), nunca soltos a pairar sem contexto.

---

## 2 · Cores (tokens exatos, copiados de `ytb-tokens.css`)

```css
:root{
  /* superfícies */
  --bg:#080C08;      /* fundo base — quase preto, ligeiramente verde */
  --bg2:#0F1410;
  --bg3:#161D17;
  --bg4:#1A241A;
  --border:#1F2520;
  --border2:#2A322B;

  /* texto */
  --text:#ECEFEA;     /* off-white, nunca branco puro */
  --slate:#9AA39A;    /* texto secundário */
  --muted:#6B756C;    /* texto terciário, legendas */

  /* marca — dourado RESERVADO a selo de verificação + marcos, nunca decoração */
  --gold:#D4AF37;
  --gold-bright:#F5C842;
  --gold-soft:rgba(212,175,55,.14);
  --gold-border:rgba(212,175,55,.32);

  /* sinais */
  --up:#00D46A;       /* subida / positivo / "grátis" */
  --down:#ff5050;      /* descida / erro — usar com moderação, evitar alarmar */
  --warn:#E0A458;      /* aviso / pendente — NÃO vermelho, mais suave que erro */
  --blue:#5AA9E6;       /* acento secundário — bom para diferenciar um segundo "lado" */
  --purple:#A78BFA;     /* terceiro acento, usar com ainda mais moderação */

  /* proveniência do dado — par de cores para distinguir quem disse o quê */
  --obs:#D3E7D9;       /* observado por terceiro (scout/treinador) — mais fiável */
  --dec:#8E978E;       /* declarado pelo próprio/família — igualmente válido, fonte diferente */
}
```

**Regra de aplicação, não só de paleta:** dourado só entra em contacto visual com algo que já é *verdade verificada* — um selo, uma data marcante, um preço definitivo. Nunca em texto corrido, nunca em mais do que ~10% de qualquer ecrã.

---

## 3 · Tipografia

```css
--font-display:'Barlow Condensed', system-ui, sans-serif;  /* títulos — condensada, garrafal, grande impacto */
--font-body:'Plus Jakarta Sans', system-ui, sans-serif;    /* corpo — geométrica, moderna, legível */
```

Escala de seis degraus (não mais que isto — é o "poucos tamanhos" da filosofia a virar números):

| Token | Valor | Uso |
|---|---|---|
| `--fs-hero` | 40px | Número de destaque — KPI grande, placar |
| `--fs-titulo` | 26px | Título de página/secção, sempre em Barlow Condensed |
| `--fs-sub` | 18px | Subtítulo, título de cartão |
| `--fs-corpo` | 14px | Texto corrido — o tamanho por omissão |
| `--fs-legenda` | 12px | Legenda, meta-informação, rótulo |
| `--fs-micro` | 10px | O mais pequeno — badge, carimbo de tempo |

**Sem fonte web disponível?** (ambientes sem acesso à rede para Google Fonts, confirmado esta sessão): `DejaVu Sans Condensed Bold` substitui Barlow Condensed com resultado visualmente muito próximo; `Poppins` (frequentemente já instalada) substitui Plus Jakarta Sans.

---

## 4 · Forma e ritmo

```css
--r:14px; --r-sm:9px; --r-lg:20px;      /* três raios, não mais */
--maxw:980px;                            /* largura de leitura confortável */
--shadow:0 1px 0 rgba(255,255,255,.02), 0 8px 30px rgba(0,0,0,.35);
```

---

## 5 · A estrutura real da landing page (`index.html`)

A sequência de secções, do topo ao fundo — cada uma com `id` próprio e a classe `.stage`, o que permite scroll suave e navegação por âncora:

1. **`#top` (hero)** — título grande + subtítulo + CTA duplo (ação primária + ação secundária "ver os percursos"). Tem **chips de persona** (`Família` / `Treinador` / `Clube` / `Scout`) que trocam o texto do hero consoante quem clica — a mesma página fala com quatro públicos diferentes sem os separar em páginas distintas.
2. **`#numero` (numstage)** — um número gigante que conta a subir (`data-count`), sozinho no ecrã, a estabelecer o problema antes da solução. *"2000 horas de treino até aos 14 anos. Registadas? Quase nenhuma."*
3. **`#passaporte` (reveal-stage)** — a solução, com uma curva SVG animada a desenhar-se ao entrar no ecrã (gradiente verde a esmorecer por baixo da linha), e indicadores numéricos por baixo.
4. **`#diferenca` (proof-stage)** — a prova. Nunca um número sozinho: *"4 observadores independentes · 26 eventos · 3 épocas"*. Este é o padrão mais importante de replicar noutro projeto.
5. **`#personas` (persona-stage)** — lista de linhas (`.prow`), uma por público, cada uma com: rótulo curto, uma frase de valor, e um CTA específico daquele público. Eram 8 no total nesta plataforma (pais, jogadores, treinadores, CoachBase, scouts, clubes, academias, atletas/famílias) — o número certo é o número de públicos reais que o *teu* próximo projeto tem, não este.
6. **`#precos` (price-stage)**
7. **close-stage** — CTA final, mais um canal alternativo de baixa fricção (*"Prefere falar primeiro? WhatsApp"*), e uma palavra sozinha no fim (`.whisper`) — o nome da marca, pequeno, quase um sussurro depois de tudo o resto.
8. **footer** — logo + tagline de uma linha + contactos.

**O mecanismo que amarra tudo:** a classe `.reveal` em quase todos os elementos — cada bloco nasce invisível e entra suavemente quando cruza o viewport ao scroll. Isto faz a página parecer viva sem exigir nada do utilizador além de descer.

---

## 6 · Padrões que usei nos artefactos derivados (apresentações, gráficos, páginas HTML avulsas)

Não vêm do código da plataforma diretamente, mas apliquei-os consistentemente esta sessão a tudo o que construí a partir da mesma base — vale a pena levá-los também:

- **Moldura de telemóvel para mockups de ecrã**: retângulo arredondado escuro, barra de notch fina no topo, conteúdo dentro com os mesmos tokens de cor. Sempre com a legenda *"dados ilustrativos"* quando os dados são fictícios — depois de um incidente real esta sessão em que usei um nome verdadeiro sem querer, isto passou a ser regra fixa, não opcional.
- **Radar/gráfico sem números visíveis quando o assunto é desenvolvimento de uma pessoa**: mostrar a forma (proporção, tendência) em vez do valor exato, quando o valor exato convida a comparação entre pessoas que não devia acontecer.
- **Um numeral gigante e quase transparente** (opacidade ~5%) como marca d'água de capítulo em conteúdo longo — dá orientação sem competir com o texto real.
- **Cada "capítulo" ou secção ganha um acento de cor próprio** dentro da mesma paleta (verde para uma coisa, azul para outra, dourado reservado para o clímax) — mantém a identidade unificada mas evita monotonia num documento longo.

---

## 7 · O que NÃO trazer sem adaptar

- **Copy específico da YTB** ("o passaporte digital do atleta", "livro-razão") é linguagem de domínio, não de marca — o próximo projeto precisa da *sua própria* metáfora central, não desta.
- **A distinção `--obs`/`--dec`** (observado vs. declarado) só faz sentido se o novo projeto também distinguir dados de terceiros vs. autodeclarados. Se não distinguir, não a forces.
- **O nome "YTB"** e o símbolo (círculo dourado + letra) são desta marca. Um símbolo novo para um projeto novo é rápido de fazer com o mesmo sistema — não é reutilizar o símbolo, é reutilizar o *método*.
