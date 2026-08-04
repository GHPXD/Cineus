class Clue {
  final int id;
  final int movieId;
  final int clueNumber;
  final String category;
  final String text;

  const Clue({
    required this.id,
    required this.movieId,
    required this.clueNumber,
    required this.category,
    required this.text,
  });

  Clue copyWith({
    int? id,
    int? movieId,
    int? clueNumber,
    String? category,
    String? text,
  }) {
    return Clue(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      clueNumber: clueNumber ?? this.clueNumber,
      category: category ?? this.category,
      text: text ?? this.text,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Clue && other.id == id && other.clueNumber == clueNumber;

  @override
  int get hashCode => Object.hash(id, clueNumber);
}
