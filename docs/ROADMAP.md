# Roadmap e estado do backlog

Registro do que foi feito, do que ficou de fora e do que falta decidir.
Escrito para que qualquer um (inclusive nós mesmos em três meses) consiga retomar
sem reconstruir o contexto.

Última atualização: **2026-08-04**

**Códigos:** `A#` = bug, `B#` = melhoria, `C#` = refatoração, `D#` = feature.
Vêm da auditoria inicial do projeto e são mantidos para rastreabilidade.

---

## ✅ Concluído

### Fase 1 — Bugs que afetavam o jogador

| # | Problema | Correção |
|---|---|---|
| A1 | Estatísticas contaminadas por sessões de Poster; `ORDER BY date DESC` era ordenação de string, então `"visual_…"` vinha antes das datas | Filtro por chave diária; ordenação cronológica |
| A2 | Modo Poster aceitava prefixo de franquia — **205 combinações** do catálogo davam pontuação máxima pelo filme errado | Só `isExactMatch` decide acerto |
| A4 | `challengeEpoch` local comparado com UTC → nº do desafio errado em 1 | `DateTime.utc` |
| A5 | Rollover em UTC, contador em hora local (desafio trocava 3h antes do anunciado) | Contador em UTC |
| A6 | Botões "Próximo" atravessavam um estágio inteiro com 1 ticket | Todos os 5 pontos de entrada passam por `startFilmWithTicket` |
| A7 | Grid de Estágios não atualizava no modo Dicas (assimetria com Poster) | `refreshAfterGameFinished` nos dois modos |
| A9 | Stats da Home congeladas até abrir a tela de Estatísticas | Mesmo hook invalida os providers derivados |
| A10 | Limite de 5 palpites exibido mas nunca aplicado | Removido da UI; regra real documentada |

**Extras da fase:** sequência passou a exigir dias **consecutivos de calendário**
(antes somava por cima de buracos); filme fixado na sessão para a mudança de epoch
não trocar o filme de uma partida em andamento; `widget_test` reescrito (A20).

### Fase 2 — Bloqueadores de release

| # | Problema | Correção |
|---|---|---|
| A3 | Tipografia caía para a fonte do sistema em release: `google_fonts` baixava de `fonts.gstatic.com` e o manifest de release não tem `INTERNET` | 14 instâncias estáticas bundladas, com subset (3,2 MB → 1,2 MB) e cobertura de glifos provada |
| A11 | Release assinado com chave de debug | Gradle lê `key.properties`, com aviso no fallback |
| A12 | Catálogo novo nunca chegava a quem já tinha o app | `app_meta.content_version` + refresh preservando dados do jogador |
| A23 | `android:label="cineus"`, manifest web com "A new Flutter project." | Metadados reais |
| A27 | Projeto sem git; `.venv` de 176 MB e **`.env` fora do `.gitignore`** | `git init` + regras (sem commit — é seu) |

### Fase 3 — Busca e dados

| # | Problema | Correção |
|---|---|---|
| A8 | Busca accent-sensitive: **172 dos 500 títulos** inalcançáveis sem digitar o acento; caixa alta com acento retornava zero | Índice em memória + normalização |
| A30 | `ORDER BY title ASC` não é relevância ("star" trazia "A Culpa é das Estrelas" primeiro) | Camadas de pontuação em `MovieSearch` |
| B2 | — | Levenshtein com abandono antecipado (`matrox`→Matrix) |
| B3 | Homônimos indistinguíveis na lista | Ano inline quando dois resultados colidem |
| A13 | 10 "falsos acertos" por títulos duplicados | **Decisão registrada:** aceitar. O jogador produziu o nome certo e as dicas não fixam o ano |

### Fase 4 — Refatorações estruturais

