from __future__ import annotations

from pathlib import Path
import re
import shutil

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    (ROOT / path).write_text(text, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one match, found {count}: {old[:80]!r}")
    write(path, text.replace(old, new, 1))


def sub_once(path: str, pattern: str, repl: str, *, flags: int = 0) -> None:
    text = read(path)
    new, count = re.subn(pattern, repl, text, count=1, flags=flags)
    if count != 1:
        raise RuntimeError(f"{path}: regex expected one match, found {count}: {pattern[:80]!r}")
    write(path, new)


def remove_once(path: str, old: str) -> None:
    replace_once(path, old, "")


# ---------------------------------------------------------------------------
# Database retry seam + mobile catalogue refresh from bundled SQLite
# ---------------------------------------------------------------------------
replace_once(
    "lib/data/datasources/database_helper.dart",
    "import 'package:flutter/foundation.dart' show kIsWeb;",
    "import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;",
)
replace_once(
    "lib/data/datasources/database_helper.dart",
    "class DatabaseHelper implements DatabaseProvider {\n  DatabaseHelper._();\n  static final DatabaseHelper instance = DatabaseHelper._();\n\n  final _seeder = const DatabaseSeeder();",
    "class DatabaseHelper implements DatabaseProvider {\n"
    "  DatabaseHelper._() : _initializer = null;\n\n"
    "  @visibleForTesting\n"
    "  DatabaseHelper.forTesting(this._initializer);\n\n"
    "  static final DatabaseHelper instance = DatabaseHelper._();\n\n"
    "  final Future<Database> Function()? _initializer;\n"
    "  final _seeder = const DatabaseSeeder();",
)
replace_once(
    "lib/data/datasources/database_helper.dart",
    "      final db = await _initDatabase();",
    "      final db = await (_initializer?.call() ?? _initDatabase());",
)
replace_once(
    "lib/data/datasources/database_helper.dart",
    "      await _seeder.refreshContentIfStale(db);\n    }\n\n    return db;\n  }\n\n  Future<void> _onCreateWebAndSeed",
    "      await _refreshMobileContentIfStale(db);\n    }\n\n"
    "    return db;\n"
    "  }\n\n"
    "  Future<void> _refreshMobileContentIfStale(Database db) async {\n"
    "    await _seeder.ensureAppMetaTable(db);\n"
    "    final installed = await _seeder.readContentVersion(db);\n"
    "    if (installed >= AppConstants.contentVersion) return;\n\n"
    "    final tempPath = join(await getDatabasesPath(), 'cineus_content_source.db');\n"
    "    Database? source;\n"
    "    try {\n"
    "      await deleteDatabase(tempPath);\n"
    "      final data = await rootBundle.load('assets/cineus_v1.db');\n"
    "      await File(tempPath).writeAsBytes(\n"
    "        data.buffer.asUint8List(),\n"
    "        flush: true,\n"
    "      );\n"
    "      source = await openDatabase(tempPath, readOnly: true);\n"
    "      await _seeder.refreshContentFromDatabaseIfStale(db, source);\n"
    "    } finally {\n"
    "      await source?.close();\n"
    "      await deleteDatabase(tempPath);\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> _onCreateWebAndSeed",
)

# ---------------------------------------------------------------------------
# Web seed stays available, but no longer ships as a Flutter mobile asset.
# Existing mobile installs refresh from the current bundled SQLite catalogue.
# ---------------------------------------------------------------------------
replace_once(
    "lib/data/datasources/database_seeder.dart",
    "import 'package:flutter/services.dart' show rootBundle;",
    "import 'package:flutter/services.dart' show NetworkAssetBundle;",
)
replace_once(
    "lib/data/datasources/database_seeder.dart",
    "  /// Reads `assets/cineus_v1_seed.json` and batch-inserts all rows.",
    "  /// Reads the web-only seed JSON and batch-inserts all rows.",
)
replace_once(
    "lib/data/datasources/database_seeder.dart",
    "    final jsonStr = await rootBundle.loadString('assets/cineus_v1_seed.json');",
    "    final jsonStr = await NetworkAssetBundle(Uri.base)\n"
    "        .loadString('cineus_v1_seed.json');",
)
insert_marker = "\n  // ── Content versioning ─────────────────────────────────────────────────────\n"
seed_from_db = r'''

  /// Copies catalogue rows from another SQLite database into [db].
  ///
  /// Mobile uses the bundled `cineus_v1.db` as the source for content upgrades,
  /// so the 1.2 MB JSON seed can remain web-only instead of inflating the APK.
  Future<void> seedFromDatabase(
    DatabaseExecutor db,
    Database source, {
    ConflictAlgorithm conflict = ConflictAlgorithm.replace,
  }) async {
    final movies = await source.query('movies');
    final clues = await source.query('clues');

    const movieCols = {
      'id', 'tmdb_id', 'title', 'original_title', 'year', 'director',
      'genres', 'poster_path', 'overview', 'tagline', 'runtime',
    };
    const clueCols = {'id', 'movie_id', 'clue_number', 'category', 'text'};
    const chunkSize = 100;

    for (var i = 0; i < movies.length; i += chunkSize) {
      final batch = db.batch();
      for (final m in movies.sublist(
        i,
        (i + chunkSize).clamp(0, movies.length),
      )) {
        batch.insert(
          'movies',
          {
            for (final e in m.entries)
              if (movieCols.contains(e.key)) e.key: e.value,
          },
          conflictAlgorithm: conflict,
        );
      }
      await batch.commit(noResult: true);
    }

    for (var i = 0; i < clues.length; i += chunkSize) {
      final batch = db.batch();
      for (final c in clues.sublist(
        i,
        (i + chunkSize).clamp(0, clues.length),
      )) {
        batch.insert(
          'clues',
          {
            for (final e in c.entries)
              if (clueCols.contains(e.key)) e.key: e.value,
          },
          conflictAlgorithm: conflict,
        );
      }
      await batch.commit(noResult: true);
    }
  }
'''
text = read("lib/data/datasources/database_seeder.dart")
if text.count(insert_marker) != 1:
    raise RuntimeError("database_seeder.dart: content-version marker not unique")
write("lib/data/datasources/database_seeder.dart", text.replace(insert_marker, seed_from_db + insert_marker, 1))

refresh_marker = "\n  /// Groups all movie IDs into buckets of [AppConstants.stageSize], adding only\n"
refresh_from_db = r'''

  /// Mobile counterpart to [refreshContentIfStale], using the bundled SQLite
  /// catalogue as source instead of the web JSON seed.
  Future<bool> refreshContentFromDatabaseIfStale(
    Database db,
    Database source,
  ) async {
    await ensureAppMetaTable(db);
    final installed = await readContentVersion(db);
    if (installed >= AppConstants.contentVersion) return false;

    await db.transaction((txn) async {
      await seedFromDatabase(txn, source);
    });
    await syncStages(db);
    await writeContentVersion(db, AppConstants.contentVersion);
    return true;
  }
'''
text = read("lib/data/datasources/database_seeder.dart")
if text.count(refresh_marker) != 1:
    raise RuntimeError("database_seeder.dart: syncStages marker not unique")
write("lib/data/datasources/database_seeder.dart", text.replace(refresh_marker, refresh_from_db + refresh_marker, 1))

seed_src = ROOT / "assets/cineus_v1_seed.json"
seed_dst = ROOT / "web/cineus_v1_seed.json"
if seed_src.exists():
    shutil.move(seed_src, seed_dst)
elif not seed_dst.exists():
    raise RuntimeError("cineus_v1_seed.json missing from both assets/ and web/")

# ---------------------------------------------------------------------------
# Splash lifecycle
# ---------------------------------------------------------------------------
replace_once(
    "lib/presentation/screens/splash_screen.dart",
    "import 'package:flutter/material.dart';",
    "import 'dart:async';\n\nimport 'package:flutter/material.dart';",
)
replace_once(
    "lib/presentation/screens/splash_screen.dart",
    "  late final Animation<double> _scale;",
    "  late final Animation<double> _scale;\n  Timer? _completionTimer;",
)
replace_once(
    "lib/presentation/screens/splash_screen.dart",
    "    Future.delayed(AppConstants.splashDuration, widget.onComplete);",
    "    _completionTimer = Timer(AppConstants.splashDuration, () {\n"
    "      if (mounted) widget.onComplete();\n"
    "    });",
)
replace_once(
    "lib/presentation/screens/splash_screen.dart",
    "  void dispose() {\n    _ctrl.dispose();",
    "  void dispose() {\n    _completionTimer?.cancel();\n    _ctrl.dispose();",
)

# ---------------------------------------------------------------------------
# String normalization: European diacritics + hyphens treated as separators.
# ---------------------------------------------------------------------------
replace_once(
    "lib/core/utils/string_normalizer.dart",
    ".replaceAll(RegExp(r'[áàâã]'), 'a')\n"
    "        .replaceAll(RegExp(r'[éèê]'), 'e')\n"
    "        .replaceAll(RegExp(r'[íìî]'), 'i')\n"
    "        .replaceAll(RegExp(r'[óòôõ]'), 'o')\n"
    "        .replaceAll(RegExp(r'[úùû]'), 'u')\n"
    "        .replaceAll('ç', 'c')\n"
    "        .replaceAll(RegExp(r'[^a-z0-9\\s]'), '')",
    ".replaceAll(RegExp(r'[áàâãä]'), 'a')\n"
    "        .replaceAll(RegExp(r'[éèêë]'), 'e')\n"
    "        .replaceAll(RegExp(r'[íìîï]'), 'i')\n"
    "        .replaceAll(RegExp(r'[óòôõö]'), 'o')\n"
    "        .replaceAll(RegExp(r'[úùûü]'), 'u')\n"
    "        .replaceAll('ç', 'c')\n"
    "        .replaceAll('ñ', 'n')\n"
    "        .replaceAll(RegExp(r'[-‐‑‒–—]'), ' ')\n"
    "        .replaceAll(RegExp(r'[^a-z0-9\\s]'), '')",
)
sub_once(
    "test/guess_matching_test.dart",
    r"    test\('hífen é removido sem virar espaço — trocar por espaço NÃO casa', \(\) \{.*?    \}\);",
    "    test('hífen vira separador e a variante com espaço casa', () {\n"
    "      expect(StringNormalizer.normalize('Spider-Man'), 'spider man');\n"
    "      expect(StringNormalizer.normalize('Spider Man'), 'spider man');\n"
    "      expect(\n"
    "        StringNormalizer.isExactMatch(\n"
    "          'Spider Man No Way Home',\n"
    "          ['Spider-Man: No Way Home'],\n"
    "        ),\n"
    "        isTrue,\n"
    "      );\n"
    "    });\n\n"
    "    test('diacríticos europeus são normalizados', () {\n"
    "      expect(StringNormalizer.normalize('München, España'), 'munchen espana');\n"
    "      expect(StringNormalizer.normalize('Häxan'), 'haxan');\n"
    "    });",
    flags=re.S,
)

# ---------------------------------------------------------------------------
# Remove unused dependencies and dead constants/APIs.
# ---------------------------------------------------------------------------
for dep in ["  cupertino_icons: ^1.0.8\n", "  path_provider: ^2.1.5\n"]:
    remove_once("pubspec.yaml", dep)
remove_once("pubspec.yaml", "    - assets/cineus_v1_seed.json\n")

for block in [
    "  static const String appName = 'Cineus';\n",
    "  /// Free daily tickets each player receives at midnight.\n  static const int dailyTickets = 20;\n\n",
    "  /// Default animation durations.\n"
    "  static const Duration animationFast = Duration(milliseconds: 200);\n"
    "  static const Duration animationMedium = Duration(milliseconds: 600);\n"
    "  static const Duration animationSlow = Duration(milliseconds: 800);\n\n",
    "  /// Max characters for guess input.\n  static const int maxGuessInputLength = 200;\n\n",
    "  /// Ordered clue categories (from most abstract to most obvious).\n"
    "  static const List<String> clueCategories = [\n"
    "    'Atmosfera',\n    'Estilo Visual',\n    'Temática',\n    'Narrativa',\n"
    "    'País / Época',\n    'Trilha Sonora',\n    'Prêmios',\n    'Diretor',\n"
    "    'Elenco',\n    'Tagline Oficial',\n  ];\n\n",
]:
    remove_once("lib/core/constants/app_constants.dart", block)

sub_once(
    "lib/presentation/providers/stage_notifier.dart",
    r"\n  /// Called when a stage film is won, to refresh the stage list\.\n"
    r"  Future<void> markMovieCompleted\(int stageId, int movieId\) async \{.*?\n  \}\n",
    "\n",
    flags=re.S,
)
remove_once(
    "lib/domain/repositories/stage_repository.dart",
    "  Future<bool> isMovieCompleted(int stageId, int movieId, {String mode = 'clue'});\n",
)
sub_once(
    "lib/data/repositories/stage_repository_impl.dart",
    r"\n  @override\n  Future<bool> isMovieCompleted\(.*?\n  \}\n",
    "\n",
    flags=re.S,
)

# Remove unused score gradients, inline the only ruby dim gradient that remains useful.
for pattern in [
    r"\n  static const goldGradient = LinearGradient\(.*?\n  \);\n",
    r"\n  static const blueGradient = LinearGradient\(.*?\n  \);\n",
    r"\n  static const rubyGradient = LinearGradient\(.*?\n  \);\n",
    r"\n  static const rubyDimGradient = LinearGradient\(.*?\n  \);\n",
    r"\n  static LinearGradient scoreGradient\(int score\) \{.*?\n  \}\n",
]:
    sub_once("lib/core/theme/app_colors.dart", pattern, "\n", flags=re.S)
replace_once(
    "lib/core/theme/app_colors.dart",
    "    return rubyDimGradient;",
    "    return const LinearGradient(\n"
    "      colors: [Color(0x478C004A), Color(0x14F04080)],\n"
    "      begin: Alignment.topLeft,\n"
    "      end: Alignment.bottomRight,\n"
    "    );",
)

remove_once("lib/presentation/widgets/score_badge_widget.dart", "  final bool compact;\n")
remove_once("lib/presentation/widgets/score_badge_widget.dart", "    this.compact = false,\n")
replace_once(
    "lib/presentation/widgets/score_badge_widget.dart",
    "      padding: EdgeInsets.symmetric(\n        horizontal: 20,\n        vertical: compact ? 10 : 16,\n      ),",
    "      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),",
)
replace_once(
    "lib/presentation/widgets/score_badge_widget.dart",
    "                style: (compact ? AppTypography.scoreMedium : AppTypography.scoreLarge)\n                    .copyWith(color: color),",
    "                style: AppTypography.scoreLarge.copyWith(color: color),",
)
sub_once(
    "lib/presentation/widgets/score_badge_widget.dart",
    r"          if \(!compact\) \.\.\.\[\n(.*?)\n          \],",
    lambda m: re.sub(r"^            ", "          ", m.group(1), flags=re.M),
    flags=re.S,
)

# ---------------------------------------------------------------------------
# Localized controlled errors and shared franchise hint UI.
# ---------------------------------------------------------------------------
locales = {
    "lib/l10n/app_pt.arb": "Não foi possível carregar. Tente novamente.",
    "lib/l10n/app_en.arb": "Could not load. Try again.",
    "lib/l10n/app_es.arb": "No se pudo cargar. Inténtalo de nuevo.",
}
for path, message in locales.items():
    text = read(path)
    if '"genericLoadError"' not in text:
        marker = '  "noMoviesInDatabase":'
        pos = text.find(marker)
        if pos < 0:
            raise RuntimeError(f"{path}: noMoviesInDatabase marker missing")
        end = text.find("\n", pos) + 1
        text = text[:end] + f'  "genericLoadError": "{message}",\n' + text[end:]
        write(path, text)

# Require the error mapper so production and tests cannot accidentally fall back
# to a non-localized technical string.
replace_once(
    "lib/presentation/providers/play_notifier.dart",
    "    String Function(PlayLoadError error)? errorText,\n  })  : _errorText = errorText ?? _fallbackErrorText,",
    "    required String Function(PlayLoadError error) errorText,\n  })  : _errorText = errorText,",
)
sub_once(
    "lib/presentation/providers/play_notifier.dart",
    r"\n  static String _fallbackErrorText\(PlayLoadError error\) => switch \(error\) \{.*?\n      \};\n",
    "\n",
    flags=re.S,
)
sub_once(
    "lib/presentation/providers/play_notifier.dart",
    r"    PlayLoadError\.loadFailed => switch \(locale\.languageCode\) \{.*?\n      \},",
    "    PlayLoadError.loadFailed => l10n.genericLoadError,",
    flags=re.S,
)

for path in [
    "lib/presentation/screens/generic_stage_detail_screen.dart",
    "lib/presentation/screens/generic_stages_screen.dart",
]:
    text = read(path)
    text, count = re.subn(
        r"context\.l10n\.errorWithMessage\('\$[A-Za-z_]+'\)",
        "context.l10n.genericLoadError",
        text,
    )
    if count < 1:
        raise RuntimeError(f"{path}: raw error UI pattern not found")
    write(path, text)

replace_once(
    "lib/presentation/providers/game_actions.dart",
    "import 'package:flutter_riverpod/flutter_riverpod.dart';",
    "import 'package:flutter/material.dart';\n"
    "import 'package:flutter_riverpod/flutter_riverpod.dart';",
)
replace_once(
    "lib/presentation/providers/game_actions.dart",
    "import 'play_notifier.dart';",
    "import '../l10n_mappers.dart';\nimport 'play_notifier.dart';",
)
shared_hint = r'''

/// Shows the same franchise-near-miss feedback in every game mode.
void showFranchiseHint(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.franchiseHint,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF8B6914),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
'''
marker = "\n/// Charges one ticket and then runs [start].\n"
text = read("lib/presentation/providers/game_actions.dart")
if text.count(marker) != 1:
    raise RuntimeError("game_actions.dart: start marker not unique")
write("lib/presentation/providers/game_actions.dart", text.replace(marker, shared_hint + marker, 1))

snackbar_pattern = (
    r"      if \(next\.lastGuessOutcome == GuessOutcome\.franchise &&\n"
    r"          next\.guessCount != prev\?\.guessCount\) \{\n"
    r"        ScaffoldMessenger\.of\(context\)\.showSnackBar\(.*?\n"
    r"        \);\n"
    r"      \}"
)
for path in [
    "lib/presentation/screens/game_screen.dart",
    "lib/presentation/screens/visual_screen.dart",
]:
    sub_once(
        path,
        snackbar_pattern,
        "      if (next.lastGuessOutcome == GuessOutcome.franchise &&\n"
        "          next.guessCount != prev?.guessCount) {\n"
        "        showFranchiseHint(context);\n"
        "      }",
        flags=re.S,
    )

# ---------------------------------------------------------------------------
# Focused regression tests: DB retry, exact ticket rollback, streak rollback.
# ---------------------------------------------------------------------------
write(
    "test/database_helper_retry_test.dart",
    r'''import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/datasources/database_helper.dart';

void main() {
  test('database initialization preserves the original error and retries', () async {
    sqfliteFfiInit();
    var attempts = 0;
    final helper = DatabaseHelper.forTesting(() async {
      attempts++;
      if (attempts == 1) throw StateError('original database failure');
      return databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    });

    await expectLater(
      helper.database,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'original database failure',
        ),
      ),
    );

    final db = await helper.database;
    expect(attempts, 2);
    await db.close();
  });
}
''',
)

write(
    "test/ticket_notifier_test.dart",
    r'''import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/core/utils/daily_selector.dart';
import 'package:cineus/presentation/providers/ticket_notifier.dart';

import 'support/test_database.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openTestDatabase();
    await db.execute('''
      CREATE TABLE player_tickets (
        id INTEGER PRIMARY KEY,
        daily_tickets INTEGER NOT NULL,
        extra_tickets INTEGER NOT NULL,
        last_reset_date TEXT NOT NULL
      )
    ''');
    await db.insert('player_tickets', {
      'id': 1,
      'daily_tickets': 2,
      'extra_tickets': 3,
      'last_reset_date': DailySelector.todayKey(),
    });
  });

  tearDown(() async => db.close());

  test('refund restores the exact daily/extra buckets that were debited', () async {
    final notifier = TicketNotifier(TestDatabaseProvider(db));

    final debit = await notifier.debitTickets(count: 4);
    expect(debit, isNotNull);
    expect(debit!.dailyTickets, 2);
    expect(debit.extraTickets, 2);
    expect(notifier.state.dailyTickets, 0);
    expect(notifier.state.extraTickets, 1);

    await notifier.refundDebit(debit);
    expect(notifier.state.dailyTickets, 2);
    expect(notifier.state.extraTickets, 3);

    final stored = (await db.query('player_tickets')).single;
    expect(stored['daily_tickets'], 2);
    expect(stored['extra_tickets'], 3);
  });

  test('insufficient balance does not mutate state', () async {
    final notifier = TicketNotifier(TestDatabaseProvider(db));
    final debit = await notifier.debitTickets(count: 99);
    expect(debit, isNull);
    expect(notifier.state.total, 5);
  });
}
''',
)

write(
    "test/reward_rollback_test.dart",
    r'''import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/domain/entities/player_tickets.dart';
import 'package:cineus/domain/entities/ticket_reward.dart';
import 'package:cineus/domain/repositories/game_repository.dart';
import 'package:cineus/domain/repositories/reward_repository.dart';
import 'package:cineus/domain/repositories/stage_repository.dart';
import 'package:cineus/presentation/providers/reward_notifier.dart';

void main() {
  RewardNotifier build(RewardRepository rewards) => RewardNotifier(
        rewards: rewards,
        stages: _UnusedStageRepository(),
        games: _UnusedGameRepository(),
        credit: (_) async {},
      );

  test('streak freeze refunds the exact debit when repository rejects it', () async {
    final notifier = build(_RejectingRewardRepository());
    TicketDebit? refunded;

    final ok = await notifier.freezeMissedDay(
      date: '2026-08-10',
      charge: (_) async =>
          const TicketDebit(dailyTickets: 2, extraTickets: 1),
      refund: (debit) async => refunded = debit,
    );

    expect(ok, isFalse);
    expect(refunded?.dailyTickets, 2);
    expect(refunded?.extraTickets, 1);
  });

  test('streak freeze refunds when repository throws', () async {
    final notifier = build(_ThrowingRewardRepository());
    var refundCount = 0;

    final ok = await notifier.freezeMissedDay(
      date: '2026-08-10',
      charge: (_) async =>
          const TicketDebit(dailyTickets: 3, extraTickets: 0),
      refund: (debit) async => refundCount += debit.total,
    );

    expect(ok, isFalse);
    expect(refundCount, 3);
  });
}

class _RejectingRewardRepository implements RewardRepository {
  @override
  Future<bool> freezeStreakDay(String date) async => false;

  @override
  Future<Set<String>> streakFreezes() async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingRewardRepository implements RewardRepository {
  @override
  Future<bool> freezeStreakDay(String date) async => throw StateError('disk full');

  @override
  Future<Set<String>> streakFreezes() async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedStageRepository implements StageRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedGameRepository implements GameRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''',
)

# Add a source-database content refresh test to guard A29.
content_test = read("test/content_upgrade_test.dart")
anchor = "  group('syncStages — aditivo, nunca destrutivo', () {"
new_test = r'''  group('refresh a partir do SQLite empacotado', () {
    test('atualiza catálogo sem depender do seed JSON mobile', () async {
      await seeder.ensureStagesAndTickets(db);
      await seeder.ensureAppMetaTable(db);

      final source = await factory.openDatabase(inMemoryDatabasePath);
      addTearDown(source.close);
      await source.execute(_bundledMoviesSchema);
      await source.execute('''
        CREATE TABLE clues (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movie_id INTEGER NOT NULL,
          clue_number INTEGER NOT NULL,
          category TEXT NOT NULL,
          text TEXT NOT NULL
        )
      ''');
      await source.insert('movies', {
        'id': 42,
        'tmdb_id': 90042,
        'title': 'Catálogo Novo',
      });
      await source.insert('clues', {
        'movie_id': 42,
        'clue_number': 1,
        'category': 'Conceito',
        'text': 'Nova dica',
      });

      expect(
        await seeder.refreshContentFromDatabaseIfStale(db, source),
        isTrue,
      );
      expect((await db.query('movies', where: 'id = 42')).single['title'],
          'Catálogo Novo');
      expect((await db.query('clues', where: 'movie_id = 42')).length, 1);
      expect(
        await seeder.readContentVersion(db),
        AppConstants.contentVersion,
      );
    });
  });

'''
if content_test.count(anchor) != 1:
    raise RuntimeError("content_upgrade_test.dart anchor missing")
write("test/content_upgrade_test.dart", content_test.replace(anchor, new_test + anchor, 1))

# ---------------------------------------------------------------------------
# Convert all posters once. Quality 84 preserves visual detail while materially
# reducing bundle size; method=6 favors compression over encoding speed.
# ---------------------------------------------------------------------------
poster_dir = ROOT / "assets/posters"
jpgs = sorted(poster_dir.glob("*.jpg"))
if jpgs:
    before = sum(p.stat().st_size for p in jpgs)
    for jpg in jpgs:
        webp = jpg.with_suffix(".webp")
        with Image.open(jpg) as image:
            image = ImageOps.exif_transpose(image).convert("RGB")
            image.save(webp, "WEBP", quality=84, method=6)
        jpg.unlink()
    after = sum(p.stat().st_size for p in poster_dir.glob("*.webp"))
    print(f"posters: {len(jpgs)} converted; {before / 1024 / 1024:.1f} MiB -> {after / 1024 / 1024:.1f} MiB")
elif not list(poster_dir.glob("*.webp")):
    raise RuntimeError("No poster assets found")

for path in [
    "lib/presentation/providers/play_notifier.dart",
    "lib/presentation/screens/generic_stage_detail_screen.dart",
    "lib/presentation/widgets/poster_card_widget.dart",
    "test/play_notifier_test.dart",
]:
    text = read(path)
    if ".jpg" not in text and ".webp" in text:
        continue
    write(path, text.replace(".jpg", ".webp"))

# ---------------------------------------------------------------------------
# Sanity assertions before Flutter tooling runs.
# ---------------------------------------------------------------------------
assert not (ROOT / "assets/cineus_v1_seed.json").exists()
assert (ROOT / "web/cineus_v1_seed.json").exists()
assert "assets/cineus_v1_seed.json" not in read("pubspec.yaml")
assert "path_provider:" not in read("pubspec.yaml")
assert "cupertino_icons:" not in read("pubspec.yaml")
assert "e.toString()" not in "\n".join(
    p.read_text(encoding="utf-8")
    for p in (ROOT / "lib/presentation").rglob("*.dart")
)
for p in (ROOT / "lib").rglob("*.dart"):
    assert "assets/posters/" not in p.read_text(encoding="utf-8") or ".jpg" not in p.read_text(encoding="utf-8")

print("release-hardening source patches applied")
