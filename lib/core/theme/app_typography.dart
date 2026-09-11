import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

/// Cineus Typography System
///
/// Playfair Display → titles/branding
/// Inter → UI/body copy
/// DM Mono → scores/numbers/counters
///
/// Text tokens deliberately use the contrast-verified semantic text palette.
/// Surface colors from the obsidian ramp remain for borders/decorations only.
abstract final class AppTypography {
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: AppFonts.playfair,
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: AppColors.obsidian0,
    height: 1.1,
  );

  static TextStyle get displayMedium => const TextStyle(
    fontFamily: AppFonts.playfair,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: AppColors.obsidian0,
    height: 1.15,
  );

  static TextStyle get displaySmall => const TextStyle(
    fontFamily: AppFonts.playfair,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.obsidian0,
    height: 1.2,
  );

  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: AppFonts.playfair,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.obsidian0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: AppFonts.playfair,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.obsidian0,
    height: 1.3,
  );

  static TextStyle get titleLarge => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.obsidian0,
    height: 1.3,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.obsidian0,
    height: 1.4,
  );

  static TextStyle get titleSmall => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.obsidian0,
    height: 1.4,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.obsidian100,
    height: 1.6,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.obsidian100,
    height: 1.6,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static TextStyle get labelLarge => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.obsidian0,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 1.5,
  );

  static TextStyle get overline => const TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AppColors.textTertiary,
    height: 1.2,
    letterSpacing: 2,
  );

  static TextStyle get scoreLarge => const TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 64,
    fontWeight: FontWeight.w500,
    color: AppColors.gold200,
    height: 1,
    letterSpacing: -3,
  );

  static TextStyle get scoreMedium => const TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 48,
    fontWeight: FontWeight.w500,
    color: AppColors.gold200,
    height: 1,
    letterSpacing: -2,
  );

  static TextStyle get scoreSmall => const TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: AppColors.obsidian0,
    height: 1,
    letterSpacing: -1,
  );

  static TextStyle get mono => const TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get monoSmall => const TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
}