| # | O que mudou |
|---|---|
| C1 | Identidade da sessão saiu da string `date` para colunas `mode`/`kind`/`date`/`stage_id`, com índices únicos parciais e migração transacional testada |
| C2 | `GameNotifier` + `VisualGameNotifier` (85% idênticos, já divergentes) → um `PlayNotifier` parametrizado por `GameMode` |
| C3 | `VictoryScreen` + `DefeatScreen` (~320 linhas cada) → `GenericResultScreen` + 2 wrappers de 23 |
| C4 | `DatabaseProvider` como costura de injeção — destravou testar repositórios contra SQLite real |
| C5 | `ScoringRules`: uma definição por modo, no lugar de `11 -`, `6 -`, `< 10`, `>= 5` espalhados |
| C6/C7 | Já resolvidos na Fase 1 pelo `game_actions.dart` |

**Extras:** `error` com limpeza explícita (A14) e `guessCount` para o banner de
franquia reaparecer em palpites consecutivos (A15).

### Fase 5 — Features

| # | Feature | Nota |
|---|---|---|
| D1 | Ganhar tickets | `extraTickets` existia e nada incrementava. 3 caminhos de ganho, idempotentes por chave |
| D2 | Compartilhamento nativo | `share_plus` estava no pubspec com zero imports |
| D3 | Onboarding no primeiro uso | O guia existia, só alcançável por um `?` discreto |
| D5 | 7 conquistas | Derivadas do histórico, nunca armazenadas |
| D7 | Proteger sequência | 3 🎫 por um dia perdido, sem inventar vitória |
| D8 | Perfil por gênero e década | `genres`/`year` só decoravam o poster |
| D9 | i18n pt/en/es | 204 chaves; texto de UI saiu do domínio |
| D12 | Dicas extras pagas | Custam ticket, não pontos |
| B9 | Acessibilidade | Contraste medido, alvos de 48dp, sem overflow até 2× |
| D4 | Lembrete diário | 9h local, permissão só sob comando do jogador |
| D10 | Desafiar amigo | Código `CIN-XXXX` + deep link `cineus://` |
| A16 | Race no `TicketNotifier` | Guard `_ready` (necessário para D1 ter contabilidade correta) |

---

## 🔶 D11 — Tema claro (a decidir antes de codar)

**Aprovado, não iniciado.** É o único item aprovado que não entreguei, e por um
motivo específico: não é trabalho de código, é decisão de design.

### Por que não é inversão de cores

A paleta **Obsidian** foi desenhada para fundo escuro. Um tema claro precisa de
respostas que só você pode dar:

1. **Qual é o fundo claro?** Branco puro (`#FFFFFF`), off-white (`obsidian50`
   = `#EAEAF2`), ou um creme quente que combine com o dourado?

2. **Quais cores de destaque sobrevivem?** Medi todas contra os dois fundos
   candidatos. **Cinco das oito reprovam AA:**

   | Cor | sobre branco | sobre off-white | Veredito |
   |---|---|---|---|
   | `gold300` (destaque atual) | **1.91** | 1.60 | ✗ |
   | `amber400` (tier 4–3) | **2.16** | 1.80 | ✗ |
   | `blue300` (tier 7–5) | **2.95** | 2.47 | ✗ |
   | `ruby300` (tier 2–1) | **3.65** | 3.05 | ✗ para corpo, ~ok grande |
   | `success400` | **1.94** | 1.62 | ✗ |
   | `gold600` | 5.65 | 4.72 | ✓ |
   | `gold700` | 8.56 | 7.16 | ✓ |
   | `blue500` | 6.96 | 5.81 | ✓ |

   Ou seja: o tema claro precisa de um **segundo conjunto de destaques**, puxando
   para os tons 500–700 da rampa. Não é ajuste, é uma paleta paralela.

3. **Os tiers de pontuação mudam?** `AppColors.scoreColor` mapeia 10→gold,
   7→blue, 4→amber, 1→ruby — e três dos quatro reprovam sobre claro. Os tiers
   precisam de um mapeamento próprio no tema claro, o que muda a identidade visual
   do placar.

4. **A arte dos estágios muda?** As 10 paletas cinematográficas de
   `_StageCoverArt` são todas escuras por definição, e o texto em cima é branco.

### Custo técnico, uma vez decidido

O bloqueio real: **~200 usos diretos de `AppColors.*`** nos widgets. Um tema claro
funcional exige uma camada semântica:

```dart
// Hoje                          // Necessário
AppColors.obsidian950            palette.background
AppColors.obsidian800            palette.surface
AppColors.textSecondary          palette.textSecondary
```

