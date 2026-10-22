# Cineus: conteúdo geek, monetização e direitos

Planejamento original de 21/10/2026. Escopo: Android e iOS no Brasil, com anúncios como receita prioritária. Aquisição paga de usuários fica fora desta etapa.

**Atualização de implementação:** o usuário autorizou a execução e esclareceu que os personagens conhecidos de **Cores devem ser preservados**. O elenco de homenagens substitui apenas os antigos mascotes de animais nas coleções e missões. Isso substitui a proposta de piloto autoral para Cores descrita abaixo. O registro do que foi efetivamente alterado e das pendências externas está em [Implementação de cinema](IMPLEMENTACAO-CINEMA-2026-10-21.md). O restante deste arquivo conserva o planejamento original como histórico, não como atestado de conclusão ou licença.

**Público atualizado após as respostas do usuário:** o jogo tem público pretendido de **16 anos ou mais**, com **adultos de 18 anos ou mais como público comprador**. Esta decisão substitui a hipótese anterior de incluir crianças menores de 13 anos. O foco comercial é uma escolha de posicionamento, não evidência de que essa faixa converterá. A classificação nas lojas precisa refletir o conteúdo e os recursos reais.

**Recomendação:** reduzir a vitrine comercial a tickets, ajuda por vídeo e remoção de anúncios comuns; construir uma identidade geek própria; e resolver a procedência comercial do conteúdo antes de uma publicação monetizada. Coleções e assinatura não deveriam ser a aposta principal no produto atual.

Esta é uma análise preliminar de produto e risco documental, não uma autorização jurídica. A falta de comprovante no repositório não prova que um contrato externo inexista; significa que sua cobertura ainda não pôde ser verificada. Exceções controversas, contratos e a seleção final de artes precisam de revisão jurídica antes do lançamento.

## 1. O que a inspeção encontrou

| Evidência atual | Implicação para o plano |
| --- | --- |
| 500 arquivos em `assets/posters/` | O problema de direitos não está restrito aos personagens de Cores. |
| 50 personagens em `assets/credits/colors_sources.json`: 26 artes geradas e 24 baseadas em referências | Gerar, redesenhar ou vetorizar não comprova autorização sobre personagens reconhecíveis. |
| 33 referências de estudo apontam para `toontone.app` | Fazer curadoria independente das perguntas, regiões e referências; a presença dessas URLs não demonstra, isoladamente, uma infração. |
| `docs/legal/content-rights.json`: 4 de 5 grupos aguardam evidência | O validador com `--public-release` falhou como previsto, solicitando documentação. As fontes Fredoka/Nunito são o grupo marcado como verificado. |
| 10 tickets diários; vídeo concede 2, com limite de 3 recompensas diárias compartilhado com ajudas | A oferta é simples, mas a procura depende de o jogador realmente precisar e querer continuar. |
| Dicas/Pôsteres: bônus padrão de 10 tickets ao concluir estágio de 10 filmes | Em uma passagem sem gastos adicionais, 10 entradas podem ser integralmente repostas. Isso enfraquece a necessidade de comprar ou assistir. |
| Há variante `economy_v2` com bônus 4; rollout padrão do servidor é zero | Existe base para testar outro equilíbrio sem inventar uma segunda economia. Estágios antigos preservam o contrato fixado. |
| Cores: uma entrada compra uma partida de cinco rodadas | Dez tickets podem financiar 50 rodadas, antes de outros bônus. Comparar só o número de tickets entre os modos engana. |
| Catálogo/interface atuais: pacotes de 20 e 60 tickets | Há documentação antiga mencionando 10/30. Unificar a documentação e os produtos reais antes da ativação. |
| Plus só pode ser ofertado quando `plus && interstitials` | Com nativos/banners e intersticiais desligados, o produto de remoção pode ficar indevidamente indisponível. Planejar correção. |
| `CINEUS_ADS_AUDIENCE` define `general`, `teen` ou `child` para a build | Essa configuração global ainda não comprova tratamento correto de público misto por usuário. Planejar tratamento de idade e privacidade antes de habilitar anúncios reais. |
| Coleções decoram principalmente o cartão compartilhado; Clube acrescenta coleção mensal | O valor depende de uso real de personalização/compartilhamento. Não há conversão observada que justifique tratá-los como pilares. |

