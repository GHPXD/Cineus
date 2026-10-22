import '../../core/utils/daily_selector.dart';
import 'color_question.dart';
import 'color_training_session.dart';

/// Fixed arithmetic and sorted IDs: no VM hashCode or platform Random algorithm.
abstract final class ColorDailySelector {
  static const version = 'poly31-lcg31-v1';
  static ColorTrainingSession draw(
    ColorPilotCatalog catalog,
    String date, {
    List<String>? publishedQuestions,
  }) {
    final parsed = DailySelector.dateFromKey(date);
    if (parsed == null || DailySelector.todayKey(parsed) != date) {
      throw const FormatException('Invalid UTC date');
    }
    if (publishedQuestions != null) {
      final byId = {for (final q in catalog.questions) q.id: q};
      return ColorTrainingSession(
        packVersion: catalog.packVersion,
        questions: [
          for (final id in publishedQuestions)
            byId[id] ??
                (throw const FormatException(
                  'Published color question missing',
                )),
        ],
      );
    }
    var seed = 0;
    for (final byte in '$version|${catalog.packVersion}|$date'.codeUnits) {
      seed = (seed * 31 + byte) & 0x7FFFFFFF;
    }
    int next(int max) {
      seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
      return seed % max;
    }

    final grouped = <String, List<ColorQuestion>>{};
    for (final q in catalog.questions) {
      grouped.putIfAbsent(q.characterId, () => []).add(q);
    }
    if (grouped.length < 5) {
      throw const FormatException('Five characters required');
    }
    final ids = grouped.keys.toList()..sort();
    for (var i = ids.length - 1; i > 0; i--) {
      final j = next(i + 1), item = ids[i];
      ids[i] = ids[j];
      ids[j] = item;
    }
    return ColorTrainingSession(
      packVersion: catalog.packVersion,
      questions: [
        for (final id in ids.take(5))
          (grouped[id]!
            ..sort((a, b) => a.id.compareTo(b.id)))[next(grouped[id]!.length)],
      ],
    );
  }
}
