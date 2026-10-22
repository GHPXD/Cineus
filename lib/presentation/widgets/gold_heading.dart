import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

class GoldHeading extends StatelessWidget {
  final String text;
  final double size;
  const GoldHeading(this.text, {super.key, required this.size});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => const LinearGradient(
        colors: [Color(0xFFFFFCF1), Color(0xFFFFFCF1), Color(0xFFFFCC3F)],
        stops: [0, .35, 1],
      ).createShader(rect),
      child: Text(
        text,
        style: AppTypography.displaySmall.copyWith(
          fontSize: size,
          height: 1.15,
        ),
      ),
    ),
  );
}
