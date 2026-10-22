import 'stage_navigation_indicator.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/stage.dart';
import '../l10n_mappers.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

class PosterStageTitle extends StatelessWidget {
  final Stage stage;
  final double size;
  const PosterStageTitle({super.key, required this.stage, this.size = 20});
  @override
  Widget build(BuildContext context) {
    final name = context.l10n.stageNumber('${stage.id}');
    final number = '${stage.id}';
    final index = name.lastIndexOf(number);
    final style = AppTypography.displaySmall.copyWith(
      fontSize: size,
      height: 1.15,
      color: stage.isLocked ? const Color(0xFFAFBBD4) : const Color(0xFFFFFCF1),
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: index < 0
            ? [TextSpan(text: name)]
            : [
                TextSpan(text: name.substring(0, index)),
                TextSpan(
                  text: number,
                  style: TextStyle(
                    color: stage.isLocked
                        ? const Color(0xFFAFBBD4)
                        : AppColors.gold300,
                  ),
                ),
                TextSpan(text: name.substring(index + number.length)),
              ],
      ),
    );
  }
}

class PosterStageProgress extends StatelessWidget {
  final Stage stage;
  const PosterStageProgress({super.key, required this.stage});
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.stageSemanticsProgress(
      context.l10n.stageNumber('${stage.id}'),
      stage.completedCount,
      stage.totalMovies,
    ),
    value: '${(stage.progress.clamp(0, 1) * 100).round()}%',
    child: Container(
      height: 7,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF465168), width: .7),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(.7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: stage.progress.clamp(0, 1),
          minHeight: 4,
          color: stage.isLocked ? const Color(0xFF7B849D) : AppColors.gold300,
          backgroundColor: const Color(0xFF171E2C),
        ),
      ),
    ),
  );
}

class PosterStageRow extends StatelessWidget {
  final Stage stage;
  final Stage? previous;
  final bool large;
  final VoidCallback? onOpen;
  const PosterStageRow({
    super.key,
    required this.stage,
    this.previous,
    required this.large,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final progress = l.stageProgressLine(
      stage.completedCount,
      stage.totalMovies,
      l.postersDone,
    );
    final description = stage.isLocked ? l.locked : progress;
    final prerequisite = stage.isLocked
        ? l.stageUnlockAfter(l.stageNumber('${previous?.id ?? stage.id}'))
        : '';
    final art = [
      'amber',
      'blue',
      'red',
    ][(stage.orderIndex - 1).clamp(0, 999999) % 3];
    return Semantics(
      label:
          '${l.stageNumber('${stage.id}')}. $description. $prerequisite${stage.isCompleted ? l.stageCompleteLabel : ''}',
      button: !stage.isLocked,
      enabled: !stage.isLocked && onOpen != null,
      onTap: stage.isLocked ? null : onOpen,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF060C16),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('stage-${stage.id}'),
          onTap: stage.isLocked ? null : onOpen,
          child: Container(
            constraints: const BoxConstraints(minHeight: 78),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: stage.isLocked
                    ? const Color(0xFF303A4F)
                    : AppColors.gold300,
                width: stage.isLocked ? 1 : 1.2,
              ),
              boxShadow: stage.isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.gold300.withValues(alpha: .1),
                        blurRadius: 10,
                      ),
                    ],
              gradient: const LinearGradient(
                colors: [Color(0xFF07101D), Color(0xFF070A11)],
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                if (!large) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      width: 68,
                      height: 58,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ExcludeSemantics(
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 3.5,
                                  sigmaY: 3.5,
                                ),
                                child: Image.asset(
                                  'assets/poster_stages/$art.png',
                                  fit: BoxFit.cover,
                                  cacheWidth: 220,
                                ),
                              ),
                            ),
                          ),
                          if (stage.isLocked)
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Tooltip(
                                message: prerequisite,
                                child: Container(
                                  width: 22,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xF006101D),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF54718E),
                                    ),
                                  ),
                                  child: const Center(
                                    child: _PosterLock(size: 14),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosterStageTitle(stage: stage),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          height: 1.3,
                          color: const Color(0xFFB4C3E3),
                        ),
                      ),
                      const SizedBox(height: 7),
                      PosterStageProgress(stage: stage),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StageNavigationIndicator(
                  locked: stage.isLocked,
                  completed: stage.isCompleted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterLock extends StatelessWidget {
  final double size;
  const _PosterLock({required this.size});
  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: const ColorFilter.mode(Color(0xFFB8C2D9), BlendMode.srcIn),
    child: CineusIcon(CineusAssetId.lock, size: size),
  );
}
