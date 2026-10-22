# Cineus — sprints de implementação da monetização aprovada

**Planejamento de 14/10/2026 · Android e iOS · Brasil**

Escopo aprovado: [relatório de monetização do produto](MONETIZACAO-PRODUTO-2026-10-14.md). Este plano inclui coleção, compras, anúncios dentro do jogo, progressão, Plus, temporadas, Clube e eventos patrocinados. A aprovação abrange o planejamento dessas funcionalidades; contas, publicação, contratos e ativação de cobranças precisam estar efetivamente configurados para operar.

**Ordem de implementação: sprints 1 a 12.** Cada sprint entrega uma parte utilizável e verificada, com dependências explícitas. Aquisição paga de usuários permanece fora deste ciclo. Não há datas prometidas: acesso às lojas, ambiente iOS, licenças e respostas externas afetam a conclusão operacional.

**Andamento em 15/10/2026:** implementações das sprints 1 a 12 e conteúdo inicial preparados. [Fechamento e validação das sprints 5–12](CICLO-MONETIZACAO-ENTREGA-2026-10-15.md), com entregas individuais e condições externas. Ainda sem deploy, compra genuína, AdMob ativo ou validação iPhone; testes controlados não significam produção comercial.

## Visão geral

| Sprint | Entrega principal | Depende de | Resultado concreto |
|---|---|---|---|
| 1 | Fundação comercial, economia e medição | Estado atual | Contratos de dados, regras e configuração consistentes |
| 2 | Perfil leve e Minha coleção | 1 | Inventário gratuito, seleção e persistência |
| 3 | Assets pagos e cartão personalizado | 2 | Prévia real, Coleção Estreia e exportação com aparência equipada |
| 4 | Backend de direitos e concessões | 1 e catálogo da 3 | Validação, registro e recuperação de benefícios confiáveis |
| 5 | Compras Android e iOS | 3–4 | Coleção Estreia comprável e restaurável nas duas lojas |
| 6 | Vídeos recompensados | 1 e 4 | Anúncio opcional com +2 tickets, limite e crédito único |
| 7 | Missões, descoberta e novos módulos | 2 e medição da 1 | Progresso visual e conteúdo para sustentar retorno |
| 8 | Intersticiais moderados e Plus | 5–6 | Frequência centralizada e compra permanente que remove interrupções |
| 9 | Temporadas e entrega de coleções | 3–5 e 7 | Coleções adicionais publicáveis e preservadas após compra |
| 10 | Cineus Clube | 8–9 | Assinatura completa com entrega recorrente e cancelamento correto |
| 11 | Eventos patrocinados | 7 e 9 | Estrutura de evento com identificação de patrocínio e conteúdo autorizado |
| 12 | Fechamento, suporte e rentabilidade | 1–11 | Experiência integrada, validação final e operação documentada |

As dependências de catálogo/contratos permitem desenvolver partes independentes, mas a ordem acima é o caminho de acompanhamento. Uma integração não é considerada comercialmente concluída apenas por funcionar com serviços simulados.

## Sprint 1 — Fundação comercial, economia e medição

**Objetivo:** preparar a base compartilhada para evitar regras de anúncio, compra e inventário duplicadas.

Entregas:

- Auditar a economia e registrar entradas/saídas de tickets, reinício diário, bônus e limites existentes. Preservar os 20 tickets gratuitos e as regras já publicadas.
- Separar tipos de produto e direito: coleção permanente, Plus permanente e Clube por período. Substituir a ambiguidade do Pass único no desenho da integração.
- Definir IDs estáveis de produtos, coleções, itens, concessões e eventos. Preço visível vem da loja quando integrada; referências de R$ 14,90/19,90/9,90 não são confirmação de produto cadastrado.
- Criar configuração por ambiente e controles para habilitar cada oferta/placement de forma independente. Configuração indisponível mantém gameplay funcionando.
- Instrumentar eventos mínimos de partida, retorno, saldo, prévia, compra e recompensa, com adaptação para medição real e sem dados pessoais desnecessários.
- Levantar o acesso necessário a contas das lojas, rede de anúncios, backend e macOS/iPhone. Registrar situação de público e direitos do catálogo; manter condições comerciais externas visíveis.
- Definir métricas, retenção de dados e relatório operacional simples. Não exigir uma conta do jogo para jogar a primeira partida.

