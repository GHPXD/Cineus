import '../../domain/repositories/app_meta_repository.dart';
import '../datasources/database_provider.dart';
import '../datasources/database_seeder.dart';

class AppMetaRepositoryImpl implements AppMetaRepository {
  final DatabaseProvider _db;
  final DatabaseSeeder _seeder;

  AppMetaRepositoryImpl(
    this._db, {
    DatabaseSeeder seeder = const DatabaseSeeder(),
  }) : _seeder = seeder;

  static const _onboardingKey = 'onboarding_seen';

  @override
  Future<bool> hasSeenOnboarding() async {
    final db = await _db.database;
    return await _seeder.readMeta(db, _onboardingKey) == 'true';
  }

  @override
  Future<void> markOnboardingSeen() async {
    final db = await _db.database;
    await _seeder.writeMeta(db, _onboardingKey, 'true');
  }

  @override
  Future<String?> read(String key) async {
    final db = await _db.database;
    return _seeder.readMeta(db, key);
  }

  @override
  Future<void> write(String key, String value) async {
    final db = await _db.database;
    await _seeder.writeMeta(db, key, value);
  }
}
