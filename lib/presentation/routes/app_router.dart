import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/challenge_code.dart';
import '../../domain/entities/game_session.dart';
import '../providers/providers.dart';
import '../screens/cinema_showcase_screen.dart';

import '../screens/about_screen.dart';
import '../screens/font_licenses_screen.dart';
import '../screens/challenge_entry_screen.dart';
import '../screens/challenge_loader.dart';
import '../screens/defeat_screen.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/color_session_screen.dart';
import '../screens/color_hub_screen.dart';
import '../screens/color_stages_screen.dart';
import '../screens/color_credits_screen.dart';
import '../screens/color_tutorial_screen.dart';
import '../../data/repositories/color_repository.dart';
import '../screens/how_to_play_screen.dart';
import '../screens/legal_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/poster_result_screen.dart';
import '../screens/poster_stage_detail_screen.dart';
import '../screens/poster_stages_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/player_collection_screen.dart';
import '../screens/journey_screen.dart';
import '../screens/seasons_screen.dart';
import '../screens/support_screen.dart';
import '../screens/archive_screen.dart';
import '../screens/mastery_screen.dart';
import '../screens/player_data_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/stage_detail_screen.dart';
import '../screens/stages_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/victory_screen.dart';
import '../screens/visual_screen.dart';
import '../screens/visual_search_screen.dart';

abstract final class AppRouter {
  static final router = create();

