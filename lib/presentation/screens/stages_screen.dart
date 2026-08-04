import 'package:flutter/material.dart';

import 'generic_stages_screen.dart';

class StagesScreen extends StatelessWidget {
  const StagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericStagesScreen(config: StagesConfig.clues);
  }
}
