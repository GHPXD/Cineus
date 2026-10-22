# Rentabilidade do Cineus após a implementação

O produto agora tem caminhos distintos de receita: coleções permanentes, Plus permanente, Clube mensal, vídeos opcionais, intersticiais com limites e eventos patrocinados configuráveis. **Ainda não há receita comercial observada ou validação de demanda.** Compra, anúncio e patrocínio reais dependem da configuração e dos testes externos registrados no fechamento. Este relatório trata da monetização do jogo; aquisição de usuários e verba de campanha ficam para depois.

## O que vender e qual benefício entregar

| Modelo | Benefício | Apresentação implementada | Receita esperada em termos de comportamento |
| --- | --- | --- | --- |
| Coleção Estreia | 2 avatares, 3 molduras, 1 aparência | Minha coleção e Personalizar; prévia sem concessão | Compra única por coleção; depende de o jogador querer compartilhar um cartão próprio |
| Coleções mensais | Mesma composição, temas distintos | Temporadas e catálogo versionado; Noite e Cidade preparadas | Novas vendas a interessados em novos temas; itens já possuídos não viram outra venda |
| Plus | Remoção permanente de interrupções, moldura e aparência próprias | Compra única, somente com benefício de intersticial disponível | Pagamento único de novos compradores elegíveis; não é receita mensal da mesma pessoa |
| Clube | Coleção do ciclo e remoção de interrupções enquanto válido | Assinatura mensal da loja, gestão e restauração | Receita recorrente apenas dos ciclos pagos; exige produção editorial recorrente |
| Vídeo opcional | +2 tickets, até 3 confirmações por dia UTC | Saldo, sem chamada permanente no Início | Receita por impressão válida, variável por disponibilidade e valor informado pela rede |
| Intersticial | Monetização complementar | Pausa no resultado de estágio após 10 s sem interação, grupo de controle e limites | Receita incremental a comparar com eventual perda de retorno; não ampliar frequência para fechar uma projeção |
| Patrocínio | Evento gratuito com identidade declarada e recompensa original | Aurora explicitamente demonstrativo | Receita contratada por escopo/período; hoje não existe contrato nem receita |

Referências de preço aprovadas para planejamento: coleção R$ 14,90, Plus R$ 19,90 e Clube R$ 9,90/mês. O aplicativo só apresenta uma oferta com o preço localizado que a loja realmente retornar. Não há preço simulado disponível para compra.

Missões, descoberta de personagens, itens gratuitos e novos estágios sustentam uso e valor da personalização sem cobrar por pontuação. O catálogo de Cores mantém os 50 personagens e passa a 11 estágios/110 regiões; a ordem dos nove estágios e 90 perguntas anteriores foi preservada.

## Resultado ilustrativo, com premissas abertas

O [modelo reproduzível](PROJECAO-MONETIZACAO-2026-10-15.json) usa, por mês: 1% de pedidos de coleção, 0,5% de novos pedidos de Plus e 0,5% de ciclos pagos do Clube em relação a usuários ativos mensais. Não são taxas medidas. Um jogador pode fazer mais de um pedido, mas posse anterior e coleção recebida no Clube não devem ser contadas como uma venda duplicada.

Outras hipóteses: DAU/MAU de 20%; 0,15 tentativa de vídeo e 0,05 oportunidade de intersticial por usuário diário; preenchimento de 60%; eCPM de receita do editor de R$ 20 e R$ 8 respectivamente; reserva de reembolso de 3%; desembolso mensal ilustrativo de R$ 80; 8 horas editoriais a R$ 15/h de custo de oportunidade. Nenhum desses custos ou eCPMs foi contratado ou observado. Taxas, encargos de conta das lojas e tributação devem ser acrescentados quando conhecidos.

| Usuários mensais hipotéticos | Compras brutas | Publicidade estimada | Saldo de caixa antes de tributos, comissão de 15% | Incluindo R$ 120 de tempo editorial |
| ---: | ---: | ---: | ---: | ---: |
| 200 | R$ 59,60 | R$ 2,45 | **−R$ 28,41** | **−R$ 148,41** |
| 1.000 | R$ 298,00 | R$ 12,24 | R$ 177,94 | R$ 57,94 |
| 3.000 | R$ 894,00 | R$ 36,72 | R$ 693,82 | R$ 573,82 |

