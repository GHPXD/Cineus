import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/extra_hint.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../providers/rewarded_help_provider.dart';
import '../providers/telemetry_provider.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'round_help_sheet.dart';

/// One quiet entry point. Already unlocked information stays visible; payment
/// methods and optional video offers only appear after asking for help.
class ExtraHintsBar extends ConsumerWidget {
  final PlayState state;
  const ExtraHintsBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = state.movie, session = state.session;
    if (movie == null || session == null || state.isFinished) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    final available = ExtraHint.values
        .where(
          (hint) =>
              !session.hasHint(hint) &&
              switch (hint) {
                ExtraHint.director => movie.director.trim().isNotEmpty,
                ExtraHint.year => movie.year > 0,
                ExtraHint.runtime => (movie.runtime ?? 0) > 0,
              },
        )
        .toList();
    String value(ExtraHint hint) => switch (hint) {
      ExtraHint.director => movie.director,
      ExtraHint.year => movie.year.toString(),
      ExtraHint.runtime => l.runtimeMinutes(movie.runtime!),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.purchasedHints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final hint in state.purchasedHints)
                  Text(
                    '${l.hintLabel(hint)}: ${value(hint)}',
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),
        if (available.isNotEmpty && session.id != null)
          OutlinedButton.icon(
            key: const ValueKey('round-help-entry'),
            onPressed: () {
              // Capture services now: the screen may close while an ad is open.
              final tickets = ref.read(ticketNotifierProvider.notifier);
              final game = ref.read(
                (state.mode == GameMode.poster
                        ? posterGameProvider
                        : clueGameProvider)
                    .notifier,
              );
              final telemetry = ref.read(productTelemetryProvider);
              showRoundHelp(
                context,
                gameKey: '${state.mode.name}:${session.id}',
                options: [
                  for (final hint in available)
                    RoundHelpOption(
                      id: hint.name,
                      title: l.hintLabel(hint),
                      asset: CineusAssets.forHint(hint),
                      purchase: () => purchaseRoundHelp(tickets, () async {
                        final granted = await game.grantHint(
                          hint,
                          expectedSessionId: session.id,
                        );
                        if (granted) {
                          await telemetry.record(
                            'extra_hint_bought',
                            properties: {
                              'mode': state.mode.name,
                              'hint': hint.name,
                              'ticket_cost': 1,
                            },
                          );
                        }
                        return granted;
                      }),
                    ),
                ],
              );
            },
            icon: const CineusIcon(CineusAssetId.help, size: 22),
            label: Text(l.helpTitle),
          ),
      ],
    );
  }
}
