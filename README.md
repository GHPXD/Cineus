# 🎬 Cineus — Jogo Diário de Adivinhação de Filmes

> *Adivinha o filme em até 10 dicas. Quanto menos usar, mais pontos.*

Jogo mobile e web (Android / iOS / Web) estilo Wordle: o jogador adivinha um filme
a partir de dicas progressivas. Um desafio por dia, **o mesmo filme para todos**.

**Estado:** 89 arquivos Dart · ~15.600 linhas · 281 casos de teste · 3 idiomas
(pt / en / es) · catálogo offline de 500 filmes × 10 dicas.

Para o que já foi feito e o que falta, ver **[docs/ROADMAP.md](docs/ROADMAP.md)**.

---

## 🎮 Modos e mecânicas

| Modo | Como funciona | Escala |
|------|---------------|--------|
| **Dicas** | 10 dicas progressivas, da mais abstrata à mais óbvia | 10 → 1 ponto |
| **Poster** | 5 níveis de desfoque sobre o cartaz | 5 → 1 ponto |
| **Estágios** | Blocos de 10 filmes, desbloqueados em sequência, em ambos os modos | por filme |
| **Desafio de amigo** | Um filme avulso recebido por código/link | 10 → 1 ponto |

| Mecânica | Detalhe |
|----------|---------|
| **Pontuação** | Definida por `ScoringRules` — uma regra por modo, em um só lugar |
| **Revelar** | Cada revelação custa 1 ponto |
| **Palpites** | Sem limite fixo. Cada erro queima o passo seguinte |
| **Derrota** | Errar quando o último passo já está revelado |
| **Acerto** | Título exato, insensível a caixa e acento (PT-BR ou original). Proximidade de franquia é **dica**, nunca acerto |
| **Busca** | Ranqueada por relevância, tolerante a 2 erros de digitação, insensível a acento/caixa/pontuação |
| **Dia** | **UTC**, para que todos recebam o mesmo filme no mesmo instante |
| **Tickets** | 20 por dia + ganhos por vitória, sequência e estágio completo. Custam 1 por partida de estágio |
| **Dicas extras** | Diretor / Ano / Duração por 1 🎫 — **não** consomem passo de revelação |
| **Sequência** | Consecutiva em dias de calendário. Pode ser protegida pagando 3 🎫 por um dia perdido |
| **Conquistas** | 7 badges, **derivados** do histórico — nunca armazenados |

---

## 🏗️ Arquitetura

Clean Architecture com separação real: `domain/` não conhece Flutter nem SQLite.

```
lib/
├── core/
│   ├── constants/app_constants.dart      # Configuração + mapa de 162 emojis de categoria
│   ├── theme/
│   │   ├── app_colors.dart               # Rampa Obsidian + tons de texto com contraste AA
│   │   ├── app_fonts.dart                # Nomes das famílias bundladas
│   │   ├── app_typography.dart           # Escala tipográfica
│   │   └── app_theme.dart                # ThemeData.dark
│   └── utils/
│       ├── daily_selector.dart           # Filme do dia (determinístico, UTC)
│       ├── string_normalizer.dart        # Normalização para matching de palpite
│       ├── movie_search.dart             # Ranking + Levenshtein da busca
│       ├── challenge_code.dart           # Código CIN-XXXX (base32 + checksum)
│       └── daily_reminder_time.dart      # Horário do lembrete diário
│
├── domain/                               # Regras de negócio, zero dependências
│   ├── entities/
│   │   ├── movie.dart · clue.dart · stage.dart
│   │   ├── game_session.dart             # GameMode, SessionKind, identidade explícita
│   │   ├── scoring_rules.dart            # Pontuação por modo
│   │   ├── game_stats.dart · play_insights.dart
│   │   ├── achievement.dart              # Só id + emoji; o texto é da apresentação
│   │   ├── ticket_reward.dart            # RewardKind + valor
│   │   ├── extra_hint.dart · player_tickets.dart
│   └── repositories/                     # 5 interfaces
│
├── data/
│   ├── datasources/
│   │   ├── database_provider.dart        # Costura de injeção (torna repos testáveis)
│   │   ├── database_helper.dart          # Abre/copia/migra o SQLite
│   │   ├── database_seeder.dart          # Schema, seed e migrações idempotentes
│   │   ├── legacy_session_key.dart       # Parser da chave antiga (migração única)
│   │   └── notification_service.dart     # Lembrete diário, atrás de interface
│   ├── models/movie_model.dart
│   └── repositories/                     # 5 implementações
│
├── l10n/                                 # ARB (pt/en/es) + AppL10n gerado
│
├── presentation/
│   ├── l10n_mappers.dart                 # id de domínio → texto localizado
│   ├── deep_link_handler.dart            # cineus://challenge/CIN-XXXX
│   ├── providers/
│   │   ├── providers.dart                # DI
│   │   ├── play_notifier.dart            # UM notifier para os dois modos
│   │   ├── game_actions.dart             # Efeitos compartilhados (ticket, refresh)
│   │   ├── reward_notifier.dart          # Recompensas e congelamento de sequência
│   │   ├── reminder_notifier.dart        # Preferência de lembrete
│   │   ├── locale_notifier.dart          # Idioma
│   │   └── stats_ · stage_ · ticket_ · search_notifier.dart
│   ├── screens/                          # 20 telas (Generic* + wrappers finos)
│   └── widgets/                          # 12 widgets
│
├── app.dart · main.dart
```

