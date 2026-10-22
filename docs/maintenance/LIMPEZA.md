# Limpeza do projeto — 14/10/2026

Foram retiradas seis implementações antigas, dois arquivos de testes exclusivos
de protótipos, 52 scripts históricos e 126 mensagens de localização sem referência.
Os testes de progressão e retomada foram adaptados às telas atuais.

As famílias de arte desativadas, a prévia piloto e suas dependências foram removidas.
Os 50 personagens, 90 regiões de Cores, 500 filmes, pôsteres, referências e licenças
atuais foram preservados. Os registros de origem ficam em `docs/artwork` e as
referências visuais fornecidas pelo usuário em `docs/design`.

O histórico de sprints e capturas foi retirado após backup com hashes conferidos,
fora deste repositório. Os caminhos de recuperação ficam em `history-recovery.json`
e `recovery.json`. O APK existente mais recente está em `dist/Cineus.apk`, com hash
conferido; nenhum APK novo foi compilado nesta limpeza.

Foram apagados os caches locais de Flutter, testes, Gradle e Kotlin (7,27 GiB).
O SDK, o ambiente Python, o banco do catálogo e os dados do jogador não foram
apagados. Na próxima compilação, comece com `flutter pub get`.

Validação: 688 testes da suíte principal, dois testes de decodificação de SVGs,
análise sem avisos e verificadores de catálogo, direitos de release, hashes de
origem e cobertura de código/assets. Todos passaram. `scripts/validate_project_usage.py`
foi incorporado ao CI para detectar arquivos Dart órfãos e assets sem registro.

O resumo e as contagens estão em `cleanup-report.json`.
