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

## Fase 3 — Resiliência de runtime 🚧

Objetivo: eliminar falhas que só aparecem durante lifecycle/plataforma e garantir que integrações auxiliares nunca derrubem ou naveguem o app de forma inesperada.

Primeiro bloco:

- [x] cancelar a navegação atrasada do splash quando o widget é desmontado
- [x] conter falhas do `app_links` no cold start
- [x] ignorar resolução tardia de deep link após `dispose`
- [x] cancelar a assinatura de links ao desmontar
- [x] criar seam testável para deep links sem platform channel
- [ ] padronizar erros de carregamento como estados tipados/localizados, com ação de retry
- [ ] remover feedback duplicado de franquia entre Dicas e Poster
- [ ] revisar lifecycle de timers/listeners restantes
- [ ] corrigir resolução de timezone do lembrete para uma zona IANA real em vez de offset fixo

### Gate de aceitação

A Fase 3 só pode ser mesclada quando o HEAD do PR passar novamente por:

1. validação do catálogo;
2. `flutter analyze --fatal-infos`;
3. suíte Flutter completa;
4. Web release build;
5. Android API 36 release AAB;
6. iOS/Xcode 26 release build sem assinatura.
