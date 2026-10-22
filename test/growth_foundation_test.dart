import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/utils/daily_selector.dart';
import 'package:cineus/core/utils/friend_code.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/datasources/journey_schema.dart';
import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/data/repositories/progress_repository.dart';
import 'package:cineus/data/repositories/economy_repository.dart';
import 'package:cineus/data/repositories/journey_repository.dart';
import 'package:cineus/data/repositories/color_repository.dart';
import 'package:cineus/data/repositories/interstitial_repository.dart';
import 'package:cineus/data/services/growth_gateway.dart';
import 'package:cineus/data/services/paid_ticket_wallet.dart';
import 'package:cineus/data/services/population_telemetry.dart';
import 'package:cineus/data/services/progress_backup.dart';
import 'package:cineus/domain/entities/daily_calendar.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/domain/services/product_telemetry.dart';
import 'package:cineus/presentation/providers/ticket_notifier.dart';
import 'package:cineus/presentation/widgets/share_grid_widget.dart';
import 'color_training_session_test.dart' show trainingFixture;
import 'color_persistence_test.dart' show finishColors;
import 'support/test_database.dart';

class _Gateway extends Fake implements GrowthGateway {
  final List<String> actions = [];
  @override
  Future<Map<String, dynamic>> command(
    String action, [
    Map<String, Object?> data = const {},
  ]) async {
    actions.add(action);
    return {
      'accepted': [
        for (final e in data['events'] as List? ?? []) (e as Map)['id'],
      ],
    };
  }
}

class _Wallet extends Fake implements PaidTicketWallet {
  int balance = 4, committed = 0, refunded = 0;
  @override
  Future<int> refresh() async => balance;
  @override
  Future<String> reserve(int amount) async {
    if (balance < amount) throw StateError('No balance');
    balance -= amount;
    return 'test';
  }

  @override
  Future<void> commit(String operation) async {
    committed++;
  }

