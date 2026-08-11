import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import 'database_provider.dart';
import 'database_seeder.dart';

class DatabaseHelper implements DatabaseProvider {
  DatabaseHelper._() : _initializer = null;

  @visibleForTesting
  DatabaseHelper.forTesting(this._initializer);

  static final DatabaseHelper instance = DatabaseHelper._();

  final Future<Database> Function()? _initializer;
  final _seeder = const DatabaseSeeder();

  /// Completer guard to prevent concurrent initialization.
  Completer<Database>? _initCompleter;

  @override
  Future<Database> get database {
    final inFlight = _initCompleter;
    if (inFlight != null) return inFlight.future;

    // Keep a local reference. On failure `_initCompleter` is cleared to allow a
    // retry, so dereferencing the field after the catch would turn the original
    // database error into a null-assertion error.
    final completer = Completer<Database>();
    _initCompleter = completer;
    _initializeDatabase(completer);
    return completer.future;
  }

  Future<void> _initializeDatabase(Completer<Database> completer) async {
    try {
      final db = await (_initializer?.call() ?? _initDatabase());
      completer.complete(db);
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      if (identical(_initCompleter, completer)) {
        _initCompleter = null; // Allow retry on the next access.
      }
    }
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
      await File(dbPath).writeAsBytes(data.buffer.asUint8List(), flush: true);
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
      await _refreshMobileContentIfStale(db);
    }

    return db;
  }

  Future<void> _refreshMobileContentIfStale(Database db) async {
    await _seeder.ensureAppMetaTable(db);
    final installed = await _seeder.readContentVersion(db);
    if (installed >= AppConstants.contentVersion) return;

    final tempPath = join(await getDatabasesPath(), 'cineus_content_source.db');
    Database? source;
    try {
      await deleteDatabase(tempPath);
      final data = await rootBundle.load('assets/cineus_v1.db');
      await File(tempPath).writeAsBytes(data.buffer.asUint8List(), flush: true);
      source = await openDatabase(tempPath, readOnly: true);
      await _seeder.refreshContentFromDatabaseIfStale(db, source);
    } finally {
      await source?.close();
      await deleteDatabase(tempPath);
    }
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
