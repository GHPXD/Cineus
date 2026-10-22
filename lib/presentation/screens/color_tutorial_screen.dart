import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/color_question.dart';
import '../../domain/entities/color_training_session.dart';
import '../../l10n/app_l10n.dart';
import '../providers/color_providers.dart';
import '../providers/telemetry_provider.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/color_character_art.dart';
import '../widgets/color_controls.dart';
import '../widgets/gameplay_widgets.dart';
import '../widgets/color_studio.dart';
import '../../domain/entities/color_scoring.dart';
import 'package:intl/intl.dart';
import 'color_session_screen.dart';

class ColorGuideScreen extends ConsumerWidget {
  const ColorGuideScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/colors');
      }
    }

    return ref
        .watch(colorCatalogProvider)
        .when(
          loading: () =>
              ColorLoadState(failed: false, onBack: back, onRetry: () {}),
          error: (e, s) => ColorLoadState(
            failed: true,
            onBack: back,
            onRetry: () => ref.invalidate(colorCatalogProvider),
          ),
          data: (catalog) => ColorTutorialScreen(
            catalog: catalog,
            onBack: back,
            onDone: () async {
              final repository = ref.read(colorRepositoryProvider);
              final telemetry = ref.read(productTelemetryProvider);
              await repository.markGuideSeen();
              await telemetry.record(
                'tutorial_completed',
                properties: {'mode': 'colors'},
              );
              if (context.mounted) back();
            },
          ),
        );
  }
}

/// A fixed practice example; its sliders never touch a real game or tickets.
class ColorTutorialScreen extends StatefulWidget {
  final ColorPilotCatalog catalog;
  final VoidCallback onBack;
  final Future<void> Function() onDone;
  const ColorTutorialScreen({
    super.key,
    required this.catalog,
    required this.onBack,
    required this.onDone,
  });
  @override
  State<ColorTutorialScreen> createState() => _ColorTutorialScreenState();
}