  @override
  Future<void> refund(String operation) async {
    refunded++;
    balance++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'published daily windows are distinct and independent of current catalog order',
    () {
      final calendar = DailyCalendar.fromJson(
        jsonDecode(File('assets/daily/calendar_v1.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(calendar.days, hasLength(1500));
      for (final mode in GameMode.values) {
        expect(
          calendar.days.values.take(500).map((d) => d[mode]).toSet(),
          hasLength(500),
        );
      }
      expect(calendar.movie(GameMode.clue, '2026-10-19'), isNull);
      expect(
        DailySelector.movieIndexForDate(500, DateTime.utc(2026, 10, 20)),
        calendar.movie(GameMode.clue, '2026-10-20')! - 1,
      );
    },
  );
  test('perfect poster card is green relative to the five-point scale', () {
    final perfect = ShareGrid(
      revealedClues: 1,
      won: true,
      totalSteps: 5,
      score: 5,
    );
    expect(perfect.toEmojiGrid(), contains('🟩'));
    expect(
      ShareGrid(
        revealedClues: 3,
        won: true,
        totalSteps: 5,
        score: 3,
      ).toEmojiGrid(),
      contains('🟨'),
    );
    expect(
      ShareGrid(
        revealedClues: 5,
        won: true,
        totalSteps: 5,
        score: 1,
      ).toEmojiGrid(),
      contains('🟥'),
    );
  });
  test(
    'clock rollback never renews daily tickets; trusted reset gate blocks unverified future',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      await const DatabaseSeeder().ensureStagesAndTickets(db);
      var now = DateTime.utc(2026, 10, 19);
      var verified = true;
      final tickets = TicketNotifier(
        TestDatabaseProvider(db),
        now: () => now,
        canReset: () => verified,
      );
      addTearDown(tickets.dispose);
      await tickets.ready;
      await tickets.consumeTicket(count: 10);
      now = DateTime.utc(2026, 10, 18);
      await tickets.refreshBalance();
      expect(tickets.state.total, 0);
      verified = false;
      now = DateTime.utc(2030, 1, 1);
      await tickets.refreshBalance();
      expect(tickets.state.total, 0);
      verified = true;
      now = DateTime.utc(2026, 10, 20);
      await tickets.refreshBalance();
      expect(tickets.state.total, 10);
    },
  );
  test(
    'reward receipt and balance rollback together, then pay exactly once',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      await const DatabaseSeeder().ensureStagesAndTickets(db);
      final tickets = TicketNotifier(TestDatabaseProvider(db));
      addTearDown(tickets.dispose);
      await tickets.ready;
      await db.execute(
        "CREATE TRIGGER fail_credit BEFORE UPDATE ON player_tickets WHEN NEW.extra_tickets>OLD.extra_tickets BEGIN SELECT RAISE(ABORT,'disk'); END",
      );
      Future<bool> credit() => tickets.creditOnce(
        key: 'growth-test',
        amount: 2,
        verify: (_) async {},
      );
      await expectLater(credit(), throwsA(anything));
      expect(await db.query('ticket_rewards'), isEmpty);
      await db.execute('DROP TRIGGER fail_credit');
      expect(
        (await Future.wait([credit(), credit()])).where((v) => v),
        hasLength(1),
      );
      expect(tickets.state.extraTickets, 2);
    },
  );
  test(
    'archives and practice do not replace daily results; all contexts and presence include losses',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final provider = TestDatabaseProvider(db);
      final games = GameRepositoryImpl(
        provider,
        now: () => DateTime.utc(2026, 10, 19),
      );
      for (final kind in SessionKind.values) {
        await games.saveSession(
          GameSession(
            mode: GameMode.clue,
            kind: kind,
            date: '2026-10-18',
            stageId: kind == SessionKind.stage ? 1 : 0,
            movieId: 1,
            status: GameStatus.lost,
          ),
        );
      }
      final progress = ProgressRepository(
        provider,
        () => DateTime.utc(2026, 10, 19),
      );
      expect(
        await progress.films(GameMode.clue, ActivityScope.all),
        hasLength(5),
      );
      expect(
        await progress.films(GameMode.clue, ActivityScope.practice),
        hasLength(2),
      );
      expect(
        (await games.getDailySession(GameMode.clue, '2026-10-18'))!.kind,
        SessionKind.daily,
      );
      expect((await progress.presence()).current, 1);
    },
  );
  test(
    'existing stage contract stays ten; new treatment stays four across config changes',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final provider = TestDatabaseProvider(db);
      await GameRepositoryImpl(provider).saveSession(
        GameSession.stage(mode: GameMode.clue, stageId: 1, movieId: 1),
      );
      final economy = EconomyRepository(provider);
      expect(await economy.pin('clue', 1, 4), 10);
      expect(await economy.pin('clue', 2, 4), 4);
      expect(await economy.pin('clue', 2, 10), 4);
    },
  );
  test(
    'weekly objectives and rewards rotate; duplicate compensation survives delivery retry',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      await const DatabaseSeeder().ensureStagesAndTickets(db);
      var now = DateTime.utc(2026, 10, 19, 12);
      final provider = TestDatabaseProvider(db);
      final journey = JourneyRepository(provider, () => now);
      final first = (await journey.load()).missions.first;
      expect(first.target, 5);
      expect(
        PlayerCollectionCatalog.items.any((i) => i.id == first.item),
        isTrue,
      );
      await db.insert('collection_ownership', {
        'item_id': first.item,
        'source_id': 'already',
        'granted_at': now.toIso8601String(),
      });
      for (var i = 0; i < 5; i++) {
        await JourneySchema.finish(
          db,
          key: 'game:$i',
          mode: 'clue',
          kind: 'stage',
          at: now,
          scoreCents: 0,
        );
      }
      expect(await journey.claim('play'), isTrue);
      expect(await journey.claim('play'), isFalse);
      final tickets = TicketNotifier(provider, now: () => now);
      addTearDown(tickets.dispose);
      await tickets.ready;
      Future<bool> credit(String key, int amount) =>
          tickets.creditOnce(key: key, amount: amount, verify: (_) async {});
      await journey.deliver(credit);
      await journey.deliver(credit);
      expect(tickets.state.extraTickets, 2);
      now = now.add(const Duration(days: 7));
      expect((await journey.load()).missions.first.item, isNot(first.item));
    },
  );
  test(
    'cancelled or expired ad reservation does not consume impression cap',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      var now = DateTime.utc(2026, 10, 19);
      final repo = InterstitialRepository(
        TestDatabaseProvider(db),
        () => now,
        holdout: () => false,
      );
      for (var i = 0; i < 4; i++) {
        await repo.foreground();
        now = now.add(const Duration(minutes: 31));
        await JourneySchema.finish(
          db,
          key: 'film:$i',
          mode: 'clue',
          kind: 'stage',
          at: now,
          scoreCents: 0,
        );
      }
      Future<bool> reserve() =>
          repo.reserve('film:3', rightsKnown: true, paid: false, ready: true);
      expect(await reserve(), isTrue);
      await repo.cancel('film:3');
      expect(await reserve(), isTrue);
      now = now.add(const Duration(minutes: 3));
      expect(await reserve(), isTrue);
      await repo.shown('film:3');
      await repo.cancel('film:3');
      expect(await reserve(), isFalse);
    },
  );
  test(
    'metrics never queue without consent and erasure instruction remains durable',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final api = _Gateway();
      final metrics = PopulationTelemetry(
        TestDatabaseProvider(db),
        () => DateTime.utc(2026, 10, 19),
        () => api,
      );
      await metrics.record('app_active');
      expect(await db.query('metrics_outbox'), isEmpty);
      await metrics.setConsent(true);
      await metrics.record(
        'game_opened',
        properties: {'mode': 'colors', 'kind': 'archive', 'guess': 'secret'},
      );
      expect(
        (await db.query('metrics_outbox')).single['properties'],
        isNot(contains('secret')),
      );
      await metrics.flush();
      expect(await db.query('metrics_outbox'), isEmpty);
      await metrics.setConsent(false);
      expect((await db.query('metrics_preferences')).single['pending'], 1);
      await metrics.flush();
      expect((await db.query('metrics_preferences')).single['pending'], 0);
    },
  );
  test(
    'backup merge preserves finished games, remaps IDs, rejects financial tables and deduplicates color packs',
    () async {
      final source = await openTestDatabase(),
          target = await openTestDatabase();
      addTearDown(source.close);
      addTearDown(target.close);
      final src = TestDatabaseProvider(source),
          dst = TestDatabaseProvider(target);
      final games = GameRepositoryImpl(src);
      await games.saveSession(
        GameSession.daily(
          mode: GameMode.clue,
          date: '2026-10-18',
          movieId: 1,
        ).copyWith(status: GameStatus.won, score: 10),
      );
      final local = await GameRepositoryImpl(dst).saveSession(
        GameSession.daily(
          mode: GameMode.clue,
          date: '2026-10-18',
          movieId: 1,
        ).copyWith(status: GameStatus.lost),
      );
      final colors = ColorRepository(
        src,
        now: () => DateTime.utc(2026, 10, 19),
      );
      final started = await colors.start(
        trainingFixture(),
        ColorSessionKind.training,
      );
      final finished = await colors.save(
        started,
        finishColors(started.game.clone()),
      );
      await colors.review(finished);
      final backup = ProgressBackup(src, _Gateway());
      final data = await backup.export();
      expect(data['version'], 2);
      expect(data['catalogs'] as List, hasLength(1));
      await ProgressBackup(
        dst,
        _Gateway(),
      ).merge(Map<String, dynamic>.from(data));
      expect(
        (await GameRepositoryImpl(
          dst,
        ).getDailySession(GameMode.clue, '2026-10-18'))!.status,
        local.status,
      );
      expect(await ColorRepository(dst).list(), hasLength(2));
      await expectLater(
        ProgressBackup(dst, _Gateway()).merge({
          'version': 1,
          'tables': {'player_tickets': []},
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'paid buckets are separate and never become negative when local tickets run out',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      await const DatabaseSeeder().ensureStagesAndTickets(db);
      final wallet = _Wallet(),
          tickets = TicketNotifier(
            TestDatabaseProvider(db),
            paidWallet: () => wallet,
          );
      addTearDown(tickets.dispose);
      await tickets.ready;
      await tickets.consumeTicket(count: 10);
      await tickets.refreshPaidBalance();
      final debit = await tickets.debitTickets();
      expect(debit!.paid, 1);
      expect(tickets.state.extraTickets, 0);
      await tickets.refundDebit(debit);
      expect(wallet.refunded, 1);
      expect(tickets.state.paidTickets, 4);
    },
  );
  test(
    'friendly codes preserve case and reject arbitrary hosts and extra parameters',
    () {
      const code = 'aB123456_-de';
      expect(FriendCode.parse('cineus://friend/$code'), code);
      expect(FriendCode.parse('https://evil.test/friend/$code'), isNull);
      expect(FriendCode.parse('cineus://friend/$code?owner=someone'), isNull);
    },
  );
}
