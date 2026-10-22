import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/daily_selector.dart';
import '../../data/datasources/database_provider.dart';
import '../../data/datasources/ticket_audit.dart';
import '../../domain/entities/player_tickets.dart';
import '../../domain/services/product_telemetry.dart';
import '../../data/services/disabled_product_telemetry.dart';
import '../../data/services/paid_ticket_wallet.dart';

class TicketNotifier extends StateNotifier<PlayerTickets> {
  final DatabaseProvider _db;
  final DateTime Function() _now;
  final ProductTelemetry _telemetry;
  final PaidTicketWallet? Function()? _paidWallet;
  final bool Function()? _canReset;
  final void Function(AsyncValue<void>)? _onLoadStateChanged;
  Object? _loadError;
  bool _auditInitialized = false;

  /// Completes once the stored balance has been read.
  late final Future<void> _ready;

  /// Serializes every balance mutation. Two rapid taps must never spend the
  /// same snapshot and accidentally turn two paid actions into one debit.
  Future<void> _mutationTail = Future<void>.value();

  TicketNotifier(
    this._db, {
    DateTime Function()? now,
    ProductTelemetry telemetry = const DisabledProductTelemetry(),
    void Function(AsyncValue<void>)? onLoadStateChanged,
    PaidTicketWallet? Function()? paidWallet,
    bool Function()? canReset,
  }) : _now = now ?? DateTime.now,
       _onLoadStateChanged = onLoadStateChanged,
       _telemetry = telemetry,
       _paidWallet = paidWallet,
       _canReset = canReset,
       super(
         PlayerTickets(
           dailyTickets: PlayerTickets.maxDailyTickets,
           lastResetDate: DailySelector.todayKey((now ?? DateTime.now)()),
         ),
       ) {
    _ready = _loadSafely();
  }

  Future<void> get ready => _ready;

  Future<void> _loadSafely() async {
    try {
      await _load();
      _loadError = null;
      if (mounted) _onLoadStateChanged?.call(const AsyncValue.data(null));
    } catch (error, stack) {
      _loadError = error;
      if (mounted) _onLoadStateChanged?.call(AsyncValue.error(error, stack));
    }
  }

  /// Reads persisted buckets again on foreground/UTC rollover. Uses the same
  /// queue as debits and refunds, so refresh cannot overwrite a pending spend.
  Future<void> refreshBalance() => _serialize(() async {
    await _ready;
    if (mounted) _onLoadStateChanged?.call(const AsyncValue.loading());
    await _loadSafely();
  });

  void _requireLoaded() {
    if (_loadError != null) throw StateError('Ticket balance unavailable');
  }

