// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get colorModeTitle => 'Colors';

  @override
  String colorRecallPart(String part) {
    return 'Remember the color: $part';
  }

  @override
  String get colorYourTone => 'Your shade';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Saturation';

  @override
  String get colorBrightness => 'Brightness';

  @override
  String get colorRulesAction => 'How it works';

  @override
  String get colorRulesTitle => 'Five colors. One memory.';

  @override
  String get colorCatalogFailed => 'Could not load the questions.';

  @override
  String get colorRetry => 'Try again';

  @override
  String get colorClose => 'Got it';

  @override
  String get appTitle => 'Cineus';

  @override
  String shareWin(
    Object challenge,
    int clue,
    int total,
    int score,
    Object grid,
  ) {
    return '🎬 Cineus #$challenge\nGot it on clue $clue/$total · ${score}pts\n\n$grid';
  }

  @override
  String get semBack => 'Back';

  @override
  String get semStats => 'View statistics';

  @override
  String get semHelp => 'How to play';

  @override
  String semTicketBalance(int count) {
    return '$count tickets available';
  }

  @override
  String get reminderTitle => 'Cineus';

  @override
  String get reminderBody =>
      'Today\'s challenge is live. How many clues will you need?';

  @override
  String get reminderSettingTitle => 'Daily reminder';

  @override
  String get reminderSettingSubtitle => 'One nudge at 9am, your time';

  @override
  String get reminderDenied =>
      'Notifications are blocked. Allow them in system settings to turn this on.';

  @override
  String get reminderFailed =>
      'Could not update the reminder. Please try again.';

  @override
  String get fontLicensesTitle => 'Font licenses';

  @override
  String get fontLicenseFailed =>
      'Could not open the license. Please try again.';

  @override
  String get rewardFailed =>
      'Could not add the reward right now. Your result is saved.';

  @override
  String get challengeSectionTitle => 'Challenge a friend';

  @override
  String get challengeShareButton => 'Challenge a friend';

  @override
  String challengeShareText(Object code, Object link) {
    return '🎬 Cineus: bet you can\'t get this film.\nCode: $code\n$link';
  }

  @override
  String get challengeOpenTitle => 'Open a challenge';

  @override
  String get challengeCodeHint => 'CIN-0000';

  @override
  String get challengeOpen => 'Open';

  @override
  String get challengeInvalid =>
      'Invalid code. Check the characters and try again.';

  @override
  String get challengeBadge => 'FRIEND\'S CHALLENGE';

  @override
  String get challengeFilmNotFound =>
      'That challenge points at a film this version of the app does not have.';

  @override
  String get appTagline =>
      'Guess movies from clues or posters.\nRecall colors and advance through stages.';

  @override
  String get navHome => 'Home';

  @override
  String get navFilms => 'Films';

  @override
  String get navPosters => 'Posters';

  @override
  String get back => 'Back';

  @override
  String get backHome => 'Back to Home';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get movieNotFound => 'Film not found';

  @override
  String get noMoviesInDatabase => 'No films in the database';

  @override
  String get gameLoadFailed => 'The game could not be loaded.';

  @override
  String get loadingGame => 'Loading game…';

  @override
  String get retryAction => 'Try again';

  @override
  String get statsLoadFailed => 'Your statistics could not be loaded.';

  @override
  String get stageNotFound =>
      'This stage does not exist or is no longer available.';

  @override
  String get backToStages => 'Back to Stages';

  @override
  String get dailyChallengeLabel => 'DAILY CHALLENGE';

  @override
  String get modeClues => 'Clues';

  @override
  String get modePoster => 'Poster';

  @override
  String get dailyDone => 'Today\'s challenge is done!';

  @override
  String nextChallengeCountdown(Object hours, Object minutes, Object seconds) {
    return 'Next in ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String get statPlayed => 'Played';

  @override
  String get statWins => 'Wins';

  @override
  String get quickActionStatsSub => 'Your history';

  @override
  String get homeOpenChallenge => 'Open challenge';

  @override
  String get homeOpenChallengeSub => 'By code or link';

  @override
  String get cluesHeader => 'CLUES';

  @override
  String cluesRevealed(int count, int total) {
    return '$count / $total revealed';
  }

  @override
  String clueFallback(int number) {
    return 'Clue $number';
  }

  @override
  String get clueNew => 'NEW';

  @override
  String get lastAttempt => 'Last attempt!';

  @override
  String skipToClue(int next) {
    return 'Skip · see clue $next (−1 pt)';
  }

  @override
  String get youGotIt => 'You got it!';

  @override
  String get notThisTime => 'Not this time.';

  @override
  String scoreLine(int score) {
    return 'Score: $score pts';
  }

  @override
  String get tryAgainTomorrow => 'Try again tomorrow.';

  @override
  String get seeResult => 'See Result';

  @override
  String stageNumber(Object id) {
    return 'Stage $id';
  }

  @override
  String get franchiseHint => 'Close! Right franchise, wrong film!';

  @override
  String get scorePoints => 'POINTS';

  @override
  String get scoreAvailable => 'available';

  @override
  String get whichMovie => 'Which film is it?';

  @override
  String get movieNameHint => 'Film title...';

  @override
  String get attemptsHeader => 'ATTEMPTS';

  @override
  String errorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count misses',
      one: '1 miss',
    );
    return '$_temp0';
  }

  @override
  String searchChallenge(Object number) {
    return 'Challenge #$number · ';
  }

  @override
  String searchStage(int id) {
    return 'Stage $id · ';
  }

  @override
  String get searchFriendChallenge => 'Friend challenge · ';

  @override
  String searchPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points',
      one: '1 point',
    );
    return ' · $_temp0';
  }

  @override
  String get searchAvailableSuffix => ' available';

  @override
  String get searchTypeHint => 'Type at least 2 letters to search.';

  @override
  String get searchNoResults => 'No films found.';

  @override
  String get searchFailed => 'Search is unavailable right now.';

  @override
  String get blurLabel => 'Blur ';

  @override
  String get share => 'Share';

  @override
  String get resultShared => 'Result shared!';

  @override
  String get resultCopied => 'Result copied!';

  @override
  String get noTicketsForNext => 'No tickets for the next one';

  @override
  String get nextChallengeIn => 'NEXT CHALLENGE IN';

  @override
  String get stagesSubtitleClues =>
      'Advance through stages and unlock new movies.';

  @override
  String get stagesSubtitlePosters => 'Guess movies from blurred posters.';

  @override
  String get locked => 'Locked';

  @override
  String filmsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count films',
      one: '1 film',
      zero: '0 films',
    );
    return '$_temp0';
  }

  @override
  String stageSemanticsProgress(Object name, int done, int total) {
    return '$name, $done of $total done';
  }

  @override
  String get filmsDone => 'films done';

  @override
  String get postersDone => 'posters done';

  @override
  String stageProgressLine(int done, int total, Object label) {
    return '$done / $total $label';
  }

  @override
  String get itemFilm => 'Film';

  @override
  String get itemPoster => 'Poster';

  @override
  String get slotNotStarted => 'Not started';

  @override
  String get slotMissedRetry => 'Missed';

  @override
  String get slotInProgress => 'In progress';

  @override
  String slotPoints(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '1 point',
      zero: '0 points',
    );
    return '$_temp0';
  }

  @override
  String get actionContinue => 'Continue';

  @override
  String get noTicketsShort => 'No tickets';

  @override
  String get revealMore => 'Reveal more · −1 pt';

  @override
  String worthPoints(int points) {
    return 'Worth $points pts';
  }

  @override
  String gotItAtLevel(int level) {
    return 'Got it at level $level!';
  }

  @override
  String get betterLuckTomorrow => 'Better luck tomorrow';

  @override
  String blurAndPoints(Object blur, int points) {
    return 'Blur $blur · $points pts';
  }

  @override
  String get youRecognized => 'You recognised it!';

  @override
  String get didntRecognize => 'Didn\'t recognise it';

  @override
  String itWas(Object title) {
    return 'It was: $title';
  }

  @override
  String pointsPlain(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '1 point',
      zero: '0 points',
    );
    return '$_temp0';
  }

  @override
  String get youDidntGuess => 'You didn\'t guess it';

  @override
  String get nextWithTicket => 'Next · 1 ticket';

  @override
  String get finish => 'Finish';

  @override
  String get hintDirector => 'Director';

  @override
  String get hintYear => 'Year';

  @override
  String get hintRuntime => 'Runtime';

  @override
  String get unknownDirector => 'Unknown';

  @override
  String runtimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get oneTicket => '1 ticket';

  @override
  String get noTicketsLower => 'no tickets';

  @override
  String get noTicketsForHint => 'Not enough tickets to buy a hint';

  @override
  String buyHintSemantics(Object label, int cost) {
    return 'Buy the $label hint for $cost ticket';
  }

  @override
  String ticketsEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count tickets!',
      one: '+1 ticket!',
    );
    return '$_temp0';
  }

  @override
  String get rewardDailyWin => 'Daily challenge completed';

  @override
  String rewardStreak(int days) {
    return '$days-day streak';
  }

  @override
  String rewardStageComplete(int id) {
    return 'Stage $id complete';
  }

  @override
  String get streakAtRisk => 'Your streak is at risk';

  @override
  String streakRecoverBody(Object day, int cost) {
    return 'You missed $day. Use $cost tickets to protect that day and keep your streak.';
  }

  @override
  String protectStreak(int cost) {
    return 'Protect streak · $cost tickets';
  }

  @override
  String get protecting => 'Protecting…';

  @override
  String needTickets(int cost) {
    return 'You need $cost tickets';
  }

  @override
  String get streakProtected => 'Streak protected!';

  @override
  String get statGames => 'GAMES';

  @override
  String get statWinsCaps => 'WINS';

  @override
  String get statRate => 'RATE';

  @override
  String get statAverage => 'AVERAGE';

  @override
  String get statAverageSub => 'clues';

  @override
  String get statAveragePosterSub => 'levels';

  @override
  String get currentStreakTitle => 'Current Streak';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'Best';

  @override
  String get playToSeeDistribution => 'Play to see the distribution';

  @override
  String get pointsDistribution => 'POINTS DISTRIBUTION';

  @override
  String get achievementsHeader => 'ACHIEVEMENTS';

  @override
  String get yourProfileHeader => 'YOUR PROFILE';

  @override
  String profileSummary(Object best, int bestPct, Object worst, int worstPct) {
    return 'You do best in $best ($bestPct%) and worst in $worst ($worstPct%).';
  }

  @override
  String get byGenre => 'By genre';

  @override
  String get byDecade => 'By decade';

  @override
  String get recentGamesHeader => 'RECENT GAMES';

  @override
  String get unknownMovie => 'Unknown film';

  @override
  String cluesUsedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clues',
      one: '1 clue',
      zero: '0 clues',
    );
    return '$_temp0';
  }

  @override
  String get defeatShort => 'Loss';

  @override
  String bucketSemantics(Object label, int pct, int played) {
    return '$label: $pct percent win rate over $played games';
  }

  @override
  String bucketValue(int pct, int played) {
    return '$pct% · $played';
  }

  @override
  String get achievementUnlocked => 'Unlocked';

  @override
  String achievementInProgress(Object progress) {
    return 'In progress $progress';
  }

  @override
  String get achFirstWin => 'First win';

  @override
  String get achFirstWinDesc => 'Win your first daily challenge.';

  @override
  String get achPerfect => 'Never flinched';

  @override
  String get achPerfectDesc => 'Guess on the first clue, worth 10 points.';

  @override
  String get achStreak7 => 'Full week';

  @override
  String get achStreak7Desc => '7 days in a row.';

  @override
  String get achStreak30 => 'Perfect month';

  @override
  String get achStreak30Desc => '30 days in a row.';

  @override
  String get achGames50 => 'Regular';

  @override
  String get achGames50Desc => 'Play 50 daily challenges.';

  @override
  String get achStages5 => 'Marathoner';

  @override
  String get achStages5Desc => 'Complete 5 stages.';

  @override
  String get achTickets100 => 'Box office';

  @override
  String get achTickets100Desc => 'Earn 100 tickets by playing.';

  @override
  String get quickGuide => 'QUICK GUIDE';

  @override
  String get gotItLetsPlay => 'Got it, let\'s play!';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get contentLanguageNote =>
      'Clues and film titles come from the Portuguese catalogue.';

  @override
  String get rewardedTitle => 'Earn tickets';

  @override
  String rewardedBody(int amount, int remaining) {
    return 'Watch an optional ad and earn $amount tickets. $remaining rewards left today.';
  }

  @override
  String rewardedAction(int amount) {
    return 'Watch and earn +$amount tickets';
  }

  @override
  String get rewardedDone => 'Tickets added!';

  @override
  String get passTitle => 'Cineus Pass';

  @override
  String get passBody =>
      'All gameplay stays free. Pass removes non-optional ads and may include convenience benefits.';

  @override
  String get passActive => 'Pass active · no non-optional ads';

  @override
  String passGet(String price) {
    return 'Get Pass $price';
  }

  @override
  String get passRestore => 'Restore purchase';

  @override
  String tickets(int current, int max) {
    return '$current/$max';
  }

  @override
  String get homeTitle => 'Cinema, every day.';

  @override
  String get dailyFree => 'FREE';

  @override
  String dailyWinPoints(int score) {
    return '$score points · Correct';
  }

  @override
  String get dailyLost => 'Finished · Not this time';

  @override
  String get dailyPlaying => 'Game in progress';

  @override
  String ticketBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
      zero: '0 tickets',
    );
    return '$_temp0';
  }

  @override
  String get ticketDetailsTitle => 'Your tickets';

  @override
  String get ticketDaily => 'Daily';

  @override
  String get ticketBonus => 'Bonus';

  @override
  String ticketDailyDetail(int count, int max) {
    return '$count of $max';
  }

  @override
  String get ticketResetInfo =>
      'Daily tickets refill at midnight UTC. Bonus tickets stay with you.';

  @override
  String get ticketUsageInfo =>
      'Daily and friend challenges are free. Starting or replaying a stage movie and each extra hint cost 1 ticket.';

  @override
  String get ticketBalanceFailed => 'Your balance could not be loaded.';

  @override
  String ticketResetCountdown(Object hours, Object minutes) {
    return 'Refill in ${hours}h ${minutes}m';
  }

  @override
  String get confirmGuess => 'Confirm guess';

  @override
  String get selectedMovieLabel => 'Selected film';

  @override
  String selectMovieSemantics(Object title, int year) {
    return 'Select $title, $year';
  }

  @override
  String get guessSaveFailed => 'Could not save your guess. Please try again.';

  @override
  String get savingGuess => 'Saving guess…';

  @override
  String get gameActionFailed => 'Could not save the action. Please try again.';

  @override
  String get hintSaveFailed =>
      'Could not complete the hint purchase. Check your balance and try again.';

  @override
  String get wrongGuessRevealed =>
      'Incorrect guess. A new step has been revealed.';

  @override
  String clueRevealedAnnouncement(int number) {
    return 'Clue $number revealed.';
  }

  @override
  String posterRevealedAnnouncement(int number) {
    return 'Level $number revealed.';
  }

  @override
  String lastGuessLabel(Object title) {
    return 'Last guess: $title';
  }

  @override
  String get ticketHelpAction => 'Understand tickets';

  @override
  String get ticketEmptyHint =>
      'No tickets for extra hints. You can continue this game for free.';

  @override
  String get noTicketDailyTip => 'The daily challenge is free in both modes.';

  @override
  String get gameAnswer => 'Answer';

  @override
  String posterStep(int step, int total) {
    return 'Level $step of $total';
  }

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count films found',
      one: '1 film found',
    );
    return '$_temp0';
  }

  @override
  String get challengeInputLabel => 'Cineus code or link';

  @override
  String get pasteChallenge => 'Paste code or link';

  @override
  String get challengeLoadFailed =>
      'Could not load the challenge. Please try again.';

  @override
  String get editChallenge => 'Edit code or link';

  @override
  String get resultUnavailable =>
      'This result is unavailable. Return to the game or home screen.';

  @override
  String get returnToGame => 'Back to game';

  @override
  String resultProgress(int step, int total) {
    return 'Steps: $step/$total';
  }

  @override
  String resultScore(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '1 point',
      zero: '0 points',
    );
    return '$_temp0';
  }

  @override
  String get shareImage => 'Share result card';

  @override
  String get copyResultText => 'Copy result as text';

  @override
  String get shareCardTitle => 'Your result card';

  @override
  String get shareFailed => 'Could not open sharing. Try again.';

  @override
  String get copyFailed => 'Could not copy. Please try again.';

  @override
  String get challengeInviteHelp =>
      'Send the code or link to a friend to play this film in the same mode.';

  @override
  String get shareChallengeCopy => 'Copy invitation';

  @override
  String get dailyInviteWarning =>
      'The invitation opens this same film. The Daily card still hides the answer.';

  @override
  String get sharePreviewAction => 'View card';

  @override
  String get shareModeClues => 'Clues';

  @override
  String get shareModePoster => 'Poster';

  @override
  String get resultVictoryLabel => 'Correct!';

  @override
  String get resultDefeatLabel => 'Not this time';

  @override
  String get challengeEntryHelp =>
      'Paste the code or link a friend sent you. The invitation includes the game mode.';

  @override
  String get stagesCurrent => 'Your next stage';

  @override
  String get stageOpen => 'View games';

  @override
  String stageUnlockAfter(Object stage) {
    return 'Complete $stage in this mode to unlock.';
  }

  @override
  String get stageCompleteLabel => 'Stage completed';

  @override
  String get stageCostHelp =>
      'Starting or retrying costs 1 ticket. Resuming a game is free.';

  @override
  String get stageNoTicketsHelp =>
      'No tickets for a new game? Resume active games for free or play the Daily. Check when your balance renews.';

  @override
  String get stageLoadingAction => 'Opening game…';

  @override
  String get statsOverview => 'Overview';

  @override
  String get statsAchievementsTab => 'Achievements';

  @override
  String statsDailyOnly(Object mode) {
    return 'Daily history · $mode';
  }

  @override
  String get statsEmptyTitle => 'Your story starts here';

  @override
  String get statsEmptyBody =>
      'Finish a daily challenge to record your first result.';

  @override
  String get streakEmpty => 'No active streak';

  @override
  String get streakDailyHelp =>
      'Consecutive daily wins in this mode. Protected days keep the streak but do not add wins.';

  @override
  String protectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count protected days',
      one: '1 protected day',
      zero: '0 protected days',
    );
    return '$_temp0';
  }

  @override
  String get protectedDaysHelp =>
      'Protections recorded in history, valid for both modes.';

  @override
  String get achievementScopeDailyClues => 'Daily · Clues';

  @override
  String get achievementScopeStagesBoth => 'Stages · Clues and Poster';

  @override
  String get achievementScopeRewardsBoth => 'Rewards · Clues and Poster';

  @override
  String get achievementRulesHelp =>
      'Win, score, streak and game achievements use the Clues Daily. Completed stages and earned tickets combine both modes. Invitations do not count as Daily games.';

  @override
  String get achievementLockedLabel => 'Not unlocked yet';

  @override
  String achievementProgress(int done, int total) {
    return '$done of $total achievements unlocked';
  }

  @override
  String get streakProtectFailed =>
      'Your streak could not be protected. Try again.';

  @override
  String get stageDailyAction => 'View free Daily';

  @override
  String get guideTitle => 'Try the three modes';

  @override
  String get guideCluesTitle => 'Clues: from mystery to answer';

  @override
  String get guideCluesBody =>
      'Guess with up to 10 clues. Each reveal or wrong guess reduces the score by 1 point.';

  @override
  String get guidePosterTitle => 'Poster: reveal gradually';

  @override
  String get guidePosterBody =>
      'Guess with up to 5 blur levels. Revealing more or guessing wrong reduces the score by 1 point.';

  @override
  String get guideAnswerTitle => 'Choose, check and confirm';

  @override
  String get guideAnswerBody =>
      'Search by the Portuguese or original title. Select the movie with the correct year and confirm.';

  @override
  String get guideWrongTitle => 'A wrong guess advances the game';

  @override
  String get guideWrongBody =>
      'A wrong guess automatically reveals the next clue or level. A wrong final attempt ends the game with zero points.';

  @override
  String get guideTicketsTitle => 'Tickets: know when to use them';

  @override
  String get guideTicketsBody =>
      'Starting or replaying a stage costs 1 ticket; resuming is free. In Need a hint?, use 1 ticket or an optional video to unlock help and keep 1 ticket. Dailies and movie invitations are free.';

  @override
  String get guideTicketsRenewal =>
      'Your daily balance resets to 10 at midnight UTC. Extra tickets are kept. Finishing the Colors daily grants +2 once per date; stages do not grant this reward.';

  @override
  String get guideDailyTitle => 'Dailies on Home';

  @override
  String get guideDailyBody =>
      'Clues, Poster and Colors each have a free daily on Home. They change at midnight UTC. The screen countdown shows the time remaining.';

  @override
  String get guideStagesTitle => 'Progress at your own pace';

  @override
  String get guideStagesBody =>
      'In Movies, Posters and Colors, finish the games to unlock the next stage. Movies and Posters have 10 games per stage; Colors has two games of five different characters. Each mode has separate progress.';

  @override
  String get guideSaveFailed =>
      'Could not save that you saw the guide. Try again.';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsHelpSection => 'Help and support';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportBody =>
      'Find help or report a problem on GitHub. Opening the link does not send a message automatically. Avoid posting personal data.';

  @override
  String get supportOpen => 'Open support';

  @override
  String get supportCopy => 'Copy support link';

  @override
  String get supportOpenFailed =>
      'Could not open the browser. Copy the link to access support.';

  @override
  String get supportCopied => 'Support link copied.';

  @override
  String get supportCopyFailed =>
      'Could not copy. You can select the link below.';

  @override
  String get searchEmptyHelp =>
      'Check spelling or try the original title. Select a movie with the correct year before confirming.';

  @override
  String get colorTrainingBadge => 'TRAINING';

  @override
  String colorRoundProgress(int current, int total) {
    return 'Round $current/$total';
  }

  @override
  String get colorComplete => 'Complete';

  @override
  String get colorTrainingRulesBody =>
      'Adjust the color, confirm and compare with the reference. Five rounds give a final average. A hint deducts 1 point.';

  @override
  String get colorConfirm => 'Confirm colour';

  @override
  String get colorNextRound => 'Next round';

  @override
  String get colorSeeFinal => 'See final average';

  @override
  String get colorPlayAgain => 'Play again';

  @override
  String get colorRestart => 'Restart training';

  @override
  String get colorHintAction => 'Use hint · −1 point';

  @override
  String get colorHintApplied => 'Hint used · −1 point';

  @override
  String get colorRoundResult => 'Your colour, side by side.';

  @override
  String get colorReferenceTone => 'Reference';

  @override
  String colorScoreValue(String score) {
    return '$score / 10';
  }

  @override
  String get colorFinalTitle => 'Five colours. Your memory.';

  @override
  String get colorAverageLabel => 'Your average';

  @override
  String get colorDiscardTitle => 'Leave this training?';

  @override
  String get colorDiscardBody =>
      'This game’s progress will be lost. New training starts at round one.';

  @override
  String get colorKeepPlaying => 'Keep playing';

  @override
  String get colorDiscardAction => 'Discard game';

  @override
  String get colorDailyBadge => 'DAILY';

  @override
  String get colorDailyTitle => 'Daily challenge';

  @override
  String get colorResume => 'Continue game';

  @override
  String colorResumeRound(int round) {
    return 'Continue · round $round/5';
  }

  @override
  String get colorPendingDaily => 'Unfinished daily';

  @override
  String get colorOldDailyPolicy =>
      'Finish this game whenever you like. It keeps its original date and does not take today’s daily slot.';

  @override
  String get colorHistory => 'Colour history';

  @override
  String get colorOpenHistory => 'View my history';

  @override
  String get colorHistoryEmpty =>
      'You have not completed a game in this category yet.';

  @override
  String get colorHistoryFive =>
      'Five confirmed answers. Open to review each round.';

  @override
  String get colorSeeResult => 'Review result';

  @override
  String get colorSaving => 'Saving your game…';

  @override
  String get colorSaveFailed =>
      'Could not save. Retry before leaving; the game has not advanced.';

  @override
  String get colorReloadSaved => 'Reload saved version';

  @override
  String get colorBackHub => 'Back to Colors';

  @override
  String get colorLoadFailed =>
      'Could not open colour data. It has been preserved. Retry; a game with an incompatible version needs an app update.';

  @override
  String get colorLoading => 'Opening your saved colours…';

  @override
  String get colorReplaceTrainingBody =>
      'Starting another training game replaces the current training. Completed results stay in your history.';

  @override
  String get colorSavedRules =>
      'Adjust the color and confirm to compare it with the reference. Five rounds give a final average. A hint deducts 1 point. Stages are on Colors; dailies are on Home.';

  @override
  String get colorReplaceTrainingTitle => 'Start another training game?';

  @override
  String get colorReplaceTrainingAction => 'Replace training';

  @override
  String get colorGuideTitle => 'How to play Colors';

  @override
  String get colorGuideAdjustTitle => 'Color the character';

  @override
  String get colorGuideAdjustBody =>
      'Adjust the character’s color and see the result in real time.';

  @override
  String get colorGuideResultTitle => 'Compare your choice';

  @override
  String get colorGuideResultBody =>
      'Colors close to the reference earn up to 10 points. Each game has five rounds; the final score is their average.';

  @override
  String get colorGuideHintRule =>
      'One hint per round subtracts 1 point. The quick hint is free; adjustment guidance uses 1 ticket or an optional video.';

  @override
  String get colorGuideDailyRule =>
      'On Colors, each stage has ten different characters in two games of five. Finish both to unlock the next stage. The daily challenge is on Home.';

  @override
  String get colorGuideSaveRule =>
      'The game is saved on this device and can be resumed. An older daily keeps its date. Clearing app data or uninstalling removes local history.';

  @override
  String get colorGuideSaveFailed =>
      'Could not save the tutorial step. Retry; no game has been created.';

  @override
  String get colorGuideDone => 'Got it, let’s play';

  @override
  String get colorGuideNext => 'Next step';

  @override
  String get colorGuidePrevious => 'Previous step';

  @override
  String get colorRewardSaving => 'Recording your +2 tickets…';

  @override
  String get colorRewardEarned =>
      '+2 tickets earned from daily. This date’s reward is already in your balance.';

  @override
  String get colorRewardFailed =>
      'Your result is saved. Could not confirm the tickets; retry to recover the reward.';

  @override
  String get colorStatsTitle => 'Colour statistics';

  @override
  String get colorStatsCompleted => 'Completed games';

  @override
  String get colorStatsMean => 'Game average';

  @override
  String get colorStatsBest => 'Best average';

  @override
  String get colorStatsRounds => 'Average per round';

  @override
  String get colorStatsRoundsBody =>
      'Each position combines scores from your completed games in this category.';

  @override
  String colorStatsRound(int round) {
    return 'Round $round';
  }

  @override
  String get colorStatsRecent => 'Recent results';

  @override
  String get colorStatsScope =>
      'Colour scores are independent. They do not change Clues or Poster wins or streaks.';

  @override
  String get colorStatsOpen => 'View my statistics';

  @override
  String get colorShareTitle => 'My memory has colour.';

  @override
  String get colorSharePrivacy =>
      'Scores only: characters, questions and colours stay out of this card.';

  @override
  String get colorShareText => 'Share text';

  @override
  String get colorHomeDescription =>
      'Remember the shade? Recolour five characters and compare your memory with the reference.';

  @override
  String colorExactTitle(String label) {
    return 'Adjust $label';
  }

  @override
  String colorExactRange(int max) {
    return 'Value from 0 to $max. Decimals are allowed.';
  }

  @override
  String colorExactInvalid(int max) {
    return 'Enter a number between 0 and $max.';
  }

  @override
  String colorExactSemantic(int max, String value) {
    return '$value out of $max';
  }

  @override
  String get colorExactApply => 'Apply value';

  @override
  String get colorExactCancel => 'Cancel';

  @override
  String colorDecrease(String label) {
    return 'Decrease $label';
  }

  @override
  String colorIncrease(String label) {
    return 'Increase $label';
  }

  @override
  String get colorCreditsTitle => 'Colour sources';

  @override
  String get colorCreditsDescription =>
      'References used in the colour collection. Shades correspond to the indicated parts and versions; the artwork is a visual interpretation.';

  @override
  String get colorCreditsGenerated => 'Illustration generated for Cineus';

  @override
  String get colorCreditsReference => 'Illustration based on a reference image';

  @override
  String get colorCreditsStudy => 'Colour-study reference';

  @override
  String get colorCreditsArt => 'Reference image source';

  @override
  String get homeDailyAction => 'Play daily';

  @override
  String get homeDailyCompleted => 'Daily completed';

  @override
  String get homeStatsTitle => 'My statistics';

  @override
  String get homeCluesDescription => 'Test your movie knowledge.';

  @override
  String get homePosterDescription => 'Can you name the movie from its poster?';

  @override
  String get homeChallengeUnavailable => 'Could not load this challenge.';

  @override
  String get filmsToStart => 'to start';

  @override
  String get filmsInStage => 'in this stage';

  @override
  String get filmsAllStages => 'All stages';

  @override
  String filmsUnlockAfter(String stage) {
    return 'Complete $stage';
  }

  @override
  String get filmsEmpty => 'No stages available.';

  @override
  String get colorEnlargeCharacter => 'Enlarge character';

  @override
  String get colorZoomHint => 'Use two fingers to zoom in on the details.';

  @override
  String get colorStagesSubtitle => 'Recall colors and advance through stages.';

  @override
  String colorStageTitle(int stage) {
    return 'Stage $stage';
  }

  @override
  String colorStageProgress(int done, int total) {
    return '$done / $total characters completed';
  }

  @override
  String get colorStageStructure => '10 different characters · 2 games of 5';

  @override
  String get colorStageReturn => 'Back to stage';

  @override
  String colorStageMatch(int match) {
    return 'Game $match';
  }

  @override
  String get colorStageStart => 'Start · 1 ticket';

  @override
  String get colorStageResume => 'Continue';

  @override
  String get colorStageOpen => 'View games';

  @override
  String colorStageLocked(int stage) {
    return 'Complete Stage $stage';
  }

  @override
  String get colorStageDailyHome => 'Daily challenges are on Home.';

  @override
  String get colorStageLegacy => 'Resume previous practice';

  @override
  String get colorStagesAndTraining => 'Stages and practice';

  @override
  String get splashWelcome => 'Cinema, memory and color.';

  @override
  String get colorStageGamesTitle => 'Stage games';

  @override
  String get resultNext => 'Next';

  @override
  String get stagePlay => 'Play';

  @override
  String get stageRetry => 'Try again';

  @override
  String get stageContinue => 'Continue';

  @override
  String get guidePracticeNotice =>
      'Free example · no tickets used and no progress changed.';

  @override
  String get guideColorsBody =>
      'Recreate the color of one character region. Adjust hue, saturation and brightness, then confirm to compare.';

  @override
  String get guideTryColors => 'Try Colors';

  @override
  String get guideDemoReset => 'Try again';

  @override
  String get guideDemoComplete => 'Finish the example game';

  @override
  String get guideDemoUnlocked => 'Stage 2 unlocked in the example.';

  @override
  String get guideDemoCorrect =>
      'You got the example right! The result shows your points and the movie.';

  @override
  String get guideDemoWrong =>
      'In this example, a wrong guess reveals another clue: Christopher Nolan directed the movie. You can still try Interstellar.';

  @override
  String get guideDemoClues =>
      'A group travels through space to find a new home.|Earth faces a food crisis.|Time passes differently on another planet.|A father promises to return to his daughter.|The journey goes through a wormhole.|A robot named TARS joins the team.|One planet is covered with water.|The protagonist is named Cooper.|Christopher Nolan directed the movie.|Matthew McConaughey plays Cooper.';

  @override
  String get guideSaveTitle => 'Game and history';

  @override
  String get guideSaveBody =>
      'Leave and resume your game later. Progress and statistics stay on this device; clearing app data or uninstalling removes local records.';

  @override
  String get guideResultsTitle => 'Result and card';

  @override
  String get guideResultsBody =>
      'Next opens the next game. View card shows the poster, brand and points; sharing is inside the card. The bar is green for 7–10, yellow for 4–6 and red for 0–3 points. Challenge a friend creates a movie invitation. Colors shows five scores and their average.';

  @override
  String get guideColorsEconomy =>
      'Stages cost 1 ticket; resuming is free. Completing the free daily grants +2. Both the quick hint and adjustment guidance subtract 1 point this round; guidance uses a ticket or an optional video.';

  @override
  String get guideJourneyTitle => 'Dailies and stages';

  @override
  String get guideEssentialsTitle => 'Your progress and results';

  @override
  String get colorMysteryCharacters => 'Mystery characters';

  @override
  String get colorStatsAllScope => 'All completed Colors games';

  @override
  String get colorStatsPointScale => 'points from 0 to 10';

  @override
  String get colorStatsRoundsPlayed => 'Completed rounds';

  @override
  String get achievementScopeColors => 'Colors · all modes';

  @override
  String get achievementScopeDailyPoster => 'Daily · Poster';

  @override
  String get achPosterFirst => 'First frame';

  @override
  String get achPosterFirstDesc => 'Win a daily Poster challenge.';

  @override
  String get achPosterPerfect => 'Sharp eye';

  @override
  String get achPosterPerfectDesc =>
      'Earn 5 points in a daily Poster at the first blur level.';

  @override
  String get achColorsFirst => 'First brushstroke';

  @override
  String get achColorsFirstDesc => 'Finish a Colors game with five characters.';

  @override
  String get achColors25 => 'Memory studio';

  @override
  String get achColors25Desc => 'Finish 25 Colors games.';

  @override
  String get achColorsExcellent => 'Color memory';

  @override
  String get achColorsExcellentDesc =>
      'Achieve a final average of at least 9 points in a Colors game.';

  @override
  String get achColorsStages3 => 'Growing gallery';

  @override
  String get achColorsStages3Desc =>
      'Complete both games in three Colors stages.';

  @override
  String get collectionTitle => 'My collection';

  @override
  String get collectionProfile => 'My profile';

  @override
  String get collectionEditProfile => 'Edit profile';

  @override
  String get collectionDisplayName => 'Display name';

  @override
  String get collectionNameHint => 'How should you appear?';

  @override
  String get collectionShowIdentity => 'Show name and avatar on the card';

  @override
  String get collectionNameInvalid =>
      'Use up to 24 characters, without line breaks.';

  @override
  String get collectionSave => 'Save';

  @override
  String get collectionAvatars => 'Avatars';

  @override
  String get collectionFrames => 'Frames';

  @override
  String get collectionAppearances => 'Cards';

  @override
  String get collectionApply => 'Apply';

  @override
  String get collectionEquipped => 'Equipped';

  @override
  String get collectionUnavailable => 'Unavailable';

  @override
  String get collectionPreview => 'Preview';

  @override
  String get collectionLoadFailed => 'Could not open your collection.';

  @override
  String get collectionSaveFailed => 'Could not save. Try again.';

  @override
  String get collectionEmpty => 'No items in this category.';

  @override
  String get collectionAvatarOwl => 'Íris, a Última Técnica';

  @override
  String get collectionAvatarFox => 'Dante Rebobina';

  @override
  String get collectionFrameGold => 'Golden light';

  @override
  String get collectionFrameBlue => 'Blue reel';

  @override
  String get collectionAppearanceNoir => 'Cinema night';

  @override
  String get collectionPremiere => 'Premiere Collection';

  @override
  String get collectionTryPremiere => 'Try the collection';

  @override
  String get collectionPremierePreview => 'Premiere Collection preview';

  @override
  String get collectionFree => 'Free';

  @override
  String get collectionPersonalize => 'Customize';

  @override
  String get collectionAvatarCat => 'Otto Corte-Final';

  @override
  String get collectionAvatarHare => 'Vitor Plano-Mestre';

  @override
  String get collectionFrameMarquee => 'Premiere lights';

  @override
  String get collectionFrameDeco => 'Art Deco cinema';

  @override
  String get collectionFrameSpotlight => 'In the spotlight';

  @override
  String get collectionAppearanceVelvet => 'Premiere velvet';

  @override
  String get commerceRestore => 'Restore purchases';

  @override
  String commerceBuy(String price) {
    return 'Buy · $price';
  }

  @override
  String get commercePending => 'Purchase awaiting confirmation.';

  @override
  String get commerceVerified =>
      'Purchase verified. Your items are in the collection.';

  @override
  String get commerceFailed =>
      'Could not verify. Try restoring when the connection returns.';

  @override
  String get commerceCancelled => 'Purchase cancelled.';

  @override
  String get commerceRestoring =>
      'Restore requested. Verification may take a moment.';

  @override
  String get commerceUse => 'Use collection';

  @override
  String get commercePermanent => 'One-time purchase · permanent items';

  @override
  String get commerceRecovery => 'Recover access';

  @override
  String get commerceRecoveryKey => 'Recovery key';

  @override
  String get commerceRecoveryInfo =>
      'Keep this key privately before reinstalling or changing devices. It recovers commerce access, not game progress. Do not share it.';

  @override
  String get commerceRecoverAction => 'Recover';

  @override
  String get commercePlus => 'Cineus Plus';

  @override
  String get commerceClub => 'Cineus Club';

  @override
  String get commercePrivacy => 'Ad privacy';

  @override
  String get commerceHideRewarded => 'Hide video offers';

  @override
  String get commerceClubTerms =>
      'Monthly auto-renewing subscription. Includes the cycle collection and removes interruptions while active. Cancel in the store; acquired items remain yours.';

  @override
  String get commerceManage => 'Manage subscription';

  @override
  String get missionsTitle => 'Your journey';

  @override
  String get missionsWeekly => 'Weekly missions';

  @override
  String get missionPlay => 'Complete 3 games';

  @override
  String get missionModes => 'Play all 3 modes';

  @override
  String get missionDays => 'Play on 3 days';

  @override
  String get missionClaim => 'Claim';

  @override
  String get missionClaimed => 'Claimed';

  @override
  String get discoveryTitle => 'Discovered characters';

  @override
  String get discoveryMystery => 'Mystery character';

  @override
  String get seasonTitle => 'Cinema showcases';

  @override
  String get seasonArchive => 'Previous collections';

  @override
  String get sponsorTitle => 'Special screening';

  @override
  String get sponsorDemo => 'Demo · Aurora Studio';

  @override
  String get sponsorDisclosure => 'Sponsorship';

  @override
  String get sponsorGoal => 'Complete 3 games during the event';

  @override
  String get sponsorReward => 'Free visual reward';

  @override
  String get collectionNight => 'Starry Night';

  @override
  String get collectionCity => 'City Lights';

  @override
  String get itemMissionFirefly => 'Enzo Replay';

  @override
  String get itemMissionProjector => 'Weekly projection';

  @override
  String get itemMissionConstellation => 'Constellation';

  @override
  String get itemPlusCrown => 'Cinema crown';

  @override
  String get itemPlusPremiere => 'Plus velvet';

  @override
  String get itemNightRaccoon => 'Nara Estelar';

  @override
  String get itemNightOtter => 'Ciro Maré-de-Cena';

  @override
  String get itemNightOrbit => 'Golden orbit';

  @override
  String get itemNightComet => 'Comet trail';

  @override
  String get itemNightObservatory => 'Observatory';

  @override
  String get itemNightSky => 'Cinema sky';

  @override
  String get itemCityPanda => 'Raul Duplo-Corte';

  @override
  String get itemCityHummingbird => 'Sol Última-Tomada';

  @override
  String get itemCitySkyline => 'Luminous skyline';

  @override
  String get itemCityBridge => 'Golden bridge';

  @override
  String get itemCityRain => 'Premiere rain';

  @override
  String get itemCityNight => 'City at night';

  @override
  String get itemAuroraFrame => 'First light';

  @override
  String get seasonRefresh => 'Update collections';

  @override
  String get seasonUpdateFailed =>
      'Could not update. Your collection is still available.';

  @override
  String get sponsorJoin => 'Join';

  @override
  String get sponsorEnded => 'Event ended';

  @override
  String get collectionOwned => 'Owned';

  @override
  String sponsorGoalCount(int count) {
    return 'Complete $count games during the event';
  }

  @override
  String get guideCollectionTitle => 'Your journey and your look';

  @override
  String get guideCollectionBody =>
      'Weekly missions and free events unlock cosmetics. Preview and apply them in My collection. Optional purchases personalize cards; they do not change your score.';

  @override
  String get collectionPreviewNotice =>
      'Preview · your equipped items stay unchanged.';

  @override
  String get commercePlusTerms =>
      'One-time purchase · no interruptions, with an exclusive frame and card.';

  @override
  String get commerceCollectionTerms =>
      'One-time purchase · 2 avatars, 3 frames and 1 card.';

  @override
  String get commerceSubscriptionActive => 'Subscription active';

  @override
  String get earnTickets => 'Earn tickets';

  @override
  String get earnTicketsSubtitle => 'Optional videos, more games';

  @override
  String get commerceComingSoon => 'Coming soon';

  @override
  String get adSpaceLabel => 'Advertisement';

  @override
  String get adSpaceReserved => 'Reserved advertising space';

  @override
  String get rewardedLoading => 'Preparing video…';

  @override
  String get rewardedUnavailable => 'No video available right now.';

  @override
  String get rewardedLimitReached => 'You have used today’s videos.';

  @override
  String get rewardedPlaceholderBody => 'Watch a video to earn extra tickets.';

  @override
  String get rewardedRetry => 'Load video';

  @override
  String get rewardedFailed => 'Could not finish. Try again.';

  @override
  String get rewardedCancelled => 'Reward not confirmed yet.';

  @override
  String get rewardedWatching => 'Waiting for reward…';

  @override
  String get rewardedPreviewLabel => 'Rewarded video · coming soon';

  @override
  String get ticketPacksTitle => 'Ticket packs';

  @override
  String get ticketPackSmall => '20 tickets';

  @override
  String get ticketPackLarge => '60 tickets';

  @override
  String get ticketPacksNote =>
      'More games, without waiting for the daily refill.';

  @override
  String get seasonIntro =>
      'Play, complete missions and discover your next character.';

  @override
  String get seasonCurrent => 'This season';

  @override
  String get seasonNext => 'Up next';

  @override
  String get seasonFinished => 'Ended';

  @override
  String get seasonEmpty => 'New seasons are on the way.';

  @override
  String get seasonItems => 'Six looks to discover';

  @override
  String get seasonTry => 'Explore collection';

  @override
  String get seasonPreviewTitle => 'Try the looks';

  @override
  String seasonAvailableOn(String date) {
    return 'Arrives $date';
  }

  @override
  String seasonUntil(String date) {
    return 'Until $date';
  }

  @override
  String seasonOwnedCount(int count, int total) {
    return '$count of $total in your collection';
  }

  @override
  String get seasonEventTitle => 'Free event';

  @override
  String get seasonEventDemo => 'Demonstration event';

  @override
  String get seasonStoreSoon => 'Collections will be available soon.';

  @override
  String get commerceOptionalExtras => 'Play your way';

  @override
  String get commerceOptionalBody =>
      'Tickets to keep playing and an option to remove regular ads. Rewarded videos remain optional.';

  @override
  String get ticketLearnMore => 'About tickets';

  @override
  String get commerceLoading => 'Loading options…';

  @override
  String get commerceCheckFailed => 'Could not verify your purchases.';

  @override
  String get commerceOffersFailed => 'Could not load the store.';

  @override
  String get commerceNoOffers => 'No offers available right now.';

  @override
  String get commerceRestoreDone => 'Purchases restored.';

  @override
  String get commerceRestoreEmpty => 'No active purchases confirmed.';

  @override
  String get commerceBenefitsActive => 'Benefits active';

  @override
  String get commerceAdFreeActive =>
      'Advertising removed. Rewarded videos remain optional.';

  @override
  String get collectionHowToGet => 'How to get it';

  @override
  String get collectionOnlyOwned => 'My items';

  @override
  String get collectionAllItems => 'All items';

  @override
  String get collectionUnlockMission =>
      'Complete weekly missions to unlock this look.';

  @override
  String get collectionUnlockEvent => 'This look is an event reward.';

  @override
  String get collectionUnlockSeason => 'Find this collection in Seasons.';

  @override
  String get collectionUnlockSoon =>
      'This look will be available in the store soon.';

  @override
  String get collectionUnlocked => 'Unlocked';

  @override
  String get helpTitle => 'Need a hint?';

  @override
  String get helpUseTicket => 'Use 1 ticket';

  @override
  String get helpWatch => 'Video · hint + 1 ticket';

  @override
  String get helpVideoSoon => 'Video coming soon';

  @override
  String get helpVideoUsed => 'Video already used in this game';

  @override
  String get helpVideoTerms => '1 per game · shares the daily video limit.';

  @override
  String get helpPending => 'Confirming reward…';

  @override
  String get helpPendingBody =>
      'You can keep playing. Your reward will be recovered once confirmed.';

  @override
  String get helpClaim => 'Claim hint';

  @override
  String get helpStored => 'The 2 tickets stayed in your balance.';

  @override
  String get helpDone => 'Hint unlocked. +1 ticket in your balance.';

  @override
  String get helpNoAvailable => 'You have used all available hints.';

  @override
  String get helpColorGuidance => 'Color guidance';

  @override
  String get helpColorGuidanceBody =>
      'A tone and adjustment suggestion. −1 point this round.';

  @override
  String get helpColorSimple => 'Quick hint';

  @override
  String get helpColorSimpleBody => 'Character hint · −1 point';

  @override
  String get helpAdOffer =>
      'Watch an ad to unlock this hint and keep 1 ticket.';

  @override
  String helpColorFamily(String family) {
    return 'Try the $family family.';
  }

  @override
  String get helpFamilyRed => 'red';

  @override
  String get helpFamilyOrange => 'orange';

  @override
  String get helpFamilyYellow => 'yellow';

  @override
  String get helpFamilyGreen => 'green';

  @override
  String get helpFamilyCyan => 'cyan';

  @override
  String get helpFamilyBlue => 'blue';

  @override
  String get helpFamilyPurple => 'purple';

  @override
  String get helpFamilyPink => 'pink';

  @override
  String get helpFamilyNeutral => 'neutral tone';

  @override
  String get helpBrighter => 'Increase the brightness a little.';

  @override
  String get helpDarker => 'Decrease the brightness a little.';

  @override
  String get helpMoreSaturation => 'Increase the intensity a little.';

  @override
  String get helpLessSaturation => 'Decrease the intensity a little.';

  @override
  String get helpAdjustClose => 'Your settings are close; refine the hue.';

  @override
  String get archiveMode => 'Archive';

  @override
  String get practiceMode => 'Practice';

  @override
  String get activityAll => 'All games';

  @override
  String get activityDaily => 'Daily';

  @override
  String get activityStage => 'Stages';

  @override
  String get activityInvites => 'Invitations';

  @override
  String get activityContext => 'Activity';

  @override
  String get presenceStreak => 'Consecutive days played';

  @override
  String get nextGoal => 'Your next goal';

  @override
  String get continueGame => 'Continue game';

  @override
  String get practiceAgain => 'Review in practice';

  @override
  String get masteryTitle => 'Your mastery';

  @override
  String get archiveTitle => 'Previous daily games';

  @override
  String get archiveDescription =>
      'Play at your pace, without changing today’s result.';

  @override
  String get editorialFeedback => 'Report an issue';

  @override
  String get feedbackSent => 'Thanks! Report saved for review.';

  @override
  String get feedbackClue => 'Clue or answer';

  @override
  String get feedbackArtwork => 'Image or character';

  @override
  String get feedbackDifficulty => 'Difficulty';

  @override
  String get feedbackOther => 'Other issue';

  @override
  String get feedbackNote => 'Optional description';

  @override
  String get sendFeedback => 'Send report';

  @override
  String get neutralCard => 'Hide answer';

  @override
  String get quickStart => 'Play an example';

  @override
  String get backupTitle => 'Your progress';

  @override
  String get backupSave => 'Save backup';

  @override
  String get backupRestore => 'Restore backup';

  @override
  String get backupCode => 'Recovery key';

  @override
  String get backupSaved => 'Backup saved.';

  @override
  String get backupConfirm =>
      'Restore this progress? Local progress will be merged with the backup.';

  @override
  String get metricsConsent => 'Share usage data';

  @override
  String get metricsConsentBody =>
      'Help improve the game. Your guesses and names are not sent.';

  @override
  String get metricsDelete => 'Delete usage data';

  @override
  String get friendGames => 'Friends challenges';

  @override
  String get friendJoin => 'Open invitation';

  @override
  String get friendCreate => 'Create challenge';

  @override
  String get connectedRequired => 'Connect to use this feature.';

  @override
  String get missionDuplicate => 'Already owned · alternative reward';

  @override
  String get itemMissionCapybara => 'Breno Efeito-Bruto';

  @override
  String get itemMissionAxolotl => 'Bento Rolo-Perdido';

  @override
  String get itemMissionPenguin => 'Glifo Caça-Cenas';

  @override
  String get archiveMore => 'Load more days';

  @override
  String get masteryEmpty => 'Finish games to discover your themes.';

  @override
  String get playerDataTitle => 'Data and recovery';

  @override
  String get dataActionFailed => 'Could not complete the action. Try again.';

  @override
  String get backupRestored => 'Progress recovered.';

  @override
  String get recoveryKeepPrivate =>
      'Keep this key safe. It recovers your data and purchases. Do not share it.';

  @override
  String get backupScope =>
      'Saves games, stages and history. Purchased tickets are recovered from the server; daily tickets and this device’s bonuses remain local.';

  @override
  String get recoverAnotherDevice => 'Recover from another device';

  @override
  String get backupDelete => 'Delete cloud backup';

  @override
  String get backupDeleteConfirm =>
      'Delete the saved copy? Progress on this device will remain.';

  @override
  String get metricsDeletionQueued =>
      'Local data deleted. Online deletion is pending.';

  @override
  String get friendActionFailed =>
      'Could not open this invitation. Check the code, connection and availability.';

  @override
  String get friendPlayFirst =>
      'Finish a Clues or Poster game to create a challenge.';

  @override
  String get friendChooseGame => 'Choose a finished game';

  @override
  String get friendCreated => 'Invitation valid for 7 days';

  @override
  String get friendPrivateRules =>
      'A private invitation to the same game. Device-reported scores, with no ranking or prizes.';

  @override
  String get friendYou => 'You';

  @override
  String get friendOther => 'Friend';

  @override
  String get nextAction => 'Next';

  @override
  String get purchasedTickets => 'Purchased';

  @override
  String ticketPackAmount(int count) {
    return '$count tickets';
  }

  @override
  String get ticketPackTerms =>
      'One-time purchase. Tickets do not expire; connection is required to use and recover them. They do not increase your score.';

  @override
  String missionPlayCount(int count) {
    return 'Finish $count games';
  }

  @override
  String missionModesCount(int count) {
    return 'Play $count modes';
  }

  @override
  String missionDaysCount(int count) {
    return 'Play on $count days';
  }

  @override
  String masteryStageTitle(int count) {
    return 'Stage $count keeper';
  }

  @override
  String get masteryTitles => 'Earned titles';

  @override
  String get masteryAnimation => 'Animation';

  @override
  String get masteryFantasy => 'Fantasy';

  @override
  String get masteryClassics => 'Classics through 1989';

  @override
  String get assistedResult => 'Assisted';

  @override
  String presenceDays(int count) {
    return '$count days played';
  }

  @override
  String resultScoreScale(int score, int total) {
    return '$score/$total points';
  }

  @override
  String stageBonusOffer(int count) {
    return 'Completion: +$count tickets';
  }

  @override
  String stageBonusTitleOffer(int count) {
    return 'Completion: +$count tickets and a title';
  }

  @override
  String get manageProgress => 'Manage progress';

  @override
  String get progressOnDevice => 'Automatically saved on this device.';

  @override
  String get backupCloudUnavailable => 'Cloud backup is coming soon.';

  @override
  String get backupCloudChecking => 'Checking backup…';

  @override
  String get backupCloudEmpty => 'You do not have a cloud backup yet.';

  @override
  String get backupCloudError => 'Could not check your backup.';

  @override
  String backupCloudLastSaved(String date) {
    return 'In the cloud · $date';
  }

  @override
  String get backupOptions => 'Recovery and other options';

  @override
  String get backupDeleted =>
      'Cloud backup deleted. Your local progress was kept.';

  @override
  String get metricsDeletedLocal => 'Usage data on this device deleted.';

  @override
  String get metricsDeleted => 'Usage data deleted.';

  @override
  String get metricsUnavailable =>
      'Usage sharing is turned off in this version.';

  @override
  String get journeyMasteryShortcut => 'Mastery';

  @override
  String get journeyFriendsShortcut => 'Friends';

  @override
  String get audienceTitle => 'Your age range';

  @override
  String get audienceBody => 'Cineus is designed for people aged 16 and over.';

  @override
  String get audiencePrivacy =>
      'Only your age range is saved, not your date of birth. In-app purchases are intended for adults.';

  @override
  String get audienceUnder16 => 'I am under 16';

  @override
  String get audienceTeen => 'I am 16 or 17';

  @override
  String get audienceAdult => 'I am 18 or older';

  @override
  String get audienceUnavailable =>
      'This version is intended for people aged 16 and over.';

  @override
  String get audiencePurchases => 'Purchases available to adults aged 18+';

  @override
  String get showcaseAnimation => 'Animated worlds';

  @override
  String get showcaseFantasy => 'Beyond imagination';

  @override
  String get showcaseClassics => 'Classics on screen';

  @override
  String get showcasePlay => 'Choose games';

  @override
  String get showcasePractice =>
      'A selection to play at your own pace. Your progress is saved.';

  @override
  String get showcaseRewards =>
      'Looks rotate through mission rewards. Everything you already own stays yours.';

  @override
  String showcaseFilm(int number) {
    return 'Film $number';
  }
}
