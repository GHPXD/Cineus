import 'dart:ui';

abstract final class OrientationPolicy {
  /// Phones keep the focused portrait game experience. Tablet-sized windows are
  /// left unrestricted so iPad, Android large screens and desktop-like windows
  /// can use the responsive layouts introduced in Phase 6.
  static bool lockPortrait(Size logicalSize) => logicalSize.shortestSide < 600;
}
