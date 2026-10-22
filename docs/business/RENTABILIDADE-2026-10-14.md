# Cineus — análise e plano de rentabilidade

> **Relatório anterior, com escopo substituído:** o plano vigente solicitado pelo proprietário é [Monetização do produto](MONETIZACAO-PRODUTO-2026-10-14.md), dedicado às funcionalidades, ofertas e publicidade dentro do jogo. A aquisição paga fica para depois da conclusão da monetização v1. As simulações desta página permanecem apenas como histórico.

**Data:** 14 de outubro de 2026. **Escopo atualizado:** Android e iOS no Brasil, com **R$ 100 de mídia no primeiro teste**, conforme informado pelo proprietário. Esse valor é o teto inicial, sem compromisso de gasto recorrente. Público etário, métricas reais e licenças comerciais ainda precisam ser definidos. Não há acesso a Play Console, App Store Connect, AdMob ou faturamento real nesta análise.

## 1. Decisão recomendada

O Cineus tem uma estrutura adequada para testar um negócio pequeno: partidas curtas, três modos, desafios diários, compartilhamento e catálogo local. O conteúdo local reduz a necessidade de servidores para jogar. A rentabilidade depende principalmente de retorno frequente e de uma oferta paga com valor percebido. Disponibilizar nas duas lojas amplia a distribuição possível; não duplica automaticamente público ou receita.

**Eu começaria por um beta mensurável e anúncios recompensados opcionais, com uma oferta cosmética simples. Deixaria uma assinatura para depois de demonstrar retorno e capacidade de entregar novidades.** Não reduziria os 20 tickets gratuitos para forçar anúncios, nem bloquearia o catálogo atual atrás de pagamento.

**Para os R$ 100, recomendo um único experimento de aquisição no Android, reaproveitando artes e vídeos do próprio jogo, e divulgação orgânica no iOS.** As duas plataformas continuam no plano de lançamento. Concentrar a primeira verba evita dividir uma amostra já pequena entre sistemas, redes e muitos anúncios. Só escolher uma rede e configurar o experimento quando o app estiver publicável e as instalações puderem ser medidas. Não contratar ferramenta de atribuição ou produção de criativos paga para esse primeiro teste.

Com CPI hipotético de R$ 2 no Android, R$ 100 comprariam aproximadamente **50 instalações**, sem garantia de quantidade. O modelo inicial de anúncios + cosmético resultaria em apenas **R$ 10,67 de recebimentos ao longo da vida dessa coorte**, antes de várias despesas. **A função desse primeiro teste seria aprender sobre anúncio, instalação e primeira partida; não contar com o dinheiro voltando.** Se a monetização continuar desativada, a receita comercial dessa coorte será zero.

O produto ainda não permite afirmar que será lucrativo. Com as hipóteses deste relatório, **1.000 usuários ativos diários produziriam aproximadamente R$ 439/mês em recebimentos modelados**, dos quais apenas R$ 109 viriam de anúncios. Esse volume poderia cobrir parte de uma operação enxuta, mas não remuneraria adequadamente o trabalho de manutenção. Direitos sobre conteúdo e custo de licenciamento são a principal incerteza externa.

## 2. O que o projeto já tem e o que ainda falta

| Evidência no projeto | Consequência para o negócio |
|---|---|
| 500 filmes, 5.000 dicas, 50 personagens e 90 regiões; nove estágios de Cores, com duas partidas cada | Há conteúdo para um teste de retenção; novas sessões não exigem gerar imagens em tempo real |
| SQLite, imagens e conteúdo locais | Custo marginal de jogar é baixo; instalações não equivalem a clientes simultâneos em um servidor |
| Diários gratuitos, estágios, convites e cartão de resultado | Caminhos existentes para hábito e divulgação voluntária |
| 20 tickets gratuitos por dia; iniciar/refazer estágio custa um; retomar é grátis | Boa entrada gratuita, mas baixa escassez para vender tickets ou estimular muitos vídeos |
| Política de rewarded: +2 tickets, no máximo três por dia, sempre opcionais | Ponto de partida coerente, sujeito à medição de demanda real |
| `DisabledMonetizationService` e `DisabledProductTelemetry` em produção padrão | As integrações não estão operacionais; o código atual não oferece receita comercial ou métricas reais de produto |
| Sem adaptador real de anúncios/compras nas dependências atuais | Instalar SDKs, configurar produtos, implementar callbacks e validar em lojas ainda é trabalho futuro |
| Progresso e economia armazenados no dispositivo | Adequado ao jogo offline; compras precisam de restauração, validação e tratamento de reembolso antes de serem vendidas |

