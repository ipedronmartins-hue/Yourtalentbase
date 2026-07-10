# CLAUDE.md · YourTalentBase

Ler antes de tocar em qualquer coisa neste repositório. Este ficheiro é o resumo operacional; a lei completa está em `YTB_CONSTITUTION.md` e prevalece em caso de conflito.

## O que é a YTB
Registo longitudinal, verificado e multi-observador do desenvolvimento de jovens futebolistas. O produto é o **Passaporte Digital**: pertence ao atleta, acompanha-o entre clubes e épocas. Stack: HTML single-file + Supabase + Vercel + GitHub. Site: yourtalentbase.pt.

## Como pensar aqui (não é opcional)
Cada feature é avaliada em duas frentes ao mesmo tempo — engenharia **e** negócio. Antes de construir, responde:
- Fecha um círculo (quem alimenta o sistema recebe valor)? Se abre um círculo novo sem o fechar, para.
- Entra no loop de crescimento (scout→atleta→passaporte→família→treinador→partilha→novo utilizador) ou é uma ilha? Ilhas não se constroem.
- Aumenta retenção, receita, partilha ou orgulho? Se não faz nenhuma, propõe alternativa antes de escrever código.

Pensa à escala de líder mundial, mas **nunca** deixes a ambição suprimir a honestidade: não inflar números, não esconder riscos, manter crítica adversarial mesmo em modo growth. O fundador quer ideias testadas ao limite, não validadas.

## Divisão de trabalho por modelo (o fundador organiza sessões assim)
- **Opus** — produto e estratégia: questionar fluxos, UX, novas features, crescimento, concorrência, visão a 5 anos. Nunca aceitar um MVP só porque funciona.
- **Sonnet** — engenharia: implementar, refatorar, testar, performance, segurança, validar RLS/RPC/migrações/Supabase/GitHub. Entregar robusto, não só funcional.
- **Fable** — criativo: campanhas, landing pages, copy, branding, redes sociais, funis.

Isto é uma convenção de organização humana. Cada sessão é um único modelo a trabalhar — não há agentes paralelos. Confirmar sempre com as ferramentas reais disponíveis (GitHub, Supabase, Vercel, pesquisa web); nunca assumir capacidades ou dados.

## Regras técnicas inquebráveis
- **Livro-razão primeiro:** todo o facto relevante emite evento em `atleta_eventos`, na mesma transação da escrita. O que não está no livro, não aconteceu.
- **Escrita só por RPC** `security definer` com verificação de papel no servidor. O cliente nunca escreve direto em tabelas.
- **RLS deny-by-default** em todas as tabelas; toda a policy vive no repo.
- **Migrações numeradas e imutáveis**, aplicadas por ordem (ver `supabase/migrations/`). **Staging antes de produção, sempre** — há dados de crianças reais em produção.
- `atleta_eventos` é imutável: sem UPDATE/DELETE; correções são novos eventos.
- Sem framework de frontend até ao gatilho (1º contrato B2B pago ou 1ª contratação técnica). Nada de microserviços ou engenharia especulativa.
- Segredos só server-side. Validação verde local antes de apresentar (SQL em Postgres, JS em Node, isolamento entre famílias testado).

## O que nunca fazemos
1. Nunca expor publicamente notas/classificações de menores. A montra mostra percurso, nunca veredicto.
2. **Nunca vender acesso a menores.** Monetiza-se o serviço de desenvolvimento, nunca a criança. Esta linha é a marca.
3. Nunca prometer no ecrã o que o sistema não faz.
4. Nunca token/PIN em links para dados de menores — a chave é a sessão autenticada.
5. Nunca escrever no domínio sem emitir o evento.
6. Nunca o cliente a escrever direto numa tabela.
7. Nunca SQL em produção sem passar por staging.
8. Nunca feature nova enquanto houver um círculo aberto (Regra de Ouro).
9. Nunca reescrever o que está correto — corrige-se a sequência, não se recomeça.
10. Nunca deixar a verificação de identidade depender para sempre de um terceiro (ZeroZero é andaime).

## Modelo de negócio (âncora)
O cliente é a **entidade** (academia/escola/clube). A **família é funil, gratuita** — paga no máximo extras de orgulho (anuário, relatório de época). Subscrição familiar para ver o próprio filho: proibida (envenena o moat). O relatório à família é a peça central de valor.

## Ordem de desenvolvimento
Fase 0 Blindagem (M1) → Fase 1 Fechar Círculos (M2) → Fase 2 Academia (M3) → Fase 3 UX (M4) → Fase 4 Diferenciação (M5). Não avançar de fase com a anterior por fechar.

## Protocolo antes de qualquer feature nova
1. Verificar contra "O que nunca fazemos". 2. Verificar a Regra de Ouro (círculos abertos?). 3. Verificar a fase (pertence ao mandato atual?). 4. Em conflito: parar, explicar, propor alternativa. Só depois, código.
