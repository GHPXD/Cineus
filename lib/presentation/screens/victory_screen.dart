import 'package:flutter/material.dart';

import 'generic_result_screen.dart';

class VictoryScreen extends StatelessWidget {
  final VoidCallback onNavigateToStats;
  final VoidCallback onNavigateHome;

  const VictoryScreen({
    super.key,
    required this.onNavigateToStats,
    required this.onNavigateHome,
  });

  @override
  Widget build(BuildContext context) {
    return GenericResultScreen(
      config: ResultConfig.victory,
      onNavigateToStats: onNavigateToStats,
      onNavigateHome: onNavigateHome,
    );
  }
}