Evidências de código: [política de monetização](../../lib/domain/entities/monetization.dart), [serviço desativado](../../lib/data/services/disabled_monetization_service.dart), [telemetria desativada](../../lib/data/services/disabled_product_telemetry.dart), [dependências](../../pubspec.yaml). A receita modelada abaixo pressupõe implementar essas integrações; **não representa receita disponível na versão atual**.

### Conteúdo e duração

Com 20 tickets gratuitos, um jogador muito intenso consegue iniciar as 18 partidas de Cores em um dia. Não significa que a maioria fará isso, mas indica que a retenção não pode depender apenas de desbloquear os nove estágios. Para os filmes, 500 primeiras partidas consumiriam 25 dias de 20 tickets, ignorando tentativas adicionais e recompensas. O uso real deve ser medido.

As prioridades de conteúdo seriam diários interessantes, novos conjuntos de estágios, outras partes dos personagens e desafios compartilháveis. Não financiar uma assinatura recorrente apenas com a promessa de acesso ao catálogo que já é gratuito.

## 3. Condições comerciais antes de ativar receitas

### Conteúdo e direitos

O TMDB distingue projetos comerciais dos não comerciais e orienta obter uma licença comercial para uso comercial de sua API, dados ou imagens. A licença gratuita com atribuição não deve ser tratada como autorização comercial automática. Solicitar proposta que descreva o jogo, os pôsteres incluídos no aplicativo, distribuição offline e cartões compartilhados. **Não há preço público suficiente nesta fonte para orçar esse contrato.** [TMDB: FAQ e licenciamento](https://developer.themoviedb.org/docs/faq)

Também é necessário verificar direitos sobre os personagens e imagens de terceiros usados em Cores. O registro de origem e a geração por IA não demonstram, por si, autorização do titular de uma franquia. A política do Google Play abrange propriedade intelectual, imagens de filmes/desenhos e modificações de conteúdo protegido. Avaliar licenças com escopo adequado ou um catálogo original/licenciado antes da exploração comercial. Isso é uma condição de distribuição e de orçamento, sem concluir aqui a situação jurídica de cada obra. [Google Play: propriedade intelectual](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en)

Os novos fundos e emblemas desta correção foram gerados como arte genérica; não substituem a análise dos direitos do catálogo principal.

### Loja, publicidade e público

- Para o Brasil, o modelo usa **15% nas compras de ambas as lojas**, pressupondo enquadramento/adesão ao programa aplicável. No Google, conferir o programa de 15% e as regras do produto; na Apple, a adesão ao Small Business Program depende de elegibilidade e aprovação, não é automática. Revalidar no lançamento. **Não aplicar essa comissão novamente à receita de anúncios.** [Taxas do Google Play](https://support.google.com/googleplay/android-developer/answer/112622?hl=en), [Apple Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- A conta de desenvolvedor Google Play tem taxa única de **US$ 25**, separada do fluxo mensal em reais. Contas pessoais novas podem exigir teste fechado com pelo menos 12 testadores inscritos continuamente por 14 dias antes de solicitar produção. [Conta](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), [testes](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- O Apple Developer Program custa **US$ 99 por ano, ou moeda local onde disponível**. Conferir a cobrança efetiva no cadastro; não converter aqui por uma cotação presumida. Essa anuidade e a conta Google são **separadas dos R$ 100 de mídia**. [Apple: valores e recursos](https://developer.apple.com/programs/whats-included/)
- Preparar compilação, assinatura e testes iOS com acesso a macOS/Xcode e um iPhone, próprios, emprestados ou por serviço adequado. Orçar qualquer acesso pago antes de contratar. A pasta iOS no repositório não comprova funcionamento em aparelho; não foi validado um build iOS nesta análise em Windows. [Flutter: preparação para iOS](https://docs.flutter.dev/platform-integration/ios/setup)
- No iOS, ATT é necessário quando houver rastreamento nos termos da Apple, como vinculação de dados entre empresas para publicidade. Não presumir que qualquer medição exige ATT, nem contornar a recusa. Conferir dados dos SDKs e declarações de privacidade; atribuição pode ter limites e atrasos. [Apple: privacidade e uso de dados](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- Rewarded precisa descrever ação e recompensa, obter a escolha do jogador, permitir recusa sem impedir o uso normal e entregar o prometido. O ticket deve continuar sendo benefício interno. [Política de recompensas do AdMob](https://support.google.com/admob/answer/7313578?hl=en)
- Definir público etário antes de configurar SDKs e publicidade. Desenhos conhecidos podem atrair menores; não declarar uma idade apenas para contornar obrigações. Avaliar dados mínimos, base legal e melhor interesse conforme o público efetivo. [Orientação da ANPD](https://www.gov.br/anpd/pt-br/assuntos/noticias/anpd-divulga-enunciado-sobre-o-tratamento-de-dados-pessoais-de-criancas-e-adolescentes)

## 4. Fontes de receita e ordem de teste

| Opção | Proposta para Cineus | Decisão inicial |
|---|---|---|
| Vídeo recompensado | Troca explícita por +2 tickets, respeitando o limite atual | Primeiro experimento comercial; sem anúncio na abertura ou no meio da escolha de cor |
| Cosméticos avulsos | Molduras do cartão, temas de interface e emblemas decorativos originais | Testar disposição a pagar sem prometer serviço recorrente; preço ilustrativo de teste R$ 9,90–19,90 |
| Pacote de fundador | Conjunto cosmético permanente e descrição objetiva dos itens | Possível teste limitado; nada de promessas vagas de conteúdo futuro |
| Cineus Pass | Cosméticos sazonais e novidades entregues com regularidade | Só depois de validar interesse e uma rotina sustentável; R$ 9,90/mês é hipótese inicial, não preço publicado |
| Anúncio entre partidas | Intervalo natural após vários jogos, com limite de frequência | Adiar; primeiro medir efeito sobre retorno e conclusão |
| Banners | Pouco espaço útil em telas já visuais | Não priorizar |
| Patrocínio/parceria | Temporada ou desafio de marca com conteúdo autorizado | Prospectar após demonstrar público; receita excluída do modelo sem contrato |

Assinatura “sem anúncios” oferece pouco valor enquanto não há anúncios obrigatórios. Tampouco há evidência de que o jogador comprará tickets recebendo 20 por dia. A oferta paga deve ter benefício demonstrável, sem alterar a política atual de acesso gratuito aos modos e ao catálogo incluído.

## 5. Modelo financeiro mensal

Todos os valores de receita, eCPM, adoção, disponibilidade, custos e preço abaixo são **hipóteses de sensibilidade**, não benchmarks observados do mercado brasileiro, contratos ou metas garantidas. Os cenários não são uma curva de crescimento prevista.

Esta tabela representa a **base ativa total das duas plataformas**, já retida, antes de descontar aquisição. Para abrir os números por sistema, o arquivo usa 70% do público no Android e 30% no iOS, apenas como divisão de trabalho, **não participação de mercado**. Ambos usam a mesma monetização hipotética: não há evidência de maior valor por usuário iOS neste jogo. No Base, são 700 DAU Android + 300 DAU iOS, totalizando os mesmos 1.000 DAU e R$ 438,88. A divisão de público também não decorre da divisão de verba: CPI e retenção podem ser diferentes.

A receita de assinatura desta tabela é uma possibilidade futura. O produto inicial recomendado é cosmético avulso; a seção 6 calcula esse caso separadamente. Os valores de despesas continuam ilustrativos e precisam incorporar o custo real de manter duas lojas. Não usar esta tabela como projeção de retorno do teste de R$ 100.

**DAU**: pessoas ativas em um dia médio. **MAU**: pessoas distintas ativas no mês. **eCPM do publisher**: receita do desenvolvedor por mil impressões remuneradas; não é o preço bruto cobrado do anunciante. A adoção paga é a fração de MAU com assinatura ativa, não a conversão mensal de novas instalações.

| Premissa | Conservador | Base | Expansão |
|---|---:|---:|---:|
| DAU | 200 | 1.000 | 5.000 |
| DAU/MAU | 15% | 25% | 30% |
| MAU estimado | 1.333 | 4.000 | 16.667 |
| Fração de DAU que opta por rewarded | 10% | 20% | 30% |
| Vídeos solicitados por optante/dia | 1 | 1,5 | 2 |
| Disponibilidade de anúncios | 70% | 85% | 90% |
| Conclusão remunerada | 90% | 95% | 95% |
| eCPM líquido do publisher, R$ | 8 | 15 | 25 |
| Assinantes ativos / MAU | 0,3% | 1% | 2% |
| Preço mensal hipotético, R$ | 9,90 | 9,90 | 12,90 |
| Comissão assumida nas compras | 15% | 15% | 15% |
| Reserva de reembolsos nas compras | 2% | 2% | 2% |
| Despesas de caixa/mês, R$ | 200 | 350 | 900 |
| Pró-labore/trabalho/mês, R$ | 1.500 | 1.800 | 3.000 |

Os assinantes esperados podem ser fracionários no cálculo estatístico; não se arredonda o número antes de calcular a receita. Preços maiores e desempenho melhor no cenário Expansão são hipóteses adicionais, não uma consequência automática de ter mais usuários.

### Fórmulas reproduzíveis

```text
MAU = DAU / (DAU/MAU)
Impressões remuneradas = DAU × 30 × opt-in × vídeos × disponibilidade × conclusão
Receita de anúncios = impressões remuneradas × eCPM / 1.000
Recebimentos de compras = MAU × fração assinante × preço × (1 − comissão) × (1 − reembolsos)
Contribuição de caixa = anúncios + compras − despesas de caixa
Contribuição econômica = contribuição de caixa − pró-labore
Resultado final = contribuição econômica − tributos − licenças − aquisição paga − outros custos não orçados
```

O fator de conclusão é um desconto conservador nas solicitações, usado para estimar impressões remuneradas. Na operação, substituir por impressões/receita efetivamente reportadas pela rede; impressões de anúncios nem sempre coincidem com callbacks de recompensa. O eCPM usado já é o recebido pelo publisher. Não descontar novamente uma participação da rede.

### Resultados dos cenários

| Resultado mensal, R$ | Conservador | Base | Expansão |
|---|---:|---:|---:|
| Anúncios | 3,02 | 109,01 | 1.923,75 |
| Compras após comissão e reserva | 32,99 | 329,87 | 3.581,90 |
| **Recebimentos modelados** | **36,01** | **438,88** | **5.505,65** |
| Contribuição após caixa | −163,99 | 88,88 | 4.605,65 |
| **Após caixa e pró-labore** | **−1.663,99** | **−1.711,12** | **1.605,65** |

**Nenhuma das duas últimas linhas é lucro líquido.** Não incluem tributos, contratos de licenciamento, custo histórico de desenvolvimento, investimento inicial, aquisição paga ou contingências. Os R$ 200/350/900 de despesas são tetos ilustrativos para ferramentas, infraestrutura, suporte e produção; precisam ser substituídos por cotações. Os valores de pró-labore não são estimativas de salário de mercado.

A tabela atribui receitas ao mês de uso e aproxima os repasses, sem simular datas de liquidação, retenções ou valores mínimos de pagamento das plataformas. “Contribuição de caixa” é o saldo operacional modelado, não um extrato nem uma projeção de saldo bancário. Planejar capital de giro para o intervalo entre despesas e repasses.

O cenário Base praticamente se paga em caixa antes dessas exclusões, mas não paga o trabalho. O cenário Expansão teria margem econômica preliminar de aproximadamente 29% antes das exclusões; uma licença de R$ 2.000/mês já eliminaria essa margem. Esse valor de licença é apenas teste de sensibilidade, não cotação.

Arquivos reproduzíveis: [modelo Python](modelo_rentabilidade.py), [premissas e resultados JSON](cenarios.json), [tabela CSV](cenarios.csv), [divisão por plataforma](cenarios_plataformas.csv).

### Equilíbrio e ausência de compradores

Mantendo as proporções do cenário Base, a receita por DAU/mês seria R$ 0,43888. Com R$ 350 de caixa, o equilíbrio preliminar estaria perto de **798 DAU**. Incluindo R$ 1.800 de trabalho, seria aproximadamente **4.899 DAU**, antes de tributos e licenças. Isso supõe custo fixo constante até esse volume; reorçar quando a operação crescer.

Se ninguém assinar, a receita de 1.000 DAU cairia a **R$ 109/mês**. Para cobrir R$ 2.150 apenas com os anúncios do cenário Base, seriam necessários cerca de **19.723 DAU**. Portanto, não usar “quantidade de downloads” como indicador suficiente de retorno financeiro.

## 6. Primeiro teste de mídia: teto de R$ 100

### Uso recomendado da verba

1. Preparar uma gravação curta de uma rodada real, com início claro e resultado visual; usar conteúdo com direitos adequados. Escolher a melhor demonstração entre Dicas, Pôster e Cores organicamente antes de pagar por distribuição.
2. Rodar **uma campanha de instalação no Brasil para Android, com um criativo e limite total de R$ 100**. Escolher uma rede que aceite a configuração e o orçamento no momento de criar a campanha. Não abrir vários conjuntos para tentar testar tudo com essa verba.
3. Acompanhar gasto, instalações válidas e conclusão da primeira partida. Verificar erros cedo; interromper se o destino, a instalação ou a medição estiverem quebrados. Conferir como a rede aplica o limite de orçamento para manter o total dentro do teto; não configurar só um gasto diário sem data final.
4. Encerrar no teto e observar retorno D1/D7. **Não renovar automaticamente.** Se o teste vier com poucas instalações, aproveitar feedback qualitativo e divulgação orgânica; não concluir que a ausência de compradores prova falta de demanda.
5. No iOS, preparar a página da loja, beta e divulgação orgânica; reservar um teste pago específico para quando houver nova verba e validação técnica. Não aumentar o orçamento informado para tentar cobrir as duas lojas de uma vez.

Produção do criativo com recursos próprios: **R$ 0 de desembolso adicional assumido**, não trabalho gratuito em termos econômicos. Contas de loja, licenças, equipamentos/serviços de build e eventual faturamento de mídia com tributos/encargos precisam ser considerados à parte. Se R$ 100 também tiver de cobrir encargos da campanha, reduzir a mídia para caber no total. Não foi iniciada campanha nem contratada ferramenta nesta tarefa.

### Quantas instalações esse teste poderia trazer?

Os CPIs abaixo são números para testar a conta, **não preços observados ou cotados**. O CPI real pode ficar fora desta faixa. Instalações não são usuários ativos permanentes.

| CPI hipotético no Android | R$ 100 de mídia / CPI |
|---|---:|
| R$ 1 | 100 instalações |
| R$ 2 | 50 instalações |
| R$ 4 | 25 instalações |

Com 50 instalações, uma única pessoa representa 2 pontos percentuais. Uma conversão de compra hipotética de 1% equivale a apenas 0,5 comprador esperado; zero compras seria um resultado plausível. Este experimento não tem amostra para estimar LTV com confiança, escolher entre vários canais ou comprovar lucratividade. Acrescentar beta e tráfego orgânico melhora a leitura do produto, mas manter as origens separadas.

### Receita por instalação e comparação entre sistemas

**Coorte**: conjunto de novas instalações acompanhado ao longo do tempo. **LTV aqui**: recebimentos esperados durante a vida da coorte, depois da comissão e reserva de reembolsos das compras, ainda antes de tributos, licenças e outros custos variáveis não cotados. **CPI**: mídia dividida pelas instalações. **Custo de aquisição por instalação** deve incluir também criativo, gestão e atribuição pagos; não é CAC por comprador.

| Premissa de coorte | Android | iOS |
|---|---:|---:|
| CPI usado apenas na simulação | R$ 2,00 | R$ 4,00 |
| Dias ativos ao longo da vida, média sobre todas as instalações | 20 | 20 |
| Receita de anúncios por dia ativo | R$ 0,00363375 | R$ 0,00363375 |
| Instalações que compram ao longo da vida | 1% | 1% |
| Cosmético inicial: uma compra por comprador | R$ 16,90 | R$ 16,90 |
| Comissão elegível / reserva de reembolsos | 15% / 2% | 15% / 2% |
| LTV apenas de anúncios | R$ 0,072675 | R$ 0,072675 |
| **LTV anúncios + cosmético avulso** | **R$ 0,213452** | **R$ 0,213452** |
| LTV alternativo com Pass futuro, em vez do cosmético | R$ 0,320076 | R$ 0,320076 |

O Pass alternativo supõe 1% das instalações pagando três meses a R$ 9,90. Não somar os dois produtos como se todos comprassem ambos. A conversão de coorte acima é diferente da fração de assinantes ativos/MAU da seção 5. Os 20 dias ativos incluem a média de quem abandona ou nem termina a primeira partida; não multiplicar outra taxa de ativação novamente. Não se pressupõe que todos esses dias ocorram no primeiro mês.

```text
Anúncios/dia ativo = 20% × 1,5 vídeos × 85% disponibilidade × 95% conclusão × R$ 15 / 1.000
LTV anúncios = 20 dias ativos × R$ 0,00363375
LTV cosmético = 1% × R$ 16,90 × (1 − 15%) × (1 − 2%)
LTV inicial = LTV anúncios + LTV cosmético
Instalações por sistema = mídia destinada ao sistema / CPI desse sistema
Recebimentos da coorte = instalações × LTV
Saldo da coorte = recebimentos da coorte − mídia − outros custos de aquisição
```

| Destinação dos mesmos R$ 100 | Recomendação: Android primeiro | Comparação: 70% Android / 30% iOS |
|---|---:|---:|
| Mídia Android / iOS | R$ 100 / R$ 0 | R$ 70 / R$ 30 |
| Instalações Android / iOS esperadas | 50 / 0 | 35 / 7,5 |
| Instalações totais esperadas | 50 | 42,5 |
| LTV total, só anúncios | R$ 3,63 | R$ 3,09 |
| **LTV total, anúncios + cosmético** | **R$ 10,67** | **R$ 9,07** |
| Saldo após mídia, antes das exclusões | −R$ 89,33 | −R$ 90,93 |
| LTV alternativo com Pass futuro | R$ 16,00 | R$ 13,60 |

Números fracionários são médias esperadas, não uma promessa de instalações ou compradores fracionários. As duas colunas são **alternativas**, não duas campanhas de R$ 100. O exemplo 70/30 não é participação de mercado nem recomendação para pulverizar esta verba.

Nenhum recebimento de vida inteira deve ser lançado integralmente como receita no mês da campanha. Não foi estimado prazo de retorno: faltam retenção e cronograma de compras reais. Não somar este LTV à receita mensal da mesma base de usuários, o que duplicaria receitas. A simulação assume instalações incrementais; atribuição de uma rede não demonstra por si que todas foram causadas pela mídia.

### Limite para ampliar aquisição no futuro

Usando uma meta interna ilustrativa de LTV/custo de aquisição ≥ 1,3, o produto inicial permitiria custo total de aquisição de apenas **R$ 0,164 por instalação**, ainda antes das exclusões. Se não houver gasto adicional de criativo/gestão, esse seria também o teto preliminar de CPI. Com custo adicional equivalente a 20% da mídia, o teto de CPI cairia para **R$ 0,137**. No Pass alternativo, o teto sem adicionais seria R$ 0,246. Esses limites não são lances recomendados nem preços de mercado.

Isso significa que as premissas atuais **não sustentam compra contínua de usuários com CPI de R$ 2 ou R$ 4**. É preciso melhorar retorno, dias ativos, receita por jogador ou distribuição orgânica antes de esperar margem. Se o usuário pagar R$ 2 para adquirir cada instalação e ela retornar R$ 0,21 ao longo da vida, aumentar verba aumenta a perda. O primeiro R$ 100 pode comprar aprendizado; a próxima verba deve depender do que foi aprendido.

Arquivos da simulação: [premissas e resultados de aquisição](aquisicao_paga.json), [comparação das destinações](aquisicao_paga.csv), [detalhamento Android/iOS](aquisicao_plataformas.csv). Executar `python docs/business/modelo_rentabilidade.py` a partir da raiz reproduz as tabelas sem rede ou credenciais.

### O que medir

| Medida | Pergunta que resolve |
|---|---|
| tutorial iniciado/concluído, primeira partida iniciada/concluída | O jogador entende o produto? |
| D1, D7 e D30 por coorte de instalação e origem | O hábito existe além da primeira sessão? |
| DAU, WAU, MAU; dias ativos por pessoa | Há frequência suficiente para receita recorrente? |
| Partidas por modo, avanço, tentativas, abandono | Onde o conteúdo diverte ou frustra? |
| Tickets disponíveis/usados; oferta, opt-in, disponibilidade e recompensa de anúncios | Existe motivo voluntário para assistir? |
| Oferta vista, compra válida, restauração, reembolso e renovação | A oferta paga tem demanda e funciona? |
| Receita por pessoa/coorte e custo de conteúdo por mês | Há margem após manter o jogo interessante? |

Para acompanhar o produto, proponho referências internas de D1 ≥ 30%, D7 ≥ 12%, D30 ≥ 5% e conclusão da primeira partida ≥ 70%. São critérios escolhidos para este projeto, não benchmarks oficiais. O teste de R$ 100 pode dar sinais, mas provavelmente não fornecerá amostra para aprovar esses números com confiança. Avaliar também feedback e coortes orgânicas, sempre separando sistema, origem e data. Antes de escalar, acumular amostra maior e observar receita e retenção maduras; um CPI baixo ou poucos primeiros compradores não bastam.

## 7. Plano de execução por sprints

| Sprint | Entrega | Critério de saída |
|---|---|---|
| 0 — comercial e público | Definir titular/contas das duas lojas, idade-alvo, inventário de direitos e pedido de licença TMDB | Custos de loja/licença/build separados do teto de R$ 100; sem assumir autorização apenas por citar a fonte |
| 1 — beta e medição nas duas plataformas | Validar iOS em macOS/iPhone, beta Android e TestFlight; eventos mínimos de funil e painel de coortes por sistema/origem | Primeira partida, retorno e instalação medidos; privacidade/ATT quando aplicável; teste fechado Google aplicável concluído |
| 2 — rewarded | SDK real, anúncios de teste, consentimento quando necessário, disponibilidade e callback de crédito idempotente | Jogar offline continua; erro/cancelamento não cobra nem duplica tickets; testar reinstalação e retorno do app |
| 3 — disposição a pagar | Cosmético original avulso nas duas lojas, validação, restauração e reembolso | Compra pendente não libera indevidamente; compra válida restaura; observar interesse antes de assinatura |
| 4 — piloto de R$ 100 | Um criativo e uma campanha Android, iOS orgânico; limite total e encerramento definidos | Relato de gasto, instalações, primeiras partidas e retorno; nenhuma renovação automática e nenhuma promessa de lucro |
| 5 — recorrência e eventual escala | Rotina de conteúdo; Pass somente com entrega recorrente sustentável; nova mídia só com verba definida | LTV após custos supera aquisição com margem e prazo de retorno aceitáveis; analisar por sistema e coorte |

As durações dependem das integrações e respostas externas; revisão de loja e negociação de licença não têm prazo garantido. As sprints são planejamento, não autorização para publicar, contratar serviços, veicular anúncios ou ativar cobranças nesta tarefa.

### Preparação técnica indispensável

O caminho oficial de Flutter exige configurar o Google Mobile Ads SDK e as contas/unidades correspondentes. O UMP permite atualizar consentimento e checar `canRequestAds()` antes de solicitar anúncios. Não basta trocar um ID de teste por um real. [SDK Flutter](https://developers.google.com/admob/flutter/quick-start), [UMP](https://developers.google.com/admob/flutter/privacy)

Compras exigem tratamento do ciclo real de cada loja: validar legitimidade, liberar apenas estado válido, concluir/reconhecer conforme a plataforma e lidar com cancelamento/reembolso/restauração. A documentação Google recomenda validação em backend para reduzir fraude; no iOS preparar StoreKit e o ciclo de transações. Orçar essa arquitetura mesmo com gameplay local. Compras Android não se restauram automaticamente no iOS sem uma política e um mecanismo de conta apropriados; não prometer sincronização inexistente. [Segurança Google Play](https://developer.android.com/google/play/billing/security), [Apple StoreKit](https://developer.apple.com/storekit/)

## 8. Próxima decisão prática

1. Preparar Android e iOS para distribuição, apurando direitos e custos das contas/build separadamente.
2. Rodar beta orgânico e medir retenção, desempenho e consumo de tickets.
3. Integrar rewarded opcional e validar um cosmético avulso, sem depender de assinatura no começo.
4. Executar o primeiro teste com teto de R$ 100 de mídia, preferencialmente concentrado no Android, quando a medição e a publicação estiverem prontas.
5. Ler o resultado sem extrapolar a amostra, recalcular com dados observados e só então decidir sobre outra verba.

**Decisão para este orçamento:** manter Android e iOS como destinos do produto, usar divulgação orgânica em ambos e concentrar os primeiros R$ 100 pagos em um experimento simples. Há viabilidade de testar interesse com pouco desembolso em mídia; ainda não há evidência de aquisição lucrativa. Se as contas e a distribuição iOS ainda não estiverem viabilizadas, preparar esse lançamento em paralelo, sem consumir os R$ 100 supondo que eles cubram todas as despesas do negócio.
