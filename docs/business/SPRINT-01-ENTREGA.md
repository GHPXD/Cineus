# Monetização — entrega da Sprint 1

**14/10/2026 · Fundação comercial, economia e medição**

## Implementação

- Catálogo tipado de Coleção Estreia, Plus permanente e Clube mensal; benefícios e IDs internos separados. Nenhum preço de planejamento apresentado como oferta confirmada de loja.
- Contratos de ofertas, compra, direitos e restauração. Adapter padrão indisponível; Pass genérico antigo protegido e sem exposição como novo produto.
- Configuração por ambiente e flags independentes, desligadas por padrão. Uma flag não cria SDK, preço, consentimento ou produto real.
- Auditoria local transacional de tickets: inicialização, renovação UTC, débito, estorno, bônus, recompensa única local e início atômico de partida. Limite de registros, sem inventar consumo passado.
- Migração aditiva do schema lógico 3 para 4, preservando saldo, progresso e catálogo.
- Diagnóstico local opcional, sem envio, com whitelist de campos e janela/limite de registros. Eventos de atividade, guias, abertura/conclusão dos três modos, necessidade de tickets e fluxos de monetização existentes.
- Isolamento de falhas de analytics: erro de diagnóstico não invalida um crédito ou impede a operação principal.
- Script de relatório agregado de cópia SQLite somente leitura e documentação de operação em [MONETIZATION.md](../MONETIZATION.md).

Não há novos assets visuais nesta etapa; a coleção visual pertence às sprints 2–3. Não foi gerado APK ou apresentação de antes/depois.

## Economia preservada

20 tickets gratuitos por dia UTC, bônus e retomada gratuita mantidos. Rewarded segue definido como +2, no máximo três recompensas por dia; SDK real e verificação comercial robusta são sprint 6.

Recompensas de conclusão de estágios e diários podem reduzir a demanda por tickets. O histórico permite observar movimentos futuros; não demonstra necessidade de vídeos ou compras por si só. Diagnóstico local não substitui recibos comerciais nem verificação antifraude em backend.

## Métricas e retenção

Eventos atuais permitem demonstrar os pontos instrumentados. Contratos de prévia, coleção e compras estão reservados para as próximas sprints; não se fabricam eventos de funcionalidades inexistentes.

Definições para operação futura:

| Métrica | Definição |
|---|---|
| Primeira partida concluída | Instalações elegíveis que concluem sua primeira partida / instalações elegíveis |
| D1/D7/D30 | Retorno no dia correspondente após instalação por coorte; depende de identidade/observação apropriadas |
| Necessidade de tickets | Consumo, entradas, estornos e tentativas com saldo insuficiente |
| Adesão a rewarded | Escolhas / ofertas elegíveis, separando disponibilidade e crédito |
| Conversão | Compradores novos validados / público elegível, por produto/plataforma |
| Receita | Relatórios reconciliados de lojas/rede, com comissão/reembolsos aplicáveis; clique não é venda |

Um banco de um aparelho não determina população, retenção ou receita real. O diagnóstico opcional tem 60 dias/2.000 eventos, limpos ao gravar/consultar. Auditoria de tickets tem o mesmo limite/janela, limpos nas movimentações. Recibos existentes de proteção contra recompensa duplicada permanecem. Não há SDK de transmissão nem coleta de nomes, palpites e comprovantes nos eventos permitidos.

## Dependências externas

| Dependência | Situação nesta entrega | Etapa afetada |
|---|---|---|
| Google Play Console e produtos | Acesso/configuração não confirmados; nenhum produto consultado | Sprint 5 |
| App Store Connect e produtos | Acesso/configuração não confirmados; nenhuma oferta consultada | Sprints 5 e 10 |
| macOS/Xcode e iPhone | Ambiente atual Windows; build/teste iOS não realizados nesta sprint | Validação externa iOS |
| Rede de anúncios e unidades | Sem SDK real e nenhum anúncio veiculado | Sprints 6 e 8 |
| Backend e hospedagem | Contratos de cliente preparados; nenhuma infraestrutura contratada/implantada | Sprint 4 |
| Público etário pretendido | Não confirmado; nenhuma faixa comercial foi inventada | SDKs, privacidade e lojas |
| Direitos TMDB, pôsteres e personagens | Origens registradas não comprovam autorização comercial; escopo/licenças não demonstrados | Ativação comercial |
| Operador e suporte comercial | Conferir dados reais antes de ativar provedores; fluxos locais existentes mantidos | Fechamento |
| Patrocinador/contrato | Nenhuma contratação demonstrada ou mensagem enviada | Sprint 11 |

Essas pendências não impedem a coleção local da Sprint 2. Não equivalem a integrações externas concluídas nem receita disponível. Credenciais e implantação serão necessárias nas etapas correspondentes; nenhum segredo foi embutido no código.

## Segurança

Aplicada a skill secure-code-guardian à superfície desta sprint: confusão de benefícios, ativação por flag, dados privados em diagnóstico, falha de analytics após crédito e escrita parcial de saldo.

Controles: tipos e vigência independentes, ofertas reais obrigatórias, adapters indisponíveis por padrão, whitelist, SQL com parâmetros, transação e armazenamento limitado. Não há endpoints, autenticação, validação criptográfica de recibos ou sincronização entre plataformas nesta sprint. O objeto de direito é contrato para uma origem confiável futura; um valor criado no cliente não prova pagamento.

## Validação

Testes específicos cobrem vigência/revogação, ausência de ofertas fictícias, filtragem de dados, retenção, rollback de saldo, crédito único, instalação existente e falha de analytics durante recompensa/compra.

- Suíte completa executada: **701 testes aprovados**, em `docs/maintenance/monetizacao-sprint-01-tests-final.log`.
- Após essa execução, foi acrescentado e aprovado separadamente um teste de integração dos providers reais. O arquivo de diagnóstico atualizado tem seis testes aprovados, em `docs/maintenance/monetizacao-sprint-01-diagnostics-final.log`; cinco já integravam a suíte acima.
- Análise estática sem problemas, em `docs/maintenance/monetizacao-sprint-01-analyze-final.log`.
- Verificadores de publicação e de uso: aprovados; 164 arquivos Dart de produção alcançáveis e 1.055 assets/origens registrados.
- Relatório Python testado em uma cópia SQLite: saída agregada, conteúdo do arquivo preservado e conexão fechada após a leitura.
- Testes de recuperação usam esperas limitadas para SQLite real, evitando bloquear operações nativas dentro do relógio simulado de testes de interface.

**Situação:** implementação da Sprint 1 concluída. Dependências externas foram registradas para as próximas etapas; não foram apresentadas como integrações já operacionais.
