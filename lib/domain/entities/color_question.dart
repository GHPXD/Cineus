/// Stable, source-backed content. Colours are sRGB bytes, never generated art.
class SrgbColor {
  final int red, green, blue;
  const SrgbColor(this.red, this.green, this.blue)
    : assert(red >= 0 && red <= 255),
      assert(green >= 0 && green <= 255),
      assert(blue >= 0 && blue <= 255);

  factory SrgbColor.fromHex(String hex) {
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
      throw FormatException('Expected #RRGGBB', hex);
    }
    final value = int.parse(hex.substring(1), radix: 16);
    return SrgbColor(value >> 16, (value >> 8) & 255, value & 255);
  }
  int get rgb => (red << 16) | (green << 8) | blue;
  String get hex => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class ColorQuestion {
  final String id;
  final SrgbColor target;
  final Map<String, Map<String, String>> copy;
  final Uri source;
  final String referenceEdition;
  final String characterId;
  final String? artPart;

  ColorQuestion._(
    this.id,
    this.target,
    this.copy,
    this.source,
    this.referenceEdition,
    this.characterId,
    this.artPart,
  );

  factory ColorQuestion.fromJson(Map<String, dynamic> json) {
    final copy = (json['copy'] as Map<String, dynamic>).map(
      (locale, value) => MapEntry(
        locale,
        Map<String, String>.unmodifiable(
          Map<String, String>.from(value as Map),
        ),
      ),
    );
    for (final locale in ['pt', 'en', 'es']) {
      for (final key in ['character', 'work', 'part', 'hint']) {
        if (copy[locale]?[key]?.trim().isNotEmpty != true) {
          throw FormatException('Missing $locale/$key', json['id']);
        }
      }
    }
    final source = Uri.parse(json['source_url'] as String);
    if (source.scheme != 'https' || source.host.isEmpty) {
      throw const FormatException('Missing HTTPS colour reference');
    }
    return ColorQuestion._(
      json['id'] as String,
      SrgbColor.fromHex(json['target_hex'] as String),
      Map.unmodifiable(copy),
      source,
      json['reference_edition'] as String,
      json['character_id'] as String? ?? json['id'] as String,
      json['art_part'] as String?,
    );
  }

  String text(String field, String language) =>
      (copy[language] ?? copy['en']!)[field]!;

  Map<String, dynamic> toJson() => {
    'id': id,
    'target_hex': target.hex,
    'copy': copy,
    'source_url': source.toString(),
    'reference_edition': referenceEdition,
    'character_id': characterId,
    'art_part': artPart,
  };
}

class ColorPilotCatalog {
  final String packVersion;
  final List<ColorQuestion> questions;
  ColorPilotCatalog._(this.packVersion, this.questions);

  Map<String, dynamic> toJson() => {
    'schema_version': 1,
    'pack_version': packVersion,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  factory ColorPilotCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 1) {
      throw const FormatException('Unsupported colour catalog schema');
    }
    final questions = (json['questions'] as List)
        .map(
          (row) =>
              ColorQuestion.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    if (questions.length < 5 ||
        questions.any((q) => q.id.isEmpty) ||
        questions.map((q) => q.id).toSet().length != questions.length) {
      throw const FormatException('Need distinct colour question IDs');
    }
    return ColorPilotCatalog._(
      json['pack_version'] as String,
      List.unmodifiable(questions),
    );
  }
}
