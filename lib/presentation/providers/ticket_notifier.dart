import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../data/datasources/database_provider.dart';
import '../../domain/entities/player_tickets.dart';

class TicketNotifier extends StateNotifier<PlayerTickets> {
  final DatabaseProvider _db;
  final DateTime Function() _now;

  /// Completes once the stored balance has been read.
  late final Future<void> _ready;

  /// Serializes every balance mutation. Two rapid taps must never spend the
  /// same snapshot and accidentally turn two paid actions into one debit.
  Future<void> _mutationTail = Future<void>.value();

  TicketNotifier(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(PlayerTickets(
          dailyTickets: PlayerTickets.maxDailyTickets,
          lastResetDate: DailySelector.todayKey((now ?? DateTime.now)()),
        )) {
    _ready = _load();
  }

  Future<void> _load() async {
    final db = await _db.database;
    final rows = await db.query('player_tickets', where: 'id = 1');
    final today = DailySelector.todayKey(_now());

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
    final stored = PlayerTickets(
      dailyTickets: row['daily_tickets'] as int,
      extraTickets: row['extra_tickets'] as int,
      lastResetDate: lastReset,
    );

    if (lastReset != today) {
      final updated = PlayerTickets(
        dailyTickets: PlayerTickets.maxDailyTickets,
        extraTickets: stored.extraTickets,
        lastResetDate: today,
      );
      await _persist(updated);
      state = updated;
    } else {
      state = stored;
    }
  }

  Future<T> _serialize<T>(Future<T> Function() mutation) {
    final completer = Completer<T>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        completer.complete(await mutation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  /// Handles midnight while the app remains open. Previously the daily balance
  /// only reset when the notifier was constructed, so a long-lived session could
  /// keep yesterday's depleted allowance indefinitely.
  Future<void> _resetIfDayChanged() async {
    final today = DailySelector.todayKey(_now());
    if (state.lastResetDate == today) return;

    final updated = PlayerTickets(
      dailyTickets: PlayerTickets.maxDailyTickets,
      extraTickets: state.extraTickets,
      lastResetDate: today,
    );
    await _persist(updated);
    state = updated;
  }

  /// Debits [count] tickets and returns the exact daily/earned split that was
  /// consumed. The receipt lets a caller roll back a failed paid action without
  /// inventing or losing tickets.
  Future<TicketDebit?> debitTickets({int count = 1}) {
    if (count <= 0) {
      return Future<TicketDebit?>.value(
        TicketDebit(daily: 0, extra: 0, date: state.lastResetDate),
      );
    }

    return _serialize(() async {
      await _ready;
      await _resetIfDayChanged();
      if (state.total < count) return null;

      final fromDaily = count <= state.dailyTickets ? count : state.dailyTickets;
      final fromExtra = count - fromDaily;
      final debit = TicketDebit(
        daily: fromDaily,
        extra: fromExtra,
        date: state.lastResetDate,
      );

      final updated = state.copyWith(
        dailyTickets: state.dailyTickets - fromDaily,
        extraTickets: state.extraTickets - fromExtra,
      );
      await _persist(updated);
      state = updated;
      return debit;
    });
  }

  /// Compatibility helper for call sites that only need a yes/no answer.
  Future<bool> consumeTicket({int count = 1}) async =>
      await debitTickets(count: count) != null;

  /// Reverses a previously successful [debit].
  ///
  /// On the same UTC day the original buckets are restored. If midnight passed
  /// after the charge, the old daily allowance has expired; the refund becomes
  /// earned/extra tickets so the player still gets back exactly what was paid.
  Future<void> refundDebit(TicketDebit debit) {
    if (debit.total <= 0) return Future<void>.value();

    return _serialize(() async {
      await _ready;
      await _resetIfDayChanged();

      late final PlayerTickets updated;
      if (debit.date == state.lastResetDate) {
        final dailyRoom = PlayerTickets.maxDailyTickets - state.dailyTickets;
        final restoreDaily = debit.daily <= dailyRoom ? debit.daily : dailyRoom;
        final overflow = debit.daily - restoreDaily;
        updated = state.copyWith(
          dailyTickets: state.dailyTickets + restoreDaily,
          extraTickets: state.extraTickets + debit.extra + overflow,
        );
      } else {
        updated = state.copyWith(extraTickets: state.extraTickets + debit.total);
      }

      await _persist(updated);
      state = updated;
    });
  }

  /// Credits earned tickets, which persist across days.
  Future<void> addTickets(int amount) {
    if (amount <= 0) return Future<void>.value();

    return _serialize(() async {
      await _ready;
      await _resetIfDayChanged();
      final updated = state.copyWith(extraTickets: state.extraTickets + amount);
      await _persist(updated);
      state = updated;
    });
  }

  Future<void> _persist(PlayerTickets tickets) async {
    final db = await _db.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO player_tickets '
      '(id, daily_tickets, extra_tickets, last_reset_date) VALUES (1, ?, ?, ?)',
      [
        tickets.dailyTickets,
        tickets.extraTickets,
        tickets.lastResetDate,
      ],
    );
  }
}
