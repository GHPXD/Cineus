import 'dart:ui';

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
import '../../l10n/app_l10n.dart';
import 'locale_notifier.dart';
import 'providers.dart';

const visualBlurSigmas = [22.0, 14.0, 8.0, 3.0, 0.0];
const visualBlurLabels = ['90%', '70%', '45%', '15%', '0%'];

enum GuessOutcome {
  correct,
  wrong,
  lost,
  invalid,
  franchise,
}

enum PlayLoadError {
  noMovies,
  movieNotFound,
  loadFailed,
}

class PlayState {
  final GameMode mode;
  final Movie? movie;
  final GameSession? session;
  final bool isLoading;
  final String? error;
  final int challengeNumber;
  final List<int> stageMovieIds;
  final GuessOutcome? lastGuessOutcome;
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
  int get step => session?.revealedClues ?? 1;
  int get currentScore => session?.potentialScore ?? rules.maxScore;
  bool get isFinished => session?.isFinished ?? false;
  bool get canRevealMore => session?.canRevealMore ?? true;
  bool get isOnLastStep => session?.isOnLastStep ?? false;

  double get blurSigma {
    if (mode != GameMode.poster) return 0;
    if (session?.status == GameStatus.won) return 0;
    return visualBlurSigmas[step.clamp(1, visualBlurSigmas.length) - 1];
  }

  String get blurLabel =>
      visualBlurLabels[step.clamp(1, visualBlurLabels.length) - 1];

  String? get posterAsset =>
      movie != null ? 'assets/posters/${movie!.id}.jpg' : null;

  Set<ExtraHint> get purchasedHints => session?.purchasedHints ?? const {};
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
  final String Function(PlayLoadError error) _errorText;

  PlayNotifier(
    this.mode,
    this._movieRepo,
    this._gameRepo,
    this._stageRepo, {
    String Function(PlayLoadError error)? errorText,
  })  : _errorText = errorText ?? _fallbackErrorText,
        super(PlayState(mode: mode));

  static String _fallbackErrorText(PlayLoadError error) => switch (error) {
        PlayLoadError.noMovies => 'No movies available',
        PlayLoadError.movieNotFound => 'Movie not found',
        PlayLoadError.loadFailed => 'Could not load the game',
      };

  String get _stageProgressMode => mode == GameMode.clue ? 'clue' : 'poster';

  int _dailyMovieId(int totalMovies) => mode == GameMode.clue
      ? DailySelector.movieIdForDate(totalMovies)
      : DailySelector.posterMovieIdForDate(totalMovies);

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
          error: _errorText(PlayLoadError.noMovies),
          challengeNumber: challenge,
        );
        return;
      }

      var session = await _gameRepo.getDailySession(mode, today);
      final movieId = session?.movieId ?? _dailyMovieId(totalMovies);
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        state = PlayState(
          mode: mode,
          isLoading: false,
          error: _errorText(PlayLoadError.movieNotFound),
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
    } catch (_) {
      state = PlayState(
        mode: mode,
        isLoading: false,
        error: _errorText(PlayLoadError.loadFailed),
      );
    }
  }

  Future<bool> loadStageFilm(
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
          error: _errorText(PlayLoadError.movieNotFound),
        );
        return false;
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
      return true;
    } catch (_) {
      state = PlayState(
        mode: mode,
        isLoading: false,
        error: _errorText(PlayLoadError.loadFailed),
      );
      return false;
    }
  }

  Future<void> loadChallenge(int movieId) async {
    state = PlayState(mode: mode, isLoading: true);
    try {
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        state = PlayState(
          mode: mode,
          isLoading: false,
          error: _errorText(PlayLoadError.movieNotFound),
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
    } catch (_) {
      state = PlayState(
        mode: mode,
        isLoading: false,
        error: _errorText(PlayLoadError.loadFailed),
      );
    }
  }

  Future<bool> resetStageFilm(
    int movieId,
    int stageId,
    List<int> stageMovieIds,
  ) async {
    try {
      await _gameRepo.deleteStageSession(mode, stageId, movieId);
    } catch (_) {
      state = PlayState(
        mode: mode,
        isLoading: false,
        error: _errorText(PlayLoadError.loadFailed),
      );
      return false;
    }
    return loadStageFilm(movieId, stageId, stageMovieIds);
  }

  Future<void> grantHint(ExtraHint hint) async {
    final session = state.session;
    if (session == null || session.isFinished || session.hasHint(hint)) return;

    final saved = await _gameRepo.saveSession(
      session.copyWith(extraHints: [...session.extraHints, hint.name]),
    );
    state = state.copyWith(session: saved);
  }

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

String _localizedPlayError(Ref ref, PlayLoadError error) {
  final override = ref.read(localeNotifierProvider);
  final device = PlatformDispatcher.instance.locale;
  final locale = override ??
      (LocaleNotifier.isSupported(device) ? device : const Locale('pt'));
  final l10n = lookupAppL10n(locale);

  return switch (error) {
    PlayLoadError.noMovies => l10n.noMoviesInDatabase,
    PlayLoadError.movieNotFound => l10n.movieNotFound,
    PlayLoadError.loadFailed => switch (locale.languageCode) {
        'en' => 'Could not load the game. Try again.',
        'es' => 'No se pudo cargar el juego. Inténtalo de nuevo.',
        _ => 'Não foi possível carregar o jogo. Tente novamente.',
      },
  };
}

PlayNotifier _build(Ref ref, GameMode mode) => PlayNotifier(
      mode,
      ref.read(movieRepositoryProvider),
      ref.read(gameRepositoryProvider),
      ref.read(stageRepositoryProvider),
      errorText: (error) => _localizedPlayError(ref, error),
    );

final clueGameProvider = StateNotifierProvider<PlayNotifier, PlayState>(
  (ref) => _build(ref, GameMode.clue),
);

final posterGameProvider = StateNotifierProvider<PlayNotifier, PlayState>(
  (ref) => _build(ref, GameMode.poster),
);
