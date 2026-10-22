# Prévias, estatísticas unificadas e conquistas — 14/10/2026

## Entrega

- Todos os componentes das prévias de personagens, inclusive a arte base, recebem filtro em preto e branco. Quando bloqueadas, as prévias recebem uma cor única e os nomes da partida são substituídos por “Personagens misteriosos”. O jogo e os resultados mantêm suas artes e referências reais.
- Removida a implementação `lib/presentation/screens/color_stats_screen.dart`. A rota antiga redireciona para `/stats?mode=colors`, na mesma `StatsScreen` de Dicas/Poster, sem abrir outro layout de navegação.
- Resumo e Conquistas são comuns aos três modos. Cores agrega partidas concluídas, conserva escala de 0–10 e não inventa vitórias ou taxa de acerto.
- O título Cores usa `GoldHeading`, compartilhado com Filmes e Posters.
- Dois fundos genéricos novos nos cards de partidas de filmes e pôsteres, sem revelar o filme.
- Seis novas conquistas elevam o catálogo a 13. Nenhum desbloqueio depende de pagamento ou estado inventado; o progresso é derivado dos resultados salvos e estágios realmente completos.

## Assets criados

Todos foram gerados pelo **ImageGen integrado / GPT Image**. Os seis emblemas foram convertidos em paths SVG pelo conversor VTracer existente, incluindo versão de contraste. Nenhuma geometria de ícone foi desenhada manualmente.

| Asset | Arquivo final | Registro com prompt, origem e hashes |
|---|---|---|
| Fundo Dicas/Filmes | `assets/match_cards/clue_match.png` | `docs/artwork/match-cards.json` |
| Fundo Poster | `assets/match_cards/poster_match.png` | `docs/artwork/match-cards.json` |
| Primeiro enquadramento | `assets/generated/icons/badgePosterFirst.svg` | `docs/artwork/interface/records/badgePosterFirst.json` |
| Olho clínico | `assets/generated/icons/badgePosterPerfect.svg` | `docs/artwork/interface/records/badgePosterPerfect.json` |
| Primeira pincelada | `assets/generated/icons/badgeColorsFirst.svg` | `docs/artwork/interface/records/badgeColorsFirst.json` |
| Ateliê de memórias | `assets/generated/icons/badgeColors25.svg` | `docs/artwork/interface/records/badgeColors25.json` |
| Memória cromática | `assets/generated/icons/badgeColorsExcellent.svg` | `docs/artwork/interface/records/badgeColorsExcellent.json` |
| Galeria em expansão | `assets/generated/icons/badgeColorsStages3.svg` | `docs/artwork/interface/records/badgeColorsStages3.json` |

Originais imutáveis dos emblemas em `assets/generated/sources/`, com os mesmos IDs. Registro completo de interface em `docs/artwork/interface/MANIFEST.json`. Os prompts finais e o caminho do arquivo gerado constam nos registros acima.

## Validações

Suíte completa final: **690 testes aprovados**. Análise Flutter sem problemas. Captura real e decodificação de SVGs: **2 testes aprovados**.

- Teste de pixels de personagem real: nenhum canal de cor vaza na prévia disponível; pixels opacos da silhueta usam uma cor única.
- Teste de contagem e limiares das novas conquistas, incluindo partidas ainda ativas e médias abaixo de 9.
- Troca de categoria por query da rota validada, além da troca pelos seletores.
- Verificação de média agregada de Cores, legibilidade em PT/EN/ES, persistência e economia.
- Validador de assets: 108 ícones, cinco ilustrações e marca nativa; 223 SVGs de interface; 50 personagens e 140 SVGs de arte preservados.
- Renderização interna da tela real com fontes locais em `docs/preview`, sem gerar APK. Logs de análise, suíte e captura em `docs/maintenance/privacy-stats-*.log`.

## Relatório de negócio

`docs/business/RENTABILIDADE-2026-10-14.md` contém auditoria comercial do código, três cenários, custos ainda não cotados, aquisição, retenção, condições de licenciamento e plano de sprints. Os cálculos são reproduzíveis por `docs/business/modelo_rentabilidade.py` e geram JSON/CSV.
