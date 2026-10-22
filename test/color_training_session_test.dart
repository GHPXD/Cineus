import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/color_question.dart';
import 'package:cineus/domain/entities/color_scoring.dart';
import 'package:cineus/domain/entities/color_training_session.dart';

ColorPilotCatalog trainingFixture() => ColorPilotCatalog.fromJson(
  jsonDecode(File('assets/colors/training_v1.json').readAsStringSync())
      as Map<String, dynamic>,
);
ColorTrainingSession fixedTraining(ColorPilotCatalog catalog) =>
    ColorTrainingSession(
      packVersion: catalog.packVersion,
      questions: [
        for (final id in [
          'spongebob_body',
          'goku_gi',
          'cartman_jacket',
          'finn_backpack',
          'aang_tattoos',
        ])
          catalog.questions.singleWhere((q) => q.id == id),
      ],
    );

void main() {
  test(
    '110 source-backed regions cover 50 distinct characters with the original regions preserved',
    () {
      final json =
          jsonDecode(File('assets/colors/training_v1.json').readAsStringSync())
              as Map<String, dynamic>;
      final catalog = trainingFixture();
      expect(catalog.questions.length, 110);
      expect(catalog.questions.map((q) => q.id).toSet().length, 110);
      final chars = catalog.questions.map((q) => q.characterId).toSet();
      expect(chars.length, 50);
      for (final char in chars) {
        final questions = catalog.questions.where((q) => q.characterId == char);
        expect(questions.length, isIn([1, 2, 5]));
        expect(
          questions.map((q) => q.artPart).toSet(),
          questions.length == 1
              ? {'p0'}
              : questions.length == 2
              ? {'p0', 'p1'}
              : {'p0', 'p1', 'p2', 'p3', 'p4'},
        );
        for (final q in questions) {
          expect(q.source.scheme, 'https');
          expect(q.referenceEdition, isNotEmpty);
          for (final locale in ['pt', 'en', 'es']) {
            for (final field in ['character', 'work', 'part', 'hint']) {
              expect(q.text(field, locale).trim(), isNotEmpty);
            }
            expect(q.text('hint', locale), isNot(contains(q.target.hex)));
          }
        }
      }
      expect(
        (json['questions'] as List).where((q) => q['sampling'] != null).length,
        77,
      );
    },
  );
  test('draws five distinct characters and questions across seeded games', () {
    final catalog = trainingFixture();
    final seen = <String>{};
    for (var seed = 0; seed < 1000; seed++) {
      final game = ColorTrainingSession.draw(catalog, random: Random(seed));
      expect(game.questions.map((q) => q.id).toSet().length, 5);
      expect(game.questions.map((q) => q.characterId).toSet().length, 5);
      seen.addAll(game.questions.map((q) => q.id));
    }
    expect(seen.length, 110);
  });
  test(
    'HSB bytes match the actual Flutter preview, including boundary hues and greys',
    () {
      final random = Random(9);
      final values = [
        ColorSelection(0, 100, 100),
        ColorSelection(360, 100, 100),
        ColorSelection(200, 0, 50),
        ColorSelection(30, 100, 0),
        for (var i = 0; i < 100; i++)
          ColorSelection(
            random.nextDouble() * 360,
            random.nextDouble() * 100,
            random.nextDouble() * 100,
          ),
      ];
      for (final choice in values) {
        final colour = HSVColor.fromAHSV(
          1,
          choice.hue,
          choice.saturation / 100,
          choice.brightness / 100,
        ).toColor().toARGB32();
        expect(choice.rgb.rgb, colour & 0xffffff);
      }
      for (final invalid in [double.nan, double.infinity, -1.0, 361.0]) {
        expect(() => ColorSelection(invalid, 50, 50), throwsArgumentError);
      }
      expect(() => ColorSelection(10, 101, 50), throwsArgumentError);
    },
  );
  test(
    'confirmation locks edits/hints and duplicate taps do not alter an answer',
    () {
      final game = fixedTraining(trainingFixture()), id = gameId();
      expect(game.question.id, id);
      expect(game.choose(ColorSelection(56, 90, 99), id), isTrue);
      expect(game.confirm(id), isTrue);
      final score = game.answers.single.scoreCents;
      expect(game.confirm(id), isFalse);
      expect(game.choose(ColorSelection(120, 100, 100), id), isFalse);
      expect(game.useHint(id), isFalse);
      expect(game.answers.single.scoreCents, score);
      expect(game.answers.single.selection.hue, 56);
      expect(() => game.answers.clear(), throwsUnsupportedError);
    },
  );
  test('stale callbacks cannot skip a round or confirm the next question', () {
    final game = fixedTraining(trainingFixture());
    final old = game.question.id;
    expect(game.advance(old), isFalse);
    expect(game.confirm(old), isTrue);
    expect(game.advance(old), isTrue);
    expect(game.round, 2);
    expect(game.advance(old), isFalse);
    expect(game.confirm(old), isFalse);
    expect(game.useHint(old), isFalse);
    expect(game.choose(ColorSelection(0, 0, 0), old), isFalse);
    expect(game.answers.length, 1);
    expect(game.phase, ColorRoundPhase.answering);
    expect(game.selection.hue, 200);
    expect(game.hintUsed, isFalse);
  });
  test(
    'hint deducts once, resets next round and never produces a negative score',
    () {
      final catalog = trainingFixture();
      final hinted = fixedTraining(catalog), plain = fixedTraining(catalog);
      for (final game in [hinted, plain]) {
        game.choose(ColorSelection(56, 100, 100), game.question.id);
      }
      expect(hinted.useHint(hinted.question.id), isTrue);
      expect(hinted.useHint(hinted.question.id), isFalse);
      for (final game in [hinted, plain]) {
        game.confirm(game.question.id);
      }
      expect(
        plain.answers.single.scoreCents - hinted.answers.single.scoreCents,
        100,
      );
      hinted.advance(hinted.question.id);
      expect(hinted.hintUsed, isFalse);
      hinted.useHint(hinted.question.id);
      hinted.choose(ColorSelection(0, 0, 0), hinted.question.id);
      hinted.confirm(hinted.question.id);
      expect(hinted.answers.last.scoreCents, greaterThanOrEqualTo(0));
    },
  );
  test(
    'five committed answers produce one rounded mean and a terminal state',
    () {
      final game = fixedTraining(trainingFixture());
      expect(game.averageCents, isNull);
      for (var index = 1; index <= 5; index++) {
        final id = game.question.id;
        expect(game.round, index);
        game.choose(ColorSelection(index * 60, 70, 80), id);
        expect(game.confirm(id), isTrue);
        expect(game.averageCents, isNull);
        expect(game.advance(id), isTrue);
      }
      expect(game.phase, ColorRoundPhase.finished);
      expect(game.answers.length, 5);
      expect(
        game.averageCents,
        ColorScoring.averageCents(
          game.answers.map((a) => a.scoreCents).toList(),
        ),
      );
      expect(game.confirm(game.question.id), isFalse);
      expect(game.advance(game.question.id), isFalse);
      expect(game.ruleVersion, ColorScoring.version);
    },
  );
  test('duplicate questions/characters and incomplete games are rejected', () {
    final catalog = trainingFixture();
    expect(
      () => ColorTrainingSession(
        packVersion: 'x',
        questions: catalog.questions.take(4).toList(),
      ),
      throwsArgumentError,
    );
    expect(
      () => ColorTrainingSession(
        packVersion: 'x',
        questions: catalog.questions.take(5).toList(),
      ),
      throwsArgumentError,
    );
    expect(
      () => ColorTrainingSession(
        packVersion: 'x',
        questions: List.filled(5, catalog.questions.first),
      ),
      throwsArgumentError,
    );
  });
}

String gameId() => 'spongebob_body';
