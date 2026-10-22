import 'package:flutter/material.dart';

import 'film_stages_screen.dart';

class PosterStagesScreen extends StatelessWidget {
  const PosterStagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FilmStagesScreen(isPoster: true);
  }
}
