import 'package:flutter/widgets.dart';

import '../domain/entities/extra_hint.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/ticket_reward.dart';
import '../l10n/app_l10n.dart';

/// Bridges domain identifiers to localised copy.
///
/// The domain deliberately carries ids and enums rather than text, so the wording
/// lives here — one place to look when a string reads wrong in some language.
extension DomainL10n on AppL10n {
  String achievementTitle(String id) => switch (id) {
        'first_win' => achFirstWin,
        'perfect' => achPerfect,
        'streak_7' => achStreak7,
        'streak_30' => achStreak30,
        'games_50' => achGames50,
        'stages_5' => achStages5,
        'tickets_100' => achTickets100,
        _ => id,
      };

  String achievementDescription(String id) => switch (id) {
        'first_win' => achFirstWinDesc,
        'perfect' => achPerfectDesc,
        'streak_7' => achStreak7Desc,
        'streak_30' => achStreak30Desc,
        'games_50' => achGames50Desc,
        'stages_5' => achStages5Desc,
        'tickets_100' => achTickets100Desc,
        _ => '',
      };

  String hintLabel(ExtraHint hint) => switch (hint) {
        ExtraHint.director => hintDirector,
        ExtraHint.year => hintYear,
        ExtraHint.runtime => hintRuntime,
      };

  String rewardReason(TicketReward reward) => switch (reward.kind) {
        RewardKind.dailyWin => rewardDailyWin,
        RewardKind.streakMilestone => rewardStreak(reward.value ?? 0),
        RewardKind.stageComplete => rewardStageComplete(reward.value ?? 0),
      };

  String modeName(GameMode mode) =>
      mode == GameMode.clue ? modeClues : modePoster;
}

/// Lets widgets write `context.l10n.something` instead of the longer
/// `AppL10n.of(context)`.
extension L10nContext on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}
