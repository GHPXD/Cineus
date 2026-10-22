import 'package:flutter/material.dart';

/// Filters the entire traced character, including fixed base colors and details.
/// Available previews never reveal colors; locked previews reveal only an outline.
class CharacterPreview extends StatelessWidget {
  final Widget child;
  final bool locked;
  const CharacterPreview({
    super.key,
    required this.child,
    required this.locked,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColorFiltered(
      colorFilter: locked
          ? const ColorFilter.mode(Color(0xFF607087), BlendMode.srcIn)
          : const ColorFilter.matrix(<double>[
              .2126,
              .7152,
              .0722,
              0,
              0,
              .2126,
              .7152,
              .0722,
              0,
              0,
              .2126,
              .7152,
              .0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
      child: child,
    ),
  );
}
