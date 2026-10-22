import 'dart:math';
import '../datasources/database_provider.dart';
import 'growth_gateway.dart';
import 'commerce_gateway.dart';

/// The server is the only purchased balance authority. A durable operation
/// journal survives a lost response and retries using the same idempotency key.
class PaidTicketWallet {
  final DatabaseProvider database;
  final GrowthGateway gateway;
  bool _recovered = false;
  PaidTicketWallet(this.database, this.gateway);
  Future<void> _ensure() async => (await database.database).execute(
    '''CREATE TABLE IF NOT EXISTS paid_ticket_operations(
    operation TEXT PRIMARY KEY, owner TEXT NOT NULL, amount INTEGER NOT NULL,
    state TEXT NOT NULL CHECK(state IN ('requested','open','commit','refund','settled')))''',
  );
  Future<int> refresh() async {
    await _ensure();
    final db = await database.database;
    // Bootstrap the authenticated identity before selecting its journal.
    final initial = await gateway.command('wallet');
    final owner = gateway.synchronizer.identity!.owner;
    if (!_recovered) {
      await db.rawUpdate(
        "UPDATE paid_ticket_operations SET state='refund' WHERE owner=? AND state IN ('requested','open')",
        [owner],
      );
      _recovered = true;
    }
    var balance = initial['balance'] as int;
    for (final row in await db.query(
      'paid_ticket_operations',
      where: "owner=? AND state IN ('commit','refund')",
      whereArgs: [owner],
    )) {
      try {
        final result = await gateway.command(
          row['state'] == 'commit' ? 'wallet_commit' : 'wallet_refund',
          {'operation': row['operation']},
        );
        balance = result['balance'] as int;
        await db.update(
          'paid_ticket_operations',
          {'state': 'settled'},
          where: 'operation=?',
          whereArgs: [row['operation']],
        );
      } on CommerceNetworkException catch (error) {
        if (row['state'] == 'refund' && error.status == 404) {
          await db.update(
            'paid_ticket_operations',
            {'state': 'settled'},
            where: 'operation=?',
            whereArgs: [row['operation']],
          );
        }
      } catch (_) {
        /* Keep the instruction durable; do not invent a refund. */
      }
    }
    if (balance < 0 || balance > 100000000) {
      throw const FormatException('Invalid paid balance');
    }
    return balance;
  }

  Future<String> reserve(int amount) async {
    await refresh();
    final owner = gateway.synchronizer.identity!.owner;
    final random = Random.secure();
    final operation =
        'play:${DateTime.now().microsecondsSinceEpoch}:${random.nextInt(1 << 32)}';
    final db = await database.database;
    await db.insert('paid_ticket_operations', {
      'operation': operation,
      'owner': owner,
      'amount': amount,
      'state': 'requested',
    });
    try {
      await gateway.command('wallet_reserve', {
        'operation': operation,
        'amount': amount,
      });
      await db.update(
        'paid_ticket_operations',
        {'state': 'open'},
        where: 'operation=?',
        whereArgs: [operation],
      );
      return operation;
    } catch (_) {
      await db.update(
        'paid_ticket_operations',
        {'state': 'refund'},
        where: 'operation=?',
        whereArgs: [operation],
      );
      rethrow;
    }
  }

  Future<void> _settle(String operation, bool success) async {
    final db = await database.database;
    final next = success ? 'commit' : 'refund';
    await db.update(
      'paid_ticket_operations',
      {'state': next},
      where: "operation=? AND state IN ('open','requested',?)",
      whereArgs: [operation, next],
    );
    try {
      await gateway.command(success ? 'wallet_commit' : 'wallet_refund', {
        'operation': operation,
      });
      await db.update(
        'paid_ticket_operations',
        {'state': 'settled'},
        where: 'operation=?',
        whereArgs: [operation],
      );
    } catch (_) {
      /* Delivery is already durable; foreground will settle it. */
    }
  }

  Future<void> commit(String operation) => _settle(operation, true);
  Future<void> refund(String operation) => _settle(operation, false);
}
