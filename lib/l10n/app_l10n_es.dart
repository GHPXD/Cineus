// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get colorModeTitle => 'Colores';

  @override
  String colorRecallPart(String part) {
    return 'Recuerda el color: $part';
  }

  @override
  String get colorYourTone => 'Tu tono';

  @override
  String get colorHue => 'Tono';

  @override
  String get colorSaturation => 'Saturación';

  @override
  String get colorBrightness => 'Brillo';

  @override
  String get colorRulesAction => 'Cómo funciona';

  @override
  String get colorRulesTitle => 'Cinco colores. Una memoria.';

  @override
  String get colorCatalogFailed => 'No se pudieron cargar las preguntas.';

  @override
  String get colorRetry => 'Intentar de nuevo';

  @override
  String get colorClose => 'Entendido';

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
    return '🎬 Cineus #$challenge\nAcerté en la pista $clue/$total · ${score}pts\n\n$grid';
  }

  @override
  String get semBack => 'Volver';

  @override
  String get semStats => 'Ver estadísticas';

  @override
  String get semHelp => 'Cómo jugar';

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
  String get reminderFailed =>
      'No se pudo actualizar el recordatorio. Inténtalo de nuevo.';

  @override
  String get fontLicensesTitle => 'Licencias de las fuentes';

  @override
  String get fontLicenseFailed =>
      'No se pudo abrir la licencia. Inténtalo de nuevo.';

  @override
  String get rewardFailed =>
      'No se pudo añadir la recompensa ahora. Tu resultado está guardado.';

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
      'Adivina películas por pistas o pósteres.\nRecuerda colores y avanza por etapas.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navFilms => 'Cine';

  @override
  String get navPosters => 'Pósters';

  @override
  String get back => 'Volver';

  @override
  String get backHome => 'Volver al inicio';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get movieNotFound => 'Película no encontrada';

  @override
  String get noMoviesInDatabase => 'No hay películas en la base';

  @override
  String get gameLoadFailed => 'No se pudo cargar la partida.';

  @override
  String get loadingGame => 'Cargando partida…';

  @override
  String get retryAction => 'Intentar de nuevo';

  @override
  String get statsLoadFailed => 'No se pudieron cargar tus estadísticas.';

  @override
  String get stageNotFound => 'Esta etapa no existe o ya no está disponible.';

  @override
  String get backToStages => 'Volver a Etapas';

  @override
  String get dailyChallengeLabel => 'DESAFÍO DIARIO';

  @override
  String get modeClues => 'Pistas';

  @override
  String get modePoster => 'Póster';

  @override
  String get dailyDone => '¡Desafío de hoy completado!';

  @override
  String nextChallengeCountdown(Object hours, Object minutes, Object seconds) {
    return 'Próximo en ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String get statPlayed => 'Jugados';

  @override
  String get statWins => 'Victorias';

  @override
  String get quickActionStatsSub => 'Tu historial';

  @override
  String get homeOpenChallenge => 'Abrir desafío';

  @override
  String get homeOpenChallengeSub => 'Por código o enlace';

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
  String get lastAttempt => '¡Último intento!';

  @override
  String skipToClue(int next) {
    return 'Saltar · ver pista $next (−1 pt)';
  }

  @override
  String get youGotIt => '¡Acertaste!';

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
  String searchStage(int id) {
    return 'Etapa $id · ';
  }

  @override
  String get searchFriendChallenge => 'Desafío de un amigo · ';

  @override
  String searchPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points puntos',
      one: '1 punto',
    );
    return ' · $_temp0';
  }

  @override
  String get searchAvailableSuffix => ' en juego';

  @override
  String get searchTypeHint => 'Escribe al menos 2 letras para buscar.';

  @override
  String get searchNoResults => 'No se encontraron películas.';

  @override
  String get searchFailed => 'No se puede buscar en este momento.';

  @override
  String get blurLabel => 'Desenfoque ';

  @override
  String get share => 'Compartir';

  @override
  String get resultShared => '¡Resultado compartido!';

  @override
  String get resultCopied => '¡Resultado copiado!';

  @override
  String get noTicketsForNext => 'Sin tickets para la siguiente';

  @override
  String get nextChallengeIn => 'PRÓXIMO DESAFÍO EN';

  @override
  String get stagesSubtitleClues =>
      'Avanza por etapas y desbloquea nuevas películas.';

  @override
  String get stagesSubtitlePosters =>
      'Adivina películas por pósters desenfocados.';

  @override
  String get locked => 'Bloqueada';

  @override
  String filmsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas',
      one: '1 película',
      zero: '0 películas',
    );
    return '$_temp0';
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
  String get slotNotStarted => 'Sin iniciar';

  @override
  String get slotMissedRetry => 'No acertaste';

  @override
  String get slotInProgress => 'En curso';

  @override
  String slotPoints(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '1 punto',
      zero: '0 puntos',
    );
    return '$_temp0';
  }

  @override
  String get actionContinue => 'Continuar';

  @override
  String get noTicketsShort => 'Sin tickets';

  @override
  String get revealMore => 'Revelar más · −1 pt';

  @override
  String worthPoints(int points) {
    return 'Vale $points pts';
  }

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
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '1 punto',
      zero: '0 puntos',
    );
    return '$_temp0';
  }

  @override
  String get youDidntGuess => 'No la adivinaste';

  @override
  String get nextWithTicket => 'Siguiente · 1 ticket';

  @override
  String get finish => 'Terminar';

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
  String get oneTicket => '1 ticket';

  @override
  String get noTicketsLower => 'sin tickets';

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
    return 'No jugaste el $day. Usa $cost tickets para proteger ese día y mantener tu racha.';
  }

  @override
  String protectStreak(int cost) {
    return 'Proteger racha · $cost tickets';
  }

  @override
  String get protecting => 'Protegiendo…';

  @override
  String needTickets(int cost) {
    return 'Necesitas $cost tickets';
  }

  @override
  String get streakProtected => '¡Racha protegida!';

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
  String get statAveragePosterSub => 'niveles';

  @override
  String get currentStreakTitle => 'Racha actual';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: '0 días',
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas',
      one: '1 pista',
      zero: '0 pistas',
    );
    return '$_temp0';
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
  String get gotItLetsPlay => '¡Entendido, a jugar!';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get contentLanguageNote =>
      'Las pistas y los títulos provienen del catálogo en portugués.';

  @override
  String get rewardedTitle => 'Ganar tickets';

  @override
  String rewardedBody(int amount, int remaining) {
    return 'Mira un anuncio opcional y gana $amount tickets. Quedan $remaining recompensas hoy.';
  }

  @override
  String rewardedAction(int amount) {
    return 'Ver y ganar +$amount tickets';
  }

  @override
  String get rewardedDone => '¡Tickets añadidos!';

  @override
  String get passTitle => 'Cineus Pass';

  @override
  String get passBody =>
      'Todo el juego sigue siendo gratuito. El Pass elimina anuncios no opcionales y puede incluir ventajas de comodidad.';

  @override
  String get passActive => 'Pass activo · sin anuncios no opcionales';

  @override
  String passGet(String price) {
    return 'Obtener Pass $price';
  }

  @override
  String get passRestore => 'Restaurar compra';

  @override
  String tickets(int current, int max) {
    return '$current/$max';
  }

  @override
  String get homeTitle => 'Cine, cada día.';

  @override
  String get dailyFree => 'GRATIS';

  @override
  String dailyWinPoints(int score) {
    return '$score puntos · Acertaste';
  }

  @override
  String get dailyLost => 'Finalizado · Esta vez no';

  @override
  String get dailyPlaying => 'Partida en curso';

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
  String get ticketDetailsTitle => 'Tus tickets';

  @override
  String get ticketDaily => 'Diarios';

  @override
  String get ticketBonus => 'Bonos';

  @override
  String ticketDailyDetail(int count, int max) {
    return '$count de $max';
  }

  @override
  String get ticketResetInfo =>
      'Los tickets diarios se reponen a medianoche UTC. Los bonos se conservan.';

  @override
  String get ticketUsageInfo =>
      'Daily y desafíos de amigos son gratis. Iniciar o repetir una película de etapa y cada pista extra cuestan 1 ticket.';

  @override
  String get ticketBalanceFailed => 'No se pudo cargar tu saldo.';

  @override
  String ticketResetCountdown(Object hours, Object minutes) {
    return 'Reposición en ${hours}h ${minutes}m';
  }

  @override
  String get confirmGuess => 'Confirmar respuesta';

  @override
  String get selectedMovieLabel => 'Película seleccionada';

  @override
  String selectMovieSemantics(Object title, int year) {
    return 'Seleccionar $title, $year';
  }

  @override
  String get guessSaveFailed =>
      'No se pudo guardar tu respuesta. Inténtalo de nuevo.';

  @override
  String get savingGuess => 'Guardando respuesta…';

  @override
  String get gameActionFailed =>
      'No se pudo guardar la acción. Inténtalo de nuevo.';

  @override
  String get hintSaveFailed =>
      'No se pudo completar la compra de la pista. Revisa tu saldo e inténtalo de nuevo.';

  @override
  String get wrongGuessRevealed => 'Respuesta incorrecta. Nuevo paso revelado.';

  @override
  String clueRevealedAnnouncement(int number) {
    return 'Pista $number revelada.';
  }

  @override
  String posterRevealedAnnouncement(int number) {
    return 'Nivel $number revelado.';
  }

  @override
  String lastGuessLabel(Object title) {
    return 'Última respuesta: $title';
  }

  @override
  String get ticketHelpAction => 'Entender los tickets';

  @override
  String get ticketEmptyHint =>
      'Sin tickets para pistas extra. Puedes continuar esta partida gratis.';

  @override
  String get noTicketDailyTip => 'El desafío diario es gratis en ambos modos.';

  @override
  String get gameAnswer => 'Responder';

  @override
  String posterStep(int step, int total) {
    return 'Nivel $step de $total';
  }

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count películas encontradas',
      one: '1 película encontrada',
    );
    return '$_temp0';
  }

  @override
  String get challengeInputLabel => 'Código o enlace Cineus';

  @override
  String get pasteChallenge => 'Pegar código o enlace';

  @override
  String get challengeLoadFailed =>
      'No se pudo cargar el desafío. Inténtalo de nuevo.';

  @override
  String get editChallenge => 'Editar código o enlace';

  @override
  String get resultUnavailable =>
      'Este resultado no está disponible. Vuelve al juego o al inicio.';

  @override
  String get returnToGame => 'Volver al juego';

  @override
  String resultProgress(int step, int total) {
    return 'Pasos: $step/$total';
  }

  @override
  String resultScore(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '1 punto',
      zero: '0 puntos',
    );
    return '$_temp0';
  }

  @override
  String get shareImage => 'Compartir tarjeta';

  @override
  String get copyResultText => 'Copiar resultado en texto';

  @override
  String get shareCardTitle => 'Tu tarjeta de resultado';

  @override
  String get shareFailed =>
      'No se pudo abrir el menú para compartir. Inténtalo de nuevo.';

  @override
  String get copyFailed => 'No se pudo copiar. Inténtalo de nuevo.';

  @override
  String get challengeInviteHelp =>
      'Envía el código o enlace a un amigo para jugar esta película en el mismo modo.';

  @override
  String get shareChallengeCopy => 'Copiar invitación';

  @override
  String get dailyInviteWarning =>
      'La invitación abre esta misma película. La tarjeta Daily oculta la respuesta.';

  @override
  String get sharePreviewAction => 'Ver tarjeta';

  @override
  String get shareModeClues => 'Pistas';

  @override
  String get shareModePoster => 'Poster';

  @override
  String get resultVictoryLabel => '¡Acertaste!';

  @override
  String get resultDefeatLabel => 'No fue esta vez';

  @override
  String get challengeEntryHelp =>
      'Pega el código o enlace que te envió un amigo. La invitación incluye el modo de juego.';

  @override
  String get stagesCurrent => 'Tu próxima etapa';

  @override
  String get stageOpen => 'Ver partidas';

  @override
  String stageUnlockAfter(Object stage) {
    return 'Completa $stage en este modo para desbloquear.';
  }

  @override
  String get stageCompleteLabel => 'Etapa completada';

  @override
  String get stageCostHelp =>
      'Empezar o reintentar cuesta 1 ticket. Retomar una partida es gratis.';

  @override
  String get stageNoTicketsHelp =>
      '¿Sin tickets para una partida nueva? Retoma partidas activas gratis o juega el Daily. Consulta cuándo se renueva tu saldo.';

  @override
  String get stageLoadingAction => 'Abriendo partida…';

  @override
  String get statsOverview => 'Resumen';

  @override
  String get statsAchievementsTab => 'Logros';

  @override
  String statsDailyOnly(Object mode) {
    return 'Historial del Daily · $mode';
  }

  @override
  String get statsEmptyTitle => 'Tu historia empieza aquí';

  @override
  String get statsEmptyBody =>
      'Completa un desafío diario para registrar tu primer resultado.';

  @override
  String get streakEmpty => 'Sin racha activa';

  @override
  String get streakDailyHelp =>
      'Victorias diarias consecutivas en este modo. Los días protegidos mantienen la racha, pero no suman victorias.';

  @override
  String protectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días protegidos',
      one: '1 día protegido',
      zero: '0 días protegidos',
    );
    return '$_temp0';
  }

  @override
  String get protectedDaysHelp =>
      'Protecciones registradas en el historial, válidas para ambos modos.';

  @override
  String get achievementScopeDailyClues => 'Daily · Pistas';

  @override
  String get achievementScopeStagesBoth => 'Etapas · Pistas y Póster';

  @override
  String get achievementScopeRewardsBoth => 'Recompensas · Pistas y Póster';

  @override
  String get achievementRulesHelp =>
      'Los logros de victorias, puntos, racha y partidas usan el Daily de Pistas. Las etapas completadas y los tickets ganados suman ambos modos. Las invitaciones no cuentan como Daily.';

  @override
  String get achievementLockedLabel => 'Aún no desbloqueado';

  @override
  String achievementProgress(int done, int total) {
    return '$done de $total logros desbloqueados';
  }

  @override
  String get streakProtectFailed =>
      'No se pudo proteger tu racha. Inténtalo de nuevo.';

  @override
  String get stageDailyAction => 'Ver Daily gratis';

  @override
  String get guideTitle => 'Prueba los tres modos';

  @override
  String get guideCluesTitle => 'Pistas: del misterio a la respuesta';

  @override
  String get guideCluesBody =>
      'Acierta con hasta 10 pistas. Cada revelación o error reduce la nota en 1 punto.';

  @override
  String get guidePosterTitle => 'Póster: revela poco a poco';

  @override
  String get guidePosterBody =>
      'Acierta con hasta 5 niveles de desenfoque. Revelar más o fallar reduce la nota en 1 punto.';

  @override
  String get guideAnswerTitle => 'Elige, revisa y confirma';

  @override
  String get guideAnswerBody =>
      'Busca por el título en portugués u original. Selecciona la película con el año correcto y confirma.';

  @override
  String get guideWrongTitle => 'Un error avanza la partida';

  @override
  String get guideWrongBody =>
      'Un error revela automáticamente la siguiente pista o nivel. Fallar en el último intento termina la partida con cero puntos.';

  @override
  String get guideTicketsTitle => 'Tickets: cuándo usarlos';

  @override
  String get guideTicketsBody =>
      'Iniciar o repetir una etapa cuesta 1 ticket; reanudar es gratis. En ¿Necesitas ayuda?, usa 1 ticket o un vídeo opcional para desbloquear la ayuda y guardar 1 ticket. Los diarios y las invitaciones de películas son gratis.';

  @override
  String get guideTicketsRenewal =>
      'El saldo diario vuelve a 10 a medianoche UTC. Los tickets extra se conservan. Completar el diario de Colores da +2 una vez por fecha; las etapas no dan esa recompensa.';

  @override
  String get guideDailyTitle => 'Diarios en Inicio';

  @override
  String get guideDailyBody =>
      'Pistas, Póster y Colores tienen un diario gratuito en Inicio. Cambian a medianoche UTC. La cuenta atrás muestra el tiempo restante.';

  @override
  String get guideStagesTitle => 'Avanza a tu ritmo';

  @override
  String get guideStagesBody =>
      'En Películas, Pósteres y Colores, completa las partidas para desbloquear la siguiente etapa. Películas y Pósteres tienen 10 partidas por etapa; Colores tiene dos partidas de cinco personajes diferentes. Cada modo tiene su propio progreso.';

  @override
  String get guideSaveFailed =>
      'No se pudo guardar que viste la guía. Inténtalo de nuevo.';

  @override
  String get settingsPreferences => 'Preferencias';

  @override
  String get settingsHelpSection => 'Ayuda y soporte';

  @override
  String get supportTitle => 'Soporte';

  @override
  String get supportBody =>
      'Encuentra ayuda o informa de un problema en GitHub. Abrir el enlace no envía un mensaje automáticamente. Evita publicar datos personales.';

  @override
  String get supportOpen => 'Abrir soporte';

  @override
  String get supportCopy => 'Copiar enlace de soporte';

  @override
  String get supportOpenFailed =>
      'No se pudo abrir el navegador. Copia el enlace para acceder al soporte.';

  @override
  String get supportCopied => 'Enlace de soporte copiado.';

  @override
  String get supportCopyFailed =>
      'No se pudo copiar. Puedes seleccionar el enlace de abajo.';

  @override
  String get searchEmptyHelp =>
      'Revisa la ortografía o prueba el título original. Selecciona una película con el año correcto antes de confirmar.';

  @override
  String get colorTrainingBadge => 'PRÁCTICA';

  @override
  String colorRoundProgress(int current, int total) {
    return 'Ronda $current/$total';
  }

  @override
  String get colorComplete => 'Completado';

  @override
  String get colorTrainingRulesBody =>
      'Ajusta el color, confirma y compara con la referencia. Cinco rondas dan un promedio final. La pista resta 1 punto.';

  @override
  String get colorConfirm => 'Confirmar color';

  @override
  String get colorNextRound => 'Siguiente ronda';

  @override
  String get colorSeeFinal => 'Ver media final';

  @override
  String get colorPlayAgain => 'Jugar otra vez';

  @override
  String get colorRestart => 'Reiniciar práctica';

  @override
  String get colorHintAction => 'Usar pista · −1 punto';

  @override
  String get colorHintApplied => 'Pista usada · −1 punto';

  @override
  String get colorRoundResult => 'Tu color, lado a lado.';

  @override
  String get colorReferenceTone => 'Referencia';

  @override
  String colorScoreValue(String score) {
    return '$score / 10';
  }

  @override
  String get colorFinalTitle => 'Cinco colores. Tu memoria.';

  @override
  String get colorAverageLabel => 'Tu media';

  @override
  String get colorDiscardTitle => '¿Salir de esta práctica?';

  @override
  String get colorDiscardBody =>
      'Se perderá el progreso de esta partida. Una nueva práctica empieza en la primera ronda.';

  @override
  String get colorKeepPlaying => 'Seguir jugando';

  @override
  String get colorDiscardAction => 'Descartar partida';

  @override
  String get colorDailyBadge => 'DIARIO';

  @override
  String get colorDailyTitle => 'Desafío diario';

  @override
  String get colorResume => 'Continuar partida';

  @override
  String colorResumeRound(int round) {
    return 'Continuar · ronda $round/5';
  }

  @override
  String get colorPendingDaily => 'Diario pendiente';

  @override
  String get colorOldDailyPolicy =>
      'Puedes terminar esta partida cuando quieras. Conserva su fecha original y no ocupa el diario de hoy.';

  @override
  String get colorHistory => 'Historial de Colores';

  @override
  String get colorOpenHistory => 'Ver mi historial';

  @override
  String get colorHistoryEmpty =>
      'Todavía no has completado una partida en esta categoría.';

  @override
  String get colorHistoryFive =>
      'Cinco respuestas confirmadas. Abre para revisar cada ronda.';

  @override
  String get colorSeeResult => 'Revisar resultado';

  @override
  String get colorSaving => 'Guardando tu partida…';

  @override
  String get colorSaveFailed =>
      'No se pudo guardar. Reintenta antes de salir; la partida no ha avanzado.';

  @override
  String get colorReloadSaved => 'Recargar la versión guardada';

  @override
  String get colorBackHub => 'Volver a Colores';

  @override
  String get colorLoadFailed =>
      'No se pudieron abrir los datos de Colores. Se han conservado. Reintenta; una partida con versión incompatible necesita una actualización de la app.';

  @override
  String get colorLoading => 'Abriendo tus colores guardados…';

  @override
  String get colorReplaceTrainingBody =>
      'Empezar otro entrenamiento sustituye el actual. Los resultados completados siguen en el historial.';

  @override
  String get colorSavedRules =>
      'Ajusta el color y confirma para compararlo con la referencia. Cinco rondas dan un promedio final. La pista resta 1 punto. Las etapas están en Colores; el diario en Inicio.';

  @override
  String get colorReplaceTrainingTitle => '¿Empezar otro entrenamiento?';

  @override
  String get colorReplaceTrainingAction => 'Sustituir entrenamiento';

  @override
  String get colorGuideTitle => 'Cómo jugar Colores';

  @override
  String get colorGuideAdjustTitle => 'Dale color al personaje';

  @override
  String get colorGuideAdjustBody =>
      'Ajusta el color del personaje y ve el resultado en tiempo real.';

  @override
  String get colorGuideResultTitle => 'Compara tu elección';

  @override
  String get colorGuideResultBody =>
      'Los colores cercanos a la referencia reciben hasta 10 puntos. Cada partida tiene cinco rondas; la nota final es su promedio.';

  @override
  String get colorGuideHintRule =>
      'Una ayuda por ronda resta 1 punto. La pista rápida es gratis; la orientación de ajustes usa 1 ticket o un vídeo opcional.';

  @override
  String get colorGuideDailyRule =>
      'En Colores, cada etapa reúne diez personajes diferentes en dos partidas de cinco. Completa ambas para abrir la siguiente. El desafío diario está en Inicio.';

  @override
  String get colorGuideSaveRule =>
      'La partida se guarda en este dispositivo y puede retomarse. Un diario antiguo conserva su fecha. Borrar datos o desinstalar la app elimina el historial local.';

  @override
  String get colorGuideSaveFailed =>
      'No se pudo registrar el tutorial. Reintenta; no se ha creado ninguna partida.';

  @override
  String get colorGuideDone => 'Entendido, vamos a jugar';

  @override
  String get colorGuideNext => 'Siguiente paso';

  @override
  String get colorGuidePrevious => 'Paso anterior';

  @override
  String get colorRewardSaving => 'Registrando tus +2 tickets…';

  @override
  String get colorRewardEarned =>
      '+2 tickets recibidos por el diario. La recompensa de esta fecha ya está en tu saldo.';

  @override
  String get colorRewardFailed =>
      'Tu resultado está guardado. No se pudieron confirmar los tickets; reintenta para recuperar la recompensa.';

  @override
  String get colorStatsTitle => 'Estadísticas de Colores';

  @override
  String get colorStatsCompleted => 'Partidas completadas';

  @override
  String get colorStatsMean => 'Promedio de partidas';

  @override
  String get colorStatsBest => 'Mejor promedio';

  @override
  String get colorStatsRounds => 'Promedio por ronda';

  @override
  String get colorStatsRoundsBody =>
      'Cada posición reúne las notas de tus partidas completadas en esta categoría.';

  @override
  String colorStatsRound(int round) {
    return 'Ronda $round';
  }

  @override
  String get colorStatsRecent => 'Últimos resultados';

  @override
  String get colorStatsScope =>
      'Las notas de Colores son independientes. No cambian victorias ni rachas de Pistas y Póster.';

  @override
  String get colorStatsOpen => 'Ver mis estadísticas';

  @override
  String get colorShareTitle => 'Mi memoria tiene color.';

  @override
  String get colorSharePrivacy =>
      'Solo las notas: los personajes, preguntas y colores quedan fuera de esta tarjeta.';

  @override
  String get colorShareText => 'Compartir texto';

  @override
  String get colorHomeDescription =>
      '¿Recuerdas el tono? Recolorea cinco personajes y compara tu memoria con la referencia.';

  @override
  String colorExactTitle(String label) {
    return 'Ajustar $label';
  }

  @override
  String colorExactRange(int max) {
    return 'Valor de 0 a $max. Puedes usar decimales.';
  }

  @override
  String colorExactInvalid(int max) {
    return 'Introduce un número entre 0 y $max.';
  }

  @override
  String colorExactSemantic(int max, String value) {
    return '$value de $max';
  }

  @override
  String get colorExactApply => 'Aplicar valor';

  @override
  String get colorExactCancel => 'Cancelar';

  @override
  String colorDecrease(String label) {
    return 'Reducir $label';
  }

  @override
  String colorIncrease(String label) {
    return 'Aumentar $label';
  }

  @override
  String get colorCreditsTitle => 'Fuentes de Colores';

  @override
  String get colorCreditsDescription =>
      'Referencias usadas en el acervo de Colores. Los tonos corresponden a las partes y versiones indicadas; las ilustraciones son interpretaciones visuales.';

  @override
  String get colorCreditsGenerated => 'Ilustración generada para Cineus';

  @override
  String get colorCreditsReference =>
      'Ilustración basada en una imagen de referencia';

  @override
  String get colorCreditsStudy => 'Referencia del estudio de color';

  @override
  String get colorCreditsArt => 'Origen de la imagen de referencia';

  @override
  String get homeDailyAction => 'Jugar el diario';

  @override
  String get homeDailyCompleted => 'Diario completado';

  @override
  String get homeStatsTitle => 'Mis estadísticas';

  @override
  String get homeCluesDescription => 'Pon a prueba tus conocimientos de cine.';

  @override
  String get homePosterDescription => '¿Cuál es la película por su póster?';

  @override
  String get homeChallengeUnavailable => 'No se pudo cargar el desafío.';

  @override
  String get filmsToStart => 'para empezar';

  @override
  String get filmsInStage => 'en esta etapa';

  @override
  String get filmsAllStages => 'Todas las etapas';

  @override
  String filmsUnlockAfter(String stage) {
    return 'Completa $stage';
  }

  @override
  String get filmsEmpty => 'No hay etapas disponibles.';

  @override
  String get colorEnlargeCharacter => 'Ampliar personaje';

  @override
  String get colorZoomHint => 'Usa dos dedos para ampliar los detalles.';

  @override
  String get colorStagesSubtitle => 'Recuerda colores y avanza por etapas.';

  @override
  String colorStageTitle(int stage) {
    return 'Etapa $stage';
  }

  @override
  String colorStageProgress(int done, int total) {
    return '$done / $total personajes completados';
  }

  @override
  String get colorStageStructure => '10 personajes distintos · 2 partidas de 5';

  @override
  String get colorStageReturn => 'Volver a la etapa';

  @override
  String colorStageMatch(int match) {
    return 'Partida $match';
  }

  @override
  String get colorStageStart => 'Empezar · 1 ticket';

  @override
  String get colorStageResume => 'Continuar';

  @override
  String get colorStageOpen => 'Ver partidas';

  @override
  String colorStageLocked(int stage) {
    return 'Completa la Etapa $stage';
  }

  @override
  String get colorStageDailyHome => 'Los desafíos diarios están en Inicio.';

  @override
  String get colorStageLegacy => 'Retomar práctica anterior';

  @override
  String get colorStagesAndTraining => 'Etapas y práctica';

  @override
  String get splashWelcome => 'Cine, memoria y color.';

  @override
  String get colorStageGamesTitle => 'Partidas de la etapa';

  @override
  String get resultNext => 'Siguiente';

  @override
  String get stagePlay => 'Jugar';

  @override
  String get stageRetry => 'Reintentar';

  @override
  String get stageContinue => 'Continuar';

  @override
  String get guidePracticeNotice =>
      'Ejemplo libre · no usa tickets ni cambia tu progreso.';

  @override
  String get guideColorsBody =>
      'Recrea el color de una región del personaje. Ajusta tono, saturación y brillo y confirma para comparar.';

  @override
  String get guideTryColors => 'Probar Colores';

  @override
  String get guideDemoReset => 'Probar de nuevo';

  @override
  String get guideDemoComplete => 'Completar la partida del ejemplo';

  @override
  String get guideDemoUnlocked => 'Etapa 2 desbloqueada en el ejemplo.';

  @override
  String get guideDemoCorrect =>
      '¡Acertaste el ejemplo! El resultado muestra tus puntos y la película.';

  @override
  String get guideDemoWrong =>
      'En este ejemplo, fallar revela otra pista: Christopher Nolan dirigió la película. Aún puedes probar Interstellar.';

  @override
  String get guideDemoClues =>
      'Un grupo viaja por el espacio buscando un nuevo hogar.|La Tierra enfrenta una crisis alimentaria.|El tiempo pasa de forma distinta en otro planeta.|Un padre promete volver con su hija.|El viaje atraviesa un agujero de gusano.|Un robot llamado TARS acompaña al equipo.|Un planeta está cubierto por agua.|El protagonista se llama Cooper.|Christopher Nolan dirigió la película.|Matthew McConaughey interpreta a Cooper.';

  @override
  String get guideSaveTitle => 'Partida e historial';

  @override
  String get guideSaveBody =>
      'Puedes salir y continuar después. El progreso y las estadísticas quedan en este dispositivo; borrar los datos o desinstalar la app elimina los registros locales.';

  @override
  String get guideResultsTitle => 'Resultado y tarjeta';

  @override
  String get guideResultsBody =>
      'Siguiente abre la próxima partida. Ver tarjeta muestra el póster, la marca y los puntos; compartir está dentro de la tarjeta. La barra es verde para 7–10, amarilla para 4–6 y roja para 0–3 puntos. Desafiar a un amigo crea una invitación de película. Colores muestra cinco notas y su promedio.';

  @override
  String get guideColorsEconomy =>
      'Las etapas cuestan 1 ticket; reanudar es gratis. Completar el diario gratuito da +2. La pista rápida y la orientación de ajustes restan 1 punto en la ronda; la orientación usa un ticket o un vídeo opcional.';

  @override
  String get guideJourneyTitle => 'Diarios y etapas';

  @override
  String get guideEssentialsTitle => 'Tu progreso y resultados';

  @override
  String get colorMysteryCharacters => 'Personajes misteriosos';

  @override
  String get colorStatsAllScope => 'Todas las partidas completadas de Colores';

  @override
  String get colorStatsPointScale => 'puntos de 0 a 10';

  @override
  String get colorStatsRoundsPlayed => 'Rondas completadas';

  @override
  String get achievementScopeColors => 'Colores · todos los modos';

  @override
  String get achievementScopeDailyPoster => 'Daily · Póster';

  @override
  String get achPosterFirst => 'Primer encuadre';

  @override
  String get achPosterFirstDesc => 'Gana un desafío diario de Póster.';

  @override
  String get achPosterPerfect => 'Ojo clínico';

  @override
  String get achPosterPerfectDesc =>
      'Consigue 5 puntos en un diario de Póster, en el primer nivel de desenfoque.';

  @override
  String get achColorsFirst => 'Primera pincelada';

  @override
  String get achColorsFirstDesc =>
      'Completa una partida de Colores con cinco personajes.';

  @override
  String get achColors25 => 'Taller de recuerdos';

  @override
  String get achColors25Desc => 'Completa 25 partidas de Colores.';

  @override
  String get achColorsExcellent => 'Memoria cromática';

  @override
  String get achColorsExcellentDesc =>
      'Alcanza una media final de al menos 9 puntos en una partida de Colores.';

  @override
  String get achColorsStages3 => 'Galería en expansión';

  @override
  String get achColorsStages3Desc =>
      'Completa las dos partidas de tres etapas de Colores.';

  @override
  String get collectionTitle => 'Mi colección';

  @override
  String get collectionProfile => 'Mi perfil';

  @override
  String get collectionEditProfile => 'Editar perfil';

  @override
  String get collectionDisplayName => 'Nombre visible';

  @override
  String get collectionNameHint => '¿Cómo quieres aparecer?';

  @override
  String get collectionShowIdentity => 'Mostrar nombre y avatar en la tarjeta';

  @override
  String get collectionNameInvalid =>
      'Usa hasta 24 caracteres, sin saltos de línea.';

  @override
  String get collectionSave => 'Guardar';

  @override
  String get collectionAvatars => 'Avatares';

  @override
  String get collectionFrames => 'Marcos';

  @override
  String get collectionAppearances => 'Tarjetas';

  @override
  String get collectionApply => 'Aplicar';

  @override
  String get collectionEquipped => 'En uso';

  @override
  String get collectionUnavailable => 'No disponible';

  @override
  String get collectionPreview => 'Vista previa';

  @override
  String get collectionLoadFailed => 'No se pudo abrir tu colección.';

  @override
  String get collectionSaveFailed => 'No se pudo guardar. Inténtalo otra vez.';

  @override
  String get collectionEmpty => 'No hay artículos en esta categoría.';

  @override
  String get collectionAvatarOwl => 'Íris, a Última Técnica';

  @override
  String get collectionAvatarFox => 'Dante Rebobina';

  @override
  String get collectionFrameGold => 'Luz dorada';

  @override
  String get collectionFrameBlue => 'Rollo azul';

  @override
  String get collectionAppearanceNoir => 'Noche de cine';

  @override
  String get collectionPremiere => 'Colección Estreno';

  @override
  String get collectionTryPremiere => 'Probar colección';

  @override
  String get collectionPremierePreview =>
      'Vista previa de la Colección Estreno';

  @override
  String get collectionFree => 'Gratis';

  @override
  String get collectionPersonalize => 'Personalizar';

  @override
  String get collectionAvatarCat => 'Otto Corte-Final';

  @override
  String get collectionAvatarHare => 'Vitor Plano-Mestre';

  @override
  String get collectionFrameMarquee => 'Luces del estreno';

  @override
  String get collectionFrameDeco => 'Cine Art Déco';

  @override
  String get collectionFrameSpotlight => 'Bajo los focos';

  @override
  String get collectionAppearanceVelvet => 'Terciopelo del estreno';

  @override
  String get commerceRestore => 'Restaurar compras';

  @override
  String commerceBuy(String price) {
    return 'Comprar · $price';
  }

  @override
  String get commercePending => 'Compra pendiente de confirmación.';

  @override
  String get commerceVerified =>
      'Compra confirmada. Tus artículos están en la colección.';

  @override
  String get commerceFailed =>
      'No se pudo confirmar. Intenta restaurar cuando vuelva la conexión.';

  @override
  String get commerceCancelled => 'Compra cancelada.';

  @override
  String get commerceRestoring =>
      'Restauración solicitada. La confirmación puede tardar unos instantes.';

  @override
  String get commerceUse => 'Usar colección';

  @override
  String get commercePermanent => 'Compra única · artículos permanentes';

  @override
  String get commerceRecovery => 'Recuperar acceso';

  @override
  String get commerceRecoveryKey => 'Clave de recuperación';

  @override
  String get commerceRecoveryInfo =>
      'Guarda esta clave en privado antes de reinstalar o cambiar de dispositivo. Recupera el acceso comercial, no el progreso del juego. No la compartas.';

  @override
  String get commerceRecoverAction => 'Recuperar';

  @override
  String get commercePlus => 'Cineus Plus';

  @override
  String get commerceClub => 'Cineus Club';

  @override
  String get commercePrivacy => 'Privacidad de anuncios';

  @override
  String get commerceHideRewarded => 'Ocultar ofertas de vídeo';

  @override
  String get commerceClubTerms =>
      'Suscripción mensual con renovación automática. Incluye la colección del ciclo y elimina interrupciones durante su vigencia. Cancela en la tienda; los artículos adquiridos permanecen.';

  @override
  String get commerceManage => 'Gestionar suscripción';

  @override
  String get missionsTitle => 'Tu aventura';

  @override
  String get missionsWeekly => 'Misiones semanales';

  @override
  String get missionPlay => 'Completa 3 partidas';

  @override
  String get missionModes => 'Juega los 3 modos';

  @override
  String get missionDays => 'Juega en 3 días';

  @override
  String get missionClaim => 'Reclamar';

  @override
  String get missionClaimed => 'Reclamado';

  @override
  String get discoveryTitle => 'Personajes descubiertos';

  @override
  String get discoveryMystery => 'Personaje misterioso';

  @override
  String get seasonTitle => 'Muestras de cine';

  @override
  String get seasonArchive => 'Colecciones anteriores';

  @override
  String get sponsorTitle => 'Sesión especial';

  @override
  String get sponsorDemo => 'Demostración · Estudio Aurora';

  @override
  String get sponsorDisclosure => 'Patrocinio';

  @override
  String get sponsorGoal => 'Completa 3 partidas durante el evento';

  @override
  String get sponsorReward => 'Recompensa visual gratuita';

  @override
  String get collectionNight => 'Noche estrellada';

  @override
  String get collectionCity => 'Luces de la ciudad';

  @override
  String get itemMissionFirefly => 'Enzo Replay';

  @override
  String get itemMissionProjector => 'Proyección semanal';

  @override
  String get itemMissionConstellation => 'Constelación';

  @override
  String get itemPlusCrown => 'Corona del cine';

  @override
  String get itemPlusPremiere => 'Terciopelo Plus';

  @override
  String get itemNightRaccoon => 'Nara Estelar';

  @override
  String get itemNightOtter => 'Ciro Maré-de-Cena';

  @override
  String get itemNightOrbit => 'Órbita dorada';

  @override
  String get itemNightComet => 'Estela de cometa';

  @override
  String get itemNightObservatory => 'Observatorio';

  @override
  String get itemNightSky => 'Cielo de cine';

  @override
  String get itemCityPanda => 'Raul Duplo-Corte';

  @override
  String get itemCityHummingbird => 'Sol Última-Tomada';

  @override
  String get itemCitySkyline => 'Horizonte de luz';

  @override
  String get itemCityBridge => 'Puente dorado';

  @override
  String get itemCityRain => 'Lluvia de estreno';

  @override
  String get itemCityNight => 'Ciudad nocturna';

  @override
  String get itemAuroraFrame => 'Primera luz';

  @override
  String get seasonRefresh => 'Actualizar colecciones';

  @override
  String get seasonUpdateFailed =>
      'No se pudo actualizar. Tu colección sigue disponible.';

  @override
  String get sponsorJoin => 'Participar';

  @override
  String get sponsorEnded => 'Evento finalizado';

  @override
  String get collectionOwned => 'Adquirido';

  @override
  String sponsorGoalCount(int count) {
    return 'Completa $count partidas durante el evento';
  }

  @override
  String get guideCollectionTitle => 'Tu recorrido y tus diseños';

  @override
  String get guideCollectionBody =>
      'Las misiones semanales y los eventos gratuitos desbloquean diseños. Revísalos y aplícalos en Mi colección. Las compras opcionales personalizan la tarjeta; no cambian tu puntuación.';

  @override
  String get collectionPreviewNotice =>
      'Vista previa · sin cambiar tus elementos en uso.';

  @override
  String get commercePlusTerms =>
      'Compra única · sin interrupciones, con marco y tarjeta exclusivos.';

  @override
  String get commerceCollectionTerms =>
      'Compra única · 2 avatares, 3 marcos y 1 tarjeta.';

  @override
  String get commerceSubscriptionActive => 'Suscripción activa';

  @override
  String get earnTickets => 'Ganar tickets';

  @override
  String get earnTicketsSubtitle => 'Vídeos opcionales, más partidas';

  @override
  String get commerceComingSoon => 'Próximamente';

  @override
  String get adSpaceLabel => 'Publicidad';

  @override
  String get adSpaceReserved => 'Espacio reservado para anuncios';

  @override
  String get rewardedLoading => 'Preparando vídeo…';

  @override
  String get rewardedUnavailable => 'No hay vídeos disponibles ahora.';

  @override
  String get rewardedLimitReached => 'Ya usaste los vídeos de hoy.';

  @override
  String get rewardedPlaceholderBody => 'Mira un vídeo y gana tickets extra.';

  @override
  String get rewardedRetry => 'Cargar vídeo';

  @override
  String get rewardedFailed => 'No se pudo completar. Inténtalo de nuevo.';

  @override
  String get rewardedCancelled => 'Recompensa aún sin confirmar.';

  @override
  String get rewardedWatching => 'Esperando recompensa…';

  @override
  String get rewardedPreviewLabel => 'Vídeo con recompensa · próximamente';

  @override
  String get ticketPacksTitle => 'Paquetes de tickets';

  @override
  String get ticketPackSmall => '20 tickets';

  @override
  String get ticketPackLarge => '60 tickets';

  @override
  String get ticketPacksNote => 'Más partidas sin esperar la recarga diaria.';

  @override
  String get seasonIntro =>
      'Juega, completa misiones y descubre tu próximo personaje.';

  @override
  String get seasonCurrent => 'Esta temporada';

  @override
  String get seasonNext => 'Próximamente';

  @override
  String get seasonFinished => 'Finalizada';

  @override
  String get seasonEmpty => 'Vienen nuevas temporadas.';

  @override
  String get seasonItems => 'Seis estilos por descubrir';

  @override
  String get seasonTry => 'Explorar colección';

  @override
  String get seasonPreviewTitle => 'Prueba los estilos';

  @override
  String seasonAvailableOn(String date) {
    return 'Llega el $date';
  }

  @override
  String seasonUntil(String date) {
    return 'Hasta el $date';
  }

  @override
  String seasonOwnedCount(int count, int total) {
    return '$count de $total en tu colección';
  }

  @override
  String get seasonEventTitle => 'Evento gratuito';

  @override
  String get seasonEventDemo => 'Evento de demostración';

  @override
  String get seasonStoreSoon => 'Las colecciones estarán disponibles pronto.';

  @override
  String get commerceOptionalExtras => 'Juega a tu manera';

  @override
  String get commerceOptionalBody =>
      'Tickets para seguir jugando y una opción para quitar anuncios comunes. Los videos con recompensa siguen siendo opcionales.';

  @override
  String get ticketLearnMore => 'Sobre los tickets';

  @override
  String get commerceLoading => 'Cargando opciones…';

  @override
  String get commerceCheckFailed => 'No se pudieron verificar tus compras.';

  @override
  String get commerceOffersFailed => 'No se pudo cargar la tienda.';

  @override
  String get commerceNoOffers => 'No hay ofertas disponibles ahora.';

  @override
  String get commerceRestoreDone => 'Compras restauradas.';

  @override
  String get commerceRestoreEmpty => 'No se confirmaron compras activas.';

  @override
  String get commerceBenefitsActive => 'Ventajas activas';

  @override
  String get commerceAdFreeActive =>
      'Publicidad eliminada. Los vídeos con recompensa siguen siendo opcionales.';

  @override
  String get collectionHowToGet => 'Cómo conseguirlo';

  @override
  String get collectionOnlyOwned => 'Mis artículos';

  @override
  String get collectionAllItems => 'Todos los artículos';

  @override
  String get collectionUnlockMission =>
      'Completa misiones semanales para desbloquear este estilo.';

  @override
  String get collectionUnlockEvent =>
      'Este estilo es la recompensa de un evento.';

  @override
  String get collectionUnlockSeason =>
      'Encuentra esta colección en Temporadas.';

  @override
  String get collectionUnlockSoon =>
      'Este estilo estará disponible en la tienda próximamente.';

  @override
  String get collectionUnlocked => 'Desbloqueado';

  @override
  String get helpTitle => '¿Necesitas ayuda?';

  @override
  String get helpUseTicket => 'Usar 1 ticket';

  @override
  String get helpWatch => 'Vídeo · ayuda + 1 ticket';

  @override
  String get helpVideoSoon => 'Vídeo próximamente';

  @override
  String get helpVideoUsed => 'Vídeo ya usado en esta partida';

  @override
  String get helpVideoTerms =>
      '1 por partida · comparte el límite diario de vídeos.';

  @override
  String get helpPending => 'Confirmando recompensa…';

  @override
  String get helpPendingBody =>
      'Puedes seguir jugando. La recompensa se recuperará al confirmarse.';

  @override
  String get helpClaim => 'Recibir ayuda';

  @override
  String get helpStored => 'Los 2 tickets quedaron en tu saldo.';

  @override
  String get helpDone => 'Ayuda desbloqueada. +1 ticket en el saldo.';

  @override
  String get helpNoAvailable => 'Ya has usado todas las ayudas disponibles.';

  @override
  String get helpColorGuidance => 'Orientación de color';

  @override
  String get helpColorGuidanceBody =>
      'Una sugerencia de tono y ajuste. −1 punto en esta ronda.';

  @override
  String get helpColorSimple => 'Pista rápida';

  @override
  String get helpColorSimpleBody => 'Pista del personaje · −1 punto';

  @override
  String get helpAdOffer =>
      'Mira un anuncio para desbloquear esta ayuda y guardar 1 ticket.';

  @override
  String helpColorFamily(String family) {
    return 'Prueba la familia de $family.';
  }

  @override
  String get helpFamilyRed => 'rojos';

  @override
  String get helpFamilyOrange => 'naranjas';

  @override
  String get helpFamilyYellow => 'amarillos';

  @override
  String get helpFamilyGreen => 'verdes';

  @override
  String get helpFamilyCyan => 'cianes';

  @override
  String get helpFamilyBlue => 'azules';

  @override
  String get helpFamilyPurple => 'morados';

  @override
  String get helpFamilyPink => 'rosas';

  @override
  String get helpFamilyNeutral => 'tonos neutros';

  @override
  String get helpBrighter => 'Aumenta un poco el brillo.';

  @override
  String get helpDarker => 'Reduce un poco el brillo.';

  @override
  String get helpMoreSaturation => 'Aumenta un poco la intensidad.';

  @override
  String get helpLessSaturation => 'Reduce un poco la intensidad.';

  @override
  String get helpAdjustClose => 'Los ajustes están cerca; afina el tono.';

  @override
  String get archiveMode => 'Archivo';

  @override
  String get practiceMode => 'Práctica';

  @override
  String get activityAll => 'Todas las partidas';

  @override
  String get activityDaily => 'Diarios';

  @override
  String get activityStage => 'Etapas';

  @override
  String get activityInvites => 'Invitaciones';

  @override
  String get activityContext => 'Actividad';

  @override
  String get presenceStreak => 'Días consecutivos jugando';

  @override
  String get nextGoal => 'Tu próxima meta';

  @override
  String get continueGame => 'Continuar partida';

  @override
  String get practiceAgain => 'Repasar en práctica';

  @override
  String get masteryTitle => 'Tu dominio';

  @override
  String get archiveTitle => 'Diarios anteriores';

  @override
  String get archiveDescription =>
      'Juega a tu ritmo sin cambiar el resultado de hoy.';

  @override
  String get editorialFeedback => 'Informar de un problema';

  @override
  String get feedbackSent => '¡Gracias! Informe guardado para revisión.';

  @override
  String get feedbackClue => 'Pista o respuesta';

  @override
  String get feedbackArtwork => 'Imagen o personaje';

  @override
  String get feedbackDifficulty => 'Dificultad';

  @override
  String get feedbackOther => 'Otro problema';

  @override
  String get feedbackNote => 'Descripción opcional';

  @override
  String get sendFeedback => 'Enviar informe';

  @override
  String get neutralCard => 'Ocultar respuesta';

  @override
  String get quickStart => 'Jugar un ejemplo';

  @override
  String get backupTitle => 'Tu progreso';

  @override
  String get backupSave => 'Guardar copia';

  @override
  String get backupRestore => 'Restaurar copia';

  @override
  String get backupCode => 'Clave de recuperación';

  @override
  String get backupSaved => 'Respaldo guardado.';

  @override
  String get backupConfirm =>
      '¿Restaurar este progreso? Se combinará con el progreso local.';

  @override
  String get metricsConsent => 'Compartir datos de uso';

  @override
  String get metricsConsentBody =>
      'Ayuda a mejorar el juego. No se envían tus intentos ni nombres.';

  @override
  String get metricsDelete => 'Borrar datos de uso';

  @override
  String get friendGames => 'Desafíos entre amigos';

  @override
  String get friendJoin => 'Abrir invitación';

  @override
  String get friendCreate => 'Crear desafío';

  @override
  String get connectedRequired => 'Conéctate para usar esta función.';

  @override
  String get missionDuplicate => 'Ya adquirido · recompensa alternativa';

  @override
  String get itemMissionCapybara => 'Breno Efeito-Bruto';

  @override
  String get itemMissionAxolotl => 'Bento Rolo-Perdido';

  @override
  String get itemMissionPenguin => 'Glifo Caça-Cenas';

  @override
  String get archiveMore => 'Ver más días';

  @override
  String get masteryEmpty => 'Completa partidas para descubrir tus temas.';

  @override
  String get playerDataTitle => 'Datos y recuperación';

  @override
  String get dataActionFailed =>
      'No se pudo completar la acción. Inténtalo de nuevo.';

  @override
  String get backupRestored => 'Progreso recuperado.';

  @override
  String get recoveryKeepPrivate =>
      'Guarda esta clave en un lugar seguro. Permite recuperar datos y compras. No la compartas.';

  @override
  String get backupScope =>
      'Guarda partidas, etapas e historial. Los tickets comprados se recuperan del servidor; los diarios y bonos de este dispositivo son locales.';

  @override
  String get recoverAnotherDevice => 'Recuperar de otro dispositivo';

  @override
  String get backupDelete => 'Borrar copia de la nube';

  @override
  String get backupDeleteConfirm =>
      '¿Borrar la copia guardada? Se conserva el progreso de este dispositivo.';

  @override
  String get metricsDeletionQueued =>
      'Datos locales eliminados. La eliminación en línea está pendiente.';

  @override
  String get friendActionFailed =>
      'No se pudo abrir la invitación. Revisa el código, la conexión y disponibilidad.';

  @override
  String get friendPlayFirst =>
      'Completa una partida de Pistas o Póster para crear un reto.';

  @override
  String get friendChooseGame => 'Elige una partida terminada';

  @override
  String get friendCreated => 'Invitación válida por 7 días';

  @override
  String get friendPrivateRules =>
      'Un reto privado con la misma partida. Puntuaciones del dispositivo, sin clasificación ni premios.';

  @override
  String get friendYou => 'Tú';

  @override
  String get friendOther => 'Amigo';

  @override
  String get nextAction => 'Siguiente';

  @override
  String get purchasedTickets => 'Comprados';

  @override
  String ticketPackAmount(int count) {
    return '$count tickets';
  }

  @override
  String get ticketPackTerms =>
      'Compra única. No caducan; requieren conexión para usarlos y recuperarlos. No aumentan la puntuación.';

  @override
  String missionPlayCount(int count) {
    return 'Completa $count partidas';
  }

  @override
  String missionModesCount(int count) {
    return 'Juega en $count modos';
  }

  @override
  String missionDaysCount(int count) {
    return 'Juega en $count días';
  }

  @override
  String masteryStageTitle(int count) {
    return 'Guardián de la etapa $count';
  }

  @override
  String get masteryTitles => 'Títulos obtenidos';

  @override
  String get masteryAnimation => 'Animación';

  @override
  String get masteryFantasy => 'Fantasía';

  @override
  String get masteryClassics => 'Clásicos hasta 1989';

  @override
  String get assistedResult => 'Con ayuda';

  @override
  String presenceDays(int count) {
    return '$count días jugados';
  }

  @override
  String resultScoreScale(int score, int total) {
    return '$score/$total puntos';
  }

  @override
  String stageBonusOffer(int count) {
    return 'Al completar: +$count tickets';
  }

  @override
  String stageBonusTitleOffer(int count) {
    return 'Al completar: +$count tickets y un título';
  }

  @override
  String get manageProgress => 'Gestionar progreso';

  @override
  String get progressOnDevice =>
      'Guardado automáticamente en este dispositivo.';

  @override
  String get backupCloudUnavailable => 'Respaldo en la nube próximamente.';

  @override
  String get backupCloudChecking => 'Consultando respaldo…';

  @override
  String get backupCloudEmpty => 'Aún no tienes un respaldo en la nube.';

  @override
  String get backupCloudError => 'No se pudo consultar el respaldo.';

  @override
  String backupCloudLastSaved(String date) {
    return 'En la nube · $date';
  }

  @override
  String get backupOptions => 'Recuperación y otras opciones';

  @override
  String get backupDeleted =>
      'Respaldo de la nube eliminado. Tu progreso local se conservó.';

  @override
  String get metricsDeletedLocal =>
      'Datos de uso de este dispositivo eliminados.';

  @override
  String get metricsDeleted => 'Datos de uso eliminados.';

  @override
  String get metricsUnavailable =>
      'El envío de datos está desactivado en esta versión.';

  @override
  String get journeyMasteryShortcut => 'Dominio';

  @override
  String get journeyFriendsShortcut => 'Amigos';

  @override
  String get audienceTitle => 'Tu rango de edad';

  @override
  String get audienceBody =>
      'Cineus está pensado para personas a partir de 16 años.';

  @override
  String get audiencePrivacy =>
      'Solo guardamos tu rango de edad, no tu fecha de nacimiento. Las compras están destinadas a adultos.';

  @override
  String get audienceUnder16 => 'Tengo menos de 16 años';

  @override
  String get audienceTeen => 'Tengo 16 o 17 años';

  @override
  String get audienceAdult => 'Tengo 18 años o más';

  @override
  String get audienceUnavailable =>
      'Esta versión está destinada a personas a partir de 16 años.';

  @override
  String get audiencePurchases => 'Compras disponibles para mayores de 18 años';

  @override
  String get showcaseAnimation => 'Mundos animados';

  @override
  String get showcaseFantasy => 'Más allá de la imaginación';

  @override
  String get showcaseClassics => 'Clásicos en cartel';

  @override
  String get showcasePlay => 'Elegir partidas';

  @override
  String get showcasePractice =>
      'Una selección para jugar a tu ritmo. Tu avance se guarda.';

  @override
  String get showcaseRewards =>
      'Los estilos rotan entre las recompensas de misiones. Lo que ya tienes sigue siendo tuyo.';

  @override
  String showcaseFilm(int number) {
    return 'Película $number';
  }
}
