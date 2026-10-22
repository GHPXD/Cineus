import 'package:sqflite/sqflite.dart';
import '../datasources/database_provider.dart';
import '../datasources/collection_schema.dart';
import '../datasources/journey_schema.dart';
import '../../domain/entities/player_collection.dart';

class WeeklyMission {
  final String id, item;
  final int current, target;
  final bool claimed;
  final int duplicateTickets;
  const WeeklyMission(
    this.id,
    this.item,
    this.current,
    this.target,
    this.claimed, [
    this.duplicateTickets = 0,
  ]);
}

class JourneyProgress {
  final DateTime start, end;
  final List<WeeklyMission> missions;
  final Set<String> discovered;
  const JourneyProgress(this.start, this.end, this.missions, this.discovered);
}

class JourneyRepository {
  final DatabaseProvider database;
  final DateTime Function() now;
  const JourneyRepository(this.database, this.now);
  static const rewards = {
    'play': 'mission_frame_projector_v1',
    'modes': 'mission_avatar_firefly_v1',
    'days': 'mission_appearance_constellation_v1',
  };
  DateTime _start() {
    final n = now().toUtc();
    return DateTime.utc(
      n.year,
      n.month,
      n.day,
    ).subtract(Duration(days: n.weekday - 1));
  }

  Map<String, String> _rotation(DateTime start) {
    final week = start.difference(DateTime.utc(2026, 10, 12)).inDays ~/ 7;
    if (week <= 0) return rewards;
    const fresh = [
      'mission_avatar_capybara_v1',
      'mission_avatar_axolotl_v1',
      'mission_avatar_penguin_v1',
    ];
    final pool = <String>{
      ...rewards.values,
      ...fresh,
      if (week >= 2)
        ...PlayerCollectionCatalog.items
            .where(
              (i) =>
                  !i.starter &&
                  {
                    'night_v1',
                    'city_v1',
                    'premiere_v1',
                  }.contains(i.collectionId),
            )
            .map((i) => i.id),
    }.toList();
    return {
      for (var i = 0; i < 3; i++)
        rewards.keys.elementAt(i): pool[(week * 3 + i) % pool.length],
    };
  }

  int _target(DateTime start, String mission) {
    final week = start.difference(DateTime.utc(2026, 10, 12)).inDays ~/ 7;
    if (week <= 0) return 3;
    return switch (mission) {
      'play' => [3, 5, 7][week % 3],
      'modes' => week.isOdd ? 2 : 3,
      _ => week.isOdd ? 2 : 3,
    };
  }