Fontes locais principais: [inventário de direitos](C:/Projects/Cineus/docs/legal/content-rights.json), [fontes dos personagens](C:/Projects/Cineus/assets/credits/colors_sources.json), [regras de recompensa](C:/Projects/Cineus/lib/domain/entities/ticket_reward.dart), [economia por estágio](C:/Projects/Cineus/lib/data/repositories/economy_repository.dart), [configuração comercial](C:/Projects/Cineus/lib/domain/entities/commercial_configuration.dart) e [catálogo de produtos](C:/Projects/Cineus/lib/domain/entities/commercial_product.dart).

## 2. Conteúdo geek que pertença ao Cineus

### A direção criativa recomendada

Trocar o foco de animais decorativos sem relação forte com as partidas por um elenco ligado aos **gêneros e aos bastidores do cinema**. Isso não exige descartar automaticamente as artes atuais; primeiro devemos testar quais ainda combinam com a direção.

Exemplos conceituais, ainda sem artes ou nomes comercialmente liberados:

| Conceito original | Ligação com cinema/geek | Possível uso |
| --- | --- | --- |
| Projecionista interdimensional | Uma operadora que conserta sessões em universos diferentes | Tutorial e ficção científica |
| Detetive da Fileira Sete | Investigação de mistérios numa sala de cinema | Dicas e mostras de suspense |
| Robô contrarregra | Máquina modular que organiza cenários e troca acessórios | Cores e conquistas de precisão |
| Cavaleira da Última Sessão | Fantasia medieval com equipamentos de produção próprios | Mostra de aventura |
| Cartógrafa de constelações | Exploração espacial com instrumentos e roupa autorais | Coleção espacial |
| Criatura do camarim | Monstro que trabalha na equipe de maquiagem | Terror leve e desafios de memória |
| Pilota de cenários | Especialista em veículos cenográficos impossíveis | Ação e velocidade |
| Arqueóloga dos rolos perdidos | Pesquisa a história de um cinema fictício | Arquivo e clássicos |
| Mensageiro da cidade de neon | Aventura urbana com linguagem visual própria | Temas noturnos |
| Guardiã do arquivo de histórias | Conservação de memórias e objetos de filmagens fictícias | Jornada e domínio |

Cada ficha deve definir silhueta, personalidade, materiais, acessórios, paleta, história e humor próprios. Não basta retirar um logo de um traje conhecido. Revisar o conjunto, inclusive nomes, poses, rosto, voz, símbolos e o modo de apresentar a coleção. Nomes desta tabela são rascunhos, sem busca de marca concluída.

### O que aproveitar da ideia do Broforce

A referência serve para discutir humor, exagero e reconhecimento de gêneros. **Não foi verificada a cadeia contratual de Broforce, e sua existência no mercado não autoriza o Cineus a copiar personagens ou a adotar a mesma defesa.**

