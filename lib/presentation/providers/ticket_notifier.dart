import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../data/datasources/database_provider.dart';
import '../../domain/entities/player_tickets.dart';

class TicketNotifier extends StateNotifier<PlayerTickets> {
  final DatabaseProvider _db;

  /// Completes once the stored balance has been read.
  ///
  /// Every mutation awaits this. Without it, tapping "Jogar" before the initial
  /// read finished debited the optimistic default (20) and the load then
  /// overwrote the result, silently refunding the ticket.
  late final Future<void> _ready;

  TicketNotifier(this._db)
    : super(
        PlayerTickets(
          dailyTickets: PlayerTickets.maxDailyTickets,
          lastResetDate: DailySelector.todayKey(),
        ),
      ) {
    _ready = _load();
  }

  Future<void> _load() async {
    final db = await _db.database;
    final rows = await db.query('player_tickets', where: 'id = 1');

    final today = DailySelector.todayKey();

    if (rows.isEmpty) {
      final fresh = PlayerTickets(
        dailyTickets: PlayerTickets.maxDailyTickets,
        lastResetDate: today,
      );
      await db.insert('player_tickets', {
        'id': 1,
        'daily_tickets': fresh.dailyTickets,
        'extra_tickets': fresh.extraTickets,
        'last_reset_date': fresh.lastResetDate,
      });
      state = fresh;
      return;
    }

    final row = rows.first;
    final lastReset = row['last_reset_date'] as String;

    if (lastReset != today) {
      // New day — reset daily tickets, keep extras
      final updated = PlayerTickets(
        dailyTickets: PlayerTickets.maxDailyTickets,
        extraTickets: row['extra_tickets'] as int,
        lastResetDate: today,
      );
      await _persist(updated);
      state = updated;
    } else {
      state = PlayerTickets(
        dailyTickets: row['daily_tickets'] as int,
        extraTickets: row['extra_tickets'] as int,
        lastResetDate: lastReset,
      );
    }
  }

  /// Debits [count] tickets and returns an exact receipt for rollback.
  ///
  /// Daily tickets are spent first so earned tickets remain the balance that
  /// carries across days. Returning the split matters: a failed operation must
  /// restore the same buckets instead of turning a daily ticket into an extra.
  Future<TicketDebit?> debitTickets({int count = 1}) async {
    if (count <= 0) {
      return const TicketDebit(dailyTickets: 0, extraTickets: 0);
    }
    await _ready;
    if (state.total < count) return null;

    final fromDaily = count <= state.dailyTickets ? count : state.dailyTickets;
    final fromExtra = count - fromDaily;
    final debit = TicketDebit(dailyTickets: fromDaily, extraTickets: fromExtra);

    final updated = state.copyWith(
      dailyTickets: state.dailyTickets - debit.dailyTickets,
      extraTickets: state.extraTickets - debit.extraTickets,
    );

    await _persist(updated);
    state = updated;
    return debit;
  }

  /// Compatibility helper for callers that only need success/failure.
  Future<bool> consumeTicket({int count = 1}) async =>
      await debitTickets(count: count) != null;

  /// Reverses a previous [debit], restoring the exact balances it consumed.
  Future<void> refundDebit(TicketDebit debit) async {
    if (debit.total <= 0) return;
    await _ready;

    final updated = state.copyWith(
      dailyTickets: state.dailyTickets + debit.dailyTickets,
      extraTickets: state.extraTickets + debit.extraTickets,
    );
    await _persist(updated);
    state = updated;
  }

  /// Credits earned tickets, which persist across days.
  Future<void> addTickets(int amount) async {
    if (amount <= 0) return;
    await _ready;

    final updated = state.copyWith(extraTickets: state.extraTickets + amount);
    await _persist(updated);
    state = updated;
  }

  Future<void> _persist(PlayerTickets t) async {
    final db = await _db.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO player_tickets '
      '(id, daily_tickets, extra_tickets, last_reset_date) VALUES (1, ?, ?, ?)',
      [t.dailyTickets, t.extraTickets, t.lastResetDate],
    );
  }
}
