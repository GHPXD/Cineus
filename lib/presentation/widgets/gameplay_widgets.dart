import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'ticket_details_sheet.dart';
import 'color_play_background.dart';

/// Footer occupies real space, leaving a scrollable reading area at large fonts.
class GameplayFrame extends StatelessWidget {
  final Widget header, body, actions;
  final bool colorStudio;
  const GameplayFrame({
    super.key,
    required this.header,
    required this.body,
    required this.actions,
    this.colorStudio = false,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.obsidian950,
    body: ColorPlayBackground(
      enabled: colorStudio,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .28,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: colorStudio
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                  color: AppColors.obsidian600,
                                ),
                              ),
                      ),
                      child: SingleChildScrollView(child: header),
                    ),
                  ),
                  Expanded(child: body),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .46,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorStudio
                            ? Colors.transparent
                            : AppColors.obsidian900,
                        border: colorStudio
                            ? null
                            : const Border(
                                top: BorderSide(color: AppColors.obsidian600),
                              ),
                      ),
                      child: SingleChildScrollView(child: actions),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class GameplayHeader extends ConsumerWidget {
  final PlayState state;
  final VoidCallback onBack;
  final VoidCallback? onStats, onHelp;
  const GameplayHeader({
    super.key,
    required this.state,
    required this.onBack,
    this.onStats,
    this.onHelp,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = state.session!;
    final label = switch (session.kind) {
      SessionKind.daily => '#${state.challengeNumber}',
      SessionKind.stage => l.stageNumber('${session.stageId}'),
      SessionKind.challenge => l.challengeBadge,
      SessionKind.archive => l.archiveMode,
      SessionKind.training => l.practiceMode,
    };
    final balance = ref.watch(ticketBalanceStatusProvider);
    final tickets = ref.watch(ticketNotifierProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l.semBack,
                onPressed: onBack,
                icon: const CineusIcon(CineusAssetId.back),
              ),
              Expanded(
                child: Text(
                  state.mode == GameMode.clue ? l.modeClues : l.modePoster,
                  style: AppTypography.headlineMedium,
                ),
              ),
              if (onStats != null)
                IconButton(
                  tooltip: l.semStats,
                  onPressed: onStats,
                  icon: const CineusIcon(CineusAssetId.stats),
                ),
              if (onHelp != null)
                IconButton(
                  tooltip: l.semHelp,
                  onPressed: onHelp,
                  icon: const CineusIcon(CineusAssetId.help),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(label, style: AppTypography.monoSmall),
                if (state.mode == GameMode.poster)
                  Text(
                    l.worthPoints(state.currentScore),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gold300,
                    ),
                  ),
                TextButton.icon(
                  key: const ValueKey('game-ticket-details'),
                  onPressed: () => showTicketDetails(context),
                  icon: const CineusIcon(CineusAssetId.ticket, size: 16),
                  label: Text(
                    balance.isLoading || balance.hasError
                        ? '—'
                        : l.ticketBalance(tickets.total),
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.gold300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameNotice extends StatelessWidget {
  final String message;
  final CineusAssetId asset;
  final Color color;
  const GameNotice({
    super.key,
    required this.message,
    this.asset = CineusAssetId.warning,
    this.color = AppColors.ruby300,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CineusIcon(asset, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    ),
  );
}

class GuessFeedback extends StatelessWidget {
  final PlayState state;
  const GuessFeedback({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final guesses = state.session?.guesses ?? [];
    if (guesses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GameNotice(
        key: const ValueKey('guess-feedback'),
        asset: CineusAssetId.error,
        message:
            '${context.l10n.wrongGuessRevealed}\n${context.l10n.lastGuessLabel(guesses.last)}',
      ),
    );
  }
}

class GameplayActions extends ConsumerStatefulWidget {
  final PlayState state;
  final VoidCallback onSearch;
  const GameplayActions({
    super.key,
    required this.state,
    required this.onSearch,
  });
  @override
  ConsumerState<GameplayActions> createState() => _GameplayActionsState();
}

class _GameplayActionsState extends ConsumerState<GameplayActions> {
  bool _busy = false;
  String? _error;
  Future<void> _reveal() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(
            (widget.state.mode == GameMode.clue
                    ? clueGameProvider
                    : posterGameProvider)
                .notifier,
          )
          .revealNext();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.gameActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final last = state.isOnLastStep;
    final l = context.l10n;
    return Container(
      key: const ValueKey('game-actions'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.obsidian950,
        border: Border(top: BorderSide(color: AppColors.obsidian700)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            GameNotice(message: _error!, asset: CineusAssetId.error),
            const SizedBox(height: 8),
          ],
          ElevatedButton.icon(
            key: const ValueKey('game-answer'),
            onPressed: _busy ? null : widget.onSearch,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: last ? AppColors.ruby300 : AppColors.gold300,
              foregroundColor: AppColors.obsidian950,
            ),
            icon: const CineusIcon(
              CineusAssetId.search,
              color: AppColors.obsidian950,
            ),
            label: Text(l.gameAnswer),
          ),
          if (state.canRevealMore) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              key: const ValueKey('game-reveal'),
              onPressed: _busy ? null : _reveal,
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const CineusIcon(
                      CineusAssetId.reveal,
                      color: AppColors.textSecondary,
                    ),
              label: Text(
                state.mode == GameMode.clue
                    ? l.skipToClue(state.step + 1)
                    : l.revealMore,
                style: AppTypography.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
