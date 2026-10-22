import '../../domain/entities/cinema_showcase.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/database_provider.dart';

/// Uses a versioned training identity, keeping daily/stage stats independent.
class CinemaShowcaseRepository {
  final DatabaseProvider database;
  final GameRepository games;
  const CinemaShowcaseRepository(this.database, this.games);
  Future<List<GameSession>> sessions(
    CinemaShowcase showcase,
    GameMode mode,
  ) async {
    final db = await database.database;
    final rows = await db.query(
      'game_sessions',
      where: 'kind=? AND mode=? AND date=?',
      whereArgs: ['training', mode.name, showcase.sessionKey],
    );
    return rows.map(GameSession.fromMap).toList();
  }

  Future<GameSession> open(
    CinemaShowcase showcase,
    GameMode mode,
    int movie,
  ) async {
    if (!showcase.movies.contains(movie)) {
      throw ArgumentError('Movie outside showcase');
    }
    final existing = (await sessions(
      showcase,
      mode,
    )).where((s) => s.movieId == movie).firstOrNull;
    return existing ??
        await games.saveSession(
          GameSession(
            mode: mode,
            kind: SessionKind.training,
            movieId: movie,
            date: showcase.sessionKey,
          ),
        );
  }
}
