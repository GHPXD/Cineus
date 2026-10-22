import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/progress_repository.dart';
import 'providers.dart';
import 'app_clock.dart';

export '../../data/repositories/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.read(databaseProvider),
    ref.read(appClockProvider),
  ),
);
final activityScopeProvider = StateProvider<ActivityScope>(
  (_) => ActivityScope.all,
);
final presenceProvider = FutureProvider<PresenceProgress>(
  (ref) => ref.watch(progressRepositoryProvider).presence(),
);
final continuingGameProvider = FutureProvider(
  (ref) => ref.watch(progressRepositoryProvider).continuing(),
);
