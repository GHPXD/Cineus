import 'dart:math';
import 'color_question.dart';
import 'color_scoring.dart';

/// HSB values independent from Flutter; the chosen sRGB bytes are scored exactly.
class ColorSelection {
  final double hue, saturation, brightness;
  const ColorSelection._(this.hue, this.saturation, this.brightness);
  static const initial = ColorSelection._(200, 50, 50);
  factory ColorSelection(double hue, double saturation, double brightness) {
    if (!hue.isFinite ||
        !saturation.isFinite ||
        !brightness.isFinite ||
        hue < 0 ||
        hue > 360 ||
        saturation < 0 ||
        saturation > 100 ||
        brightness < 0 ||
        brightness > 100) {
      throw ArgumentError('Expected H[0,360], S/B[0,100]');
    }
    return ColorSelection._(hue, saturation, brightness);
  }

  List<double> toJson() => [hue, saturation, brightness];
  factory ColorSelection.fromJson(Object? value) {
    final values = (value as List).cast<num>();
    if (values.length != 3) throw const FormatException('Invalid HSB');
    return ColorSelection(
      values[0].toDouble(),
      values[1].toDouble(),
      values[2].toDouble(),
    );
  }

  SrgbColor get rgb {
    final h = (hue % 360) / 60, s = saturation / 100, v = brightness / 100;
    final c = v * s, x = c * (1 - ((h % 2) - 1).abs()), m = v - c;
    final (r, g, b) = switch (h.floor()) {
      0 => (c, x, 0.0),
      1 => (x, c, 0.0),
      2 => (0.0, c, x),
      3 => (0.0, x, c),
      4 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    return SrgbColor(
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
    );
  }
}

enum ColorRoundPhase { answering, review, finished }

class ColorRoundAnswer {
  final ColorQuestion question;
  final ColorSelection selection;
  final bool hintUsed;
  final int scoreCents;
  ColorRoundAnswer._(this.question, this.selection, this.hintUsed)
    : scoreCents = ColorScoring.roundCents(
        selection.rgb,
        question.target,
        hintUsed: hintUsed,
      );
  ColorRoundAnswer._saved(
    this.question,
    this.selection,
    this.hintUsed,
    this.scoreCents,
  );
}

/// A serializable five-round game. Actions carry a question ID:
/// stale callbacks cannot confirm/advance the following question after a fast tap.
class ColorTrainingSession {
  final String packVersion;
  final List<ColorQuestion> questions;
  final String ruleVersion;
  final List<ColorRoundAnswer> _answers = [];
  int _index = 0;
  ColorRoundPhase _phase = ColorRoundPhase.answering;
  ColorSelection _selection = ColorSelection.initial;
  bool _hintUsed = false;
  ColorSelection? _guidanceAt;
  int? _averageCents;

  ColorTrainingSession({
    required this.packVersion,
    required List<ColorQuestion> questions,
    this.ruleVersion = ColorScoring.version,
  }) : questions = List.unmodifiable(questions) {
    if (questions.length != ColorScoring.rounds ||
        questions.map((q) => q.id).toSet().length != ColorScoring.rounds ||
        questions.map((q) => q.characterId).toSet().length !=
            ColorScoring.rounds) {
      throw ArgumentError('Five distinct questions and characters required');
    }
  }

  factory ColorTrainingSession.draw(
    ColorPilotCatalog catalog, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final grouped = <String, List<ColorQuestion>>{};
    for (final question in catalog.questions) {
      grouped.putIfAbsent(question.characterId, () => []).add(question);
    }
    if (grouped.length < ColorScoring.rounds) {
      throw ArgumentError('At least five characters required');
    }
    final characters = grouped.keys.toList()..shuffle(rng);
    return ColorTrainingSession(
      packVersion: catalog.packVersion,
      questions: [
        for (final id in characters.take(ColorScoring.rounds))
          grouped[id]![rng.nextInt(grouped[id]!.length)],
      ],
    );
  }

  ColorQuestion get question => questions[_index];
  int get round => _index + 1;
  ColorRoundPhase get phase => _phase;
  ColorSelection get selection => _selection;
  bool get hintUsed => _hintUsed;
  ColorSelection? get guidanceAt => _guidanceAt;
  List<ColorRoundAnswer> get answers => List.unmodifiable(_answers);
  int? get averageCents =>
      _phase == ColorRoundPhase.finished ? _averageCents : null;
  bool _editing(String id) =>
      _phase == ColorRoundPhase.answering && question.id == id;

