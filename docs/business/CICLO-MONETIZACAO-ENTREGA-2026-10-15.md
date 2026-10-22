# Fechamento das sprints 5–12

Implementação local do ciclo autorizado, em 15/10/2026. Inclui app, backend, conteúdo, testes e operação. **Não houve publicação, contratação, gasto com mídia, cobrança real ou patrocínio.** Sem APK e sem apresentação de antes/depois, conforme pedido. Os recursos comerciais continuam ocultos/desligados por padrão.

## Entregas por sprint

| Sprint | Entrega implementada | Evidência local principal | Condição externa |
| --- | --- | --- | --- |
| 5 | Compras Google/StoreKit 2, preço localizado, pendente/cancelada/falha, validação antes da conclusão, restauração e recuperação | `native_commerce_test.dart`, protocolo assinado e testes do ledger | Cadastrar produtos, backend HTTPS e testes genuínos Android/iOS |
| 6 | Google Mobile Ads/UMP, oferta no saldo, +2 com SSV, limite 3/dia UTC, retomada e preferência de privacidade | Testes de crédito único/callback, cota e vínculo; manifesto Android mesclado | AdMob/consentimento/unidades/SSV público e aparelho |
| 7 | Três missões semanais, recompensas, descoberta sem spoiler, mais dois estágios de Cores | Jornada transacional; preservação das 90 perguntas/9 estágios; 110 regiões/11 estágios validados | Curadoria/licenças comerciais do catálogo preexistente |
| 8 | Política central de intersticial, holdout persistido, Plus permanente e dois visuais próprios | Sessões, quatro conclusões, dez minutos, teto diário, direitos e deduplicação | Evidência de retenção/exposição genuína; aprovação do placement |
| 9 | Duas coleções mensais, Temporadas, manifesto assinado, retomada, integridade, ativação atômica e rollback | Atualização interrompida/retomada, assinatura errada, versão incompatível, cache anterior; API autenticada/Range | Publicação de pacote e configuração real das ofertas |
| 10 | Clube mensal, estados de cobrança, cancelamento/graça/expiração, ciclos permanentes separados e gestão pela loja | Dois ciclos, refund de um ciclo, replay, histórico Apple, migração/backup e Plus preservado | Sandbox/testes genuínos das lojas, aparelho e cadência editorial |
| 11 | Evento por configuração, identidade original demonstrativa, meta e resgate atômicos, material comercial/relatório | Adesão, janela, fim do evento, conclusão distinta de resgate | Patrocinador/contrato/assets autorizados; nenhum contratado |
| 12 | Revisão de telas, tutorial/textos legais, relatórios por fonte/plataforma/moeda, guia e modelo financeiro | Análise estática, regressão, validadores e QA visual local | TestFlight/iPhone, ensaios reais e conciliação operacional |

## Conteúdo e experiência

**18 artes novas feitas com GPT Image**: três de missões, duas do Plus, seis Noite, seis Cidade e uma do evento. São 29 itens no catálogo incluindo os anteriores. Avatares vetorizados derivam da imagem gerada; molduras/aparências usam PNG com centro transparente quando aplicável. Prompts, arquivos imutáveis e hashes estão em [collection.json](../artwork/collection.json). Nenhuma geometria de ícone foi desenhada manualmente para substituir esse processo.

Cores mantém os 50 personagens, acrescentando vinte regiões extraídas das origens existentes e referência independente para respostas. São 160 camadas SVG, 110 regiões e 11 estágios. Na revisão visual, máscaras/tonalidades que atingiam região vizinha foram corrigidas antes do fechamento. As nove fases/90 perguntas originais permanecem iguais às fixtures preservadas; partidas salvas continuam com catálogo fixado.

Missões e Temporadas entram por Configurações; a navegação inferior mantém quatro categorias. Resultado/compartilhamento continuam no fluxo atual. Tutorial explica missão e personalização em seção expansível. Telas novas seguem Fredoka/Nunito, com textos PT/EN/ES. Capturas locais de QA ficam em `docs/preview/commerce/`, sem apresentação ao usuário nesta etapa.

## Segurança e continuidade

O backend usa verificação autoritativa dos provedores e snapshots Ed25519; provas/eventos/ciclos sensíveis são cifrados. Campos de produto, titular, ambiente, período e tipo são conferidos; repetição, concorrência, evento inválido e falha intermediária não concedem duas vezes. Reembolso de uma origem não remove outra origem válida.

Compras nativas inacabadas ficam disponíveis para redelivery/retentativa. Compra/restauração pendente também suprime intersticial, inclusive se o estado mudar durante a reserva da oportunidade. Identidade comercial pode ser recuperada com chave guardada privadamente; progresso continua local e independente. Não há promessa de restauração silenciosa sem essa identidade nem de compra cruzada Google/Apple.

