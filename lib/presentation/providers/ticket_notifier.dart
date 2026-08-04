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
      : super(PlayerTickets(
          dailyTickets: PlayerTickets.maxDailyTickets,
          lastResetDate: DailySelector.todayKey(),
        )) {
    _ready = _load();
  }

  Future<void> _load() async {
    final db = await _db.database;
    final rows =
        await db.query('player_tickets', where: 'id = 1');

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

  /// Consumes [count] tickets. Returns false — changing nothing — when the
  /// player cannot afford it.
  ///
  /// Spends the daily allowance first so earned tickets are the ones that carry
  /// over to tomorrow.
  Future<bool> consumeTicket({int count = 1}) async {
    if (count <= 0) return true;
    await _ready;
    if (state.total < count) return false;

    final fromDaily = count <= state.dailyTickets ? count : state.dailyTickets;
    final fromExtra = count - fromDaily;

    final updated = state.copyWith(
      dailyTickets: state.dailyTickets - fromDaily,
      extraTickets: state.extraTickets - fromExtra,
    );

    await _persist(updated);
    state = updated;
    return true;
  }

  /// Credits earned tickets, which persist across days.
  ///
  /// The counterpart to [consumeTicket] that never existed: `extraTickets` was
  /// only ever spent, so the economy had no earning path at all.
  Future<void> addTickets(int amount) async {
    if (amount <= 0) return;
    await _ready;

    final updated = state.copyWith(extraTickets: state.extraTickets + amount);
    await _persist(updated);
    state = updated;
  }

  Future<void> _persist(PlayerTickets t) async {
    final db = await _db.database;
    // INSERT OR REPLACE ensures the row exists even if _load() hasn't completed yet.
    await db.rawInsert(
      'INSERT OR REPLACE INTO player_tickets '
      '(id, daily_tickets, extra_tickets, last_reset_date) VALUES (1, ?, ?, ?)',
      [t.dailyTickets, t.extraTickets, t.lastResetDate],
    );
  }
}
