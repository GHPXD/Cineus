import 'saved_color_session.dart';

/// Uses recorded cents only. Cores does not count as a clue/poster win or streak.
class ColorStats {
  final int games;
  final int? averageCents, bestCents;
  final List<int?> roundAverages;
  final List<SavedColorSession> recent;
  const ColorStats._(
    this.games,
    this.averageCents,
    this.bestCents,
    this.roundAverages,
    this.recent,
  );
  factory ColorStats.fromSessions(
    Iterable<SavedColorSession> sessions, [
    ColorSessionKind? kind,
  ]) {
    final completed =
        sessions
            .where(
              (s) =>
                  (kind == null || s.kind == kind) && s.status == 'completed',
            )
            .toList()
          ..sort((a, b) {
            final time = b.updatedAt.compareTo(a.updatedAt);
            return time == 0 ? b.id.compareTo(a.id) : time;
          });
    if (completed.isEmpty) {
      return const ColorStats._(0, null, null, [
        null,
        null,
        null,
        null,
        null,
      ], []);
    }
    final means = completed.map((s) => s.game.averageCents!).toList();
    return ColorStats._(
      completed.length,
      (means.reduce((a, b) => a + b) / completed.length).round(),
      means.reduce((a, b) => a > b ? a : b),
      List.unmodifiable([
        for (var i = 0; i < 5; i++)
          (completed.fold<int>(
                    0,
                    (sum, s) => sum + s.game.answers[i].scoreCents,
                  ) /
                  completed.length)
              .round(),
      ]),
      List.unmodifiable(completed.take(10)),
    );
  }
}