SDK de anúncio não altera saldo sozinho. Apenas confirmação assinada vincula nonce/identidade/recibo. Recibo, movimento e crédito local são atômicos antes do ACK. Intersticial consulta direitos atualizados e é suprimido em falha, evitando interrupção indevida a quem pagou. Reserva conservadora e grupo sem exposição persistem.

Entrega de conteúdo é declarativa e compatível com IDs conhecidos: sem código remoto ou caminho/URL arbitrário. Download verifica assinatura, ambiente, audiência, idade da resposta, tamanho, SHA-256, formato e dimensões antes de ativar. Atualização parcial não apaga inventário ou a versão funcional.

## Verificação e limites

- Backend: **57 testes aprovados**, incluindo API/assinaturas, conteúdo autenticado com Range, dois ciclos, expiração, reembolso por ciclo, histórico Apple, backup, migração 1→2 e relatórios sem dados identificáveis.
- Flutter: **767 testes passaram** na regressão completa, em aproximadamente 1 min 50 s. Depois da proteção final de compra/restauração pendente, dez verificações dirigidas de compra/jornada/intersticial e decodificação foram reexecutadas e passaram. O decoder conferiu as 160 camadas com dimensões correspondentes às bases.
- Análise estática: **sem problemas**. Validação de 50 sprites/110 regiões/160 SVGs, 29 origens GPT Image, transparência, uso dos arquivos e documentos de release passou.
- QA visual local: telas a 320 px/200% em PT/EN/ES; vinte regiões novas renderizadas com escolha de contraste para conferir o recorte. As nove molduras novas também são exercitadas nos três cartões reais de resultado.
- Android: `:app:processDebugMainManifest` passou. Billing presente; inicializador automático de anúncios e permissões AD_ID/AdServices ausentes. Só houve configuração/mesclagem de manifestos; não foi gerado APK. Gradle ainda emite depreciações de plugins existentes, sem falhar a tarefa.
- iOS: código/Info.plist/xcconfig preparados; **nenhuma compilação Xcode, TestFlight ou validação iPhone foi executada neste Windows**. Testes controlados não substituem recibo genuíno, renovação da loja, consentimento ou anúncio de produção.

Logs locais: `docs/maintenance/monetizacao-cycle-*.log`. O backend tem um aviso de depreciação do cliente de teste Starlette/httpx; os testes passaram, sem alterar dependências fora do escopo para ocultar esse aviso.

## Matriz de operação real

| Recurso | Implementado/testado localmente | Validado externamente | Ativo em produção |
| --- | --- | --- | --- |
| Coleções, missão, descoberta, novos estágios e evento demo | Sim | Revisão em aparelho/uso comercial do catálogo pendente | Arquivos locais; sem publicação |
| Compra/restore Google | Sim, provedores controlados | Não | Não |
| Compra/restore Apple/Clube iOS | Sim, contratos e fixtures | Não; exige macOS/iPhone/loja | Não |
| Backend/callbacks/worker/backup | Sim | HTTPS/credenciais/provas genuínas pendentes | Não |
| Vídeo recompensado/SSV | Sim | AdMob/UMP/dispositivo pendentes | Não |
| Intersticial/Plus | Sim | Retenção/placement/dispositivo pendentes | Não |
| Temporadas/download assinado | Sim | Pacote publicado e rede real pendentes | Não |
| Clube e ciclos | Sim; dois ciclos controlados | Loja/cadência real pendentes | Não |
| Patrocínio | Sim, demonstração original | Sem contrato e sem cliente | Não |
| Receita/margem | Relatórios e hipóteses preparados | Receita paga e custos não observados | Nenhuma receita comprovada nesta execução |

O calendário outubro/novembro está preparado; dezembro não foi produzido. Novas ofertas do Clube bloqueiam sem mês atual e seguinte, mas ocultar uma oferta não elimina obrigações com assinantes existentes. O catálogo anterior usa personagens/imagens de terceiros cuja condição de publicação comercial precisa ser resolvida; gerar uma nova representação não comprova licença desses personagens.

A operação precisa ainda de um canal privado de suporte para provas/chaves; o issue público atual serve à triagem. Não publicar segredos em chamado. Nenhum contato foi enviado nesta tarefa.

## Documentos de operação e resultado

- [Operação, configuração e recuperação](../../backend/OPERACAO-COMERCIAL.md)
- [Rentabilidade do produto](RENTABILIDADE-PRODUTO-2026-10-15.md) e [modelo reproduzível](PROJECAO-MONETIZACAO-2026-10-15.json)
- [Calendário editorial e custo](CALENDARIO-COLECOES-2026-10-15.md)
- [Evento demonstrativo e proposta comercial](PATROCINIO-DEMONSTRACAO-2026-10-15.md)

As sprints de software não comprovam operação comercial nem lucro. As limitações acima ficam registradas como pendências externas; não foram substituídas por simulações apresentadas como resultados reais.
