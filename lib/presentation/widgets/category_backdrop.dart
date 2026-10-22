import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The same cinema atmosphere behind every category heading.
class CategoryBackdrop extends StatelessWidget {
  static const surface = Color(0xFF030910);
  final Widget child;
  const CategoryBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 240,
        child: ExcludeSemantics(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Colors.transparent],
            ).createShader(rect),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Image.asset(
                'assets/home/poster.png',
                fit: BoxFit.cover,
                cacheWidth: 1000,
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}
