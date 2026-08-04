import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/clue.dart';
import 'clue_card_widget.dart';
import '../../l10n/app_l10n.dart';

/// Animated list of clue cards with fade-in transitions for newly revealed clues.
class ClueList extends StatelessWidget {
  final List<Clue> allClues;
  final int revealedCount;

  const ClueList({
    super.key,
    required this.allClues,
    required this.revealedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(AppConstants.totalClues, (index) {
        final clueNumber = index + 1;

        final isRevealed = clueNumber <= revealedCount;
        final isLatest = clueNumber == revealedCount && revealedCount > 1;
        final isNext = clueNumber == revealedCount + 1;

        // Find the matching clue data
        final clue = allClues.where((c) => c.clueNumber == clueNumber).firstOrNull;
        final category =
            clue?.category ?? AppL10n.of(context).clueFallback(clueNumber);

        final cardState = isRevealed
            ? ClueCardState.revealed
            : isNext
                ? ClueCardState.next
                : ClueCardState.locked;

        final card = ClueCard(
          clue: clue,
          clueNumber: clueNumber,
          category: category,
          cardState: cardState,
          isLatest: isLatest,
        );

        // Animate latest revealed clue
        if (isLatest) {
          return _RevealAnimation(
            key: ValueKey('clue-reveal-$clueNumber'),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: card,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: card,
        );
      }),
    );
  }
}

class _RevealAnimation extends StatefulWidget {
  final Widget child;

  const _RevealAnimation({super.key, required this.child});

  @override
  State<_RevealAnimation> createState() => _RevealAnimationState();
}

class _RevealAnimationState extends State<_RevealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