**Aceite:** partidas e progressos existentes preservados; contratos de integração definidos; eventos demonstráveis; configuração de teste isolada; pendências externas registradas com a etapa que afetam. Nenhuma oferta de compra fictícia aparece como disponível.

## Sprint 2 — Perfil leve e Minha coleção

**Objetivo:** dar utilidade visível à personalização antes de vender itens.

Entregas:

- Perfil leve com avatar e nome de exibição opcionais, inicialmente locais; avatar/nome podem ser ocultados no cartão. Sem confundir isso com conta ou sincronização entre dispositivos.
- Minha coleção em Configurações, sem nova aba na navegação inferior.
- Catálogo de molduras, avatares e aparências de cartão. Separar estado possuído, disponível para prévia e equipado.
- Seleção gratuita inicial: **duas molduras, dois avatares e uma aparência básica de cartão**.
- Persistência local e migração que preserva usuários existentes. Equipar um item não o consome.
- Estados de carregamento, catálogo indisponível, inventário vazio e item revogado, com retorno a um visual gratuito quando necessário.

**Aceite:** o usuário seleciona e mantém a aparência ao reabrir o app; prévia de item não possuído não o libera; navegação, fontes e acessibilidade seguem o padrão atual.

## Sprint 3 — Coleção Estreia, assets e cartão personalizado

**Objetivo:** entregar o benefício comercial completo e sua prévia.

Entregas:

- Coleção Estreia com **três molduras, dois avatares e uma aparência de cartão**, diferentes dos gratuitos.
- Artes originais feitas com **GPT Image/ImageGen**, seguindo a direção visual aprovada. Converter para SVG quando adequado, com origem, prompt e arquivos finais registrados; não desenhar os ícones manualmente por código.
- Prévia da coleção sobre o resultado real do jogador, sem abrir pagamento automaticamente.
- Entrada Personalizar dentro de Ver cartão. Preservar a tela de resultados simplificada e as quatro categorias da barra inferior.
- Renderizador compartilhado entre prévia e imagem exportada para que o cartão compartilhado tenha a mesma aparência equipada.
- Legibilidade de pontuação, barra e marca nos três modos. Ornamentação não altera resultado nem concede conquistas de desempenho.

**Aceite:** prévia e arquivo compartilhado correspondem; nenhuma moldura corta conteúdo; itens gratuitos e pagos permanecem distinguíveis; oferta ainda não integrada não aceita compra nem inventa preço de loja.

## Sprint 4 — Backend de direitos, validação e concessões

**Objetivo:** sustentar compras e recompensas reais com recuperação após falhas.

Entregas:

- Backend e armazenamento para transações verificadas, origem das concessões, direitos ativos e reconciliação. Definir hospedagem e custo antes de contratar serviços.
- Validação com provedores das lojas, identificação única de transação e processamento idempotente.
- Recebimento autenticado de notificações dos provedores e proteção contra mensagens duplicadas, antigas ou inválidas.
- Regras de reembolso/revogação que consideram todas as origens do mesmo item: revogar uma origem não apaga um direito adquirido por outra origem válida.
- Registro de recompensas publicitárias e limite diário confiável, com recuperação de concessões confirmadas e ainda não aplicadas no dispositivo.
- Cache de direitos verificados para uso offline e comportamento definido durante falhas de atualização.
- Identidade mínima necessária à restauração e aos provedores, sem obrigar cadastro para gameplay. Não prometer restauração Android↔iOS sem mecanismo de conta e associação verificado.
- Segredos fora do cliente e do repositório, ambientes separados, logs operacionais, backups e procedimento de recuperação.

**Aceite:** transação repetida não duplica benefício; evento inválido não concede item; falha intermediária é recuperável; concessão e revogação podem ser auditadas. Deploy e validação externa permanecem identificados se o ambiente ainda não estiver disponível.

## Sprint 5 — Compras reais nas duas plataformas

**Objetivo:** concluir a primeira venda de ponta a ponta.

Entregas:

