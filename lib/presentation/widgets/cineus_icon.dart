import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../visuals/cineus_assets.dart';

enum CineusIconState { normal, muted, highlighted }

/// Artwork generated in GPT Image and automatically traced into SVG assets.
/// Geometry lives in the generated assets; this widget controls layout/state.
class CineusIcon extends StatelessWidget {
  final CineusAssetId asset;
  final double size;
  final Color? color;
  final CineusIconState state;
  final String? semanticLabel;
  const CineusIcon(
    this.asset, {
    super.key,
    this.size = 20,
    this.color,
    this.state = CineusIconState.normal,
    this.semanticLabel,
  }) : assert(size > 0);
  @override
  Widget build(BuildContext context) {
    final tone =
        color ??
        switch (state) {
          CineusIconState.normal => IconTheme.of(context).color,
          CineusIconState.muted => AppColors.textTertiary,
          CineusIconState.highlighted => AppColors.blue300,
        };
    final ink = tone != null && tone.computeLuminance() < .12 && tone.a > .8;
    final muted =
        state == CineusIconState.muted || tone == AppColors.textTertiary;
    final art = SizedBox.square(
      dimension: size,
      child: Opacity(
        opacity: (muted ? .55 : 1.0) * (tone?.a ?? 1.0),
        child: SvgPicture.asset(
          'assets/generated/icons/${asset.name}${ink ? '_ink' : ''}.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ink ? ColorFilter.mode(tone, BlendMode.srcIn) : null,
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: art)
        : Semantics(
            image: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: art,
          );
  }
}