  Future<void> _load() async {
    final db = await _db.database;
    if (!_auditInitialized) {
      await db.transaction((txn) => TicketAudit.ensure(txn));
      _auditInitialized = true;
    }
    final rows = await db.query('player_tickets', where: 'id = 1');
    final today = DailySelector.todayKey(_now());

    if (rows.isEmpty) {
      final fresh = PlayerTickets(
        dailyTickets: PlayerTickets.maxDailyTickets,
        lastResetDate: today,
      );
      await _persist(fresh, TicketMovement.baseline);
      state = fresh;
      return;
    }

    final row = rows.first;
    final lastReset = row['last_reset_date'] as String;
    final stored = PlayerTickets(
      paidTickets: state.paidTickets,
      dailyTickets: row['daily_tickets'] as int,
      extraTickets: row['extra_tickets'] as int,
      lastResetDate: lastReset,
    );

    if (lastReset.compareTo(today) < 0 && (_canReset?.call() ?? true)) {
      final updated = PlayerTickets(
        paidTickets: state.paidTickets,
        dailyTickets: PlayerTickets.maxDailyTickets,
        extraTickets: stored.extraTickets,
        lastResetDate: today,
      );
      await _persist(updated, TicketMovement.dailyReset);
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
    if (state.lastResetDate.compareTo(today) >= 0 ||
        !(_canReset?.call() ?? true)) {
      return;
    }

    final updated = PlayerTickets(
      paidTickets: state.paidTickets,
      dailyTickets: PlayerTickets.maxDailyTickets,
      extraTickets: state.extraTickets,
      lastResetDate: today,
    );
    await _persist(updated, TicketMovement.dailyReset);
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
      _requireLoaded();
      await _resetIfDayChanged();
      if (state.total < count) {
        unawaited(
          _telemetry.record(
            'tickets_insufficient',
            properties: {'requested': count},
          ),
        );
        return null;
      }

      final fromDaily = count <= state.dailyTickets
          ? count
          : state.dailyTickets;
      final fromExtra = (count - fromDaily).clamp(0, state.extraTickets);
      final fromPaid = count - fromDaily - fromExtra;
      final operation = fromPaid > 0
          ? await _paidWallet?.call()?.reserve(fromPaid)
          : null;
      if (fromPaid > 0 && operation == null) return null;
      final debit = TicketDebit(
        daily: fromDaily,
        extra: fromExtra,
        date: state.lastResetDate,
        paid: fromPaid,
        paidOperation: operation,
      );

      final updated = state.copyWith(
        dailyTickets: state.dailyTickets - fromDaily,
        extraTickets: state.extraTickets - fromExtra,
        paidTickets: state.paidTickets - fromPaid,
      );
      try {
        await _persist(updated, TicketMovement.debit);
      } catch (_) {
        if (operation != null) await _paidWallet?.call()?.refund(operation);
        rethrow;
      }
      state = updated;
      return debit;
    });
  }

  /// Compatibility helper for call sites that only need a yes/no answer.
  Future<bool> consumeTicket({int count = 1}) async {
    final debit = await debitTickets(count: count);
    if (debit == null) return false;
    await completeDebit(debit);
    return true;
  }

  Future<void> completeDebit(TicketDebit debit) async {
    if (debit.paidOperation != null) {
      await _paidWallet?.call()?.commit(debit.paidOperation!);
    }
  }

  Future<void> refreshPaidBalance() => _serialize(() async {
    await _ready;
    final wallet = _paidWallet?.call();
    if (wallet == null) return;
    final balance = await wallet.refresh();
    if (mounted) state = state.copyWith(paidTickets: balance);
  });

  /// Reverses a previously successful [debit].
  ///
  /// On the same UTC day the original buckets are restored. If midnight passed
  /// after the charge, the old daily allowance has expired; the refund becomes
  /// earned/extra tickets so the player still gets back exactly what was paid.
  Future<void> refundDebit(TicketDebit debit) {
    if (debit.total <= 0) return Future<void>.value();

    return _serialize(() async {
      await _ready;
      _requireLoaded();
      await _resetIfDayChanged();

      late final PlayerTickets updated;
      if (debit.paidOperation != null) {
        await _paidWallet?.call()?.refund(debit.paidOperation!);
      }
      if (debit.date == state.lastResetDate) {
        final dailyRoom = PlayerTickets.maxDailyTickets - state.dailyTickets;
        final restoreDaily = debit.daily <= dailyRoom ? debit.daily : dailyRoom;
        final overflow = debit.daily - restoreDaily;
        updated = state.copyWith(
          dailyTickets: state.dailyTickets + restoreDaily,
          extraTickets: state.extraTickets + debit.extra + overflow,
        );
      } else {
        updated = state.copyWith(
          extraTickets: state.extraTickets + debit.daily + debit.extra,
        );
      }

      final refunded = updated.copyWith(
        paidTickets: state.paidTickets + debit.paid,
      );
      await _persist(refunded, TicketMovement.refund);
      state = refunded;
    });
  }

  /// Credits earned tickets, which persist across days.
  Future<void> addTickets(int amount) {
    if (amount <= 0) return Future<void>.value();

    return _serialize(() async {
      await _ready;
      _requireLoaded();
      await _resetIfDayChanged();
      final updated = state.copyWith(extraTickets: state.extraTickets + amount);
      await _persist(updated, TicketMovement.earned);
      state = updated;
    });
  }

  /// A receipt and its credit commit together, under the balance mutation queue.
  /// Verification reads the qualifying result in that same SQLite transaction.
  Future<bool> creditOnce({
    required String key,
    required int amount,
    required Future<void> Function(DatabaseExecutor db) verify,
  }) {
    if (key.isEmpty || amount <= 0) throw ArgumentError('Invalid reward');
    return _serialize(() async {
      await _ready;
      _requireLoaded();
      await _resetIfDayChanged();
      final db = await _db.database;
      final credited = await db.transaction((txn) async {
        await verify(txn);
        final existing = await txn.query(
          'ticket_rewards',
          columns: ['amount'],
          where: 'key = ?',
          whereArgs: [key],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          if (existing.single['amount'] != amount) {
            throw StateError('Incompatible reward receipt');
          }
          return false;
        }
        final before = (await txn.query(
          'player_tickets',
          where: 'id = 1',
        )).single;
        await txn.insert('ticket_rewards', {
          'key': key,
          'amount': amount,
          'awarded_at': _now().toUtc().toIso8601String(),
        });
        final updated = await txn.rawUpdate(
          'UPDATE player_tickets SET extra_tickets = extra_tickets + ? WHERE id = 1',
          [amount],
        );
        if (updated != 1) throw StateError('Missing persisted balance');
        await TicketAudit.record(
          txn,
          reason: TicketMovement.verifiedReward,
          dailyBefore: before['daily_tickets'] as int,
          extraBefore: before['extra_tickets'] as int,
          dailyAfter: before['daily_tickets'] as int,
          extraAfter: (before['extra_tickets'] as int) + amount,
          now: _now(),
        );
        return true;
      });
      // An interrupted read after commit is recoverable: the receipt prevents
      // a retry from paying again, and refresh reads the credited balance.
      try {
        await _load();
        _loadError = null;
        if (mounted) _onLoadStateChanged?.call(const AsyncValue.data(null));
      } catch (error, stack) {
        _loadError = error;
        if (mounted) _onLoadStateChanged?.call(AsyncValue.error(error, stack));
        rethrow;
      }
      return credited;
    });
  }

  Future<void> _persist(PlayerTickets tickets, TicketMovement reason) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query('player_tickets', where: 'id = 1');
      final before = rows.firstOrNull;
      await txn.rawInsert(
        'INSERT OR REPLACE INTO player_tickets '
        '(id, daily_tickets, extra_tickets, last_reset_date) VALUES (1, ?, ?, ?)',
        [tickets.dailyTickets, tickets.extraTickets, tickets.lastResetDate],
      );
      await TicketAudit.record(
        txn,
        reason: reason,
        dailyBefore: before?['daily_tickets'] as int? ?? 0,
        extraBefore: before?['extra_tickets'] as int? ?? 0,
        dailyAfter: tickets.dailyTickets,
        extraAfter: tickets.extraTickets,
        now: _now(),
      );
    });
  }

  /// Creation and debit share one transaction. A duplicate tap resumes the
  /// committed record without charging again; a failed write rolls both back.
  Future<T?> purchaseOnce<T>({
    required Future<T?> Function(DatabaseExecutor db) existing,
    required Future<T> Function(DatabaseExecutor db) create,
  }) => _serialize(() async {
    await _ready;
    _requireLoaded();
    await _resetIfDayChanged();
    final db = await _db.database;
    final previous = await existing(db);
    if (previous != null) return previous;
    final wallet = _paidWallet?.call();
    final paid =
        state.dailyTickets + state.extraTickets == 0 && state.paidTickets > 0;
    final operation = paid ? await wallet?.reserve(1) : null;
    if (paid && operation == null) return null;
    PlayerTickets? updated;
    T? result;
    try {
      result = await db.transaction<T?>((txn) async {
        final previous = await existing(txn);
        if (previous != null) return previous;
        if (!state.hasTickets) {
          unawaited(
            _telemetry.record(
              'tickets_insufficient',
              properties: {'requested': 1},
            ),
          );
          return null;
        }
        final record = await create(txn);
        updated = state.dailyTickets > 0
            ? state.copyWith(dailyTickets: state.dailyTickets - 1)
            : state.extraTickets > 0
            ? state.copyWith(extraTickets: state.extraTickets - 1)
            : state.copyWith(paidTickets: state.paidTickets - 1);
        if (operation != null) {
          await txn.update(
            'paid_ticket_operations',
            {'state': 'commit'},
            where: 'operation=?',
            whereArgs: [operation],
          );
        }
        final changed = await txn.update(
          'player_tickets',
          {
            'daily_tickets': updated!.dailyTickets,
            'extra_tickets': updated!.extraTickets,
          },
          where: 'id = ?',
          whereArgs: [1],
        );
        if (changed != 1) throw StateError('Missing ticket balance');
        await TicketAudit.record(
          txn,
          reason: TicketMovement.stageStart,
          dailyBefore: state.dailyTickets,
          extraBefore: state.extraTickets,
          dailyAfter: updated!.dailyTickets,
          extraAfter: updated!.extraTickets,
          now: _now(),
        );
        return record;
      });
    } catch (_) {
      if (operation != null) await wallet?.refund(operation);
      rethrow;
    }
    if (operation != null) {
      if (updated != null) {
        await wallet?.commit(operation);
      } else {
        await wallet?.refund(operation);
      }
    }
    if (updated != null) state = updated!;
    return result;
  });
}
