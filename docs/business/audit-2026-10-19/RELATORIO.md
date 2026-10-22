# Cineus — análise de produto, retenção e rentabilidade

**Data: 19 de outubro de 2026 · Android e iOS · Brasil**

Relatório baseado no código e conteúdo locais, testes executados nesta revisão, renderizações do Flutter e fontes públicas primárias. O foco é a receita dentro do jogo, especialmente anúncios; aquisição paga de usuários fica fora desta análise. Nenhuma regra do aplicativo foi alterada nesta entrega.

## 1. Parecer

**O Cineus já tem conteúdo e infraestrutura suficientes para testar um negócio. Ainda não há evidência de que seu ciclo de retenção ou sua economia funcionem com jogadores reais.** A próxima evolução deve conectar diversão, progresso e receita, corrigindo inconsistências antes de acrescentar novos sistemas comerciais.

A proposta mais promissora é um jogo de memória e cultura pop em sessões curtas: um desafio diário compartilhado, uma jornada de estágios e ajuda opcional por vídeo. Cores acrescenta variedade visual; Dicas e Pôsteres aproveitam a familiaridade com cinema. Isso é uma boa combinação de produto, mas os componentes ainda parecem mais completos individualmente do que como um ciclo único.

As decisões que recomendo agora são:

1. Corrigir seleção repetitiva dos pôsteres, feedback de pontuação e estatísticas que escondem partidas de estágio.
2. Medir o funil real antes de reduzir mais tickets ou aumentar anúncios.
3. Rever a devolução integral de tickets nos estágios e as missões que repetem os mesmos cosméticos.
4. Priorizar dois anúncios recompensados úteis: ajuda durante a rodada e reposição de tickets. Banners discretos são uma integração adicional, não uma funcionalidade já pronta.
5. Dar ao jogador uma próxima meta pessoal e uma recompensa nova por semana, sem transformar o Início em uma loja.
6. Fazer backup de progresso e proteção econômica antes de vender tickets de verdade.
7. Comprovar as permissões de conteúdo e concluir a configuração comercial antes da ativação pública.

Não recomendo começar por PvP em tempo real, clãs, chat, gacha ou um passe complexo. O custo de conteúdo, suporte e operação pode consumir a receita de um jogo pequeno.

## 2. O que foi verificado

| Área | Evidência atual |
| --- | --- |
| Catálogo de filmes | 500 filmes, 5.000 dicas e 500 pôsteres locais; nenhum filme sem diretor, ano, duração ou caminho de pôster na consulta estrutural |
| Cores | 50 personagens, 110 perguntas/partes e 11 estágios de 10 personagens distintos, divididos em duas partidas de cinco |
| Código | 200 arquivos Dart; aproximadamente 42 mil linhas incluindo localizações geradas |
| Economia | 10 tickets diários, bônus persistentes, início e ajuda por 1 ticket; vídeo entrega 2 tickets; ajuda por vídeo usa 1 e conserva 1 |
| Comércio | Cinco produtos internos: três coleções, Plus permanente e Clube mensal; pacotes de tickets continuam como placeholders |
| Retenção | Diários, estágios, conquistas, três missões semanais, descoberta, personalização de cartão, convites e lembrete local |
| Anúncios | Adaptadores de recompensado e intersticial, consentimento e verificação de recompensa; espaços de banner continuam somente visuais |
| Testes executados | 803 testes Flutter aprovados; 57 testes do backend aprovados; análise estática sem problemas |
| Verificação visual | Nova execução de captura com roteador e widgets reais, em 390 × 844; imagens geradas em resolução dupla |

Os testes do backend passaram na execução fora das restrições do sandbox. A tentativa inicial esbarrou na criação de diretórios temporários; isso não foi classificado como defeito do jogo. Há um aviso de depreciação do conjunto FastAPI/Starlette/httpx que merece manutenção de dependências, sem falha nessa suíte.

**Limites:** não houve teste novo em aparelho físico, distribuição TestFlight, compra real, impressão real do AdMob, medição de bateria ou ensaio de carga do servidor. As capturas usam dados controlados e relógio de fixture de 13/10/2026; foram renderizadas em 19/10. Testes aprovados não comprovam retenção, faturamento ou ausência de bugs semânticos. Não foi feito um pentest completo nem uma avaliação jurídica conclusiva.

## 3. Comparação com o mercado: o que está validado e o que é hipótese

É preciso distinguir três níveis de evidência: **uma mecânica existe num concorrente**, **o proprietário publicou resultado de um experimento**, e **ela funciona no Cineus**. Só os dois primeiros podem ser sustentados hoje; o terceiro exige dados nossos.

| Referência | Evidência observável/publicada | Aplicação ao Cineus |
| --- | --- | --- |
| Framed | Diário de reconhecimento de filmes, variantes Classic/One Frame/Poster e arquivo de dias anteriores | Validar uma rotina curta e disponibilizar um arquivo para quem quer continuar; não é prova de lucratividade do Cineus |
| Toon Tone | Memória de cores em cinco rodadas, ajuste HSB, pontuação, personagens e novidades semanais; acesso pelo navegador | O conceito de Cores já tem concorrência direta. Diferenciar por progressão, qualidade editorial e experiência mobile, em vez de apenas aumentar personagens |
| Trivia Crack | Power-ups adquiridos com tickets e segunda chance por vídeo na versão com anúncios | Ajuda contextual tem precedente direto em trivia. Evitar a resposta automática: ela destrói a sensação de mérito que faz o resultado valer |
| Royal Match | Vidas, coleções, eventos, perfil e recuperação de progresso; a coleção só é apresentada após progressão inicial | Revelação gradual de sistemas e metas de coleção. Não copiar sua economia ou esforço de operação para um projeto pequeno |
| Duolingo | Experimento publicado separou a sequência da meta diária e informou aumento relativo de 3,3% em retenção D14 | Uma sequência fácil de manter pode ser melhor que exigir desempenho perfeito. O efeito num app educacional não se transfere automaticamente para este jogo |
| Boxing Star / Four Thirty Three | Caso publicado pelo AdMob relata aumento de 15% na receita com recompensados e otimização por métricas | Anúncio como troca de valor e análise por contexto. O caso é selecionado pelo fornecedor e não uma promessa de receita ou experimento independente para o Cineus |