**Padrão recorrente:** telas que diferem só em configuração são um `Generic*Screen`
mais um `*Config`, com wrappers de ~20 linhas. Vale para estágios, detalhe de
estágio, busca e resultado.

---

## 🗄️ Banco de dados

### Schema

```sql
-- Conteúdo (vem do asset, substituível)
movies (id, tmdb_id, title, original_title, year, director, genres,
        poster_path, overview, tagline, runtime, created_at, preview_url)
clues  (id, movie_id, clue_number 1..10, category, text)

-- Dados do jogador (nunca sobrescritos)
game_sessions (id, mode, kind, date, stage_id, movie_id,
               revealed_clues, guesses, status, score, extra_hints)
stages         (id, order_index, name, film_ids)
stage_progress (id, stage_id, movie_id, mode, status)
player_tickets (id, daily_tickets, extra_tickets, last_reset_date)
ticket_rewards (key, amount, awarded_at)     -- idempotência das recompensas
streak_freezes (date, created_at)            -- dias protegidos
app_meta       (key, value)                  -- versão de conteúdo, flags, idioma
```

`game_sessions` tem **índices únicos parciais**, um por tipo de sessão:

```sql
UNIQUE (mode, date)                WHERE kind = 'daily'
UNIQUE (mode, stage_id, movie_id)  WHERE kind = 'stage'
UNIQUE (mode, movie_id)            WHERE kind = 'challenge'
```

`date` e `stage_id` usam sentinelas (`''` e `0`) em vez de NULL: o SQLite trata
NULLs como distintos e os índices deixariam duplicatas passar.

### Carregamento e migrações

- **Mobile:** o `cineus_v1.db` é copiado do asset no primeiro launch. As tabelas
  de jogador são criadas em runtime.
- **Web:** banco criado via `sqflite_common_ffi_web`, semeado do
  `assets/cineus_v1_seed.json`.
- **Migrações** são idempotentes e **auto-detectáveis** (inspecionam colunas em
  vez de depender do `onUpgrade`) — o arquivo bundled vem de um script Python com
  `user_version` fora do nosso controle.

---

## 🛠️ Stack

| Pacote | Uso |
|--------|-----|
| `flutter_riverpod` ^2.6 | Estado (StateNotifier) |
| `sqflite` + `sqflite_common_ffi_web` | SQLite local e no browser |
| `go_router` ^14.8 | Navegação declarativa |
| `flutter_localizations` + `intl` | i18n (pt/en/es) via `gen_l10n` |
| `share_plus` | Compartilhamento nativo |
| `flutter_local_notifications` + `timezone` | Lembrete diário |
| `app_links` | Deep link `cineus://` |
| `sqflite_common_ffi` (dev) | SQLite real nos testes |

