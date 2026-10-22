# Sprint 2 — Perfil leve e Minha coleção

Implementada em 14/10/2026. Escopo: [planejamento aprovado](SPRINTS-MONETIZACAO-2026-10-14.md#sprint-2--perfil-leve-e-minha-coleção).

## O que está disponível

**Configurações → Minha coleção** permite visualizar, escolher e aplicar os itens gratuitos. As quatro abas de navegação continuam as mesmas. A tela usa Fredoka/Nunito e a paleta dourada, azul e marfim do app.

- Dois avatares: Coruja projecionista e Raposa cinéfila.
- Duas molduras: Luz dourada e Filme azul.
- Uma aparência de cartão: Noite de cinema.
- Nome opcional de até 24 caracteres Unicode e controle para mostrar ou ocultar nome/avatar na prévia.

Na primeira abertura, o nome fica vazio e o avatar gratuito fica visível. Não é criada conta. Selecionar um item muda apenas a prévia; **Aplicar** confirma o equipamento. Trocar de categoria descarta a prévia ainda não aplicada. Equipar não gasta tickets nem consome o item.

Esta sprint entrega a prévia e as escolhas persistidas. A aplicação ao resultado real e ao arquivo compartilhado pertence à **Sprint 3**, junto com a Coleção Estreia. Não há catálogo pago fictício, botão de compra ou promessa de sincronização entre aparelhos.

## Persistência e recuperação

O SQLite separa perfil, origens de posse e equipamento. A migração lógica 4 → 5 acrescenta tabelas sem apagar partidas, saldo ou preferências. As cinco concessões iniciais são idempotentes. Fechar e reabrir o banco mantém o perfil e os itens aplicados.

Equipamento exige um ID conhecido e posse válida. A prévia não concede posse. Uma origem revogada não elimina outras origens válidas do mesmo item; um equipamento sem posse volta ao item gratuito da mesma categoria. Concessões desconhecidas são preservadas para compatibilidade, mas não se tornam itens equipáveis por isso. A posse local ainda não é prova de uma compra: a validação comercial vem nas sprints 4–5.

Carregamento inicial, erro com nova tentativa e falha de gravação são tratados. Uma falha mantém o último perfil confirmado e permite tentar novamente. Categorias sem itens têm estado vazio, e um item não possuído pode ser visualizado sem habilitar Aplicar. O catálogo inicial é empacotado e funciona offline.

O nome permanece local e não entra nos eventos. Os eventos `collection_opened`, `item_previewed` e `collection_item_equipped` usam somente IDs permitidos; o diagnóstico continua desativado por padrão. A política de privacidade em PT/EN/ES foi atualizada para o perfil e a coleção locais.

## Artes e origem

As **cinco artes foram geradas do zero pelo GPT Image**, pela ferramenta integrada `image_gen.imagegen`. Não houve desenho manual de SVG. Os avatares foram vetorizados com VTracer a partir das imagens geradas, com caminhos SVG reais; molduras e fundo mantêm PNG para preservar textura e transparência.

| Item | Arquivo usado no app | Conversão |
|---|---|---|
| Coruja | `assets/collection/avatar_owl.svg` | Imagem GPT → VTracer, 384 px/64 cores |
| Raposa | `assets/collection/avatar_fox.svg` | Imagem GPT → VTracer, 384 px/64 cores |
| Luz dourada | `assets/collection/frame_premiere.png` | Redução para até 640 × 800, alfa preservado |
| Filme azul | `assets/collection/frame_blue_reel.png` | Redução para até 640 × 800, alfa preservado |
| Noite de cinema | `assets/collection/appearance_noir.png` | Redução otimizada para uso no app |

O ID interno `frame_premiere_v1` identifica a moldura **gratuita** Luz dourada; não é o produto pago Coleção Estreia. Os itens comerciais da Sprint 3 terão IDs próprios.

[Manifesto das artes](../artwork/collection.json): prompts completos, ferramenta, caminhos dos arquivos originais gerados, cópias de origem, hashes e arquivos finais. As cópias imutáveis ficam em `assets/generated/sources/collection_*.png`; somente os arquivos de execução em `assets/collection/` entram no app, somando cerca de 1,55 MB. Preparação reproduzível em `scripts/prepare_collection_assets.py`; verificação de origem/transparência em `scripts/validate_collection_assets.py`, também ligada ao CI.

## Verificação

- 13 testes específicos passaram: persistência após fechar/reabrir SQLite, concessão sem duplicação, prévia sem equipamento, aplicação, edição/ocultação do perfil, migração, revogação, rejeição de item não possuído, rollback, catálogo indisponível e recuperação de falhas. São oito testes de interface e cinco de persistência/estado.
- Layout e editor verificados em 320 px com texto a 200% em PT/EN/ES, 390 px e 840 px; navegação real a partir de Configurações também testada.
- Análise estática sem problemas. Validadores de origem das artes, uso de arquivos e conformidade passaram.
- Suíte completa final: **715 testes passaram**, sem falhas, com os arquivos estabilizados. A primeira execução ampla foi descartada como resultado final porque compilou o repositório antes do último ajuste de recuperação e o teste novo depois dele; a repetição final usou a versão consolidada.
- Captura interna da tela conferida em `docs/preview/collection/sprint-02.png`. Sem apresentação de antes/depois ou APK, conforme solicitado.

Logs: `docs/maintenance/monetizacao-sprint-02-targeted.log`, `monetizacao-sprint-02-recovery.log`, `monetizacao-sprint-02-analyze.log` e `monetizacao-sprint-02-tests-final.log`. A execução de testes Flutter no Windows não substitui a futura verificação em aparelhos Android/iOS.

## Próxima etapa

**Sprint 3:** Coleção Estreia com artes próprias, personalização dentro de Ver cartão e renderização compartilhada entre prévia e exportação do resultado real.
