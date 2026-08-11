// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

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
    return '🎬 Cineus #$challenge\nGot it on clue $clue/$total · ${score}pts\n\n$grid\n\ncineus.app';
  }

  @override
  String shareLose(Object challenge, Object grid) {
    return '🎬 Cineus #$challenge · Loss\n\n$grid\n\ncineus.app';
  }

  @override
  String get semBack => 'Back';

  @override
  String get semStats => 'View statistics';

  @override
  String get semHelp => 'How to play';

  @override
  String semGuessThisMovie(Object title) {
    return 'Guess $title';
  }

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
      'Guess the film in up to 10 clues.\nThe fewer you use, the more points.';

  @override
  String get splashCredits => 'CINEUS v1.0 · FLUTTER · DART · TMDB';

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
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get movieNotFound => 'Film not found';

  @override
  String get noMoviesInDatabase => 'No films in the database';

  @override
  String get genericLoadError => 'Could not load. Try again.';

  @override
  String get dailyChallengeLabel => 'DAILY CHALLENGE';

  @override
  String get modeClues => 'Clues';

  @override
  String get modePoster => 'Poster';

  @override
  String get notPlayedToday => 'Not played today';

  @override
  String get inProgressEllipsis => 'In progress...';

  @override
  String scoreWithCheck(int score) {
    return '$score pts ✅';
  }

  @override
  String get notThisTimeSkull => 'Not this time 💀';

  @override
  String get dailyDone => 'Today\'s challenge is done!';

  @override
  String get playChallenge => 'Play Challenge';

  @override
  String get continueClues => 'Continue Clues';

  @override
  String get playPoster => 'Play Poster';

  @override
  String nextChallengeCountdown(Object hours, Object minutes, Object seconds) {
    return 'Next in ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String get statPlayed => 'Played';

  @override
  String get statWins => 'Wins';

  @override
  String get statStreak => 'Streak';

  @override
  String get quickActionStages => 'Stages';

  @override
  String get quickActionStagesSub => 'Films by level';

  @override
  String get quickActionStatsSub => 'Your history';

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
  String tryAnswerClue(int clue) {
    return 'Take a Guess · Clue $clue';
  }

  @override
  String get lastAttempt => 'Last attempt!';

  @override
  String skipToClue(int next) {
    return 'Skip · see clue $next (−1 pt)';
  }

  @override
  String get fewPointsLeft => 'Few points left!';

  @override
  String get lastClueNowOrNever => 'Last clue! Now or never.';

  @override
  String get youGotIt => 'You got it! ✅';

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
  String get scoreHintMax => 'Guess now and take the maximum';

  @override
  String scoreHintStillWorth(int revealed) {
    return '$revealed clues revealed · still worth it';
  }

  @override
  String get scoreHintRunningOut => 'Careful — the points are running out';

  @override
  String scoreHintNextLeaves(int next, int points) {
    return 'Revealing clue $next leaves you just ${points}pt';
  }

  @override
  String get scoreHintLastChance => 'Last chance — worth only 1pt';

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
  String searchPoints(int points) {
    return '$points points';
  }

  @override
  String get searchAvailableSuffix => ' available';

  @override
  String get blurLabel => 'Blur ';

  @override
  String get resultWin => '🎉 CORRECT!';

  @override
  String get resultLose => '💔 NOT THIS TIME';

  @override
  String get theMovieWas => 'THE FILM WAS';

  @override
  String gotItOnClue(int clue) {
    return 'Got it on clue $clue!';
  }

  @override
  String get yourResult => 'YOUR RESULT';

  @override
  String get share => 'Share';

  @override
  String get resultShared => 'Result shared! 🎬';

  @override
  String get resultCopied => 'Result copied! 📋';

  @override
  String get playPosterArrow => 'Play Poster →';

  @override
  String get nextFilmCost => 'Next Film · 1 🎫';

  @override
  String get noTicketsForNext => 'No 🎫 for the next one';

  @override
  String get nextChallengeIn => 'NEXT CHALLENGE IN';

  @override
  String get stagesSubtitleClues => 'Complete the stages to unlock more films.';

  @override
  String get stagesSubtitlePosters =>
      'Guess the films from the blurred poster.';

  @override
  String get stageWord => 'STAGE';

  @override
  String get locked => 'Locked';

  @override
  String filmsCount(int count) {
    return '$count films';
  }

  @override
  String stageSemanticsLocked(Object name) {
    return '$name, locked';
  }

  @override
  String stageSemanticsComplete(Object name) {
    return '$name, complete';
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
  String get slotNotStarted => 'Not started • 1 🎫';

  @override
  String get slotMissedRetry => 'Missed • 1 🎫 to replay';

  @override
  String get slotInProgress => 'In progress';

  @override
  String slotPoints(int score) {
    return '$score points';
  }

  @override
  String get slotCompleted => 'Done';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionRetry => 'Retry';

  @override
  String get noTicketsShort => 'No 🎫';

  @override
  String get revealMore => 'Reveal more · −1 pt';

  @override
  String tryAnswerPoints(int points) {
    return 'Take a Guess · $points pts';
  }

  @override
  String get wrongAttemptsHeader => 'WRONG ATTEMPTS';

  @override
  String worthPoints(int points) {
    return 'Worth $points pts';
  }

  @override
  String get gameOver => 'Game Over';

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
    return '$score points';
  }

  @override
  String get youDidntGuess => 'You didn\'t guess it';

  @override
  String get nextWithTicket => 'Next · 1 🎫';

  @override
  String get finish => 'Finish';

  @override
  String get extraHintsHeader => 'EXTRA HINTS';

  @override
  String get extraHintsNoPointCost => 'no point cost';

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
  String get oneTicket => '1 🎫';

  @override
  String get noTicketsLower => 'no 🎫';

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
    return 'You didn\'t play on $day. Spend $cost 🎫 to protect that day and keep your streak.';
  }

  @override
  String protectStreak(int cost) {
    return 'Protect streak · $cost 🎫';
  }

  @override
  String get protecting => 'Protecting…';

  @override
  String needTickets(int cost) {
    return 'Needs $cost 🎫';
  }

  @override
  String get streakProtected => 'Streak protected! 🔥';

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
  String get currentStreakTitle => 'Current Streak';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
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
    return '$count clues';
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
  String get howItWorks => 'How Cineus\nworks';

  @override
  String get rule1Title => '10 progressive clues';

  @override
  String get rule1Desc =>
      'Each challenge has 10 clues, from the most abstract to the most obvious. You choose when to reveal the next one.';

  @override
  String get rule2Title => 'Fewer clues = more points';

  @override
  String get rule2Desc =>
      'Each revealed clue costs 1 point. Guess on the first and take 10; on the tenth, just 1.';

  @override
  String get rule3Title => 'Search with autocomplete';

  @override
  String get rule3Desc =>
      'Type the title in the search field — accents and exact spelling are not required. The Portuguese or the original title both work.';

  @override
  String get rule4Title => 'One challenge a day';

  @override
  String get rule4Desc =>
      'A new film every day at midnight UTC. Share your result spoiler-free and compare with friends.';

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
  String tickets(int current, int max) {
    return '$current/$max';
  }
}