- Integração Flutter com compras Google Play e App Store, conectada ao backend da sprint 4.
- Cadastro/configuração da Coleção Estreia como produto não consumível em cada loja; preço inicial proposto de R$ 14,90, com apresentação localizada fornecida pela loja.
- Estados de compra iniciada, pendente, cancelada, concluída e falha. Liberar somente após validação.
- Restauração e reconciliação em reinstalação, retorno do app e troca de aparelho na plataforma correspondente.
- Concessão do pacote inteiro uma única vez e equipamento da aparência após confirmação, respeitando a escolha do jogador.
- Tratamento de reembolso/revogação, confirmação/conclusão das transações e acesso a suporte.
- Testes em sandbox e aparelhos Android/iOS; ofertas escondidas quando a loja não consegue oferecer o produto.

**Aceite:** comprar → validar → receber → equipar → compartilhar funciona. Cancelar não concede; pendência não libera prematuramente; restaurar não duplica; reembolso não danifica outros itens. Teste real no iOS exige ambiente Apple e não pode ser substituído apenas por teste Flutter no Windows.

## Sprint 6 — Vídeos recompensados

**Objetivo:** implementar a troca opcional já definida pela economia.

Entregas:

- SDK de anúncios nas duas plataformas, ambientes/IDs separados e configurações de público/privacidade aplicáveis.
- Carregamento antecipado e oferta no saldo ou quando faltarem tickets; não inserir chamadas permanentes em todas as telas.
- Troca explícita: **assistir e ganhar +2 tickets, até três recompensas por dia**.
- Crédito pela confirmação de recompensa, integrado ao registro da sprint 4; fechar o anúncio, sozinho, não concede nada.
- Recuperação após encerramento do app ou falha de rede, limite diário e proteção contra concessões duplicadas.
- Métricas de disponibilidade, escolha, exibição, recompensa confirmada e crédito entregue.

**Aceite:** jogador pode recusar; anúncio indisponível não bloqueia jogo; recompensa válida é concedida uma vez; repetição do callback não aumenta saldo novamente. O ambiente de testes não produz receita nem tráfego de anúncio de produção.

## Sprint 7 — Missões, descoberta e continuidade de conteúdo

**Objetivo:** sustentar frequência e dar valor à coleção sem criar pressão de compra.

Entregas:

- Três missões semanais simples, com progresso derivado de partidas reais, sem exigir anúncio ou compra.
- Recompensas visuais gratuitas e originais, com concessão única por missão/período; não substituir medalhas de desempenho por itens pagos.
- Coleção descoberta dos personagens já encontrados, mantendo silhuetas para conteúdo ainda bloqueado e evitando prévias que revelem respostas.
- Primeiro lote de continuidade: **dois módulos adicionais de Cores, com dez desenhos distintos por módulo**. Reaproveitar personagens em módulos diferentes somente com perguntas/regiões adequadas; nenhum desenho repetido no mesmo módulo.
- Novos IDs e publicação do conteúdo sem reordenar perguntas que fazem parte de partidas já salvas. Validar regiões, referências e comparação de cor.
- Lembretes voluntários de conteúdo real, reaproveitando preferências existentes; sem notificação comercial insistente.

**Aceite:** objetivos não duplicam recompensa, partidas anteriores continuam válidas, prévias não entregam cores e nenhuma ausência pune o jogador. Conteúdo novo tem origem/direitos e curadoria registrados.

## Sprint 8 — Intersticiais moderados e Cineus Plus

**Objetivo:** construir e avaliar uma fonte complementar sem deteriorar as sessões.

Entregas:

- Controlador central de elegibilidade. Limites iniciais: fora das três primeiras sessões, tutorial e diários; ao menos quatro partidas de estágio concluídas entre exibições; intervalo mínimo de dez minutos entre anúncios de tela cheia; máximo de dois intersticiais por dia.
- Encaixe em pausa natural após o resultado, sem disparo por Jogar, Próximo, compartilhar, voltar ao início ou sair. Se não houver encaixe adequado ou anúncio pronto, não exibir.
- Grupo sem intersticiais para avaliar o efeito sobre retorno e abandono, com tamanho de amostra e incerteza informados.
- **Cineus Plus permanente**, referência de R$ 19,90, produto não consumível integrado ao fluxo da sprint 5.
- Uma moldura e uma aparência originais próprias do Plus, distintas da Coleção Estreia.
- Remoção central das interrupções e preferência para ocultar ofertas de vídeos opcionais. Direito ainda sendo verificado não deve causar exposição indevida a intersticial.
- Textos precisos sobre compra única e benefícios; preservar todos os direitos permanentes comprados.

