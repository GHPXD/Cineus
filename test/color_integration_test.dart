import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/data/datasources/database_provider.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/repositories/color_repository.dart';
import 'package:cineus/domain/entities/color_stats.dart';
import 'package:cineus/domain/entities/color_training_session.dart';
import 'package:cineus/domain/entities/player_tickets.dart';
import 'package:cineus/l10n/app_l10n_en.dart';
import 'package:cineus/l10n/app_l10n_es.dart';
import 'package:cineus/l10n/app_l10n_pt.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'package:cineus/presentation/providers/ticket_notifier.dart';
import 'package:cineus/presentation/widgets/color_share_card.dart';
import 'color_training_session_test.dart' show trainingFixture, fixedTraining;
import 'color_persistence_test.dart' show finishColors;
import 'support/test_database.dart';

class ReadFailureDatabase implements Database {
  final Database delegate;
  bool failRead = false;
  ReadFailureDatabase(this.delegate);
  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    if (failRead && table == 'player_tickets') {
      return Future.error(StateError('Read failed after commit'));
    }
    return delegate.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) => delegate.transaction(action, exclusive: exclusive);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected DB call: ${invocation.memberName}');
}

class WrappedColorDatabase implements DatabaseProvider {
  final Database db;
  WrappedColorDatabase(this.db);
  @override
  Future<Database> get database async => db;
}

SavedColorSession statisticFixture({
  required String id,
  String? date,
  List<int> scores = const [100, 200, 300, 400, 500],
  int mean = 300,
  DateTime? updated,
  bool active = false,
}) {
  final catalog = trainingFixture();
  var game = fixedTraining(catalog);
  if (!active) {
    game = finishColors(game);
    final json = game.toJson();
    for (var i = 0; i < 5; i++) {
      (json['answers'] as List)[i]['score'] = scores[i];
    }
    json['average'] = mean;
    json['rule'] = 'historical-rule-v0';
    game = ColorTrainingSession.fromJson(json);
  }
  return SavedColorSession(
    id: id,
    kind: date == null ? ColorSessionKind.training : ColorSessionKind.daily,
    dailyDate: date,
    revision: 0,
    status: active ? 'active' : 'completed',
    createdAt: DateTime.utc(2026, 10, 13),
    updatedAt: updated ?? DateTime.utc(2026, 10, 13),
    catalog: catalog,
    game: game,
  );
}

