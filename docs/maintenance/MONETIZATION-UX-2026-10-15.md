# Revisão de monetização e Temporadas

Prioridade solicitada: receita por anúncios, com tickets e vantagens opcionais.
O usuário ainda não configurou o AdMob e pediu apenas boxes/placeholders. O
celular foi desconectado durante esta etapa; não houve nova instalação nem
compilação de APK. As capturas finais são renderizações das telas de produção
do Flutter com dados locais de teste, não imagens conceituais.

## Entrega

- Acesso Ganhar tickets no Início e nas Configurações; saldo reorganizado com
  vídeo recompensado em destaque e detalhes recolhidos.
- Placeholder de publicidade no Início e no mesmo ponto das três categorias.
- Espaços de pacotes de 10/30 tickets e Cineus Plus. Sem preços inventados,
  checkout ou concessões de teste. Plus usa o painel comercial existente se a
  oferta real da loja estiver disponível.
- Vídeo configurado mantém o card em falta de inventário, com retentativa,
  limite diário e feedback de recompensa não confirmada. A opção não fica
  acionável durante o carregamento. A configuração ausente mostra Em breve.
- Falta de tickets em Cores abre o saldo, como nos demais modos.
- Temporadas tem cards limitados ao conteúdo, datas, coleção atual/próxima e
  contagem real de itens. A prévia combina avatar, moldura e cartão sem adquirir
  ou equipar. Foram removidos o falso placar 10/10 e a prévia de largura total
  que criava um cartão excessivamente alto.
- Eventos têm carregamento, erro/retentativa e progresso atualizado ao retomar.
  Coleções anteriores adquiridas permanecem acessíveis. O catálogo comercial
  passou à revisão 2 com a acentuação do evento corrigida.
- Assets existentes de GPT Image e Fredoka/Nunito foram reutilizados. A seta
  padrão que aparecia como quadrado sem glifo foi substituída pelo asset do app.

## Evidências

Regressão dirigida em 14 arquivos: **119 testes aprovados**. Depois do último
ajuste de lint e da ampliação da checagem da prévia, os sete testes de experiência
foram reexecutados e passaram. Análise estática final: **sem problemas**.
Validação de alcance dos 196 arquivos Dart/1.134 arquivos de assets e compliance
de release passou. Layout de tickets, temporadas e prévia verificado em 320 px,
fonte a 200%, nos três idiomas. Os testes cobrem ausência de configuração,
inventário indisponível, retentativa, saldo preservado em vídeo incompleto e
prévia sem conceder/equipar cosméticos.

Galeria: `docs/preview/monetization-ux/GALERIA.html`, com oito prints.
Logs locais: `commerce-ux-regression.log`, `commerce-ux-captures-final.log` e
`commerce-ux-analyze-final.log`, ignorados pelo Git.

Anúncios reais, impressões, compras e receita não foram ativados nem validados
nesta etapa. Os pacotes de tickets são apenas interface; exigirão cadastro de
produtos e implementação/verificação do crédito antes de abrir o checkout.
Não houve mudança no saldo diário de 20 tickets ou no limite de três vídeos.
