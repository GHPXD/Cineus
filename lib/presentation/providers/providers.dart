import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/database_provider.dart';
import '../../data/repositories/app_meta_repository_impl.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../data/repositories/movie_repository_impl.dart';
import '../../data/repositories/reward_repository_impl.dart';
import '../../data/repositories/stage_repository_impl.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/player_tickets.dart';
import '../../domain/entities/stage.dart';
import '../../domain/repositories/app_meta_repository.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/movie_repository.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/repositories/stage_repository.dart';
import 'stage_notifier.dart';
import 'ticket_notifier.dart';

/// Database seam. Overriding this in a test swaps in an in-memory SQLite.
final databaseProvider = Provider<DatabaseProvider>((_) {
  return DatabaseHelper.instance;
});

/// Repository providers
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(ref.read(databaseProvider));
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl(ref.read(databaseProvider));
});

final stageRepositoryProvider = Provider<StageRepository>((ref) {
  return StageRepositoryImpl(ref.read(databaseProvider));
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepositoryImpl(ref.read(databaseProvider));
});

final appMetaRepositoryProvider = Provider<AppMetaRepository>((ref) {
  return AppMetaRepositoryImpl(ref.read(databaseProvider));
});

/// Whether the how-to-play screen has already been shown (D3).
///
/// The guide was complete but only reachable from a small `?` button inside the
/// game header, so a first-time player never saw the rules.
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  return ref.read(appMetaRepositoryProvider).hasSeenOnboarding();
});

/// Ticket provider
final ticketNotifierProvider =
    StateNotifierProvider<TicketNotifier, PlayerTickets>((ref) {
  return TicketNotifier(ref.read(databaseProvider));
});

/// Stage list provider (clue mode)
final stageNotifierProvider =
    StateNotifierProvider<StageNotifier, AsyncValue<List<Stage>>>((ref) {
  return StageNotifier(ref.read(stageRepositoryProvider), mode: 'clue');
});

/// Stage list provider (poster mode — separate progress tracking)
final posterStageNotifierProvider =
    StateNotifierProvider<StageNotifier, AsyncValue<List<Stage>>>((ref) {
  return StageNotifier(ref.read(stageRepositoryProvider), mode: 'poster');
});

/// Today's daily session per mode, read straight from the database so the home
/// screen does not depend on whichever game is currently loaded in a notifier.
final dailySessionProvider =
    FutureProvider.autoDispose.family<GameSession?, GameMode>(
  (ref, mode) async {
    final gameRepo = ref.read(gameRepositoryProvider);
    return gameRepo.getDailySession(mode, DailySelector.todayKey());
  },
);