void main() {
  sqfliteFfiInit();
  final catalog = trainingFixture();
  late Database db;
  late ColorRepository repo;
  late TicketNotifier tickets;
  var clock = DateTime.utc(2026, 10, 13, 15);
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await const DatabaseSeeder().ensureCanonicalSchema(db);
    clock = DateTime.utc(2026, 10, 13, 15);
    await db.insert('player_tickets', {
      'id': 1,
      'daily_tickets': 2,
      'extra_tickets': 7,
      'last_reset_date': '2026-10-13',
    });
    repo = ColorRepository(TestDatabaseProvider(db), now: () => clock);
    tickets = TicketNotifier(TestDatabaseProvider(db), now: () => clock);
    await tickets.ready;
  });
  tearDown(() async {
    tickets.dispose();
    await db.close();
  });
  Future<SavedColorSession> dailyDone() async {
    final start = await repo.start(catalog, ColorSessionKind.daily);
    return repo.save(start, finishColors(start.game.clone()));
  }

  test(
    'statistics separate kinds, exclude active games and use recorded cents',
    () {
      final results = [
        statisticFixture(
          id: 'd1',
          date: '2026-10-12',
          scores: [100, 200, 300, 400, 500],
          mean: 456,
        ),
        statisticFixture(
          id: 'd2',
          date: '2026-10-13',
          scores: [200, 400, 600, 800, 1000],
          mean: 789,
        ),
        statisticFixture(
          id: 't1',
          scores: [1000, 1000, 1000, 1000, 1000],
          mean: 1000,
        ),
        statisticFixture(id: 't2', active: true),
      ];
      final daily = ColorStats.fromSessions(results, ColorSessionKind.daily);
      expect(daily.games, 2);
      expect(daily.averageCents, 623);
      expect(daily.bestCents, 789);
      expect(daily.roundAverages, [150, 300, 450, 600, 750]);
      final training = ColorStats.fromSessions(
        results,
        ColorSessionKind.training,
      );
      expect(training.games, 1);
      expect(training.averageCents, 1000);
      expect(() => daily.roundAverages[0] = 0, throwsUnsupportedError);
    },
  );
  test(
    'statistics distinguish no results from a legitimate zero score and cap recent games',
    () {
      final empty = ColorStats.fromSessions([], ColorSessionKind.daily);
      expect(empty.averageCents, isNull);
      expect(empty.bestCents, isNull);
      final results = [
        for (var i = 0; i < 12; i++)
          statisticFixture(
            id: 't${i.toString().padLeft(2, '0')}',
            scores: [0, 0, 0, 0, 0],
            mean: 0,
          ),
      ];
      final stats = ColorStats.fromSessions(results, ColorSessionKind.training);
      expect(stats.games, 12);
      expect(stats.averageCents, 0);
      expect(stats.bestCents, 0);
      expect(stats.recent.length, 10);
      expect(stats.recent.first.id, 't11');
      expect(() => stats.recent.clear(), throwsUnsupportedError);
    },
  );
  test(
    'whitelisted share text excludes questions, choices, sources and IDs in PT/EN/ES',
    () {
      final result = statisticFixture(id: 'private-id', date: '2026-10-13');
      final share = ColorShareData.fromSession(result);
      for (final item in [
        (AppL10nPt(), 'pt'),
        (AppL10nEn(), 'en'),
        (AppL10nEs(), 'es'),
      ]) {
        final text = share.text(item.$1, item.$2);
        expect(text, contains('2026-10-13'));
        expect(text, contains('UTC'));
        expect(
          text.split('\n').where((line) => line.contains('/ 10')).length,
          6,
        );
        for (final q in result.game.questions) {
          expect(text, isNot(contains(q.id)));
          expect(text, isNot(contains(q.target.hex)));
          expect(text, isNot(contains(q.text('character', item.$2))));
          expect(text, isNot(contains(q.source.toString())));
        }
        expect(text, isNot(contains(result.id)));
        expect(text, isNot(contains('historical-rule')));
      }
      expect(() => share.scores.clear(), throwsUnsupportedError);
      expect(
        () => ColorShareData.fromSession(
          statisticFixture(id: 'active', active: true),
        ),
        throwsStateError,
      );
    },
  );
  test(
    'tutorial marker is idempotent, preserves flags and never creates a game',
    () async {
      await const DatabaseSeeder().writeMeta(db, 'other_flag', 'keep');
      expect(await repo.guideSeen(), false);
      await repo.markGuideSeen();
      await repo.markGuideSeen();
      expect(await repo.guideSeen(), true);
      expect(await repo.list(), isEmpty);
      expect(await const DatabaseSeeder().readMeta(db, 'other_flag'), 'keep');
    },
  );
  test(
    'completed daily pays exactly once across concurrent claims, reopens and migrations',
    () async {
      final done = await dailyDone();
      final snapshot = jsonEncode(done.game.toJson());
      final results = await Future.wait(
        List.generate(8, (_) => ColorRewards.claim(repo, tickets, done.id)),
      );
      expect(results.where((r) => r).length, 1);
      expect(tickets.state.extraTickets, 9);
      expect(
        (await db.query('ticket_rewards')).single['key'],
        'colors_daily_2026-10-13',
      );
      await const DatabaseSeeder().ensureCanonicalSchema(db);
      expect(await ColorRewards.claim(repo, tickets, done.id), false);
      expect(tickets.state.extraTickets, 9);
      expect(jsonEncode((await repo.load(done.id))!.game.toJson()), snapshot);
    },
  );
  test(
    'training and incomplete daily do not create a reward receipt',
    () async {
      var training = await repo.start(catalog, ColorSessionKind.training);
      training = await repo.save(training, finishColors(training.game.clone()));
      final active = await repo.start(catalog, ColorSessionKind.daily);
      await expectLater(
        ColorRewards.claim(repo, tickets, training.id),
        throwsStateError,
      );
      await expectLater(
        ColorRewards.claim(repo, tickets, active.id),
        throwsStateError,
      );
      expect(await db.query('ticket_rewards'), isEmpty);
      expect(tickets.state.extraTickets, 7);
    },
  );
  test(
    'failed credit rolls back receipt and can retry without changing the score',
    () async {
      final done = await dailyDone();
      final average = done.game.averageCents;
      await db.execute(
        "CREATE TRIGGER reject_color_credit BEFORE UPDATE OF extra_tickets ON player_tickets BEGIN SELECT RAISE(ABORT,'disk write failed'); END",
      );
      await expectLater(
        ColorRewards.claim(repo, tickets, done.id),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('ticket_rewards'), isEmpty);
      expect((await db.query('player_tickets')).single['extra_tickets'], 7);
      expect((await repo.load(done.id))!.game.averageCents, average);
      await db.execute('DROP TRIGGER reject_color_credit');
      expect(await ColorRewards.claim(repo, tickets, done.id), true);
      expect(await ColorRewards.claim(repo, tickets, done.id), false);
      expect(tickets.state.extraTickets, 9);
    },
  );
  test(
    'failed balance refresh after commit blocks stale debits and retry does not repay',
    () async {
      final wrapper = ReadFailureDatabase(db);
      final notifier = TicketNotifier(
        WrappedColorDatabase(wrapper),
        now: () => clock,
      );
      addTearDown(notifier.dispose);
      await notifier.ready;
      await expectLater(
        notifier.creditOnce(
          key: 'colors_daily_2026-10-13',
          amount: 2,
          verify: (tx) async {
            wrapper.failRead = true;
          },
        ),
        throwsStateError,
      );
      expect((await db.query('player_tickets')).single['extra_tickets'], 9);
      expect((await db.query('ticket_rewards')).length, 1);
      await expectLater(notifier.debitTickets(count: 4), throwsStateError);
      wrapper.failRead = false;
      await notifier.refreshBalance();
      expect(
        await notifier.creditOnce(
          key: 'colors_daily_2026-10-13',
          amount: 2,
          verify: (tx) async {},
        ),
        false,
      );
      expect(notifier.state.extraTickets, 9);
    },
  );
  test(
    'reward shares the same queue as debit and exact refund, without lost credit',
    () async {
      final done = await dailyDone();
      final results = await Future.wait<Object?>([
        ColorRewards.claim(repo, tickets, done.id),
        tickets.debitTickets(count: 4),
      ]);
      expect(results.first, true);
      expect(tickets.state.total, 7);
      final debit = results.last as TicketDebit;
      await tickets.refundDebit(debit);
      expect(tickets.state.dailyTickets, 2);
      expect(tickets.state.extraTickets, 9);
    },
  );
  test(
    'old daily rewards keep their challenge date and earned tickets survive UTC reset',
    () async {
      var old = await repo.start(catalog, ColorSessionKind.daily);
      clock = DateTime.utc(2026, 10, 14, 1);
      old = await repo.save(old, finishColors(old.game.clone()));
      final today = await dailyDone();
      await ColorRewards.claim(repo, tickets, old.id);
      await ColorRewards.claim(repo, tickets, today.id);
      expect(tickets.state.extraTickets, 11);
      expect(tickets.state.dailyTickets, 10);
      final keys = (await db.query(
        'ticket_rewards',
      )).map((r) => r['key']).toSet();
      expect(keys, {'colors_daily_2026-10-13', 'colors_daily_2026-10-14'});
      expect(await ColorRewards.claim(repo, tickets, old.id), false);
    },
  );
  test(
    'legacy rewards remain separate and an incompatible receipt is not silently replaced',
    () async {
      await db.insert('ticket_rewards', {
        'key': 'daily_win_clue_2026-10-13',
        'amount': 2,
        'awarded_at': clock.toIso8601String(),
      });
      final done = await dailyDone();
      await db.insert('ticket_rewards', {
        'key': 'colors_daily_2026-10-13',
        'amount': 99,
        'awarded_at': clock.toIso8601String(),
      });
      await expectLater(
        ColorRewards.claim(repo, tickets, done.id),
        throwsStateError,
      );
      expect((await db.query('ticket_rewards')).length, 2);
      expect(tickets.state.extraTickets, 7);
    },
  );
}