A comissão de 15% é um cenário condicionado aos programas e termos aplicáveis, não uma inscrição já aprovada do Cineus. O Google descreve a faixa reduzida e assinaturas em sua [tabela de serviços](https://support.google.com/googleplay/android-developer/answer/112622); a Apple exige elegibilidade/adesão ao [Small Business Program](https://developer.apple.com/app-store/small-business-program/). O JSON também calcula comissão de 30% como teste de sensibilidade: com 1.000 usuários, o saldo econômico antes dos tributos cai para **R$ 14,58**. Não some esses resultados como lucro garantido.

Nesse cenário, poucas vendas cosméticas contribuem mais que elevar a pressão publicitária. Sem publicidade e sob as hipóteses de comissão de 15%/reserva de 3%, R$ 80 de desembolso equivalem a cerca de 7 pedidos de coleção, 5 novos Plus ou 10 ciclos de Clube; cobrindo também R$ 120 de tempo, seriam 17, 13 ou 25. São alternativas matemáticas, não metas de venda comprovadas.

## Como acompanhar o que realmente aconteceu

1. **Pedidos e direitos:** `python -m cineus_commerce --config ARQUIVO.json report` agrupa ordens verificadas por plataforma, produto, moeda e estado. Concessão não equivale a depósito bancário. O total não mistura moedas nem inventa taxa, câmbio ou líquido desconhecido. Google pode retornar receita do desenvolvedor; Apple requer conciliação com seus relatórios financeiros para o líquido.
2. **Clube:** acompanhar ciclos válidos, cancelamento, cobrança pendente, expiração, reembolso e coleções faltantes. Contar a cobrança de renovação como ciclo, não cada snapshot/restauração. A expiração não remove cosméticos permanentes de ciclos válidos nem o Plus independente.
3. **Publicidade:** os callbacks de valor alimentam o diagnóstico local opcional por placement, moeda e precisão. São estimativas, não extrato de pagamento. Conciliar com AdMob e excluir tráfego de teste; o SDK não controla sozinho o crédito de tickets. Confirmação SSV/recibo e movimentação local evitam duplicação.
4. **Eventos:** relatório por ID de adesão, conclusão e resgate, com cobertura e limitações. A ferramenta inicial é local. Não há coletor de analytics populacional, DAU/MAU real, identificação de jogadores ou patrocínio contratado.
5. **Margem:** registrar geração/curadoria, infraestrutura, suporte, lojas, reembolsos, tributos e obrigações editoriais. Substituir cada hipótese do modelo por dado observado; avaliar caixa e custo do próprio tempo separadamente.

Os detalhes financeiros consultados do Google ficam limitados ao uso necessário para validar e conciliar a ordem; não se exportam dados de endereço do comprador. A [Orders API](https://developers.google.com/android-publisher/api-ref/rest/v3/orders) fornece estado e valores da ordem. O relatório interno não representa apuração fiscal ou contábil.

## Sequência operacional para obter uma primeira receita verificável

Primeiro resolver o uso comercial do catálogo e público, configurar o backend HTTPS e executar compra/restauração/reembolso em testes genuínos das duas lojas. Validar em aparelho o consentimento e uma recompensa assinada, conservando IDs de teste durante o desenvolvimento. Só então habilitar as ofertas correspondentes e acompanhar uma primeira venda entregue e conciliada.

Manter intersticiais desligados enquanto não houver evidência suficiente sobre retorno/abandono; o grupo de controle e os limites estão implementados. O Plus fica indisponível para venda enquanto a remoção não for um benefício oferecido. O Clube requer conteúdo do ciclo atual e seguinte, plano mensal e aprovação explícita; as coleções de outubro/novembro estão prontas, dezembro ainda precisa de produção antes de manter novas ofertas em novembro. Obrigações de assinantes existentes continuam mesmo ao ocultar uma oferta.

Patrocínio pode ser demonstrado com [escopo e material preparados](PATROCINIO-DEMONSTRACAO-2026-10-15.md), sem inventar audiência. A análise de campanhas pagas só retoma após este fechamento comercial e os dados iniciais de retenção, conversão e custos; nenhum gasto de aquisição foi realizado nesta implementação.