Tipografia (Playfair Display, Inter, DM Mono) é **asset bundlado**, não download —
ver "Build de release".

> **Declarados sem uso:** `path_provider` e `cupertino_icons`. Podem sair.

---

## 🚀 Rodando

```bash
flutter pub get
flutter run -d chrome      # mais rápido para testar
flutter run -d android
flutter analyze
flutter test
```

Ao mexer nos ARB: `flutter gen-l10n` (ou apenas rode o app — `generate: true`).

---

## 📦 Build de release

### 1. Chave de assinatura (uma vez)

O `build.gradle.kts` procura `android/key.properties`. **Sem esse arquivo o build
usa a chave de debug** — funciona local, mas a Play Store rejeita e instalar por
cima de um release real falha por divergência de assinatura. O Gradle avisa.

```bash
keytool -genkey -v -keystore %USERPROFILE%\cineus-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copie `android/key.properties.example` para `android/key.properties` e preencha.
`key.properties`, `*.jks` e `*.keystore` estão no `.gitignore` — **perder essa
chave impede atualizar o app publicado**.

### 2. Fontes

As três famílias são assets em `assets/fonts/`, declaradas no `pubspec.yaml`. O app
não usa `google_fonts` e não baixa fonte alguma: o manifest de release não tem
permissão de `INTERNET` (o Flutter só a injeta em debug/profile), então qualquer
download falharia em silêncio e derrubaria toda a tipografia para a fonte do
sistema.

Playfair Display e Inter só existem como *variable fonts* upstream — os arquivos
são instâncias estáticas por peso, com subset para os caracteres que o app e o
catálogo usam (3,2 MB → 1,2 MB).

### 3. Atualizando o catálogo

Trocar o JSON **não basta**: o `.db` só é copiado no primeiro launch.

1. Regenere `assets/cineus_v1.db` e `assets/cineus_v1_seed.json`.
2. Incremente `AppConstants.contentVersion`.

Na próxima abertura o app importa o catálogo novo e estende a lista de estágios.
Sessões, progresso e tickets **não são tocados** — os ids de filme são estáveis
entre exportações, e é isso que mantém o `stage_progress` válido.

---

## 🌍 Idiomas

204 chaves em `lib/l10n/app_{pt,en,es}.arb`, com plurais ICU e placeholders
tipados. Português é o template.

- Padrão: segue o aparelho. Override persistido em `app_meta`.
- Seletor no fim da tela de Estatísticas, cada idioma **no próprio idioma**.
- O texto de compartilhamento também é localizado.
- Entidades de domínio carregam **id/enum**, nunca texto — a tradução vive em
  `presentation/l10n_mappers.dart`.

> **Limitação:** o catálogo é conteúdo em português. As 5.000 dicas, as 162
> categorias e os títulos vêm do banco e **continuam em português em qualquer
> idioma**. Não existem títulos em espanhol na base — apenas PT-BR + original
> (inglês). Isso é dito ao jogador na própria tela de idioma.

---

## ♿ Acessibilidade

- **Contraste medido, não estimado.** `textSecondary` (5.24:1) e `textTertiary`
  (4.69:1) passam AA para corpo de texto; `textQuaternary` (3.32:1) só para texto
  grande. Os tons dim da rampa obsidian (1.31–2.08:1) ficaram restritos a bordas e
  fundos.
- **Alvos de toque** de no mínimo 48×48 via `TapTarget`, que exige rótulo.
- **Decorativos** (`FilmStrip`, grid de compartilhamento) marcados com
  `ExcludeSemantics`.
- **Fonte grande** verificada em 1.0× / 1.3× / 1.6× / 2.0× sem overflow.

> **Cuidado ao mexer:** `excludeSemantics: true` descarta a semântica do filho
> **incluindo a ação de toque** do `GestureDetector`/`InkWell`. Sempre declare
> `onTap:` também no `Semantics`, ou o botão é anunciado e não ativa.

---

## 🔔 Lembrete diário

Switch desligado por padrão em Estatísticas. A permissão do SO é pedida **somente
quando o jogador liga** — pedir na inicialização converte mal e, no Android, duas
recusas bloqueiam permanentemente.

- Dispara às **9h locais**. Reagendado a cada abertura, porque o SO descarta
  agendamentos em reboot/reinstalação e o texto precisa acompanhar o idioma.
- Agendamento **inexato** de propósito: `SCHEDULE_EXACT_ALARM` exige tela de acesso
  especial no Android 14 e um lembrete não precisa de precisão de segundo.
- Permissão revogada nas configurações desliga o switch em vez de mentir.

---

## 🎯 Desafiar um amigo

O jogador manda um filme já jogado como desafio avulso.

- Código **`CIN-XXXX`** em base-32 estilo Crockford (sem I, L, O, U — para não
  confundir com 1 e 0), id embaralhado por multiplicação modular + 5 bits de
  checksum. **97% dos erros de um caractere são rejeitados** em vez de abrirem o
  filme errado em silêncio.
- Deep link `cineus://challenge/CIN-XXXX`, registrado no `AndroidManifest` e no
  `Info.plist`. Quem não tem o app cola o código em Estatísticas.
