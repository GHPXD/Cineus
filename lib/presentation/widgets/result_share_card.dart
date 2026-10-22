import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/player_collection.dart';
import '../../l10n/app_l10n.dart';
import 'cineus_brand.dart';
import 'cineus_poster.dart';
import 'share_grid_widget.dart';
import 'collection_artwork.dart';

/// The requested poster and score; guesses and invitation codes stay private.
class ResultShareData {
  final GameMode mode;
  final SessionKind kind;
  final bool won;
  final int score, steps, total, challenge, stage, movieId;
  const ResultShareData({
    required this.mode,
    required this.kind,
    required this.won,
    required this.score,
    required this.steps,
    required this.total,
    required this.movieId,
    this.challenge = 0,
    this.stage = 0,
  });
  factory ResultShareData.fromSession(GameSession s, int challenge) =>
      ResultShareData(
        mode: s.mode,
        movieId: s.movieId,
        kind: s.kind,
        won: s.status == GameStatus.won,
        score: s.score,
        steps: s.status == GameStatus.won
            ? s.revealedClues
            : s.rules.totalSteps,
        total: s.rules.totalSteps,
        challenge: challenge,
        stage: s.stageId,
      );
  String modeLabel(AppL10n l) =>
      mode == GameMode.clue ? l.shareModeClues : l.shareModePoster;
  String contextLabel(AppL10n l) => switch (kind) {
    SessionKind.daily => '${l.dailyChallengeLabel} #$challenge',
    SessionKind.stage => l.stageNumber('$stage'),
    SessionKind.challenge => l.challengeBadge,
    SessionKind.archive => l.archiveMode,
    SessionKind.training => l.practiceMode,
  };
  String text(AppL10n l) {
    final grid = ShareGrid(
      revealedClues: steps,
      won: won,
      totalSteps: total,
      score: score,
    ).toEmojiGrid();
    return 'Cineus\n${l.resultScoreScale(score, total)}\n\n$grid';
  }
}

class ResultShareCard extends StatelessWidget {
  final ResultShareData data;
  final CollectionLook? look;
  final bool revealMovie;
  const ResultShareCard({
    super.key,
    required this.data,
    this.look,
    this.revealMovie = true,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return CollectionCardSurface(
      look: look,
      children: [
        const Center(
          child: CineusWordmark(
            fontSize: 32,
            showSymbol: true,
            vectorSymbol: true,
          ),
        ),
        const SizedBox(height: 20),
        if (revealMovie)
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold300.withValues(alpha: .12),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CineusPoster(
                  movieId: data.movieId,
                  width: 160,
                  height: 240,
                  minimumPixelRatio: 2,
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          l.resultScoreScale(data.score, data.total),
          style: AppTypography.headlineMedium.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        ShareGrid(
          revealedClues: data.steps,
          won: data.won,
          totalSteps: data.total,
          score: data.score,
        ),
      ],
    );
  }
}
