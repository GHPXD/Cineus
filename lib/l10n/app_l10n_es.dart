// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

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
    return '🎬 Cineus #$challenge\nAcerté en la pista $clue/$total · ${score}pts\n\n$grid\n\ncineus.app';
  }

  @override
  String shareLose(Object challenge, Object grid) {
    return '🎬 Cineus #$challenge · Derrota\n\n$grid\n\ncineus.app';
  }

  @override
  String get semBack => 'Volver';

  @override
  String get semStats => 'Ver estadísticas';

  @override
  String get semHelp => 'Cómo jugar';

  @override
  String semGuessThisMovie(Object title) {
    return 'Adivinar $title';
  }

  @override
  String semTicketBalance(int count) {
    return '$count tickets disponibles';
  }

  @override
  String get reminderTitle => 'Cineus';

  @override
  String get reminderBody =>
      'El desafío de hoy ya está disponible. ¿Cuántas pistas necesitarás?';

  @override
  String get reminderSettingTitle => 'Recordatorio diario';

  @override
  String get reminderSettingSubtitle => 'Un aviso a las 9h, tu hora';

  @override
  String get reminderDenied =>
      'Las notificaciones están bloqueadas. Permítelas en los ajustes del sistema para activarlo.';

  @override
  String get challengeSectionTitle => 'Desafiar a un amigo';

  @override
  String get challengeShareButton => 'Desafiar a un amigo';

  @override
  String challengeShareText(Object code, Object link) {
    return '🎬 Cineus: apuesto a que no aciertas esta película.\nCódigo: $code\n$link';
  }

  @override
  String get challengeOpenTitle => 'Abrir un desafío';

  @override
  String get challengeCodeHint => 'CIN-0000';

  @override
  String get challengeOpen => 'Abrir';

  @override
  String get challengeInvalid =>
      'Código no válido. Revisa los caracteres e inténtalo de nuevo.';

  @override
  String get challengeBadge => 'DESAFÍO DE UN AMIGO';

  @override
  String get challengeFilmNotFound =>
      'Ese desafío apunta a una película que esta versión de la app no tiene.';

  @override
  String get appTagline =>
      'Adivina la película en hasta 10 pistas.\nCuantas menos uses, más puntos.';

  @override
  String get splashCredits => 'CINEUS v1.0 · FLUTTER · DART · TMDB';

  @override
  String get navHome => 'Inicio';

  @override
  String get navFilms => 'Películas';

  @override
  String get navPosters => 'Pósters';

  @override
  String get back => 'Volver';

  @override
  String get backHome => 'Volver al inicio';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get movieNotFound => 'Película no encontrada';

  @override
  String get noMoviesInDatabase => 'No hay películas en la base';

  @override
  String get genericLoadError => 'No se pudo cargar. Inténtalo de nuevo.';

  @override
  String get dailyChallengeLabel => 'DESAFÍO DIARIO';

  @override
  String get modeClues => 'Pistas';

  @override
  String get modePoster => 'Póster';

  @override
  String get notPlayedToday => 'No jugado hoy';

  @override
  String get inProgressEllipsis => 'En curso...';

  @override
  String scoreWithCheck(int score) {
    return '$score pts ✅';
  }

  @override
  String get notThisTimeSkull => 'No fue esta vez 💀';

  @override
  String get dailyDone => '¡Desafío de hoy completado!';

  @override
  String get playChallenge => 'Jugar desafío';

  @override
  String get continueClues => 'Seguir con pistas';

  @override
  String get playPoster => 'Jugar póster';

  @override
  String nextChallengeCountdown(Object hours, Object minutes, Object seconds) {
    return 'Próximo en ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String get statPlayed => 'Jugados';

  @override
  String get statWins => 'Victorias';

  @override
  String get statStreak => 'Racha';

  @override
  String get quickActionStages => 'Etapas';

  @override
  String get quickActionStagesSub => 'Películas por nivel';

  @override
  String get quickActionStatsSub => 'Tu historial';

  @override
  String get cluesHeader => 'PISTAS';

  @override
  String cluesRevealed(int count, int total) {
    return '$count / $total reveladas';
  }

  @override
  String clueFallback(int number) {
    return 'Pista $number';
  }

  @override
  String get clueNew => 'NUEVA';

  @override
  String tryAnswerClue(int clue) {
    return 'Intentar responder · Pista $clue';
  }

  @override
  String get lastAttempt => '¡Último intento!';

  @override
  String skipToClue(int next) {
    return 'Saltar · ver pista $next (−1 pt)';
  }

  @override
  String get fewPointsLeft => '¡Quedan pocos puntos!';

  @override
  String get lastClueNowOrNever => '¡Última pista! Ahora o nunca.';

  @override
  String get youGotIt => '¡Acertaste! ✅';

  @override
  String get notThisTime => 'No fue esta vez.';

  @override
  String scoreLine(int score) {
    return 'Puntuación: $score pts';
  }

  @override
  String get tryAgainTomorrow => 'Inténtalo de nuevo mañana.';

  @override
  String get seeResult => 'Ver resultado';

  @override
  String stageNumber(Object id) {
    return 'Etapa $id';
  }

  @override
  String get franchiseHint => '¡Casi! Es de esa saga, pero es otra película.';

  @override
  String get scorePoints => 'PUNTOS';

  @override
  String get scoreAvailable => 'disponibles';

  @override
  String get scoreHintMax => 'Acierta ahora y llévate el máximo';

  @override
  String scoreHintStillWorth(int revealed) {
    return '$revealed pistas reveladas · aún vale la pena';
  }

  @override
  String get scoreHintRunningOut => 'Atención — los puntos se están acabando';

  @override
  String scoreHintNextLeaves(int next, int points) {
    return 'Revelar la pista $next te deja con solo ${points}pt';
  }

  @override
  String get scoreHintLastChance => 'Última oportunidad — vale solo 1pt';

  @override
  String get whichMovie => '¿Qué película es?';

  @override
  String get movieNameHint => 'Nombre de la película...';

  @override
  String get attemptsHeader => 'INTENTOS';

  @override
  String errorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fallos',
      one: '1 fallo',
    );
    return '$_temp0';
  }

  @override
  String searchChallenge(Object number) {
    return 'Desafío n.º $number · ';
  }

  @override
  String searchPoints(int points) {
    return '$points puntos';
  }

  @override
  String get searchAvailableSuffix => ' disponibles';

  @override
  String get blurLabel => 'Desenfoque ';

  @override
  String get resultWin => '🎉 ¡ACERTASTE!';

  @override
  String get resultLose => '💔 NO FUE ESTA VEZ';

  @override
  String get theMovieWas => 'LA PELÍCULA ERA';

  @override
  String gotItOnClue(int clue) {
    return '¡Acertaste en la pista $clue!';
  }

  @override
  String get yourResult => 'TU RESULTADO';

  @override
  String get share => 'Compartir';

  @override
  String get resultShared => '¡Resultado compartido! 🎬';

  @override
  String get resultCopied => '¡Resultado copiado! 📋';

  @override
  String get playPosterArrow => 'Jugar póster →';

  @override
  String get nextFilmCost => 'Siguiente película · 1 🎫';

  @override
  String get noTicketsForNext => 'Sin 🎫 para la siguiente';

  @override
  String get nextChallengeIn => 'PRÓXIMO DESAFÍO EN';

  @override
  String get stagesSubtitleClues =>
      'Completa las etapas para desbloquear más películas.';

  @override
  String get stagesSubtitlePosters =>
      'Adivina las películas por el póster desenfocado.';

  @override
  String get stageWord => 'ETAPA';

  @override
  String get locked => 'Bloqueada';

  @override
  String filmsCount(int count) {
    return '$count películas';
  }

  @override
  String stageSemanticsLocked(Object name) {
    return '$name, bloqueada';
  }

  @override
  String stageSemanticsComplete(Object name) {
    return '$name, completa';
  }

  @override
  String stageSemanticsProgress(Object name, int done, int total) {
    return '$name, $done de $total completadas';
  }

  @override
  String get filmsDone => 'películas completadas';

  @override
  String get postersDone => 'pósters completados';

  @override
  String stageProgressLine(int done, int total, Object label) {
    return '$done / $total $label';
  }

  @override
  String get itemFilm => 'Película';

  @override
  String get itemPoster => 'Póster';

  @override
  String get slotNotStarted => 'Sin empezar • 1 🎫';

  @override
  String get slotMissedRetry => 'No acertaste • 1 🎫 para reintentar';

  @override
  String get slotInProgress => 'En curso';

  @override
  String slotPoints(int score) {
    return '$score puntos';
  }

  @override
  String get slotCompleted => 'Completada';

  @override
  String get actionPlay => 'Jugar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get noTicketsShort => 'Sin 🎫';

  @override
  String get revealMore => 'Revelar más · −1 pt';

  @override
  String tryAnswerPoints(int points) {
    return 'Intentar responder · $points pts';
  }

  @override
  String get wrongAttemptsHeader => 'INTENTOS FALLIDOS';

  @override
  String worthPoints(int points) {
    return 'Vale $points pts';
  }

  @override
  String get gameOver => 'Fin del juego';

  @override
  String gotItAtLevel(int level) {
    return '¡Acertaste en el nivel $level!';
  }

  @override
  String get betterLuckTomorrow => 'Mejor suerte mañana';

  @override
  String blurAndPoints(Object blur, int points) {
    return 'Desenfoque $blur · $points pts';
  }

  @override
  String get youRecognized => '¡La reconociste!';

  @override
  String get didntRecognize => 'No la reconociste';

  @override
  String itWas(Object title) {
    return 'Era: $title';
  }

  @override
  String pointsPlain(int score) {
    return '$score puntos';
  }

  @override
  String get youDidntGuess => 'No la adivinaste';

  @override
  String get nextWithTicket => 'Siguiente · 1 🎫';

  @override
  String get finish => 'Terminar';

  @override
  String get extraHintsHeader => 'PISTAS EXTRA';

  @override
  String get extraHintsNoPointCost => 'no cuestan puntos';

  @override
  String get hintDirector => 'Director';

  @override
  String get hintYear => 'Año';

  @override
  String get hintRuntime => 'Duración';

  @override
  String get unknownDirector => 'Desconocido';

  @override
  String runtimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get oneTicket => '1 🎫';

  @override
  String get noTicketsLower => 'sin 🎫';

  @override
  String get noTicketsForHint => 'No tienes tickets para comprar una pista';

  @override
  String buyHintSemantics(Object label, int cost) {
    return 'Comprar la pista $label por $cost ticket';
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
  String get rewardDailyWin => 'Desafío diario completado';

  @override
  String rewardStreak(int days) {
    return 'Racha de $days días';
  }

  @override
  String rewardStageComplete(int id) {
    return 'Etapa $id completada';
  }

  @override
  String get streakAtRisk => 'Tu racha está en riesgo';

  @override
  String streakRecoverBody(Object day, int cost) {
    return 'No jugaste el $day. Gasta $cost 🎫 para proteger ese día y mantener la racha.';
  }

  @override
  String protectStreak(int cost) {
    return 'Proteger racha · $cost 🎫';
  }

  @override
  String get protecting => 'Protegiendo…';

  @override
  String needTickets(int cost) {
    return 'Necesitas $cost 🎫';
  }

  @override
  String get streakProtected => '¡Racha protegida! 🔥';

  @override
  String get statGames => 'PARTIDAS';

  @override
  String get statWinsCaps => 'VICTORIAS';

  @override
  String get statRate => 'TASA';

  @override
  String get statAverage => 'MEDIA';

  @override
  String get statAverageSub => 'pistas';

  @override
  String get currentStreakTitle => 'Racha actual';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'Mejor';

  @override
  String get playToSeeDistribution => 'Juega para ver la distribución';

  @override
  String get pointsDistribution => 'DISTRIBUCIÓN DE PUNTOS';

  @override
  String get achievementsHeader => 'LOGROS';

  @override
  String get yourProfileHeader => 'TU PERFIL';

  @override
  String profileSummary(Object best, int bestPct, Object worst, int worstPct) {
    return 'Te va mejor en $best ($bestPct%) y peor en $worst ($worstPct%).';
  }

  @override
  String get byGenre => 'Por género';

  @override
  String get byDecade => 'Por década';

  @override
  String get recentGamesHeader => 'PARTIDAS RECIENTES';

  @override
  String get unknownMovie => 'Película desconocida';

  @override
  String cluesUsedCount(int count) {
    return '$count pistas';
  }

  @override
  String get defeatShort => 'Derrota';

  @override
  String bucketSemantics(Object label, int pct, int played) {
    return '$label: $pct por ciento de acierto en $played partidas';
  }

  @override
  String bucketValue(int pct, int played) {
    return '$pct% · $played';
  }

  @override
  String get achievementUnlocked => 'Desbloqueado';

  @override
  String achievementInProgress(Object progress) {
    return 'En progreso $progress';
  }

  @override
  String get achFirstWin => 'Primera victoria';

  @override
  String get achFirstWinDesc => 'Gana tu primer desafío diario.';

  @override
  String get achPerfect => 'Sin titubear';

  @override
  String get achPerfectDesc => 'Acierta en la primera pista, con 10 puntos.';

  @override
  String get achStreak7 => 'Semana completa';

  @override
  String get achStreak7Desc => '7 días seguidos acertando.';

  @override
  String get achStreak30 => 'Mes perfecto';

  @override
  String get achStreak30Desc => '30 días seguidos acertando.';

  @override
  String get achGames50 => 'Habitual';

  @override
  String get achGames50Desc => 'Juega 50 desafíos diarios.';

  @override
  String get achStages5 => 'Maratonista';

  @override
  String get achStages5Desc => 'Completa 5 etapas.';

  @override
  String get achTickets100 => 'Taquilla';

  @override
  String get achTickets100Desc => 'Gana 100 tickets jugando.';

  @override
  String get quickGuide => 'GUÍA RÁPIDA';

  @override
  String get howItWorks => 'Cómo funciona\nCineus';

  @override
  String get rule1Title => '10 pistas progresivas';

  @override
  String get rule1Desc =>
      'Cada desafío tiene 10 pistas, de la más abstracta a la más obvia. Tú eliges cuándo revelar la siguiente.';

  @override
  String get rule2Title => 'Menos pistas = más puntos';

  @override
  String get rule2Desc =>
      'Cada pista revelada cuesta 1 punto. Acierta en la primera y gana 10; en la décima, solo 1.';

  @override
  String get rule3Title => 'Búsqueda con autocompletado';

  @override
  String get rule3Desc =>
      'Escribe el título en el buscador — no hace falta acertar los acentos ni la grafía exacta. Vale el título en portugués o el original.';

  @override
  String get rule4Title => 'Un desafío por día';

  @override
  String get rule4Desc =>
      'Una película nueva cada día a medianoche UTC. Comparte tu resultado sin spoilers y compara con amigos.';

  @override
  String get gotItLetsPlay => '¡Entendido, a jugar!';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get contentLanguageNote =>
      'Las pistas y los títulos provienen del catálogo en portugués.';

  @override
  String tickets(int current, int max) {
    return '$current/$max';
  }
}
