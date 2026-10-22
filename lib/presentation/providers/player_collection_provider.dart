import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/player_collection.dart';
import '../../data/repositories/player_collection_repository.dart';
import 'providers.dart';
import 'app_clock.dart';

final collectionCatalogProvider = Provider<List<CollectionItem>>(
  (_) => PlayerCollectionCatalog.items,
);
final playerCollectionRepositoryProvider = Provider<PlayerCollectionRepository>(
  (ref) => PlayerCollectionRepository(
    ref.read(databaseProvider),
    catalog: ref.read(collectionCatalogProvider),
    now: ref.read(appClockProvider),
  ),
);

class PlayerCollectionState {
  final PlayerCollection? profile;
  final bool loading, saving, hasError;
  const PlayerCollectionState({
    this.profile,
    this.loading = false,
    this.saving = false,
    this.hasError = false,
  });
}

class PlayerCollectionNotifier extends StateNotifier<PlayerCollectionState> {
  final PlayerCollectionRepository repository;
  bool _loading = false;
  late final Future<void> ready;
  PlayerCollectionNotifier(this.repository)
    : super(const PlayerCollectionState(loading: true)) {
    ready = load();
  }
  Future<void> load() async {
    if (state.saving || _loading) return;
    _loading = true;
    state = PlayerCollectionState(profile: state.profile, loading: true);
    try {
      final profile = await repository.load();
      if (mounted) state = PlayerCollectionState(profile: profile);
    } catch (_) {
      if (mounted) {
        state = PlayerCollectionState(profile: state.profile, hasError: true);
      }
    } finally {
      _loading = false;
    }
  }

  Future<bool> _save(Future<PlayerCollection> Function() action) async {
    if (state.saving || state.loading || state.profile == null) return false;
    final previous = state.profile;
    state = PlayerCollectionState(profile: previous, saving: true);
    try {
      final profile = await action();
      if (mounted) state = PlayerCollectionState(profile: profile);
      return true;
    } catch (_) {
      if (mounted) {
        state = PlayerCollectionState(profile: previous, hasError: true);
      }
      return false;
    }
  }

  Future<bool> equip(String itemId) => _save(() => repository.equip(itemId));
  Future<bool> saveIdentity(String name, bool show) =>
      _save(() => repository.saveIdentity(name, show));
}

final playerCollectionProvider =
    StateNotifierProvider<PlayerCollectionNotifier, PlayerCollectionState>(
      (ref) => PlayerCollectionNotifier(
        ref.read(playerCollectionRepositoryProvider),
      ),
    );
