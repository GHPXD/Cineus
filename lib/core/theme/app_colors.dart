import 'package:flutter/material.dart';

/// Cineus Design Tokens — Classic Cinema × Modern Tech
abstract final class AppColors {
  // ── Obsidian (Dark Noir Base) ──
  static const obsidian950 = Color(0xFF05050A);
  static const obsidian900 = Color(0xFF0A0A12);
  static const obsidian800 = Color(0xFF101019);
  static const obsidian700 = Color(0xFF16161F);
  static const obsidian600 = Color(0xFF1E1E2A);
  static const obsidian500 = Color(0xFF2C2C3A);
  static const obsidian400 = Color(0xFF424256);
  static const obsidian300 = Color(0xFF64647A);
  static const obsidian200 = Color(0xFF9898B0);
  static const obsidian100 = Color(0xFFC8C8DC);
  static const obsidian50  = Color(0xFFEAEAF2);
  static const obsidian0   = Color(0xFFFFFFFF);

  // ── Text tones (contrast-verified) ──
  //
  // The obsidian ramp was designed for surfaces, and reusing its dim end for
  // copy failed WCAG: obsidian400 measured 1.84–2.08:1 against the app's
  // backgrounds and obsidian500 as low as 1.31:1 — below even the 3:1 floor for
  // large text. obsidian300 reached only 3.12–3.53:1, so it passed for large
  // text but not for body copy.
  //
  // These three are for TEXT and meaningful icons. Borders, dividers and
  // decoration keep using the obsidian ramp, where contrast rules do not apply.
  //
  // Worst case is against obsidian700, the lightest surface in use.

  /// Primary secondary-text tone. 5.24:1 worst case — passes AA for body copy.
  static const textSecondary = Color(0xFF8888A6);

  /// Dimmer supporting text. 4.69:1 worst case — still passes AA.
  static const textTertiary = Color(0xFF80809C);

  /// Lowest-emphasis text (captions, disabled). 3.32:1 worst case: AA for large
  /// text only, so keep it off small body copy.
  static const textQuaternary = Color(0xFF68687F);

  // ── Deep Gold (Score & Rewards) ──
  static const gold900 = Color(0xFF2A1900);
  static const gold800 = Color(0xFF4A2E00);
  static const gold700 = Color(0xFF6B4400);
  static const gold600 = Color(0xFF8C5E00);
  static const gold500 = Color(0xFFB87C00);
  static const gold400 = Color(0xFFD49810);
  static const gold300 = Color(0xFFE8B429);
  static const gold200 = Color(0xFFF5D06B);
  static const gold100 = Color(0xFFFAE8A8);
  static const gold50  = Color(0xFFFDF6DC);

  // ── Electric Blue (Info & Clues) ──
  static const blue900 = Color(0xFF000820);
  static const blue800 = Color(0xFF001040);
  static const blue700 = Color(0xFF001E66);
  static const blue600 = Color(0xFF003399);
  static const blue500 = Color(0xFF0050CC);
  static const blue400 = Color(0xFF2B70F0);
  static const blue300 = Color(0xFF5A94FF);
  static const blue200 = Color(0xFF90B8FF);
  static const blue100 = Color(0xFFC8DAFF);

  // ── Ruby Red (Urgency & Last Chances) ──
  static const ruby900 = Color(0xFF1F000E);
  static const ruby800 = Color(0xFF40001F);
  static const ruby700 = Color(0xFF660033);
  static const ruby600 = Color(0xFF8C004A);
  static const ruby500 = Color(0xFFB30060);
  static const ruby400 = Color(0xFFD41A72);
  static const ruby300 = Color(0xFFF04080);
  static const ruby200 = Color(0xFFFF85AD);
  static const ruby100 = Color(0xFFFFBED5);

  // ── Success ──
  static const success500 = Color(0xFF00B878);
  static const success400 = Color(0xFF00D48E);
  static const success300 = Color(0xFF33E0A8);
  static const success100 = Color(0xFFB3F5E4);

  // ── Amber ──
  static const amber400 = Color(0xFFF59D20);
  static const amber300 = Color(0xFFFBBA47);

  // ── Gradients ──
  static const goldGradient = LinearGradient(
    colors: [gold500, gold300, gold200],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const blueGradient = LinearGradient(
    colors: [blue500, blue300],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const rubyGradient = LinearGradient(
    colors: [ruby600, ruby300],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const heroGradient = LinearGradient(
    colors: [obsidian950, Color(0xFF0D0B18), Color(0xFF080910), obsidian950],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFF14141E), Color(0xFF0F0F18)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldDimGradient = LinearGradient(
    colors: [Color(0x38B87C00), Color(0x14E8B429)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const blueDimGradient = LinearGradient(
    colors: [Color(0x380050CC), Color(0x145A94FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const rubyDimGradient = LinearGradient(
    colors: [Color(0x478C004A), Color(0x14F04080)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const amberDimGradient = LinearGradient(
    colors: [Color(0x38F59D20), Color(0x14FBBA47)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the score color tier based on current score.
  static Color scoreColor(int score) {
    if (score >= 8) return gold300;
    if (score >= 5) return blue300;
    if (score >= 3) return amber400;
    return ruby300;
  }

  /// Returns the gradient for a given score tier.
  static LinearGradient scoreDimGradient(int score) {
    if (score >= 8) return goldDimGradient;
    if (score >= 5) return blueDimGradient;
    if (score >= 3) return amberDimGradient;
    return rubyDimGradient;
  }

  static LinearGradient scoreGradient(int score) {
    if (score >= 8) return goldGradient;
    if (score >= 5) return blueGradient;
    if (score >= 3) {
      return const LinearGradient(colors: [amber400, amber300]);
    }
    return rubyGradient;
  }

  static Color scoreBorderColor(int score) {
    if (score >= 8) return gold300.withValues(alpha: 0.35);
    if (score >= 5) return blue300.withValues(alpha: 0.35);
    if (score >= 3) return amber400.withValues(alpha: 0.4);
    return ruby300.withValues(alpha: 0.45);
  }
}