**Aceite:** frequência respeitada em navegação e reinício; comprador Plus não vê interrupções; compra/restauração/revogação funcionam. A venda de remoção só fica disponível quando o benefício existir. Com impacto ruim ou amostra insuficiente, manter o placement desativado e registrar a decisão; implementação não exige exposição prejudicial em produção.

## Sprint 9 — Temporadas e entrega de coleções

**Objetivo:** permitir novos lançamentos sem reconstruir a loja a cada coleção.

Entregas:

- Estrutura de temporada com ID, período de apresentação, catálogo, produtos e manifesto versionado de assets/conteúdo.
- Uma primeira coleção adicional completa, nos moldes da Estreia: três molduras, dois avatares e uma aparência originais, com preço de teste dentro da faixa aprovada de R$ 9,90–14,90.
- Produtos e concessões separados por coleção; prévia, compra, restauração e equipamento reaproveitam as sprints anteriores.
- Publicação controlada, compatibilidade com versões do app, retomada de download, verificação de integridade e rollback. Não introduzir execução remota de código para entregar conteúdo.
- Itens comprados permanecem após a temporada; distinguir fim de apresentação de revogação de posse.
- Calendário editorial com custo e responsável. Preparar duas coleções mensais para validar a cadência antes da ativação do Clube, reutilizando a estrutura e evitando revender item duplicado.

**Aceite:** nova coleção é adicionada por configuração/conteúdo compatível; falha de atualização mantém a versão funcional; inventário anterior não é apagado; a descrição corresponde exatamente aos itens concedidos.

## Sprint 10 — Cineus Clube, assinatura

**Objetivo:** implementar receita recorrente com entrega recorrente concreta.

Entregas:

- Assinatura mensal, referência inicial de R$ 9,90/mês; preço e condições reais apresentados pela loja.
- Benefícios: coleção original mensal definida, personalização adicional e remoção de interrupções durante a vigência. Não alterar direitos do Plus permanente.
- Máquina de estados para compra, renovação, cancelamento, validade, problemas de cobrança, períodos reconhecidos pela loja, expiração, restauração e reembolso.
- Concessão da coleção correspondente a cada ciclo válido, com chave única para não duplicar itens em restaurações ou notificações repetidas.
- Cancelamento interrompe futuras renovações; benefícios seguem o período validado. Ao expirar, cessam os benefícios temporários, preservando cosméticos já concedidos por ciclos válidos. Reembolsos obedecem às origens de direito registradas.
- Acesso à gestão da assinatura, explicação curta da renovação e suporte. Não promover Plus e Clube como se fossem o mesmo contrato.
- Validação de dois ciclos de entrega em teste, catálogo e custo editorial preparados antes da oferta pública. Não considerar esse teste prova de demanda paga real.

**Aceite:** renovação válida entrega uma vez; cancelamento, expiração e restauração produzem direitos corretos; Plus permanece funcional; nenhum usuário perde seus itens permanentes por não assinar. Sem conteúdo/cadência ou configuração das lojas, a ativação fica pendente de forma explícita.

## Sprint 11 — Eventos patrocinados

**Objetivo:** deixar o produto apto a receber patrocínio com escopo claro.

Entregas:

- Modelo de evento com identificação do patrocinador, período, conteúdo autorizado, regras, objetivos e recompensa visual definida.
- Identificação discreta e clara de patrocínio, seguindo o layout do app e sem transformar marca em resposta ou vantagem de pontuação.
- Ferramenta operacional inicial por configuração validada, sem exigir um painel administrativo completo para lançar o primeiro evento.
- Material de apresentação comercial: entregáveis, superfícies, período, métricas agregadas e itens a orçar. Não inventar audiência ou resultados.
- Demonstração com identidade original/de teste; ativação de marca real apenas com contrato, assets autorizados e configuração correspondente.
- Relatório de participação, conclusão, entrega da recompensa e identificação do evento, sem venda de dados de jogadores.

