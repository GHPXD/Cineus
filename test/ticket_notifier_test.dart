import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/datasources/database_provider.dart';
import 'package:cineus/presentation/providers/ticket_notifier.dart';

import 'support/test_database.dart';

class RetryDatabase implements DatabaseProvider {
  final Database db;
  bool failed = true;
  RetryDatabase(this.db);
  @override
  Future<Database> get database async {
    if (failed) throw StateError('Temporary read failure');
    return db;
  }
}

void main() {
  late Database db;
  late DateTime now;
  late TicketNotifier tickets;

  setUp(() async {
    db = await openTestDatabase(withMovies: true);
    await const DatabaseSeeder().ensureStagesAndTickets(db);
    now = DateTime.utc(2026, 9, 10, 12);
    tickets = TicketNotifier(TestDatabaseProvider(db), now: () => now);
  });

  tearDown(() async {
    tickets.dispose();
    await db.close();
  });

  test(
    'consumos simultâneos são serializados e nunca gastam o mesmo saldo',
    () async {
      final results = await Future.wait(
        List.generate(11, (_) => tickets.consumeTicket()),
      );

      expect(results.where((ok) => ok).length, 10);
      expect(results.where((ok) => !ok).length, 1);
      expect(tickets.state.total, 0);

      final row = (await db.query('player_tickets')).single;
      expect(row['daily_tickets'], 0);
      expect(row['extra_tickets'], 0);
    },
  );

  test(
    'recibo permite estornar exatamente uma cobrança do mesmo dia',
    () async {
      final debit = await tickets.debitTickets(count: 3);
      expect(debit, isNotNull);
      expect(debit!.daily, 3);
      expect(debit.extra, 0);
      expect(tickets.state.dailyTickets, 7);

      await tickets.refundDebit(debit);
      expect(tickets.state.dailyTickets, 10);
      expect(tickets.state.extraTickets, 0);
    },
  );

  test(
    'estorno preserva tickets extras quando a cobrança veio deles',
    () async {
      expect(await tickets.consumeTicket(count: 10), isTrue);
      await tickets.addTickets(5);

      final debit = await tickets.debitTickets(count: 3);
      expect(debit!.daily, 0);
      expect(debit.extra, 3);
      expect(tickets.state.extraTickets, 2);

      await tickets.refundDebit(debit);
      expect(tickets.state.dailyTickets, 0);
      expect(tickets.state.extraTickets, 5);
    },
  );

  test('virada de UTC reseta a diária mesmo sem recriar o notifier', () async {
    expect(await tickets.consumeTicket(count: 5), isTrue);
    expect(tickets.state.dailyTickets, 5);

    now = DateTime.utc(2026, 9, 11, 0, 1);
    await tickets.addTickets(2);

    expect(tickets.state.lastResetDate, '2026-09-11');
    expect(tickets.state.dailyTickets, 10);
    expect(tickets.state.extraTickets, 2);
  });

  test(
    'estorno depois da virada devolve a cobrança como ticket extra',
    () async {
      final debit = await tickets.debitTickets();
      expect(tickets.state.dailyTickets, 9);

      now = DateTime.utc(2026, 9, 11, 0, 1);
      await tickets.refundDebit(debit!);

      expect(tickets.state.dailyTickets, 10);
      expect(tickets.state.extraTickets, 1);
      expect(tickets.state.total, 11);
    },
  );

  test(
    'refresh sem gasto repõe diária e conserva bônus na virada UTC',
    () async {
      await tickets.addTickets(4);
      await tickets.consumeTicket(count: 6);
      now = DateTime.utc(2026, 9, 11);
      await tickets.refreshBalance();
      expect(tickets.state.dailyTickets, 10);
      expect(tickets.state.extraTickets, 4);
      expect(tickets.state.lastResetDate, '2026-09-11');
    },
  );

  test('refresh concorrente não apaga débito ou bônus pendente', () async {
    await Future.wait([
      tickets.addTickets(4),
      tickets.refreshBalance(),
      tickets.consumeTicket(count: 5),
      tickets.refreshBalance(),
    ]);
    expect(tickets.state.dailyTickets, 5);
    expect(tickets.state.extraTickets, 4);
    final row = (await db.query('player_tickets')).single;
    expect(row['daily_tickets'], 5);
    expect(row['extra_tickets'], 4);
  });

  test(
    'falha inicial é recuperável e bloqueia gasto do saldo fictício',
    () async {
      await tickets.ready;
      final storage = RetryDatabase(db);
      final states = <bool>[];
      final retry = TicketNotifier(
        storage,
        now: () => now,
        onLoadStateChanged: (state) => states.add(state.hasError),
      );
      try {
        await retry.ready;
        expect(states.last, isTrue);
        await expectLater(retry.consumeTicket(), throwsStateError);
        storage.failed = false;
        await retry.refreshBalance();
        expect(states.last, isFalse);
        expect(await retry.consumeTicket(), isTrue);
        expect(retry.state.total, 9);
      } finally {
        retry.dispose();
      }
    },
  );
}
