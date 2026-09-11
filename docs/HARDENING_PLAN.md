# Cineus — Hardening de produção (2026)

Este documento registra a sequência **nova** de hardening iniciada em setembro de 2026.
Ela é diferente das fases históricas do `ROADMAP.md`, que descrevem a evolução original do produto e mantêm sua numeração antiga por rastreabilidade.

## Fase 0 — Toolchain e CI ✅

Objetivo: estabelecer uma baseline moderna e reproduzível antes de alterar comportamento.

- Flutter 3.47.2 fixado
- Android API/target 36, Java 17, Gradle/AGP/Kotlin modernos
- iOS 15+ e validação com Xcode/iOS SDK 26+
- gate obrigatório de analyzer, testes, Web release, Android AAB e iOS release sem assinatura

Merge: PR #2.

## Fase 1 — Estado de jogo e integridade ✅

Objetivo: impedir perda de tickets/progresso e inconsistências causadas por concorrência, falhas e navegação rápida.

- serialização da economia de tickets e estornos exatos
- rollback de fluxos pagos
- proteção contra loads/actions obsoletos
- criação concorrente de sessão convergente
- sessão finalizada não pode ser ressuscitada por write atrasado
- reparo idempotente de `stage_progress`
- desafio diário usa IDs reais do catálogo

Merge: PR #3.

## Fase 2 — Banco e conteúdo ✅

Objetivo: tornar inicialização, migração e atualização do catálogo recuperáveis e atômicas.

- bootstrap do banco com retry/repair
- instalação atômica do SQLite e backup de recuperação
- `foreign_keys`, `quick_check` e `foreign_key_check`
- schema lógico canônico Web/mobile
- IDs de filmes estáveis e soft-retire
- atualização de catálogo + stages + versionamento numa única transação
- CI valida DB, JSON, TMDb IDs, 10 dicas por filme e posters

Merge: PR #4.

## Fase 3 — Resiliência de runtime ✅

Objetivo: eliminar falhas de lifecycle/plataforma que poderiam navegar ou derrubar o app fora do fluxo normal.

- navegação atrasada do splash agora pertence a um `Timer` cancelável
- o callback do splash não executa depois do `dispose`
- `app_links` ficou atrás de um seam testável, sem depender de platform channel nos testes
- falha ao resolver o deep link de cold start é não fatal
- resolução tardia de cold-start link após `dispose` é ignorada
- assinatura de links é cancelada ao desmontar
- eventos inválidos ou erros do stream não derrubam a aplicação

Merge: PR #5.

## Fase 4 — UX e consistência 🚧

Objetivo: remover estados enganosos, duplicações e becos-sem-saída ainda visíveis ao jogador, preservando a integridade conquistada nas fases anteriores.

Primeiro bloco:

- [x] distribuição de pontos passa a representar somente vitórias; derrotas deixam de criar uma faixa invisível `score=0` que distorcia a escala do gráfico
- [x] teste de regressão cobre histórico com vitórias + derrotas e histórico somente de derrotas
- [ ] eliminar o segundo `load()` concorrente ao abrir Estatísticas
- [ ] adicionar estado de erro/retry à tela de Estatísticas
- [ ] padronizar erros de carregamento de partida como estados tipados/localizados com retry
- [ ] representar corretamente Poster diário em andamento na Home
- [ ] rejeitar/redirect de rota de estágio inválida em vez de exibir Stage 1 com id inexistente
- [ ] limpar/isolar estado de busca entre Dicas e Poster e mostrar loading/erro/sem resultados
- [ ] localizar datas do histórico e nomes de estágios
- [ ] remover feedback duplicado de franquia entre Dicas e Poster
- [ ] revisar timers/listeners restantes e o timezone do lembrete

### Gate de aceitação

A Fase 4 só pode ser mesclada quando o HEAD do PR passar por:

1. validação do catálogo;
2. `flutter analyze --fatal-infos`;
3. suíte Flutter completa;
4. Web release build;
5. Android API 36 release AAB;
6. iOS/Xcode 26 release build sem assinatura.
