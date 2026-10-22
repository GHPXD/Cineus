import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/color_question.dart';
import 'package:cineus/domain/entities/color_scoring.dart';

void main() {
  // Published numeric reference pairs; attribution in the sprint scoring spec.
  final pairs = File('test/fixtures/ciede2000_reference.txt')
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map(
        (line) => line.trim().split(RegExp(r'\s+')).map(double.parse).toList(),
      )
      .toList();
  test(
    'all 34 published reference pairs are present',
    () => expect(pairs.length, 34),
  );
  for (var i = 0; i < pairs.length; i++) {
    test('CIEDE2000 matches published pair ${i + 1} in both directions', () {
      final p = pairs[i];
      final a = LabColor(p[0], p[1], p[2]), b = LabColor(p[3], p[4], p[5]);
      expect(ColorScoring.deltaE(a, b), closeTo(p[6], .00005));
      expect(ColorScoring.deltaE(b, a), closeTo(p[6], .00005));
    });
  }
  test('sRGB conversion preserves neutrals and white/black endpoints', () {
    final white = LabColor.fromSrgb(const SrgbColor(255, 255, 255));
    final black = LabColor.fromSrgb(const SrgbColor(0, 0, 0));
    expect(white.l, closeTo(100, .0001));
    expect(white.a, closeTo(0, .0001));
    expect(white.b, closeTo(0, .0001));
    expect(black.l, 0);
    expect(black.a, 0);
    expect(black.b, 0);
    final grey = LabColor.fromSrgb(const SrgbColor(128, 128, 128));
    expect(grey.a, closeTo(0, .0001));
    expect(grey.b, closeTo(0, .0001));
    expect(grey.l, inExclusiveRange(50, 55));
    // W3C CSS Color 4 published example, rounded to sRGB bytes.
    final sample = LabColor.fromSrgb(const SrgbColor(106, 128, 93));
    expect(sample.l, closeTo(51.2345, .3));
    expect(sample.a, closeTo(-13.6271, .4));
    expect(sample.b, closeTo(16.2401, .4));
  });
  test('score anchors, bounded hints and invalid distances', () {
    for (final pair in [
      (0.0, 1000),
      (5.0, 900),
      (10.0, 800),
      (25.0, 500),
      (50.0, 0),
      (90.0, 0),
    ]) {
      expect(ColorScoring.centsFromDistance(pair.$1), pair.$2);
    }
    expect(ColorScoring.centsFromDistance(0, hintUsed: true), 900);
    expect(ColorScoring.centsFromDistance(49, hintUsed: true), 0);
    expect(
      () => ColorScoring.centsFromDistance(double.nan),
      throwsArgumentError,
    );
    expect(
      () => ColorScoring.centsFromDistance(double.infinity),
      throwsArgumentError,
    );
    expect(() => ColorScoring.centsFromDistance(-1), throwsArgumentError);
    for (var i = 0; i < 500; i++) {
      expect(
        ColorScoring.centsFromDistance(i / 10),
        greaterThanOrEqualTo(ColorScoring.centsFromDistance((i + 1) / 10)),
      );
    }
  });
  test('five displayed round scores give the displayed average', () {
    expect(ColorScoring.averageCents([887, 901, 818, 1000, 900]), 901);
    expect(ColorScoring.averageCents([1000, 1000, 1000, 1000, 1000]), 1000);
    expect(() => ColorScoring.averageCents([1000]), throwsArgumentError);
    expect(
      () => ColorScoring.averageCents([1001, 0, 0, 0, 0]),
      throwsArgumentError,
    );
  });
  test(
    'published catalogue has 110 sourced questions and all localised content',
    () {
      final json =
          jsonDecode(File('assets/colors/training_v1.json').readAsStringSync())
              as Map<String, dynamic>;
      final catalog = ColorPilotCatalog.fromJson(json);
      expect(catalog.packVersion, 'training-3');
      expect(catalog.questions.length, 110);
      expect(catalog.questions.map((q) => q.id).toSet().length, 110);
      for (final q in catalog.questions) {
        expect(q.source.scheme, 'https');
        expect(ColorScoring.roundCents(q.target, q.target), 1000);
        for (final language in ['pt', 'en', 'es']) {
          for (final key in ['character', 'work', 'part', 'hint']) {
            expect(q.text(key, language), isNotEmpty);
          }
        }
      }
      expect(() => SrgbColor.fromHex('#FFF'), throwsFormatException);
      expect(() => SrgbColor.fromHex('#GGGGGG'), throwsFormatException);
      final rows = json['questions'] as List;
      expect(
        () => ColorPilotCatalog.fromJson({
          ...json,
          'questions': [
            rows.first,
            rows.first,
            rows.first,
            rows.first,
            rows.first,
          ],
        }),
        throwsFormatException,
      );
    },
  );
}