class _ColorTutorialScreenState extends State<ColorTutorialScreen> {
  int _step = 0, _matches = 0;
  ColorSelection _selection = ColorSelection.initial;
  bool _hint = false, _busy = false, _error = false;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_busy) return;
    if (_step < 2) {
      setState(() => _step++);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } else {
      setState(() {
        _busy = true;
        _error = false;
      });
      try {
        await widget.onDone();
      } catch (_) {
        if (mounted) setState(() => _error = true);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context),
        lang = Localizations.localeOf(context).languageCode;
    final q = widget.catalog.questions.firstWhere(
      (q) => q.id == 'spongebob_body',
      orElse: () => widget.catalog.questions.first,
    );
    final palette = {
      for (final part in widget.catalog.questions.where(
        (p) => p.characterId == q.characterId && p.artPart != null,
      ))
        part.artPart!: part.target,
    };
    final titles = [
      l.colorGuideAdjustTitle,
      l.colorGuideResultTitle,
      l.guideStagesTitle,
    ];
    final descriptions = [
      l.colorGuideAdjustBody,
      l.colorGuideResultBody,
      l.colorGuideDailyRule,
    ];
    Widget art(SrgbColor color, double height) => ColorCharacterArt(
      question: q,
      choice: color,
      palette: palette,
      height: height,
    );
    final score = NumberFormat('0.00', lang).format(
      ColorScoring.roundCents(_selection.rgb, q.target, hintUsed: _hint) / 100,
    );
    return GameplayFrame(
      colorStudio: true,
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: _busy ? null : widget.onBack,
              tooltip: l.semBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF14223B),
                side: const BorderSide(color: AppColors.obsidian600),
                shape: const CircleBorder(),
              ),
              icon: const CineusIcon(CineusAssetId.back),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: l.colorGuideTitle.replaceFirst(
                        l.colorModeTitle,
                        '',
                      ),
                    ),
                    TextSpan(
                      text: l.colorModeTitle,
                      style: const TextStyle(color: AppColors.gold200),
                    ),
                  ],
                ),
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text('${_step + 1}/3', style: AppTypography.monoSmall),
            const SizedBox(width: 12),
          ],
        ),
      ),
      body: ListView(
        key: const ValueKey('colors-guide-scroll'),
        controller: _scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: SizedBox(
              width: 120,
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    left: 8,
                    right: 8,
                    child: SizedBox(
                      height: 3,
                      child: ColoredBox(color: AppColors.obsidian600),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Semantics(
                          label: '${i + 1}/3',
                          selected: i == _step,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= _step
                                  ? AppColors.gold200
                                  : AppColors.obsidian600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_step > 0) ...[
            Text(titles[_step], style: AppTypography.headlineLarge),
            const SizedBox(height: 8),
          ],
          Text(descriptions[_step], style: AppTypography.bodySmall),
          const SizedBox(height: 16),
          if (_step == 0) ...[
            ColorStudio(
              heading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.text('character', lang),
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.obsidian950,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    q.text('work', lang),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.obsidian500,
                    ),
                  ),
                ],
              ),
              art: art(
                _selection.rgb,
                (MediaQuery.sizeOf(context).height * .30).clamp(240.0, 360.0),
              ),
              controls: ColorControls(
                compact: true,
                selection: _selection,
                onChanged: (s) => setState(() => _selection = s),
              ),
              tools: IconButton(
                key: const ValueKey('colors-guide-hint'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.gold50,
                  side: const BorderSide(color: AppColors.gold200),
                  shape: const CircleBorder(),
                ),
                tooltip: l.colorHintAction,
                onPressed: _hint ? null : () => setState(() => _hint = true),
                icon: const CineusIcon(CineusAssetId.reveal, size: 24),
              ),
              hint: !_hint
                  ? null
                  : Text(
                      q.text('hint', lang),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.obsidian900,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(l.guidePracticeNotice, style: AppTypography.bodySmall),
          ] else if (_step == 1) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                Widget sample(String title, SrgbColor color) => Column(
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffF4F3E8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: art(color, 260),
                    ),
                  ],
                );
                final choice = sample(l.colorYourTone, _selection.rgb);
                final target = sample(l.colorReferenceTone, q.target);
                return MediaQuery.textScalerOf(context).scale(14) > 20
                    ? Column(
                        children: [choice, const SizedBox(height: 16), target],
                      )
                    : Row(
                        children: [
                          Expanded(child: choice),
                          const SizedBox(width: 12),
                          Expanded(child: target),
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),
            Text(
              l.colorScoreValue(score),
              key: const ValueKey('colors-guide-score'),
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.gold300,
              ),
            ),
            if (_hint)
              Text(
                l.colorHintApplied,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
            const SizedBox(height: 12),
            Text(l.colorGuideHintRule, style: AppTypography.bodySmall),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.obsidian800,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.gold300.withValues(alpha: .4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.colorStageTitle(1),
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _matches / 2),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < 2; i++)
                        Chip(
                          avatar: CineusIcon(
                            i < _matches
                                ? CineusAssetId.completed
                                : CineusAssetId.modeColors,
                            size: 20,
                          ),
                          label: Text(l.colorStageMatch(i + 1)),
                        ),
                    ],
                  ),
                  OutlinedButton(
                    key: const ValueKey('colors-guide-stage-demo'),
                    onPressed: () => setState(
                      () => _matches = _matches == 2 ? 0 : _matches + 1,
                    ),
                    child: Text(
                      _matches == 2 ? l.guideDemoReset : l.guideDemoComplete,
                    ),
                  ),
                  if (_matches == 2)
                    Text(
                      l.guideDemoUnlocked,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(l.guideTicketsTitle),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l.guideColorsEconomy),
                ),
              ],
            ),
            ExpansionTile(
              title: Text(l.guideSaveTitle),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l.colorGuideSaveRule),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l.colorGuideSaveFailed,
                    style: AppTypography.bodySmall,
                  ),
                ),
              ),
            ColorActionSurface(
              enabled: !_busy,
              child: FilledButton(
                key: const ValueKey('colors-guide-next'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 56),
                  backgroundColor: Colors.transparent,
                  textStyle: AppTypography.labelLarge.copyWith(fontSize: 18),
                ),
                onPressed: _busy ? null : _next,
                child: Text(
                  _busy
                      ? l.colorSaving
                      : _step == 2
                      ? l.colorGuideDone
                      : _step == 0
                      ? l.colorConfirm
                      : l.colorGuideNext,
                ),
              ),
            ),
            if (_step > 0)
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => _step--);
                        if (_scroll.hasClients) _scroll.jumpTo(0);
                      },
                child: Text(l.colorGuidePrevious),
              ),
          ],
        ),
      ),
    );
  }
}
