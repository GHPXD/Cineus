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

  static const _webDatabaseName = 'cineus_web.db';
  static const _assetDatabasePath = 'assets/cineus_v1.db';
  static const _sqliteHeader = 'SQLite format 3\u0000';

  final _seeder = const DatabaseSeeder();

  /// Single-flight guard: every concurrent caller observes the same attempt.
  Completer<Database>? _initCompleter;
  Database? _openedDatabase;

  @override
  Future<Database> get database {
    final existing = _initCompleter;
    if (existing != null) return existing.future;

    final attempt = Completer<Database>();
    _initCompleter = attempt;
    unawaited(_completeInitialization(attempt));
    return attempt.future;
  }

  Future<void> _completeInitialization(Completer<Database> attempt) async {
    try {
      final db = await _initDatabase();
      if (!attempt.isCompleted) attempt.complete(db);
    } catch (error, stackTrace) {
      final open = _openedDatabase;
      _openedDatabase = null;
      if (open != null && open.isOpen) {
        try {
          await open.close();
        } catch (_) {
          // Preserve the initialization error as the one the caller receives.
        }
      }

      if (!attempt.isCompleted) attempt.completeError(error, stackTrace);
      // Clear only our own failed attempt. A future caller can retry and the
      // original caller still receives the original error via [attempt.future].
      if (identical(_initCompleter, attempt)) {
        _initCompleter = null;
      }
    }
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      final db = await openDatabase(
        _webDatabaseName,
        version: AppConstants.dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreateWebAndSeed,
        onUpgrade: _onUpgrade,
      );
      _openedDatabase = db;
      await _seeder.ensureCanonicalSchema(db);
      await _validateDatabase(db);
      await _seeder.refreshContentIfStale(db);
      return db;
    }

    final dbPath = join(await getDatabasesPath(), AppConstants.dbName);
    final isFirstLaunch = !await File(dbPath).exists();

    if (isFirstLaunch) {
      await _copyBundledDatabaseAtomically(dbPath);
    }

    final db = await openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
    _openedDatabase = db;

    await _seeder.ensureCanonicalSchema(db);
    await _validateDatabase(db);

    if (isFirstLaunch) {
      // The copied asset already is the current snapshot. Recording the version
      // avoids a redundant JSON rewrite on the first launch.
      await _seeder.writeContentVersion(db, AppConstants.contentVersion);
    } else {
      await _seeder.refreshContentIfStale(db);
    }

    return db;
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    final enabled = await db.rawQuery('PRAGMA foreign_keys');
    final value = enabled.isEmpty ? 0 : enabled.first.values.first;
    if (value != 1) {
      throw StateError('SQLite foreign-key enforcement could not be enabled');
    }
  }

  Future<void> _validateDatabase(Database db) async {
    final check = await db.rawQuery('PRAGMA quick_check(1)');
    final result = check.isEmpty ? null : check.first.values.first;
    if (result != 'ok') {
      throw StateError('SQLite integrity check failed: $result');
    }

    final foreignKeyErrors = await db.rawQuery('PRAGMA foreign_key_check');
    if (foreignKeyErrors.isNotEmpty) {
      throw StateError(
        'SQLite foreign-key check failed: ${foreignKeyErrors.length} violation(s)',
      );
    }
  }

  Future<void> _copyBundledDatabaseAtomically(String dbPath) async {
    final parent = Directory(dirname(dbPath));
    await parent.create(recursive: true);

    final target = File(dbPath);
    final temp = File('$dbPath.installing');
    if (await temp.exists()) await temp.delete();

    try {
      final data = await rootBundle.load(_assetDatabasePath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      _validateBundledDatabaseBytes(bytes);

      await temp.writeAsBytes(bytes, flush: true);
      // Rename on the same filesystem is atomic. A crash before this line leaves
      // only the disposable `.installing` file; a crash after it leaves a full DB.
      if (await target.exists()) {
        throw StateError('Refusing to overwrite an existing local database');
      }
      await temp.rename(target.path);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }

  void _validateBundledDatabaseBytes(List<int> bytes) {
    if (bytes.length < _sqliteHeader.length) {
      throw const FormatException('Bundled database is truncated');
    }
    final header = String.fromCharCodes(bytes.take(_sqliteHeader.length));
    if (header != _sqliteHeader) {
      throw const FormatException('Bundled database has an invalid SQLite header');
    }
  }

  Future<void> _onCreateWebAndSeed(Database db, int version) async {
    await _seeder.createMoviesSchema(db);
    await _seeder.seedFromJsonAsset(db);
    await _seeder.ensureGameSessionsTable(db);
    await _seeder.ensureStagesAndTickets(db);
    await _seeder.ensureRewardTables(db);
    await _seeder.ensureExtraHintsColumn(db);
    await _seeder.ensureAppMetaTable(db);
    await _seeder.writeSchemaVersion(db, DatabaseSeeder.schemaVersion);
    await _seeder.writeContentVersion(db, AppConstants.contentVersion);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _seeder.ensureCanonicalSchema(db);
  }

  /// Retries initialization after a transient failure.
  Future<Database> retry() => database;

  /// Last-resort local repair used by the bootstrap error screen.
  ///
  /// Mobile keeps a byte-for-byte backup beside the database before rebuilding
  /// from the bundled snapshot. Web storage cannot be copied through `dart:io`,
  /// so it is recreated directly. This action is intentionally explicit because
  /// player progress may need manual recovery from the mobile backup.
  Future<Database> repairDatabase() async {
    final open = _openedDatabase;
    _openedDatabase = null;
    if (open != null && open.isOpen) {
      await open.close();
    }
    _initCompleter = null;

    if (kIsWeb) {
      await deleteDatabase(_webDatabaseName);
      return database;
    }

    final dbPath = join(await getDatabasesPath(), AppConstants.dbName);
    final source = File(dbPath);
    if (await source.exists()) {
      final backup = File('$dbPath.recovery.bak');
      if (await backup.exists()) await backup.delete();
      await source.copy(backup.path);
    }
    await deleteDatabase(dbPath);
    final installing = File('$dbPath.installing');
    if (await installing.exists()) await installing.delete();

    return database;
  }
}
