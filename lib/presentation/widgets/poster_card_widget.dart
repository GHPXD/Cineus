import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/movie.dart';

/// A stylized movie poster card with gradient overlay.
class PosterCard extends StatelessWidget {
  final Movie movie;
  final double height;

  const PosterCard({super.key, required this.movie, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Color(0xD9000000),
            blurRadius: 60,
            offset: Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Poster from bundled local assets
          Image.asset(
            'assets/posters/${movie.id}.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Stack(
              fit: StackFit.expand,
              children: [
                _gradientFallback(),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.6),
                        radius: 1.2,
                        colors: [
                          AppColors.blue300.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.5, 0.5),
                        radius: 1.0,
                        colors: [
                          AppColors.gold300.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    _movieIcon(),
                    style: TextStyle(
                      fontSize: height * 0.25,
                      shadows: const [
                        Shadow(blurRadius: 40, color: Color(0xCC000000)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom fade + info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xF005050A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      fontFamily: AppFonts.playfair,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.year} · ${movie.genres.join(", ")}',
                    style: AppTypography.mono.copyWith(
                      color: AppColors.gold300,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
            Color(0xFF1a1a2e),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  String _movieIcon() {
    final genres = movie.genres.map((g) => g.toLowerCase()).join(' ');
    if (genres.contains('ficção') || genres.contains('sci')) return '🚀';
    if (genres.contains('crime') || genres.contains('thriller')) return '🔪';
    if (genres.contains('ação') || genres.contains('action')) return '💥';
    if (genres.contains('comédia') || genres.contains('comedy')) return '😂';
    if (genres.contains('romance')) return '❤️';
    if (genres.contains('terror') || genres.contains('horror')) return '👻';
    if (genres.contains('animação') || genres.contains('animation')) {
      return '🧸';
    }
    if (genres.contains('aventura') || genres.contains('adventure')) {
      return '🗺️';
    }
    if (genres.contains('guerra') || genres.contains('war')) return '⚔️';
    if (genres.contains('documentário') || genres.contains('documentary')) {
      return '📹';
    }
    if (genres.contains('música') || genres.contains('music')) return '🎵';
    if (genres.contains('fantasia') || genres.contains('fantasy')) return '🧙';
    if (genres.contains('mistério') || genres.contains('mystery')) return '🕵️';
    if (genres.contains('família') || genres.contains('family')) {
      return '👨‍👩‍👧‍👦';
    }
    if (genres.contains('drama')) return '🎭';
    return '🎬';
  }
}
