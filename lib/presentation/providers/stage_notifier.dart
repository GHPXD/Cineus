import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/stage.dart';
import '../../domain/repositories/stage_repository.dart';

class StageNotifier extends StateNotifier<AsyncValue<List<Stage>>> {
  final StageRepository _repo;
  final String mode;
  int _generation = 0;

  StageNotifier(this._repo, {this.mode = 'clue'})
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    final generation = ++_generation;
    state = const AsyncValue.loading();
    try {
      final stages = await _repo.getAllStages(mode: mode);
      if (!mounted || generation != _generation) return;
      state = AsyncValue.data(stages);
    } catch (e, st) {
      if (!mounted || generation != _generation) return;
      state = AsyncValue.error(e, st);
    }
  }
}
