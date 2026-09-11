import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/daily_selector.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/player_tickets.dart';
import '../l10n_mappers.dart';
import '../providers/providers.dart';
import '../providers/stats_notifier.dart';
import '../widgets/reward_toast.dart';
import '../widgets/streak_recovery_card.dart';
import '../widgets/tap_target.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketNotifierProvider);

    return RewardToast(
      child: Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context, tickets)),
                  SliverToBoxAdapter(child: _buildDailyCard(context, ref)),
                  const SliverToBoxAdapter(child: StreakRecoveryCard()),
                  SliverToBoxAdapter(child: _buildStatsRow(context, ref)),
                  SliverToBoxAdapter(child: _buildQuickActions(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayerTickets tickets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Text(
            'Cineus',
            style: TextStyle(
              fontFamily: AppFonts.playfair,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _TicketBadge(tickets: tickets),
          const SizedBox(width: 4),
          TapTarget(
            label: context.l10n.settingsTitle,
            onTap: () => context.push('/settings'),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.obsidian800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.obsidian700),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 19,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final challengeNum = DailySelector.challengeNumber();
    final clueAsync = ref.watch(dailySessionProvider(GameMode.clue));
    final posterAsync = ref.watch(dailySessionProvider(GameMode.poster));
    final clueSession = clueAsync.valueOrNull;
    final posterSession = posterAsync.valueOrNull;
    final bothDone = clueSession?.isFinished == true &&
        posterSession?.isFinished == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.obsidian700, AppColors.obsidian800],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.obsidian600),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold300.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold300.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    l10n.dailyChallengeLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold300,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#$challengeNum',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DailyModeTile(
              icon: '🎬',
              label: l10n.modeClues,
              session: clueSession,
              isLoading: clueAsync.isLoading,
              onTap: () => context.push('/game?source=daily'),
              playLabel: l10n.playChallenge,
              continueLabel: l10n.continueClues,
            ),
            const SizedBox(height: 10),
            _DailyModeTile(
              icon: '🖼️',
              label: l10n.modePoster,
              session: posterSession,
              isLoading: posterAsync.isLoading,
              onTap: () => context.push('/visual/play?source=daily'),
              playLabel: l10n.playPoster,
              continueLabel: l10n.continuePoster,
            ),
            if (bothDone) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success400.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success400.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '🎉  ${l10n.dailyDone}',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.success400,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const _LiveCountdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(statsNotifierProvider);
    final stats = state.stats;

    if (state.isLoading && stats.totalGames == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                height: 72,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
                decoration: BoxDecoration(
                  color: AppColors.obsidian800,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.obsidian700),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatCard(value: '${stats.totalGames}', label: l10n.statPlayed),
          const SizedBox(width: 10),
          _StatCard(
            value: stats.totalGames == 0
                ? '—'
                : '${(stats.winRate * 100).round()}%',
            label: l10n.statWins,
          ),
          const SizedBox(width: 10),
          _StatCard(value: '${stats.currentStreak}🔥', label: l10n.statStreak),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            _ActionTile(
              icon: Icons.emoji_events_outlined,
              title: l10n.challengeOpenTitle,
              subtitle: l10n.quickActionChallengeSub,
              onTap: () => context.push('/challenge-entry'),
            ),
            _ActionTile(
              icon: Icons.bar_chart_rounded,
              title: l10n.statsTitle,
              subtitle: l10n.quickActionStatsSub,
              onTap: () => context.push('/stats'),
            ),
          ];
          if (constraints.maxWidth < 390) {
            return Column(
              children: [
                actions[0],
                const SizedBox(height: 10),
                actions[1],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: actions[0]),
              const SizedBox(width: 12),
              Expanded(child: actions[1]),
            ],
          );
        },
      ),
    );
  }
}

class _DailyModeTile extends StatelessWidget {
  final String icon;
  final String label;
  final GameSession? session;
  final bool isLoading;
  final VoidCallback onTap;
  final String playLabel;
  final String continueLabel;

  const _DailyModeTile({
    required this.icon,
    required this.label,
    required this.session,
    required this.isLoading,
    required this.onTap,
    required this.playLabel,
    required this.continueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = session?.isFinished == true;
    final inProgress = session != null && !session!.isFinished;
    final won = session?.status == GameStatus.won;

    final status = done
        ? won
            ? l10n.scoreWithCheck(session?.score ?? 0)
            : l10n.notThisTimeSkull
        : inProgress
            ? l10n.inProgressEllipsis
            : l10n.notPlayedToday;
    final statusColor = done
        ? won
            ? AppColors.success400
            : AppColors.ruby300
        : inProgress
            ? AppColors.gold300
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.obsidian700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(
                  isLoading && session == null ? '…' : status,
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!done)
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: isLoading ? null : onTap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: AppTypography.labelSmall.copyWith(fontSize: 12),
                ),
                child: Text(inProgress ? continueLabel : playLabel),
              ),
            )
          else
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success400,
              size: 24,
            ),
        ],
      ),
    );
  }
}

class _TicketBadge extends StatelessWidget {
  final PlayerTickets tickets;
  const _TicketBadge({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final isEmpty = !tickets.hasTickets;
    return Semantics(
      label: context.l10n.semTicketBalance(tickets.total),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isEmpty
              ? AppColors.ruby900.withValues(alpha: 0.5)
              : AppColors.gold900.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmpty
                ? AppColors.ruby300.withValues(alpha: 0.4)
                : AppColors.gold300.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎫', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              context.l10n.tickets(
                tickets.total,
                PlayerTickets.maxDailyTickets,
              ),
              style: AppTypography.monoSmall.copyWith(
                color: isEmpty ? AppColors.ruby300 : AppColors.gold300,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.obsidian800,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.obsidian700),
        ),
        child: Column(
          children: [
            Text(value, style: AppTypography.titleMedium),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.obsidian800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.obsidian700),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.blue300, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveCountdown extends StatefulWidget {
  const _LiveCountdown();

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  late final Timer _timer;
  Duration _remaining = DailySelector.timeUntilNextChallenge();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = DailySelector.timeUntilNextChallenge();
      if (mounted) setState(() => _remaining = remaining);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    return Row(
      children: [
        const Icon(
          Icons.timer_outlined,
          size: 15,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            context.l10n.nextChallengeCountdown(
              '$h',
              m.toString().padLeft(2, '0'),
              s.toString().padLeft(2, '0'),
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}