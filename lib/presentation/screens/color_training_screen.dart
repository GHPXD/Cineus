import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/color_question.dart';
import '../../domain/entities/color_training_session.dart';
import '../../l10n/app_l10n.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_state_art.dart';
import '../widgets/color_character_art.dart';
import '../widgets/color_controls.dart';
import '../widgets/color_studio.dart';
import '../widgets/color_round_help.dart';
import '../widgets/result_break.dart';
import '../widgets/gameplay_widgets.dart';
import '../providers/color_session_controller.dart';
import '../../data/repositories/color_repository.dart';

/// Shared live game UI; production sessions use the durable controller.
class ColorTrainingScreen extends StatefulWidget {
  final ColorPilotCatalog? catalog;
  final ColorTrainingSession? session;
  final VoidCallback? onBack;
  final ColorSessionController? controller;
  final Future<void> Function()? onNewTraining;
  final Widget Function(SavedColorSession record)? resultActionsBuilder;
  const ColorTrainingScreen({
    super.key,
    this.catalog,
    this.session,
    this.onBack,
    this.controller,
    this.onNewTraining,
    this.resultActionsBuilder,
  });
  @override
  State<ColorTrainingScreen> createState() => _ColorTrainingScreenState();
}

class _ColorTrainingScreenState extends State<ColorTrainingScreen>
    with WidgetsBindingObserver {
  late Future<ColorPilotCatalog> _catalog;
  ColorTrainingSession? _game;
  bool _dialogOpen = false;
  bool _allowPop = false;
  bool _restarting = false;
  bool _leaving = false;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _catalog = _load();
    _game = widget.session;
    if (widget.controller != null) {
      _game = widget.controller!.game;
      widget.controller!.addListener(_changed);
      WidgetsBinding.instance.addObserver(this);
    }
  }

  void _changed() {
    if (mounted) setState(() => _game = widget.controller!.game);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.controller?.flush();
  }

  @override
  void dispose() {
    _scroll.dispose();
    widget.controller?.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<ColorPilotCatalog> _load() async =>
      widget.catalog ??
      ColorPilotCatalog.fromJson(
        jsonDecode(
              await rootBundle.loadString('assets/colors/training_v1.json'),
            )
            as Map<String, dynamic>,
      );

  String _score(int cents) => NumberFormat(
    '0.00',
    Localizations.localeOf(context).languageCode,
  ).format(cents / 100);
  Map<String, SrgbColor> _palette(ColorPilotCatalog catalog, ColorQuestion q) =>
      {
        for (final item in catalog.questions.where(
          (item) => item.characterId == q.characterId && item.artPart != null,
        ))
          item.artPart!: item.target,
      };
  void _top() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Future<bool> _discard() async {
    if (_dialogOpen) return false;
    _dialogOpen = true;
    final l = AppL10n.of(context);
    try {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              scrollable: true,
              title: Text(
                widget.controller == null
                    ? l.colorDiscardTitle
                    : l.colorReplaceTrainingTitle,
              ),
              content: Text(
                widget.controller == null
                    ? l.colorDiscardBody
                    : l.colorReplaceTrainingBody,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l.colorKeepPlaying),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    widget.controller == null
                        ? l.colorDiscardAction
                        : l.colorReplaceTrainingAction,
                  ),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    try {
      if (widget.controller != null) {
        if (widget.controller!.busy || !await widget.controller!.flush()) {
          return;
        }
      } else if (_game?.phase != ColorRoundPhase.finished &&
          !await _discard()) {
        return;
      }
      if (!mounted) return;
      if (widget.onBack != null) {
        widget.onBack!();
      } else if (context.canPop()) {
        setState(() => _allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        context.pop();
      } else {
        context.go('/home');
      }
    } finally {
      _leaving = false;
    }
  }

  Future<void> _restart(ColorPilotCatalog catalog) async {
    if (_restarting) return;
    _restarting = true;
    try {
      if (_game?.phase != ColorRoundPhase.finished && !await _discard()) return;
      if (!mounted) return;
      if (widget.controller != null) {
        if (widget.controller!.busy || !await widget.controller!.flush()) {
          return;
        }
        await widget.onNewTraining?.call();
        return;
      }
      setState(() => _game = ColorTrainingSession.draw(catalog));
      _top();
    } finally {
      _restarting = false;
    }
  }

  Future<void> _act(bool Function(ColorTrainingSession game) action) async {
    final controller = widget.controller;
    if (controller != null) {
      if (await controller.act(action)) _top();
    } else {
      setState(() => action(_game!));
      _top();
    }
  }

  void _rules() {
    final l = AppL10n.of(context);
    final gameContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.obsidian800,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CineusIcon(CineusAssetId.modeColors, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        l.colorRulesTitle,
                        style: AppTypography.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.controller == null
                            ? l.colorTrainingRulesBody
                            : l.colorSavedRules,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.colorClose),
              ),
              if (widget.controller != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    gameContext.push('/colors/guide');
                  },
                  child: Text(l.colorGuideTitle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return FutureBuilder<ColorPilotCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                tooltip: l.semBack,
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                icon: const CineusIcon(CineusAssetId.back),
              ),
              title: Text(l.colorModeTitle),
            ),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const CineusStateArt(CineusStateKind.error),
                Text(l.colorCatalogFailed, style: AppTypography.bodyMedium),
                FilledButton(
                  onPressed: () => setState(() => _catalog = _load()),
                  child: Text(l.colorRetry),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final catalog = snapshot.data!;
        final game = _game ??= ColorTrainingSession.draw(catalog);
        final id = game.question.id;
        final finished = game.phase == ColorRoundPhase.finished;
        final controller = widget.controller;
        final daily = controller?.record.kind == ColorSessionKind.daily;
        final stage = controller?.record.isStage == true;
        final enabled =
            controller == null ||
            (!controller.busy && controller.error == null);
        return PopScope(
          canPop: finished || _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _leave();
          },
          child: ResultBreak(
            gameKey: finished && stage
                ? 'colors:${controller!.record.id}'
                : null,
            child: GameplayFrame(
              colorStudio: true,
              header: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l.semBack,
                      onPressed: _leave,
                      icon: const CineusIcon(CineusAssetId.back),
                    ),
                    const CineusIcon(CineusAssetId.modeColors, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.colorModeTitle,
                        style: AppTypography.headlineMedium,
                      ),
                    ),
                    if (!daily && !stage)
                      IconButton(
                        key: const ValueKey('colors-restart'),
                        tooltip: l.colorRestart,
                        onPressed: enabled ? () => _restart(catalog) : null,
                        icon: const CineusIcon(CineusAssetId.retry),
                      ),
                    IconButton(
                      key: const ValueKey('colors-help'),
                      tooltip: l.colorRulesAction,
                      onPressed: _rules,
                      icon: const CineusIcon(CineusAssetId.help),
                    ),
                  ],
                ),
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 700 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 20;
                  return ListView(
                    key: const ValueKey('colors-game-scroll'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _badge(
                            stage
                                ? l.colorStageTitle(controller!.record.stageId!)
                                : daily
                                ? l.colorDailyBadge
                                : l.colorTrainingBadge,
                          ),
                          if (daily)
                            Text(
                              controller!.record.dailyDate!,
                              style: AppTypography.monoSmall,
                            ),
                          Text(
                            finished
                                ? l.colorComplete
                                : l.colorRoundProgress(game.round, 5),
                            style: AppTypography.monoSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (finished)
                        _final(game, catalog)
                      else if (game.phase == ColorRoundPhase.review)
                        _review(game, catalog, wide)
                      else
                        _question(
                          game,
                          catalog,
                          (constraints.maxHeight * .48).clamp(280.0, 440.0),
                        ),
                    ],
                  );
                },
              ),
              actions: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controller != null &&
                        (controller.error != null ||
                            controller.saving ||
                            controller.dirty ||
                            controller.busy)) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          controller.error != null
                              ? l.colorSaveFailed
                              : l.colorSaving,
                          key: const ValueKey('colors-save-status'),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (controller?.error != null)
                      TextButton(
                        onPressed: controller!.busy ? null : controller.retry,
                        child: Text(
                          controller.error is ColorWriteConflict
                              ? l.colorReloadSaved
                              : l.colorRetry,
                        ),
                      ),
                    if (finished)
                      FilledButton.icon(
                        key: const ValueKey('colors-play-again'),
                        onPressed: enabled
                            ? (daily || stage
                                  ? _leave
                                  : () => _restart(catalog))
                            : null,
                        icon: CineusIcon(
                          daily || stage
                              ? CineusAssetId.back
                              : CineusAssetId.retry,
                          color: AppColors.obsidian900,
                        ),
                        label: Text(
                          stage
                              ? l.colorStageReturn
                              : daily
                              ? l.colorBackHub
                              : l.colorPlayAgain,
                        ),
                      )
                    else if (game.phase == ColorRoundPhase.review)
                      FilledButton.icon(
                        key: const ValueKey('colors-next-round'),
                        onPressed: enabled
                            ? () => _act((game) => game.advance(id))
                            : null,
                        icon: const CineusIcon(
                          CineusAssetId.chevron,
                          color: AppColors.obsidian900,
                        ),
                        label: Text(
                          game.round == 5 ? l.colorSeeFinal : l.colorNextRound,
                        ),
                      )
                    else
                      ColorActionSurface(
                        enabled: enabled,
                        child: FilledButton(
                          key: const ValueKey('colors-confirm'),
                          onPressed: enabled
                              ? () => _act((game) => game.confirm(id))
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 56),
                            backgroundColor: Colors.transparent,
                            textStyle: AppTypography.labelLarge.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          child: Text(l.colorConfirm),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String value) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.gold900,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.gold300.withValues(alpha: .35)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        value,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.gold300,
          letterSpacing: 1,
        ),
      ),
    ),
  );

  Widget _question(
    ColorTrainingSession game,
    ColorPilotCatalog catalog,
    double height,
  ) {
    final l = AppL10n.of(context),
        language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l.colorRecallPart(game.question.text('part', language)),
          child: ColorStudio(
            heading: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        game.question.text('character', language),
                        style: AppTypography.pageTitle.copyWith(
                          color: AppColors.obsidian950,
                          fontWeight: FontWeight.w700,
                          fontSize:
                              MediaQuery.textScalerOf(context).scale(16) > 22
                              ? 20
                              : 26,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('colors-enlarge'),
                      tooltip: l.colorEnlargeCharacter,
                      onPressed: () => _enlarge(game, catalog),
                      icon: const CineusIcon(CineusAssetId.search, size: 22),
                    ),
                  ],
                ),
                Text(
                  game.question.text('work', language),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.obsidian500,
                  ),
                ),
              ],
            ),
            art: ColorCharacterArt(
              key: const ValueKey('colors-live-character'),
              question: game.question,
              choice: game.selection.rgb,
              palette: _palette(catalog, game.question),
              height: height,
            ),
            tools: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gold50,
                border: Border.all(color: AppColors.gold200),
                borderRadius: BorderRadius.circular(999),
              ),
              child: game.hintUsed
                  ? const SizedBox.shrink()
                  : widget.controller != null
                  ? ColorRoundHelpButton(
                      controller: widget.controller!,
                      questionId: game.question.id,
                    )
                  : IconButton(
                      key: const ValueKey('colors-use-hint'),
                      tooltip: l.colorHintAction,
                      onPressed: widget.controller != null
                          ? (widget.controller!.busy ||
                                    widget.controller!.error != null
                                ? null
                                : () => _act(
                                    (game) => game.useHint(game.question.id),
                                  ))
                          : () =>
                                setState(() => game.useHint(game.question.id)),
                      icon: const CineusIcon(CineusAssetId.reveal, size: 22),
                    ),
            ),
            hint: !game.hintUsed
                ? null
                : Container(
                    key: const ValueKey('colors-active-hint'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.obsidian900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      game.guidanceAt != null
                          ? colorRoundAdvice(l, game)
                          : game.question.text('hint', language),
                      style: AppTypography.bodySmall,
                    ),
                  ),
            controls: _editing(game, game.question.id),
          ),
        ),
      ],
    );
  }

  void _enlarge(ColorTrainingSession game, ColorPilotCatalog catalog) {
    final l = AppL10n.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * .45,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: const Color(0xffF4F3E8),
                      child: InteractiveViewer(
                        key: const ValueKey('colors-character-zoom'),
                        minScale: 1,
                        maxScale: 5,
                        child: ColorCharacterArt(
                          question: game.question,
                          choice: game.selection.rgb,
                          palette: _palette(catalog, game.question),
                          height: MediaQuery.sizeOf(context).height * .45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    l.colorZoomHint,
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('colors-character-zoom-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.colorClose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas(Widget child) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xffF4F3E8),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.gold300.withValues(alpha: .55)),
    ),
    child: child,
  );

  Widget _editing(ColorTrainingSession game, String id) => ColorControls(
    compact: true,
    enabled:
        widget.controller == null ||
        (!widget.controller!.busy && widget.controller!.error == null),
    selection: game.selection,
    onChanged: (value) {
      if (widget.controller != null) {
        widget.controller!.choose(value, id);
      } else {
        setState(() => game.choose(value, id));
      }
    },
    onChangeEnd: widget.controller == null
        ? null
        : () => widget.controller!.flush(),
  );

  Widget _review(
    ColorTrainingSession game,
    ColorPilotCatalog catalog,
    bool wide,
  ) {
    final l = AppL10n.of(context),
        language = Localizations.localeOf(context).languageCode;
    final answer = game.answers.last;
    Widget comparison(String label, SrgbColor colour) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: 8),
        _canvas(
          ColorCharacterArt(
            question: answer.question,
            choice: colour,
            palette: _palette(catalog, answer.question),
            height: wide ? 240 : 160,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          colour.hex,
          textAlign: TextAlign.center,
          style: AppTypography.monoSmall,
        ),
      ],
    );
    final enlarged = MediaQuery.textScalerOf(context).scale(14) > 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.colorRoundResult, style: AppTypography.headlineLarge),
        const SizedBox(height: 8),
        Text(
          answer.question.text('character', language),
          style: AppTypography.titleLarge,
        ),
        Text(
          answer.question.text('part', language),
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 16),
        if (enlarged) ...[
          comparison(l.colorYourTone, answer.selection.rgb),
          const SizedBox(height: 16),
          comparison(l.colorReferenceTone, answer.question.target),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: comparison(l.colorYourTone, answer.selection.rgb),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: comparison(l.colorReferenceTone, answer.question.target),
              ),
            ],
          ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text(
            l.colorScoreValue(_score(answer.scoreCents)),
            key: const ValueKey('colors-round-score'),
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.gold300,
            ),
          ),
        ),
        if (answer.hintUsed) ...[
          const SizedBox(height: 8),
          Text(
            l.colorHintApplied,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _final(ColorTrainingSession game, ColorPilotCatalog catalog) {
    final l = AppL10n.of(context),
        language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: CineusIcon(CineusAssetId.modeColors, size: 64)),
        const SizedBox(height: 12),
        Text(
          l.colorFinalTitle,
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          l.colorAverageLabel,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        Text(
          l.colorScoreValue(_score(game.averageCents!)),
          key: const ValueKey('colors-final-average'),
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(color: AppColors.gold300),
        ),
        const SizedBox(height: 20),
        for (final (index, answer) in game.answers.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.obsidian800,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.gold300,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer.question.text('character', language),
                        style: AppTypography.labelLarge,
                      ),
                      Text(
                        answer.question.text('part', language),
                        style: AppTypography.bodySmall,
                      ),
                      if (answer.hintUsed)
                        Text(
                          l.colorHintApplied,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.blue200,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _score(answer.scoreCents),
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.gold300,
                  ),
                ),
              ],
            ),
          ),

        if (widget.controller != null &&
            widget.resultActionsBuilder != null) ...[
          const SizedBox(height: 20),
          widget.resultActionsBuilder!(widget.controller!.record),
        ],
      ],
    );
  }
}
