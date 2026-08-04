import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../core/utils/string_normalizer.dart';
import '../../domain/entities/extra_hint.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/scoring_rules.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/movie_repository.dart';
import '../../domain/repositories/stage_repository.dart';
import 'providers.dart';

/// Gaussian blur sigma per poster reveal level (1 = most blurry → 5 = clear).
const visualBlurSigmas = [22.0, 14.0, 8.0, 3.0, 0.0];

/// Human-readable blur labels, aligned with [visualBlurSigmas].
const visualBlurLabels = ['90%', '70%', '45%', '15%', '0%'];

enum GuessOutcome {
  correct,
  wrong,
  lost,
  invalid,

  /// Wrong, but the same franchise as the answer — shown as a hint.
  franchise,
}

/// State of one play-through, for either game mode.
///
/// `GameNotifier` and `VisualGameNotifier` were about 85% identical: same load /
/// reset / reveal / submit shape, same session handling, two copies of every
/// fix. They drifted anyway — the poster mode accepted franchise prefixes as
/// wins while the clue mode did not, and only one of them cleared `error`
/// correctly. One implementation parameterised by [GameMode] removes the class
/// of bug rather than the instances.
class PlayState {
  final GameMode mode;
  final Movie? movie;
  final GameSession? session;
  final bool isLoading;
  final String? error;

  /// Daily challenge number. Zero for stage play.
  final int challengeNumber;

  /// Film order of the stage being played, for the "next film" button.
  final List<int> stageMovieIds;

  final GuessOutcome? lastGuessOutcome;

  /// Increments on every submitted guess.
  ///
  /// Lets the UI react to a *new* outcome even when it repeats: comparing only
  /// `lastGuessOutcome` meant two consecutive franchise guesses showed the hint
  /// banner once.
  final int guessCount;

  const PlayState({
    required this.mode,
    this.movie,
    this.session,
    this.isLoading = true,
    this.error,
    this.challengeNumber = 0,
    this.stageMovieIds = const [],
    this.lastGuessOutcome,
    this.guessCount = 0,
  });

  ScoringRules get rules => ScoringRules.forMode(mode);

  bool get isStage => session?.isStage ?? false;
  int? get stageId => session?.isStage == true ? session!.stageId : null;

  /// Current reveal step (clue number, or blur level), 1-based.
  int get step => session?.revealedClues ?? 1;

  int get currentScore => session?.potentialScore ?? rules.maxScore;
  bool get isFinished => session?.isFinished ?? false;
  bool get canRevealMore => session?.canRevealMore ?? true;
  bool get isOnLastStep => session?.isOnLastStep ?? false;

  /// Blur strength for the poster mode; 0 once the game is over.
  double get blurSigma {
    if (mode != GameMode.poster) return 0;
    if (session?.status == GameStatus.won) return 0;
    return visualBlurSigmas[step.clamp(1, visualBlurSigmas.length) - 1];
  }

  String get blurLabel =>
      visualBlurLabels[step.clamp(1, visualBlurLabels.length) - 1];

  String? get posterAsset =>
      movie != null ? 'assets/posters/${movie!.id}.jpg' : null;

  /// Hints already paid for in this session.
  Set<ExtraHint> get purchasedHints => session?.purchasedHints ?? const {};

  /// Hints still available to buy.
  List<ExtraHint> get availableHints =>
      ExtraHint.values.where((h) => !purchasedHints.contains(h)).toList();

  PlayState copyWith({
    Movie? movie,
    GameSession? session,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? challengeNumber,
    List<int>? stageMovieIds,
    GuessOutcome? lastGuessOutcome,
    int? guessCount,
  }) {
    return PlayState(
      mode: mode,
      movie: movie ?? this.movie,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      challengeNumber: challengeNumber ?? this.challengeNumber,
      stageMovieIds: stageMovieIds ?? this.stageMovieIds,
      lastGuessOutcome: lastGuessOutcome ?? this.lastGuessOutcome,
      guessCount: guessCount ?? this.guessCount,
    );
  }
}

class PlayNotifier extends StateNotifier<PlayState> {
  final GameMode mode;
  final MovieRepository _movieRepo;
  final GameRepository _gameRepo;
  final StageRepository _stageRepo;

  PlayNotifier(this.mode, this._movieRepo, this._gameRepo, this._stageRepo)
      : super(PlayState(mode: mode));

  String get _stageProgressMode => mode == GameMode.clue ? 'clue' : 'poster';