**Aceite:** evento demonstrável do início ao fim, desligamento ao final correto e progresso preservado. Capacidade técnica entregue não significa patrocinador contratado nem receita obtida. Prospecção, envio de mensagens e assinatura de contrato não fazem parte da execução automática destas sprints.

## Sprint 12 — Fechamento, suporte e rentabilidade

**Objetivo:** fechar a integração inteira e explicitar o estado comercial real.

Entregas:

- QA Android/iOS de compras, renovação, anúncios, inventário, missões, temporadas e eventos; falhas de rede, reinício, reinstalação, migração e notificações duplicadas.
- Revisão visual das telas comerciais, acessibilidade, desempenho, tamanho de assets e consistência das fontes. Tutoriais atualizados para explicar apenas o que mudou, sem excesso de texto ou oferta disfarçada.
- Revisão de textos, preço localizado, restauração, contato de suporte, privacidade e informações exigidas nas lojas, conforme a configuração efetivamente usada.
- Guia operacional: publicar coleção, interromper anúncio/oferta, recuperar concessão, tratar compra, restaurar backup e acompanhar falha.
- Relatório de produto/receita por plataforma e fonte: vendas novas, assinaturas válidas, reembolsos, receita publicitária, entrega de benefícios e custo editorial/operacional.
- Atualizar o modelo de rentabilidade com dados disponíveis. Manter premissas identificadas onde não houver observação; não transformar receita de compra única em mensalidade.
- Registro final de cada recurso: implementado, testado localmente, validado externamente e ativado/desativado em produção, com pendências e motivo.

**Aceite:** todos os fluxos aprovados foram implementados e sua situação externa está comprovada. Integração sem credencial, teste iOS não realizado, licença pendente ou contrato ausente não recebe marca de operação concluída. Recursos sem condição de ativação permanecem ocultos/desativados, sem prejudicar as funcionalidades prontas.

## Regras de entrega para todas as sprints

1. Preservar partidas, catálogo, conquistas e dados existentes. Não cobrar retroativamente por acesso gratuito já incluído nem criar vantagem paga de pontuação.
2. Manter navegação e identidade atuais: Fredoka/Nunito, quatro categorias, cartões legíveis e pouca informação repetida.
3. Novas artes dedicadas passam por GPT Image/ImageGen e registro de origem; SVG quando útil vem da arte gerada. Assets de terceiros exigem origem e condições de uso adequadas.
4. Entregar a funcionalidade completa no seu escopo: interface, estado persistido, integração necessária, falhas e verificações proporcionais. Simulações servem ao desenvolvimento e ficam distinguidas de validações reais.
5. Ao terminar cada sprint, informar mudanças, verificações e pendências concretas. Sem gerar APK ou apresentação de antes/depois a cada etapa; capturas e pacote final seguem o momento solicitado pelo usuário.
6. Não contratar infraestrutura, ativar cobrança, publicar em lojas, contratar patrocínio ou gastar com campanhas apenas por este planejamento. Preparar a configuração e os resultados revisáveis; ações externas seguem o acesso e a autorização correspondentes.

## Critério de conclusão do ciclo completo

**Atualização de 15/10/2026:** as implementações e o conteúdo inicial das sprints 5–12 foram executados. A [entrega consolidada](CICLO-MONETIZACAO-ENTREGA-2026-10-15.md) registra testes, limitações e a matriz de ativação. Integrações comerciais externas continuam pendentes; não confundir conclusão de software com receita/produção ativa.

**Implementação completa:** as 12 sprints entregam produto, integrações, conteúdo inicial, operação e verificação correspondentes. Os modelos de receita são distinguíveis; benefício permanente, benefício por período e recompensa não se confundem.

**Operação completa:** lojas/backend configurados, direitos e público resolvidos, testes em aparelhos realizados e somente ofertas sustentadas por benefícios reais ativadas. O patrocínio pode estar tecnicamente pronto e continuar sem contrato; a assinatura pode estar implementada e aguardar o calendário de conteúdo. Essas condições são registradas como pendentes de operação, não omitidas do fechamento.

**Rentabilidade:** será avaliada pelo resultado observado depois de despesas e obrigações. Concluir o software não garante compradores, assinantes ou margem. A aquisição paga de usuários só volta ao planejamento após o fechamento deste ciclo e a revisão dessas condições.
