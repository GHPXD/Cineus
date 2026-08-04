import 'package:sqflite/sqflite.dart';

/// Supplies the opened database to the repositories.
///
/// The repositories used to depend on the concrete `DatabaseHelper` singleton,
/// which reaches for `getDatabasesPath()` and `rootBundle` — neither available
/// in a unit test. That made every repository untestable, so the statistics bug
/// had to be diagnosed by replicating its SQL by hand instead of running it.
///
/// This stays deliberately thin: it hands over a sqflite [Database] rather than
/// abstracting SQL away. The goal is an injection seam, not a second ORM.
abstract class DatabaseProvider {
  Future<Database> get database;
}
