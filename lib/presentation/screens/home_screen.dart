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
import '../providers/providers.dart';
import '../l10n_mappers.dart';
import '../providers/stats_notifier.dart';
import '../widgets/reward_toast.dart';
import '../widgets/streak_recovery_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketNotifierProvider);

    return RewardToast(
      child: Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, tickets)),
              SliverToBoxAdapter(child: _buildDailyCard(context, ref)),
              const SliverToBoxAdapter(child: StreakRecoveryCard()),
              SliverToBoxAdapter(child: _buildStatsRow(context, ref)),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayerTickets tickets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Cineus',
                  style: TextStyle(
                    fontFamily: AppFonts.playfair,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _TicketBadge(tickets: tickets),
        ],
      ),
    );
  }

  Widget _buildDailyCard(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final challengeNum = DailySelector.challengeNumber();

    // ── Clue game state (read from DB, independent of current game mode) ─────
    final clueAsync = ref.watch(dailySessionProvider(GameMode.clue));
    final clueSession = clueAsync.value;
    final isClueInProgress = clueSession != null && !clueSession.isFinished;
    final isCluesDone = clueSession != null && clueSession.isFinished;
    final cluesWon = isCluesDone && clueSession.status == GameStatus.won;

    // ── Poster game state ────────────────────────────────────────────────────
    final posterAsync = ref.watch(dailySessionProvider(GameMode.poster));
    final posterSession = posterAsync.value;
    final isPosterDone = posterSession != null && posterSession.isFinished;
    final posterWon = isPosterDone && posterSession.status == GameStatus.won;

    // ── Button state ─────────────────────────────────────────────────────────
    final bothDone = isCluesDone && isPosterDone;
    String? buttonLabel;
    VoidCallback? buttonAction;
    IconData? buttonIcon;

    if (!bothDone) {
      if (isCluesDone) {
        buttonLabel = l10n.playPoster;
        buttonIcon = Icons.image_search_rounded;
        buttonAction = () => context.push('/visual/play');
      } else if (isClueInProgress) {
        buttonLabel = l10n.continueClues;
        buttonIcon = Icons.play_circle_outline_rounded;
        buttonAction = () => context.push('/game');
      } else {
        buttonLabel = l10n.playChallenge;
        buttonIcon = Icons.play_circle_outline_rounded;
        buttonAction = () => context.push('/game');
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.obsidian700, AppColors.obsidian800],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.obsidian600),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
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
                      fontSize: 10,
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

            // ── Status rows ───────────────────────────────────────────────────
            _DailyStatusRow(
              icon: '🎬',
              label: l10n.modeClues,
              isDone: isCluesDone,
              isInProgress: isClueInProgress,
              isWon: cluesWon,
              score: clueSession?.score,
            ),
            const SizedBox(height: 8),
            _DailyStatusRow(
              icon: '🖼️',
              label: l10n.modePoster,
              isDone: isPosterDone,
              isInProgress: false,
              isWon: posterWon,
              score: posterSession?.score,
            ),
            const SizedBox(height: 16),

            // ── Action button / completed badge ───────────────────────────────
            if (bothDone)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success400.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.success400.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.dailyDone,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.success400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: buttonAction,
                  icon: Icon(
                    buttonIcon,
                    size: 18,
                    color: AppColors.obsidian900,
                  ),
                  label: Text(
                    buttonLabel ?? '',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.obsidian900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // ── Countdown ─────────────────────────────────────────────────────
            const _LiveCountdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsState = ref.watch(statsNotifierProvider);

    if (statsState.isLoading) return const SizedBox(height: 80);
    final stats = statsState.stats;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatCard(value: '${stats.totalGames}', label: l10n.statPlayed),
          const SizedBox(width: 12),
          _StatCard(
            value: '${(stats.winRate * 100).round()}%',
            label: l10n.statWins,
          ),
          const SizedBox(width: 12),
          _StatCard(value: '${stats.currentStreak}🔥', label: l10n.statStreak),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.movie_filter_rounded,
              title: l10n.quickActionStages,
              subtitle: l10n.quickActionStagesSub,
              onTap: () => context.go('/stages'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionTile(
              icon: Icons.bar_chart_rounded,
              title: l10n.statsTitle,
              subtitle: l10n.quickActionStatsSub,
              onTap: () => context.push('/stats'),
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Text('🎫', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            context.l10n.tickets(tickets.total, PlayerTickets.maxDailyTickets),
            style: AppTypography.monoSmall.copyWith(
              color: isEmpty ? AppColors.ruby300 : AppColors.gold300,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
      // Declared here too: `excludeSemantics` drops the GestureDetector's own
      // tap action, leaving a button a screen reader cannot activate.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
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

// ─────────────────────────────────────────────────────────────────────────────
// Daily mode row (used inside the daily card for each game type)
// ─────────────────────────────────────────────────────────────────────────────

class _DailyStatusRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool isDone;
  final bool isInProgress;
  final bool isWon;
  final int? score;

  const _DailyStatusRow({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isInProgress,
    required this.isWon,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String statusText;
    Color statusColor;

    if (isDone) {
      statusText = isWon
          ? l10n.scoreWithCheck(score ?? 0)
          : l10n.notThisTimeSkull;
      statusColor = isWon ? AppColors.success400 : AppColors.ruby300;
    } else if (isInProgress) {
      statusText = l10n.inProgressEllipsis;
      statusColor = AppColors.gold300;
    } else {
      statusText = l10n.notPlayedToday;
      statusColor = AppColors.obsidian400;
    }

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.labelLarge),
        const Spacer(),
        Text(
          statusText,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live countdown to next daily challenge
// ─────────────────────────────────────────────────────────────────────────────

class _LiveCountdown extends StatefulWidget {
  const _LiveCountdown();

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  late Timer _timer;
  Duration _remaining = DailySelector.timeUntilNextChallenge();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = DailySelector.timeUntilNextChallenge();
      if (mounted) setState(() => _remaining = r);
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
        Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          context.l10n.nextChallengeCountdown(
            '$h',
            m.toString().padLeft(2, '0'),
            s.toString().padLeft(2, '0'),
          ),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
