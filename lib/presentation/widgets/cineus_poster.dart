import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../visuals/poster_assets.dart';
import 'cineus_state_art.dart';

/// One offline image path, a neutral error state and bounded decoded memory.
/// Flutter Web may ignore cacheWidth; this does not promise a browser memory gain.
class CineusPoster extends StatelessWidget {
  final int movieId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageFrameBuilder? frameBuilder;
  final double minimumPixelRatio;
  const CineusPoster({
    super.key,
    required this.movieId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.frameBuilder,
    this.minimumPixelRatio = 1,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) => Image.asset(
        PosterAssets.path(movieId),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: PosterAssets.decodeWidth(
          width ?? constraints.maxWidth,
          math.max(minimumPixelRatio, MediaQuery.devicePixelRatioOf(context)),
        ),
        frameBuilder: frameBuilder,
        errorBuilder: (_, __, ___) => const PosterPlaceholder(),
      ),
    ),
  );
}