A legislação brasileira distingue ideias/regras de jogo da expressão artística. Reprodução e adaptação de obras protegidas podem exigir autorização; a exceção de paródia tem condições. Usar outro nome, outra cor, silhueta, desfoque, SVG ou IA não é uma licença. Também não existe uma porcentagem geral de mudança que torne uma cópia segura. [Lei de Direitos Autorais, arts. 7, 8, 29 e 47](https://www.planalto.gov.br/ccivil_03/leis/l9610.htm).

O STJ descreve a paródia como uma criação autônoma com conteúdo cômico/satírico e registra requisitos adicionais, incluindo limites relacionados à exploração publicitária. Não devemos concluir que toda exploração comercial é proibida nem que todo uso engraçado está liberado. Uma coleção vendida por sua semelhança com astros ou franquias exige análise do uso concreto; um simples trocadilho não resolve. [STJ, REsp 1.967.264/SP, Informativo 725](https://processo.stj.jus.br/jurisprudencia/externo/informativo/?livre=%40CNOT%3D018846).

Para este projeto e orçamento, recomendo **arquétipos autorais de gênero como padrão**, licenças pontuais quando fizerem sentido e paródias reconhecíveis apenas após revisão específica.

### O efeito sobre o jogo de Cores

Personagens inéditos não trazem a mesma memória prévia de Bob Esponja ou Goku. Portanto, substituir as imagens sem adaptar a experiência enfraqueceria o desafio.

Duas rotas para decidir antes de produzir o catálogo:

1. **Memória visual autoral:** mostrar a referência brevemente, ocultá-la e pedir para recompor uma região. Observar → lembrar → ajustar → comparar. Testar duração e dificuldade; não fixar uma regra universal sem jogar o protótipo.
2. **Memória cultural com licença:** manter a proposta de lembrar personagens conhecidos, usando um acervo expressamente autorizado. Parcerias com autores independentes podem ser um começo; custo e disponibilidade ainda não foram consultados.

Piloto recomendado: **10 personagens originais, com três regiões distintas em cada um**, permitindo três estágios de dez personagens sem repetir o mesmo desenho dentro do estágio. Validar diversão e clareza antes de ampliar a cinquenta. Isso é um piloto proposto, não uma redução já feita no catálogo atual.

Temporadas poderiam virar **mostras jogáveis**: uma seleção temática de partidas e uma conquista ligada ao desempenho. Avatares/molduras entram como recordação visível do que o jogador fez, em vez de uma vitrine de seis desenhos sem vínculo forte com o jogo. Não criar obrigação mensal de conteúdo enquanto a capacidade de produção não estiver demonstrada.

## 3. Monetização: o que manter, corrigir e adiar

| Produto/formato | Decisão proposta | Motivo e aplicação |
| --- | --- | --- |
| Vídeo por tickets | Prioridade principal | Troca compreensível no momento em que o jogador quer continuar. Manter escolha explícita e entrega confiável. |
| Vídeo por ajuda | Prioridade principal | Atende uma dificuldade concreta. Mostrar benefício e eventual impacto na nota antes da escolha. |
| Pacotes de tickets | Manter, com dois tamanhos | Alternativa para quem prefere pagar a assistir. A quantidade precisa ter valor na economia revisada. |
| Nativos | Receita complementar | Usar intervalos previstos nas listas e a posição da inicial; medir impressões reais e impacto na navegação. |
| Remover anúncios comuns | Manter e simplificar a promessa | Explicar que remove nativos, banners e intersticiais cobertos; vídeos recompensados continuam opcionais. |
| Coleções avulsas | Adiar destaque comercial | Testar interesse usando itens conquistáveis e prévias, sem prometer demanda por personalização. |
| Clube mensal | Não priorizar no lançamento | Hoje exige produção recorrente para entregar um valor que ainda não foi validado. Preservar compromissos de eventuais compradores existentes. |
| Passe de temporada pago | Não adicionar agora | Acrescentaria outra camada comercial antes de validar o ciclo de partidas. |
| Patrocínio | Oportunidade posterior | Depende de audiência, contrato e entrega; não entra na receita-base atual. |
| Caixas aleatórias pagas | Não adotar | Desnecessárias para este jogo e incompatíveis com uma abordagem simples e adequada a menores. |

Há precedentes relevantes, mas não uma validação automática do Cineus: o suporte oficial de **Trivia Crack** documenta tickets obtidos no jogo e na loja e usados para obter ajudas. **Wordscapes** documenta remoção de anúncios comuns mantendo vídeos voluntários por moedas/dicas. Eles sustentam a escolha dos mecanismos, não uma taxa de conversão para nosso aplicativo. [Trivia Crack: tickets](https://triviacrack.help.etermax.com/hc/en-us/articles/4411825736595-How-can-I-get-tickets), [Trivia Crack: ajudas](https://triviacrack.help.etermax.com/hc/en-us/articles/52615645243283-How-can-I-get-Power-Ups), [Wordscapes: remoção de anúncios](https://peoplefun.helpshift.com/hc/en/6-wordscapes/faq/320-how-can-i-remove-ads/).

### Quem esperamos que compre

O posicionamento inicial é para adultos fãs de cinema e cultura geek que jogam com frequência. Não há pesquisa que permita afirmar que 18–34, 35+ ou outra faixa compre mais no Cineus. Esses recortes podem orientar pesquisa com adultos, sem prometer resultado.

Para quem deseja continuar, testar tickets; para quem prefere conforto, testar remoção de anúncios comuns. Conduzir pesquisa de preço e testes de oferta com adultos. Acompanhar compras verificadas, uso posterior do benefício, retorno e reembolsos. Downloads, faixa etária e intenção declarada não substituem uma compra entregue.

Jogadores de 16/17 anos podem participar da proposta gratuita, com salvaguardas adequadas. **A estratégia não deve depender de converter menores em pagantes.** Planejar acesso às compras por adulto/responsável, com fluxo apropriado, e não confundir uma barreira de compra com prova de consentimento para todos os tratamentos de dados.

### Os motivos de conversão que fazem sentido

| Vontade do jogador | Resposta proposta | Resultado a observar |
| --- | --- | --- |
| Quero mais uma partida | Vídeo por tickets ou compra, sem perder a partida já iniciada | Retomada após a oferta e retorno em dias seguintes |
| Estou travado, mas quero resolver | Ajuda contextual com troca e efeito na pontuação claros | Menos abandono, sem sensação de resultado comprado |
| Quero jogar com menos interrupção | Compra única de remoção de anúncios comuns | Uso após comprar, satisfação e receita líquida |
| Quero mostrar que entendo de cinema | Títulos/conquistas e cartão que reflitam progresso real | Equipamento e compartilhamento voluntário |
| Quero descobrir a próxima mostra | Conteúdo temático com uma prévia concreta | Partidas iniciadas e concluídas, não só abertura da vitrine |

Não usar urgência falsa, culpa por perder sequência, botões de recusa escondidos ou dificuldade alterada para fabricar necessidade de compra. A regra do AdMob exige escolha afirmativa, descrição da recompensa e entrega; recusar não deve prejudicar o uso normal. [Política de anúncios recompensados](https://support.google.com/admob/answer/7313578?hl=pt-BR).

### A economia vem antes de cortar tickets

O principal desequilíbrio encontrado não é simplesmente conceder dez tickets por dia: **o bônus padrão pode repor integralmente dez entradas de um estágio**. Isso é uma inferência contábil do código, não uma medição de comportamento. Gastos com ajudas, tentativas e outras situações mudam o saldo individual.

Plano de teste:

1. Manter uma única moeda e o acesso gratuito aos diários. Não reduzir saldo comprado, bônus já recebido ou benefício prometido.
2. Medir por modo: tickets disponíveis, entradas, ajudas, bônus, gasto líquido e momento de saldo insuficiente.
3. Avaliar a variante existente de bônus 4 em **novos contratos de estágio**, comparada ao controle 10. Começar a avaliação comercial com adultos; não desenhar o teste para pressionar menores a comprar ou assistir. Preservar os contratos antigos e informar os benefícios reais. Nada foi ativado nesta rodada.
4. Só depois avaliar a cota diária. Cortá-la junto com bônus, preço e frequência de vídeo impediria saber a causa do resultado.
5. Em Cores, avaliar minutos e rodadas por ticket: uma partida tem cinco rodadas. Não multiplicar o custo por cinco apenas para igualar a aparência dos números.
6. Rever o limite compartilhado de três vídeos somente após observar demanda e frustração. Esse limite é uma decisão do Cineus, não um teto universal imposto pelo AdMob.

Na vitrine, preservar os pacotes existentes de 20/60 como hipótese inicial. Preços precisam ser definidos depois do equilíbrio e retornados pelas lojas; não há evidência para dizer que R$ 4,90, R$ 9,90 ou qualquer outro valor seja o melhor hoje.

O preço de remoção deve considerar a receita futura de anúncios comuns perdida naquela coorte, custos e comissão aplicável. Não presumir que o comprador de remoção deixa de assistir a todos os vídeos opcionais, nem contar essa receita duas vezes.

## 4. Problemas jurídicos e alternativas

| Área | Avaliação preliminar | Alternativa ou evidência necessária |
| --- | --- | --- |
| Personagens conhecidos em Cores | Prioridade alta: núcleo visual depende de identidades de terceiros | Licença específica ou migração aprovada para personagens autorais; verificar arte e personagem separadamente |
| Pôsteres dentro do app e nos cartões exportados | Prioridade alta: uso principal de imagens e distribuição de cópias | Cobertura para exibição, armazenamento, adaptações e compartilhamento, ou catálogo autorizado substituto |
| Dados/imagens TMDB | Prioridade alta antes de monetizar | Acordo comercial compatível e verificação da cobertura dos direitos subjacentes |
| Uso de celebridades em novas artes/produtos | Risco separado de copyright | Não usar rosto, voz, nome ou representação reconhecível como atrativo comercial sem análise de imagem/nome e autorizações cabíveis |
| Artes originais geradas | Procedência registrada, mas inventário ainda pendente | Rever termos da ferramenta, referências, semelhanças e documentação de criação; não prometer exclusividade automática |
| Títulos de filmes e marca Cineus | Situações diferentes | Referências factuais/editoriais sem sugerir endosso; busca de marca Cineus e nomes dos produtos antes de investir em divulgação |
| Cópia de perguntas/curadoria de outro jogo | Auditoria editorial necessária | Produzir redação e seleção próprias; manter fontes dos fatos e referências de pesquisa independentes |

**TMDB:** a documentação distingue uso comercial de uso não comercial e pede contato para licença comercial. Também declara que o serviço não reivindica a propriedade das imagens/dados. Assim, atribuição e chave de desenvolvedor não bastam, e não devemos presumir que um acordo de API resolva todos os direitos dos pôsteres. Confirmar o escopo por escrito. [FAQ oficial do TMDB](https://developer.themoviedb.org/docs/faq).

**Referências públicas:** a fonte registrada para Pernalonga aponta a um arquivo da Wikipédia identificado como conteúdo não livre, com justificativa ligada ao contexto enciclopédico daquela página. Isso não é licença comercial para o Cineus. O mesmo cuidado deve ser aplicado individualmente às demais fontes. [Licenciamento do arquivo Bugs Bunny.svg](https://en.wikipedia.org/wiki/File:Bugs_Bunny.svg).

**Astros e marcas:** nome/imagem de uma pessoa e associação comercial são questões adicionais, mesmo que a arte seja nova. Não tratar uma caricatura reconhecível como automaticamente autorizada. A marca Cineus também precisa de busca de disponibilidade, sem concluir que esteja livre apenas porque o domínio ou um perfil está disponível. [Código Civil, arts. 18–20](https://www.planalto.gov.br/ccivil_03/leis/2002/l10406compilada.htm), [Lei de Propriedade Industrial](https://www.planalto.gov.br/ccivil_03/leis/l9279.htm).

### Como preservar o valor do jogo com menor dependência de licenças

- **Dicas:** manter o conceito de quiz, com textos autorais sobre fatos verificados e revisão da origem dos metadados. Isso reduz exposição visual, mas não resolve automaticamente contratos de fontes ou usos de marcas.
- **Pôsteres:** começar por parceiros independentes com autorização documentada; avaliar obras em domínio público **por território e por versão da arte**. Não presumir que um filme antigo ou um arquivo disponível na internet esteja liberado.
- **Cores:** testar memória visual com personagens próprios ou personagens de autores parceiros. Manter a proposta de memória cultural só com conteúdo cuja utilização esteja fundamentada.
- **Coleção e loja:** usar universo autoral do Cineus. Uma arte original sobre fantasia ou exploração espacial é uma direção mais sustentável que vender versões renomeadas de personagens famosos.

Um pôster gerado que reproduza composição, traje, símbolo e aparência de um filme continua merecendo revisão; IA e desfoque não devem ser usados como mecanismo de contornar direitos.

Licenças a negociar devem cobrir, conforme o material: titularidade, imagens/personagens, Brasil e demais territórios pretendidos, Android/iOS, prazo, anúncios e compras, alterações de cor/desfoque, armazenamento offline, cartões exportados e peças de divulgação. Definir retirada/substituição e o destino de compras existentes. Não basta uma permissão genérica para postar a imagem.

### Outras pendências antes de publicar

**Público e proteção de menores.** A decisão agora é jogo 16+ e público comprador 18+. Jogadores de 16/17 anos continuam sendo menores. O ECA Digital já está em vigor em 2026; seus requisitos de proteção e restrições ao perfilamento publicitário de menores continuam relevantes. A idade pretendida não substitui classificação real, controles proporcionais e análise de acesso provável. [ECA Digital](https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/lei/l15211.htm), [orientações da ANPD](https://www.gov.br/anpd/pt-br/assuntos/eca-digital).

| Público | Tratamento proposto |
| --- | --- |
| Adultos 18+ | Público comprador prioritário; tickets e remoção de anúncios com valor e preço claros |
| Adolescentes 16/17 | Experiência gratuita adequada, proteção de dados e publicidade sem perfilamento comercial; compras mediadas por adulto/responsável conforme o fluxo aprovado |
| Idade desconhecida | Não presumir maioridade para liberar anúncios ou ofertas; definir tratamento conservador antes de inicializar SDKs |
| Crianças menores de 13 | Fora do público pretendido; avaliar atração/acesso provável e medidas aplicáveis, sem presumir que uma etiqueta resolva a questão |

A escolha de 16+ deve ser coerente com conteúdo, artes e divulgação. Ela não obriga automaticamente a categoria Kids da Apple nem prova enquadramento fora das políticas infantis do Google Play. Caso crianças façam parte do público efetivo/da proposta, reavaliar as regras pertinentes. Uma tela simples de idade não prova, por si só, cumprimento da legislação brasileira. [Google Play: declaração de público](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en), [Apple: diretrizes de revisão](https://developer.apple.com/app-store/review/guidelines/).

Planejar curadoria dos 500 pôsteres e das perguntas também por adequação etária, inclusive nos diários, arquivo, resultados e links de convite. Não foi realizada nesta rodada uma classificação título a título do catálogo. Se houver conteúdo 18+, sua apresentação a jogadores de 16/17 exige tratamento apropriado ou exclusão daquele acervo. O alvo comercial adulto não libera automaticamente todo o catálogo para adolescentes.

**Privacidade.** Identificadores técnicos, IP, recibos e eventos de anúncios podem envolver dados pessoais mesmo sem nome ou login. Rever bases legais por finalidade, operadores, retenção, exclusão, segurança e declarações das lojas. Anúncio não personalizado não significa ausência de tratamento de dados. O tratamento de dados de menores deve considerar seu melhor interesse. [LGPD](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm).

**Compras e atendimento.** Explicar quantidade, validade, restauração e limitações de tickets; organizar atendimento privado para dados e compras. Não depender de uma issue pública no GitHub para tratar recibos ou credenciais. Rever reembolsos e termos conforme o CDC e os procedimentos das lojas. A chave opcional de recuperação é um ponto de atenção: precisamos de uma recuperação confiável do saldo comprado após reinstalação, sem obrigar cadastro para simplesmente jogar. [Código de Defesa do Consumidor](https://www.planalto.gov.br/ccivil_03/leis/l8078compilado.htm).

**Publicação.** Google Play pode exigir prova dos direitos, e alterações de imagens não evitam sua política de propriedade intelectual. A Apple também exige cobertura de conteúdo/serviços de terceiros, compras digitais pelo mecanismo aplicável e valor contínuo para assinaturas. As telas de desenvolvimento com placeholders e ofertas indisponíveis devem ser revisadas antes da submissão pública. [Propriedade intelectual no Google Play](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en), [App Review Guidelines: 2.1, 3.1 e 5.2](https://developer.apple.com/app-store/review/guidelines/).

## 5. Resultado esperado e como verificar

O resultado esperado é **uma oferta mais simples e ligada ao jogo**, menos produção decorativa recorrente e menor risco de perda do catálogo. Crescimento de receita é uma hipótese que ainda precisa de dados; não há evidência de que o Cineus já desperte as conversões necessárias.

| Mudança planejada | Hipótese | Critério de avaliação |
| --- | --- | --- |
| Revisar o bônus de novos estágios | Tickets extras passam a ter utilidade sem tirar o início gratuito | Gasto líquido, continuidade, retorno D1/D7 e reclamações |
| Ajuda com vídeo no contexto | Jogador supera um bloqueio sem abandonar | Aceitação, entrega, uso da ajuda e continuação |
| Simplificar a loja | Menos escolhas irrelevantes facilitam entender o que comprar | Oferta vista → compra verificada → benefício usado |
| Elenco/mostras ligados às partidas | Identidade e descoberta aumentam o valor do conteúdo | Conclusões, equipamentos e compartilhamentos voluntários |
| Retirar dependências sem licença | Menor risco de remoção e retrabalho | Evidência de direitos para todo conteúdo publicado |

Usar os eventos existentes (`tickets_insufficient`, `rewarded_requested`, `reward_credit_delivered`, `game_completed`, `ad_shown`, `ad_value`, `purchase_verified`) como base. Planejar eventos mínimos de oferta vista, escolha/recusa, motivo da ajuda e consumo de tickets por modo, com minimização de dados e consentimento quando aplicável. Não confundir callback, placeholder ou clique com impressão paga ou venda concluída.

Com poucos usuários, fazer primeiro entrevistas e sessões de jogo; exemplos de testes qualitativos com 10–20 pessoas ajudam a detectar problemas, não a estimar conversão populacional. Experimentar uma mudança por vez, registrar incerteza e não declarar vitória estatística a partir de duas vendas. Interromper uma mudança se quebrar entrega, aumentar reclamações ou prejudicar continuidade sem benefício demonstrável.

### Uma conta para dimensionar a expectativa com anúncios

Valores abaixo são **hipóteses aritméticas de sensibilidade**, não benchmarks do Brasil nem previsão para o Cineus. Impressões são válidas e efetivamente servidas, já considerando quem não vê anúncios. Médias abrangem todos os usuários ativos, não só quem assiste.

| Cenário hipotético | Vídeos por usuário ativo/dia × eCPM | Nativos por usuário ativo/dia × eCPM | Receita em 30 dias com 100 ativos/dia | Com 1.000 ativos/dia |
| --- | --- | --- | ---: | ---: |
| Menor exposição/valor | 0,2 × R$ 8 | 0,5 × R$ 1 | R$ 6,30 | R$ 63,00 |
| Referência matemática | 0,6 × R$ 20 | 1 × R$ 3 | R$ 45,00 | R$ 450,00 |
| Maior exposição/valor | 1 × R$ 35 | 2 × R$ 6 | R$ 141,00 | R$ 1.410,00 |

Fórmula: `30 × ativos_diários × (vídeos_por_ativo × eCPM_vídeo + nativos_por_ativo × eCPM_nativo) / 1000`.

São valores de receita publicitária hipotética antes de despesas e tributos. Não incluem vendas, intersticiais, banners, licenças, backend ou custo do trabalho. Separar Android/iOS nos dados reais e conciliar valores estimados com o painel da rede. Para vendas, apurar preço efetivo menos comissão aplicável, reembolsos, tributos e custos. Mais produtos não substituem retenção, audiência e uma margem viável.

Com o público comprador 18+ definido, não aplicar a todos os jogadores uma taxa hipotética de compra de adultos. Separar compradores adultos elegíveis, usuários que apenas jogam e disponibilidade publicitária, sem criar perfis comerciais de menores. A tabela não demonstra viabilidade do segmento escolhido.

## 6. Sequência de sprints proposta, aguardando decisão

| Sprint | Entrega concreta | Condição para considerar concluída |
| --- | --- | --- |
| 1 — Escopo e direitos | Público de jogo 16+/comprador 18+, adequação etária, matriz por asset/fonte, decisão entre licenciar/substituir, busca inicial de marca e revisão jurídica dirigida | Tratamento de menores e idade desconhecida definido; cada grupo tem rota documentada; não se marca como licenciado sem evidência |
| 2 — Piloto criativo | Dez personagens autorais, três regiões cada, estilo geek/cinema, uma mostra e protótipo de memória | Dez desenhos distintos por estágio; sem associação evidente não revisada; teste de clareza/diversão antes da expansão |
| 3 — Economia | Simulação dos ganhos/gastos e desenho de teste 10 versus 4 de bônus em novos estágios | Preserva saldos e contratos existentes; nenhuma mudança simultânea de cota, preço e dificuldade |
| 4 — Oferta comercial | Oferta para compradores adultos; tratamento de adolescentes e idade desconhecida; fluxos de vídeo/tickets/remoção; vitrine reduzida; Plus independente de intersticial quando houver anúncios cobertos | Preço real, troca compreensível, acesso de adulto/responsável às compras, recuperação do saldo e entrega idempotente comprovadas |
| 5 — Validação e publicação | Testes genuínos Android/iOS, consentimento/público, compra/reembolso/restauração, anúncios e medição | Direitos documentados, informações jurídicas atuais, placeholders revisados e resultados observados registrados |

Na sprint 1, licenças podem depender de terceiros e não têm prazo ou preço garantidos. Se um acordo não for viável, seguir a rota de substituição aprovada. Só expandir o elenco a cinquenta depois de validar o piloto. Só reconsiderar Clube/coleções pagas quando houver uso recorrente e interesse verificável.

## 7. Alteração executada nesta rodada

Foi removida a tag “Retomar grátis” do componente comum às três categorias. Ticket e progresso dividem a largura disponível, com altura igual e adaptação a fonte ampliada. O botão equivalente de Cores passou a dizer “Continuar”. A retomada continua sem nova cobrança.

Validação: 23 testes relacionados passaram, mais um teste de navegação/captura das três categorias. [Prints atualizados](C:/Projects/Cineus/docs/preview/two-stage-tags-2026-10-21/GALERIA.html).

Não foram alterados catálogo, artes, produtos comerciais, preços, bônus, frequência de anúncios, regras de pontuação ou configurações de público como consequência deste planejamento. Nenhum contato com titulares/lojas foi enviado e nenhum APK foi gerado.

Atualização posterior de público: apenas este documento foi revisado para registrar jogo 16+ e público comprador 18+, conforme as respostas do usuário. Não foram aplicadas novas mudanças no aplicativo.
