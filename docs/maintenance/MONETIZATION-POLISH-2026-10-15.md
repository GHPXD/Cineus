# Revisão de monetização antes da ativação

Escopo: corrigir estados e navegação da experiência existente, mantendo publicidade e pacotes como placeholders conforme solicitado. Nenhum SDK de anúncio foi ativado, produto real comprado ou APK instalado nesta revisão.

## Correções

- Resultado sem tickets: Próximo abre o saldo, preservando o resultado e sem cobrança.
- Saldo atualiza ao abrir, retomar o aplicativo ou atravessar a virada UTC; extras permanecem.
- Carregamento e erro comercial têm estados próprios e nova tentativa. Erro não vira Em breve.
- Checkout aguarda direitos verificados e não tenta atualizar tela fechada durante a operação.
- Restaurar compras conclui com confirmação, ausência de compra ativa ou erro; verificação nativa pendente continua indicada como pendente.
- Plus/Clube ativo substitui a oferta por vantagens adquiridas. Publicidade comum é suprimida; vídeos com recompensa continuam opcionais.
- Expiração dos benefícios invalida a apresentação local na data limite, sem depender de uma nova resposta da loja. A validação de pagamento permanece no servidor.
- Ofertas de coleções completas já possuídas por ciclos do Clube não permitem compra duplicada.
- Coleção mostra primeiro itens equipados/adquiridos, filtro Meus itens e origem correta dos bloqueados. Como conseguir abre o caminho correspondente sem conceder ou equipar a prévia.
- Loja foi movida para depois dos itens da coleção. Prévia de temporada encerrada deixa de prometer Em breve; período se atualiza ao retomar a tela.
- Atualizações simultâneas da disponibilidade de vídeo são agrupadas e relidas, preservando a última notificação do SDK.

## Verificação

Testes de widgets e serviços cobrem expiração, revogação, falha de verificação, nova tentativa, restauração, compra interrompida por fechamento da tela, ausência de saldo, virada UTC, navegação de bloqueados, prévia sem concessão e disponibilidade concorrente de anúncios. A regressão inclui categorias, resultados, coleção, Temporadas, anúncios, preços verificados, localização e layouts a 320 px/200% em PT/EN/ES.

Galeria: `docs/preview/monetization-ux/GALERIA.html`. As imagens vêm dos widgets reais do Flutter a 390 × 844, exportados a 2x. As capturas Plus ativo e falha da loja usam respostas controladas de teste, identificadas na galeria. Não são capturas do celular nem prova de transação real.

## Pendências externas preservadas

Os IDs do AdMob ainda não foram fornecidos. A ativação requer configuração válida, backend/SSV e validação de anúncio/recompensa no ambiente de teste antes de produção. Pacotes de 10/30 tickets continuam apenas visuais: produtos consumíveis, crédito verificado no servidor e validação pelas lojas serão necessários para vendê-los. Plus/Clube/coleções usam o adaptador comercial existente e também dependem dos produtos e serviços externos configurados. Não foi declarado faturamento operacional.
