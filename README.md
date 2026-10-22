# Cineus

Aplicativo Flutter de memória e adivinhação, com catálogo local de 500 filmes,
5.000 dicas e 50 personagens com 90 regiões de cor. Android, iOS e Web.

## Modos atuais

| Modo | Partida | Pontuação |
|---|---|---|
| Dicas | Até dez dicas progressivas | 10 a 1; derrota vale zero |
| Pôster | Até cinco níveis de desfoque | 5 a 1; derrota vale zero |
| Cores | Cinco personagens por partida; ajustar, confirmar e comparar | Notas de 0 a 10 e média final |

Os diários gratuitos ficam no Início e mudam à meia-noite UTC. As abas Filmes,
Pôsteres e Cores mostram estágios com progresso separado. Cada estágio de Cores
reúne dez personagens diferentes em duas partidas de cinco. Iniciar ou refazer
uma partida de estágio custa um ticket; retomar é grátis. Convites de filmes são
gratuitos. Concluir o diário de Cores rende dois tickets uma vez por data.

As partidas e os resultados ficam neste dispositivo. A limpeza do repositório
não altera o banco do jogador. O tutorial geral e o de Cores têm exemplos
interativos que não gastam tickets nem criam partidas reais.

A interface usa Fredoka 600 para títulos, Fredoka 700 para nomes e ações, e
Nunito 400–600 para descrições, controles e números. As fontes são locais; as
licenças oficiais estão em `assets/licenses` e os hashes em `docs/artwork/fonts.json`.

As estatísticas de Dicas, Poster e Cores usam a mesma tela, com Resumo e
Conquistas. Há 13 conquistas derivadas dos resultados; as de Cores usam médias
reais de 0 a 10, sem convertê-las em taxa de vitória. As prévias de personagens
dos estágios são em preto e branco; partidas bloqueadas usam silhuetas.

O estudo de monetização está em `docs/business/RENTABILIDADE-2026-10-14.md`,
com premissas reproduzíveis em `modelo_rentabilidade.py`. Receitas ali são
cenários hipotéticos; anúncios, compras e telemetria continuam desativados.

## Executar e validar

Use a versão registrada em `.flutter-version` e Java 17 para Android.

```sh
flutter pub get
flutter run
flutter analyze --fatal-infos
flutter test
python scripts/validate_catalog.py
python scripts/validate_release_compliance.py
python scripts/validate_gpt_assets.py
python scripts/validate_project_usage.py
flutter test scripts/gpt_svg_decode_test.dart --no-pub
flutter test scripts/color_art_decode_test.dart --no-pub
```

Ao editar as traduções, execute `flutter gen-l10n`. PT-BR é o idioma de produção:
a interface EN/ES continua testada, mas as dicas de filmes ainda estão em português.
Para conferir essas interfaces, use
`--dart-define=CINEUS_ENABLE_INTERFACE_ONLY_LOCALES=true`.

## APK de testes no PowerShell

```powershell
cd C:\Projects\Cineus
$env:CINEUS_ALLOW_DEBUG_SIGNED_RELEASE = "true"
flutter pub get
flutter build apk --release --build-name=1.0.0 --build-number=13
python scripts/verify_android_startup.py build/app/outputs/flutter-apk/app-release.apk
```

O arquivo sai em `build/app/outputs/flutter-apk/app-release.apk`. Aumente o número
para cada atualização. Esse comando usa a assinatura de desenvolvimento dos APKs
de testes; para publicação, configure `android/key.properties` a partir do exemplo
versionado e mantenha a chave fora do repositório.

A verificação do APK confere os construtores usados na abertura do Android,
incluindo o banco interno do WorkManager. Mantenha `android/app/proguard-rules.pro`
no build de release: a dependência Room antiga precisa dessa regra com R8.

`dist/Cineus.apk` conserva o binário mais recente existente antes da limpeza;
o código atual deve ser compilado para gerar uma nova entrega.

## Organização

| Pasta | Conteúdo |
|---|---|
| `lib/core` | Tema, constantes e utilidades |
| `lib/domain` | Regras e entidades |
| `lib/data` | SQLite, migrações e repositórios |
| `lib/presentation` | Telas, navegação, estado e widgets |
| `lib/l10n` | ARBs e código gerado de localização |
| `assets` | Catálogos, imagens, fontes e originais das artes |
| `test` | Testes de regras, persistência e interface |
| `scripts` | Validações, ferramentas de dados, conversão e captura atual |
| `docs/artwork` | Prompts, hashes, fontes, referências e registros das artes ativas |
| `docs/maintenance` | Evidências e resultado da limpeza |

Os originais de GPT Image em `assets/generated/sources` e os originais dos
personagens em `assets/colors/sources` são usados pelos verificadores e conversores.
Eles ficam fora do bundle Flutter. Os SVGs são rastreados dessas imagens ou de
imagens existentes autorizadas, preservando a origem de cada desenho.

Para executar ferramentas de conversão de arte:

```sh
python -m pip install -r scripts/requirements.txt
python scripts/validate_color_assets.py
```

As ferramentas Node de rasterização/exportação usam `sharp`.
A captura atual permanece disponível em `scripts/capture_app_test.dart`; ela gera
prévias em `docs/preview`, pasta ignorada pelo Git.

## Atualizar conteúdo

IDs publicados de filmes, perguntas e estágios são estáveis. Ao alterar o catálogo
de filmes, regenere tanto `assets/cineus_v1.db` quanto `assets/cineus_v1_seed.json` e
incremente `AppConstants.contentVersion`. As migrações preservam sessões,
progresso e tickets. Partidas de Cores guardam a edição original do catálogo para
não mudar perguntas ou referências no meio de uma partida antiga.

## Documentação de operação

- [Ferramentas de release](docs/RELEASE_TOOLCHAIN.md)
- [Requisitos de publicação](docs/RELEASE_COMPLIANCE.md)
- [Pôsteres e direitos](docs/POSTER_ASSETS.md)
- [Links públicos](docs/PUBLIC_LINKS.md)
- [Monetização](docs/MONETIZATION.md)
- [Localização](docs/LOCALIZATION_WORKFLOW.md)

As licenças das fontes ficam em `assets/licenses` e podem ser lidas no app.
Privacy, Terms e Support em `docs` são mantidos em sincronia com suas cópias em
`web`. Os serviços de monetização ficam ocultos enquanto não houver configuração
real. O CI verifica catálogo, origem das artes, fontes, análise e testes, além de
compilar Android, iOS e Web.

Projeto privado para uso pessoal e portfólio.
