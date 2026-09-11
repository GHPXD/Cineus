import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

import '../screens/about_screen.dart';
import '../screens/challenge_loader.dart';
import '../screens/defeat_screen.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/how_to_play_screen.dart';
import '../screens/legal_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/poster_stage_detail_screen.dart';
import '../screens/poster_stages_screen.dart';
import '../screens/search_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/stage_detail_screen.dart';
import '../screens/stages_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/victory_screen.dart';
import '../screens/visual_screen.dart';
import '../screens/visual_search_screen.dart';

abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash — outside shell
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashGate(),
      ),

      // ── Main shell with bottom nav ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/stages',
            builder: (context, state) => const StagesScreen(),
          ),
          GoRoute(
            path: '/stages/:id',
            builder: (context, state) {
              final id =
                  int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
              return StageDetailScreen(stageId: id);
            },
          ),
          GoRoute(
            path: '/visual',
            builder: (context, state) => const PosterStagesScreen(),
          ),
          GoRoute(
            path: '/visual/stage/:id',
            builder: (context, state) {
              final id =
                  int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
              return PosterStageDetailScreen(stageId: id);
            },
          ),
        ],
      ),

      // ── Visual game full-screen routes ────────────────────────────────────
      GoRoute(
        path: '/visual/play',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const VisualScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/visual/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: VisualSearchScreen(onBack: () => context.pop()),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/visual/victory',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const VisualVictoryScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, _, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/visual/defeat',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const VisualDefeatScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // ── Full-screen game flows ────────────────────────────────────────────
      GoRoute(
        path: '/game',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: GameScreen(
            onNavigateToSearch: () => context.push('/search'),
            onNavigateToVictory: () => context.go('/victory'),
            onNavigateToDefeat: () => context.go('/defeat'),
            onNavigateToStats: () => context.push('/stats'),
            onNavigateToHowToPlay: () => context.push('/how-to-play'),
            onNavigateBack: () => context.go('/home'),
          ),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: SearchScreen(onBack: () => context.pop()),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/victory',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, _, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: VictoryScreen(
            onNavigateToStats: () => context.push('/stats'),
            onNavigateHome: () => context.go('/home'),
          ),
        ),
      ),
      GoRoute(
        path: '/defeat',
        pageBuilder: (context, state) => CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: DefeatScreen(
            onNavigateToStats: () => context.push('/stats'),
            onNavigateHome: () => context.go('/home'),
          ),
        ),
      ),
      // Challenge received from a friend (D10). Reached from a pasted code or
      // from a cineus:// deep link.
      GoRoute(
        path: '/challenge/:movieId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          return ChallengeLoader(movieId: id);
        },
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => StatsScreen(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalScreen(
          document: LegalDocument.privacy,
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalScreen(
          document: LegalDocument.terms,
        ),
      ),
      GoRoute(
        path: '/how-to-play',
        builder: (context, state) {
          // Reached two ways: the `?` button mid-game (pop back), and the
          // first-run onboarding, which has nothing to pop back to.
          final isOnboarding = state.uri.queryParameters['first'] == '1';
          return HowToPlayScreen(
            isOnboarding: isOnboarding,
            onDismiss: () =>
                isOnboarding ? context.go('/home') : context.pop(),
          );
        },
      ),
    ],
  );
}

/// Splash screen that routes to the how-to-play guide on a first run (D3).
class _SplashGate extends ConsumerWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SplashScreen(
      onComplete: () {
        // Resolved by the time the splash finishes; if the read is somehow still
        // pending, fall through to home rather than block on it.
        final seen = ref.read(onboardingSeenProvider).valueOrNull ?? true;
        context.go(seen ? '/home' : '/how-to-play?first=1');
      },
    );
  }
}
