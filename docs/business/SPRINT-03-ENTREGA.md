# Sprint 3 — Coleção Estreia e cartão personalizado

Implementada em 14/10/2026. Escopo: [planejamento aprovado](SPRINTS-MONETIZACAO-2026-10-14.md#sprint-3--coleção-estreia-assets-e-cartão-personalizado).

## Experiência entregue

**Ver cartão → Personalizar** abre Minha coleção usando o resultado real da partida como prévia, nos modos Dicas, Pôster e Cores. Equipar um item possuído atualiza o cartão ao voltar. O PNG compartilhado captura o mesmo componente exibido; não há um segundo layout de exportação.

Os cinco itens gratuitos permanecem disponíveis. A Coleção Estreia acrescenta **três molduras, dois avatares e uma aparência**, todos distintos dos gratuitos. Os itens são identificados por coleção e posse; tocar em uma arte bloqueada ou em **Experimentar coleção** altera somente a prévia. Aplicar permanece indisponível para itens não possuídos. Sair da prévia volta à aparência efetivamente equipada.

Nome e avatar entram na imagem apenas quando sua visibilidade está ativada no perfil. A preferência de ocultação é respeitada também pelo PNG. Palpites, códigos privados, respostas de Cores e nomes de personagens não são acrescentados. O pôster dos filmes continua presente conforme a configuração anterior do cartão.

As telas de resultado continuam simplificadas e a navegação inferior mantém as quatro abas. Não foi gerado APK ou uma apresentação de antes/depois.

## Coleção Estreia

As seis artes foram criadas do zero pelo **GPT Image**, com a ferramenta integrada `image_gen.imagegen`, em dourado, azul e marfim. Os dois avatares foram vetorizados com VTracer; os SVGs contêm caminhos reais provenientes das imagens, sem desenho manual por código. Molduras e fundo preservam os PNGs gerados, otimizados para execução.

| Tipo | Nome | ID estável | Arquivo no app |
|---|---|---|---|
| Avatar | Gato diretor | `premiere_avatar_cat_v1` | `assets/collection/premiere_avatar_cat.svg` |
| Avatar | Lebre cinegrafista | `premiere_avatar_hare_v1` | `assets/collection/premiere_avatar_hare.svg` |
| Moldura | Luzes da estreia | `premiere_frame_marquee_v1` | `assets/collection/premiere_frame_marquee.png` |
| Moldura | Cinema Art Déco | `premiere_frame_deco_v1` | `assets/collection/premiere_frame_deco.png` |
| Moldura | Sob os holofotes | `premiere_frame_spotlight_v1` | `assets/collection/premiere_frame_spotlight.png` |
| Aparência | Veludo da estreia | `premiere_appearance_velvet_v1` | `assets/collection/premiere_appearance_velvet.png` |

[Manifesto de origem](../artwork/collection.json): prompts completos, ferramenta, caminhos dos originais gerados, cópias imutáveis, hashes e transformações. Os novos originais ficam em `assets/generated/sources/collection_premiere_*.png`, fora do bundle. Os seis arquivos usados no app somam aproximadamente **1,75 MB**; o conjunto inteiro da coleção, incluindo os gratuitos, soma 3,30 MB.

O catálogo passou para a versão 2; os IDs gratuitos e o schema SQLite 5 foram preservados. As novas artes não são marcadas como `starter`, portanto usuários existentes e instalações novas continuam recebendo somente os cinco itens gratuitos. O produto interno `cineus.collection.premiere.v1` corresponde à coleção `premiere_v1`.

## Renderização, exportação e falhas

`CollectionCardSurface` é compartilhado pelas prévias e pelos cartões reais. A imagem da moldura usa recorte central expansível para preservar suas bordas em cartões altos; a área de conteúdo tem proteção inferior para evitar sobreposição do nome. O layout cresce com o texto em vez de reduzir o tamanho escolhido pelo usuário.

`PersonalizedSharePanel` atende às três modalidades. Antes de capturar o `RepaintBoundary`, `captureResultCard` aguarda as artes utilizadas e um frame pintado. O pôster reserva resolução de pelo menos 2× para a exportação, respeitando o limite do original. O arquivo exportado é PNG a 2×.

Compartilhamento repetido fica bloqueado durante a operação. Cancelamento não é tratado como sucesso nem copia texto automaticamente; falha permite nova tentativa. A navegação para Personalizar também evita aberturas duplicadas. Falha ao carregar o perfil mantém um visual gratuito sem identidade, permite tentar carregar novamente e não transforma estado local desconhecido em compra.

Prévia e item equipado são estados separados: overrides visuais existem apenas na tela da coleção; o compartilhamento resolve somente equipamento possuído ou uma alternativa gratuita. Prévia não grava concessões, não consome tickets e não altera os dados de pontuação. A abertura da prévia da coleção registra somente o ID permitido do produto no diagnóstico local opcional.

A privacidade em PT/EN/ES foi atualizada para explicar o conteúdo opcional das imagens compartilhadas. As cópias públicas em `docs/privacy.html` e `web/privacy.html` permanecem iguais.

## Estado comercial real

A Coleção Estreia está **disponível para prévia**, com vendas ainda não abertas. Não há botão de compra, preço inventado ou concessão paga no cliente. A associação dos seis itens ao catálogo prepara a integração; validação e concessões confiáveis pertencem à Sprint 4, e compras nas lojas à Sprint 5.

Os testes que precisam de uma aparência paga equipada inserem concessões em um SQLite isolado de teste. Isso não comprova compra, não modifica o banco do usuário e não oferece desbloqueio no app.

## Verificação

- 14 testes novos passaram: catálogo com seis itens pagos não concedidos, prévia temporária sobre resultado real, aplicação gratuita, fallback de equipamento inválido, privacidade, PNG idêntico à prévia nos três modos e nove combinações de moldura/modo em 320 px com texto a 200% em PT/EN/ES.
- Os 39 testes direcionados de coleção, resultado e integração de Cores passaram durante a implementação; a suíte completa final cobre novamente esses fluxos com os ajustes consolidados.
- Análise estática sem problemas. Validadores de origem de assets, transparência, uso de arquivos e conformidade passaram.
- Suíte completa final: **729 testes passaram**, sem falhas, com a versão consolidada.
- PNGs internos conferidos visualmente em `docs/preview/collection/sprint-03-mode-0.png`, `sprint-03-mode-1.png` e `sprint-03-mode-2.png`. As capturas mostram fixtures de teste, não compras reais.

Logs em `docs/maintenance/monetizacao-sprint-03-personalized.log`, `monetizacao-sprint-03-targeted.log`, `monetizacao-sprint-03-analyze.log` e `monetizacao-sprint-03-tests-final.log`. As verificações Flutter no Windows não substituem a futura validação em aparelhos Android e iOS.

Próxima etapa: **Sprint 4 — backend de direitos, validação e concessões**.
