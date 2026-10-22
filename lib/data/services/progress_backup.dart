import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/saved_color_session.dart';
import '../../core/utils/daily_selector.dart';
import '../datasources/database_provider.dart';
import '../datasources/color_schema.dart';
import '../datasources/journey_schema.dart';
import '../datasources/collection_schema.dart';
import '../repositories/economy_repository.dart';
import '../repositories/journey_repository.dart';
import '../../domain/entities/player_collection.dart';
import 'growth_gateway.dart';

/// Progress only. Identity, store rights, paid balance and rewards are never
/// recreated from client backup data. Terminal local games always win a merge.
class ProgressBackup {
  final DatabaseProvider database;
  final GrowthGateway gateway;
  ProgressBackup(this.database, this.gateway);
  static const tables = {
    'game_sessions',
    'color_sessions',
    'color_stage_slots',
    'journey_completions',
    'journey_claims',
    'character_discovery',
    'journey_offers',
    'economy_stage_contracts',
    'ticket_rewards',
  };
  Future<Map<String, Object?>> export() async {
    final db = await database.database;
    return db.transaction((txn) async {
      final existing = (await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      )).map((r) => r['name']).toSet();
      final content = <String, List<Map<String, Object?>>>{
        for (final table in tables)
          if (existing.contains(table))
            table: (await txn.query(
              table,
            )).map((row) => Map<String, Object?>.from(row)).toList(),
      };
      final catalogs = <Object?>[], known = <String, int>{};
      for (final row in content['color_sessions'] ?? <Map<String, Object?>>[]) {
        final snapshot =
            jsonDecode(row['snapshot'] as String) as Map<String, dynamic>;
        final packed = jsonEncode(snapshot['catalog']);
        final index = known.putIfAbsent(packed, () {
          catalogs.add(snapshot['catalog']);
          return catalogs.length - 1;
        });
        snapshot
          ..remove('catalog')
          ..['catalog_ref'] = index;
        row['snapshot'] = jsonEncode(snapshot);
      }
      return {'version': 2, 'catalogs': catalogs, 'tables': content};
    });
  }

  Future<void> save() async {
    final previous = await gateway.command('backup_get');
    final payload = base64Encode(
      zlib.encode(utf8.encode(jsonEncode(await export()))),
    );
    if (payload.length > 55000) {
      throw const FormatException('Backup exceeds current storage limit');
    }
    await gateway.command('backup_put', {
      'revision': previous['revision'],
      'payload': payload,
    });
  }

  Future<void> restore() async {
    final remote = await gateway.command('backup_get');
    final payload = remote['payload'];
    if (payload == null) throw StateError('No saved backup');
    await merge(
      jsonDecode(utf8.decode(zlib.decode(base64Decode(payload as String))))
          as Map<String, dynamic>,
    );
  }

  Future<void> merge(Map<String, dynamic> backup) async {
    final data = backup['tables'];
    if (!{1, 2}.contains(backup['version']) ||
        data is! Map<String, dynamic> ||
        data.keys.toSet().difference(tables).isNotEmpty) {
      throw const FormatException('Unsupported backup');
    }
    for (final entry in data.entries) {
      if (entry.value is! List || (entry.value as List).length > 20000) {
        throw const FormatException('Invalid backup size');
      }
      for (final value in entry.value as List) {
        if (value is! Map<String, dynamic> ||
            value.values.any((v) => v != null && v is! String && v is! num)) {
          throw const FormatException('Invalid backup row');
        }
      }
    }
    final films = [
      for (final row in data['game_sessions'] as List? ?? [])
        Map<String, dynamic>.from(row as Map),
    ];
    for (final row in films) {
      final s = GameSession.fromMap(row);
      if (s.movieId < 1 ||
          s.movieId > 500 ||
          s.stageId < 0 ||
          s.stageId > 1000 ||
          s.revealedClues < 1 ||
          s.revealedClues > s.rules.totalSteps ||
          s.score < 0 ||
          s.score > s.rules.totalSteps ||
          s.guesses.length > 20 ||
          s.extraHints.length > 10 ||
          s.guesses.any((s) => s.length > 300) ||
          ((s.isDaily || s.kind == SessionKind.archive) &&
              DailySelector.dateFromKey(s.date) == null)) {
        throw const FormatException('Invalid saved game');
      }
    }
    final colors = [
      for (final row in data['color_sessions'] as List? ?? [])
        Map<String, Object?>.from(row as Map),
    ];
    if (backup['version'] == 2) {
      final catalogs = backup['catalogs'] as List;
      if (catalogs.length > 100) {
        throw const FormatException('Too many pinned catalogues');
      }
      for (final row in colors) {
        final snapshot =
            jsonDecode(row['snapshot'] as String) as Map<String, dynamic>;
        final index = snapshot.remove('catalog_ref');
        if (index is! int || index < 0 || index >= catalogs.length) {
          throw const FormatException('Missing pinned catalogue');
        }
        snapshot['catalog'] = catalogs[index];
        row['snapshot'] = jsonEncode(snapshot);
      }
    }
    for (final row in colors) {
      SavedColorSession.fromRow(row);
    }
    final db = await database.database;
    await ColorSchema.ensure(db);
    await JourneySchema.ensure(db);
    await CollectionSchema.ensure(db);
    await EconomyRepository(database).ensure(db);
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS journey_offers(period TEXT NOT NULL,mission TEXT NOT NULL,item TEXT NOT NULL,target INTEGER NOT NULL DEFAULT 3,PRIMARY KEY(period,mission))''',
    );
    await db.transaction((txn) async {
      final existingTables = (await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      )).map((r) => r['name']).toSet();
      final idMap = <int, int>{};
      for (final row in films) {
        final original = row['id'] as int?;
        final s = GameSession.fromMap(row);
        final condition = s.isDaily || s.kind == SessionKind.archive
            ? 'date=?'
            : s.isChallenge
            ? 'date=? AND movie_id=?'
            : s.kind == SessionKind.training
            ? 'date=? AND movie_id=?'
            : 'stage_id=? AND movie_id=?';
        final args = <Object?>[
          s.mode.name,
          s.kind.name,
          if (s.isDaily ||
              s.kind == SessionKind.archive ||
              s.kind == SessionKind.training ||
              s.isChallenge)
            s.date
          else
            s.stageId,
          if (!(s.isDaily || s.kind == SessionKind.archive)) s.movieId,
        ];
        final found = await txn.query(
          'game_sessions',
          where: 'mode=? AND kind=? AND $condition',
          whereArgs: args,
          limit: 1,
        );
        final clean = s.toMap()..remove('id');
        clean['updated_at'] = row['updated_at'] is String
            ? row['updated_at']
            : '';
        int id;
        if (found.isEmpty) {
          id = await txn.insert('game_sessions', clean);
        } else {
          id = found.single['id'] as int;
          final local = GameSession.fromMap(
            Map<String, dynamic>.from(found.single),
          );
          if (!local.isFinished &&
              (s.isFinished || s.revealedClues > local.revealedClues)) {
            await txn.update(
              'game_sessions',
              clean,
              where: 'id=?',
              whereArgs: [id],
            );
          }
        }
        if (original != null) idMap[original] = id;
      }
      for (final row in colors) {
        final found = await txn.query(
          'color_sessions',
          where: 'id=?',
          whereArgs: [row['id']],
        );
        final clean = SavedColorSession.fromRow(row).toRow();
        if (found.isEmpty) {
          if (clean['active_slot'] != null &&
              (await txn.query(
                'color_sessions',
                where: 'active_slot=?',
                whereArgs: [clean['active_slot']],
              )).isNotEmpty) {
            clean['active_slot'] = null;
          }
          await txn.insert('color_sessions', clean);
        } else if (found.single['status'] == 'active' &&
            (clean['revision'] as int) > (found.single['revision'] as int)) {
          await txn.update(
            'color_sessions',
            clean,
            where: 'id=?',
            whereArgs: [row['id']],
          );
        }
      }
      for (final entry in data.entries) {
        if ({'game_sessions', 'color_sessions'}.contains(entry.key) ||
            !existingTables.contains(entry.key)) {
          continue;
        }
        final columns = (await txn.rawQuery(
          'PRAGMA table_info(${entry.key})',
        )).map((c) => c['name']).toSet();
        for (final source in entry.value as List) {
          final row = Map<String, Object?>.from(source as Map);
          if (row.keys.toSet().difference(columns).isNotEmpty) {
            throw const FormatException('Unknown backup column');
          }
          if (entry.key == 'journey_completions' &&
              row['game_key'] is String &&
              (row['game_key'] as String).startsWith('film:')) {
            final old = int.tryParse((row['game_key'] as String).substring(5));
            if (!idMap.containsKey(old)) continue;
            row['game_key'] = 'film:${idMap[old]}';
          }
          await txn.insert(
            entry.key,
            row,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      if (existingTables.contains('stage_progress')) {
        await txn.rawInsert(
          "INSERT OR IGNORE INTO stage_progress(stage_id,movie_id,mode,status) SELECT stage_id,movie_id,mode,'completed' FROM game_sessions WHERE kind='stage' AND status='won'",
        );
      }
      for (final claim in await txn.query('journey_claims')) {
        final offer = (await txn.query(
          'journey_offers',
          where: 'period=? AND mission=?',
          whereArgs: [claim['period'], claim['mission']],
        )).firstOrNull;
        final id =
            offer?['item'] ?? JourneyRepository.rewards[claim['mission']];
        if (!PlayerCollectionCatalog.items.any(
          (i) =>
              i.id == id && {'weekly_v1', 'weekly_v2'}.contains(i.collectionId),
        )) {
          continue;
        }
        await txn.insert('collection_ownership', {
          'item_id': id,
          'source_id': 'mission:${claim['period']}:${claim['mission']}',
          'granted_at': claim['claimed_at'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }
}
