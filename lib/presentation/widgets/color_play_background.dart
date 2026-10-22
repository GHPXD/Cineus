import 'package:flutter/material.dart';

/// Quiet navy circles from the layout reference, behind all interactive content.
class ColorPlayBackground extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const ColorPlayBackground({
    super.key,
    required this.child,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => !enabled
      ? child
      : DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF09162D), Color(0xFF040D1C), Color(0xFF0B1D3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 100,
                left: -100,
                child: _Orb(180, Color(0x221857AC)),
              ),
              const Positioned(
                bottom: 100,
                right: -95,
                child: _Orb(210, Color(0x222854A8)),
              ),
              const Positioned(
                bottom: -100,
                left: -50,
                child: _Orb(230, Color(0x223949AF)),
              ),
              child,
            ],
          ),
        );
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb(this.size, this.color);
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );
}
