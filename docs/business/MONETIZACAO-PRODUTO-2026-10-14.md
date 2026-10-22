# Cineus — plano de monetização do produto

**14 de outubro de 2026 · Android e iOS · Brasil**

Este relatório define funcionalidades, ofertas, publicidade exibida dentro do jogo, implementação e resultados a acompanhar. A aquisição paga de usuários fica para uma etapa posterior à conclusão da monetização v1. Os preços e números financeiros são hipóteses para validação, não ofertas publicadas ou previsão de faturamento. Esta entrega é planejamento; nenhuma cobrança ou publicidade foi ativada.

**Propostas aprovadas pelo proprietário:** o [plano executivo em 12 sprints](SPRINTS-MONETIZACAO-2026-10-14.md) detalha a implementação completa, incluindo temporadas, Clube e eventos patrocinados. Ele expande a sequência inicial de sete sprints da seção 12; condições de ativação e validação permanecem aplicáveis.

## 1. Modelo de negócio recomendado

**Cineus gratuito para jogar, com personalização paga, vídeos recompensados opcionais e uma compra permanente para remover interrupções quando elas existirem.** Assinatura e temporadas pagas entram somente após comprovar demanda e capacidade de entregar benefícios novos.

A proposta comercial deve acompanhar o valor atual do app: sessões rápidas, memória visual, cinema, personagens e cartões de resultado. A pessoa pode pagar para personalizar sua experiência e compartilhar um cartão bonito; pode escolher um vídeo para continuar jogando. Os modos, o catálogo já incluído, os diários, as conquistas de desempenho e os convites básicos continuam disponíveis gratuitamente.

| Frente | Papel no negócio | Prioridade |
|---|---|---|
| Coleções cosméticas originais | Primeira oferta de compra; aproveita a identidade visual e o compartilhamento | Alta |
| Vídeo recompensado por tickets | Receita opcional de quem deseja jogar mais | Alta, com demanda a verificar |
| Missões semanais e progressão visual | Aumentar frequência e tornar personalização relevante | Alta como sustentação do produto |
| Intersticial moderado + Cineus Plus permanente | Receita complementar e conveniência para quem prefere remover interrupções | Condicional à experiência observada |
| Coleção de temporada, compra avulsa | Novas ocasiões de compra com itens definidos | Depois da primeira coleção |
| Assinatura Cineus Clube | Receita recorrente em troca de entrega recorrente | Posterior, sem assinatura no lançamento v1 |
| Patrocínio de evento com conteúdo autorizado | Receita por contrato, sem depender apenas do usuário final | Futuro; não entra nas contas sem contrato |

**Não priorizar:** vender tickets como principal negócio, vender dicas que melhorem artificialmente a competição, cobrar pelos modos atuais, bloquear estatísticas existentes ou transformar cada tela em uma vitrine. O projeto já teve várias correções para reduzir excesso de informação; a monetização precisa preservar esse ganho.

## 2. Diagnóstico do projeto atual

| O que existe | O que significa | Trabalho necessário |
|---|---|---|
| 500 filmes, 5.000 dicas, 50 personagens e nove estágios de Cores | Base de conteúdo para experimentar retenção | Planejar reposição e custo editorial; volume instalado não comprova hábito |
| 20 tickets gratuitos por dia, bônus de diários e progresso | A escassez de tickets é baixa | Medir saldo e gasto antes de escolher tickets como motor de receita |
| Rewarded configurado como regra: +2 tickets, até três por dia | A política já tem uma primeira troca definida | Integrar SDK real e fortalecer concessão e contagem, hoje locais |
| Cartão de resultado e compartilhamento | Superfície natural para personalização | Construir inventário, seleção e renderização da aparência no cartão exportado |
| Conquistas e estatísticas comuns aos três modos | Progresso que pode sustentar retorno | Preservar acesso gratuito e distinguir conquista de item comprado |
| `MonetizationService` com interface para anúncio e Pass | Existe um ponto de integração | A interface atual precisa ser ampliada para produtos avulsos e direitos permanentes |
| `DisabledMonetizationService` e `DisabledProductTelemetry` como padrão | Anúncios, compras e medição comercial não estão operacionais | Implementar adaptadores e configurar lojas/rede antes de oferecer algo real |
| SQLite e progresso local | Gameplay offline econômico | Direitos de compra e recompensas comerciais precisam de validação e recuperação adequadas |

