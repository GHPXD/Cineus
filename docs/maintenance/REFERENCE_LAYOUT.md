# Layout de Cores, tipografia e estatísticas — 14/10/2026

- Luni era ilustrativo: a implementação reutiliza personagens do catálogo, sem adicionar o mascote gerado.
- Fredoka 600: títulos; Fredoka 700: nomes e ações. Nunito 400–600: descrições, controles e números. Fontes locais, sem download na execução; licenças oficiais em assets/licenses, proveniência e hashes em docs/artwork/fonts.json.
- FeaturedStageCard é compartilhado por Dicas, Pôster e Cores: mesmos espaçamentos, altura, tratamento da arte, cores, fonte, progresso e ação. A altura do texto de progresso reserva o maior texto localizado dos três modos para manter igualdade com fonte ampliada.
- Removidos do hub de Cores o aviso dos diários e os atalhos de estatísticas/histórico pedidos. Retomada de treinos antigos e créditos continuam acessíveis.
- Tutorial de Cores em tela cheia: três etapas, indicador visual, exemplo ajustável, comparação pontuada e demonstração de desbloqueio. Nenhuma atividade de exemplo altera tickets ou partidas reais.
- Jogo e tutorial usam ColorStudio: imagem em canvas marfim, nome integrado, painel de controles inteiro, seletor Tom/Intensidade/Brilho, ajustes exatos, setas e slider. Interface mantém salvamento, confirmação e pontuação originais.
- Estatísticas: seletores de modo, cartões com ícones, indicadores reais, gráficos de pontos e rodadas, resultados recentes e conquistas. Separação de escopos diários/estágios permanece explícita. Navegação de Cores para Dicas/Pôster seleciona o modo solicitado.

## Validação

- Suíte completa: 687 testes aprovados, incluindo igualdade dos cards, navegação, economia, persistência e acessibilidade em PT/EN/ES.
- Flutter analyze: nenhum problema.
- Verificadores: 153 arquivos Dart alcançáveis; 1.035 assets/origens registrados; 102 ícones, 5 ilustrações, marca nativa e 50 personagens/90 regiões/140 SVGs validados.
- Renderização interna com fontes reais em docs/preview (ignorada pelo Git). Nenhum APK novo foi compilado nesta correção.
- Logs em docs/maintenance/layout-reference-*.log. Os testes específicos e a renderização foram repetidos após o acabamento final.
