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

- navegação atrasada do splash pertence a um `Timer` cancelável
- callback do splash não executa depois do `dispose`
- `app_links` atrás de um seam testável
- falha no deep link de cold start é não fatal
- resolução tardia após `dispose` é ignorada
- assinatura de links é cancelada ao desmontar

Merge: PR #5.

## Fase 4 — UX e consistência ✅

- distribuição de pontos representa somente vitórias
- derrotas não criam bucket invisível `score=0`
- testes cobrem histórico misto e somente derrotas

Merge: PR #6.

## Fase 5 — Compliance e prontidão para lojas ✅

- Política de Privacidade e Termos versionados em PT/EN/ES
- Privacidade/Termos/Sobre acessíveis dentro do app
- atribuição TMDB documentada e presente no produto
- release Android falha sem assinatura configurada, exceto bypass explícito de CI
- gate automatizado de compliance

Pendências externas de publicação continuam em `docs/RELEASE_COMPLIANCE.md` (logo/licença TMDB, URLs públicas e signing de distribuição real).

Merge: PR #7.

## Fase 6 — UX/UI, navegação e product polish 🚧

Objetivo: transformar os fluxos já robustos em uma experiência coerente de produto, com contexto preservado, estados recuperáveis, design system consistente e layout adaptativo.

### 6A — Flow correctness

- [x] tornar Daily/Estágio/Desafio contexto explícito da rota e sessão
- [x] impedir estado antigo de Estágio/Desafio de vazar para o Daily
- [x] impedir o `Cineus #0` em busca/resultado/compartilhamento
- [x] validar retorno de `loadStageFilm` antes de navegar em Continuar
- [x] tratar rota de estágio inexistente sem fallback silencioso para Estágio 1
- [x] preservar retorno de jogo para o estágio de origem

### 6B — Navegação e arquitetura de informação

- [x] separar Configurações de Estatísticas
- [x] mover entrada de desafio por código para uma superfície própria acessível pela Home
- [x] adicionar navegação lateral adaptativa em telas grandes
- [ ] avaliar migração final para `StatefulShellRoute` com pilhas independentes por tab

### 6C — Experiência de jogo

- [x] tornar Dicas e Poster Daily independentes na Home
- [x] alinhar cabeçalhos com contexto Daily/Estágio/Desafio
- [x] remover empilhamento duplicado de resultado no Poster
- [x] preservar proporção 2:3 do poster ao revelar a resposta

### 6D — Resultados

- [x] compartilhamento contextual para Daily/Estágio/Desafio
- [x] próxima ação de resultado depende da origem da partida
- [x] countdown exibido somente em resultado Daily
- [ ] aproximar ainda mais a composição visual do resultado Poster do resultado Dicas

### 6E — Async UX

- [x] erros de partida tipados e localizados
- [x] retry real para Daily
- [x] Estatísticas com erro/retry e sem load duplicado
- [x] Busca com estados vazio/loading/sem resultados/erro e provider `autoDispose`
- [x] slots de estágio com erro visível + retry

### 6F — Design system e acessibilidade

- [x] mover `bodySmall`, `labelSmall`, `mono` e `monoSmall` para cores semânticas com contraste verificado
- [x] garantir mínimo de 48dp nos temas globais de botão
- [x] usar `TapTarget` nos CTAs pequenos de estágio e dicas extras
- [x] respeitar Reduce Motion no score pulsante e revelação do Poster
- [ ] concluir auditoria de text scaling extremo e VoiceOver/TalkBack

### 6G — Responsive

- [x] grid de estágios por largura, não duas colunas fixas
- [x] Stats em 2/4 colunas conforme largura
- [x] limites de largura para Home, busca, Stats, Settings e Poster
- [x] NavigationRail em telas expandidas
- [ ] concluir QA visual em landscape/tablet/iPad/Web

### 6H — Próximos itens antes do merge

- [ ] reduzir splash artificial em launches recorrentes
- [ ] completar educação contextual de tickets/estágios/poster
- [ ] corrigir timezone/permissão iOS do lembrete
- [ ] validar i18n gerada e remover strings residuais não localizadas
- [ ] adicionar testes de regressão de navegação/estado e layouts críticos
- [ ] passar por catálogo + compliance + analyzer + testes + Web + Android API 36 + iOS 26

### Gate de aceitação

A Fase 6 só pode sair de draft quando o HEAD passar por:

1. validação do catálogo;
2. validação de release compliance;
3. `flutter analyze --fatal-infos`;
4. suíte Flutter completa;
5. Web release build;
6. Android API 36 release AAB;
7. iOS/Xcode 26 release build sem assinatura.
