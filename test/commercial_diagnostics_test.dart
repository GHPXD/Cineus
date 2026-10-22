import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineus/domain/entities/commercial_configuration.dart';
import 'package:cineus/domain/entities/player_audience.dart';
import 'package:cineus/presentation/providers/audience_provider.dart';
import 'package:cineus/presentation/providers/commercial_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/telemetry_provider.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/datasources/ticket_audit.dart';
import 'package:cineus/data/services/local_product_telemetry.dart';
import 'package:cineus/presentation/providers/ticket_notifier.dart';
import 'support/test_database.dart';

class _BrokenTelemetry implements ProductTelemetry {
  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) => Future.error(StateError('Diagnostics unavailable'));
}

void main() {
  test(
    'real provider flows emit local events without exposing movie data',
    () async {
      final db = await openTestDatabase(withMovies: true);
      addTearDown(db.close);
      await const DatabaseSeeder().ensureStagesAndTickets(db);
      await db.insert('movies', {
        'id': 1,
        'tmdb_id': 1001,
        'title': 'Private movie title',
      });
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
          playerAudienceProvider.overrideWith(
            (_) async => PlayerAudience.adult,
          ),
          commercialConfigurationProvider.overrideWithValue(
            const CommercialConfiguration(localMetrics: true),
          ),
          appClockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 14)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(playerAudienceProvider.future);
      await container.read(usageDataServiceProvider).setConsent(true);
      final tickets = container.read(ticketNotifierProvider.notifier);
      await tickets.ready;
      await tickets.consumeTicket(count: 10);
      expect(await tickets.debitTickets(), isNull);
      expect(
        await container.read(clueGameProvider.notifier).loadChallenge(1),
        isTrue,
      );
      final telemetry = LocalProductTelemetry(TestDatabaseProvider(db));
      List<Map<String, Object?>> summary = [];
      for (var i = 0; i < 20; i++) {
        summary = await telemetry.summary();
        if (summary.length == 2) break;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(summary.map((r) => r['event']).toSet(), {
        'tickets_insufficient',
        'game_opened',
      });
      expect(
        (await db.query('product_events')).toString(),
        isNot(contains('Private movie title')),
      );
      expect(tickets.state.total, 0);
    },
  );

  test(
    'telemetry strips private/unbounded values and ignores unknown events',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final telemetry = LocalProductTelemetry(TestDatabaseProvider(db));
      await telemetry.record(
        'game_completed',
        properties: {
          'mode': 'colors',
          'kind': 'stage',
          'score_cents': 900,
          'guesses': ['secret'],
          'receipt': 'secret',
          'player_name': 'secret',
          'outcome': "' OR 1=1--",
          'revealed_steps': -100,
        },
      );
      await telemetry.record(
        'private_unknown_event',
        properties: {'secret': 'secret'},
      );
      final rows = await db.query('product_events');
      expect(rows, hasLength(1));
      expect(jsonDecode(rows.single['properties'] as String), {
        'mode': 'colors',
        'kind': 'stage',
        'score_cents': 900,
      });
      await _BrokenTelemetry().record('game_completed');
    },
  );

  test(
    'local events expire and retain only the newest bounded sample',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      var now = DateTime.utc(2026, 10, 14);
      final telemetry = LocalProductTelemetry(
        TestDatabaseProvider(db),
        now: () => now,
      );
      await telemetry.record('app_active');
      now = now.add(const Duration(days: 61));
      expect(await telemetry.summary(), isEmpty);
      final batch = db.batch();
      for (var i = 0; i < LocalProductTelemetry.maxEvents + 10; i++) {
        batch.insert('product_events', {
          'event': 'app_active',
          'occurred_at': now.toIso8601String(),
          'properties': '{}',
        });
      }
      await batch.commit(noResult: true);
      await telemetry.record(
        'tutorial_completed',
        properties: {'mode': 'clue'},
      );
      expect(
        await db.query('product_events'),
        hasLength(LocalProductTelemetry.maxEvents),
      );
    },
  );

  test(
    'debits, refunds, bonus and UTC reset keep an auditable balance',
    () async {
      final db = await openTestDatabase(withMovies: true);
      addTearDown(db.close);
      await const DatabaseSeeder().ensureStagesAndTickets(db);
      var now = DateTime.utc(2026, 10, 14, 12);
      final tickets = TicketNotifier(
        TestDatabaseProvider(db),
        now: () => now,
        telemetry: _BrokenTelemetry(),
      );
      addTearDown(tickets.dispose);
      await tickets.ready;
      final debit = await tickets.debitTickets(count: 3);
      await tickets.refundDebit(debit!);
      await tickets.addTickets(5);
      expect(await tickets.debitTickets(count: 99), isNull);
      now = now.add(const Duration(days: 1));
      await tickets.refreshBalance();
      expect(tickets.state.total, 15);
      final sums = await db.rawQuery(
        'SELECT SUM(daily_delta) AS daily, SUM(extra_delta) AS extra FROM ticket_movements',
      );
      expect(sums.single['daily'], tickets.state.dailyTickets);
      expect(sums.single['extra'], tickets.state.extraTickets);
      expect(
        await db.query(
          'ticket_movements',
          where: 'reason = ?',
          whereArgs: ['debit'],
        ),
        hasLength(1),
      );
    },
  );

  test(
    'failed audit rolls back balance and a retry does not lose tickets',
    () async {
      final db = await openTestDatabase(withMovies: true);
      addTearDown(db.close);
      await const DatabaseSeeder().ensureStagesAndTickets(db);
      final tickets = TicketNotifier(TestDatabaseProvider(db));
      addTearDown(tickets.dispose);
      await tickets.ready;
      await db.execute(
        "CREATE TRIGGER fail_audit BEFORE INSERT ON ticket_movements BEGIN SELECT RAISE(ABORT, 'disk full simulation'); END",
      );
      await expectLater(tickets.debitTickets(), throwsA(anything));
      expect(tickets.state.total, 10);
      expect((await db.query('player_tickets')).single['daily_tickets'], 10);
      await db.execute('DROP TRIGGER fail_audit');
      expect(await tickets.consumeTicket(), isTrue);
      expect(tickets.state.total, 9);
    },
  );

  test(
    'verified reward and audit commit once together; migration preserves saved balance',
    () async {
      final db = await openTestDatabase(withMovies: true);
      addTearDown(db.close);
      const seeder = DatabaseSeeder();
      await seeder.ensureStagesAndTickets(db);
      await db.insert('player_tickets', {
        'id': 1,
        'daily_tickets': 7,
        'extra_tickets': 8,
        'last_reset_date': '2026-10-14',
      });
      await seeder.ensureStagesAndTickets(db);
      final tickets = TicketNotifier(
        TestDatabaseProvider(db),
        now: () => DateTime.utc(2026, 10, 14),
      );
      addTearDown(tickets.dispose);
      await tickets.ready;
      expect(tickets.state.total, 15);
      Future<bool> grant() => tickets.creditOnce(
        key: 'verified_test',
        amount: 2,
        verify: (_) async {},
      );
      expect(await grant(), isTrue);
      expect(await grant(), isFalse);
      expect(tickets.state.total, 17);
      expect(
        await db.query(
          'ticket_movements',
          where: 'reason = ?',
          whereArgs: ['verifiedReward'],
        ),
        hasLength(1),
      );
      expect(await TicketAudit.summary(db), isNotEmpty);
    },
  );
}
