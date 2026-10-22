# Implementação da auditoria de produto — 19/10/2026

Pedido: implementar o plano completo de `docs/business/audit-2026-10-19/RELATORIO.md`.

## Execução

- [x] Sprint 1: calendário publicado e estável; pontuação relativa; recompensa atômica; estatísticas por contexto; eventos dos três modos.
- [x] Sprint 2: missões rotativas e substituição de duplicatas; sequência de presença; próxima meta/continuar; domínio por tema; entrada rápida.
- [x] Sprint 3: banner adaptável real com consentimento; intersticial em transição e reservas recuperáveis; telemetria com outbox/consentimento; parâmetros e grupo de controle.
- [x] Sprint 4: tempo confiável; consumíveis verificados e ledger de saldo; backup/recuperação; economia versionada com migração.
- [x] Sprint 5: arquivo de diários; revanche de treino; feedback editorial; convites neutros e landing HTTPS; confronto assíncrono.
- [x] Verificação local: migrações, regressões, análise estática, backend, renderização e galeria. Testes com lojas e SDKs em aparelhos reais permanecem na ativação externa.

IDs/produtos de lojas, publicação do backend/domínio, contratos e autorização dos titulares não são fabricados pelo aplicativo. O código deve ter estados operacionais e testes para esses fluxos; a ativação externa permanece identificada como dependência.

Diretrizes: preservar saldos e sessões; nenhum custo oculto; não criar urgência fictícia, competidores falsos ou mecânicas de cassino; experimentos opcionais e versionados; não iniciar PvP em tempo real/clãs/chat (itens adiados no relatório).

## Entregas no código

1. **Consistência e progresso.** Calendário imutável com 1.500 dias a partir de 20/10/2026, sem repetir filmes em qualquer janela de 500 dias por modo; os 50 personagens aparecem em cada janela de dez dias. Partidas já salvas mantêm seus conteúdos. O resultado de Pôster usa sua escala de cinco pontos. Créditos de conclusão usam recibos transacionais, com recuperação de resultados pendentes. Estatísticas separam diário, estágios, convites e prática.
2. **Retorno.** Missões variam objetivos e recompensas, preservam a oferta já registrada e compensam cosméticos repetidos com dois tickets creditados uma vez. Três avatares novos foram criados por ImageGen. Presença inclui dias com derrotas, sem simular vitórias. Início permite continuar a partida ou ver a próxima meta. Domínio inclui três temas editoriais de dez filmes e revisão gratuita dos erros. Entrada rápida opcional com exemplo jogável.
3. **Publicidade e medição.** Componente de banner adaptável do SDK, consentimento, descarte fora de tela, estados de indisponibilidade e valor por moeda. Intersticial condicionado ao toque em Próximo, com reserva separada da impressão. Mantidos os dois fluxos recompensados e verificação no servidor. Telemetria opcional com fila limitada, consentimento e exclusão; relatório agregado de coortes observadas e eventos. Grupo de controle persistente e configuração assinada, limitada a parâmetros permitidos.
4. **Economia.** Relógio autenticado com validade, proteção contra retrocesso, packs consumíveis de 20 e 60 tickets, saldo comprado separado e ledger remoto com operações idempotentes. Backup opcional de progresso, revisão para conflitos e recuperação por credencial; não importa saldo local como moeda comprada. Contrato de bônus por estágio: estágios anteriores mantêm dez; experimento de quatro tickets só entra para estágios novos de contas selecionadas no servidor. Tratamento adiciona título visual. Rollout padrão: zero.
5. **Conteúdo e social.** Arquivo nos três modos, treino de revanche em Cores sem substituir o resultado, feedback editorial em fila, opção de cartão neutro e convites privados assíncronos com um convidado e validade de sete dias. Tentativa do convidado é separada de desafios anteriores. Pontuações informadas pelo aparelho não servem como ranking competitivo nem geram prêmios. Landing estática HTTPS preparada, sem publicação automática.

## Onde conferir

- [Galeria de renderizações Flutter](../preview/growth-2026-10-19/GALERIA.html).
- [Configuração e operação desta entrega](../business/audit-2026-10-19/ATIVACAO.md).
- [Origem das novas artes](../artwork/mission-v2-prompts.json).

## Limites da entrega

Os checks acima indicam implementação, não ativação comercial. Não foram usados IDs de anúncios reais, compras reais, domínio, conta de hospedagem ou permissões de conteúdo inventadas. A configuração padrão mantém publicidade e vendas indisponíveis, conforme solicitado. Testes locais usam respostas controladas para rede, SDK e loja; não equivalem a Internal Testing/TestFlight, SSV genuíno ou reconciliação financeira.

Não foi gerado APK nesta entrega. iOS requer compilação e testes em macOS/aparelho. Não foi executado experimento com jogadores nem medido aumento de retenção ou receita.

## Validação final

- **824 testes Flutter aprovados**, suíte completa com dois processos: `flutter test --no-pub --concurrency=2`.
- **64 testes do servidor aprovados**, incluindo idempotência, autenticação, backup, expiração de métricas e saldo comprado. Um aviso de depreciação da dependência de testes Starlette/httpx permanece; não é falha de execução.
- **Análise estática sem problemas:** `flutter analyze --no-pub --fatal-infos`.
- Oito validadores de calendário, catálogo, artes, uso e preparo de release aprovados. Inventário de direitos registra quatro grupos ainda sem evidência comercial.
- Manifesto Android debug validado. A tarefa `verifyCineusReleaseSigning` recusou corretamente a ausência de keystore; release não recebe assinatura debug automaticamente. Permanecem avisos de migração futura do Gradle/AGP.
- **29 PNGs reais do Flutter**, com variantes em três idiomas e texto de 200%; links locais da galeria conferidos.

Logs e interpretação em [evidências de validação](../preview/growth-2026-10-19/validation/README.md).
