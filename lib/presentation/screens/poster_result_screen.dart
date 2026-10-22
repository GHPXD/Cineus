import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/game_session.dart';
import 'generic_result_screen.dart';

class PosterResultScreen extends StatelessWidget {
  final bool won;
  const PosterResultScreen({super.key, required this.won});
  @override
  Widget build(BuildContext context) => GenericResultScreen(
    mode: GameMode.poster,
    config: won ? ResultConfig.victory : ResultConfig.defeat,
    onNavigateToStats: () => context.push('/stats'),
    onNavigateHome: () => context.go('/home'),
  );
}