  bool choose(ColorSelection value, String id) {
    if (!_editing(id)) return false;
    _selection = value;
    return true;
  }

  bool useHint(String id) {
    if (!_editing(id) || _hintUsed) return false;
    _hintUsed = true;
    return true;
  }

  bool useGuidance(String id) {
    if (!useHint(id)) return false;
    _guidanceAt = _selection;
    return true;
  }

  bool confirm(String id) {
    if (!_editing(id)) return false;
    if (ruleVersion != ColorScoring.version) {
      throw const FormatException('Unsupported saved scoring rule');
    }
    _answers.add(ColorRoundAnswer._(question, _selection, _hintUsed));
    _phase = ColorRoundPhase.review;
    return true;
  }

  bool advance(String id) {
    if (_phase != ColorRoundPhase.review || question.id != id) return false;
    if (_index == ColorScoring.rounds - 1) {
      _averageCents = ColorScoring.averageCents(
        _answers.map((a) => a.scoreCents).toList(),
      );
      _phase = ColorRoundPhase.finished;
    } else {
      _index++;
      _phase = ColorRoundPhase.answering;
      _selection = ColorSelection.initial;
      _hintUsed = false;
      _guidanceAt = null;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'pack': packVersion,
    'rule': ruleVersion,
    'questions': questions.map((q) => q.toJson()).toList(),
    'index': _index,
    'phase': _phase.name,
    'selection': _selection.toJson(),
    'hint': _hintUsed,
    if (_guidanceAt != null) 'guidance': _guidanceAt!.toJson(),
    'average': _averageCents,
    'answers': [
      for (final a in _answers)
        {
          'id': a.question.id,
          'selection': a.selection.toJson(),
          'hint': a.hintUsed,
          'score': a.scoreCents,
        },
    ],
  };

  /// Restore recorded cents, never calculate old answers with a new formula.
  factory ColorTrainingSession.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported session schema');
    }
    final game = ColorTrainingSession(
      packVersion: json['pack'] as String,
      ruleVersion: json['rule'] as String,
      questions: [
        for (final q in json['questions'] as List)
          ColorQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
      ],
    );
    game._index = json['index'] as int;
    game._phase = ColorRoundPhase.values.byName(json['phase'] as String);
    game._selection = ColorSelection.fromJson(json['selection']);
    game._hintUsed = json['hint'] as bool;
    if (json['guidance'] != null) {
      game._guidanceAt = ColorSelection.fromJson(json['guidance']);
      if (!game._hintUsed) {
        throw const FormatException('Guidance requires hint flag');
      }
    }
    game._averageCents = json['average'] as int?;
    if (game._index < 0 || game._index >= 5) {
      throw const FormatException('Invalid round');
    }
    final rows = json['answers'] as List;
    final expected =
        game._index + (game._phase == ColorRoundPhase.answering ? 0 : 1);
    if (rows.length != expected) {
      throw const FormatException('Invalid answer count');
    }
    for (final (i, raw) in rows.indexed) {
      final a = Map<String, dynamic>.from(raw as Map);
      final score = a['score'] as int;
      if (a['id'] != game.questions[i].id || score < 0 || score > 1000) {
        throw const FormatException('Invalid saved answer');
      }
      game._answers.add(
        ColorRoundAnswer._saved(
          game.questions[i],
          ColorSelection.fromJson(a['selection']),
          a['hint'] as bool,
          score,
        ),
      );
    }
    if (game._phase != ColorRoundPhase.answering) {
      final last = game._answers.last;
      if (last.hintUsed != game._hintUsed ||
          last.selection.toJson().toString() !=
              game._selection.toJson().toString()) {
        throw const FormatException('Invalid review state');
      }
    }
    if (game._phase == ColorRoundPhase.finished) {
      if (game._index != 4 ||
          game._averageCents == null ||
          game._averageCents! < 0 ||
          game._averageCents! > 1000) {
        throw const FormatException('Invalid final state');
      }
    } else if (game._averageCents != null) {
      throw const FormatException('Premature final score');
    }
    return game;
  }

  ColorTrainingSession clone() => ColorTrainingSession.fromJson(toJson());
}
