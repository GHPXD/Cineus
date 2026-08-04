import 'dart:convert';

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

/// A single play-through, identified by explicit columns.
///
/// Identity used to be encoded into the `date` string — `2026-08-04`,
/// `visual_2026-08-04`, `stage_1_5`, `visual_stage_1_5` — parsed by string
/// prefix wherever it mattered. That is what let poster rows leak into the clue
/// statistics (`date NOT LIKE 'stage_%'` matched neither `visual_` form) and
/// what made `ORDER BY date DESC` sort `"visual_…"` above real dates. Mode,
/// kind, date and stage now live in their own columns.
class GameSession {
  final int? id;
  final GameMode mode;
  final SessionKind kind;

  /// `YYYY-MM-DD` for daily sessions; empty for stage sessions.
  ///
  /// Empty rather than null so the partial unique indexes work — SQLite treats
  /// NULLs as distinct, which would let duplicates through.
  final String date;

  /// Stage number for stage sessions; 0 for daily sessions.
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

  /// A fresh daily session for [date].
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

  /// A fresh one-off session for a film received as a challenge.
  ///
  /// Identified by mode + film: a friend can send the same film twice and it is
  /// the same challenge, but the clue and poster versions are separate games.
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

  /// A fresh stage session for one film inside [stageId].
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

  /// Score the player would take by guessing right now.
  int get potentialScore =>
      status == GameStatus.playing ? rules.scoreAt(revealedClues) : score;

  bool get isFinished => status != GameStatus.playing;

  bool get canRevealMore => rules.canRevealMore(revealedClues);

  /// True when a wrong guess now ends the game.
  bool get isOnLastStep => rules.isLastStep(revealedClues);

  int get wrongGuessCount => guesses.length;

  /// Hints already paid for, ignoring any name no longer in the enum.
  Set<ExtraHint> get purchasedHints => {
        for (final name in extraHints)
          if (ExtraHint.values.any((h) => h.name == name))
            ExtraHint.values.firstWhere((h) => h.name == name),
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

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'mode': mode.name,
        'kind': kind.name,
        'date': date,
        'stage_id': stageId,
        'movie_id': movieId,
        'revealed_clues': revealedClues,
        'guesses': jsonEncode(guesses),
        'status': status.name,
        'score': score,
        'extra_hints': jsonEncode(extraHints),
      };

  factory GameSession.fromMap(Map<String, dynamic> map) => GameSession(
        id: map['id'] as int?,
        mode: GameMode.values.byName(map['mode'] as String),
        kind: SessionKind.values.byName(map['kind'] as String),
        date: map['date'] as String? ?? '',
        stageId: map['stage_id'] as int? ?? 0,
        movieId: map['movie_id'] as int,
        revealedClues: map['revealed_clues'] as int,
        guesses: (jsonDecode(map['guesses'] as String) as List).cast<String>(),
        status: GameStatus.values.byName(map['status'] as String),
        score: map['score'] as int,
        // Column added later; installs that predate it read as null.
        extraHints: map['extra_hints'] == null
            ? const []
            : (jsonDecode(map['extra_hints'] as String) as List).cast<String>(),
      );
}