### O problema específico dos tickets

Nos estágios de Dicas/Pôster, dez partidas iniciadas custam dez tickets se não houver novas tentativas. A conclusão do estágio concede dez tickets. Além dos 20 diários, isso pode repor integralmente o gasto de avanço de um jogador que conclui tudo de primeira. Dicas extras e novas tentativas podem consumir mais; o saldo real depende do comportamento.

Portanto, **há pouca evidência de necessidade de comprar tickets ou assistir a vídeos por apenas +2**. O primeiro teste de rewarded deve verificar essa utilidade. Não recomendo retirar benefícios existentes para criar pressão comercial. Se o jogador raramente fica sem tickets, investir primeiro em cosméticos e conteúdo relevante, em vez de insistir em mais locais para oferecer o mesmo anúncio.

Em Cores, cada partida tem cinco rodadas; os nove estágios representam 18 partidas. A repetição de personagens com outras regiões pode ampliar o conteúdo, mantendo a regra de não repetir o mesmo desenho dentro do módulo. Essa ampliação exige curadoria e novas perguntas úteis, não apenas embaralhamento.

Evidências: [tickets](../../lib/domain/entities/player_tickets.dart), [recompensas](../../lib/domain/entities/ticket_reward.dart), [política comercial](../../lib/domain/entities/monetization.dart), [integração atual](../../lib/domain/services/monetization_service.dart), [adaptador desativado](../../lib/data/services/disabled_monetization_service.dart), [dependências](../../pubspec.yaml).

## 3. Feature principal: coleção e personalização

### O que fazer

Criar **Minha coleção**, com três tipos de item inicialmente:

- Moldura do cartão de resultado.
- Avatar original do Cineus para uso no perfil leve e no cartão, se o usuário quiser exibi-lo.
- Aparência do cartão: fundo, acabamento e ornamentos; pontuação e informações permanecem legíveis.

Não começar por temas que alteram toda a interface: eles multiplicam os estados de contraste e layout a testar. Personalizar primeiro o cartão permite mostrar o benefício imediatamente sem comprometer o design das telas do jogo.

### Como fazer

1. Disponibilizar uma pequena seleção gratuita: duas molduras, dois avatares e uma aparência básica de cartão.
2. Criar uma **Coleção Estreia** com três molduras, dois avatares e uma aparência de cartão, todos originais. Preço inicial para teste: **R$ 14,90, compra única**.
3. Gerar os assets com ImageGen e converter em SVG quando adequado, seguindo a origem registrada e a direção visual do app. As fontes Fredoka/Nunito e a legibilidade permanecem consistentes.
4. Mostrar prévia com o resultado do próprio jogador antes da compra. O jogador escolhe, visualiza e confirma; não apresentar a janela de pagamento automaticamente.
5. Salvar itens possuídos e aparência equipada separadamente. Comprar um pacote concede seus itens uma única vez; equipar não consome o item.
6. Aplicar a aparência tanto ao cartão mostrado quanto à imagem efetivamente compartilhada.

**Entrada na UI:** Configurações → Minha coleção; dentro de Ver cartão → Personalizar. Manter a barra inferior com as quatro categorias atuais. Não acrescentar uma aba de loja nem um banner comercial permanente na tela inicial.

**Resultado esperado:** tornar o cartão mais pessoal e criar uma compra com benefício visível. Não há evidência de que o público pagará por isso; validar prévia usada, oferta aberta, compra concluída e item equipado após a compra. Abrir a loja sem comprar não comprova disposição a pagar.

**Cuidados de oferta:** itens pagos são ornamentos, não conquistas de desempenho. A coleção não concede medalhas de acerto, pontuação ou vitória. Sem caixas aleatórias, contagem regressiva artificial ou suposta exclusividade que não exista.

## 4. Anúncios dentro do jogo

### 4.1. Vídeo recompensado — primeira implementação

**Oferta inicial:** “Assistir e ganhar 2 tickets”, com o limite atual de três recompensas por dia. Mostrar quando o usuário abrir o saldo e, quando necessário, na falta de tickets. Nunca iniciar automaticamente.

