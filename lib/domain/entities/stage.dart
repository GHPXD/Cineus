enum StageStatus { locked, unlocked, completed }

class Stage {
  final int id;
  final int orderIndex;
  final String name;
  final List<int> movieIds;
  final StageStatus status;
  final int completedCount;

  const Stage({
    required this.id,
    required this.orderIndex,
    required this.name,
    required this.movieIds,
    this.status = StageStatus.locked,
    this.completedCount = 0,
  });

  int get totalMovies => movieIds.length;
  bool get isLocked => status == StageStatus.locked;
  bool get isCompleted => status == StageStatus.completed;
  double get progress =>
      totalMovies == 0 ? 0 : completedCount / totalMovies;

  Stage copyWith({StageStatus? status, int? completedCount}) {
    return Stage(
      id: id,
      orderIndex: orderIndex,
      name: name,
      movieIds: movieIds,
      status: status ?? this.status,
      completedCount: completedCount ?? this.completedCount,
    );
  }
}
