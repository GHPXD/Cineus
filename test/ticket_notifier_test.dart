import 'package:flutter_test/flutter_test.dart';
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

  test(
    'refund restores the exact daily/extra buckets that were debited',
    () async {
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
    },
  );

  test('insufficient balance does not mutate state', () async {
    final notifier = TicketNotifier(TestDatabaseProvider(db));
    final debit = await notifier.debitTickets(count: 99);
    expect(debit, isNull);
    expect(notifier.state.total, 5);
  });
}