**Fluxo:** jogador escolhe assistir → anúncio disponível é apresentado → SDK confirma a recompensa → concessão é registrada → saldo atualizado. Se falhar ou for cancelado antes da recompensa, a partida e o saldo permanecem consistentes. Conceder no callback de recompensa, não simplesmente quando o vídeo fecha. A confirmação recebida precisa ser recuperável se houver falha de rede ou encerramento do app.

**Como implementar:** adaptador Google Mobile Ads para as duas plataformas; IDs de teste separados dos de produção; carregamento antecipado; limite diário; transação/identificador único para evitar crédito duplicado; verificação no servidor quando disponível; consentimento e configuração etária aplicáveis. A implementação atual que retorna um booleano não substitui uma trilha de concessão robusta para produção. [Rewarded no Flutter](https://developers.google.com/admob/flutter/rewarded)

**Resultado esperado:** monetizar uma parcela de jogadores que precisa de mais tentativas, sem interromper quem não escolheu o vídeo. Com a economia atual, a adoção pode ser baixa; não presumir que todos verão três anúncios por dia.

**Medição:** oferta elegível, toque, anúncio carregado, exibição, conclusão/recompensa e tickets efetivamente concedidos. Se existir procura e pouca disponibilidade, o problema pode estar na integração/rede. Se houver disponibilidade e quase ninguém escolher, revisar o valor da oferta; adicionar mais banners não resolve falta de interesse.

A política do AdMob exige escolha explícita, descrição clara e entrega da recompensa. Não usar “assista para apoiar o desenvolvedor” como incentivo de rewarded; apresentar a troca objetiva. [Política de recompensas](https://support.google.com/admob/answer/7313578?hl=en)

### 4.2. Intersticial — experimento posterior e limitado

Pode complementar receita, mas tem risco maior de reduzir satisfação e retorno. **Não é pré-requisito para lançar cosméticos e rewarded.**

Proposta inicial de frequência, sujeita a validação:

- Somente em pausas naturais após partidas de estágios concluídas, com o resultado já apresentado; nunca acionado por Voltar ao início, fechar o app ou compartilhar.
- Nenhum nas três primeiras sessões, no tutorial ou nos desafios diários.
- Pelo menos quatro partidas de estágio concluídas desde a última exibição.
- Intervalo mínimo de dez minutos entre anúncios de tela cheia, inclusive depois de rewarded.
- Máximo de dois intersticiais por dia; nenhum para quem possui Plus.
- Sem espera forçada se não houver anúncio pronto. Não mostrar no início da próxima partida nem após o toque em Jogar/Próximo enquanto o jogador espera começar.

Esses limites são escolhas de produto, não números impostos pelas lojas. O encaixe exato no encerramento precisa ser validado com a tela real de resultados, sem disparos atrasados enquanto a pessoa toca em outro controle. Usar um controlador central de elegibilidade, e não chamadas espalhadas nas telas.

**Resultado esperado:** receita adicional moderada. Testar contra uma variante sem intersticial; acompanhar retorno, partidas por pessoa, saída após anúncio e receita. Uma regra interna possível é pausar se houver queda relativa de D7 superior a 5% com evidência suficiente, ou padrão claro de abandono/reclamações. É critério de decisão escolhido para este jogo; não benchmark e não conclusão com amostra pequena.

O Google proíbe intersticiais inesperados, inclusive no começo de níveis e antes da ação que o usuário escolheu. A documentação técnica orienta intervalos naturais. [Política de anúncios](https://support.google.com/googleplay/android-developer/answer/9857753?hl=en), [intersticiais no Flutter](https://developers.google.com/admob/flutter/interstitial)

### 4.3. Formatos que eu deixaria fora da v1

Banners permanentes, anúncios na abertura, ofertas que aparecem sobre os controles de Cores e vídeos a cada rodada. O espaço visual e a concentração são parte do valor do jogo. Não há razão comprovada para ocupar essas superfícies antes de medir as opções menos invasivas.

## 5. Cineus Plus — compra permanente

**Proposta:** R$ 19,90 uma única vez para remover intersticiais, mais uma aparência e uma moldura originais próprias do Plus. Itens diferentes dos da Coleção Estreia, para não vender o mesmo benefício duas vezes. Não inclui pontos, dicas grátis ou vantagem na disputa.

**Quando vender:** somente depois de implementar intersticiais de verdade e confirmar que a experiência continua boa. Antes disso, a Coleção Estreia já oferece uma compra concreta; não vender a remoção de uma interrupção que ainda não existe.

**Descrição da oferta:** “Compra única · remove anúncios de interrupção”. Vídeos com recompensa continuam opcionais e podem ser ocultados nas preferências do comprador. Não usar “sem anúncios” de forma ampla se ainda houver superfícies publicitárias. Não prometer acesso ilimitado a futuras funcionalidades ou todas as futuras coleções.

**Como fazer:** produto não consumível em cada loja; direito persistente validado; restauração; tratamento de reembolso/revogação; bloqueio central de intersticiais. Um usuário com direito válido não pode ver um anúncio enquanto a tela de configurações ainda carrega. Após compra/restauração verificada, manter o uso offline com política de atualização do direito definida.

**Resultado esperado:** opção simples para quem valoriza continuidade e quer apoiar com um benefício permanente. Cada comprador paga uma vez; o mesmo comprador não gera essa receita todo mês. A receita perdida de intersticiais dos proprietários precisa ser descontada nas projeções.

**Nome e arquitetura:** o Pass atual é apenas uma interface e um estado booleano; não prova existência de assinatura ou direito permanente. Separar IDs e direitos `colecao_estreia`, `plus_permanente` e eventual `clube_assinatura`, evitando um booleano único que represente contratos diferentes.

## 6. Features que sustentam retorno e novas compras

| Feature | Implementação concreta | Resultado a verificar |
|---|---|---|
| Missões semanais | Três objetivos simples, como concluir partidas em dois modos ou melhorar o próprio resultado; progresso derivado das partidas salvas | Mais retorno e variedade de modos, sem obrigação de entrar diariamente |
| Recompensas visuais por progresso | Pequeno conjunto de ornamentos gratuitos, sem substituir as conquistas atuais | Tornar o perfil/cartão interessante mesmo sem compra |
| Coleção de personagens descoberta | Registrar personagens já jogados; bloquear prévias futuras com silhueta e não revelar cores antes da rodada | Curiosidade e sensação de coleção, respeitando as correções de spoiler |
| Novos módulos e desafios curados | Acrescentar perguntas, partes do personagem e combinações úteis; verificar duplicidade por módulo | Evitar que o conteúdo seja esgotado rapidamente; medir uso do conteúdo novo |
| Lembrete voluntário | Reaproveitar o sistema de notificações e respeitar preferências; mostrar novidade real | Retorno por interesse, sem spam de oferta |
| Novo cartão compartilhável | Aparência equipada, resultado correto e leitura clara; compartilhar nunca exige comprar | Tornar a personalização visível e ampliar o valor social do resultado |

Não introduzir outra moeda já no início. Tickets continuam sendo recurso de partida; cosméticos são direitos de inventário. Missões não exigem comprar ou assistir a anúncio, não punem ausências e não usam recompensas em tickets sem avaliar o impacto sobre o saldo já generoso.

**Cuidado com rankings:** Dicas, Pôster e Cores usam escalas diferentes. Uma futura comparação entre modos exige normalização e regras sobre dicas, tentativas e integridade. Não vender benefício que aumente pontuação em uma classificação pública.

## 7. Modelos para depois da primeira versão comercial

### Coleções de temporada — próxima opção preferida

Lançar uma coleção definida de cosméticos originais por, por exemplo, R$ 9,90–14,90. Uma compra concede os itens descritos; o que foi comprado permanece. A temporada é a ocasião de lançamento, sem retirada artificial de itens já adquiridos. Produzir outra coleção somente se uso e vendas da primeira justificarem o custo de arte e manutenção.

Isso cria novas ocasiões de compra. Não transforma automaticamente o mesmo público em comprador mensal: é necessário demonstrar interesse em cada lançamento. O modelo financeiro abaixo limita-se à primeira coleção e não soma receita especulativa de temporadas.

### Cineus Clube — assinatura opcional

Hipótese futura: R$ 9,90/mês por uma coleção original nova por mês, personalização adicional e remoção de interrupções. Exige calendário editorial, regras claras sobre o que permanece após cancelar, suporte a cobrança, cancelamento e restauração. O Plus permanente mantém todos os benefícios comprados, mesmo que não assine o Clube; não retirar seus direitos para induzir migração.

Só recomendar lançamento depois de entregar coleções novas em cadência por pelo menos dois ciclos de teste, demonstrar interesse pago e calcular o custo dessa entrega. Benefícios básicos e conteúdo já gratuito permanecem. Não vender uma assinatura sustentada somente pela promessa de “novidades em breve”. A Apple exige valor contínuo para assinatura. [Diretrizes, seção 3.1.2](https://developer.apple.com/app-store/review/guidelines/#subscriptions)

Exemplo puramente aritmético: 100 assinaturas ativas a R$ 9,90 resultariam em aproximadamente **R$ 824,67/mês após comissão de 15% e reserva de 2%**, antes de conteúdo, suporte, tributos e demais despesas. Ter 100 assinantes não é previsão. Cancelamentos, falhas de renovação, migração de compradores e sobreposição com ofertas existentes precisam ser medidos. Essa receita não está somada aos cenários da v1.

### Eventos patrocinados

Uma marca pode financiar um conjunto temático autorizado e receber uma identificação discreta de patrocínio. Exige escopo contratual, adequação ao público e direitos do conteúdo. Não misturar patrocinador com resposta correta ou vender vantagem. Não há valor estimável sem proposta e audiência demonstrada; receita excluída das contas.

## 8. Preços, produtos e experiência de compra

| Produto | Preço de teste | Tipo | Momento |
|---|---:|---|---|
| Coleção Estreia | R$ 14,90 | Compra única, não consumível | Primeira oferta paga |
| Cineus Plus | R$ 19,90 | Compra única, não consumível | Somente com intersticiais em operação |
| Coleção futura | R$ 9,90–14,90 | Compra única de itens definidos | Após avaliar a primeira |
| Cineus Clube | R$ 9,90/mês | Assinatura, proposta futura | Após validar entrega recorrente |

Começar com uma oferta paga, acrescentando a segunda apenas quando seu benefício existir. Não expor todos os modelos ao usuário de uma vez. Preços finais precisam existir nas lojas e a UI deve usar o preço localizado retornado por elas, não texto fixo divergente do pagamento.

**Jornada proposta:** concluir uma partida → Ver cartão → Personalizar → prévia → compra nativa → confirmação → aparência equipada. A tela de resultados mantém as ações já simplificadas. O acesso à compra fica dentro da personalização, sem novo botão comercial dominante no resultado.

Compras digitais usam os sistemas das lojas como caminho inicial. Exceções e programas de pagamento alternativo exigem análise própria; não planejar um botão Pix como atalho presumido para evitar comissão. [Google Play: pagamentos](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en), [Apple: compras no app](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)

## 9. Resultado financeiro esperado — hipóteses transparentes

Os números abaixo mostram **o que aconteceria se as hipóteses fossem atingidas**. Não há receita observada, eCPM contratado nem pesquisa de disposição a pagar. Anúncios e compras continuam desativados na versão atual. Os usuários das duas plataformas estão somados; disponibilizar em duas lojas não multiplica o número usado na tabela.

### Premissas

| Premissa | Conservador | Base | Expansão |
|---|---:|---:|---:|
| Usuários ativos diários médios — DAU | 200 | 1.000 | 5.000 |
| DAU / usuários mensais — MAU | 15% | 25% | 30% |
| MAU calculado | 1.333 | 4.000 | 16.667 |
| DAU que escolhe rewarded | 5% | 10% | 20% |
| Vídeos solicitados por optante/dia | 1 | 1,2 | 1,5 |
| Disponibilidade de anúncios | 75% | 85% | 90% |
| Conclusão remunerada do rewarded | 90% | 95% | 95% |
| eCPM do desenvolvedor: rewarded | R$ 8 | R$ 15 | R$ 20 |
| eCPM do desenvolvedor: intersticial | R$ 4 | R$ 6 | R$ 8 |
| Oportunidades elegíveis de intersticial / DAU sem Plus / dia | 0,15 | 0,30 | 0,50 |
| DAU que já possui Plus, média do mês | 1% | 3% | 8% |
| Novos compradores da coleção / MAU / mês | 0,30% | 0,75% | 1% |
| Novos compradores de Plus / MAU / mês | 0,10% | 0,25% | 0,50% |
| Ferramentas/infraestrutura/suporte, caixa mensal | R$ 100 | R$ 350 | R$ 700 |
| Produção de conteúdo/arte, caixa mensal | R$ 100 | R$ 200 | R$ 500 |
| Trabalho do proprietário, valor atribuído/mês | R$ 1.500 | R$ 1.800 | R$ 3.000 |

Os eCPMs são sensibilidades escolhidas, não benchmarks do Brasil. As oportunidades de intersticial já descontam sessões iniciais, pausas não elegíveis e limites de frequência; o modelo não prevê um anúncio por partida. O fator de conclusão aproxima receita do rewarded; substituir por impressões remuneradas reais nos relatórios da rede, que não se confundem com callbacks de recompensa.

Compras usam preço R$ 14,90/19,90, comissão de 15% e reserva de 2% para reembolsos. O percentual de comissão pressupõe enquadramento e adesão aplicáveis; deve ser confirmado nas duas lojas. Não há desconto de comissão de loja sobre anúncios, cujo eCPM já é do desenvolvedor. [Google: taxas](https://support.google.com/googleplay/android-developer/answer/112622?hl=en), [Apple: Small Business Program](https://developer.apple.com/app-store/small-business-program/)

### Recebimentos mensais modelados

| Recebimento | Conservador | Base | Expansão |
|---|---:|---:|---:|
| Rewarded | R$ 1,62 | R$ 43,61 | R$ 769,50 |
| Coleção Estreia, após comissão/reserva | R$ 49,65 | R$ 372,35 | R$ 2.068,62 |
| **Versão inicial: rewarded + coleção** | **R$ 51,27** | **R$ 415,96** | **R$ 2.838,12** |
| Intersticiais, etapa posterior | R$ 2,67 | R$ 44,52 | R$ 496,80 |
| Novas compras de Plus, após comissão/reserva | R$ 22,10 | R$ 165,77 | R$ 1.381,39 |
| **Versão ampliada: total das quatro fontes** | **R$ 76,04** | **R$ 626,25** | **R$ 4.716,31** |
| Caixa operacional + produção | R$ 200 | R$ 550 | R$ 1.200 |
| Saldo ampliado após esse caixa | −R$ 123,96 | R$ 76,25 | R$ 3.516,31 |
| **Saldo ampliado após caixa e trabalho atribuído** | **−R$ 1.623,96** | **−R$ 1.723,75** | **R$ 516,31** |

Linhas arredondadas individualmente; o cálculo utiliza valores completos. A versão inicial e a ampliada são estágios alternativos de operação; não somar seus totais. As taxas de compra da coleção na versão ampliada foram mantidas apenas para comparação, sem provar ausência de canibalização.

**Não é lucro líquido:** tributos, licenças de conteúdo, investimento inicial, contas das lojas e contingências não estão orçados. Os custos indicados são hipóteses a cotar. A atribuição ao mês de uso não simula calendário de repasses ou saldo bancário; é necessário capital de giro. O saldo positivo de R$ 516,31 na Expansão é frágil: um custo adicional mensal superior a esse valor já o eliminaria.

### O que os números dizem sobre as features

- No Base, a coleção pressupõe **30 compradores novos no mês** e o Plus **10 compradores novos**. Um produto avulso exige novos compradores elegíveis; não é receita recorrente do mesmo jogador.
- Se não houver novos compradores, restariam apenas anúncios. Mantendo o estoque de Plus e a atividade simulados, a versão ampliada Base receberia **R$ 88,13/mês** e teria saldo de **−R$ 2.261,87** depois do caixa e trabalho assumidos. Não é prudente depender apenas de anúncios.
- Na versão inicial Base, R$ 415,96 ainda ficariam abaixo dos R$ 550 de despesas de caixa assumidas, antes de remunerar o trabalho.
- A assinatura pode melhorar previsibilidade no futuro, mas acrescenta obrigação de conteúdo e suporte. Não incluí-la nas contas antes de existir produto recorrente.
- Se os gastos reais forem menores por uso de recursos próprios, o desembolso pode diminuir; isso não elimina o custo econômico das horas dedicadas.

### Fórmulas e reprodução

```text
MAU = DAU / (DAU/MAU)
Rewarded = DAU × 30 × adesão × vídeos × disponibilidade × conclusão × eCPM / 1.000
Intersticiais = DAU × (1 − proprietários Plus) × 30 × oportunidades elegíveis × disponibilidade × eCPM / 1.000
Coleção = MAU × taxa de novos compradores × R$ 14,90 × 0,85 × 0,98
Plus = MAU × taxa de novos compradores × R$ 19,90 × 0,85 × 0,98
Saldo preliminar = recebimentos − caixa operacional − produção − trabalho atribuído
```

Arquivos: [modelo reproduzível](modelo_monetizacao_produto.py), [premissas e resultados JSON](monetizacao_produto.json), [tabela CSV](monetizacao_produto.csv). Executar `python docs/business/modelo_monetizacao_produto.py` na raiz. Os modelos anteriores de aquisição não são usados neste plano.

## 10. Implementação técnica necessária

### Produtos e inventário

Catálogo local de itens com ID estável, tipo, asset, coleção e versão. Inventário separa posse de equipamento. O servidor valida transações e materializa os direitos; o dispositivo mantém cache para uso offline. Pacotes não podem reaplicar a concessão ao restaurar, nem apagar itens gratuitos quando um pagamento é revogado. Não armazenar apenas “premium = true” como prova de compra.

### Compras

Adaptador de compras nas duas lojas, produtos não consumíveis, tratamento de pagamento pendente/cancelado, confirmação, restauração, reembolso e revogação. Os direitos devem ser concedidos após validação, com processamento idempotente; notificações e reconciliação corrigem estados se o app estiver fechado. Compras de teste em sandbox, IDs e ambiente separados.

Usar Play Billing/StoreKit por integração Flutter compatível e validação adequada. O caminho Google recomenda backend para verificação; StoreKit fornece transações e ferramentas próprias. [Segurança Google Play](https://developer.android.com/google/play/billing/security), [StoreKit](https://developer.apple.com/storekit/)

Uma conta do jogo não precisa bloquear a primeira partida. Restauração com a conta da loja e sincronização de perfil são coisas distintas. Prometer continuidade Android↔iOS exige identidade e backend próprios, regras para juntar progresso e atendimento a conflitos. Isso precisa ser orçado antes de entrar como benefício pago.

### Publicidade e concessões

Controlador central de placements, disponibilidade, limites e direito Plus. Usar identificação única para concessão, processamento persistente e reconciliação; impedir duas recompensas para a mesma conclusão. O atual contador local pode ser reiniciado por reinstalação e não demonstra proteção de uma economia comercial. Quando necessário, usar a verificação de recompensa do provedor e limite confiável em backend.

Não travar o gameplay offline se rede, consentimento ou anúncios estiverem indisponíveis. Adapters desativados continuam sendo fallback correto para ambientes sem configuração.

### Medição mínima

Eventos de partida iniciada/concluída, modo, tutorial concluído, saldo insuficiente, saldo gasto, oferta de anúncio, anúncio/recompensa confirmada, coleção aberta, item pré-visualizado, compra iniciada/validada, restauração e revogação. Medir receita efetiva dos provedores; clique em comprar não é venda. Evitar conteúdo pessoal e não enviar palpites ou respostas sem uma finalidade demonstrada.

Separar relatórios por Android/iOS, versão e origem da receita. Comparar uso e retenção com e sem exposição comercial. A instrumentação atual não envia dados; criar um adaptador real com divulgações coerentes antes de confiar em funis.

## 11. Condições que alteram a rentabilidade

**Direitos de conteúdo:** o TMDB considera comercial um projeto voltado a gerar receita e orienta contato para licença comercial de dados/imagens. O valor e o escopo para distribuição offline e cartões não foram cotados. Gerar arte de um personagem por IA também não demonstra autorização comercial sobre uma franquia. Apurar licenças ou substituir por conteúdo original/autorizado antes de lançar receitas; um contrato pode alterar totalmente a margem calculada. [TMDB: FAQ](https://developer.themoviedb.org/docs/faq)

**Público e privacidade:** definir a audiência efetiva antes dos SDKs. Se direcionado a crianças, as restrições de publicidade e compras podem mudar o modelo; não presumir que basta declarar uma idade maior. Configurar consentimento, privacidade e rastreamento quando aplicáveis; não é exigência de ATT para qualquer analytics indistintamente. [Google: anúncios e famílias](https://support.google.com/googleplay/android-developer/answer/9857753?hl=en), [Apple: privacidade e dados](https://developer.apple.com/app-store/user-privacy-and-data-use/), [Apple: categoria infantil](https://developer.apple.com/app-store/review/guidelines/#kids-category)

**Custo de manter o produto:** arte, seleção de conteúdo, suporte a compras e validação iOS/Android são despesas do negócio. Recursos locais ajudam no gameplay, mas compras e reconciliação demandam serviços e operação. Os valores do modelo não são cotações de licenças nem garantia de custo total.

## 12. Sprints para concluir a monetização v1

| Sprint | Entrega correlacionada | Critério de conclusão | Resultado esperado |
|---|---|---|---|
| 1 — economia e fundação | Instrumentar saldo/uso/retorno; definir público, direitos e catálogo de produtos; separar direitos permanentes de assinatura | Eventos conferidos, regras e preço de teste definidos; nenhum benefício fictício exposto | Saber onde existe demanda e evitar modelo baseado em ticket que ninguém precisa |
| 2 — coleção e cartão | Assets originais, inventário, prévias, equipar e imagem compartilhada | Gratuitos e pagos visualizados corretamente; layout acessível e sem poluição adicional | Primeira feature com valor comercial visível |
| 3 — compras reais | Coleção Estreia, lojas, validação, restauração e suporte | Compra válida, pendente, cancelada, repetida e reembolsada testadas nas duas plataformas | Primeira receita por produto, com concessão confiável |
| 4 — rewarded | SDK, consentimento/configuração, +2 tickets, limites e recuperação de concessão | Recompensa correta uma única vez; erro/cancelamento/offline não danificam sessão | Receita opcional e leitura real de interesse pela recompensa |
| 5 — retorno e conteúdo | Missões semanais leves, recompensas visuais gratuitas, módulos curados e apresentação de coleção | Objetivos reais, progresso persistente, sem spoiler ou bloqueio de função existente | Sustentar frequência e utilidade da personalização |
| 6 — interrupções e Plus, se aprovados no teste | Experimento limitado de intersticial; Plus permanente associado | Frequência e posições verificadas; comprador não recebe interrupção; retorno sem deterioração material observada | Validar ou descartar essa fonte complementar |
| 7 — fechamento comercial | QA completo, desempenho, textos, dados das lojas, restauração, reconciliação e relatório de receita | Monetização v1 utilizável e verificada em Android e iOS; decisões pendentes resolvidas | Produto preparado para operar comercialmente |

Na sprint 6, **descartar intersticiais e Plus por falta de benefício/impacto ruim é uma decisão válida e encerra essa frente**. Não é necessário manter anúncio prejudicial para considerar a v1 completa. Nesse caso, a versão comercial consiste em coleção + rewarded e seus resultados devem ser comparados à linha financeira inicial.

As sprints têm escopo fechado, mas não datas prometidas: contas, revisão, licenças e validação em aparelhos dependem de acesso e respostas externas. Assinatura, temporadas adicionais e patrocínio são evolução posterior; não bloqueiam o fechamento da v1.

## 13. O que significa “100% completo” nesta etapa

O fluxo de ponta a ponta deve funcionar nas duas plataformas: conhecer a oferta, ver benefício real, pagar, receber, usar, reinstalar/restaurar e resolver reembolso. Rewarded entrega o prometido uma vez e não oferece anúncio indisponível como se estivesse pronto. Se intersticiais forem adotados, obedecem aos limites e ao Plus.

Também precisam estar resolvidos: direitos e público da versão comercial, textos e privacidade, dados de receita confiáveis, monitoramento de falhas, suporte e manutenção do jogo gratuito. Desempenho, acessibilidade, navegação e os três modos não podem regredir por causa de SDK ou oferta. Não basta criar uma tela de loja.

**V1 concluída significa monetização implementada e validada; não significa rentabilidade garantida.** A expectativa mais plausível a testar é: personalização como primeira oferta paga, rewarded como complemento e retorno frequente como sustentação. A receita real e o custo de entregar o produto decidirão quais fontes merecem crescer.
