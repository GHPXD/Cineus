import '../entities/stage.dart';

abstract class StageRepository {
  Future<List<Stage>> getAllStages({String mode = 'clue'});
  Future<void> markMovieCompleted(
    int stageId,
    int movieId, {
    String mode = 'clue',
  });
}
