import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

enum CineusStateKind { empty, error, recovery }

/// Decorative GPT Image artwork; the adjacent localized text explains the state.
class CineusStateArt extends StatelessWidget {
  final CineusStateKind kind;
  final CineusAssetId? symbol;
  const CineusStateArt(this.kind, {super.key, this.symbol});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: SizedBox(
        width: 220,
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/generated/illustrations/state_${kind.name}.svg',
                fit: BoxFit.contain,
              ),
            ),
            if (symbol != null)
              Positioned(
                right: 12,
                bottom: 8,
                child: CineusIcon(symbol!, size: 32),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Neutral generated cover; it never invents a film poster or reveals an answer.
class PosterPlaceholder extends StatelessWidget {
  const PosterPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = math.min(
          64.0,
          math.min(constraints.maxWidth, constraints.maxHeight) * .5,
        );
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.blueDimGradient),
          child: Center(
            child: CineusIcon(
              CineusAssetId.posterMissing,
              size: math.max(8, iconSize),
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    ),
  );
}
