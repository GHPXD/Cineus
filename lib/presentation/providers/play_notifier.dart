import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../core/utils/string_normalizer.dart';
import '../../domain/entities/extra_hint.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/scoring_rules.dart';
import '../../data/services/disabled_product_telemetry.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/movie_repository.dart';
import '../../domain/repositories/stage_repository.dart';
import 'providers.dart';
import 'growth_provider.dart';
import 'progress_provider.dart';
import 'daily_calendar_provider.dart';
import 'app_clock.dart';
import 'telemetry_provider.dart';
import '../visuals/poster_assets.dart';

const visualBlurSigmas = [22.0, 14.0, 8.0, 3.0, 0.0];
const visualBlurLabels = ['90%', '70%', '45%', '15%', '0%'];

enum GuessOutcome { correct, wrong, lost, invalid, franchise }

/// UI-neutral reason why a play surface could not be loaded.
///
/// The provider used to leak Portuguese strings into the presentation layer,
/// which made English/Spanish error states impossible to localise and made
/// retry behaviour depend on parsing display text. Keep the domain reason typed
/// and let each screen decide how to present/recover from it.
enum PlayLoadError { noMovies, movieNotFound, loadFailed }

class PlayState {
  final GameMode mode;
  final Movie? movie;
  final GameSession? session;
  final bool isLoading;
  final PlayLoadError? error;
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
  bool get isDaily => session?.isDaily ?? false;
  bool get isStage => session?.isStage ?? false;
  bool get isChallenge => session?.isChallenge ?? false;
  bool get isCurrentDaily =>
      isDaily && session?.date == DailySelector.todayKey();
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
      movie != null ? PosterAssets.path(movie!.id) : null;

  Set<ExtraHint> get purchasedHints => session?.purchasedHints ?? const {};

  List<ExtraHint> get availableHints =>
      ExtraHint.values.where((h) => !purchasedHints.contains(h)).toList();

