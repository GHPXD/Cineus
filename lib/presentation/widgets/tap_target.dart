import 'package:flutter/material.dart';

/// A tap target that is always at least 48×48 and always announced (B9).
///
/// Several icon buttons in the app were 36×36 `GestureDetector`s: too small for
/// the 48dp minimum both Material and the iOS HIG ask for, and invisible to a
/// screen reader because a bare `GestureDetector` carries no semantics. The
/// visual size stays whatever [child] draws — only the touch area grows.
class TapTarget extends StatelessWidget {
  /// Spoken description of the action, e.g. "Back".
  final String label;

  final VoidCallback? onTap;
  final Widget child;

  /// Minimum touch area on both axes.
  static const double minSize = 48;

  const TapTarget({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      // The action MUST be declared here as well. `excludeSemantics` drops the
      // child's semantics wholesale, and a bare `GestureDetector` is where the
      // tap action lives — without this the button is announced but cannot be
      // activated by a screen reader.
      onTap: onTap,
      // The child usually holds an icon or short text that would otherwise be
      // read out after the label, duplicating it.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Marks purely decorative content so screen readers skip it.
///
/// The film-strip perforations, the score pips and the share grid carry no
/// information a screen-reader user can act on — the same facts are already
/// announced by the surrounding text.
class Decorative extends StatelessWidget {
  final Widget child;

  const Decorative({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: child);
}