Caminho sugerido: `AppPalette` como `ThemeExtension` com instâncias `light`/`dark`,
acessada via `Theme.of(context).extension<AppPalette>()!`, e conversão incremental
dos widgets.

Hoje o `app.dart` passa apenas `theme: AppTheme.dark`. Cheguei a escrever o
`AppTheme.light` + `ThemeNotifier` e **desfiz** — sem a camada semântica o tema
claro trocaria só a moldura do Material e deixaria as ~200 cores diretas intactas,
resultando em texto claro sobre fundo claro. Melhor não existir do que existir
quebrado.

### O que já está pronto para isso

- Tokens centralizados em `AppColors` (nenhuma cor solta nos widgets, exceto
  `Colors.white.withValues(alpha:)` em bordas)
- `accessibility_test.dart` já mede contraste — basta adicionar as asserções dos
  fundos claros e o tema nasce verificado
- `ThemeNotifier` + persistência em `app_meta` seguem o padrão já usado por
  idioma e lembrete

**Estimativa honesta:** 1 sessão para a camada semântica + conversão, depois de as
4 perguntas acima estarem respondidas.

---

## ⏸️ Em standby

### D13 — Terceiro modo de jogo (trilha sonora / frame / elenco)

Você pediu standby. Registrando o que a Fase 4 mudou: **o código ficou barato**.
Adicionar um valor em `GameMode`, uma `ScoringRules` e uma tela — o `PlayNotifier`,
os estágios, os tickets, as recompensas e as estatísticas já servem o modo novo.

O caro agora é **conteúdo**: trilhas ou frames para 500 filmes, com licenciamento.

### D6 — Modo treino/infinito

**Excluído por você.** Registrando o motivo levantado na época: parece redundante
com os Estágios, que já oferecem jogo ilimitado fora do desafio diário.

---

## 🔻 Itens do catálogo que nunca entraram em fase

Nenhum é urgente. Ordenados por relação valor/esforço.

| # | Item | Nota |
|---|---|---|
| **B7** | Posters para WebP | **Maior ganho isolado que resta.** 40 MB de JPEG → estimo 12–15 MB. É a maior parte do peso do app. Não fiz porque re-encodar 500 imagens com perda é troca de qualidade que só você aceita — posso gerar comparação lado a lado antes |
| A17 | Ticket debitado antes de `loadAction` | Se o filme não carregar, o ticket já foi. `startFilmWithTicket` é o único lugar a mudar; falta um `addTickets` de estorno |
| A18 | `Future.delayed` do splash sem cancelamento | `context.go` num widget morto se o jogador sair em < 2,5s |
| A19 | `path_provider` e `cupertino_icons` declarados sem uso | Podem sair do pubspec |
| A24 | Constantes mortas | `animationFast/Medium/Slow`, `maxGuessInputLength`, `clueCategories`, `appName` (0 usos); `AppConstants.dailyTickets` duplica `PlayerTickets.maxDailyTickets` |
| A25 | APIs mortas | `StageNotifier.markMovieCompleted`, `StageRepository.isMovieCompleted`, `AppColors.scoreGradient`/`rubyDimGradient`, `ScoreBadge.compact` |
| A26 | `normalize()` não cobre `ü ä ö ñ` | Inofensivo com o catálogo atual (só PT/EN); armadilha se entrar filme europeu |
| A29 | `seed.json` (1,2 MB) vai no APK | Só é usado na web. Falta condicional no `pubspec` |
| A31 | Dependências atrasadas | 37 pacotes com versão maior. Notáveis: `go_router` 14→17, `share_plus` 10→13, `flutter_lints` 5→6 |
| B10 | Erro exibido como `e.toString()` cru | Aparece no meio da tela em falha de carregamento |
| B11 | SnackBar de franquia duplicado | Bloco idêntico em `game_screen` e `visual_screen` |
| C8 | Riverpod 2 → 3 | `StateNotifier` está deprecado. Major breaking; deliberadamente fora da Fase 4 |
| D1+ | `RewardNotifier.freezeMissedDay` não estorna | Se `freezeStreakDay` falhar depois do débito, o ticket some. Mesmo `addTickets` do A17 resolve |