  PlayState copyWith({
    Movie? movie,
    GameSession? session,
    bool? isLoading,
    PlayLoadError? error,
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
  final DateTime Function() _now;
  final ProductTelemetry _telemetry;

  /// Newer loads supersede older ones. This prevents a slow request from an old
  /// route from replacing the state selected by a later navigation.
  int _loadGeneration = 0;

  /// Every new load also starts a new play epoch. Actions queued for a previous
  /// film become no-ops instead of mutating whichever film happens to be current
  /// when they eventually execute.
  int _sessionEpoch = 0;

  /// Serializes reveal/guess/hint mutations so rapid taps never write from the
  /// same stale session snapshot.
  Future<void> _actionTail = Future<void>.value();

  PlayNotifier(
    this.mode,
    this._movieRepo,
    this._gameRepo,
    this._stageRepo, {
    DateTime Function()? now,
    ProductTelemetry telemetry = const DisabledProductTelemetry(),
    Future<int?> Function(GameMode mode, String date)? scheduledMovie,
    Future<void> Function(int stage)? stageOpened,
    void Function()? opened,
  }) : _now = now ?? DateTime.now,
       _telemetry = telemetry,
       _scheduledMovie = scheduledMovie,
       _stageOpened = stageOpened,
       _opened = opened,
       super(PlayState(mode: mode));

  final Future<int?> Function(GameMode mode, String date)? _scheduledMovie;
  final Future<void> Function(int stage)? _stageOpened;
  final void Function()? _opened;

  String get _stageProgressMode => mode == GameMode.clue ? 'clue' : 'poster';

  void _recordOpened(GameSession session) {
    _opened?.call();
    if (session.isFinished) return;
    unawaited(
      _telemetry.record(
        'game_opened',
        properties: {'mode': mode.name, 'kind': session.kind.name},
      ),
    );
  }

  int _dailyMovieId(List<int> ids, DateTime date) {
    final index = mode == GameMode.clue
        ? DailySelector.movieIndexForDate(ids.length, date)
        : DailySelector.posterMovieIndexForDate(ids.length, date);
    return ids[index];
  }

  Future<T> _serializeAction<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _actionTail = _actionTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  int _beginLoad() {
    _sessionEpoch++;
    return ++_loadGeneration;
  }

  bool _isCurrentLoad(int generation) =>
      mounted && generation == _loadGeneration;

  void _publishLoad(int generation, PlayState next) {
    if (_isCurrentLoad(generation)) state = next;
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<bool> loadDaily() async {
    final generation = _beginLoad();
    state = PlayState(mode: mode, isLoading: true);
    try {
      final date = _now();
      final today = DailySelector.todayKey(date);
      final challenge = DailySelector.challengeNumber(date);
      final movieIds = await _movieRepo.getMovieIds();

      if (movieIds.isEmpty) {
        _publishLoad(
          generation,
          PlayState(
            mode: mode,
            isLoading: false,
            error: PlayLoadError.noMovies,
            challengeNumber: challenge,
          ),
        );
        return false;
      }

      var session = await _gameRepo.getDailySession(mode, today);
      final movieId =
          session?.movieId ??
          await _scheduledMovie?.call(mode, today) ??
          _dailyMovieId(movieIds, date);
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        _publishLoad(
          generation,
          PlayState(
            mode: mode,
            isLoading: false,
            error: PlayLoadError.movieNotFound,
            challengeNumber: challenge,
          ),
        );
        return false;
      }

      session ??= await _gameRepo.saveSession(
        GameSession.daily(mode: mode, date: today, movieId: movieId),
      );

      if (!_isCurrentLoad(generation)) return false;
      state = PlayState(
        mode: mode,
        movie: movie,
        session: session,
        isLoading: false,
        challengeNumber: challenge,
      );
      _recordOpened(session);
      return true;
    } catch (_) {
      _publishLoad(
        generation,
        PlayState(
          mode: mode,
          isLoading: false,
          error: PlayLoadError.loadFailed,
        ),
      );
      return false;
    }
  }

  Future<bool> loadStageFilm(
    int movieId,
    int stageId,
    List<int> stageMovieIds,
  ) async {
    final generation = _beginLoad();
    state = PlayState(mode: mode, isLoading: true);
    try {
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        _publishLoad(
          generation,
          PlayState(
            mode: mode,
            isLoading: false,
            error: PlayLoadError.movieNotFound,
          ),
        );
        return false;
      }

      var session = await _gameRepo.getStageSession(mode, stageId, movieId);
      await _stageOpened?.call(stageId);
      session ??= await _gameRepo.saveSession(
        GameSession.stage(mode: mode, stageId: stageId, movieId: movieId),
      );

      // A process kill after saving the win but before stage_progress used to
      // leave the stage permanently inconsistent. Loading a won session repairs
      // the derived progress idempotently.
      if (session.status == GameStatus.won) {
        await _stageRepo.markMovieCompleted(
          stageId,
          movieId,
          mode: _stageProgressMode,
        );
      }

      if (!_isCurrentLoad(generation)) return false;
      state = PlayState(
        mode: mode,
        movie: movie,
        session: session,
        isLoading: false,
        stageMovieIds: stageMovieIds,
      );
      _recordOpened(session);
      return true;
    } catch (_) {
      _publishLoad(
        generation,
        PlayState(
          mode: mode,
          isLoading: false,
          error: PlayLoadError.loadFailed,
        ),
      );
      return false;
    }
  }

  Future<bool> loadChallenge(int movieId, {String? invitation}) async {
    if (invitation != null &&
        !RegExp(r'^[A-Za-z0-9_-]{12}$').hasMatch(invitation)) {
      return false;
    }
    final generation = _beginLoad();
    state = PlayState(mode: mode, isLoading: true);
    try {
      final movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) {
        _publishLoad(
          generation,
          PlayState(
            mode: mode,
            isLoading: false,
            error: PlayLoadError.movieNotFound,
          ),
        );
        return false;
      }

      var session = invitation == null
          ? await _gameRepo.getChallengeSession(mode, movieId)
          : null;
      session ??= await _gameRepo.saveSession(
        GameSession.challenge(
          mode: mode,
          movieId: movieId,
        ).copyWith(date: invitation == null ? '' : 'friend:$invitation'),
      );

      if (!_isCurrentLoad(generation)) return false;
      state = PlayState(
        mode: mode,
        movie: movie,
        session: session,
        isLoading: false,
      );
      _recordOpened(session);
      return true;
    } catch (_) {
      _publishLoad(
        generation,
        PlayState(
          mode: mode,
          isLoading: false,
          error: PlayLoadError.loadFailed,
        ),
      );
      return false;
    }
  }