Fontes: [Framed](https://framed.wtf/), [Toon Tone](https://toontone.app/pt/), [Trivia Crack — power-ups](https://triviacrack.help.etermax.com/hc/en-us/articles/360024775733-Power-ups), [Royal Match — coleção](https://dreamgames.helpshift.com/hc/en/3-royal-match/faq/332-what-is-collection/), [Duolingo — experimento de sequência](https://blog.duolingo.com/improving-the-streak/), [caso Four Thirty Three](https://admob.google.com/home/resources/four-thirty-three-uses-admob-to-boost-mobile-game-revenue-15-percent/).

O relatório GameAnalytics 2026, com dados de 2025 de mais de 16 mil jogos mobile e corte mínimo de 1.000 usuários mensais, apresenta medianas aproximadas de D1 em 22%, D7 abaixo de 4% e D30 em 0,7–0,8%; o quartil superior aparece pouco acima de 30% em D1 e em 6–7% em D7. **São referências amplas de vários gêneros e países, não um benchmark específico de trivia brasileira nem da fase inicial deste projeto.** O relatório não oferece corte por gênero nessa edição. [GameAnalytics — metodologia e resultados](https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks).

Minha leitura: há mercado para sessões curtas e hábito diário, mas a concorrência gratuita no navegador aumenta a exigência sobre instalação, primeiro uso e qualidade. O Cineus precisa oferecer progresso e conveniência que justifiquem voltar ao aplicativo.

## 4. Problemas encontrados, com prioridade e consequência

P0 significa requisito para ativação comercial pública; P1, correção de alto impacto; P2, melhoria importante que pode seguir na sequência. A prioridade expressa meu julgamento sobre este produto, não uma classificação automática de vulnerabilidade.

| ID | Prioridade | Constatação | Consequência e recomendação |
| --- | --- | --- | --- |
| A01 | P0 | Ads/compras permanecem desativados por padrão e não há telemetria de população | Não existe validação de negócio. Configurar operação e medição, conservando placeholders apenas nas builds de apresentação |
| A02 | P0 | A origem das artes está registrada, mas não encontrei comprovação completa de permissões comerciais no repositório | Auditar licenças de dados, pôsteres e personagens antes da publicação monetizada; crédito e origem não bastam |
| A03 | P1 | O diário de Pôsteres repete uma fração pequena do catálogo | Publicar calendário sem repetição próxima, mantendo os dias já jogados estáveis |
| A04 | P1 | Estágio concluído de Dicas/Pôsteres devolve 10 tickets | A devolução neutraliza os dez inícios quando não há falhas ou ajudas. Testar uma fonte menor de tickets com recompensa visual de progresso |
| A05 | P1 | As três missões semanais sempre entregam os mesmos itens | A segunda semana perde novidade. Criar rotação e tratamento explícito de item já possuído |
| A06 | P1 | Progresso do jogo é local; identidade comercial não é uma conta de progresso | Reinstalação/troca de aparelho podem interromper a história do jogador. Implementar backup/restauração antes de investir em coleção e gastos recorrentes |
| A07 | P1 antes de vender moeda | A diária renova quando a data local é diferente da anterior, inclusive ao retroceder o relógio | Acrescentar data máxima conhecida e tempo confiável; a moeda comprada precisa de livro-razão próprio e idempotente |
| A08 | P1 | Recompensas de partidas usam gravações separadas de resgate e saldo | Uma interrupção do processo entre as gravações pode registrar resgate sem crédito. Unificar em transação ou fluxo recuperável |
| A09 | P1 antes de ativar intersticial | Existe disparo após dez segundos de inatividade no resultado | Pode surpreender quem está lendo. Substituir por oportunidade na transição natural, com anúncio previamente carregado |
| A10 | P2 | Pôster perfeito 5/5 fica amarelo | Escala visual absoluta de 10 aplicada a um modo de 5. Normalizar a faixa pelo máximo de cada modo |
| A11 | P2 | Estatísticas principais de Dicas/Pôsteres só usam diários | O jogador de estágios pode ver zero jogos. Separar filtro de contexto e mostrar também a atividade de estágios |
| A12 | P2 | Reserva de intersticial já consome frequência mesmo sem exibição | Uma oportunidade cancelada pode reduzir a receita sem uma impressão. Separar reserva, exibição e expiração |
| A13 | P2 | Tutorial de Cores pode ser registrado como Pôster na telemetria geral | Corrigir mapeamento de três modos antes de interpretar conversão por modo |
| A14 | P2 | Link de convite cai em esquema próprio quando não há domínio público | Quem não tem o app não recebe uma entrada web útil. Entregar domínio HTTPS, página de destino e preservação do desafio |

### A03. Repetição dos diários

A reprodução da fórmula atual, com os 500 filmes e incluindo a correção que impede Dicas/Pôsteres de coincidirem no mesmo dia, produziu:

| Janela encerrada em 19/10/2026 | Filmes distintos em Dicas | Filmes distintos em Pôsteres | Dias adicionais usando pôster já sorteado na janela |
| --- | --- | --- | --- |
| 30 dias | 30 | 29 | 1 |
| 90 dias | 90 | 47 | 43 |
| 365 dias | 333 | 131 | 234 |

Essa é uma **simulação do seletor**, não histórico coletado de jogadores. A causa está em aplicar multiplicação, máscara de 32 bits e módulo sobre o catálogo; isso não cria um calendário balanceado. Entre as repetições de Pôsteres dessa simulação há intervalos de 28 dias.

Solução: manifesto editorial versionado por data e modo, com ordem pseudoaleatória sem repetição e revisão de dificuldade. Preservar sessões existentes; uma atualização não pode trocar o filme que alguém já começou. Também é preciso manter o mesmo diário entre versões do catálogo e oferecer cache offline de uma janela definida.

Evidência: [daily_selector.dart:12](C:/Projects/Cineus/lib/core/utils/daily_selector.dart:12), [evidencias.json](C:/Projects/Cineus/docs/business/audit-2026-10-19/evidencias.json).

### A04 e A05. A recompensa precisa significar avanço

Hoje, dez inícios de um estágio custam dez tickets e sua conclusão rende dez. O custo líquido pode ser zero para quem vence cada filme na primeira partida e não compra ajudas. Isso é amigável, mas reduz o motivo de consumir vídeo ou comprar reposição. Não se trata de crédito duplicado: é uma escolha econômica pouco alinhada ao objetivo de receita.

As três missões semanais exigem três partidas, três modos e três dias e sempre apontam para as mesmas três artes. Um novo resgate semanal gera outra origem de posse do mesmo item, não uma nova recompensa visual. A repetição pode fazer uma tela tecnicamente funcional parecer vazia ou bugada ao jogador.

Solução: variar objetivos e recompensas em ciclos pequenos; premiar etapa concluída com domínio, título ou peça de coleção. Para itens repetidos, informar antecipadamente a substituição garantida; não mostrar um desbloqueio novo de algo que já é do jogador.

Evidência: [ticket_reward.dart:44](C:/Projects/Cineus/lib/domain/entities/ticket_reward.dart:44), [journey_repository.dart:30](C:/Projects/Cineus/lib/data/repositories/journey_repository.dart:30), [journey_repository.dart:105](C:/Projects/Cineus/lib/data/repositories/journey_repository.dart:105).

### A07 e A08. Integridade da economia

O reset aceita uma data diferente sem exigir que seja posterior. Portanto, avançar ou retroceder a data pode renovar o saldo diário. A verificação SSV do servidor protege a entrega de vídeos, mas não torna confiável todo o saldo local. Não é necessário colocar cada ação de treino online; é necessário separar claramente progresso offline, brindes locais e moeda comprada.

Além disso, o fluxo de recompensa de partidas primeiro registra o resgate e depois chama o crédito. A compensação funciona quando há exceção capturada; um encerramento do processo entre essas operações não executa a compensação. Isso é um risco de durabilidade identificado por inspeção, não um fechamento reproduzido no celular nesta revisão. A solução deve reaproveitar o padrão transacional/idempotente já usado em outros créditos.

Evidência: [ticket_notifier.dart:97](C:/Projects/Cineus/lib/presentation/providers/ticket_notifier.dart:97), [ticket_notifier.dart:125](C:/Projects/Cineus/lib/presentation/providers/ticket_notifier.dart:125), [reward_notifier.dart:62](C:/Projects/Cineus/lib/presentation/providers/reward_notifier.dart:62).

### A09, A10 e A12. Feedback e anúncios

O intersticial está desligado por padrão, mas seu fluxo preparado aguarda dez segundos sem interação no resultado. A política do Google orienta que intersticiais apareçam em pausas naturais e não surpreendam alguém já concentrado no conteúdo. Recomendo revisar esse disparo antes da ativação, sem declarar que uma violação já ocorreu. [Orientações oficiais sobre intersticiais](https://support.google.com/admob/answer/6201362?hl=en).

O registro de frequência considera todas as reservas e não apenas as que chegaram a `shown=1`; uma navegação ou mudança de direito após a reserva pode gastar a oportunidade. É uma limitação de capacidade publicitária ainda latente.

No cartão, `score >= 7` fica verde e `score >= 4` fica amarelo, independentemente do modo. Como Pôsteres vale até 5, um perfeito nunca fica verde. Normalizar por desempenho relativo, usando a mesma função no cartão e no texto compartilhado; manter as escalas originais visíveis, por exemplo 5/5 e 10/10.

Evidência: [result_break.dart:45](C:/Projects/Cineus/lib/presentation/widgets/result_break.dart:45), [interstitial_repository.dart:100](C:/Projects/Cineus/lib/data/repositories/interstitial_repository.dart:100), [share_grid_widget.dart:73](C:/Projects/Cineus/lib/presentation/widgets/share_grid_widget.dart:73), [scoring_rules.dart:24](C:/Projects/Cineus/lib/domain/entities/scoring_rules.dart:24).

### A11, A13 e A14. O jogador precisa perceber sua história

O cálculo principal de Dicas/Pôsteres consulta apenas sessões diárias. Isso é coerente como histórico do diário, mas inadequado como estatística geral do jogador de estágios. Recomendo um seletor curto de contexto e um resumo inicial que reconheça a atividade em todos os modos, sem somar pontuações incompatíveis.

No tutorial geral, a expressão binária de evento trata todo modo diferente de Dicas como Pôster, incluindo Cores. E os convites já têm códigos e tratamento de deep link, mas o domínio HTTPS é opcional; isso ainda não constitui um funil de indicação completo para novos jogadores.

Evidência: [game_repository_impl.dart:193](C:/Projects/Cineus/lib/data/repositories/game_repository_impl.dart:193), [how_to_play_screen.dart:59](C:/Projects/Cineus/lib/presentation/screens/how_to_play_screen.dart:59), [challenge_code.dart:34](C:/Projects/Cineus/lib/core/utils/challenge_code.dart:34).

## 5. Melhorias de experiência por fluxo

| Fluxo | O que manter | Próxima melhoria |
| --- | --- | --- |
| Primeiro uso | Identidade visual, exemplos interativos e entrada sem conta obrigatória | Uma rodada guiada curta antes de explicar economia, coleção e temporadas; oferecer ajuda conforme a necessidade |
| Início | Três modos, ordem atual e CTA claro | Quem tem partida aberta deve encontrar Continuar imediatamente. Nos cards laterais, usar apenas título/ícone, evitando descrições quebradas em várias linhas |
| Estágios | Consistência de tags e cards, silhuetas de bloqueados | Mostrar uma meta temática e o prêmio da próxima etapa; reduzir a repetição de Começar · 1 ticket quando o custo já aparece no topo |
| Dicas/Pôsteres | Busca com normalização de títulos e pistas progressivas | Revisar dificuldade das primeiras partidas, aceitar variantes legítimas de títulos e indicar discretamente uso de ajuda |
| Cores | Imagem dominante, controles integrados e zoom livre | Explicar a parte editável pelo próprio realce visual; testar legibilidade em telas pequenas e diferenças de cor entre displays |
| Resultado | Próximo, cartão, convite e saída clara | Dar uma única próxima ação contextual: continuar, resgatar meta ou rever um erro. Não empilhar ofertas e modais |
| Estatísticas | Linguagem visual e categorias unificadas | Destacar evolução pessoal, atividade de estágios e recordes, evitando um grande estado vazio para quem já jogou |
| Coleção | Prévia sem conceder item e filtro Meus itens | Tornar a personalização visível em mais momentos de uso; antes de isso existir, a disposição a pagar por molduras provavelmente será limitada |
| Temporadas | Distinção de datas, posse e demonstração | Calendário enxuto de conteúdo real; não usar a demonstração Aurora como substituto permanente de uma temporada jogável |
| Saldo/loja | Recompensa explícita, preço real da loja e estados de falha | Na produção, exibir ofertas utilizáveis; no preview, manter os placeholders solicitados e claramente identificados |

A captura atual ainda mostra descrições laterais do carrossel truncadas e custo repetido na tela detalhada de Cores. São oportunidades de simplificação, não justificativa para refazer toda a identidade visual novamente.

## 6. Gatilhos sutis que fazem sentido para este jogo

Aqui, “gatilho” significa uma razão compreensível para agir: curiosidade, progresso, domínio, identidade e convivência. O jogador não precisa perceber toda a arquitetura, mas deve entender o custo, o benefício e a regra. Ocultar cobrança ou inventar pressão não é uma vantagem sustentável.

| Mecanismo | Implementação concreta | Resultado a verificar | Limite para preservar confiança |
| --- | --- | --- | --- |
| Curiosidade | Silhueta da próxima descoberta e tema do próximo capítulo | Mais inícios voluntários de partidas | Não revelar a resposta nem prometer conteúdo inexistente |
| Proximidade de meta | Após jogar, mostrar Falta 1 partida para sua moldura quando isso for verdadeiro | Conclusão de missões e retorno semanal | Uma meta visível por vez, sem pop-up a cada toque |
| Domínio pessoal | Seu melhor tom, evolução de média e resumo de erros | Revanche voluntária e melhora de desempenho | Não comparar usuários que usaram ajudas com outros como se fossem equivalentes |
| Hábito de presença | Sequência de dias em que jogou, separada de sequência de vitórias | D1/D7 e número de dias ativos por semana | Perder uma rodada não apaga o hábito de comparecer |
| Próxima ação fácil | Continuar a partida salva ou iniciar a próxima com um toque | Menos abandono na transição | Nunca iniciar débito ou anúncio sem ação explícita |
| Identidade | Avatar, título e cartão equipados aparecem no próprio resultado | Uso dos cosméticos e conversão de prévia | Vender um benefício que o jogador realmente verá |
| Reciprocidade | Recompensa inicial simples por completar uma primeira meta | Ativação e aceitação das próximas metas | Não chamar o jogador de devedor nem pedir anúncio por culpa |
| Pertencimento | Desafio assíncrono entre amigos, mesmo conteúdo e regras | Convites aceitos e retorno ao grupo | Sem competidores fictícios apresentados como pessoas reais |
| Novidade previsível | Um pequeno pacote editorial por semana | Retorno após atualização | Calendário cumprível e conteúdo revisado |
| Autonomia | Ajuda por ticket, vídeo opcional ou continuar sem ajuda | Uso de ajuda e satisfação | Fechar a oferta deve ser simples e não prejudicar o jogo |
| Experimentação | Prévia de cosmético na própria foto do cartão | Mais intenção de equipar/comprar | Prévia não altera posse; preço só aparece quando disponível |
| Recomeço | Convite acolhedor para voltar e meta curta após ausência | Retorno de jogadores inativos | Sem mensagem culpabilizante ou taxa para recuperar acesso ao jogo |

Não recomendo escassez falsa, relógio de oferta que reinicia, dificuldade secretamente maior para compradores, “quase ganhou” fabricado, fila de anúncios obrigatória, compra pré-selecionada, loot box paga ou tratamento que pressione menores a gastar. Esses mecanismos podem gerar receita pontual e aumentar abandono, suporte e risco de revisão das lojas.

Para o hábito, a proposta mais importante é separar **dias jogados** de **vitórias seguidas**. Hoje as sequências de Dicas/Pôsteres são baseadas em vitórias; Cores tem outra lógica. Pode existir uma sequência global de presença e recordes de vitória independentes, com nomes claros e migração que preserve o histórico.

## 7. Economia: balancear a necessidade, sem estrangular o jogo

| Fonte ou gasto | Regra atual | Implicação |
| --- | --- | --- |
| Renovação diária | 10 tickets | A maioria dos jogadores leves pode nunca precisar repor |
| Diários | Dicas e Pôsteres concedem 2 por vitória; Cores concede 2 por conclusão | Até 6 extras por dia, nas condições de cada modo |
| Estágio Dicas/Pôsteres | 10 inícios de 1, recompensa final de 10 | Pode se autofinanciar; falhas e ajuda mudam esse saldo |
| Estágio Cores | Duas partidas de cinco por 1 ticket cada | Dez desenhos custam dois inícios; comparar tempo de diversão por ticket, não apenas quantidade de itens |
| Vídeo no saldo | +2, até três recompensas diárias compartilhadas | Já há uma proposta clara; não adicionar mais um botão para a mesma troca |
| Vídeo de ajuda | Crédito de 2 e compra de ajuda por 1 | Entrega ajuda e conserva 1; pode ampliar o saldo mesmo quando o jogador não precisava repor |
| Ajuda por ticket | 1 ticket | Preço simples; valor depende de a informação realmente ajudar |

O fluxo precisa considerar bônus de sequência e recompensas de estágio: reduzir de 20 para 10 diárias, isoladamente, não demonstra uma economia equilibrada. Também não é desejável que o jogador fique sem saldo antes de se divertir.

**Teste econômico sugerido:** manter a diária de 10 e comparar a regra atual com uma nova regra, para participantes elegíveis, que entrega 4 tickets e um marco cosmético ao concluir o estágio de filmes. O custo líquido de dez inícios sem falhas/ajudas passaria de zero para seis. O número 4 é uma hipótese de teste, não um ponto ideal provado. Não retirar direitos existentes nem aplicar alteração escondida a uma etapa já iniciada.

Não reduzir a diária e a recompensa de estágio no mesmo experimento: seria impossível saber qual mudança causou o resultado. Antes disso, medir saldo no fim da sessão, percentual que fica sem tickets, vídeos por usuário e abandono no primeiro bloqueio. Se os jogadores leves nunca usam todos os tickets, a principal alavanca pode ser a utilidade da ajuda, não escassez.

Em Dicas/Pôsteres, ajudas extras preservam a pontuação; Cores desconta 1 ponto. Essa diferença já existe. Deve ser compreensível antes do uso e considerada em qualquer ranking futuro, sem mudar retroativamente resultados. [ExtraHint](C:/Projects/Cineus/lib/domain/entities/extra_hint.dart:1), [ColorScoring](C:/Projects/Cineus/lib/domain/entities/color_scoring.dart:54).

## 8. Anúncios: modelo recomendado como receita principal

### Ordem de implantação

| Formato/local | Situação hoje | Recomendação |
| --- | --- | --- |
| Ajuda na rodada | Fluxo implementado; sem ativação real | Prioridade máxima após configuração. Contexto de necessidade, recompensa explícita e um uso por partida |
| Ganhar tickets | Fluxo implementado; sem ativação real | Prioridade máxima. Manter +2 e recuperação de recompensa pendente |
| Banner no hub/estágios | Apenas espaço visual | Implementar componente real com tamanho adaptável, reserva de área e descarte correto; testar um local por vez |
| Bônus cosmético por vídeo | Ausente | Teste posterior, com fragmento determinístico de recompensa e meta curta, sem criar outra moeda comprável agora |
| Intersticial | Preparado, com flags e limites conservadores | Revisar o momento de disparo. Só testar depois de provar estabilidade e retenção dos recompensados |
| Anúncio na abertura | Ausente | Não priorizar: o primeiro contato deve demonstrar o jogo |

**Colocar IDs não transforma o placeholder em banner.** O adaptador atual implementa recompensado e intersticial; não encontrei `BannerAd` ou `NativeAd` integrado à área reservada. Essa parte exige código e teste próprios.

O teto atual é de três recompensas por dia, compartilhadas entre saldo e ajuda. Mantê-lo inicialmente permite medir um ponto de partida. Um teste posterior pode comparar 3 com 5 recompensas para adultos elegíveis, sem mudar o restante da economia e sem saturar a sessão. O limite não é uma garantia de receita e não limita todas as impressões possíveis, como banners ou visualizações abandonadas.

Regras para ativação: usar anúncios oficiais de teste na homologação; observar consentimento e público; registrar carregamento, indisponibilidade, impressão, conclusão, SSV, crédito e uso do benefício; manter recompensa idempotente; permitir jogar quando o anúncio falhar. A recompensa deve ficar explícita e ser interna ao app, sem incentivar cliques no anúncio. [Política oficial de recompensados](https://support.google.com/admob/answer/7313578?hl=pt-BR).

O guia do próprio AdMob recomenda testar valor, contexto e equilíbrio entre recompensas e compras. Essa orientação sustenta experimentar a utilidade da ajuda, mas não prova que um limite específico ou uma quantidade de tickets será ótima aqui. [AdMob — rewarded playbook](https://admob.google.com/home/resources/rewarded-ads-playbook/).

## 9. Compras e modelos secundários

| Modelo | Quando usar | O que precisa entregar |
| --- | --- | --- |
| Tickets consumíveis | Depois de corrigir economia e ledger | Compra verificada, crédito único, persistência/restauração do saldo aplicável, tratamento de pendência e reembolso |
| Plus permanente | Quando interrupções comuns estiverem realmente disponíveis | Benefício claro de remover publicidade comum; vídeos opcionais continuam opcionais, com descrição precisa |
| Pacote inicial | Depois de demonstrar valor ao jogador | Uma combinação pequena e garantida de cosmético original e conveniência; oferta sem urgência fictícia |
| Coleção temática | Quando personalização for usada e vista | Prévia, lista exata de itens, compra única e posse permanente |
| Clube mensal | Depois de haver procura e calendário sustentável | Valor novo por ciclo, termos de renovação e cancelamento claros, retenção dos cosméticos já concedidos conforme a regra atual |
| Patrocínio | Depois de provar audiência e participação | Evento real, identidade da marca e métricas agregadas verificáveis; Aurora continua demonstração |

O catálogo de cobrança atual não tem um tipo de produto consumível: contém coleções, Plus e assinatura. Portanto os pacotes de 10/30 tickets ainda não estão prontos para venda real. Não basta trocar Em breve por um preço; o crédito, consumo, reconhecimento nativo e servidor precisam suportar esse tipo. [commercial_product.dart:1](C:/Projects/Cineus/lib/domain/entities/commercial_product.dart:1).

Começaria com poucos produtos disponíveis, sem lançar todas as ofertas ao mesmo tempo. Ads devem financiar quem prefere jogar gratuitamente; compras oferecem conveniência e identidade. A assinatura é a última prioridade, pois aumenta obrigação de conteúdo e suporte. O manifesto local só prepara os ciclos iniciais de outubro/novembro; isso não demonstra uma operação mensal contínua.

Preços precisam ser definidos após observar necessidade, uso e resposta real de loja, mantendo o valor localizado retornado pela plataforma. Não há pesquisa de disposição a pagar ou conversão do Cineus que justifique declarar um preço ótimo agora.

## 10. Features com melhor relação entre impacto e esforço

| Feature | Como fazer | Resultado esperado, ainda a validar | Esforço relativo |
| --- | --- | --- | --- |
| Uma próxima meta na Home | Exibir a missão mais próxima, com CTA que abre a partida certa | Menos navegação e mais conclusão de metas | Baixo/médio |
| Sequência de presença | Um dia conta quando uma partida válida é concluída; separar vitória e presença | Mais retorno sem exigir acerto diário | Médio |
| Missões rotativas | Rotação de objetivos e recompensa nova; informar tratamento de duplicatas | Relevância na segunda semana | Médio |
| Domínio por tema | Progresso em animação, clássicos, fantasia etc., com curadoria | Vontade de completar e se especializar | Médio |
| Arquivo de diários | Calendário de desafios anteriores com sessões separadas | Mais conteúdo útil entre diários | Médio |
| Revanche pessoal | Rever erros em treino, sem alterar o resultado original | Sensação de aprendizado e novas sessões | Médio |
| Convite sem spoiler | Reaproveitar códigos, adicionar HTTPS e uma prévia neutra do desafio | Amigos conseguem jogar antes de conhecer a resposta | Médio |
| Placarzinho de amigos | Desafio assíncrono com conteúdo comum e resultados assistidos identificados | Retorno social | Alto; exige identidade e validação |
| Backup de progresso | Entrada opcional, conflitos resolvidos, restauração testada | Menos perda de confiança e abandono após troca de aparelho | Alto |
| Feedback na rodada | Botão discreto no resultado para relatar dica incorreta ou arte divergente | Melhorar o catálogo com menos custo editorial | Baixo/médio |

Evitar transformar tudo em tela nova. Meta na Home, resultado e coleção podem reaproveitar os fluxos atuais. A nova tela só se justifica quando organiza uma função que não cabe de forma clara no fluxo existente.

**Sobre spoiler:** o cartão atual mostra o pôster por solicitação anterior e pode continuar assim. A proposta é preservar esse cartão completo e ter uma versão neutra para convites/diário, escolhida conscientemente. Mostrar a resposta ao amigo antes de ele jogar reduz o valor do convite.

## 11. Conteúdo e dificuldade são parte da retenção

O volume é suficiente para o primeiro teste, mas quantidade não equivale a qualidade editorial. A validação estrutural encontrou todos os metadados, sem julgar correção de cada dica, identidade de cada personagem ou adequação de dificuldade.

O início de Cores segue grupos em ordem de nomes como Aang, All Might, Amy, Bananaman e Beavis. Essa ordem cumpre diversidade, mas não demonstra uma curva de dificuldade. Revisar os primeiros 20 minutos manualmente: reconhecimento, clareza da parte editada, proximidade entre cor esperada e a versão ilustrada, e progresso percebido.

Para filmes, catalogar dificuldade estimada, popularidade no Brasil, ambiguidade, variantes de título e evidência da resposta. Não monetizar uma dificuldade causada por dica errada, título não encontrado ou edição de personagem inconsistente. Adaptar recomendação de treino ao histórico é útil; alterar silenciosamente a resposta ou piorar a dificuldade para vender ajuda não é.

Manter uma fila editorial pequena, um calendário de publicação e uma ferramenta de revisão. Na evolução, ampliar a diversidade de desafios e partes realmente distintas; variar só a parte de um mesmo personagem não multiplica na mesma proporção a sensação de novidade.

## 12. Código, estabilidade e manutenção

Há escolhas boas a preservar: regras de pontuação centralizadas, banco local para continuidade, testes de concorrência e rollback, recuperação de anúncios pendentes, verificação de recibos no servidor, preços da loja e conteúdo remoto assinado. Uma reescrita completa seria injustificada.

As correções técnicas prioritárias são:

1. Centralizar o feedback de desempenho por escala, inclusive no compartilhamento.
2. Publicar um calendário diário estável e testar distribuição/repetição.
3. Tornar crédito de recompensa e marcação do resgate atômicos/recuperáveis.
4. Separar saldo comprado e economia local; tratar relógio e rollback de data.
5. Separar reserva de anúncio de impressão real e registrar os motivos de supressão.
6. Corrigir a dimensão de modo do tutorial e ampliar os eventos de funil.
7. Acrescentar observabilidade de falhas e testes nativos de atualização, restauração e abertura a frio.

Arquivos de UI como estatísticas, Cores, Home e temporadas têm entre aproximadamente 700 e 1.000 linhas. Extrair componentes e casos de uso quando isso reduzir acoplamento; não fragmentar só para diminuir a contagem. Manter regras econômicas longe dos widgets e não espalhar preços/recompensas por vários arquivos.

As flags comerciais atuais são de compilação. Um serviço de configuração/experimentos com parâmetros permitidos, limites seguros, variante persistente e desligamento remoto pode ajudar na operação. Não misturar esse sistema com download de código e não permitir que configuração remota conceda compras.

### Peso e desempenho

Os assets declarados somam aproximadamente **100,85 MiB antes de compressão, excluindo fontes**. Pôsteres representam 38,67 MiB; camadas de personagens, 20,36 MiB; fundos de Home/categorias/cards somam cerca de 25 MiB. A pasta inteira de assets tem 257 MiB, mas inclui fontes de produção artística não empacotadas: esse número maior não é o tamanho do aplicativo.

Não foi medido um AAB/APK novo nesta revisão. Recomendo medir download, instalação, tempo de abertura, memória e quadros lentos em aparelho modesto. Otimizar fundos e pôsteres em resoluções adequadas, pré-carregar só o necessário e manter SVG onde a recoloração exige camadas. A origem ImageGen das artes pode ser preservada; otimização de formato não exige redesenhar ícones por código.

## 13. Medição: sem isto, as decisões continuam no escuro

A telemetria atual é opcional e local, limitada a 2.000 registros/60 dias; não há envio automático nem coortes de população. Isso é adequado para diagnóstico local, insuficiente para medir D1/D7, conversão ou efeito de uma nova regra econômica. [local_product_telemetry.dart:6](C:/Projects/Cineus/lib/data/services/local_product_telemetry.dart:6).

| Funil | Eventos/dimensões necessários | Pergunta que resolve |
| --- | --- | --- |
| Primeiro uso | Primeira abertura, tutorial iniciado, passo, concluído, primeira partida e primeiro resultado | Onde o iniciante desiste? |
| Jogo | Modo, contexto, sessão, conclusão, ajuda usada, duração ativa e saída | Qual modo produz diversão e retorno? |
| Tickets | Fontes, gastos, saldo em faixas, insuficiência e ação seguinte | O saldo está abundante ou frustrante? |
| Vídeo | Oferta visível, contexto, solicitação, carregamento, falha/no fill, impressão, conclusão, SSV e entrega | O jogador não quer, não recebe ou não consegue usar o anúncio? |
| Compra | Oferta válida, prévia, início, pendente, verificada, restaurada, reembolsada | Qual benefício vende e onde a compra falha? |
| Retenção | Coorte de primeira atividade, dias ativos, progresso de missão, descoberta e retorno | Qual motivação continua funcionando na segunda semana? |
| Convite | Compartilhamento solicitado, abertura de link e início/conclusão pelo destinatário | O convite traz alguém que realmente joga? |

É preciso atualizar os esquemas de eventos, não apenas chamar nomes novos: o sanitizador atual rejeita eventos desconhecidos. Usar identidade pseudônima e dados mínimos; não enviar palpites, nomes de cartão ou recibos nos eventos de produto. Consentimento, finalidade, exclusão e retenção precisam corresponder à implementação.

Não chamar um pedido de compartilhamento de convite convertido nem uma recompensa estimada de dinheiro recebido. O SDK já oferece evento de valor do anúncio; reconciliar métricas com relatórios do AdMob e das lojas. Publicidade não sofre automaticamente a mesma comissão de uma compra da loja; usar a receita efetiva de cada canal.

## 14. Experimentos e critérios de sucesso

Uma hipótese não vira validada porque foi implementada ou porque aumentou cliques. A métrica principal deve refletir receita por jogador ao longo do tempo, acompanhada de retenção, diversão e falhas.

| Experimento | Comparação | Métrica principal | Proteção |
| --- | --- | --- | --- |
| Primeiro minuto | Guia atual × uma rodada guiada curta | Primeiro resultado concluído | D1 e erros de compreensão |
| Missões | Três recompensas fixas × rotação simples | Atividade na segunda semana | Não aumentar tempo obrigatório |
| Economia | Bônus de estágio 10 × 4 + marco visual | Receita por jogador em janela de acompanhamento | Abandono ao ficar sem tickets e D7 |
| Ajuda | Fluxo atual × entrada mais contextual após necessidade observada | Uso útil de ajuda e retorno ao jogo | Sem modal insistente após recusa |
| Limite de vídeo | 3 × 5, depois da ativação estável | Receita acumulada por usuário | D7, tempo de anúncios e satisfação |
| Banner | Um hub × grupo sem banner | Receita incremental | Latência, toque acidental e retenção |
| Convite | Cartão completo × convite neutro, com escolha explícita | Destinatários que iniciam jogo | Nenhum envio automático |
| Oferta | Saldo genérico × oferta relevante no momento de necessidade | Compra verificada por usuário elegível | Reembolso, recusa e retenção |

Como metas internas iniciais, e não previsões: buscar primeiro resultado em até 90 segundos para quem segue a entrada rápida; D1 próximo ou acima de 30%, D7 de 8% e D30 de 3% podem orientar a ambição após haver coortes suficientes. Ajustar por modo, plataforma e origem, em vez de tratar esses valores como aprovação automática de mercado.

Com poucos jogadores, começar por 8–12 sessões observadas e ciclos de entrevista, sem interpretar isso como teste estatístico. Um A/B de retenção de 30% contra 33% exige, numa aproximação comum de duas proporções com 5% de significância e 80% de poder, cerca de 3,8 mil pessoas por grupo. Uma base pequena não consegue validar pequenos efeitos depressa.

Não mudar várias regras simultaneamente. Registrar hipótese, variante, início/fim, elegibilidade, métrica e decisão. Guardar um grupo sem a mudança quando a base permitir; o holdout atual de intersticiais, isoladamente, não é uma plataforma completa de experimentação.

## 15. Receita esperada: simulação transparente

Ainda não há eCPM, audiência diária, conversão ou retenção medidos no Cineus. Portanto o cálculo abaixo ilustra escala e sensibilidade, sem estimar demanda ou prometer faturamento brasileiro.

**Receita mensal aproximada de rewarded = DAU médio × impressões efetivas por DAU/dia × eCPM ÷ 1.000 × 30.** Impressão efetiva já pressupõe que houve anúncio servido; não multiplicar de novo por taxa de preenchimento se ela já estiver embutida nessa média. Receber recompensa e gerar impressão não são o mesmo evento.

| Hipótese ilustrativa | Impressões rewarded por DAU/dia | eCPM hipotético em reais | Receita por 1.000 DAU em 30 dias |
| --- | --- | --- | --- |
| Baixa exposição | 0,30 | R$ 5 | R$ 45 |
| Intermediária | 0,70 | R$ 12 | R$ 252 |
| Exposição/valor maiores | 1,20 | R$ 20 | R$ 720 |

Esses eCPMs são **entradas escolhidas para simulação**, não cotação do mercado nem benchmark do Brasil. Com 100 DAU, os valores seriam R$ 4,50 / R$ 25,20 / R$ 72; com 10 mil DAU, R$ 450 / R$ 2.520 / R$ 7.200. O DAU precisa ser mantido ao longo do mês; não equivale a instalações acumuladas.

As contas excluem banners, intersticiais e compras, além de custos de conteúdo, servidor, suporte, licenças e tributos. Não são lucro. O recebimento pode divergir de estimativas por ajustes e calendário de pagamento. Usar relatórios efetivos para reconciliar valores.

Para compras, calcular separadamente: usuários elegíveis × conversão observada × gasto bruto médio, menos comissão aplicável, reembolsos, tributos e custos. Não misturar ticket de compra com receita líquida. Para um Plus permanente, comparar também a receita futura de publicidade comum removida; não contar o preço inteiro como ganho adicional sem esse efeito.

A implicação prática é que aumentar retorno e dias ativos pode valer mais do que insistir em um quarto anúncio numa sessão curta. A melhor meta é receita sustentável por jogador, e não maximizar o tempo que ele fica vendo publicidade.

## 16. Conteúdo, público e publicação comercial

O manifesto de origem registra 26 personagens como gerados e 24 como referência externa. Esse registro é útil, mas não comprova autorização comercial dos titulares. No repositório também há um modelo de planilha de direitos dos pôsteres; não encontrei ali uma planilha preenchida com evidências para todos os materiais. A conclusão é **permissões não verificadas nesta auditoria**, não uma declaração de que todo uso é ilegal.

O TMDB distingue uso não comercial de projeto voltado a receita e orienta obter licença para uso comercial de API/dados/imagens. Atribuição não substitui essa autorização, e o próprio TMDB informa não ser proprietário de todas as imagens. Verificar separadamente a cadeia de direitos de pôsteres e personagens, inclusive os reinterpretados com IA. [TMDB — FAQ comercial](https://developer.themoviedb.org/docs/faq). A Apple também exige respeito aos direitos de terceiros. [App Review Guidelines, seção 5.2](https://developer.apple.com/app-store/review/guidelines/).

Para Android/iOS no Brasil, definir o público real antes de ativar SDKs e ofertas: um visual de desenhos pode alcançar menores mesmo que o desenvolvedor imagine uma audiência adulta. A configuração de consentimento, publicidade, declarações de dados e compras deve corresponder ao público e ao tratamento de dados efetivo. A ANPD destaca o melhor interesse de crianças e adolescentes. [Orientação oficial da ANPD](https://www.gov.br/anpd/pt-br/assuntos/noticias/anpd-divulga-enunciado-sobre-o-tratamento-de-dados-pessoais-de-criancas-e-adolescentes).

Se houver venda de moeda, preservar o saldo comprado e o tratamento exigido pelas lojas. O requisito de não expirar moeda adquirida por IAP aparece nas diretrizes da Apple; a renovação de tickets gratuitos deve continuar separada desse saldo. Isso deve orientar a implementação, não apenas o texto dos termos. [App Review Guidelines, seção 3.1.1](https://developer.apple.com/app-store/review/guidelines/).

## 17. Sequência de execução recomendada

As sprints abaixo são uma proposta de planejamento, não trabalho iniciado automaticamente.

| Sprint | Entrega agrupada | Critério para encerrar |
| --- | --- | --- |
| 1 — Correção e medição | A03/A08/A10/A11/A13; calendário estável, placar correto, crédito durável, contexto de estatísticas e eventos | Casos de migração preservam partidas/saldo; 5/5 fica verde; nenhuma repetição na janela editorial publicada; funil de três modos conferido |
| 2 — Retorno e propósito | Missões rotativas, próxima meta, sequência de presença e revisão do primeiro uso | Segunda semana tem recompensa útil; uma rodada rápida não exige atravessar telas de loja |
| 3 — Operação publicitária | Configuração AdMob/SSV, dois recompensados, primeiro banner real, estados de falha e revisão A09/A12 | Teste nativo de anúncio, cancelamento, pendência, restauração e benefício; comparação com grupo sem nova exposição |
| 4 — Economia e compra de tickets | Tempo confiável, ledger de consumíveis, backup/recuperação e teste econômico isolado | Comprar, repetir callback, reinstalar, restaurar e reembolsar não criam perda/duplicação; termos e saldo comprados preservados |
| 5 — Conteúdo e social leve | Arquivo de diários, curadoria de temas, HTTPS e convite sem spoiler | Amigo sem app tem destino útil; atividade e retorno mensuráveis; expansão não troca diários já iniciados |
| Depois da validação | Coleções maiores, Clube, ranking de amigos ou patrocínio | Procura observada, operação de conteúdo viável e receita incremental demonstrada |

Permissões de conteúdo, público e preparo de loja/servidor devem avançar desde o começo; são dependências da ativação pública. As sprints podem ser divididas conforme essas dependências. Não prometo prazos de loja ou receita antes da configuração e das métricas reais.

## 18. Evidências e rastreabilidade

### Artefatos desta revisão

- [Inventário e simulação do seletor](C:/Projects/Cineus/docs/business/audit-2026-10-19/evidencias.json).
- [Reprodução que importa o seletor real do jogo](C:/Projects/Cineus/docs/business/audit-2026-10-19/reproduzir_seletor.dart); executar com `dart docs/business/audit-2026-10-19/reproduzir_seletor.dart` na raiz do projeto.
- [803 testes Flutter](C:/Projects/Cineus/docs/business/audit-2026-10-19/flutter-tests.log).
- [57 testes do backend](C:/Projects/Cineus/docs/business/audit-2026-10-19/backend-tests-final.log).
- [Análise estática](C:/Projects/Cineus/docs/business/audit-2026-10-19/flutter-analyze.log).
- [Captura de telas reais do Flutter](C:/Projects/Cineus/docs/business/audit-2026-10-19/flutter-visual-capture.log).

### Telas conferidas nesta revisão

São renderizações novas, com dados de teste, não fotografias de um APK em produção. Mantêm a aparência atual do aplicativo; não representam as features propostas neste relatório.

![Início atual](C:/Projects/Cineus/docs/preview/screens/colors_home_390_1x_pt.png)

![Partida atual de Cores](C:/Projects/Cineus/docs/preview/screens/colors_game_390_1x_pt.png)

![Estatísticas atuais](C:/Projects/Cineus/docs/preview/screens/colors_stats_390_1x_pt.png)

![Detalhe atual de estágio de Cores](C:/Projects/Cineus/docs/preview/screens/colors_detail_390_1x_pt.png)

### Fontes externas consultadas em 19/10/2026

- [Framed — produto e modos](https://framed.wtf/).
- [Toon Tone — produto e regras](https://toontone.app/pt/).
- [Trivia Crack — power-ups e segunda chance](https://triviacrack.help.etermax.com/hc/en-us/articles/360024775733-Power-ups).
- [Royal Match — coleção](https://dreamgames.helpshift.com/hc/en/3-royal-match/faq/332-what-is-collection/).
- [Royal Match — vidas](https://dreamgames.helpshift.com/hc/en/3-royal-match/faq/5-lives/).
- [Royal Match — recuperação de progresso](https://dreamgames.helpshift.com/hc/en/3-royal-match/faq/39-how-can-i-transfer-my-game-progress-to-another-device-1593777955/).
- [Duolingo — resultado de experimento de sequência](https://blog.duolingo.com/improving-the-streak/).
- [Google AdMob — estudo de caso Four Thirty Three](https://admob.google.com/home/resources/four-thirty-three-uses-admob-to-boost-mobile-game-revenue-15-percent/).
- [GameAnalytics — benchmarks 2026, base 2025](https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks).
- [AdMob — guia de recompensados](https://admob.google.com/home/resources/rewarded-ads-playbook/).
- [AdMob — políticas de recompensas](https://support.google.com/admob/answer/7313578?hl=pt-BR).
- [AdMob — intersticiais inesperados](https://support.google.com/admob/answer/6201362?hl=en).
- [TMDB — licença comercial e atribuição](https://developer.themoviedb.org/docs/faq).
- [Apple — diretrizes de revisão](https://developer.apple.com/app-store/review/guidelines/).
- [ANPD — melhor interesse de crianças e adolescentes](https://www.gov.br/anpd/pt-br/assuntos/noticias/anpd-divulga-enunciado-sobre-o-tratamento-de-dados-pessoais-de-criancas-e-adolescentes).
