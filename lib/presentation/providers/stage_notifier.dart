import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/stage.dart';
import '../../domain/repositories/stage_repository.dart';

class StageNotifier extends StateNotifier<AsyncValue<List<Stage>>> {
  final StageRepository _repo;
  final String mode;

  StageNotifier(this._repo, {this.mode = 'clue'})
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final stages = await _repo.getAllStages(mode: mode);
      state = AsyncValue.data(stages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
