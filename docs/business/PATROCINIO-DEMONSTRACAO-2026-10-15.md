# Sessão especial — proposta comercial e demonstração

O app implementa um evento gratuito por configuração, com período, patrocinador identificado, meta, participação voluntária e recompensa visual. **Aurora é uma identidade original de demonstração do Cineus. Não é cliente, contrato nem receita.** A moldura Primeira luz foi gerada com GPT Image e registrada no catálogo.

Na demonstração: participar em Temporadas, concluir três partidas após a adesão e dentro do período, resgatar a moldura uma vez. Progresso e resgate persistem. Encerrar o período impede novas adesões; uma meta concluída durante o evento ainda pode ser resgatada. Não altera cor correta, pontuação, ordem dos estágios ou tickets.

## Oferta que pode ser apresentada depois

Uma sessão temática por período combinado, com crédito discreto na tela do evento, uma arte original de recompensa e relatório agregado de participação, metas concluídas e recompensas entregues. A marca não vira resposta de uma pergunta. As superfícies ficam limitadas à sessão especial e à recompensa aceita pelo jogador; sem introduzir pop-up ou tela comercial no primeiro acesso.

O orçamento deve separar criação/licenciamento das artes, revisão, configuração, QA, suporte, relatório e eventual exclusividade. Não definir CPM, valor fechado ou alcance garantido sem audiência e custos observados. O app não possui patrocinador contratado e não há estimativa de vendas incluída na rentabilidade.

## Configuração e curadoria

`assets/commerce/catalog_v1.json` contém `events`: ID estável, `from`/`until` UTC, `sponsor` nos três idiomas, `demo`, `authorized`, `target` e `reward`. A publicação aceita somente recompensa conhecida pelo catálogo compatível. `authorized: true` é a confirmação editorial do operador, **não substitui contrato/licença**. Evento real exige documentação externa, revisão e uma nova revisão assinada do manifesto. Remover a apresentação não deve apagar os registros anteriores.

## Relatório inicial

`scripts/report_local_monetization.py --database COPIA.sqlite` agrega adesão e resgate por ID. É uma amostra de um aparelho, não uma contagem populacional. O progresso vem de partidas persistidas; não depende de telemetria opcional. Para uma entrega comercial real, consolidar somente exportações autorizadas com metodologia de deduplicação/consentimento definida. Não prometer painel ou analytics de população que ainda não existe. Nenhum nome, palpite, comprovante, contato ou identificador de jogador integra o relatório destinado ao patrocinador.

Modelo de entrega: evento/período; método e cobertura da medição; participantes observados; conclusões; resgates; falhas tratadas; limitações. Hoje todos os resultados comerciais são **não observados**. Nenhuma prospecção, mensagem ou assinatura foi realizada nesta tarefa.
