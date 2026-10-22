import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/daily_selector.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/player_tickets.dart';
import '../l10n_mappers.dart';
import '../providers/app_clock.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../providers/reward_notifier.dart';
import '../providers/stats_notifier.dart';
import '../providers/telemetry_provider.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_brand.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/reward_toast.dart';
import '../widgets/streak_recovery_card.dart';
import '../widgets/ticket_details_sheet.dart';
import '../widgets/commerce_placeholders.dart';
import '../widgets/home_cinematic_deck.dart';
import '../providers/color_providers.dart';
import '../widgets/home_progress.dart';
import '../widgets/stage_native_ad.dart';
import '../providers/progress_provider.dart';
import '../providers/journey_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  late DateTime _now;
  GameMode? _opening;
  bool _openingColors = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = ref.read(appClockProvider)();
    _startTimer();
    Future.microtask(() {
      if (mounted) _tick();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick({bool resume = false}) {
    if (!mounted) return;
    final now = ref.read(appClockProvider)();
    final day = DailySelector.todayKey(now);
    final changed = ref.read(dailyDateProvider) != day;
    if (changed) ref.read(dailyDateProvider.notifier).state = day;
    if (changed || resume) {
      ref.invalidate(colorSessionsProvider);
      ref.invalidate(colorHomeOverviewProvider);
      ref.invalidate(dailySessionProvider);
      ref.invalidate(statsNotifierProvider);
      ref.invalidate(posterStatsNotifierProvider);
      ref.invalidate(recoverableStreakDayProvider);
      unawaited(ref.read(ticketNotifierProvider.notifier).refreshBalance());
    }
    setState(() => _now = now);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick(resume: true);
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _openDaily(GameMode mode) async {
    if (_opening != null) return;
    setState(() => _opening = mode);
    final provider = mode == GameMode.clue
        ? clueGameProvider
        : posterGameProvider;
    final loaded = await ref.read(provider.notifier).loadDaily();
    if (!mounted) return;
    setState(() => _opening = null);
    if (!loaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.gameLoadFailed)));
      return;
    }
    final session = ref.read(provider).session!;
    if (session.isFinished) {
      final outcome = session.status == GameStatus.won ? 'victory' : 'defeat';
      context.push(mode == GameMode.clue ? '/$outcome' : '/visual/$outcome');
    } else {
      unawaited(
        ref
            .read(productTelemetryProvider)
            .record('daily_opened', properties: {'mode': mode.name}),
      );
      context.push(
        mode == GameMode.clue
            ? '/game?source=daily'
            : '/visual/play?source=daily',
      );
    }
  }

  Future<void> _openColors() async {
    if (_openingColors || _opening != null) return;
    final overview = ref.read(colorHomeOverviewProvider);
    if (overview.isLoading || overview.hasError) return;
    final record = overview.requireValue.today;
    final date = DailySelector.todayKey(ref.read(appClockProvider)());
    final route = record != null && record.dailyDate == date
        ? '/colors/session/${Uri.encodeComponent(record.id)}'
        : '/colors/daily';
    setState(() => _openingColors = true);
    try {
      await context.push(route);
    } finally {
      if (mounted) {
        ref.invalidate(colorSessionsProvider);
        ref.invalidate(colorHomeOverviewProvider);
        setState(() => _openingColors = false);
      }
    }
  }

  HomeDailyCardData _movieCard(GameMode mode, AsyncValue<GameSession?> value) {
    final l = context.l10n;
    final session = value.valueOrNull;
    final finished = session?.isFinished == true;
    final status = finished
        ? session!.status == GameStatus.won
              ? l.dailyWinPoints(session.score)
              : l.dailyLost
        : session != null
        ? l.dailyPlaying
        : null;
    return HomeDailyCardData(
      id: mode == GameMode.clue ? 'clues' : 'poster',
      title: mode == GameMode.clue ? l.modeClues : l.modePoster,
      description: mode == GameMode.clue
          ? l.homeCluesDescription
          : l.homePosterDescription,
      action: value.hasError
          ? l.retryAction
          : finished
          ? l.seeResult
          : session != null
          ? l.actionContinue
          : l.homeDailyAction,
      status: status,
      icon: mode == GameMode.clue
          ? CineusAssetId.modeClues
          : CineusAssetId.modePoster,
      loading: value.isLoading,
      failed: value.hasError,
      opening: _opening == mode,
      onOpen: _opening != null || _openingColors
          ? null
          : value.hasError
          ? () => ref.invalidate(dailySessionProvider(mode))
          : () => _openDaily(mode),
    );
  }

  HomeDailyCardData _colorsCard() {
    final l = context.l10n;
    final overview = ref.watch(colorHomeOverviewProvider);
    final daily = overview.valueOrNull?.today;
    return HomeDailyCardData(
      id: 'colors',
      title: l.colorModeTitle,
      description: l.colorHomeDescription,
      icon: CineusAssetId.modeColors,
      action: overview.hasError
          ? l.retryAction
          : daily?.status == 'completed'
          ? l.colorSeeResult
          : daily == null
          ? l.homeDailyAction
          : l.colorResume,
      status: daily?.status == 'completed'
          ? l.homeDailyCompleted
          : daily != null
          ? l.colorResumeRound(daily.game.round)
          : null,
      loading: overview.isLoading,
      failed: overview.hasError,
      opening: _openingColors,
      onOpen: _opening != null || _openingColors
          ? null
          : overview.hasError
          ? () {
              ref.invalidate(colorSessionsProvider);
              ref.invalidate(colorHomeOverviewProvider);
            }
          : _openColors,
    );
  }

  Widget _dailyHeading(DateTime date) {
    final l = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l.colorDailyTitle,
          style: AppTypography.headlineMedium.copyWith(fontSize: 22),
        ),
        HomeChromePanel(
          padding: 7,
          radius: 24,
          child: Wrap(
            spacing: 5,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const CineusIcon(CineusAssetId.homeCalendar, size: 14),
              Text(
                '#${DailySelector.challengeNumber(date)}',
                style: AppTypography.bodySmall.copyWith(fontSize: 8.5),
              ),
              Text(
                l.dailyFree,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 8.5,
                  color: AppColors.blue300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(journeyProgressProvider);
    ref.watch(presenceProvider);
    ref.watch(continuingGameProvider);
    final l = context.l10n;
    final tickets = ref.watch(ticketNotifierProvider);
    final balance = ref.watch(ticketBalanceStatusProvider);
    final clue = ref.watch(dailySessionProvider(GameMode.clue));
    final poster = ref.watch(dailySessionProvider(GameMode.poster));
    final date = DailySelector.dateFromKey(ref.watch(dailyDateProvider))!;
    return RewardToast(
      child: Scaffold(
        backgroundColor: const Color(0xFF03080F),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                key: const ValueKey('home-scroll'),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                children: [
                  _header(tickets, balance),
                  if (balance.hasError) ...[
                    const SizedBox(height: 8),
                    _HomeNotice(
                      message: l.ticketBalanceFailed,
                      onRetry: () => ref
                          .read(ticketNotifierProvider.notifier)
                          .refreshBalance(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  HomeCinematicDeck(
                    cards: [
                      _movieCard(GameMode.clue, clue),
                      _movieCard(GameMode.poster, poster),
                      _colorsCard(),
                    ],
                    heading: _dailyHeading(date),
                    countdown: _Countdown(now: _now),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: StageNativeAd(key: ValueKey('home-native-ad')),
                  ),
                  const StreakRecoveryCard(),
                  const HomeProgress(),
                  const SizedBox(height: 12),
                  _stats(),
                  const SizedBox(height: 10),
                  _actions(),
                  const SizedBox(height: 12),
                  EarnTicketsEntry(
                    key: const ValueKey('home-earn-tickets'),
                    onTap: () => showTicketDetails(context),
                  ),
                  const SizedBox(height: 12),
                  const AdvertisementPlaceholder(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(PlayerTickets tickets, AsyncValue<void> balance) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(28) > 36;
          final settings = IconButton(
            tooltip: context.l10n.settingsTitle,
            onPressed: () => context.push('/settings'),
            icon: const CineusIcon(
              CineusAssetId.settings,
              size: 23,
              color: AppColors.gold300,
            ),
          );
          final wallet = _TicketBadge(tickets: tickets, status: balance);
          final brand = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CineusWordmark(
                fontSize: 31,
                symbolSize: 42,
                showSymbol: true,
                vectorSymbol: true,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Text(
                  context.l10n.homeTitle.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 7.5,
                    letterSpacing: 1.6,
                    color: const Color(0xFFB5C9EE),
                  ),
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                brand,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: wallet,
                      ),
                    ),
                    settings,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: brand),
              const SizedBox(width: 8),
              wallet,
              settings,
            ],
          );
        },
      );
  Widget _stats() => HomeChromePanel(
    gold: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const CineusIcon(CineusAssetId.homeStats, size: 20),
            Text(
              context.l10n.homeStatsTitle,
              style: AppTypography.headlineMedium.copyWith(fontSize: 17),
            ),
            TextButton(
              onPressed: () => context.push('/stats'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${context.l10n.modeClues} · ${context.l10n.modePoster}',
                      style: AppTypography.bodySmall.copyWith(fontSize: 8.5),
                    ),
                  ),
                  const CineusIcon(CineusAssetId.chevron, size: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _statsData(),
      ],
    ),
  );

  Widget _statsData() {
    final clue = ref.watch(statsNotifierProvider);
    final poster = ref.watch(posterStatsNotifierProvider);
    if (clue.hasError || poster.hasError) {
      return _HomeNotice(
        message: context.l10n.statsLoadFailed,
        onRetry: () {
          ref.invalidate(statsNotifierProvider);
          ref.invalidate(posterStatsNotifierProvider);
        },
      );
    }
    if (clue.isLoading || poster.isLoading) {
      return Semantics(
        liveRegion: true,
        label: context.l10n.statsTitle,
        child: const LinearProgressIndicator(),
      );
    }
    final games = clue.stats.totalGames + poster.stats.totalGames;
    final wins = clue.stats.totalWins + poster.stats.totalWins;
    final items = [
      ('$games', context.l10n.statPlayed, CineusAssetId.homeGames),
      ('$wins', context.l10n.statWins, CineusAssetId.homeTrophy),
      (
        games == 0 ? '—' : '${(wins / games * 100).round()}%',
        context.l10n.statRate,
        CineusAssetId.categoryGoal,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = MediaQuery.textScalerOf(context).scale(14) > 22 ? 1 : 3;
        final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: HomeChromePanel(
                  padding: 9,
                  radius: 10,
                  child: Row(
                    children: [
                      CineusIcon(item.$3, size: 21),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$1, style: AppTypography.titleMedium),
                            const SizedBox(height: 3),
                            Text(
                              item.$2,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _actions() => LayoutBuilder(
    builder: (context, constraints) {
      final actions = [
        _ActionTile(
          key: const ValueKey('home-open-challenge'),
          asset: CineusAssetId.challenge,
          title: context.l10n.homeOpenChallenge,
          subtitle: context.l10n.homeOpenChallengeSub,
          onTap: () => context.push('/challenge-entry'),
        ),
        _ActionTile(
          key: const ValueKey('home-open-stats'),
          asset: CineusAssetId.stats,
          title: context.l10n.statsTitle,
          subtitle: context.l10n.quickActionStatsSub,
          onTap: () => context.push('/stats'),
        ),
      ];
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      Size measure(String text, TextStyle style, double width) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: width);
        final size = painter.size;
        painter.dispose();
        return size;
      }

      // Keep titles on one line without shrinking accessible text. If either
      // title cannot fit beside the other tile, use full-width stacked tiles.
      const chromeWidth = 20 + 23 + 8 + 8 + 12;
      final columnWidth = (constraints.maxWidth - 12) / 2;
      final stacked =
          constraints.maxWidth < 330 ||
          scaler.scale(14) > 20 ||
          actions.any(
            (action) =>
                measure(
                  action.title,
                  _ActionTile.titleStyle,
                  double.infinity,
                ).width >
                columnWidth - chromeWidth,
          );
      final textWidth =
          (stacked ? constraints.maxWidth : columnWidth) - chromeWidth;
      var tileHeight = 48.0;
      for (final action in actions) {
        final contentHeight =
            measure(action.title, _ActionTile.titleStyle, textWidth).height +
            measure(
              action.subtitle,
              _ActionTile.subtitleStyle,
              textWidth,
            ).height;
        final height = (contentHeight > 23 ? contentHeight : 23.0) + 20;
        if (height > tileHeight) tileHeight = height;
      }
      final tiles = [
        for (final action in actions)
          SizedBox(height: tileHeight, child: action),
      ];
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [tiles[0], const SizedBox(height: 10), tiles[1]],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: tiles[0]),
          const SizedBox(width: 12),
          Expanded(child: tiles[1]),
        ],
      );
    },
  );
}

class _TicketBadge extends StatelessWidget {
  final PlayerTickets tickets;
  final AsyncValue<void> status;
  const _TicketBadge({required this.tickets, required this.status});
  @override
  Widget build(BuildContext context) => Semantics(
    label: status.hasError
        ? context.l10n.ticketBalanceFailed
        : status.isLoading
        ? context.l10n.ticketDetailsTitle
        : context.l10n.semTicketBalance(tickets.total),
    button: true,
    excludeSemantics: true,
    onTap: () => showTicketDetails(context),
    child: Material(
      color: const Color(0xFF100E02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.gold300.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('ticket-balance'),
        onTap: () => showTicketDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CineusIcon(
                CineusAssetId.ticket,
                color: AppColors.gold300,
                size: 18,
              ),
              const SizedBox(width: 6),
              if (status.isLoading)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Flexible(
                  child: Text(
                    status.hasError
                        ? '—'
                        : context.l10n.ticketBalance(tickets.total),
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.gold300,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final CineusAssetId asset;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    super.key,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  static TextStyle get titleStyle =>
      AppTypography.labelLarge.copyWith(fontSize: 12, letterSpacing: 0);
  static TextStyle get subtitleStyle =>
      AppTypography.bodySmall.copyWith(fontSize: 10);
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $subtitle',
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: const Color(0xFF07101B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.obsidian700),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CineusIcon(asset, color: AppColors.blue300, size: 23),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    Text(subtitle, style: subtitleStyle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CineusIcon(
                CineusAssetId.chevron,
                color: AppColors.textTertiary,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Countdown extends StatelessWidget {
  final DateTime now;
  const _Countdown({required this.now});
  @override
  Widget build(BuildContext context) {
    final remaining = DailySelector.timeUntilNextChallenge(now);
    return Row(
      children: [
        const CineusIcon(
          CineusAssetId.clock,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.l10n.nextChallengeCountdown(
              '${remaining.inHours}',
              remaining.inMinutes.remainder(60).toString().padLeft(2, '0'),
              remaining.inSeconds.remainder(60).toString().padLeft(2, '0'),
            ),
            style: AppTypography.bodySmall.copyWith(fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class _HomeNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _HomeNotice({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppTypography.bodySmall),
        TextButton(onPressed: onRetry, child: Text(context.l10n.retryAction)),
      ],
    ),
  );
}
