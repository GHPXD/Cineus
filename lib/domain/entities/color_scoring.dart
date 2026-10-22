import 'dart:math' as math;
import 'color_question.dart';

/// CIELAB coordinates, using the same reference white for both samples.
class LabColor {
  final double l, a, b;
  const LabColor(this.l, this.a, this.b);

  /// sRGB -> linear light -> XYZ D65 -> Bradford D50 -> Lab D50.
  /// Matrices/whitepoints: W3C CSS Color 4, colour-conversion reference code.
  factory LabColor.fromSrgb(SrgbColor color) {
    double linear(int byte) {
      final channel = byte / 255;
      return channel <= .04045
          ? channel / 12.92
          : math.pow((channel + .055) / 1.055, 2.4).toDouble();
    }

    final r = linear(color.red),
        g = linear(color.green),
        b = linear(color.blue);
    final x =
        (506752 / 1228815) * r + (87881 / 245763) * g + (12673 / 70218) * b;
    final y =
        (87098 / 409605) * r + (175762 / 245763) * g + (12673 / 175545) * b;
    final z =
        (7918 / 409605) * r + (87881 / 737289) * g + (1001167 / 1053270) * b;
    final xd =
        1.0479297925449969 * x +
        .022946870601609652 * y -
        .05019226628920524 * z;
    final yd =
        .02962780877005599 * x +
        .9904344267538799 * y -
        .017073799063418826 * z;
    final zd =
        -.009243040646204504 * x +
        .015055191490298152 * y +
        .7518742814281371 * z;
    double f(double value) => value > 216 / 24389
        ? math.pow(value, 1 / 3).toDouble()
        : ((24389 / 27) * value + 16) / 116;
    final fx = f(xd / (.3457 / .3585));
    final fy = f(yd);
    final fz = f(zd / ((1 - .3457 - .3585) / .3585));
    return LabColor(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
  }
}

/// Independent colour rules; classic clue/poster scoring is untouched.
abstract final class ColorScoring {
  static const version = 'ciede2000-d50-linear50-v1';
  static const rounds = 5;
  static const hintPenaltyCents = 100;

  /// CIEDE2000, kL=kC=kH=1; equations verified against Sharma's 34 pairs.
  static double deltaE(LabColor first, LabColor second) {
    double square(double x) => x * x;
    double cos(double degrees) => math.cos(degrees * math.pi / 180);
    double sin(double degrees) => math.sin(degrees * math.pi / 180);
    double seventh(double x) => math.pow(x, 7).toDouble();
    double hue(double a, double b) {
      if (a == 0 && b == 0) return 0;
      final angle = math.atan2(b, a) * 180 / math.pi;
      return angle < 0 ? angle + 360 : angle;
    }

    final c1 = math.sqrt(square(first.a) + square(first.b));
    final c2 = math.sqrt(square(second.a) + square(second.b));
    final meanC7 = seventh((c1 + c2) / 2);
    final g = .5 * (1 - math.sqrt(meanC7 / (meanC7 + seventh(25))));
    final a1 = (1 + g) * first.a, a2 = (1 + g) * second.a;
    final cp1 = math.sqrt(square(a1) + square(first.b));
    final cp2 = math.sqrt(square(a2) + square(second.b));
    final h1 = hue(a1, first.b), h2 = hue(a2, second.b);
    final dl = second.l - first.l, dc = cp2 - cp1;
    final zeroChroma = cp1 * cp2 == 0;
    var dh = zeroChroma ? 0.0 : h2 - h1;
    if (dh > 180) dh -= 360;
    if (dh < -180) dh += 360;
    final dH = 2 * math.sqrt(cp1 * cp2) * sin(dh / 2);
    final meanL = (first.l + second.l) / 2, meanC = (cp1 + cp2) / 2;
    var meanH = (h1 + h2) / 2;
    if (zeroChroma) {
      meanH = h1 + h2;
    } else if ((h1 - h2).abs() > 180) {
      meanH = (h1 + h2 + (h1 + h2 < 360 ? 360 : -360)) / 2;
    }
    final t =
        1 -
        .17 * cos(meanH - 30) +
        .24 * cos(2 * meanH) +
        .32 * cos(3 * meanH + 6) -
        .20 * cos(4 * meanH - 63);
    final dTheta = 30 * math.exp(-square((meanH - 275) / 25));
    final meanCp7 = seventh(meanC);
    final rc = 2 * math.sqrt(meanCp7 / (meanCp7 + seventh(25)));
    final sl =
        1 + .015 * square(meanL - 50) / math.sqrt(20 + square(meanL - 50));
    final sc = 1 + .045 * meanC, sh = 1 + .015 * meanC * t;
    final rt = -sin(2 * dTheta) * rc;
    final l = dl / sl, c = dc / sc, h = dH / sh;
    return math.sqrt(
      math.max(0, square(l) + square(c) + square(h) + rt * c * h),
    );
  }

  /// Versioned product curve: ΔE 0/5/10/25/50 -> 10/9/8/5/0 points.
  /// Apply one hint penalty before rounding, store integral hundredths.
  static int centsFromDistance(double distance, {bool hintUsed = false}) {
    if (!distance.isFinite || distance < 0) {
      throw ArgumentError.value(distance, 'distance');
    }
    final raw = ((10 - distance / 5).clamp(0.0, 10.0) - (hintUsed ? 1 : 0))
        .clamp(0.0, 10.0);
    return (raw * 100).round();
  }

  static int roundCents(
    SrgbColor choice,
    SrgbColor target, {
    bool hintUsed = false,
  }) => centsFromDistance(
    deltaE(LabColor.fromSrgb(choice), LabColor.fromSrgb(target)),
    hintUsed: hintUsed,
  );

  static int averageCents(List<int> scores) {
    if (scores.length != rounds || scores.any((s) => s < 0 || s > 1000)) {
      throw ArgumentError('Expected five scores in [0,1000]');
    }
    return (scores.reduce((a, b) => a + b) / rounds).round();
  }
}