- Jogar um desafio **não custa ticket** — o amigo escolheu o filme.

> Scheme customizado, não link universal `https`: este último exige domínio próprio
> e arquivo de associação hospedado. `cineus.app` hoje é só uma string no texto de
> compartilhamento.

---

## 🧪 Testes

```bash
flutter test
```

281 casos em 21 arquivos. Os que mais valem entender:

| Arquivo | Protege |
|---------|---------|
| `session_migration_test.dart` | A migração única da chave antiga — reescreve o histórico inteiro do jogador |
| `game_repository_test.dart` | Repositório real contra SQLite real |
| `play_notifier_test.dart` | Partidas completas nos dois modos |
| `ticket_economy_test.dart` | Idempotência das recompensas e congelamento de sequência |
| `movie_search_catalogue_test.dart` | Busca contra os 500 filmes reais |
| `challenge_code_test.dart` | Round-trip nos 32.767 ids + detecção de erro de digitação |
| `l10n_test.dart` | Paridade de chaves e placeholders entre os 3 idiomas |
| `no_hardcoded_strings_test.dart` | Impede string em português voltar para a UI |
| `accessibility_test.dart` | Contraste, semântica e ausência de overflow em 4 escalas |
| `fonts_test.dart` | Assets de fonte existem e casam com o pubspec |

Os dois últimos protegem **falhas silenciosas**: uma família de fonte renomeada ou
uma chave só no português compila e só quebra na cara do jogador.

---

## 📐 Decisões registradas

Coisas que parecem arbitrárias e não são:

| Decisão | Por quê |
|---------|---------|
| Dia em **UTC** | "O mesmo filme para todos" exige um instante único. Em Brasília o desafio vira às 21h — e o contador concorda |
| Acerto só por **título exato** | `isFranchiseMatch` aceita prefixo e dava pontuação máxima pelo filme errado em 205 combinações do catálogo |
| **Sem limite** de palpites | A UI anunciava "x / 5 máx." que nada aplicava. A regra real sempre foi perder ao errar no último passo |
| Títulos homônimos são aceitos | 5 pares remake/original compartilham título. O jogador produziu o nome certo e as dicas não fixam o ano |
| Migração **auto-detectável** | O `.db` vem de script Python; `user_version` não é confiável como gatilho |
| Índices únicos **parciais** | Três tipos de sessão com regras de unicidade diferentes |
| Recompensas com **chave determinística** | `PRIMARY KEY` na chave é o que impede pagar duas vezes |
| Congelar sequência **não inventa vitória** | `totalGames` e `totalWins` ficam intactos |
| Busca ranqueada **em Dart** | `LIKE` é accent-sensitive (172 dos 500 títulos têm acento) e não expressa relevância |
| Conquistas **derivadas** | Corrigir o cálculo de sequência corrige os badges retroativamente |

---

## 📜 Licença

Projeto privado — uso pessoal / portfólio.
#   C i n e u s  
 