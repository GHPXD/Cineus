import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../visuals/cineus_assets.dart';

class CineusBrandMark extends StatelessWidget {
  final double size;
  const CineusBrandMark({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      CineusAssets.brandMark,
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}

class CineusWordmark extends StatelessWidget {
  final double fontSize;
  final bool showSymbol;
  final double symbolSize;
  final bool vectorSymbol;
  const CineusWordmark({
    super.key,
    this.fontSize = 28,
    this.showSymbol = false,
    this.symbolSize = 36,
    this.vectorSymbol = false,
  });
  @override
  Widget build(BuildContext context) {
    final word = Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Cine',
            style: TextStyle(color: AppColors.obsidian0),
          ),
          const TextSpan(
            text: 'us',
            style: TextStyle(color: AppColors.gold300),
          ),
        ],
      ),
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.normal,
      ),
    );
    return Semantics(
      label: 'Cineus',
      excludeSemantics: true,
      child: showSymbol
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vectorSymbol)
                  SizedBox.square(
                    dimension: symbolSize,
                    child: SvgPicture.asset(
                      'assets/generated/icons/platformMark.svg',
                    ),
                  )
                else
                  CineusBrandMark(size: symbolSize),
                const SizedBox(width: 8),
                Flexible(child: word),
              ],
            )
          : word,
    );
  }
}
