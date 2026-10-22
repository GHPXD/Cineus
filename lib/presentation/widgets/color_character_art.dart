import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/color_question.dart';

/// Every silhouette/path is traced from a generated or authorized source PNG.
/// The only runtime
/// operation is tinting the extracted region; no character geometry is authored.
class ColorCharacterArt extends StatelessWidget {
  final ColorQuestion question;
  final SrgbColor choice;
  final Map<String, SrgbColor> palette;
  final double height;
  const ColorCharacterArt({
    super.key,
    required this.question,
    required this.choice,
    required this.palette,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/colors/art/${question.characterId}_base.svg',
            fit: BoxFit.contain,
          ),
          for (final part in palette.entries)
            SvgPicture.asset(
              'assets/colors/art/${question.characterId}_${part.key}.svg',
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                Color(
                  0xff000000 |
                      (part.key == question.artPart
                          ? choice.rgb
                          : part.value.rgb),
                ),
                BlendMode.srcIn,
              ),
            ),
        ],
      ),
    ),
  );
}