  static GoRouter create({String initialLocation = '/'}) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/data',
        builder: (context, state) => const PlayerDataScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) =>
            FriendsScreen(initialCode: state.uri.queryParameters['code']),
      ),
      GoRoute(path: '/', builder: (context, state) => const _SplashGate()),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          key: state.pageKey,
          child: MainScaffold(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stages',
                builder: (context, state) => const StagesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      return StageDetailScreen(stageId: id ?? -1);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/visual',
                builder: (context, state) => const PosterStagesScreen(),
                routes: [
                  GoRoute(
                    path: 'stage/:id',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      return PosterStageDetailScreen(stageId: id ?? -1);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/colors',
                builder: (context, state) => const ColorStagesScreen(),
                routes: [
                  GoRoute(
                    path: 'stage/:id',
                    builder: (context, state) => ColorStagesScreen(
                      stageId:
                          int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                    ),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const ColorHubScreen(),
                  ),
                  GoRoute(
                    path: 'stats',
                    redirect: (context, state) => '/stats?mode=colors',
                  ),
                  GoRoute(
                    path: 'credits',
                    builder: (context, state) => const ColorCreditsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/colors/guide',
        builder: (context, state) => const ColorGuideScreen(),
      ),
      GoRoute(
        path: '/visual/play',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: VisualScreen(
            expectedKind: _sessionKind(state.uri.queryParameters['source']),
          ),
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/visual/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: VisualSearchScreen(
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/visual/play'),
          ),
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/visual/victory',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PosterResultScreen(won: true),
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          transitionsBuilder: (context, animation, _, child) => ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
      ),
      GoRoute(
        path: '/visual/defeat',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PosterResultScreen(won: false),
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/game',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          child: GameScreen(
            expectedKind: _sessionKind(state.uri.queryParameters['source']),
            onNavigateToSearch: () => context.push('/search'),
            onNavigateToVictory: () => context.go('/victory'),
            onNavigateToDefeat: () => context.go('/defeat'),
            onNavigateToStats: () => context.push('/stats'),
            onNavigateToHowToPlay: () => context.push('/how-to-play'),
            onNavigateBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: SearchScreen(
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/game'),
          ),
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/victory',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          transitionsBuilder: (context, animation, _, child) => ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: VictoryScreen(
            onNavigateToStats: () => context.push('/stats'),
            onNavigateHome: () => context.go('/home'),
          ),
        ),
      ),
      GoRoute(
        path: '/defeat',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          reverseTransitionDuration: _motionDuration(
            context,
            const Duration(milliseconds: 400),
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          child: DefeatScreen(
            onNavigateToStats: () => context.push('/stats'),
            onNavigateHome: () => context.go('/home'),
          ),
        ),
      ),
      GoRoute(
        path: '/challenge-entry',
        builder: (context, state) => const ChallengeEntryScreen(),
      ),
      GoRoute(
        path: '/challenge/:challenge',
        builder: (context, state) {
          final value = state.pathParameters['challenge'] ?? '';
          final legacyId = int.tryParse(value);
          final target = legacyId != null && legacyId > 0 && legacyId <= 32767
              ? ChallengeTarget(legacyId)
              : ChallengeCode.decodeTarget(value);
          return ChallengeLoader(
            key: ValueKey('challenge_${target?.mode.name}_${target?.movieId}'),
            movieId: target?.movieId,
            mode: target?.mode ?? GameMode.clue,
          );
        },
      ),
      GoRoute(
        path: '/stats',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: StatsScreen(
            initialMode: state.uri.queryParameters['mode'] == 'poster'
                ? GameMode.poster
                : state.uri.queryParameters['mode'] == 'clue'
                ? GameMode.clue
                : null,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            initialColors: state.uri.queryParameters['mode'] == 'colors',
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/collection',
        builder: (context, state) => const PlayerCollectionScreen(),
      ),
      GoRoute(
        path: '/journey',
        builder: (context, state) => const JourneyScreen(),
      ),
      GoRoute(path: '/archive', builder: (_, __) => const ArchiveScreen()),
      GoRoute(path: '/mastery', builder: (_, __) => const MasteryScreen()),
      GoRoute(
        path: '/seasons',
        builder: (context, state) => const SeasonsScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(
        path: '/colors/train',
        builder: (context, state) => const ColorSessionScreen(),
      ),
      GoRoute(
        path: '/colors/daily',
        builder: (context, state) =>
            const ColorSessionScreen(kind: ColorSessionKind.daily),
      ),
      GoRoute(
        path: '/colors/session/:id',
        builder: (context, state) =>
            ColorSessionScreen(sessionId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/font-licenses',
        builder: (context, state) => const FontLicensesScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/audience',
        // Keep older links functional without restoring the retired screen.
        redirect: (context, state) => state.uri.queryParameters['first'] == '1'
            ? '/how-to-play?first=1'
            : '/home',
      ),
      GoRoute(
        path: '/showcase/:id',
        builder: (context, state) =>
            CinemaShowcaseScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocument.privacy),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocument.terms),
      ),
      GoRoute(
        path: '/how-to-play/colors',
        builder: (context, state) => const ColorGuideScreen(),
      ),
      GoRoute(
        path: '/how-to-play',
        builder: (context, state) {
          final isOnboarding = state.uri.queryParameters['first'] == '1';
          return HowToPlayScreen(
            key: ValueKey('guide-$isOnboarding'),
            isOnboarding: isOnboarding,
            onDismiss: () => !isOnboarding && context.canPop()
                ? context.pop()
                : context.go('/home'),
          );
        },
      ),
    ],
  );

  static Duration _motionDuration(BuildContext context, Duration normal) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;

  static SessionKind _sessionKind(String? source) => switch (source) {
    'stage' => SessionKind.stage,
    'challenge' => SessionKind.challenge,
    'archive' => SessionKind.archive,
    'training' => SessionKind.training,
    _ => SessionKind.daily,
  };
}

class _SplashGate extends ConsumerStatefulWidget {
  const _SplashGate();

  @override
  ConsumerState<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<_SplashGate> {
  bool _minimumElapsed = false;
  bool _navigated = false;

  void _tryNavigate(AsyncValue<bool> onboarding) {
    if (!_minimumElapsed || _navigated || !onboarding.hasValue) {
      return;
    }
    _navigated = true;
    final seen = onboarding.requireValue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(seen ? '/home' : '/how-to-play?first=1');
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingSeenProvider);
    _tryNavigate(onboarding);

    return SplashScreen(
      onComplete: () {
        if (_minimumElapsed) return;
        setState(() => _minimumElapsed = true);
      },
    );
  }
}
