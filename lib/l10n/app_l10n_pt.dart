// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppL10nPt extends AppL10n {
  AppL10nPt([String locale = 'pt']) : super(locale);

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
    return '🎬 Cineus #$challenge\nAcertei na dica $clue/$total · ${score}pts\n\n$grid\n\ncineus.app';
  }

  @override
  String shareLose(Object challenge, Object grid) {
    return '🎬 Cineus #$challenge · Derrota\n\n$grid\n\ncineus.app';
  }

  @override
  String get semBack => 'Voltar';

  @override
  String get semStats => 'Ver estatísticas';

  @override
  String get semHelp => 'Como jogar';

  @override
  String semGuessThisMovie(Object title) {
    return 'Palpitar $title';
  }

  @override
  String semTicketBalance(int count) {
    return '$count tickets disponíveis';
  }

  @override
  String get reminderTitle => 'Cineus';

  @override
  String get reminderBody =>
      'O desafio de hoje está no ar. Quantas dicas você vai precisar?';

  @override
  String get reminderSettingTitle => 'Lembrete diário';

  @override
  String get reminderSettingSubtitle => 'Um aviso às 9h, no seu horário';

  @override
  String get reminderDenied =>
      'As notificações estão bloqueadas. Libere nas configurações do sistema para ativar.';

  @override
  String get challengeSectionTitle => 'Desafiar um amigo';

  @override
  String get challengeShareButton => 'Desafiar um amigo';

  @override
  String challengeShareText(Object code, Object link) {
    return '🎬 Cineus: aposto que você não acerta esse filme.\nCódigo: $code\n$link';
  }

  @override
  String get challengeOpenTitle => 'Abrir um desafio';

  @override
  String get challengeCodeHint => 'CIN-0000';

  @override
  String get challengeOpen => 'Abrir';

  @override
  String get challengeInvalid =>
      'Código inválido. Confira as letras e tente de novo.';

  @override
  String get challengeBadge => 'DESAFIO DE AMIGO';

  @override
  String get challengeFilmNotFound =>
      'Esse desafio aponta para um filme que não está nesta versão do app.';

  @override
  String get appTagline =>
      'Adivinha o filme em até 10 dicas.\nQuanto menos usar, mais pontos.';

  @override
  String get splashCredits => 'CINEUS v1.0 · FLUTTER · DART · TMDB';

  @override
  String get navHome => 'Início';

  @override
  String get navFilms => 'Filmes';

  @override
  String get navPosters => 'Posters';

  @override
  String get back => 'Voltar';

  @override
  String get backHome => 'Voltar ao Início';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String errorWithMessage(Object message) {
    return 'Erro: $message';
  }

  @override
  String get movieNotFound => 'Filme não encontrado';

  @override
  String get noMoviesInDatabase => 'Nenhum filme na base';

  @override
  String get dailyChallengeLabel => 'DESAFIO DIÁRIO';

  @override
  String get modeClues => 'Dicas';

  @override
  String get modePoster => 'Poster';

  @override
  String get notPlayedToday => 'Não jogado hoje';

  @override
  String get inProgressEllipsis => 'Em andamento...';

  @override
  String scoreWithCheck(int score) {
    return '$score pts ✅';
  }

  @override
  String get notThisTimeSkull => 'Não foi dessa vez 💀';

  @override
  String get dailyDone => 'Desafio de hoje concluído!';

  @override
  String get playChallenge => 'Jogar Desafio';

  @override
  String get continueClues => 'Continuar Dicas';

  @override
  String get playPoster => 'Jogar Poster';

  @override
  String nextChallengeCountdown(Object hours, Object minutes, Object seconds) {
    return 'Próximo em ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String get statPlayed => 'Jogados';

  @override
  String get statWins => 'Vitórias';

  @override
  String get statStreak => 'Sequência';

  @override
  String get quickActionStages => 'Estágios';

  @override
  String get quickActionStagesSub => 'Filmes por nível';

  @override
  String get quickActionStatsSub => 'Seu histórico';

  @override
  String get cluesHeader => 'DICAS';

  @override
  String cluesRevealed(int count, int total) {
    return '$count / $total reveladas';
  }

  @override
  String clueFallback(int number) {
    return 'Dica $number';
  }

  @override
  String get clueNew => 'NOVO';

  @override
  String tryAnswerClue(int clue) {
    return 'Tentar Responder · Dica $clue';
  }

  @override
  String get lastAttempt => 'Última tentativa!';

  @override
  String skipToClue(int next) {
    return 'Pular · ver dica $next (−1 pt)';
  }

  @override
  String get fewPointsLeft => 'Poucos pontos restantes!';

  @override
  String get lastClueNowOrNever => 'Última dica! É agora ou nunca.';

  @override
  String get youGotIt => 'Você acertou! ✅';

  @override
  String get notThisTime => 'Não foi dessa vez.';

  @override
  String scoreLine(int score) {
    return 'Pontuação: $score pts';
  }

  @override
  String get tryAgainTomorrow => 'Tente novamente amanhã.';

  @override
  String get seeResult => 'Ver Resultado';

  @override
  String stageNumber(Object id) {
    return 'Estágio $id';
  }

  @override
  String get franchiseHint => 'Quase! É dessa franquia, mas é outro filme!';

  @override
  String get scorePoints => 'PONTOS';

  @override
  String get scoreAvailable => 'disponíveis';

  @override
  String get scoreHintMax => 'Acerte agora e leve o máximo';

  @override
  String scoreHintStillWorth(int revealed) {
    return '$revealed dicas reveladas · ainda vale a pena';
  }

  @override
  String get scoreHintRunningOut => 'Atenção — os pontos estão acabando';

  @override
  String scoreHintNextLeaves(int next, int points) {
    return 'Revelar dica $next te deixa com apenas ${points}pt';
  }

  @override
  String get scoreHintLastChance => 'Última chance — vale apenas 1pt';

  @override
  String get whichMovie => 'Qual é o filme?';

  @override
  String get movieNameHint => 'Nome do filme...';

  @override
  String get attemptsHeader => 'TENTATIVAS';

  @override
  String errorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erros',
      one: '1 erro',
    );
    return '$_temp0';
  }

  @override
  String searchChallenge(Object number) {
    return 'Desafio #$number · ';
  }

  @override
  String searchPoints(int points) {
    return '$points pontos';
  }

  @override
  String get searchAvailableSuffix => ' disponíveis';

  @override
  String get blurLabel => 'Desfoque ';

  @override
  String get resultWin => '🎉 ACERTOU!';

  @override
  String get resultLose => '💔 NÃO FOI DESSA VEZ';

  @override
  String get theMovieWas => 'O FILME ERA';

  @override
  String gotItOnClue(int clue) {
    return 'Acertou na $clueª dica!';
  }

  @override
  String get yourResult => 'SEU RESULTADO';

  @override
  String get share => 'Compartilhar';

  @override
  String get resultShared => 'Resultado compartilhado! 🎬';

  @override
  String get resultCopied => 'Resultado copiado! 📋';

  @override
  String get playPosterArrow => 'Jogar Poster →';

  @override
  String get nextFilmCost => 'Próximo Filme · 1 🎫';

  @override
  String get noTicketsForNext => 'Sem 🎫 para o próximo';

  @override
  String get nextChallengeIn => 'PRÓXIMO DESAFIO EM';

  @override
  String get stagesSubtitleClues =>
      'Complete os estágios para desbloquear mais filmes.';

  @override
  String get stagesSubtitlePosters =>
      'Adivinhe os filmes pelo poster desfocado.';

  @override
  String get stageWord => 'ESTÁGIO';

  @override
  String get locked => 'Bloqueado';

  @override
  String filmsCount(int count) {
    return '$count filmes';
  }

  @override
  String stageSemanticsLocked(Object name) {
    return '$name, bloqueado';
  }

  @override
  String stageSemanticsComplete(Object name) {
    return '$name, completo';
  }

  @override
  String stageSemanticsProgress(Object name, int done, int total) {
    return '$name, $done de $total concluídos';
  }

  @override
  String get filmsDone => 'filmes concluídos';

  @override
  String get postersDone => 'posters concluídos';

  @override
  String stageProgressLine(int done, int total, Object label) {
    return '$done / $total $label';
  }

  @override
  String get itemFilm => 'Filme';

  @override
  String get itemPoster => 'Poster';

  @override
  String get slotNotStarted => 'Não iniciado • 1 🎫';

  @override
  String get slotMissedRetry => 'Não acertou • 1 🎫 para rejogar';

  @override
  String get slotInProgress => 'Em andamento';

  @override
  String slotPoints(int score) {
    return '$score pontos';
  }

  @override
  String get slotCompleted => 'Concluído';

  @override
  String get actionPlay => 'Jogar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionRetry => 'Tentar';

  @override
  String get noTicketsShort => 'Sem 🎫';

  @override
  String get revealMore => 'Revelar mais · −1 pt';

  @override
  String tryAnswerPoints(int points) {
    return 'Tentar Responder · $points pts';
  }

  @override
  String get wrongAttemptsHeader => 'TENTATIVAS ERRADAS';

  @override
  String worthPoints(int points) {
    return 'Vale $points pts';
  }

  @override
  String get gameOver => 'Game Over';

  @override
  String gotItAtLevel(int level) {
    return 'Acertou no nível $level!';
  }

  @override
  String get betterLuckTomorrow => 'Melhor sorte amanhã';

  @override
  String blurAndPoints(Object blur, int points) {
    return 'Desfoque $blur · $points pts';
  }

  @override
  String get youRecognized => 'Você reconheceu!';

  @override
  String get didntRecognize => 'Não reconheceu';

  @override
  String itWas(Object title) {
    return 'Era: $title';
  }

  @override
  String pointsPlain(int score) {
    return '$score pontos';
  }

  @override
  String get youDidntGuess => 'Você não adivinhou';

  @override
  String get nextWithTicket => 'Próximo · 1 🎫';

  @override
  String get finish => 'Concluir';

  @override
  String get extraHintsHeader => 'DICAS EXTRAS';

  @override
  String get extraHintsNoPointCost => 'não custam pontos';

  @override
  String get hintDirector => 'Diretor';

  @override
  String get hintYear => 'Ano';

  @override
  String get hintRuntime => 'Duração';

  @override
  String get unknownDirector => 'Desconhecido';

  @override
  String runtimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get oneTicket => '1 🎫';

  @override
  String get noTicketsLower => 'sem 🎫';

  @override
  String get noTicketsForHint => 'Sem tickets para comprar dica';

  @override
  String buyHintSemantics(Object label, int cost) {
    return 'Comprar dica $label por $cost ticket';
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
  String get rewardDailyWin => 'Desafio diário concluído';

  @override
  String rewardStreak(int days) {
    return 'Sequência de $days dias';
  }

  @override
  String rewardStageComplete(int id) {
    return 'Estágio $id completo';
  }

  @override
  String get streakAtRisk => 'Sua sequência está em risco';

  @override
  String streakRecoverBody(Object day, int cost) {
    return 'Você não jogou em $day. Gaste $cost 🎫 para proteger esse dia e manter a sequência.';
  }

  @override
  String protectStreak(int cost) {
    return 'Proteger sequência · $cost 🎫';
  }

  @override
  String get protecting => 'Protegendo…';

  @override
  String needTickets(int cost) {
    return 'Precisa de $cost 🎫';
  }

  @override
  String get streakProtected => 'Sequência protegida! 🔥';

  @override
  String get statGames => 'JOGOS';

  @override
  String get statWinsCaps => 'VITÓRIAS';

  @override
  String get statRate => 'TAXA';

  @override
  String get statAverage => 'MÉDIA';

  @override
  String get statAverageSub => 'dicas';

  @override
  String get currentStreakTitle => 'Sequência Atual';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'Melhor';

  @override
  String get playToSeeDistribution => 'Jogue para ver a distribuição';

  @override
  String get pointsDistribution => 'DISTRIBUIÇÃO DE PONTOS';

  @override
  String get achievementsHeader => 'CONQUISTAS';

  @override
  String get yourProfileHeader => 'SEU PERFIL';

  @override
  String profileSummary(Object best, int bestPct, Object worst, int worstPct) {
    return 'Você vai melhor em $best ($bestPct%) e pior em $worst ($worstPct%).';
  }

  @override
  String get byGenre => 'Por gênero';

  @override
  String get byDecade => 'Por década';

  @override
  String get recentGamesHeader => 'JOGOS RECENTES';

  @override
  String get unknownMovie => 'Filme desconhecido';

  @override
  String cluesUsedCount(int count) {
    return '$count dicas';
  }

  @override
  String get defeatShort => 'Derrota';

  @override
  String bucketSemantics(Object label, int pct, int played) {
    return '$label: $pct por cento de acerto em $played jogos';
  }

  @override
  String bucketValue(int pct, int played) {
    return '$pct% · $played';
  }

  @override
  String get achievementUnlocked => 'Desbloqueada';

  @override
  String achievementInProgress(Object progress) {
    return 'Em progresso $progress';
  }

  @override
  String get achFirstWin => 'Primeira vitória';

  @override
  String get achFirstWinDesc => 'Acerte seu primeiro desafio diário.';

  @override
  String get achPerfect => 'Sem titubear';

  @override
  String get achPerfectDesc => 'Acerte na primeira dica, valendo 10 pontos.';

  @override
  String get achStreak7 => 'Semana cheia';

  @override
  String get achStreak7Desc => '7 dias seguidos acertando.';

  @override
  String get achStreak30 => 'Mês perfeito';

  @override
  String get achStreak30Desc => '30 dias seguidos acertando.';

  @override
  String get achGames50 => 'Frequentador';

  @override
  String get achGames50Desc => 'Jogue 50 desafios diários.';

  @override
  String get achStages5 => 'Maratonista';

  @override
  String get achStages5Desc => 'Complete 5 estágios.';

  @override
  String get achTickets100 => 'Bilheteria';

  @override
  String get achTickets100Desc => 'Ganhe 100 tickets jogando.';

  @override
  String get quickGuide => 'GUIA RÁPIDO';

  @override
  String get howItWorks => 'Como funciona\no Cineus';

  @override
  String get rule1Title => '10 dicas progressivas';

  @override
  String get rule1Desc =>
      'Cada desafio tem 10 dicas, da mais abstrata e conceitual até a mais óbvia. Você escolhe quando revelar a próxima.';

  @override
  String get rule2Title => 'Menos dicas = mais pontos';

  @override
  String get rule2Desc =>
      'Cada dica revelada custa 1 ponto. Acerte na primeira e ganhe 10; na décima, apenas 1.';

  @override
  String get rule3Title => 'Busca com autocomplete';

  @override
  String get rule3Desc =>
      'Digite o título no campo de busca — não precisa acertar acentos nem a grafia exata. Vale o título em português ou o original.';

  @override
  String get rule4Title => 'Um desafio por dia';

  @override
  String get rule4Desc =>
      'Novo filme todo dia à meia-noite UTC. Compartilhe seu resultado sem spoilers e compare com amigos.';

  @override
  String get gotItLetsPlay => 'Entendi, vamos jogar!';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get contentLanguageNote =>
      'As dicas e os títulos dos filmes vêm do catálogo em português.';

  @override
  String tickets(int current, int max) {
    return '$current/$max';
  }
}
