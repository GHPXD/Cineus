import 'game_session.dart';

/// Scoring and progression rules for one game mode.
///
/// These numbers used to be inlined at every site that needed them — `11 -
/// revealedClues` in the entity, `6 - revealLevel` in the poster notifier,
/// `revealedClues < 10` and `revealLevel >= 5` as loss conditions — while
/// `AppConstants.totalClues` and `visualLevels` sat unused next to them. A
/// single definition per mode keeps the entity, the notifier and the UI from
/// drifting apart.
class ScoringRules {
  /// How many reveal steps exist (clues, or blur levels).
  final int totalSteps;

  /// Points awarded for guessing right on the very first step.
  final int maxScore;

  const ScoringRules({required this.totalSteps, required this.maxScore});

  /// 10 progressive clues, worth 10 points down to 1.
  static const clue = ScoringRules(totalSteps: 10, maxScore: 10);

  /// 5 blur levels, worth 5 points down to 1.
  static const poster = ScoringRules(totalSteps: 5, maxScore: 5);

  static ScoringRules forMode(GameMode mode) =>
      mode == GameMode.clue ? clue : poster;

  /// Points for guessing correctly at [step] (1-based).
  int scoreAt(int step) => maxScore + 1 - step.clamp(1, totalSteps);

  /// Whether another step can still be revealed from [step].
  bool canRevealMore(int step) => step < totalSteps;

  /// Whether [step] is the final one — a wrong guess here loses the game.
  bool isLastStep(int step) => step >= totalSteps;
}