---

## ⚠️ Limitações conhecidas

Coisas que funcionam como projetado, mas cujo limite vale saber.

| Área | Limitação |
|---|---|
| **Idioma do catálogo** | Interface em 3 idiomas; **dicas, categorias e títulos seguem em português**. Não há títulos em espanhol na base — só PT-BR + original (inglês). Dito ao jogador na tela de idioma |
| **Horário de verão** | O lembrete resolve o fuso como offset fixo (`Etc/GMT±N`): acerta a hora local, mas **anda 1h na virada do DST**. Correção seria `flutter_timezone` (dependência nova) |
| **Link universal** | O desafio usa scheme `cineus://`. Um link `https` clicável exigiria domínio próprio + arquivo de associação hospedado |
| **Deep link na web** | `app_links` não cobre web; lá o código é colado manualmente |
| **Dica de franquia** | `isSameFranchise` só reconhece sequências **numeradas** ("Rocky" → "Rocky II"). Subtituladas não ("Vingadores" → "Vingadores: Ultimato"). Não afeta o critério de acerto |
| **Hífen na normalização** | `normalize` apaga o hífen sem virar espaço: "Spider Man" não casa com "Spider-Man". Inofensivo porque o palpite vem do autocomplete |
| **Homônimos** | Nomear "O Rei Leão" aceita qualquer um dos dois. Decisão registrada, não bug |

---

## 🧪 Verificação pendente em device

Tudo compila, o analyzer está limpo e `flutter build web` passa. Mas **duas
features não puderam ser validadas** por não haver device/emulador Android neste
ambiente:

### D4 — Lembrete diário

Verificado: lógica de quando/se (13 testes com fake), entradas de manifest por
leitura.
**Não verificado:** notificação chegando, prompt de permissão real no Android 13+ e
iOS, comportamento após reboot.

### D10 — Desafio por deep link

Verificado: codec em 32.767 ids, detecção de erro de digitação, entradas de
`AndroidManifest` e `Info.plist` por leitura.
**Não verificado:** o link efetivamente abrindo o app.

```bash
flutter run --release -d android
# ligar o switch em Estatísticas, aceitar a permissão
adb shell am start -a android.intent.action.VIEW -d "cineus://challenge/CIN-XXXX"
```

Use um código que o próprio app gerou (botão "Desafiar um amigo" após terminar uma
partida) — códigos inventados falham no checksum de propósito.

### Também nunca executado aqui

`flutter build apk --release`. O `build.gradle.kts` está sintaticamente correto e a
lógica é simples, mas o build Android nunca rodou. Deve completar e imprimir o aviso
de chave de debug até você criar o `key.properties`.

---

## 📁 Outros arquivos em `docs/`

| Arquivo | O que é |
|---|---|
| `ROADMAP.md` | Este documento |
| `design-system.css` | Protótipo visual original (pré-Flutter). Referência histórica de paleta e tipografia — **não** é consumido pelo app |
| `index.html` | Protótipo HTML das telas, mesma origem. Útil para comparar intenção de design |
| `filmes_mapeados.md` | Lista do catálogo gerado |

`scripts/export_seed_json.py` está **desatualizado**: aponta para `../cineus.db`
(caminho que não existe mais) e não exporta `tmdb_id`, embora o JSON em uso o
tenha. Se for regerar o seed, conferir o script antes — foi por sorte que o refresh
de catálogo funcionou.

---

## 🗂️ Como retomar

1. `flutter pub get && flutter test` — 281 casos devem passar
2. `flutter analyze` — deve estar limpo
3. Ler as **Decisões registradas** no [README](../README.md#-decisões-registradas)
   antes de mudar regra de jogo: várias parecem arbitrárias e não são
4. Escolha provável de próximo passo:
   - **Validar em device** o que a seção acima lista (menor esforço, maior risco coberto)
   - **B7 (WebP)** se o tamanho do app incomodar
   - **D11** depois de responder as 4 perguntas de paleta
   - **Faxina** (A19, A24, A25) se quiser uma sessão curta e de baixo risco
