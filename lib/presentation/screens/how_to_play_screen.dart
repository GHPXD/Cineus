import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/scoring_rules.dart';
import '../l10n_mappers.dart';
import '../providers/providers.dart';
import '../providers/telemetry_provider.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/learning_art.dart';
import '../widgets/cineus_poster.dart';

class HowToPlayScreen extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;
  final bool isOnboarding;
  const HowToPlayScreen({
    super.key,
    required this.onDismiss,
    this.isOnboarding = false,
  });
  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayState();
}

class _HowToPlayState extends ConsumerState<HowToPlayScreen> {
  int _page = 0, _mode = 0, _reveal = 1, _selection = 0;
  bool _submitted = false, _saving = false, _failed = false, _quick = false;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _move(int page) {
    setState(() => _page = page);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _dismiss() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final meta = ref.read(appMetaRepositoryProvider);
    final telemetry = ref.read(productTelemetryProvider);
    try {
      if (widget.isOnboarding) await meta.markOnboardingSeen();
      await telemetry.record(
        'tutorial_completed',
        properties: {
          'mode': ['clue', 'poster', 'colors'][_mode],
        },
      );
      if (!mounted) return;
      if (widget.isOnboarding) ref.invalidate(onboardingSeenProvider);
      widget.onDismiss();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final titles = [
      l.guideTitle,
      l.guideAnswerTitle,
      l.guideJourneyTitle,
      l.guideEssentialsTitle,
    ];
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                  child: Row(
                    children: [
                      if (!widget.isOnboarding)
                        IconButton(
                          tooltip: l.semBack,
                          onPressed: _saving ? null : widget.onDismiss,
                          icon: const CineusIcon(CineusAssetId.back),
                        ),
                      if (widget.isOnboarding) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.quickGuide,
                          style: AppTypography.headlineMedium,
                        ),
                      ),
                      Text('${_page + 1}/4', style: AppTypography.monoSmall),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(
                    value: (_page + 1) / 4,
                    color: AppColors.gold300,
                    backgroundColor: AppColors.obsidian700,
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: const ValueKey('guide-scroll'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      Text(titles[_page], style: AppTypography.displaySmall),
                      const SizedBox(height: 16),
                      if (widget.isOnboarding && _page == 0) ...[
                        FilledButton(
                          key: const ValueKey('guide-quick-start'),
                          onPressed: () {
                            setState(() {
                              _quick = true;
                              _mode = 0;
                            });
                            _move(1);
                          },
                          child: Text(l.quickStart),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_page == 0)
                        ..._modes(context)
                      else if (_page == 1)
                        ..._answer(context)
                      else if (_page == 2) ...[
                        _GuideCard(
                          key: const ValueKey('guide-daily'),
                          asset: CineusAssetId.clock,
                          title: l.guideDailyTitle,
                          body: l.guideDailyBody,
                          child: const LearningArt(LearningArtKind.daily),
                        ),
                        const SizedBox(height: 12),
                        _GuideCard(
                          key: const ValueKey('guide-stages'),
                          asset: CineusAssetId.inProgress,
                          title: l.guideStagesTitle,
                          body: l.guideStagesBody,
                        ),
                      ] else ...[
                        ExpansionTile(
                          title: Text(l.guideCollectionTitle),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(l.guideCollectionBody),
                            ),
                            TextButton(
                              onPressed: () => context.push('/journey'),
                              child: Text(l.missionsTitle),
                            ),
                          ],
                        ),
                        _GuideCard(
                          key: const ValueKey('guide-tickets'),
                          asset: CineusAssetId.ticket,
                          title: l.guideTicketsTitle,
                          body:
                              '${l.guideTicketsBody}\n\n${l.guideTicketsRenewal}',
                          child: const LearningArt(LearningArtKind.tickets),
                        ),
                        const SizedBox(height: 12),
                        ExpansionTile(
                          key: const ValueKey('guide-results'),
                          title: Text(l.guideResultsTitle),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(l.guideResultsBody),
                            ),
                          ],
                        ),
                        ExpansionTile(
                          title: Text(l.guideSaveTitle),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(l.guideSaveBody),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_failed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              l.guideSaveFailed,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.ruby300,
                              ),
                            ),
                          ),
                        ),
                      if (_quick)
                        FilledButton(
                          key: const ValueKey('guide-quick-done'),
                          onPressed: _saving || !_submitted ? null : _dismiss,
                          child: Text(l.gotItLetsPlay),
                        )
                      else if (_page < 3)
                        FilledButton(
                          key: const ValueKey('guide-next'),
                          onPressed: _saving ? null : () => _move(_page + 1),
                          child: Text(l.colorGuideNext),
                        )
                      else
                        ElevatedButton(
                          key: const ValueKey('guide-done'),
                          onPressed: _saving ? null : _dismiss,
                          child: Text(
                            _failed ? l.retryAction : l.gotItLetsPlay,
                          ),
                        ),
                      if (_page > 0 && !_quick)
                        TextButton(
                          key: const ValueKey('guide-previous'),
                          onPressed: _saving ? null : () => _move(_page - 1),
                          child: Text(l.colorGuidePrevious),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _modes(BuildContext context) {
    final l = context.l10n;
    final poster = _mode == 1;
    final rules = ScoringRules.forMode(
      poster ? GameMode.poster : GameMode.clue,
    );
    final clues = l.guideDemoClues.split('|');
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, mode) in [
            l.modeClues,
            l.modePoster,
            l.colorModeTitle,
          ].indexed)
            ChoiceChip(
              key: ValueKey('guide-mode-${['clue', 'poster', 'colors'][i]}'),
              avatar: CineusIcon(
                [
                  CineusAssetId.modeClues,
                  CineusAssetId.modePoster,
                  CineusAssetId.modeColors,
                ][i],
                size: 22,
              ),
              showCheckmark: false,
              label: Text(mode),
              selected: _mode == i,
              onSelected: (_) => setState(() {
                _mode = i;
                _reveal = 1;
              }),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (_mode == 2)
        _GuideCard(
          key: const ValueKey('guide-colors'),
          asset: CineusAssetId.modeColors,
          title: l.colorGuideAdjustTitle,
          body: l.guideColorsBody,
          child: Column(
            children: [
              const Center(
                child: CineusIcon(CineusAssetId.modeColors, size: 88),
              ),
              OutlinedButton(
                key: const ValueKey('guide-open-colors'),
                onPressed: () => context.push('/how-to-play/colors'),
                child: Text(l.guideTryColors),
              ),
            ],
          ),
        )
      else
        _GuideCard(
          key: const ValueKey('guide-mode-card'),
          asset: poster ? CineusAssetId.modePoster : CineusAssetId.modeClues,
          title: poster ? l.guidePosterTitle : l.guideCluesTitle,
          body: poster ? l.guidePosterBody : l.guideCluesBody,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (poster)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: (5 - _reveal) * 4.0,
                        sigmaY: (5 - _reveal) * 4.0,
                      ),
                      child: const CineusPoster(
                        movieId: 1,
                        width: 160,
                        height: 240,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.obsidian950,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    clues[(_reveal - 1).clamp(0, clues.length - 1)],
                    key: const ValueKey('guide-demo-clue'),
                    style: AppTypography.titleSmall,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l.worthPoints(rules.scoreAt(_reveal)),
                key: const ValueKey('guide-demo-score'),
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.gold300,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  for (var step = 1; step <= rules.totalSteps; step++)
                    Semantics(
                      selected: _reveal == step,
                      child: Container(
                        width: MediaQuery.textScalerOf(context).scale(14) + 12,
                        height: MediaQuery.textScalerOf(context).scale(14) + 12,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: step <= _reveal
                              ? AppColors.gold300
                              : AppColors.obsidian600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${rules.scoreAt(step)}',
                          style: AppTypography.monoSmall.copyWith(
                            color: step <= _reveal
                                ? AppColors.obsidian950
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const ValueKey('guide-demo-reveal'),
                onPressed: () => setState(
                  () => _reveal = _reveal == rules.totalSteps ? 1 : _reveal + 1,
                ),
                child: Text(
                  _reveal == rules.totalSteps ? l.guideDemoReset : l.revealMore,
                ),
              ),
              Text(l.guidePracticeNotice, style: AppTypography.bodySmall),
            ],
          ),
        ),
    ];
  }

  List<Widget> _answer(BuildContext context) {
    final l = context.l10n;
    final items = ['Interstellar (2014)', 'Gravity (2013)'];
    return [
      Text(l.guideAnswerBody, style: AppTypography.bodySmall),
      const SizedBox(height: 16),
      Text(l.guideDemoClues.split('|').first, style: AppTypography.titleSmall),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('guide-demo-search'),
        controller: _search,
        decoration: InputDecoration(
          labelText: l.movieNameHint,
          prefixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: CineusIcon(CineusAssetId.search),
          ),
        ),
        onChanged: (query) => setState(() {
          _query = query;
          _selection = 0;
          _submitted = false;
        }),
      ),
      const SizedBox(height: 12),
      for (final (i, title) in items.indexed)
        if (title.toLowerCase().contains(_query.trim().toLowerCase()))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: ValueKey('guide-demo-answer-$i'),
              onPressed: () => setState(() {
                _selection = i + 1;
                _submitted = false;
              }),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _selection == i + 1
                      ? AppColors.gold300
                      : AppColors.obsidian600,
                ),
              ),
              child: Text(title),
            ),
          ),
      if (_selection > 0)
        FilledButton(
          key: const ValueKey('guide-demo-confirm'),
          onPressed: _submitted
              ? null
              : () => setState(() => _submitted = true),
          child: Text(l.confirmGuess),
        ),
      if (_submitted)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _selection == 1 ? l.guideDemoCorrect : l.guideDemoWrong,
              key: const ValueKey('guide-demo-feedback'),
              style: AppTypography.bodyMedium.copyWith(
                color: _selection == 1
                    ? AppColors.success400
                    : AppColors.ruby300,
              ),
            ),
          ),
        ),
      const SizedBox(height: 12),
      _GuideCard(
        key: const ValueKey('guide-wrong'),
        asset: CineusAssetId.warning,
        title: l.guideWrongTitle,
        body: l.guideWrongBody,
      ),
      const SizedBox(height: 8),
      Text(l.guidePracticeNotice, style: AppTypography.bodySmall),
    ];
  }
}

class _GuideCard extends StatelessWidget {
  final CineusAssetId asset;
  final String title, body;
  final Widget? child;
  const _GuideCard({
    super.key,
    required this.asset,
    required this.title,
    required this.body,
    this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.obsidian800,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.gold300.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CineusIcon(asset, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTypography.titleSmall)),
          ],
        ),
        const SizedBox(height: 12),
        Text(body, style: AppTypography.bodySmall.copyWith(height: 1.5)),
        if (child != null) ...[const SizedBox(height: 16), child!],
      ],
    ),
  );
}
