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

## Fase 4 — UX e consistência ✅

Objetivo do bloco entregue: corrigir uma inconsistência visível das Estatísticas antes de entrar no hardening de release.

- distribuição de pontos representa somente vitórias
- derrotas não criam mais um bucket invisível `score=0` que reduz visualmente todas as barras 1–10
- testes cobrem histórico misto e histórico somente de derrotas

Merge: PR #6.

Os demais itens de polish/UX identificados na auditoria permanecem no backlog para o passe final de QA, depois da conformidade de release.

## Fase 5 — Compliance e prontidão para lojas 🚧

Objetivo: impedir que uma build tecnicamente saudável seja enviada às lojas sem os artefatos legais, atribuições e proteções de publicação necessários.

Primeiro bloco:

- [x] adicionar Política de Privacidade e Termos de Uso versionados em PT/EN/ES
- [x] tornar Privacidade/Termos acessíveis dentro do aplicativo
- [x] criar seção `Sobre e créditos` acessível nas configurações
- [x] incluir o aviso obrigatório do TMDB na seção de créditos
- [x] documentar obrigações pendentes do TMDB, incluindo logo oficial e licença comercial quando aplicável
- [x] impedir release Android silenciosamente assinado com chave debug
- [x] permitir chave debug no CI somente por bypass explícito e não publicável
- [x] adicionar gate automatizado de compliance ao CI
- [ ] adicionar ao app um logo oficial/aprovado do TMDB
- [ ] publicar Privacy/Terms em URL pública estável e cadastrar nas lojas
- [ ] revisar metadados Web/Android/iOS de release
- [ ] remover versão hardcoded exibida ao usuário
- [ ] validar assinatura/distribuição real Android e iOS

Detalhes: `docs/RELEASE_COMPLIANCE.md`.

### Gate de aceitação

A Fase 5 só pode ser mesclada quando o HEAD do PR passar por:

1. validação do catálogo;
2. validação de release compliance;
3. `flutter analyze --fatal-infos`;
4. suíte Flutter completa;
5. Web release build;
6. Android API 36 release AAB;
7. iOS/Xcode 26 release build sem assinatura.
