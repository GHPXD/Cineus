import 'package:flutter/material.dart';

import 'generic_result_screen.dart';

class DefeatScreen extends StatelessWidget {
  final VoidCallback onNavigateToStats;
  final VoidCallback onNavigateHome;

  const DefeatScreen({
    super.key,
    required this.onNavigateToStats,
    required this.onNavigateHome,
  });

  @override
  Widget build(BuildContext context) {
    return GenericResultScreen(
      config: ResultConfig.defeat,
      onNavigateToStats: onNavigateToStats,
      onNavigateHome: onNavigateHome,
    );
  }
}
