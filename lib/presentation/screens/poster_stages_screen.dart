import 'package:flutter/material.dart';

import 'generic_stages_screen.dart';

class PosterStagesScreen extends StatelessWidget {
  const PosterStagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericStagesScreen(config: StagesConfig.posters);
  }
}
