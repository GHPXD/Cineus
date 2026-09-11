import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/movie.dart';

/// A stylized movie-poster card.
///
/// Posters are authored close to a 2:3 portrait ratio. Result screens used to
/// force them into a full-width fixed-height landscape box, cropping much of the
/// artwork exactly when the answer is revealed. The default now preserves the
/// poster ratio; [height] remains only for backwards-compatible callers.
class PosterCard extends StatelessWidget {
  final Movie movie;
  final double? height;

  const PosterCard({super.key, required this.movie, this.height});

  @override
  Widget build(BuildContext context) {
    final poster = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Color(0xB8000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/posters/${movie.id}.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Stack(
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
                Center(
                  child: Text(
                    _movieIcon(),
                    style: const TextStyle(
                      fontSize: 64,
                      shadows: [
                        Shadow(blurRadius: 40, color: Color(0xCC000000)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono.copyWith(
                      color: AppColors.gold300,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (height != null) return SizedBox(height: height, child: poster);
    return AspectRatio(aspectRatio: 2 / 3, child: poster);
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
            Color(0xFF1A1A2E),
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
    if (genres.contains('animação') || genres.contains('animation')) return '🧸';
    if (genres.contains('aventura') || genres.contains('adventure')) return '🗺️';
    if (genres.contains('guerra') || genres.contains('war')) return '⚔️';
    if (genres.contains('documentário') || genres.contains('documentary')) {
      return '📹';
    }
    if (genres.contains('música') || genres.contains('music')) return '🎵';
    if (genres.contains('fantasia') || genres.contains('fantasy')) return '🧙';
    if (genres.contains('mistério') || genres.contains('mystery')) return '🕵️';
    if (genres.contains('família') || genres.contains('family')) return '👨‍👩‍👧‍👦';
    if (genres.contains('drama')) return '🎭';
    return '🎬';
  }
}