  /// Free practice/archive use distinct identities and never replace a daily,
  /// stage or invitation result. Archive creation is idempotent for its date.
  Future<bool> loadPractice(int movieId, {String? archiveDate}) async {
    final generation = _beginLoad();
    state = PlayState(mode: mode, isLoading: true);
    try {
      if (archiveDate != null &&
          (DailySelector.dateFromKey(archiveDate) == null ||
              archiveDate.compareTo(DailySelector.todayKey(_now())) >= 0)) {
        throw const FormatException('Archive requires a past date');
      }
      var movie = await _movieRepo.getMovieById(movieId);
      if (movie == null) throw StateError('Movie unavailable');
      final session = await _gameRepo.saveSession(
        GameSession(
          mode: mode,
          kind: archiveDate == null
              ? SessionKind.training
              : SessionKind.archive,
          movieId: movieId,
          date:
              archiveDate ??
              '${_now().toUtc().microsecondsSinceEpoch}-$_sessionEpoch',
        ),
      );
      if (session.movieId != movieId) {
        movie = await _movieRepo.getMovieById(session.movieId);
      }
      if (movie == null) throw StateError('Original movie unavailable');
      if (!_isCurrentLoad(generation)) return false;
      state = PlayState(
        mode: mode,
        movie: movie,
        session: session,
        isLoading: false,
      );
      _recordOpened(session);
      return true;
    } catch (_) {
      _publishLoad(
        generation,
        PlayState(
          mode: mode,
          isLoading: false,
          error: PlayLoadError.loadFailed,
        ),
      );
      return false;
    }
  }

  Future<bool> resume(GameSession session) async {
    final generation = _beginLoad();
    final movie = await _movieRepo.getMovieById(session.movieId);
    if (movie == null || !_isCurrentLoad(generation)) return false;
    final stages = session.isStage
        ? await _stageRepo.getAllStages(mode: _stageProgressMode)
        : null;
    if (!_isCurrentLoad(generation)) return false;
    state = PlayState(
      mode: mode,
      movie: movie,
      session: session,
      isLoading: false,
      stageMovieIds:
          stages?.where((s) => s.id == session.stageId).firstOrNull?.movieIds ??
          const [],
    );
    return true;
  }

  Future<bool> resetStageFilm(
    int movieId,
    int stageId,
    List<int> stageMovieIds,
  ) async {
    try {
      await _gameRepo.deleteStageSession(mode, stageId, movieId);
      return await loadStageFilm(movieId, stageId, stageMovieIds);
    } catch (_) {
      return false;
    }
  }

  // ── Play ───────────────────────────────────────────────────────────────────

  Future<bool> grantHint(ExtraHint hint, {int? expectedSessionId}) {
    if (!mounted) return Future.value(false);
    final epoch = _sessionEpoch;
    return _serializeAction(() async {
      if (!mounted || epoch != _sessionEpoch) return false;
      final session = state.session;
      if (session == null ||
          (expectedSessionId != null && session.id != expectedSessionId) ||
          session.isFinished ||
          session.hasHint(hint)) {
        return false;
      }

      final saved = await _gameRepo.saveSession(
        session.copyWith(extraHints: [...session.extraHints, hint.name]),
      );
      if (mounted && epoch == _sessionEpoch) {
        state = state.copyWith(session: saved);
      }
      return saved.hasHint(hint);
    });
  }

