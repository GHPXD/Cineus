import '../widgets/category_backdrop.dart';
import '../widgets/character_preview.dart';
import '../widgets/gold_heading.dart';
import '../widgets/ticket_details_sheet.dart';
import '../widgets/stage_native_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/color_stage.dart';
import '../../domain/entities/color_question.dart';
import '../../l10n/app_l10n.dart';
import '../providers/color_providers.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cinematic_app_bar.dart';
import '../widgets/home_cinematic_deck.dart';
import '../widgets/color_character_art.dart';
import 'color_session_screen.dart';

class ColorStagesScreen extends ConsumerStatefulWidget {
  final int? stageId;
  const ColorStagesScreen({super.key, this.stageId});
  @override
  ConsumerState<ColorStagesScreen> createState() => _ColorStagesScreenState();
}

class _ColorStagesScreenState extends ConsumerState<ColorStagesScreen> {
  bool _opening = false;
  void _refresh() => ref.invalidate(colorSessionsProvider);
  void _back() => context.canPop() ? context.pop() : context.go('/colors');
  Future<void> _openStage(ColorStageProgress progress) async {
    if (_opening || progress.locked) return;
    setState(() => _opening = true);
    try {
      await context.push('/colors/stage/${progress.stage.id}');
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        _refresh();
      }
    }
  }

  Future<void> _play(ColorStageProgress progress, int match) async {
    if (_opening || progress.locked) return;
    setState(() => _opening = true);
    try {
      final repo = ref.read(colorRepositoryProvider);
      if (!await repo.guideSeen()) {
        if (!mounted) return;
        await context.push('/colors/guide');
        if (!mounted || !await repo.guideSeen()) return;
      }
      final record = await startColorStage(ref, progress.stage.id, match);
      if (!mounted) return;
      if (record == null) {
        await showTicketDetails(context);
        return;
      }
      _refresh();
      await context.push('/colors/session/${Uri.encodeComponent(record.id)}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).colorSaveFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final snapshot = ref.watch(colorStageProgressProvider);
    if (snapshot.isLoading || snapshot.hasError) {
      return ColorLoadState(
        failed: snapshot.hasError,
        onBack: widget.stageId != null ? _back : null,
        onRetry: () {
          ref.invalidate(colorStageCatalogProvider);
          _refresh();
        },
      );
    }
    final stages = snapshot.requireValue;
    final chosen = widget.stageId == null
        ? null
        : stages.where((s) => s.stage.id == widget.stageId).firstOrNull;
    if (widget.stageId != null && (chosen == null || chosen.locked)) {
      return ColorLoadState(failed: true, onBack: _back, onRetry: _refresh);
    }
    final catalog = ref.watch(colorStageCatalogProvider).requireValue.colors;
    final large = MediaQuery.textScalerOf(context).scale(14) > 18;
    return Scaffold(
      backgroundColor: CategoryBackdrop.surface,
      appBar: chosen == null
          ? null
          : CinematicAppBar(
              title: l.colorStageTitle(chosen.stage.id),
              asset: CineusAssetId.modeColors,
              onBack: _back,
              textScaler: MediaQuery.textScalerOf(context),
            ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: CategoryBackdrop(
              child: ListView(
                key: ValueKey(
                  chosen == null ? 'colors-hub-scroll' : 'colors-stage-scroll',
                ),
                padding: const EdgeInsets.all(14),
                children: [
                  if (chosen == null) ...[
                    Row(
                      children: [
                        const CineusIcon(CineusAssetId.modeColors, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GoldHeading(l.colorModeTitle, size: 37),
                        ),
                        IconButton(
                          tooltip: l.colorGuideTitle,
                          onPressed: () => context.push('/colors/guide'),
                          icon: const CineusIcon(CineusAssetId.help),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l.colorStagesSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        height: 1.35,
                        color: const Color(0xFFB4C3E3),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    chosen == null ? l.filmsAllStages : l.colorStageGamesTitle,
                    style: AppTypography.sectionTitle,
                  ),
                  if (chosen != null) ...[
                    const SizedBox(height: 4),
                    Text(l.colorStageStructure, style: AppTypography.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  if (chosen == null) ...[
                    for (var index = 0; index < stages.length; index++) ...[
                      _row(stages[index], catalog, large),
                      const SizedBox(height: 10),
                      if (StageAdPolicy.after(index + 1, colors: true)) ...[
                        StageNativeAd(
                          key: ValueKey('stage-native-colors-${index + 1}'),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                    TextButton(
                      onPressed: () => context.push('/colors/credits'),
                      child: Text(l.colorCreditsTitle),
                    ),
                    for (final legacy
                        in ref
                            .watch(colorSessionsProvider)
                            .requireValue
                            .where(
                              (s) =>
                                  !s.isStage &&
                                  s.dailyDate == null &&
                                  s.status == 'active',
                            ))
                      TextButton(
                        onPressed: () => context.push(
                          '/colors/session/${Uri.encodeComponent(legacy.id)}',
                        ),
                        child: Text(l.colorStageLegacy),
                      ),
                  ] else ...[
                    for (
                      var match = 0;
                      match < chosen.stage.matches;
                      match++
                    ) ...[
                      _match(chosen, match, catalog),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    ColorStageProgress progress,
    ColorPilotCatalog catalog,
    bool large,
  ) {
    final l = AppL10n.of(context);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.colorStageTitle(progress.stage.id),
          style: AppTypography.sectionTitle.copyWith(
            color: progress.locked
                ? AppColors.textSecondary
                : AppColors.obsidian0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress.locked
              ? l.colorStageLocked(progress.stage.id - 1)
              : l.colorStageProgress(progress.completed, 10),
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: progress.completed / 10,
          minHeight: 5,
          color: AppColors.gold300,
          backgroundColor: AppColors.obsidian700,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
    return Semantics(
      button: !progress.locked,
      enabled: !progress.locked,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('colors-stage-${progress.stage.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: _opening || progress.locked
              ? null
              : () => _openStage(progress),
          child: HomeChromePanel(
            gold: !progress.locked,
            radius: 18,
            child: large
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 54,
                            child: _portrait(
                              progress.stage.questions.first,
                              catalog,
                              54,
                              progress.locked,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CineusIcon(
                            progress.locked
                                ? CineusAssetId.lock
                                : CineusAssetId.chevron,
                            size: 23,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      copy,
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: _portrait(
                          progress.stage.questions.first,
                          catalog,
                          64,
                          progress.locked,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                      const SizedBox(width: 8),
                      CineusIcon(
                        progress.locked
                            ? CineusAssetId.lock
                            : CineusAssetId.chevron,
                        size: 23,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _portrait(
    ColorQuestion question,
    ColorPilotCatalog catalog,
    double height,
    bool muted,
  ) => CharacterPreview(
    locked: muted,
    child: ColorCharacterArt(
      question: question,
      choice: const SrgbColor(180, 191, 208),
      palette: {
        for (final q in catalog.questions.where(
          (q) => q.characterId == question.characterId && q.artPart != null,
        ))
          q.artPart!: const SrgbColor(180, 191, 208),
      },
      height: height,
    ),
  );
  Widget _match(
    ColorStageProgress progress,
    int match,
    ColorPilotCatalog catalog,
  ) {
    final l = AppL10n.of(context), record = progress.record(match);
    final locked =
        match > 0 && progress.record(match - 1)?.status != 'completed';
    final language = Localizations.localeOf(context).languageCode;
    return HomeChromePanel(
      gold: !locked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.colorStageMatch(match + 1),
                  style: AppTypography.sectionTitle,
                ),
              ),
              CineusIcon(
                locked
                    ? CineusAssetId.lock
                    : record?.status == 'completed'
                    ? CineusAssetId.completed
                    : CineusAssetId.inProgress,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final q in progress.stage.match(match))
                Expanded(child: _portrait(q, catalog, 64, locked)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            locked
                ? l.colorMysteryCharacters
                : progress.stage
                      .match(match)
                      .map((q) => q.text('character', language))
                      .join(' · '),
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: ValueKey('colors-stage-match-$match'),
            onPressed: _opening || locked ? null : () => _play(progress, match),
            child: Text(
              locked
                  ? l.locked
                  : record?.status == 'completed'
                  ? l.colorSeeResult
                  : record != null
                  ? l.colorStageResume
                  : l.colorStageStart,
            ),
          ),
        ],
      ),
    );
  }
}
