import 'extra_hint.dart';
import 'scoring_rules.dart';

enum GameStatus { playing, won, lost }

/// Which game a session belongs to.
enum GameMode {
  /// Ten progressive text clues.
  clue,

  /// Five blur levels over the poster.
  poster,
}

/// Whether a session is the once-a-day challenge, a stage replay, or a one-off
/// film a friend sent over (D10).
enum SessionKind { daily, stage, challenge }

/// A single play-through, identified by explicit domain values.
///
/// Persistence belongs to the data layer. This entity deliberately knows
/// nothing about SQLite column names, JSON encoding, or migration details.
class GameSession {
  final int? id;
  final GameMode mode;
  final SessionKind kind;

  /// `YYYY-MM-DD` for daily sessions; empty for stage/challenge sessions.
  final String date;

  /// Stage number for stage sessions; 0 otherwise.
  final int stageId;

  final int movieId;
  final int revealedClues;
  final List<String> guesses;
  final GameStatus status;
  final int score;

  /// Names of [ExtraHint]s bought with tickets during this session.
  ///
  /// Stored as names rather than indices so reordering the enum cannot silently
  /// reinterpret saved data.
  final List<String> extraHints;

  const GameSession({
    this.id,
    required this.mode,
    required this.kind,
    required this.movieId,
    this.date = '',
    this.stageId = 0,
    this.revealedClues = 1,
    this.guesses = const [],
    this.status = GameStatus.playing,
    this.score = 0,
    this.extraHints = const [],
  });

  factory GameSession.daily({
    required GameMode mode,
    required String date,
    required int movieId,
  }) {
    return GameSession(
      mode: mode,
      kind: SessionKind.daily,
      date: date,
      movieId: movieId,
    );
  }

  factory GameSession.challenge({
    required GameMode mode,
    required int movieId,
  }) {
    return GameSession(
      mode: mode,
      kind: SessionKind.challenge,
      movieId: movieId,
    );
  }

  factory GameSession.stage({
    required GameMode mode,
    required int stageId,
    required int movieId,
  }) {
    return GameSession(
      mode: mode,
      kind: SessionKind.stage,
      stageId: stageId,
      movieId: movieId,
    );
  }

  ScoringRules get rules => ScoringRules.forMode(mode);

  bool get isDaily => kind == SessionKind.daily;
  bool get isStage => kind == SessionKind.stage;
  bool get isChallenge => kind == SessionKind.challenge;

  int get potentialScore =>
      status == GameStatus.playing ? rules.scoreAt(revealedClues) : score;

  bool get isFinished => status != GameStatus.playing;
  bool get canRevealMore => rules.canRevealMore(revealedClues);
  bool get isOnLastStep => rules.isLastStep(revealedClues);
  int get wrongGuessCount => guesses.length;

  Set<ExtraHint> get purchasedHints => {
    for (final name in extraHints)
      if (ExtraHint.values.any((hint) => hint.name == name))
        ExtraHint.values.firstWhere((hint) => hint.name == name),
  };

  bool hasHint(ExtraHint hint) => extraHints.contains(hint.name);

  GameSession copyWith({
    int? id,
    GameMode? mode,
    SessionKind? kind,
    String? date,
    int? stageId,
    int? movieId,
    int? revealedClues,
    List<String>? guesses,
    GameStatus? status,
    int? score,
    List<String>? extraHints,
  }) {
    return GameSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      stageId: stageId ?? this.stageId,
      movieId: movieId ?? this.movieId,
      revealedClues: revealedClues ?? this.revealedClues,
      guesses: guesses ?? this.guesses,
      status: status ?? this.status,
      score: score ?? this.score,
      extraHints: extraHints ?? this.extraHints,
    );
  }
}
