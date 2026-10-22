# Monetização do Cineus

Estado de 15/10/2026: sprints 1–12 implementadas no código e conteúdo inicial preparado. A ativação comercial externa continua pendente. Lojas, backend publicado, anúncios genuínos e iOS em aparelho não foram declarados operacionais por testes locais.

O gameplay continua gratuito. Desde 16/10/2026, a renovação é de 10 tickets diários; saldo já concedido no mesmo dia e extras são preservados. Início de estágio e dicas extras custam 1 ticket. Vídeo opcional concede 2 tickets após confirmação assinada, até três recompensas por dia UTC. Cosméticos e compras não alteram as regras de pontuação.

Precisa de ajuda? reúne as opções durante as partidas. É possível gastar 1 ticket ou escolher um vídeo que financia a ajuda e deixa 1 ticket extra. O fluxo usa o mesmo recibo de +2 já verificado, seguido da compra normal da ajuda por 1; não há crédito adicional pelo callback do SDK. Há no máximo um vídeo de ajuda por partida, compartilhando os três vídeos diários com a carteira. Sem configuração, o botão de vídeo permanece Em breve e não concede nada.

Filmes/Pôsteres oferecem diretor, ano e duração quando esses dados existem; ajudas já compradas continuam visíveis. Em Cores, a dica simples gratuita continua disponível e a nova orientação sugere uma família de tons e um ajuste, sem valores exatos ou comparação contínua. Ambas as ajudas de Cores preservam a penalidade de 1 ponto na rodada. A ampliação da imagem continua gratuita.

Um registro local durável vincula o vídeo à partida e à opção original. Cancelamento não cobra nem libera ajuda. SSV atrasado recupera a recompensa sem outro vídeo. Se a partida/pergunta mudou ou a ajuda já foi usada, os 2 tickets ficam no saldo; não se aplica ajuda à próxima pergunta. Falha ao salvar a ajuda estorna seu débito. Saldo, recibo e consumo não dependem de um widget permanecer aberto.

## Produto e interface

Minha coleção contém cinco itens iniciais gratuitos. Estreia, Noite e Cidade têm seis itens cada; Plus tem moldura e aparência próprias; missões têm três recompensas; Aurora demonstrativo tem uma moldura. Total: 29 artes, com origem GPT Image registrada em docs/artwork/collection.json.

Ver cartão → Personalizar reutiliza o mesmo renderizador da imagem compartilhada. Prévia de item não possuído não concede nem equipa. Sua jornada reúne três missões semanais e descoberta sem revelar respostas. Temporadas apresenta coleções compatíveis e o evento gratuito claramente identificado como demonstração. Não há nova aba inferior.

## Compras e direitos

NativeCommercialStore usa in_app_purchase no Android/StoreKit 2 e preço localizado da loja. Associa a compra à identidade comercial, verifica no servidor e só então conclui a transação nativa. Pendente, cancelamento, falha e restauração têm estados próprios. Produtos indisponíveis não recebem preço fictício.

Coleções e Plus são compras únicas. Clube é mensal renovável: remove interrupções enquanto válido e entrega a coleção do ciclo verificado. Cosméticos de ciclos válidos permanecem após expiração. Reembolso revoga sua origem, preservando outras origens e Plus independente. O cache temporário do Clube é limitado a 24 horas após a verificação e à validade da loja.

O acesso comercial usa identidade técnica em armazenamento seguro e chave opcional de recuperação. Não é conta de progresso. Restauração em reinstalação/aparelho novo depende da mesma conta da loja e dessa identidade/chave; não há promessa de transferência automática Android↔iOS.

## Anúncios

Google Mobile Ads com UMP, solicitações não personalizadas e configuração explícita de público/ambiente. Nenhum SDK é inicializado pela build sem configuração válida. Crédito depende do backend/SSV, não do boolean do SDK.

Revisão de UX em 15/10/2026: anúncios são a prioridade de monetização. O Início e as Configurações têm acesso a Ganhar tickets; o saldo mostra o espaço de vídeo recompensado, inclusive antes da ativação. Há espaços reservados para publicidade no Início e nas três categorias. São placeholders identificados, sem carregamento de anúncios, impressões simuladas ou recompensa por tocar no espaço. Recompensados configurados preservam a oferta quando não há vídeo, permitem nova tentativa e mostram o limite diário.

