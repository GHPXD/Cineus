import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import 'database_provider.dart';
import 'database_seeder.dart';

class DatabaseHelper implements DatabaseProvider {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  final _seeder = const DatabaseSeeder();

  /// Completer guard to prevent concurrent initialization.
  Completer<Database>? _initCompleter;

  @override
  Future<Database> get database async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<Database>();
    try {
      final db = await _initDatabase();
      _initCompleter!.complete(db);
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      _initCompleter = null; // Allow retry on error
    }
    return _initCompleter!.future;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      final db = await openDatabase(
        'cineus_web.db',
        version: AppConstants.dbVersion,
        onCreate: _onCreateWebAndSeed,
        onUpgrade: _onUpgrade,
      );
      await _seeder.refreshContentIfStale(db);
      return db;
    }

    // Mobile: copy the pre-built asset DB to device storage on first launch.
    final dbPath = join(await getDatabasesPath(), AppConstants.dbName);
    final isFirstLaunch = !File(dbPath).existsSync();

    if (isFirstLaunch) {
      final data = await rootBundle.load('assets/cineus_v1.db');
      await File(dbPath).writeAsBytes(
        data.buffer.asUint8List(),
        flush: true,
      );
    }

    final db = await openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onUpgrade: _onUpgrade,
    );
    await _seeder.ensureGameSessionsTable(db);
    await _seeder.ensureStagesAndTickets(db);
    await _seeder.ensureRewardTables(db);
    await _seeder.ensureExtraHintsColumn(db);

    if (isFirstLaunch) {
      // The asset DB we just copied *is* the current catalogue, so record that
      // and skip the redundant JSON import.
      await _seeder.ensureAppMetaTable(db);
      await _seeder.writeContentVersion(db, AppConstants.contentVersion);
    } else {
      // Existing install: pick up a newer catalogue shipped with the app update.
      // The asset file is only copied on first launch, so this import is the
      // only path by which new movies reach an existing player.
      await _seeder.refreshContentIfStale(db);
    }

    return db;
  }

  Future<void> _onCreateWebAndSeed(Database db, int version) async {
    await _seeder.createMoviesSchema(db);
    await _seeder.ensureGameSessionsTable(db);
    await _seeder.seedFromJsonAsset(db);
    await _seeder.ensureStagesAndTickets(db);
    await _seeder.ensureRewardTables(db);
    await _seeder.ensureExtraHintsColumn(db);
    await _seeder.ensureAppMetaTable(db);
    await _seeder.writeContentVersion(db, AppConstants.contentVersion);
  }

  /// Runs when [AppConstants.dbVersion] is raised above the installed schema.
  ///
  /// Every `ensure*` call is idempotent (`CREATE TABLE IF NOT EXISTS`), so
  /// re-running them is safe and covers additive schema changes. Previously
  /// there was no `onUpgrade` at all, which made any future version bump throw
  /// at startup instead of migrating.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _seeder.ensureGameSessionsTable(db);
    await _seeder.ensureStagesAndTickets(db);
    await _seeder.ensureRewardTables(db);
    await _seeder.ensureExtraHintsColumn(db);
    await _seeder.ensureAppMetaTable(db);
  }
}

