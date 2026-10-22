import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/player_collection.dart';
import '../visuals/poster_assets.dart';

/// Capture the displayed card, never a second render with different styling.
/// Wait for all artwork, then a painted frame before reading the boundary.
Future<Uint8List> captureResultCard(
  GlobalKey key,
  BuildContext context,
  CollectionLook look, {
  int? movieId,
}) async {
  await Future.wait([
    for (final item in look.artwork)
      if (item.asset.endsWith('.svg'))
        SvgAssetLoader(item.asset).loadBytes(context).then<void>((_) {})
      else
        precacheImage(
          ExactAssetImage(
            item.asset,
            scale: item.kind == CollectionItemKind.frame ? 2 : 1,
          ),
          context,
        ),
    if (movieId != null)
      precacheImage(
        ResizeImage.resizeIfNeeded(
          PosterAssets.decodeWidth(
            160,
            math.max(2, MediaQuery.devicePixelRatioOf(context)),
          ),
          null,
          AssetImage(PosterAssets.path(movieId)),
        ),
        context,
        onError: (_, __) {},
      ),
  ]);
  if (!context.mounted) throw StateError('Card dismissed');
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) throw StateError('Card dismissed');
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null || boundary.debugNeedsPaint) {
    throw StateError('Card not ready');
  }
  final snapshot = await boundary.toImage(pixelRatio: 2);
  try {
    final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Card encoding failed');
    return bytes.buffer.asUint8List();
  } finally {
    snapshot.dispose();
  }
}
