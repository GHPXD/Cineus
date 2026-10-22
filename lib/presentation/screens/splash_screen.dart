import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/cineus_brand.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';
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
      duration: const Duration(milliseconds: 680),
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
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final progress = Curves.easeOutCubic.transform(_ctrl.value);
            final reveal = Curves.easeOut.transform(
              (_ctrl.value / .55).clamp(0, 1),
            );
            return Stack(
              key: const ValueKey('splash-cinematic-scene'),
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -.18),
                          radius: .82,
                          colors: [
                            AppColors.gold500.withValues(alpha: .09 * reveal),
                            AppColors.blue300.withValues(alpha: .04 * reveal),
                            AppColors.obsidian950,
                          ],
                          stops: const [0, .42, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: -24 + progress * 24,
                  right: -24,
                  child: Opacity(
                    opacity: .35 + .65 * reveal,
                    child: const FilmStrip(),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: -24,
                  right: -24 + progress * 24,
                  child: Opacity(
                    opacity: .35 + .65 * reveal,
                    child: const FilmStrip(),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _fade,
                          child: ScaleTransition(
                            scale: _scale,
                            child: Transform.rotate(
                              angle: -.16 * (1 - progress),
                              child: Container(
                                key: const ValueKey('splash-animated-logo'),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gold300.withValues(
                                        alpha: .12 * reveal,
                                      ),
                                      blurRadius: 42,
                                      spreadRadius: 6 * progress,
                                    ),
                                  ],
                                ),
                                child: SvgPicture.asset(
                                  'assets/generated/icons/platformMark.svg',
                                  width: 138,
                                  height: 138,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Opacity(
                          opacity: ((_ctrl.value - .12) / .62).clamp(0, 1),
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - progress)),
                            child: const CineusWordmark(fontSize: 48),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: ((_ctrl.value - .23) / .65).clamp(0, 1),
                          child: Column(
                            children: [
                              Text(
                                AppL10n.of(context).splashWelcome,
                                textAlign: TextAlign.center,
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.gold300,
                                  letterSpacing: .7,
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
