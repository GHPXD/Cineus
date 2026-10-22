import 'color_question.dart';
import 'saved_color_session.dart';

class ColorStage {
  final int id;
  final List<ColorQuestion> questions;
  const ColorStage(this.id, this.questions);
  int get matches => questions.length ~/ 5;
  List<ColorQuestion> match(int index) {
    if (index < 0 || index >= matches) throw RangeError.index(index, questions);
    return questions.sublist(index * 5, (index + 1) * 5);
  }
}

/// Published ordering is bundled, so a catalogue update cannot reshuffle progress.
class ColorStageCatalog {
  final String version;
  final ColorPilotCatalog colors;
  final List<ColorStage> stages;
  const ColorStageCatalog._(this.version, this.colors, this.stages);
  factory ColorStageCatalog.fromJson(
    Map<String, dynamic> json,
    ColorPilotCatalog colors,
  ) {
    if (json['schema'] != 1 || (json['version'] as String).isEmpty) {
      throw const FormatException('Invalid stage pack');
    }
    final byId = {for (final q in colors.questions) q.id: q};
    final used = <String>{};
    final regions = <String>{};
    final stages = <ColorStage>[];
    for (final raw in json['stages'] as List) {
      final ids = (raw['questions'] as List).cast<String>();
      final questions = [
        for (final id in ids)
          byId[id] ?? (throw FormatException('Missing region $id')),
      ];
      if (raw['id'] != stages.length + 1 ||
          questions.length != 10 ||
          questions.map((q) => q.characterId).toSet().length != 10 ||
          questions.any((q) => !regions.add('${q.characterId}:${q.artPart}')) ||
          ids.any((id) => !used.add(id))) {
        throw const FormatException(
          'Stage requires ten distinct characters and unused regions',
        );
      }
      stages.add(ColorStage(raw['id'] as int, List.unmodifiable(questions)));
    }
    if (stages.isEmpty) throw const FormatException('Empty stages');
    return ColorStageCatalog._(
      json['version'] as String,
      colors,
      List.unmodifiable(stages),
    );
  }
  ColorStage stage(int id) => stages.singleWhere(
    (s) => s.id == id,
    orElse: () => throw StateError('Unknown stage'),
  );
}

class ColorStageProgress {
  final ColorStage stage;
  final bool locked;
  final List<SavedColorSession> sessions;
  const ColorStageProgress(this.stage, this.locked, this.sessions);
  int get completed =>
      sessions.fold(0, (sum, s) => sum + s.game.answers.length);
  bool get finished =>
      sessions.length == stage.matches &&
      sessions.every((s) => s.status == 'completed');
  SavedColorSession? record(int match) =>
      sessions.where((s) => s.stageMatch == match).firstOrNull;
  static List<ColorStageProgress> from(
    ColorStageCatalog catalog,
    List<SavedColorSession> records,
  ) {
    var unlocked = true;
    return [
      for (final stage in catalog.stages)
        (() {
          final progress = ColorStageProgress(
            stage,
            !unlocked,
            records
                .where(
                  (s) =>
                      s.stageId == stage.id &&
                      s.stageVersion == catalog.version,
                )
                .toList(),
          );
          unlocked = unlocked && progress.finished;
          return progress;
        })(),
    ];
  }
}