  Future<Map<String, String>> _offers(
    DatabaseExecutor db,
    DateTime start,
  ) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS journey_offers(
      period TEXT NOT NULL, mission TEXT NOT NULL, item TEXT NOT NULL,
      PRIMARY KEY(period,mission))''');
    if (!(await db.rawQuery(
      'PRAGMA table_info(journey_offers)',
    )).any((c) => c['name'] == 'target')) {
      await db.execute(
        'ALTER TABLE journey_offers ADD COLUMN target INTEGER NOT NULL DEFAULT 3',
      );
    }
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS mission_ticket_grants(
      reward_key TEXT PRIMARY KEY, amount INTEGER NOT NULL, delivered INTEGER NOT NULL DEFAULT 0)''',
    );
    final period = start.toIso8601String();
    final rotated = _rotation(start);
    for (final entry in rotated.entries) {
      final claimed = await db.query(
        'journey_claims',
        where: 'period=? AND mission=?',
        whereArgs: [period, entry.key],
      );
      // An already-claimed old offer keeps its original identity after migration.
      await db.insert('journey_offers', {
        'period': period,
        'mission': entry.key,
        'item': claimed.isNotEmpty ? rewards[entry.key] : entry.value,
        'target': claimed.isNotEmpty ? 3 : _target(start, entry.key),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    return {
      for (final r in await db.query(
        'journey_offers',
        where: 'period=?',
        whereArgs: [period],
      ))
        r['mission'] as String: r['item'] as String,
    };
  }

  Future<void> deliver(
    Future<bool> Function(String key, int amount) credit,
  ) async {
    final db = await database.database;
    await JourneySchema.ensure(db);
    await _offers(db, _start());
    for (final r in await db.query(
      'mission_ticket_grants',
      where: 'delivered=0',
    )) {
      final key = r['reward_key'] as String;
      await credit(key, r['amount'] as int);
      await db.update(
        'mission_ticket_grants',
        {'delivered': 1},
        where: 'reward_key=?',
        whereArgs: [key],
      );
    }
  }

  Future<List<int>> _counts(DatabaseExecutor db, DateTime start) async {
    final rows = await db.rawQuery(
      '''SELECT COUNT(*) games,COUNT(DISTINCT mode) modes,
      COUNT(DISTINCT substr(completed_at,1,10)) days FROM journey_completions
      WHERE completed_at>=? AND completed_at<?''',
      [
        start.toIso8601String(),
        start.add(const Duration(days: 7)).toIso8601String(),
      ],
    );
    return [
      'games',
      'modes',
      'days',
    ].map((k) => rows.single[k] as int).toList();
  }

  Future<JourneyProgress> load() async {
    final db = await database.database;
    await JourneySchema.ensure(db);
    final start = _start(), counts = await _counts(db, _start());
    await CollectionSchema.ensure(db);
    final offers = await _offers(db, start);
    final targets = {
      for (final row in await db.query(
        'journey_offers',
        where: 'period=?',
        whereArgs: [start.toIso8601String()],
      ))
        row['mission']: row['target'] as int,
    };
    final owned = (await db.query(
      'collection_ownership',
    )).map((r) => r['item_id'] as String).toSet();
    final claims = await db.query(
      'journey_claims',
      where: 'period=?',
      whereArgs: [start.toIso8601String()],
    );
    final seen = await db.query('character_discovery');
    return JourneyProgress(start, start.add(const Duration(days: 7)), [
      for (var i = 0; i < rewards.length; i++)
        WeeklyMission(
          rewards.keys.elementAt(i),
          offers[rewards.keys.elementAt(i)]!,
          counts[i].clamp(0, targets[rewards.keys.elementAt(i)]!),
          targets[rewards.keys.elementAt(i)]!,
          claims.any((c) => c['mission'] == rewards.keys.elementAt(i)),
          owned.contains(offers[rewards.keys.elementAt(i)]) ? 2 : 0,
        ),
    ], seen.map((r) => r['character_id'] as String).toSet());
  }

  Future<bool> claim(String mission) async {
    if (!rewards.containsKey(mission)) throw ArgumentError('Unknown mission');
    final db = await database.database;
    return db.transaction((txn) async {
      await JourneySchema.ensure(txn);
      await CollectionSchema.ensure(txn);
      final start = _start(), period = _start().toIso8601String();
      final offers = await _offers(txn, start);
      final index = rewards.keys.toList().indexOf(mission);
      final target =
          (await txn.query(
                'journey_offers',
                where: 'period=? AND mission=?',
                whereArgs: [period, mission],
              )).single['target']
              as int;
      if ((await _counts(txn, start))[index] < target) return false;
      if ((await txn.query(
        'journey_claims',
        where: 'period=? AND mission=?',
        whereArgs: [period, mission],
      )).isNotEmpty) {
        return false;
      }
      await txn.insert('journey_claims', {
        'period': period,
        'mission': mission,
        'claimed_at': now().toUtc().toIso8601String(),
      });
      final item = offers[mission]!;
      final duplicate = (await txn.query(
        'collection_ownership',
        where: 'item_id=?',
        whereArgs: [item],
        limit: 1,
      )).isNotEmpty;
      if (duplicate) {
        await txn.insert('mission_ticket_grants', {
          'reward_key': 'mission:$period:$mission',
          'amount': 2,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        await txn.insert('collection_ownership', {
          'item_id': item,
          'source_id': 'mission:$period:$mission',
          'granted_at': now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return true;
    });
  }
}
