import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/saved_color_session.dart';
import '../../l10n/app_l10n.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_brand.dart';
import 'cineus_icon.dart';
import '../../domain/entities/player_collection.dart';
import 'collection_artwork.dart';
import 'personalized_share_panel.dart';

/// Only these result fields can enter exported text/PNG. No question or colour.
class ColorShareData {
  final ColorSessionKind kind;
  final String? date;
  final List<int> scores;
  final int average;
  final int? stageId;
  ColorShareData.fromSession(SavedColorSession session)
    : kind = session.kind,
      stageId = session.stageId,
      date = session.dailyDate,
      scores = List.unmodifiable(session.game.answers.map((a) => a.scoreCents)),
      average =
          session.game.averageCents ?? (throw StateError('Unfinished result')) {
    if (session.status != 'completed' || scores.length != 5) {
      throw StateError('Unfinished result');
    }
  }
  String score(int value, String locale) =>
      NumberFormat('0.00', locale).format(value / 100);
  String context(AppL10n l) => stageId != null
      ? l.colorStageTitle(stageId!)
      : kind == ColorSessionKind.daily
      ? '${l.colorDailyTitle} · $date · UTC'
      : l.colorTrainingBadge;
  String text(AppL10n l, String locale) =>
      'Cineus · ${l.colorModeTitle}\n${context(l)}\n${l.colorAverageLabel}: ${score(average, locale)} / 10\n'
      '${[for (final (i, s) in scores.indexed) '${l.colorStatsRound(i + 1)}: ${score(s, locale)} / 10'].join('\n')}\n\n${l.colorSharePrivacy}';
}

class ColorShareCard extends StatelessWidget {
  final ColorShareData data;
  final CollectionLook? look;
  const ColorShareCard({super.key, required this.data, this.look});
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context),
        locale = Localizations.localeOf(context).languageCode;
    return CollectionCardSurface(
      look: look,
      children: [
        const Center(child: CineusWordmark(fontSize: 32)),
        const SizedBox(height: 20),
        const Center(child: CineusIcon(CineusAssetId.modeColors, size: 56)),
        const SizedBox(height: 12),
        Text(
          l.colorShareTitle,
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          data.context(l),
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 22),
        Text(
          l.colorAverageLabel,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        Text(
          l.colorScoreValue(data.score(data.average, locale)),
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(color: AppColors.gold300),
        ),
        const SizedBox(height: 18),
        for (final (i, score) in data.scores.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(l.colorStatsRound(i + 1), style: AppTypography.bodyMedium),
                Text(
                  l.colorScoreValue(data.score(score, locale)),
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.blue200,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        Text(
          l.colorSharePrivacy,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

class ColorSharePanel extends StatelessWidget {
  final ColorShareData data;
  const ColorSharePanel({super.key, required this.data});
  @override
  Widget build(BuildContext context) => PersonalizedSharePanel(
    colors: true,
    text: data.text(
      AppL10n.of(context),
      Localizations.localeOf(context).languageCode,
    ),
    cardBuilder: (look) => ColorShareCard(data: data, look: look),
  );
}