Pacotes de 10/30 tickets e Plus têm espaços visuais com estado Em breve. Os pacotes ainda não são produtos de cobrança: a interface não inventa preço nem inicia compra. Se o Plus estiver disponível e validado pela loja, o painel comercial existente assume o lugar do placeholder.

Revisão adicional dos fluxos: falta de tickets no resultado abre o saldo; voltar ao app ou atravessar a virada UTC atualiza os tickets preservando extras. Respostas concorrentes do SDK de anúncios são serializadas, com nova leitura quando a disponibilidade muda durante um carregamento.

Falha ou carregamento da loja não aparece como Em breve. Checkout aguarda a verificação dos direitos; restauração termina com retorno explícito, inclusive quando não há compra ativa. Fechar a tela durante uma operação não tenta atualizar widgets descartados. Plus/Clube ativo mostra vantagens adquiridas e suprime os espaços de publicidade comum, mantendo vídeos opcionais. A apresentação acompanha a expiração de benefícios, mesmo com a resposta da loja em cache.

Minha coleção prioriza itens em uso/adquiridos e permite filtrar Meus itens. Item bloqueado informa sua origem e oferece um caminho para missões, Temporadas ou Plus. Cosméticos conservados de um ciclo do Clube são reconhecidos como adquiridos, sem oferecer a mesma coleção completa novamente. Uma temporada encerrada não é apresentada como futura.

Temporadas separa coleções atuais, futuras e anteriores adquiridas, com contagem real de itens. A prévia permite combinar avatar, moldura e cartão sem conceder ou equipar. Foram removidos o placar demonstrativo 10/10 e o cartão de largura total com altura excessiva. Estados de carregamento/erro dos eventos têm retorno visível; atualizar ou retomar a tela recarrega o progresso. Texto do evento demonstrativo foi corrigido na revisão 2 do catálogo.

Intersticial: somente resultado de estágio, fora das primeiras três sessões, ao menos quatro conclusões, dez minutos, máximo dois por dia UTC e grupo sem exposição. Oportunidade após dez segundos sem interação; qualquer toque/navegação/background cancela. Direito desconhecido ou verificação indisponível suprime anúncio. Plus/Clube válido removem interrupções e permitem ocultar ofertas opcionais.

Plus só aparece quando a remoção corresponde a um benefício disponível; intersticiais exigem aprovação explícita e permanecem desligados por padrão. Testes locais não demonstram efeito positivo em retenção.

## Conteúdo, Clube e eventos

Manifesto compatível versionado/assinado, hashes, download parcial retomável, ativação atômica e rollback por nova revisão. Falha mantém a versão funcional. Produtos/itens desconhecidos exigem app compatível; conteúdo não executa código remoto.

Outubro e novembro têm coleções completas prontas. Nova oferta do Clube exige ciclo atual e seguinte, plano mensal correto e aprovação explícita. Dezembro não foi prometido nem produzido. A ausência de conteúdo de um ciclo é auditada, sem fingir entrega.

Aurora é evento de demonstração, sem patrocinador contratado. Meta conta partidas depois da adesão e dentro do período; resgate atômico e único preserva progresso. O relatório inicial é agregado por aparelho e distingue adesão, conclusão e resgate, sem analytics populacional fictício.

## Configuração, relatórios e ativação

Todas as flags comerciais são falsas por padrão. URL HTTPS/pin, mapeamento de produtos, credenciais exclusivas do servidor, IDs nativos e condições de cada recurso são exigidos. Configuração por si só não comprova licença, contrato, público ou teste genuíno.

- [Operação e configuração completas](../backend/OPERACAO-COMERCIAL.md)
- [Backend e protocolo](../backend/README.md)
- [Entrega e matriz de validação](business/CICLO-MONETIZACAO-ENTREGA-2026-10-15.md)
- [Rentabilidade do produto e hipóteses](business/RENTABILIDADE-PRODUTO-2026-10-15.md)
- [Calendário editorial](business/CALENDARIO-COLECOES-2026-10-15.md)
- [Patrocínio demonstrativo](business/PATROCINIO-DEMONSTRACAO-2026-10-15.md)

O CLI do backend agrupa ordens verificadas, ciclos, estados e líquido conhecido por moeda/plataforma/produto. Diagnóstico opcional local inclui eventos limitados e estimativas publicitárias, até 2.000 registros/60 dias, sem upload automático. Não representa DAU/MAU, extrato bancário ou lucro. O Pass legado fica apenas por compatibilidade; não é oferecido como Plus/Clube.
