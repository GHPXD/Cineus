import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';
import '../l10n_mappers.dart';
import '../widgets/film_strip_widget.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration minimumDuration;

  const SplashScreen({
    super.key,
    required this.onComplete,
    this.minimumDuration = AppConstants.splashDuration,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _completionTimer;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _completionTimer = Timer(widget.minimumDuration, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: MediaQuery.of(context).size.width / 2 - 180,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold500.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue500.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: FilmStrip()),
            ),
            const Positioned(bottom: 32, left: 0, right: 0, child: FilmStrip()),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1a1a2e),
                              Color(0xFF16213e),
                              Color(0xFF0f2040),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.gold300.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold300.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('🎬', style: TextStyle(fontSize: 46)),
                      ),
                      const SizedBox(height: 28),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Cine',
                              style: TextStyle(
                                fontFamily: AppFonts.playfair,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'us',
                              style: TextStyle(
                                fontFamily: AppFonts.playfair,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [
                                      AppColors.gold500,
                                      AppColors.gold300,
                                      AppColors.gold200,
                                    ],
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 80, 50),
                                  ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppL10n.of(context).appTagline,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fade,
                child: Text(
                  context.l10n.splashCredits,
                  textAlign: TextAlign.center,
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
