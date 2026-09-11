import 'package:flutter/material.dart';

import '../../domain/entities/game_session.dart';
import 'generic_stage_detail_screen.dart';

class PosterStageDetailScreen extends StatelessWidget {
  final int stageId;

  const PosterStageDetailScreen({super.key, required this.stageId});

  @override
  Widget build(BuildContext context) {
    return GenericStageDetailScreen(
      stageId: stageId,
      config: const StageDetailConfig(
        mode: GameMode.poster,
        playRoute: '/visual/play?source=stage',
      ),
    );
  }
}