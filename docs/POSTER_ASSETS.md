# Cineus — Pôsteres locais

## Runtime

Os pôsteres do jogo são distribuídos como assets locais em `assets/posters/`.
O runtime não precisa consultar TMDB, IMDb ou outra CDN para exibir um pôster.

Isso preserva:

- funcionamento offline;
- carregamento previsível;
- ausência de API key no cliente;
- ausência de rate limit/CDN como dependência de gameplay.

## Pipeline recomendado

1. obter a imagem a partir de uma fonte cuja licença/autorização permita o uso;
2. registrar a proveniência e a evidência correspondente;
3. padronizar dimensão/proporção;
4. remover metadados desnecessários;
5. comprimir o asset;
6. salvar usando o ID estável do filme;
7. executar `scripts/validate_catalog.py`;
8. incrementar `AppConstants.contentVersion` quando o catálogo distribuído mudar.

## Direitos

Armazenar a imagem localmente não concede direito de distribuição.

Antes de uma release comercial, mantenha para cada conjunto de assets uma
evidência rastreável de origem/licença/autorização. Não preencha o registro com
suposições.

O arquivo `poster-rights.template.csv` documenta os campos mínimos sugeridos.
