// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppL10nPt extends AppL10n {
  AppL10nPt([String locale = 'pt']) : super(locale);

  @override
  String get colorModeTitle => 'Cores';

  @override
  String colorRecallPart(String part) {
    return 'Lembre a cor: $part';
  }

  @override
  String get colorYourTone => 'Seu tom';

  @override
  String get colorHue => 'Tom';

  @override
  String get colorSaturation => 'Intensidade';

  @override
  String get colorBrightness => 'Brilho';

  @override
  String get colorRulesAction => 'Como funciona';

  @override
  String get colorRulesTitle => 'Cinco cores. Uma memória.';

  @override
  String get colorCatalogFailed => 'Não foi possível carregar as perguntas.';

  @override
  String get colorRetry => 'Tentar novamente';

  @override
  String get colorClose => 'Entendi';

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
    return '🎬 Cineus #$challenge\nAcertei na dica $clue/$total · ${score}pts\n\n$grid';
  }

  @override
  String get semBack => 'Voltar';

  @override
  String get semStats => 'Ver estatísticas';

  @override
  String get semHelp => 'Como jogar';

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
  String get reminderFailed =>
      'Não foi possível atualizar o lembrete. Tente novamente.';

  @override
  String get fontLicensesTitle => 'Licenças das fontes';

  @override
  String get fontLicenseFailed =>
      'Não foi possível abrir a licença. Tente novamente.';

  @override
  String get rewardFailed =>
      'Não foi possível adicionar a recompensa agora. Seu resultado está salvo.';

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
      'Adivinhe filmes por dicas ou pôsteres.\nRelembre cores e avance por estágios.';

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
  String get settingsTitle => 'Configurações';

  @override
  String get movieNotFound => 'Filme não encontrado';

  @override
  String get noMoviesInDatabase => 'Nenhum filme na base';

  @override
  String get gameLoadFailed => 'Não foi possível carregar a partida.';

  @override
  String get loadingGame => 'Carregando partida…';

  @override
  String get retryAction => 'Tentar novamente';

  @override
  String get statsLoadFailed => 'Não foi possível carregar suas estatísticas.';

  @override
  String get stageNotFound =>
      'Este estágio não existe ou não está mais disponível.';

  @override
  String get backToStages => 'Voltar aos Estágios';

  @override
  String get dailyChallengeLabel => 'DESAFIO DIÁRIO';

  @override
  String get modeClues => 'Dicas';

  @override
  String get modePoster => 'Poster';

  @override
  String get dailyDone => 'Desafio de hoje concluído!';

  @override
  String nextChallengeCountdown(Object hours, Object minutes, Object seconds) {
    return 'Próximo em ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String get statPlayed => 'Jogados';

  @override
  String get statWins => 'Vitórias';

  @override
  String get quickActionStatsSub => 'Seu histórico';

  @override
  String get homeOpenChallenge => 'Abrir desafio';

  @override
  String get homeOpenChallengeSub => 'Por código ou link';

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
  String get lastAttempt => 'Última tentativa!';

  @override
  String skipToClue(int next) {
    return 'Pular · ver dica $next (−1 pt)';
  }

  @override
  String get youGotIt => 'Você acertou!';

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
  String searchStage(int id) {
    return 'Estágio $id · ';
  }

  @override
  String get searchFriendChallenge => 'Desafio de amigo · ';

  @override
  String searchPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pontos',
      one: '1 ponto',
    );
    return ' · $_temp0';
  }

  @override
  String get searchAvailableSuffix => ' em jogo';

  @override
  String get searchTypeHint => 'Digite pelo menos 2 letras para buscar.';

  @override
  String get searchNoResults => 'Nenhum filme encontrado.';

  @override
  String get searchFailed => 'Não foi possível buscar agora.';

  @override
  String get blurLabel => 'Desfoque ';

  @override
  String get share => 'Compartilhar';

  @override
  String get resultShared => 'Resultado compartilhado!';

  @override
  String get resultCopied => 'Resultado copiado!';

  @override
  String get noTicketsForNext => 'Sem tickets para o próximo';

  @override
  String get nextChallengeIn => 'PRÓXIMO DESAFIO EM';

  @override
  String get stagesSubtitleClues =>
      'Avance por estágios e desbloqueie novos filmes.';

  @override
  String get stagesSubtitlePosters =>
      'Adivinhe filmes por pôsteres desfocados.';

  @override
  String get locked => 'Bloqueado';

  @override
  String filmsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes',
      one: '1 filme',
      zero: '0 filmes',
    );
    return '$_temp0';
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
  String get slotNotStarted => 'Não iniciado';

  @override
  String get slotMissedRetry => 'Não acertou';

  @override
  String get slotInProgress => 'Em andamento';

  @override
  String slotPoints(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score pontos',
      one: '1 ponto',
      zero: '0 pontos',
    );
    return '$_temp0';
  }

  @override
  String get actionContinue => 'Continuar';

  @override
  String get noTicketsShort => 'Sem tickets';

  @override
  String get revealMore => 'Revelar mais · −1 pt';

  @override
  String worthPoints(int points) {
    return 'Vale $points pts';
  }

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
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score pontos',
      one: '1 ponto',
      zero: '0 pontos',
    );
    return '$_temp0';
  }

  @override
  String get youDidntGuess => 'Você não adivinhou';

  @override
  String get nextWithTicket => 'Próximo · 1 ticket';

  @override
  String get finish => 'Concluir';

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
  String get oneTicket => '1 ticket';

  @override
  String get noTicketsLower => 'sem tickets';

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
    return 'Você não jogou em $day. Use $cost tickets para proteger esse dia e manter a sequência.';
  }

  @override
  String protectStreak(int cost) {
    return 'Proteger sequência · $cost tickets';
  }

  @override
  String get protecting => 'Protegendo…';

  @override
  String needTickets(int cost) {
    return 'Precisa de $cost tickets';
  }

  @override
  String get streakProtected => 'Sequência protegida!';

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
  String get statAveragePosterSub => 'níveis';

  @override
  String get currentStreakTitle => 'Sequência Atual';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
      zero: '0 dias',
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dicas',
      one: '1 dica',
      zero: '0 dicas',
    );
    return '$_temp0';
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
  String get gotItLetsPlay => 'Entendi, vamos jogar!';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get contentLanguageNote =>
      'As dicas e os títulos dos filmes vêm do catálogo em português.';

  @override
  String get rewardedTitle => 'Ganhar tickets';

  @override
  String rewardedBody(int amount, int remaining) {
    return 'Assista a um anúncio opcional e ganhe $amount tickets. Restam $remaining recompensas hoje.';
  }

  @override
  String rewardedAction(int amount) {
    return 'Assistir e ganhar +$amount tickets';
  }

  @override
  String get rewardedDone => 'Tickets adicionados!';

  @override
  String get passTitle => 'Cineus Pass';

  @override
  String get passBody =>
      'Todo o gameplay continua gratuito. O Pass remove anúncios não opcionais e pode incluir benefícios de conveniência.';

  @override
  String get passActive => 'Pass ativo · sem anúncios não opcionais';

  @override
  String passGet(String price) {
    return 'Obter Pass $price';
  }

  @override
  String get passRestore => 'Restaurar compra';

  @override
  String tickets(int current, int max) {
    return '$current/$max';
  }

  @override
  String get homeTitle => 'Cinema, todo dia.';

  @override
  String get dailyFree => 'GRÁTIS';

  @override
  String dailyWinPoints(int score) {
    return '$score pontos · Acertou';
  }

  @override
  String get dailyLost => 'Concluído · Não foi desta vez';

  @override
  String get dailyPlaying => 'Partida em andamento';

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
  String get ticketDetailsTitle => 'Seus tickets';

  @override
  String get ticketDaily => 'Diários';

  @override
  String get ticketBonus => 'Bônus';

  @override
  String ticketDailyDetail(int count, int max) {
    return '$count de $max';
  }

  @override
  String get ticketResetInfo =>
      'Os tickets diários são repostos na virada UTC. Os bônus continuam com você.';

  @override
  String get ticketUsageInfo =>
      'Daily e desafios de amigos são gratuitos. Iniciar ou refazer um filme de estágio e cada dica extra custam 1 ticket.';

  @override
  String get ticketBalanceFailed => 'Não foi possível carregar seu saldo.';

  @override
  String ticketResetCountdown(Object hours, Object minutes) {
    return 'Reposição em ${hours}h ${minutes}m';
  }

  @override
  String get confirmGuess => 'Confirmar palpite';

  @override
  String get selectedMovieLabel => 'Filme selecionado';

  @override
  String selectMovieSemantics(Object title, int year) {
    return 'Selecionar $title, $year';
  }

  @override
  String get guessSaveFailed =>
      'Não foi possível salvar seu palpite. Tente novamente.';

  @override
  String get savingGuess => 'Salvando palpite…';

  @override
  String get gameActionFailed =>
      'Não foi possível salvar a ação. Tente novamente.';

  @override
  String get hintSaveFailed =>
      'Não foi possível concluir a compra da dica. Confira seu saldo e tente novamente.';

  @override
  String get wrongGuessRevealed => 'Palpite incorreto. Novo passo revelado.';

  @override
  String clueRevealedAnnouncement(int number) {
    return 'Dica $number revelada.';
  }

  @override
  String posterRevealedAnnouncement(int number) {
    return 'Nível $number revelado.';
  }

  @override
  String lastGuessLabel(Object title) {
    return 'Último palpite: $title';
  }

  @override
  String get ticketHelpAction => 'Entender os tickets';

  @override
  String get ticketEmptyHint =>
      'Sem tickets para dicas extras. Você pode continuar esta partida gratuitamente.';

  @override
  String get noTicketDailyTip => 'O desafio diário é gratuito nos dois modos.';

  @override
  String get gameAnswer => 'Responder';

  @override
  String posterStep(int step, int total) {
    return 'Nível $step de $total';
  }

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filmes encontrados',
      one: '1 filme encontrado',
    );
    return '$_temp0';
  }

  @override
  String get challengeInputLabel => 'Código ou link Cineus';

  @override
  String get pasteChallenge => 'Colar código ou link';

  @override
  String get challengeLoadFailed =>
      'Não foi possível carregar o desafio. Tente novamente.';

  @override
  String get editChallenge => 'Editar código ou link';

  @override
  String get resultUnavailable =>
      'Este resultado não está disponível. Volte ao jogo ou à tela inicial.';

  @override
  String get returnToGame => 'Voltar ao jogo';

  @override
  String resultProgress(int step, int total) {
    return 'Passos: $step/$total';
  }

  @override
  String resultScore(int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score pontos',
      one: '1 ponto',
      zero: '0 pontos',
    );
    return '$_temp0';
  }

  @override
  String get shareImage => 'Compartilhar cartão';

  @override
  String get copyResultText => 'Copiar resultado em texto';

  @override
  String get shareCardTitle => 'Seu cartão de resultado';

  @override
  String get shareFailed =>
      'Não foi possível abrir o compartilhamento. Tente novamente.';

  @override
  String get copyFailed => 'Não foi possível copiar. Tente novamente.';

  @override
  String get challengeInviteHelp =>
      'Envie o código ou link para um amigo jogar este filme no mesmo modo.';

  @override
  String get shareChallengeCopy => 'Copiar convite';

  @override
  String get dailyInviteWarning =>
      'O convite abre este mesmo filme. O cartão do Daily continua sem a resposta.';

  @override
  String get sharePreviewAction => 'Ver cartão';

  @override
  String get shareModeClues => 'Dicas';

  @override
  String get shareModePoster => 'Poster';

  @override
  String get resultVictoryLabel => 'Acertou!';

  @override
  String get resultDefeatLabel => 'Não foi desta vez';

  @override
  String get challengeEntryHelp =>
      'Cole o código ou link que um amigo enviou. O modo do jogo vem no convite.';

  @override
  String get stagesCurrent => 'Seu próximo estágio';

  @override
  String get stageOpen => 'Ver partidas';

  @override
  String stageUnlockAfter(Object stage) {
    return 'Complete $stage neste modo para desbloquear.';
  }

  @override
  String get stageCompleteLabel => 'Estágio concluído';

  @override
  String get stageCostHelp =>
      'Iniciar ou tentar novamente custa 1 ticket. Retomar uma partida é grátis.';

  @override
  String get stageNoTicketsHelp =>
      'Sem tickets para uma nova partida? Continue as partidas em andamento grátis ou jogue o Daily. Confira quando seu saldo será renovado.';

  @override
  String get stageLoadingAction => 'Abrindo partida…';

  @override
  String get statsOverview => 'Resumo';

  @override
  String get statsAchievementsTab => 'Conquistas';

  @override
  String statsDailyOnly(Object mode) {
    return 'Histórico do Daily · $mode';
  }

  @override
  String get statsEmptyTitle => 'Sua história começa aqui';

  @override
  String get statsEmptyBody =>
      'Conclua um desafio diário para registrar seu primeiro resultado.';

  @override
  String get streakEmpty => 'Nenhuma sequência ativa';

  @override
  String get streakDailyHelp =>
      'Vitórias diárias consecutivas neste modo. Dias protegidos mantêm a sequência, mas não somam vitórias.';

  @override
  String protectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias protegidos',
      one: '1 dia protegido',
      zero: '0 dias protegidos',
    );
    return '$_temp0';
  }

  @override
  String get protectedDaysHelp =>
      'Proteções registradas no histórico, válidas para os dois modos.';

  @override
  String get achievementScopeDailyClues => 'Daily · Dicas';

  @override
  String get achievementScopeStagesBoth => 'Estágios · Dicas e Poster';

  @override
  String get achievementScopeRewardsBoth => 'Recompensas · Dicas e Poster';

  @override
  String get achievementRulesHelp =>
      'As conquistas de vitórias, pontos, sequência e partidas usam o Daily de Dicas. Estágios completos e tickets ganhos somam os dois modos. Convites não contam como Daily.';

  @override
  String get achievementLockedLabel => 'Ainda não desbloqueada';

  @override
  String achievementProgress(int done, int total) {
    return '$done de $total conquistas desbloqueadas';
  }

  @override
  String get streakProtectFailed =>
      'Não foi possível proteger sua sequência. Tente novamente.';

  @override
  String get stageDailyAction => 'Ver Daily grátis';

  @override
  String get guideTitle => 'Experimente os três modos';

  @override
  String get guideCluesTitle => 'Dicas: do mistério à resposta';

  @override
  String get guideCluesBody =>
      'Acerte com até 10 dicas. Cada revelação ou erro reduz a nota em 1 ponto.';

  @override
  String get guidePosterTitle => 'Poster: revele aos poucos';

  @override
  String get guidePosterBody =>
      'Acerte com até 5 níveis de desfoque. Revelar mais ou errar reduz a nota em 1 ponto.';

  @override
  String get guideAnswerTitle => 'Escolha, confira e confirme';

  @override
  String get guideAnswerBody =>
      'Busque pelo título em português ou original. Selecione o filme com o ano correto e confirme.';

  @override
  String get guideWrongTitle => 'Um erro avança o jogo';

  @override
  String get guideWrongBody =>
      'Errar revela automaticamente a próxima dica ou nível. Na última tentativa, um erro encerra a partida com zero pontos.';

  @override
  String get guideTicketsTitle => 'Tickets: saiba quando usar';

  @override
  String get guideTicketsBody =>
      'Iniciar ou refazer um estágio custa 1 ticket. Retomar é grátis. Em Precisa de ajuda?, use 1 ticket ou um vídeo opcional para liberar a ajuda e guardar 1 ticket. Diários e convites de filmes são gratuitos.';

  @override
  String get guideTicketsRenewal =>
      'O saldo diário volta a 10 à meia-noite UTC. Tickets extras ficam guardados. Concluir o diário de Cores rende +2 uma vez por data; estágios não dão essa recompensa.';

  @override
  String get guideDailyTitle => 'Diários no Início';

  @override
  String get guideDailyBody =>
      'Dicas, Pôster e Cores têm um diário gratuito no Início. Eles mudam à meia-noite UTC. A contagem na tela mostra quanto falta.';

  @override
  String get guideStagesTitle => 'Avance no seu ritmo';

  @override
  String get guideStagesBody =>
      'Nas abas Filmes, Pôsteres e Cores, conclua as partidas para liberar o estágio seguinte. Filmes e Pôsteres têm 10 partidas por estágio; Cores tem duas partidas de cinco personagens diferentes. O progresso é separado em cada modo.';

  @override
  String get guideSaveFailed =>
      'Não foi possível salvar que você viu o guia. Tente novamente.';

  @override
  String get settingsPreferences => 'Preferências';

  @override
  String get settingsHelpSection => 'Ajuda e suporte';

  @override
  String get supportTitle => 'Suporte';

  @override
  String get supportBody =>
      'Encontre ajuda ou relate um problema no GitHub. Abrir o link não envia uma mensagem automaticamente. Evite publicar dados pessoais.';

  @override
  String get supportOpen => 'Abrir suporte';

  @override
  String get supportCopy => 'Copiar link de suporte';

  @override
  String get supportOpenFailed =>
      'Não foi possível abrir o navegador. Copie o link para acessar o suporte.';

  @override
  String get supportCopied => 'Link de suporte copiado.';

  @override
  String get supportCopyFailed =>
      'Não foi possível copiar. Você pode selecionar o link abaixo.';

  @override
  String get searchEmptyHelp =>
      'Confira a grafia ou tente o título original. Selecione um filme com o ano correto antes de confirmar.';

  @override
  String get colorTrainingBadge => 'TREINO';

  @override
  String colorRoundProgress(int current, int total) {
    return 'Rodada $current/$total';
  }

  @override
  String get colorComplete => 'Concluído';

  @override
  String get colorTrainingRulesBody =>
      'Ajuste a cor, confirme e compare com a referência. São cinco rodadas e uma média final. A dica desconta 1 ponto.';

  @override
  String get colorConfirm => 'Confirmar cor';

  @override
  String get colorNextRound => 'Próxima rodada';

  @override
  String get colorSeeFinal => 'Ver média final';

  @override
  String get colorPlayAgain => 'Jogar novamente';

  @override
  String get colorRestart => 'Reiniciar treino';

  @override
  String get colorHintAction => 'Usar dica · −1 ponto';

  @override
  String get colorHintApplied => 'Dica usada · −1 ponto';

  @override
  String get colorRoundResult => 'Seu tom, lado a lado.';

  @override
  String get colorReferenceTone => 'Referência';

  @override
  String colorScoreValue(String score) {
    return '$score / 10';
  }

  @override
  String get colorFinalTitle => 'Cinco cores. Sua memória.';

  @override
  String get colorAverageLabel => 'Sua média';

  @override
  String get colorDiscardTitle => 'Sair deste treino?';

  @override
  String get colorDiscardBody =>
      'O progresso desta partida será perdido. Um novo treino começa na primeira rodada.';

  @override
  String get colorKeepPlaying => 'Continuar jogando';

  @override
  String get colorDiscardAction => 'Descartar partida';

  @override
  String get colorDailyBadge => 'DIÁRIO';

  @override
  String get colorDailyTitle => 'Desafio diário';

  @override
  String get colorResume => 'Continuar partida';

  @override
  String colorResumeRound(int round) {
    return 'Continuar · rodada $round/5';
  }

  @override
  String get colorPendingDaily => 'Diário pendente';

  @override
  String get colorOldDailyPolicy =>
      'Pode terminar esta partida quando quiser. Ela mantém a data original e não ocupa o diário de hoje.';

  @override
  String get colorHistory => 'Histórico de Cores';

  @override
  String get colorOpenHistory => 'Ver meu histórico';

  @override
  String get colorHistoryEmpty =>
      'Você ainda não concluiu uma partida nesta categoria.';

  @override
  String get colorHistoryFive =>
      'Cinco respostas confirmadas. Abra para rever cada rodada.';

  @override
  String get colorSeeResult => 'Rever resultado';

  @override
  String get colorSaving => 'Salvando sua partida…';

  @override
  String get colorSaveFailed =>
      'Não foi possível salvar. Tente novamente antes de sair; a partida não avançou.';

  @override
  String get colorReloadSaved => 'Recarregar a versão salva';

  @override
  String get colorBackHub => 'Voltar para Cores';

  @override
  String get colorLoadFailed =>
      'Não foi possível abrir os dados de Cores. Eles foram preservados. Tente novamente; uma partida de versão incompatível precisa de uma atualização do app.';

  @override
  String get colorLoading => 'Abrindo suas cores salvas…';

  @override
  String get colorReplaceTrainingBody =>
      'Começar outro treino substitui o treino em andamento. Seus resultados concluídos continuam no histórico.';

  @override
  String get colorSavedRules =>
      'Ajuste a cor e confirme para comparar com a referência. São cinco rodadas e uma média final. A dica desconta 1 ponto. Estágios ficam em Cores; o diário fica no Início.';

  @override
  String get colorReplaceTrainingTitle => 'Começar outro treino?';

  @override
  String get colorReplaceTrainingAction => 'Substituir treino';

  @override
  String get colorGuideTitle => 'Como jogar Cores';

  @override
  String get colorGuideAdjustTitle => 'Dê cor ao personagem';

  @override
  String get colorGuideAdjustBody =>
      'Ajuste a cor do personagem e veja o resultado em tempo real.';

  @override
  String get colorGuideResultTitle => 'Compare sua escolha';

  @override
  String get colorGuideResultBody =>
      'Cores próximas à referência recebem até 10 pontos. Cada partida tem cinco rodadas; a nota final é a média.';

  @override
  String get colorGuideHintRule =>
      'Uma ajuda por rodada desconta 1 ponto. A dica rápida é gratuita; a orientação de ajustes usa 1 ticket ou um vídeo opcional.';

  @override
  String get colorGuideDailyRule =>
      'Na aba Cores, cada estágio reúne dez personagens diferentes em duas partidas de cinco. Conclua as duas para abrir o próximo. O desafio diário fica no Início.';

  @override
  String get colorGuideSaveRule =>
      'A partida é salva neste aparelho e pode ser retomada. Um diário antigo mantém sua data. Limpar os dados ou desinstalar o app remove o histórico local.';

  @override
  String get colorGuideSaveFailed =>
      'Não foi possível registrar o tutorial. Tente novamente; nenhuma partida foi criada.';

  @override
  String get colorGuideDone => 'Entendi, vamos jogar';

  @override
  String get colorGuideNext => 'Próximo passo';

  @override
  String get colorGuidePrevious => 'Passo anterior';

  @override
  String get colorRewardSaving => 'Registrando seus +2 tickets…';

  @override
  String get colorRewardEarned =>
      '+2 tickets recebidos pelo diário. A recompensa desta data já está no seu saldo.';

  @override
  String get colorRewardFailed =>
      'Seu resultado está salvo. Não foi possível confirmar os tickets; tente novamente para recuperar a recompensa.';

  @override
  String get colorStatsTitle => 'Estatísticas de Cores';

  @override
  String get colorStatsCompleted => 'Partidas concluídas';

  @override
  String get colorStatsMean => 'Média das partidas';

  @override
  String get colorStatsBest => 'Melhor média';

  @override
  String get colorStatsRounds => 'Média por rodada';

  @override
  String get colorStatsRoundsBody =>
      'Cada posição reúne as notas das suas partidas concluídas nesta categoria.';

  @override
  String colorStatsRound(int round) {
    return 'Rodada $round';
  }

  @override
  String get colorStatsRecent => 'Últimos resultados';

  @override
  String get colorStatsScope =>
      'As notas de Cores são independentes. Elas não alteram vitórias ou sequências de Dicas e Pôster.';

  @override
  String get colorStatsOpen => 'Ver minhas estatísticas';

  @override
  String get colorShareTitle => 'Minha memória tem cor.';

  @override
  String get colorSharePrivacy =>
      'Só as notas: personagens, perguntas e cores ficam fora deste cartão.';

  @override
  String get colorShareText => 'Compartilhar texto';

  @override
  String get colorHomeDescription =>
      'Você lembra o tom? Recolora cinco personagens e compare sua memória com a referência.';

  @override
  String colorExactTitle(String label) {
    return 'Ajustar $label';
  }

  @override
  String colorExactRange(int max) {
    return 'Valor de 0 a $max. Você pode usar casas decimais.';
  }

  @override
  String colorExactInvalid(int max) {
    return 'Digite um número entre 0 e $max.';
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
    return 'Diminuir $label';
  }

  @override
  String colorIncrease(String label) {
    return 'Aumentar $label';
  }

  @override
  String get colorCreditsTitle => 'Fontes de Cores';

  @override
  String get colorCreditsDescription =>
      'Referências utilizadas no acervo de Cores. Os tons correspondem às partes e versões indicadas; as artes são interpretações visuais.';

  @override
  String get colorCreditsGenerated => 'Ilustração gerada para o Cineus';

  @override
  String get colorCreditsReference =>
      'Ilustração baseada em imagem de referência';

  @override
  String get colorCreditsStudy => 'Referência de estudo de cor';

  @override
  String get colorCreditsArt => 'Origem da imagem de referência';

  @override
  String get homeDailyAction => 'Jogar o diário';

  @override
  String get homeDailyCompleted => 'Diário concluído';

  @override
  String get homeStatsTitle => 'Minhas estatísticas';

  @override
  String get homeCluesDescription => 'Teste seus conhecimentos sobre filmes.';

  @override
  String get homePosterDescription => 'Qual é o filme pelo pôster?';

  @override
  String get homeChallengeUnavailable => 'Não foi possível carregar.';

  @override
  String get filmsToStart => 'para iniciar';

  @override
  String get filmsInStage => 'neste estágio';

  @override
  String get filmsAllStages => 'Todos os estágios';

  @override
  String filmsUnlockAfter(String stage) {
    return 'Complete o $stage';
  }

  @override
  String get filmsEmpty => 'Nenhum estágio disponível.';

  @override
  String get colorEnlargeCharacter => 'Ampliar personagem';

  @override
  String get colorZoomHint => 'Use dois dedos para ampliar os detalhes.';

  @override
  String get colorStagesSubtitle => 'Relembre as cores e avance por estágios.';

  @override
  String colorStageTitle(int stage) {
    return 'Estágio $stage';
  }

  @override
  String colorStageProgress(int done, int total) {
    return '$done / $total desenhos concluídos';
  }

  @override
  String get colorStageStructure => '10 desenhos distintos · 2 partidas de 5';

  @override
  String get colorStageReturn => 'Voltar ao estágio';

  @override
  String colorStageMatch(int match) {
    return 'Partida $match';
  }

  @override
  String get colorStageStart => 'Começar · 1 ticket';

  @override
  String get colorStageResume => 'Continuar';

  @override
  String get colorStageOpen => 'Ver partidas';

  @override
  String colorStageLocked(int stage) {
    return 'Complete o Estágio $stage';
  }

  @override
  String get colorStageDailyHome => 'Os desafios diários estão no Início.';

  @override
  String get colorStageLegacy => 'Retomar treino anterior';

  @override
  String get colorStagesAndTraining => 'Estágios e treino';

  @override
  String get splashWelcome => 'Cinema, memória e cor.';

  @override
  String get colorStageGamesTitle => 'Partidas do estágio';

  @override
  String get resultNext => 'Próximo';

  @override
  String get stagePlay => 'Jogar';

  @override
  String get stageRetry => 'Tentar novamente';

  @override
  String get stageContinue => 'Continuar';

  @override
  String get guidePracticeNotice =>
      'Exemplo livre · não usa tickets nem altera seu progresso.';

  @override
  String get guideColorsBody =>
      'Recrie a cor de uma região do personagem. Ajuste tom, intensidade e brilho e compare depois de confirmar.';

  @override
  String get guideTryColors => 'Experimentar Cores';

  @override
  String get guideDemoReset => 'Experimentar de novo';

  @override
  String get guideDemoComplete => 'Concluir partida do exemplo';

  @override
  String get guideDemoUnlocked => 'Estágio 2 liberado no exemplo.';

  @override
  String get guideDemoCorrect =>
      'Acertou o exemplo! O resultado mostra seus pontos e o filme.';

  @override
  String get guideDemoWrong =>
      'Neste exemplo, errar revela outra dica: o filme é de Christopher Nolan. Você ainda pode tentar Interestelar.';

  @override
  String get guideDemoClues =>
      'Um grupo viaja pelo espaço em busca de um novo lar.|A Terra enfrenta uma crise de alimentos.|O tempo passa de forma diferente em outro planeta.|Um pai promete voltar para a filha.|A viagem atravessa um buraco de minhoca.|Um robô chamado TARS acompanha a equipe.|Há um planeta coberto por água.|O protagonista se chama Cooper.|Christopher Nolan dirigiu o filme.|Matthew McConaughey interpreta Cooper.';

  @override
  String get guideSaveTitle => 'Partida e histórico';

  @override
  String get guideSaveBody =>
      'Pode sair e continuar a partida. O progresso e as estatísticas ficam neste aparelho; limpar seus dados ou desinstalar o app remove os registros locais.';

  @override
  String get guideResultsTitle => 'Resultado e cartão';

  @override
  String get guideResultsBody =>
      'Próximo abre a próxima partida. Ver cartão mostra o pôster, a marca e seus pontos; o compartilhamento fica dentro do cartão. A barra usa verde para 7–10, amarelo para 4–6 e vermelho para 0–3 pontos. Desafiar amigo cria um convite de filme. Em Cores, veja as cinco notas e sua média.';

  @override
  String get guideColorsEconomy =>
      'Estágios custam 1 ticket; retomar é grátis. O diário gratuito rende +2 ao concluir. Dica rápida e orientação de ajustes descontam 1 ponto na rodada; a orientação usa ticket ou vídeo opcional.';

  @override
  String get guideJourneyTitle => 'Diários e estágios';

  @override
  String get guideEssentialsTitle => 'Seu progresso e resultados';

  @override
  String get colorMysteryCharacters => 'Personagens misteriosos';

  @override
  String get colorStatsAllScope => 'Todas as partidas concluídas de Cores';

  @override
  String get colorStatsPointScale => 'pontos de 0 a 10';

  @override
  String get colorStatsRoundsPlayed => 'Rodadas concluídas';

  @override
  String get achievementScopeColors => 'Cores · todos os modos';

  @override
  String get achievementScopeDailyPoster => 'Daily · Poster';

  @override
  String get achPosterFirst => 'Primeiro enquadramento';

  @override
  String get achPosterFirstDesc => 'Acerte um desafio diário de Poster.';

  @override
  String get achPosterPerfect => 'Olho clínico';

  @override
  String get achPosterPerfectDesc =>
      'Ganhe 5 pontos em um diário de Poster, no primeiro nível de desfoque.';

  @override
  String get achColorsFirst => 'Primeira pincelada';

  @override
  String get achColorsFirstDesc =>
      'Conclua uma partida de Cores com cinco personagens.';

  @override
  String get achColors25 => 'Ateliê de memórias';

  @override
  String get achColors25Desc => 'Conclua 25 partidas de Cores.';

  @override
  String get achColorsExcellent => 'Memória cromática';

  @override
  String get achColorsExcellentDesc =>
      'Alcance média final de pelo menos 9 pontos em uma partida de Cores.';

  @override
  String get achColorsStages3 => 'Galeria em expansão';

  @override
  String get achColorsStages3Desc =>
      'Complete os dois jogos de três estágios de Cores.';

  @override
  String get collectionTitle => 'Minha coleção';

  @override
  String get collectionProfile => 'Meu perfil';

  @override
  String get collectionEditProfile => 'Editar perfil';

  @override
  String get collectionDisplayName => 'Nome de exibição';

  @override
  String get collectionNameHint => 'Como quer aparecer?';

  @override
  String get collectionShowIdentity => 'Mostrar nome e avatar no cartão';

  @override
  String get collectionNameInvalid =>
      'Use até 24 caracteres, sem quebras de linha.';

  @override
  String get collectionSave => 'Salvar';

  @override
  String get collectionAvatars => 'Avatares';

  @override
  String get collectionFrames => 'Molduras';

  @override
  String get collectionAppearances => 'Cartões';

  @override
  String get collectionApply => 'Aplicar';

  @override
  String get collectionEquipped => 'Em uso';

  @override
  String get collectionUnavailable => 'Indisponível';

  @override
  String get collectionPreview => 'Prévia';

  @override
  String get collectionLoadFailed => 'Não foi possível abrir sua coleção.';

  @override
  String get collectionSaveFailed =>
      'Não foi possível salvar. Tente novamente.';

  @override
  String get collectionEmpty => 'Nenhum item nesta categoria.';

  @override
  String get collectionAvatarOwl => 'Íris, a Última Técnica';

  @override
  String get collectionAvatarFox => 'Dante Rebobina';

  @override
  String get collectionFrameGold => 'Luz dourada';

  @override
  String get collectionFrameBlue => 'Rolo azul';

  @override
  String get collectionAppearanceNoir => 'Noite de cinema';

  @override
  String get collectionPremiere => 'Coleção Estreia';

  @override
  String get collectionTryPremiere => 'Experimentar coleção';

  @override
  String get collectionPremierePreview => 'Prévia da Coleção Estreia';

  @override
  String get collectionFree => 'Gratuito';

  @override
  String get collectionPersonalize => 'Personalizar';

  @override
  String get collectionAvatarCat => 'Otto Corte-Final';

  @override
  String get collectionAvatarHare => 'Vitor Plano-Mestre';

  @override
  String get collectionFrameMarquee => 'Luzes da estreia';

  @override
  String get collectionFrameDeco => 'Cinema Art Déco';

  @override
  String get collectionFrameSpotlight => 'Sob os holofotes';

  @override
  String get collectionAppearanceVelvet => 'Veludo da estreia';

  @override
  String get commerceRestore => 'Restaurar compras';

  @override
  String commerceBuy(String price) {
    return 'Comprar · $price';
  }

  @override
  String get commercePending => 'Compra pendente de confirmação.';

  @override
  String get commerceVerified =>
      'Compra confirmada. Seus itens estão na coleção.';

  @override
  String get commerceFailed =>
      'Não foi possível confirmar. Tente restaurar quando a conexão voltar.';

  @override
  String get commerceCancelled => 'Compra cancelada.';

  @override
  String get commerceRestoring =>
      'Restauração solicitada. A confirmação pode levar alguns instantes.';

  @override
  String get commerceUse => 'Usar coleção';

  @override
  String get commercePermanent => 'Compra única · itens permanentes';

  @override
  String get commerceRecovery => 'Recuperar acesso';

  @override
  String get commerceRecoveryKey => 'Chave de recuperação';

  @override
  String get commerceRecoveryInfo =>
      'Guarde esta chave em local privado antes de reinstalar ou trocar de aparelho. Ela recupera o acesso comercial, não o progresso do jogo. Não compartilhe.';

  @override
  String get commerceRecoverAction => 'Recuperar';

  @override
  String get commercePlus => 'Cineus Plus';

  @override
  String get commerceClub => 'Cineus Clube';

  @override
  String get commercePrivacy => 'Privacidade dos anúncios';

  @override
  String get commerceHideRewarded => 'Ocultar ofertas de vídeo';

  @override
  String get commerceClubTerms =>
      'Assinatura mensal com renovação automática. Inclui a coleção do ciclo e remove interrupções durante a vigência. Cancele pela loja; itens já adquiridos permanecem.';

  @override
  String get commerceManage => 'Gerenciar assinatura';

  @override
  String get missionsTitle => 'Sua jornada';

  @override
  String get missionsWeekly => 'Missões da semana';

  @override
  String get missionPlay => 'Conclua 3 partidas';

  @override
  String get missionModes => 'Jogue nos 3 modos';

  @override
  String get missionDays => 'Jogue em 3 dias';

  @override
  String get missionClaim => 'Resgatar';

  @override
  String get missionClaimed => 'Resgatado';

  @override
  String get discoveryTitle => 'Personagens encontrados';

  @override
  String get discoveryMystery => 'Personagem misterioso';

  @override
  String get seasonTitle => 'Mostras de cinema';

  @override
  String get seasonArchive => 'Coleções anteriores';

  @override
  String get sponsorTitle => 'Sessão especial';

  @override
  String get sponsorDemo => 'Demonstração · Estúdio Aurora';

  @override
  String get sponsorDisclosure => 'Patrocínio';

  @override
  String get sponsorGoal => 'Conclua 3 partidas durante o evento';

  @override
  String get sponsorReward => 'Recompensa visual gratuita';

  @override
  String get collectionNight => 'Noite Estrelada';

  @override
  String get collectionCity => 'Luzes da Cidade';

  @override
  String get itemMissionFirefly => 'Enzo Replay';

  @override
  String get itemMissionProjector => 'Projeção da semana';

  @override
  String get itemMissionConstellation => 'Constelação';

  @override
  String get itemPlusCrown => 'Coroa do cinema';

  @override
  String get itemPlusPremiere => 'Veludo Plus';

  @override
  String get itemNightRaccoon => 'Nara Estelar';

  @override
  String get itemNightOtter => 'Ciro Maré-de-Cena';

  @override
  String get itemNightOrbit => 'Órbita dourada';

  @override
  String get itemNightComet => 'Rastro de cometa';

  @override
  String get itemNightObservatory => 'Observatório';

  @override
  String get itemNightSky => 'Céu de cinema';

  @override
  String get itemCityPanda => 'Raul Duplo-Corte';

  @override
  String get itemCityHummingbird => 'Sol Última-Tomada';

  @override
  String get itemCitySkyline => 'Horizonte de luz';

  @override
  String get itemCityBridge => 'Ponte dourada';

  @override
  String get itemCityRain => 'Chuva de estreia';

  @override
  String get itemCityNight => 'Cidade noturna';

  @override
  String get itemAuroraFrame => 'Primeira luz';

  @override
  String get seasonRefresh => 'Atualizar coleções';

  @override
  String get seasonUpdateFailed =>
      'Não foi possível atualizar. Sua coleção continua disponível.';

  @override
  String get sponsorJoin => 'Participar';

  @override
  String get sponsorEnded => 'Evento encerrado';

  @override
  String get collectionOwned => 'Adquirido';

  @override
  String sponsorGoalCount(int count) {
    return 'Conclua $count partidas durante o evento';
  }

  @override
  String get guideCollectionTitle => 'Sua jornada e seus visuais';

  @override
  String get guideCollectionBody =>
      'Missões da semana e eventos gratuitos desbloqueiam visuais. Confira e aplique em Minha coleção. Compras opcionais personalizam o cartão; não mudam sua pontuação.';

  @override
  String get collectionPreviewNotice =>
      'Prévia · sem alterar seus itens em uso.';

  @override
  String get commercePlusTerms =>
      'Compra única · sem interrupções, com moldura e cartão exclusivos.';

  @override
  String get commerceCollectionTerms =>
      'Compra única · 2 avatares, 3 molduras e 1 cartão.';

  @override
  String get commerceSubscriptionActive => 'Assinatura ativa';

  @override
  String get earnTickets => 'Ganhar tickets';

  @override
  String get earnTicketsSubtitle => 'Vídeos opcionais e mais partidas';

  @override
  String get commerceComingSoon => 'Em breve';

  @override
  String get adSpaceLabel => 'Publicidade';

  @override
  String get adSpaceReserved => 'Espaço reservado para anúncio';

  @override
  String get rewardedLoading => 'Preparando vídeo…';

  @override
  String get rewardedUnavailable => 'Nenhum vídeo disponível agora.';

  @override
  String get rewardedLimitReached => 'Você usou os vídeos de hoje.';

  @override
  String get rewardedPlaceholderBody =>
      'Assista a um vídeo e ganhe tickets extras.';

  @override
  String get rewardedRetry => 'Carregar vídeo';

  @override
  String get rewardedFailed => 'Não foi possível concluir. Tente novamente.';

  @override
  String get rewardedCancelled => 'Recompensa ainda não confirmada.';

  @override
  String get rewardedWatching => 'Aguardando recompensa…';

  @override
  String get rewardedPreviewLabel => 'Vídeo recompensado · em breve';

  @override
  String get ticketPacksTitle => 'Pacotes de tickets';

  @override
  String get ticketPackSmall => '20 tickets';

  @override
  String get ticketPackLarge => '60 tickets';

  @override
  String get ticketPacksNote =>
      'Mais partidas, sem esperar a renovação diária.';

  @override
  String get seasonIntro =>
      'Jogue, complete missões e encontre seu próximo personagem.';

  @override
  String get seasonCurrent => 'Nesta temporada';

  @override
  String get seasonNext => 'A seguir';

  @override
  String get seasonFinished => 'Encerrada';

  @override
  String get seasonEmpty => 'Novas temporadas estão a caminho.';

  @override
  String get seasonItems => 'Seis visuais para descobrir';

  @override
  String get seasonTry => 'Explorar coleção';

  @override
  String get seasonPreviewTitle => 'Experimente os visuais';

  @override
  String seasonAvailableOn(String date) {
    return 'Chega em $date';
  }

  @override
  String seasonUntil(String date) {
    return 'Até $date';
  }

  @override
  String seasonOwnedCount(int count, int total) {
    return '$count de $total na sua coleção';
  }

  @override
  String get seasonEventTitle => 'Evento gratuito';

  @override
  String get seasonEventDemo => 'Evento de demonstração';

  @override
  String get seasonStoreSoon => 'As coleções estarão disponíveis em breve.';

  @override
  String get commerceOptionalExtras => 'Jogue do seu jeito';

  @override
  String get commerceOptionalBody =>
      'Tickets para continuar jogando e uma opção para remover anúncios comuns. Vídeos com recompensa continuam opcionais.';

  @override
  String get ticketLearnMore => 'Sobre os tickets';

  @override
  String get commerceLoading => 'Carregando opções…';

  @override
  String get commerceCheckFailed => 'Não foi possível verificar suas compras.';

  @override
  String get commerceOffersFailed => 'Não foi possível carregar a loja.';

  @override
  String get commerceNoOffers => 'Nenhuma oferta disponível agora.';

  @override
  String get commerceRestoreDone => 'Compras restauradas.';

  @override
  String get commerceRestoreEmpty => 'Nenhuma compra ativa confirmada.';

  @override
  String get commerceBenefitsActive => 'Vantagens ativas';

  @override
  String get commerceAdFreeActive =>
      'Publicidade removida. Vídeos com recompensa continuam opcionais.';

  @override
  String get collectionHowToGet => 'Como conseguir';

  @override
  String get collectionOnlyOwned => 'Meus itens';

  @override
  String get collectionAllItems => 'Todos os itens';

  @override
  String get collectionUnlockMission =>
      'Conclua missões da semana para desbloquear este visual.';

  @override
  String get collectionUnlockEvent =>
      'Este visual é a recompensa de um evento.';

  @override
  String get collectionUnlockSeason => 'Encontre esta coleção em Temporadas.';

  @override
  String get collectionUnlockSoon =>
      'Este visual estará disponível na loja em breve.';

  @override
  String get collectionUnlocked => 'Desbloqueado';

  @override
  String get helpTitle => 'Precisa de ajuda?';

  @override
  String get helpUseTicket => 'Usar 1 ticket';

  @override
  String get helpWatch => 'Vídeo · ajuda + 1 ticket';

  @override
  String get helpVideoSoon => 'Vídeo em breve';

  @override
  String get helpVideoUsed => 'Vídeo já usado nesta partida';

  @override
  String get helpVideoTerms =>
      '1 por partida · compartilha o limite diário de vídeos.';

  @override
  String get helpPending => 'Confirmando recompensa…';

  @override
  String get helpPendingBody =>
      'Pode continuar jogando. A recompensa será recuperada quando for confirmada.';

  @override
  String get helpClaim => 'Receber ajuda';

  @override
  String get helpStored => 'Os 2 tickets ficaram no seu saldo.';

  @override
  String get helpDone => 'Ajuda liberada. +1 ticket no saldo.';

  @override
  String get helpNoAvailable => 'Você já usou as ajudas disponíveis.';

  @override
  String get helpColorGuidance => 'Orientação de cor';

  @override
  String get helpColorGuidanceBody =>
      'Uma sugestão de tom e ajuste. −1 ponto nesta rodada.';

  @override
  String get helpColorSimple => 'Dica rápida';

  @override
  String get helpColorSimpleBody => 'Dica do personagem · −1 ponto';

  @override
  String get helpAdOffer =>
      'Assista a um anúncio para liberar esta ajuda e guardar 1 ticket.';

  @override
  String helpColorFamily(String family) {
    return 'Experimente a família de $family.';
  }

  @override
  String get helpFamilyRed => 'vermelhos';

  @override
  String get helpFamilyOrange => 'laranjas';

  @override
  String get helpFamilyYellow => 'amarelos';

  @override
  String get helpFamilyGreen => 'verdes';

  @override
  String get helpFamilyCyan => 'cianos';

  @override
  String get helpFamilyBlue => 'azuis';

  @override
  String get helpFamilyPurple => 'roxos';

  @override
  String get helpFamilyPink => 'rosas';

  @override
  String get helpFamilyNeutral => 'tons neutros';

  @override
  String get helpBrighter => 'Aumente um pouco o brilho.';

  @override
  String get helpDarker => 'Diminua um pouco o brilho.';

  @override
  String get helpMoreSaturation => 'Aumente um pouco a intensidade.';

  @override
  String get helpLessSaturation => 'Diminua um pouco a intensidade.';

  @override
  String get helpAdjustClose => 'Os ajustes estão próximos; refine o tom.';

  @override
  String get archiveMode => 'Arquivo';

  @override
  String get practiceMode => 'Treino';

  @override
  String get activityAll => 'Todas as partidas';

  @override
  String get activityDaily => 'Diários';

  @override
  String get activityStage => 'Estágios';

  @override
  String get activityInvites => 'Convites';

  @override
  String get activityContext => 'Atividade';

  @override
  String get presenceStreak => 'Dias jogados seguidos';

  @override
  String get nextGoal => 'Sua próxima meta';

  @override
  String get continueGame => 'Continuar partida';

  @override
  String get practiceAgain => 'Rever no treino';

  @override
  String get masteryTitle => 'Seu domínio';

  @override
  String get archiveTitle => 'Diários anteriores';

  @override
  String get archiveDescription =>
      'Jogue no seu ritmo, sem alterar o resultado de hoje.';

  @override
  String get editorialFeedback => 'Reportar um problema';

  @override
  String get feedbackSent => 'Obrigado! Relato salvo para revisão.';

  @override
  String get feedbackClue => 'Dica ou resposta';

  @override
  String get feedbackArtwork => 'Imagem ou personagem';

  @override
  String get feedbackDifficulty => 'Dificuldade';

  @override
  String get feedbackOther => 'Outro problema';

  @override
  String get feedbackNote => 'Descrição opcional';

  @override
  String get sendFeedback => 'Enviar relato';

  @override
  String get neutralCard => 'Ocultar resposta';

  @override
  String get quickStart => 'Jogar um exemplo';

  @override
  String get backupTitle => 'Seu progresso';

  @override
  String get backupSave => 'Salvar backup';

  @override
  String get backupRestore => 'Restaurar backup';

  @override
  String get backupCode => 'Chave de recuperação';

  @override
  String get backupSaved => 'Backup salvo.';

  @override
  String get backupConfirm =>
      'Restaurar este progresso? Seu progresso local será combinado com o backup.';

  @override
  String get metricsConsent => 'Compartilhar dados de uso';

  @override
  String get metricsConsentBody =>
      'Ajude a melhorar o jogo. Seus palpites e nomes não são enviados.';

  @override
  String get metricsDelete => 'Apagar dados de uso';

  @override
  String get friendGames => 'Desafios entre amigos';

  @override
  String get friendJoin => 'Abrir convite';

  @override
  String get friendCreate => 'Criar desafio';

  @override
  String get connectedRequired => 'Conecte-se para usar este recurso.';

  @override
  String get missionDuplicate => 'Item já adquirido · recompensa alternativa';

  @override
  String get itemMissionCapybara => 'Breno Efeito-Bruto';

  @override
  String get itemMissionAxolotl => 'Bento Rolo-Perdido';

  @override
  String get itemMissionPenguin => 'Glifo Caça-Cenas';

  @override
  String get archiveMore => 'Ver mais dias';

  @override
  String get masteryEmpty => 'Conclua partidas para descobrir seus temas.';

  @override
  String get playerDataTitle => 'Dados e recuperação';

  @override
  String get dataActionFailed => 'Não foi possível concluir. Tente novamente.';

  @override
  String get backupRestored => 'Progresso recuperado.';

  @override
  String get recoveryKeepPrivate =>
      'Guarde esta chave em local seguro. Ela permite recuperar seus dados e compras. Não a compartilhe.';

  @override
  String get backupScope =>
      'Salva partidas, estágios e histórico. Tickets comprados são recuperados pelo servidor; o saldo diário e os bônus deste aparelho permanecem locais.';

  @override
  String get recoverAnotherDevice => 'Recuperar de outro aparelho';

  @override
  String get backupDelete => 'Apagar backup da nuvem';

  @override
  String get backupDeleteConfirm =>
      'Apagar a cópia salva? O progresso neste aparelho será mantido.';

  @override
  String get metricsDeletionQueued =>
      'Dados locais apagados. A exclusão online está pendente.';

  @override
  String get friendActionFailed =>
      'Não foi possível abrir este convite. Confira o código, a conexão e se ele ainda está disponível.';

  @override
  String get friendPlayFirst =>
      'Conclua uma partida de Dicas ou Pôster para criar um confronto.';

  @override
  String get friendChooseGame => 'Escolha uma partida concluída';

  @override
  String get friendCreated => 'Convite válido por 7 dias';

  @override
  String get friendPrivateRules =>
      'Um confronto privado por convite, com a mesma partida. Pontuações informadas pelo aparelho, sem ranking ou prêmios.';

  @override
  String get friendYou => 'Você';

  @override
  String get friendOther => 'Amigo';

  @override
  String get nextAction => 'Próximo';

  @override
  String get purchasedTickets => 'Comprados';

  @override
  String ticketPackAmount(int count) {
    return '$count tickets';
  }

  @override
  String get ticketPackTerms =>
      'Compra avulsa. Tickets não expiram; precisam de conexão para usar e recuperar. Não aumentam sua pontuação.';

  @override
  String missionPlayCount(int count) {
    return 'Conclua $count partidas';
  }

  @override
  String missionModesCount(int count) {
    return 'Jogue em $count modos';
  }

  @override
  String missionDaysCount(int count) {
    return 'Jogue em $count dias';
  }

  @override
  String masteryStageTitle(int count) {
    return 'Guardião do estágio $count';
  }

  @override
  String get masteryTitles => 'Títulos conquistados';

  @override
  String get masteryAnimation => 'Animação';

  @override
  String get masteryFantasy => 'Fantasia';

  @override
  String get masteryClassics => 'Clássicos até 1989';

  @override
  String get assistedResult => 'Com ajuda';

  @override
  String presenceDays(int count) {
    return '$count dias jogados';
  }

  @override
  String resultScoreScale(int score, int total) {
    return '$score/$total pontos';
  }

  @override
  String stageBonusOffer(int count) {
    return 'Conclusão: +$count tickets';
  }

  @override
  String stageBonusTitleOffer(int count) {
    return 'Conclusão: +$count tickets e um título';
  }

  @override
  String get manageProgress => 'Gerenciar progresso';

  @override
  String get progressOnDevice => 'Salvo automaticamente neste aparelho.';

  @override
  String get backupCloudUnavailable => 'Backup na nuvem em breve.';

  @override
  String get backupCloudChecking => 'Consultando backup…';

  @override
  String get backupCloudEmpty => 'Você ainda não tem um backup na nuvem.';

  @override
  String get backupCloudError => 'Não foi possível consultar o backup.';

  @override
  String backupCloudLastSaved(String date) {
    return 'Na nuvem · $date';
  }

  @override
  String get backupOptions => 'Recuperação e outras opções';

  @override
  String get backupDeleted =>
      'Backup da nuvem apagado. Seu progresso local foi mantido.';

  @override
  String get metricsDeletedLocal => 'Dados de uso deste aparelho apagados.';

  @override
  String get metricsDeleted => 'Dados de uso apagados.';

  @override
  String get metricsUnavailable =>
      'O envio de dados está desativado nesta versão.';

  @override
  String get journeyMasteryShortcut => 'Domínio';

  @override
  String get journeyFriendsShortcut => 'Amigos';

  @override
  String get audienceTitle => 'Sua faixa etária';

  @override
  String get audienceBody =>
      'O Cineus foi pensado para pessoas a partir de 16 anos.';

  @override
  String get audiencePrivacy =>
      'Informe apenas sua faixa etária. Não guardamos sua data de nascimento. Compras no app são destinadas a adultos.';

  @override
  String get audienceUnder16 => 'Tenho menos de 16 anos';

  @override
  String get audienceTeen => 'Tenho 16 ou 17 anos';

  @override
  String get audienceAdult => 'Tenho 18 anos ou mais';

  @override
  String get audienceUnavailable =>
      'Esta versão é destinada a pessoas a partir de 16 anos.';

  @override
  String get audiencePurchases => 'Compras disponíveis para maiores de 18 anos';

  @override
  String get showcaseAnimation => 'Mundos de animação';

  @override
  String get showcaseFantasy => 'Além da imaginação';

  @override
  String get showcaseClassics => 'Clássicos em cartaz';

  @override
  String get showcasePlay => 'Escolher partidas';

  @override
  String get showcasePractice =>
      'Uma seleção para jogar no seu ritmo. Seu avanço fica salvo.';

  @override
  String get showcaseRewards =>
      'Os visuais entram na rotação das missões. O que você já conquistou continua seu.';

  @override
  String showcaseFilm(int number) {
    return 'Filme $number';
  }
}
