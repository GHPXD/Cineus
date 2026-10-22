import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LearningArtKind { tickets, daily }

/// Original GPT Image illustrations, traced into SVG assets for offline use.
class LearningArt extends StatelessWidget {
  final LearningArtKind kind;
  const LearningArt(this.kind, {super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 140,
      width: double.infinity,
      child: SvgPicture.asset(
        'assets/generated/illustrations/learning_${kind.name}.svg',
        fit: BoxFit.contain,
      ),
    ),
  );
}