  Future<void> revealNext() {
    final epoch = _sessionEpoch;
    return _serializeAction(() async {
      if (epoch != _sessionEpoch) return;
      final session = state.session;
      if (session == null || session.isFinished || !session.canRevealMore) {
        return;
      }

      final saved = await _gameRepo.saveSession(
        session.copyWith(revealedClues: session.revealedClues + 1),
      );
      if (epoch == _sessionEpoch) state = state.copyWith(session: saved);
    });
  }

  Future<GuessOutcome> submitGuess(
    String guess, {
    int? selectedMovieId,
    int? selectedMovieYear,
  }) {
    final epoch = _sessionEpoch;
    return _serializeAction(() async {
      if (epoch != _sessionEpoch) return GuessOutcome.invalid;

      final session = state.session;
      final movie = state.movie;
      if (session == null || movie == null || session.isFinished) {
        return GuessOutcome.invalid;
      }

      final exactTitle = StringNormalizer.isExactMatch(
        guess,
        movie.acceptedTitles,
      );
      if (exactTitle &&
          (selectedMovieId == null || selectedMovieId == movie.id)) {
        final won = await _gameRepo.saveSession(
          session.copyWith(
            status: GameStatus.won,
            score: session.potentialScore,
          ),
        );
        if (epoch != _sessionEpoch) return GuessOutcome.invalid;

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

      final newGuesses = [
        ...session.guesses,
        selectedMovieYear == null ? guess : '$guess ($selectedMovieYear)',
      ];

      if (session.isOnLastStep) {
        final lost = await _gameRepo.saveSession(
          session.copyWith(
            guesses: newGuesses,
            status: GameStatus.lost,
            score: 0,
          ),
        );
        if (epoch != _sessionEpoch) return GuessOutcome.invalid;
        state = state.copyWith(
          session: lost,
          lastGuessOutcome: GuessOutcome.lost,
          guessCount: state.guessCount + 1,
        );
        return GuessOutcome.lost;
      }

      final isFranchise =
          !exactTitle &&
          StringNormalizer.isSameFranchise(guess, movie.acceptedTitles);
      final outcome = isFranchise ? GuessOutcome.franchise : GuessOutcome.wrong;

      final saved = await _gameRepo.saveSession(
        session.copyWith(
          guesses: newGuesses,
          revealedClues: session.revealedClues + 1,
        ),
      );
      if (epoch != _sessionEpoch) return GuessOutcome.invalid;
      state = state.copyWith(
        session: saved,
        lastGuessOutcome: outcome,
        guessCount: state.guessCount + 1,
      );
      return outcome;
    });
  }
}

PlayNotifier _build(Ref ref, GameMode mode) {
  final calendar = ref.read(dailyCalendarProvider.future);
  final economy = ref.read(economyRepositoryProvider);
  final telemetry = ref.read(productTelemetryProvider);
  var active = true;
  ref.onDispose(() => active = false);
  return PlayNotifier(
    mode,
    ref.read(movieRepositoryProvider),
    ref.read(gameRepositoryProvider),
    ref.read(stageRepositoryProvider),
    now: ref.read(appClockProvider),
    telemetry: ref.read(productTelemetryProvider),
    scheduledMovie: (mode, date) async => (await calendar).movie(mode, date),
    stageOpened: (stage) async {
      if (!active) return;
      final config = ref.read(growthConfigurationProvider);
      final bonus = await economy.pin(mode.name, stage, config.stageBonus);
      await telemetry.record(
        'experiment_exposed',
        properties: {'variant': bonus == 4 ? 'economy_v2' : 'control'},
      );
    },
    opened: () {
      if (active) ref.invalidate(continuingGameProvider);
    },
  );
}

final clueGameProvider = StateNotifierProvider<PlayNotifier, PlayState>(
  (ref) => _build(ref, GameMode.clue),
);

final posterGameProvider = StateNotifierProvider<PlayNotifier, PlayState>(
  (ref) => _build(ref, GameMode.poster),
);
