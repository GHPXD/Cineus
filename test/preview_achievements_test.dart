import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/achievement.dart';
import 'package:cineus/domain/entities/game_stats.dart';
import 'package:cineus/domain/entities/color_stats.dart';
import 'package:cineus/presentation/visuals/cineus_assets.dart';
import 'package:cineus/presentation/widgets/character_preview.dart';
import 'package:cineus/presentation/widgets/color_character_art.dart';
import 'color_integration_test.dart' show statisticFixture;
import 'color_training_screen_test.dart' show warmTrainingAssets;
import 'color_training_session_test.dart' show trainingFixture;

void main() {
  test(
    'all completed color kinds count; active sessions never unlock badges',
    () {
      final records = [
        statisticFixture(id: 'daily', date: '2026-10-14', mean: 899),
        statisticFixture(id: 'training', mean: 900),
        statisticFixture(id: 'pending', active: true),
      ];
      final stats = ColorStats.fromSessions(records);
      expect(stats.games, 2);
      expect(stats.averageCents, 900);
      final badges = Achievements.evaluateAdditional(
        poster: const GameStats(totalWins: 1, scoreDistribution: {4: 1}),
        colors: stats,
        colorStagesCompleted: 2,
      );
      expect(
        badges.singleWhere((a) => a.id == 'poster_first').isUnlocked,
        true,
      );
      expect(
        badges.singleWhere((a) => a.id == 'poster_perfect').isUnlocked,
        false,
      );
      expect(
        badges.singleWhere((a) => a.id == 'colors_excellent').isUnlocked,
        true,
      );
      expect(
        badges.singleWhere((a) => a.id == 'colors_25').progressLabel,
        '2 / 25',
      );
      expect(
        badges.singleWhere((a) => a.id == 'colors_stages_3').isUnlocked,
        false,
      );
      final low = Achievements.evaluateAdditional(
        poster: const GameStats(),
        colors: ColorStats.fromSessions([records.first]),
        colorStagesCompleted: 0,
      );
      expect(
        low.singleWhere((a) => a.id == 'colors_excellent').isUnlocked,
        false,
      );
      expect(
        badges.map((a) => CineusAssets.forAchievement(a.id)).toSet(),
        hasLength(6),
      );
    },
  );
  for (final locked in [false, true]) {
    testWidgets('real sprite pixels disclose no color; silhouette=$locked', (
      tester,
    ) async {
      final catalog = trainingFixture();
      final q = catalog.questions.first;
      await warmTrainingAssets(tester, catalog);
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 120,
                height: 160,
                child: CharacterPreview(
                  locked: locked,
                  child: ColorCharacterArt(
                    question: q,
                    choice: q.target,
                    palette: {
                      for (final p in catalog.questions.where(
                        (p) => p.characterId == q.characterId,
                      ))
                        p.artPart!: p.target,
                    },
                    height: 160,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        var checked = 0;
        for (var i = 0; i < pixels.length; i += 4) {
          if (pixels[i + 3] != 255) continue;
          checked++;
          if (locked) {
            expect(pixels.sublist(i, i + 3), [96, 112, 135]);
          } else {
            expect((pixels[i] - pixels[i + 1]).abs(), lessThanOrEqualTo(1));
            expect((pixels[i] - pixels[i + 2]).abs(), lessThanOrEqualTo(1));
          }
        }
        expect(checked, greaterThan(100));
        image.dispose();
      });
    });
  }
}