  int _dailyMovieId(int totalMovies) => mode == GameMode.clue
      ? DailySelector.movieIdForDate(totalMovies)
      : DailySelector.posterMovieIdForDate(totalMovies);

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadDaily() async {
    state = PlayState(mode: mode, isLoading: true);
    try {
      final today = DailySelector.todayKey();
      final challenge = DailySelector.challengeNumber();
      final totalMovies = await _movieRepo.getMovieCount();

      if (totalMovies == 0) {
        state = PlayState(
          mode: mode,
          isLoading: false,
          error: 'Nenhum filme na base',
          challengeNumber: challenge,
        );
        return;
      }

      var session = await _gameRepo.getDailySession(mode, today);

      // An existing session pins the movie it started with, so a change in the
      // selection inputs can never swap the film mid-game.
      final movieId = session?.movieId ?? _dailyMovieId(totalMovies);
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        state = PlayState(
          mode: mode,
          isLoading: false,
          error: 'Filme não encontrado',
          challengeNumber: challenge,
        );
        return;
      }

      session ??= await _gameRepo.saveSession(
        GameSession.daily(mode: mode, date: today, movieId: movieId),
      );

      state = PlayState(
        mode: mode,
        movie: movie,
        session: session,
        isLoading: false,
        challengeNumber: challenge,
      );
    } catch (e) {
      state = PlayState(mode: mode, isLoading: false, error: e.toString());
    }
  }

  Future<void> loadStageFilm(
    int movieId,
    int stageId,
    List<int> stageMovieIds,
  ) async {
    state = PlayState(mode: mode, isLoading: true);
    try {
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        state = PlayState(
          mode: mode,
          isLoading: false,
          error: 'Filme não encontrado',
        );
        return;
      }

      var session = await _gameRepo.getStageSession(mode, stageId, movieId);
      session ??= await _gameRepo.saveSession(
        GameSession.stage(mode: mode, stageId: stageId, movieId: movieId),
      );

      state = PlayState(
        mode: mode,
        movie: movie,
        session: session,
        isLoading: false,
        stageMovieIds: stageMovieIds,
      );
    } catch (e) {
      state = PlayState(mode: mode, isLoading: false, error: e.toString());
    }
  }

  /// Loads a film received as a challenge from a friend (D10).
  ///
  /// Costs no ticket: the friend chose the film, and charging for an invitation
  /// would be a poor welcome.
  Future<void> loadChallenge(int movieId) async {
    state = PlayState(mode: mode, isLoading: true);
    try {
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        state = PlayState(
          mode: mode,
          isLoading: false,
          error: 'Filme não encontrado',
        );
        return;
      }

      var session = await _gameRepo.getChallengeSession(mode, movieId);
      session ??= await _gameRepo.saveSession(
        GameSession.challenge(mode: mode, movieId: movieId),
      );

      state = PlayState(
        mode: mode,
        movie: movie,
        session: session,
        isLoading: false,
      );
    } catch (e) {
      state = PlayState(mode: mode, isLoading: false, error: e.toString());
    }
  }

  /// Discards a finished stage session so the film can be replayed.
  Future<void> resetStageFilm(
    int movieId,
    int stageId,
    List<int> stageMovieIds,
  ) async {
    await _gameRepo.deleteStageSession(mode, stageId, movieId);
    await loadStageFilm(movieId, stageId, stageMovieIds);
  }

  // ── Play ───────────────────────────────────────────────────────────────────

  /// Records a hint the player paid tickets for.
  ///
  /// Does not touch `revealedClues`, so the score is unaffected — the cost was
  /// paid in tickets. Charging happens in `buyHintWithTicket`, which owns the
  /// balance; this only persists the outcome.
  Future<void> grantHint(ExtraHint hint) async {
    final session = state.session;
    if (session == null || session.isFinished || session.hasHint(hint)) return;

    final saved = await _gameRepo.saveSession(
      session.copyWith(extraHints: [...session.extraHints, hint.name]),
    );
    state = state.copyWith(session: saved);
  }

  /// Reveals the next clue / blur level, giving up one point.
  Future<void> revealNext() async {
    final session = state.session;
    if (session == null || session.isFinished || !session.canRevealMore) return;

    final saved = await _gameRepo.saveSession(
      session.copyWith(revealedClues: session.revealedClues + 1),
    );
    state = state.copyWith(session: saved);
  }

  Future<GuessOutcome> submitGuess(String guess) async {
    final session = state.session;
    final movie = state.movie;
    if (session == null || movie == null || session.isFinished) {
      return GuessOutcome.invalid;
    }

    // Exact match is the ONLY acceptance criterion, in both modes. Franchise
    // proximity is a hint; accepting prefixes awarded full marks for the wrong
    // film in 205 title combinations of the bundled catalogue.
    if (StringNormalizer.isExactMatch(guess, movie.acceptedTitles)) {
      final won = await _gameRepo.saveSession(session.copyWith(
        status: GameStatus.won,
        score: session.potentialScore,
      ));
      state = state.copyWith(
        session: won,
        lastGuessOutcome: GuessOutcome.correct,
        guessCount: state.guessCount + 1,
      );

      if (session.isStage) {
        await _stageRepo.markMovieCompleted(
          session.stageId,
          movie.id,
          mode: _stageProgressMode,
        );
      }
      return GuessOutcome.correct;
    }

    final newGuesses = [...session.guesses, guess];

    if (session.isOnLastStep) {
      final lost = await _gameRepo.saveSession(session.copyWith(
        guesses: newGuesses,
        status: GameStatus.lost,
        score: 0,
      ));
      state = state.copyWith(
        session: lost,
        lastGuessOutcome: GuessOutcome.lost,
        guessCount: state.guessCount + 1,
      );
      return GuessOutcome.lost;
    }

    // Wrong guess burns the next step.
    final isFranchise =
        StringNormalizer.isSameFranchise(guess, movie.acceptedTitles);
    final outcome = isFranchise ? GuessOutcome.franchise : GuessOutcome.wrong;

    final saved = await _gameRepo.saveSession(session.copyWith(
      guesses: newGuesses,
      revealedClues: session.revealedClues + 1,
    ));
    state = state.copyWith(
      session: saved,
      lastGuessOutcome: outcome,
      guessCount: state.guessCount + 1,
    );
    return outcome;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers — one per mode, same implementation
// ─────────────────────────────────────────────────────────────────────────────

PlayNotifier _build(Ref ref, GameMode mode) => PlayNotifier(
      mode,
      ref.read(movieRepositoryProvider),
      ref.read(gameRepositoryProvider),
      ref.read(stageRepositoryProvider),
    );

final clueGameProvider = StateNotifierProvider<PlayNotifier, PlayState>(
  (ref) => _build(ref, GameMode.clue),
);

final posterGameProvider = StateNotifierProvider<PlayNotifier, PlayState>(
  (ref) => _build(ref, GameMode.poster),
);
