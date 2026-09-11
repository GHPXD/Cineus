import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/utils/orientation_policy.dart';

void main() {
  test('telefone mantém portrait', () {
    expect(
      OrientationPolicy.lockPortrait(const Size(390, 844)),
      isTrue,
    );
  });

  test('tablet libera rotação', () {
    expect(
      OrientationPolicy.lockPortrait(const Size(800, 1280)),
      isFalse,
    );
    expect(
      OrientationPolicy.lockPortrait(const Size(1024, 768)),
      isFalse,
    );
  });

  test('breakpoint de 600dp já é tratado como tela grande', () {
    expect(
      OrientationPolicy.lockPortrait(const Size(600, 960)),
      isFalse,
    );
  });
}
