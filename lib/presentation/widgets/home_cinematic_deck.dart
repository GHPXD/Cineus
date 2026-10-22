import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

/// Presentation-only destinations. Film rules keep their existing GameMode.
class HomeDailyCardData {
  final String id, title, description, action;
  final String? status;
  final CineusAssetId icon;
  final VoidCallback? onOpen;
  final bool loading, failed, opening;
  const HomeDailyCardData({
    required this.id,
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
    required this.onOpen,
    this.status,
    this.loading = false,
    this.failed = false,
    this.opening = false,
  });
  String get artwork => 'assets/home/$id.png';
  String get actionKey => id == 'colors'
      ? 'home-colors-daily'
      : 'daily-${id == 'clues' ? 'clue' : 'poster'}';
}

class HomeCinematicDeck extends StatefulWidget {
  final List<HomeDailyCardData> cards;
  final Widget heading, countdown;
  const HomeCinematicDeck({
    super.key,
    required this.cards,
    required this.heading,
    required this.countdown,
  });
  @override
  State<HomeCinematicDeck> createState() => _HomeCinematicDeckState();
}

class _HomeCinematicDeckState extends State<HomeCinematicDeck> {
  final _pages = PageController(initialPage: 1, viewportFraction: .62);
  int _selected = 1;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (!_pages.hasClients) return;
    _pages.animateToPage(
      index,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(14) > 17;
      return Column(
        children: [
          Container(
            key: const ValueKey('home-daily-showcase'),
            decoration: BoxDecoration(
              color: const Color(0xFF050B12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold500.withValues(alpha: .55),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: widget.heading,
                ),
                if (stacked)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < widget.cards.length;
                          index++
                        ) ...[
                          HomeCinematicCard(
                            data: widget.cards[index],
                            selected: true,
                            expanded: true,
                          ),
                          if (index != widget.cards.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: constraints.maxWidth >= 560 ? 360 : 310,
                    child: PageView.builder(
                      key: const ValueKey('home-mode-carousel'),
                      controller: _pages,
                      allowImplicitScrolling: true,
                      itemCount: widget.cards.length,
                      onPageChanged: (index) =>
                          setState(() => _selected = index),
                      itemBuilder: (context, index) {
                        final selected = index == _selected;
                        return AnimatedScale(
                          scale: selected ? 1 : .9,
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          child: Transform.rotate(
                            angle: selected
                                ? 0
                                : (index < _selected ? .065 : -.065),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 12,
                              ),
                              child: Semantics(
                                label: selected
                                    ? null
                                    : widget.cards[index].title,
                                button: !selected,
                                onTap: selected ? null : () => _select(index),
                                excludeSemantics: !selected,
                                child: GestureDetector(
                                  onTap: selected ? null : () => _select(index),
                                  child: IgnorePointer(
                                    ignoring: !selected,
                                    child: HomeCinematicCard(
                                      data: widget.cards[index],
                                      selected: selected,
                                      expanded: false,
                                      peekOnLeft: index < _selected,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HomeChromePanel(
            padding: 0,
            radius: 28,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(child: widget.countdown),
                if (!stacked) ...[
                  const SizedBox(width: 4),
                  for (var index = 0; index < widget.cards.length; index++)
                    Semantics(
                      button: true,
                      selected: _selected == index,
                      label: widget.cards[index].title,
                      excludeSemantics: true,
                      onTap: () => _select(index),
                      child: InkWell(
                        key: ValueKey('home-select-${widget.cards[index].id}'),
                        onTap: () => _select(index),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _selected
                                    ? AppColors.gold300
                                    : AppColors.obsidian600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

class HomeCinematicCard extends StatelessWidget {
  final HomeDailyCardData data;
  final bool selected, expanded;
  final bool peekOnLeft;
  const HomeCinematicCard({
    super.key,
    required this.data,
    required this.selected,
    required this.expanded,
    this.peekOnLeft = false,
  });
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final gold = selected ? AppColors.gold300 : const Color(0xFF315676);
    final caption = data.loading
        ? l.loadingGame
        : data.failed
        ? l.homeChallengeUnavailable
        : data.status;
    final title = Text(
      data.title,
      style: AppTypography.displaySmall.copyWith(fontSize: 31, height: 1.12),
    );
    final description = Text(
      data.description,
      maxLines: expanded ? null : 5,
      overflow: expanded ? TextOverflow.clip : TextOverflow.ellipsis,
      style: AppTypography.bodySmall.copyWith(
        fontSize: expanded ? 14 : 12,
        color: const Color(0xFFB5C9EE),
        height: 1.4,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.id != 'colors') ...[
          CineusIcon(data.icon, size: 34),
          const SizedBox(height: 6),
        ],
        title,
        const SizedBox(height: 6),
        description,
        if (caption != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              caption,
              style: AppTypography.bodySmall.copyWith(
                fontSize: expanded ? 13 : 10,
                color: AppColors.gold200,
              ),
            ),
          ),
        ],
      ],
    );
    final button = selected
        ? SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ValueKey(data.actionKey),
              onPressed: data.loading || data.opening ? null : data.onOpen,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                minimumSize: const Size(48, 48),
                backgroundColor: AppColors.gold300,
                foregroundColor: const Color(0xFF060A10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Color(0xFFFFE99A)),
                ),
              ),
              child: data.opening || data.loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            data.action,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: expanded ? 15 : 13,
                              color: const Color(0xFF060A10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const CineusIcon(
                          CineusAssetId.homeForward,
                          size: 19,
                          color: Color(0xFF060A10),
                        ),
                      ],
                    ),
            ),
          )
        : Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold300, width: 1.2),
              ),
              child: const Center(
                child: CineusIcon(CineusAssetId.homeForward, size: 25),
              ),
            ),
          );
    final body = !selected
        ? Align(
            alignment: peekOnLeft
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  CineusIcon(data.icon, size: 32),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.title,
                      maxLines: 1,
                      style: AppTypography.displaySmall.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 16),
                  button,
                ],
              ),
            ),
          )
        : Column(
            mainAxisSize: expanded ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (expanded) const SizedBox(height: 72),
              if (expanded)
                copy
              else
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: copy),
                        if (data.id == 'colors') ...[
                          const SizedBox(width: 8),
                          const _Palette(),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              button,
            ],
          );
    return Container(
      key: ValueKey('home-${data.id}-card'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: gold, width: selected ? 1.4 : 1),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: gold.withValues(alpha: .24),
                  blurRadius: 13,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Image.asset(
                  data.artwork,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x16040910),
                      Color(0x50040910),
                      Color(0xF9040910),
                    ],
                    stops: [0, .35, 1],
                  ),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(selected ? 12 : 4), child: body),
          ],
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in const [
          Color(0xFF9F1925),
          Color(0xFF11687A),
          Color(0xFFDA991E),
          Color(0xFFFFE6AF),
          Color(0xFF203E65),
        ])
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFEEE2C8), width: .7),
            ),
          ),
      ],
    ),
  );
}

class HomeChromePanel extends StatelessWidget {
  final Widget child;
  final double padding, radius;
  final bool gold;
  const HomeChromePanel({
    super.key,
    required this.child,
    this.padding = 12,
    this.radius = 16,
    this.gold = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF07111D), Color(0xFF050A11)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: gold
            ? AppColors.gold500.withValues(alpha: .45)
            : const Color(0xFF23364D),
      ),
    ),
    child: child,
  );
}
