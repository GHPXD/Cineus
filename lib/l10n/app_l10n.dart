import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_l10n_en.dart';
import 'app_l10n_es.dart';
import 'app_l10n_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @colorModeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cores'**
  String get colorModeTitle;

  /// No description provided for @colorRecallPart.
  ///
  /// In pt, this message translates to:
  /// **'Lembre a cor: {part}'**
  String colorRecallPart(String part);

  /// No description provided for @colorYourTone.
  ///
  /// In pt, this message translates to:
  /// **'Seu tom'**
  String get colorYourTone;

  /// No description provided for @colorHue.
  ///
  /// In pt, this message translates to:
  /// **'Tom'**
  String get colorHue;

  /// No description provided for @colorSaturation.
  ///
  /// In pt, this message translates to:
  /// **'Intensidade'**
  String get colorSaturation;

  /// No description provided for @colorBrightness.
  ///
  /// In pt, this message translates to:
  /// **'Brilho'**
  String get colorBrightness;

  /// No description provided for @colorRulesAction.
  ///
  /// In pt, this message translates to:
  /// **'Como funciona'**
  String get colorRulesAction;

  /// No description provided for @colorRulesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cinco cores. Uma memória.'**
  String get colorRulesTitle;

  /// No description provided for @colorCatalogFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as perguntas.'**
  String get colorCatalogFailed;

  /// No description provided for @colorRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get colorRetry;

  /// No description provided for @colorClose.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get colorClose;

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cineus'**
  String get appTitle;

  /// No description provided for @shareWin.
  ///
  /// In pt, this message translates to:
  /// **'🎬 Cineus #{challenge}\nAcertei na dica {clue}/{total} · {score}pts\n\n{grid}'**
  String shareWin(
    Object challenge,
    int clue,
    int total,
    int score,
    Object grid,
  );

  /// No description provided for @semBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get semBack;

  /// No description provided for @semStats.
  ///
  /// In pt, this message translates to:
  /// **'Ver estatísticas'**
  String get semStats;

  /// No description provided for @semHelp.
  ///
  /// In pt, this message translates to:
  /// **'Como jogar'**
  String get semHelp;

  /// No description provided for @semTicketBalance.
  ///
  /// In pt, this message translates to:
  /// **'{count} tickets disponíveis'**
  String semTicketBalance(int count);

  /// No description provided for @reminderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cineus'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In pt, this message translates to:
  /// **'O desafio de hoje está no ar. Quantas dicas você vai precisar?'**
  String get reminderBody;

  /// No description provided for @reminderSettingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete diário'**
  String get reminderSettingTitle;

  /// No description provided for @reminderSettingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Um aviso às 9h, no seu horário'**
  String get reminderSettingSubtitle;

  /// No description provided for @reminderDenied.
  ///
  /// In pt, this message translates to:
  /// **'As notificações estão bloqueadas. Libere nas configurações do sistema para ativar.'**
  String get reminderDenied;

  /// No description provided for @reminderFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o lembrete. Tente novamente.'**
  String get reminderFailed;

  /// No description provided for @fontLicensesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Licenças das fontes'**
  String get fontLicensesTitle;

  /// No description provided for @fontLicenseFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a licença. Tente novamente.'**
  String get fontLicenseFailed;

  /// No description provided for @rewardFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível adicionar a recompensa agora. Seu resultado está salvo.'**
  String get rewardFailed;

  /// No description provided for @challengeSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desafiar um amigo'**
  String get challengeSectionTitle;

  /// No description provided for @challengeShareButton.
  ///
  /// In pt, this message translates to:
  /// **'Desafiar um amigo'**
  String get challengeShareButton;

  /// No description provided for @challengeShareText.
  ///
  /// In pt, this message translates to:
  /// **'🎬 Cineus: aposto que você não acerta esse filme.\nCódigo: {code}\n{link}'**
  String challengeShareText(Object code, Object link);

  /// No description provided for @challengeOpenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Abrir um desafio'**
  String get challengeOpenTitle;

  /// No description provided for @challengeCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'CIN-0000'**
  String get challengeCodeHint;

  /// No description provided for @challengeOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get challengeOpen;

  /// No description provided for @challengeInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido. Confira as letras e tente de novo.'**
  String get challengeInvalid;

  /// No description provided for @challengeBadge.
  ///
  /// In pt, this message translates to:
  /// **'DESAFIO DE AMIGO'**
  String get challengeBadge;

  /// No description provided for @challengeFilmNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Esse desafio aponta para um filme que não está nesta versão do app.'**
  String get challengeFilmNotFound;

  /// No description provided for @appTagline.
  ///
  /// In pt, this message translates to:
  /// **'Adivinhe filmes por dicas ou pôsteres.\nRelembre cores e avance por estágios.'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navFilms.
  ///
  /// In pt, this message translates to:
  /// **'Filmes'**
  String get navFilms;

  /// No description provided for @navPosters.
  ///
  /// In pt, this message translates to:
  /// **'Posters'**
  String get navPosters;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @backHome.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao Início'**
  String get backHome;

  /// No description provided for @statsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get statsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @movieNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Filme não encontrado'**
  String get movieNotFound;

  /// No description provided for @noMoviesInDatabase.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum filme na base'**
  String get noMoviesInDatabase;

  /// No description provided for @gameLoadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a partida.'**
  String get gameLoadFailed;

  /// No description provided for @loadingGame.
  ///
  /// In pt, this message translates to:
  /// **'Carregando partida…'**
  String get loadingGame;

  /// No description provided for @retryAction.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retryAction;

  /// No description provided for @statsLoadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar suas estatísticas.'**
  String get statsLoadFailed;

  /// No description provided for @stageNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Este estágio não existe ou não está mais disponível.'**
  String get stageNotFound;

  /// No description provided for @backToStages.
  ///
  /// In pt, this message translates to:
  /// **'Voltar aos Estágios'**
  String get backToStages;

  /// No description provided for @dailyChallengeLabel.
  ///
  /// In pt, this message translates to:
  /// **'DESAFIO DIÁRIO'**
  String get dailyChallengeLabel;

  /// No description provided for @modeClues.
  ///
  /// In pt, this message translates to:
  /// **'Dicas'**
  String get modeClues;

  /// No description provided for @modePoster.
  ///
  /// In pt, this message translates to:
  /// **'Poster'**
  String get modePoster;

  /// No description provided for @dailyDone.
  ///
  /// In pt, this message translates to:
  /// **'Desafio de hoje concluído!'**
  String get dailyDone;

  /// No description provided for @nextChallengeCountdown.
  ///
  /// In pt, this message translates to:
  /// **'Próximo em {hours}h {minutes}m {seconds}s'**
  String nextChallengeCountdown(Object hours, Object minutes, Object seconds);

  /// No description provided for @statPlayed.
  ///
  /// In pt, this message translates to:
  /// **'Jogados'**
  String get statPlayed;

  /// No description provided for @statWins.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get statWins;

  /// No description provided for @quickActionStatsSub.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico'**
  String get quickActionStatsSub;

  /// No description provided for @homeOpenChallenge.
  ///
  /// In pt, this message translates to:
  /// **'Abrir desafio'**
  String get homeOpenChallenge;

  /// No description provided for @homeOpenChallengeSub.
  ///
  /// In pt, this message translates to:
  /// **'Por código ou link'**
  String get homeOpenChallengeSub;

  /// No description provided for @cluesHeader.
  ///
  /// In pt, this message translates to:
  /// **'DICAS'**
  String get cluesHeader;

  /// No description provided for @cluesRevealed.
  ///
  /// In pt, this message translates to:
  /// **'{count} / {total} reveladas'**
  String cluesRevealed(int count, int total);

  /// No description provided for @clueFallback.
  ///
  /// In pt, this message translates to:
  /// **'Dica {number}'**
  String clueFallback(int number);

  /// No description provided for @clueNew.
  ///
  /// In pt, this message translates to:
  /// **'NOVO'**
  String get clueNew;

  /// No description provided for @lastAttempt.
  ///
  /// In pt, this message translates to:
  /// **'Última tentativa!'**
  String get lastAttempt;

  /// No description provided for @skipToClue.
  ///
  /// In pt, this message translates to:
  /// **'Pular · ver dica {next} (−1 pt)'**
  String skipToClue(int next);

  /// No description provided for @youGotIt.
  ///
  /// In pt, this message translates to:
  /// **'Você acertou!'**
  String get youGotIt;

  /// No description provided for @notThisTime.
  ///
  /// In pt, this message translates to:
  /// **'Não foi dessa vez.'**
  String get notThisTime;

  /// No description provided for @scoreLine.
  ///
  /// In pt, this message translates to:
  /// **'Pontuação: {score} pts'**
  String scoreLine(int score);

  /// No description provided for @tryAgainTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Tente novamente amanhã.'**
  String get tryAgainTomorrow;

  /// No description provided for @seeResult.
  ///
  /// In pt, this message translates to:
  /// **'Ver Resultado'**
  String get seeResult;

  /// No description provided for @stageNumber.
  ///
  /// In pt, this message translates to:
  /// **'Estágio {id}'**
  String stageNumber(Object id);

  /// No description provided for @franchiseHint.
  ///
  /// In pt, this message translates to:
  /// **'Quase! É dessa franquia, mas é outro filme!'**
  String get franchiseHint;

  /// No description provided for @scorePoints.
  ///
  /// In pt, this message translates to:
  /// **'PONTOS'**
  String get scorePoints;

  /// No description provided for @scoreAvailable.
  ///
  /// In pt, this message translates to:
  /// **'disponíveis'**
  String get scoreAvailable;

  /// No description provided for @whichMovie.
  ///
  /// In pt, this message translates to:
  /// **'Qual é o filme?'**
  String get whichMovie;

  /// No description provided for @movieNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome do filme...'**
  String get movieNameHint;

  /// No description provided for @attemptsHeader.
  ///
  /// In pt, this message translates to:
  /// **'TENTATIVAS'**
  String get attemptsHeader;

  /// No description provided for @errorCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 erro} other{{count} erros}}'**
  String errorCount(int count);

  /// No description provided for @searchChallenge.
  ///
  /// In pt, this message translates to:
  /// **'Desafio #{number} · '**
  String searchChallenge(Object number);

  /// No description provided for @searchStage.
  ///
  /// In pt, this message translates to:
  /// **'Estágio {id} · '**
  String searchStage(int id);

  /// No description provided for @searchFriendChallenge.
  ///
  /// In pt, this message translates to:
  /// **'Desafio de amigo · '**
  String get searchFriendChallenge;

  /// No description provided for @searchPoints.
  ///
  /// In pt, this message translates to:
  /// **' · {points, plural, =1{1 ponto} other{{points} pontos}}'**
  String searchPoints(int points);

  /// No description provided for @searchAvailableSuffix.
  ///
  /// In pt, this message translates to:
  /// **' em jogo'**
  String get searchAvailableSuffix;

  /// No description provided for @searchTypeHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite pelo menos 2 letras para buscar.'**
  String get searchTypeHint;

  /// No description provided for @searchNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum filme encontrado.'**
  String get searchNoResults;

  /// No description provided for @searchFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível buscar agora.'**
  String get searchFailed;

  /// No description provided for @blurLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desfoque '**
  String get blurLabel;

  /// No description provided for @share.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get share;

  /// No description provided for @resultShared.
  ///
  /// In pt, this message translates to:
  /// **'Resultado compartilhado!'**
  String get resultShared;

  /// No description provided for @resultCopied.
  ///
  /// In pt, this message translates to:
  /// **'Resultado copiado!'**
  String get resultCopied;

  /// No description provided for @noTicketsForNext.
  ///
  /// In pt, this message translates to:
  /// **'Sem tickets para o próximo'**
  String get noTicketsForNext;

  /// No description provided for @nextChallengeIn.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO DESAFIO EM'**
  String get nextChallengeIn;

  /// No description provided for @stagesSubtitleClues.
  ///
  /// In pt, this message translates to:
  /// **'Avance por estágios e desbloqueie novos filmes.'**
  String get stagesSubtitleClues;

  /// No description provided for @stagesSubtitlePosters.
  ///
  /// In pt, this message translates to:
  /// **'Adivinhe filmes por pôsteres desfocados.'**
  String get stagesSubtitlePosters;

  /// No description provided for @locked.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueado'**
  String get locked;

  /// No description provided for @filmsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 filmes} =1{1 filme} other{{count} filmes}}'**
  String filmsCount(int count);

  /// No description provided for @stageSemanticsProgress.
  ///
  /// In pt, this message translates to:
  /// **'{name}, {done} de {total} concluídos'**
  String stageSemanticsProgress(Object name, int done, int total);

  /// No description provided for @filmsDone.
  ///
  /// In pt, this message translates to:
  /// **'filmes concluídos'**
  String get filmsDone;

  /// No description provided for @postersDone.
  ///
  /// In pt, this message translates to:
  /// **'posters concluídos'**
  String get postersDone;

  /// No description provided for @stageProgressLine.
  ///
  /// In pt, this message translates to:
  /// **'{done} / {total} {label}'**
  String stageProgressLine(int done, int total, Object label);

  /// No description provided for @itemFilm.
  ///
  /// In pt, this message translates to:
  /// **'Filme'**
  String get itemFilm;

  /// No description provided for @itemPoster.
  ///
  /// In pt, this message translates to:
  /// **'Poster'**
  String get itemPoster;

  /// No description provided for @slotNotStarted.
  ///
  /// In pt, this message translates to:
  /// **'Não iniciado'**
  String get slotNotStarted;

  /// No description provided for @slotMissedRetry.
  ///
  /// In pt, this message translates to:
  /// **'Não acertou'**
  String get slotMissedRetry;

  /// No description provided for @slotInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get slotInProgress;

  /// No description provided for @slotPoints.
  ///
  /// In pt, this message translates to:
  /// **'{score, plural, =0{0 pontos} =1{1 ponto} other{{score} pontos}}'**
  String slotPoints(int score);

  /// No description provided for @actionContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// No description provided for @noTicketsShort.
  ///
  /// In pt, this message translates to:
  /// **'Sem tickets'**
  String get noTicketsShort;

  /// No description provided for @revealMore.
  ///
  /// In pt, this message translates to:
  /// **'Revelar mais · −1 pt'**
  String get revealMore;

  /// No description provided for @worthPoints.
  ///
  /// In pt, this message translates to:
  /// **'Vale {points} pts'**
  String worthPoints(int points);

  /// No description provided for @gotItAtLevel.
  ///
  /// In pt, this message translates to:
  /// **'Acertou no nível {level}!'**
  String gotItAtLevel(int level);

  /// No description provided for @betterLuckTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Melhor sorte amanhã'**
  String get betterLuckTomorrow;

  /// No description provided for @blurAndPoints.
  ///
  /// In pt, this message translates to:
  /// **'Desfoque {blur} · {points} pts'**
  String blurAndPoints(Object blur, int points);

  /// No description provided for @youRecognized.
  ///
  /// In pt, this message translates to:
  /// **'Você reconheceu!'**
  String get youRecognized;

  /// No description provided for @didntRecognize.
  ///
  /// In pt, this message translates to:
  /// **'Não reconheceu'**
  String get didntRecognize;

  /// No description provided for @itWas.
  ///
  /// In pt, this message translates to:
  /// **'Era: {title}'**
  String itWas(Object title);

  /// No description provided for @pointsPlain.
  ///
  /// In pt, this message translates to:
  /// **'{score, plural, =0{0 pontos} =1{1 ponto} other{{score} pontos}}'**
  String pointsPlain(int score);

  /// No description provided for @youDidntGuess.
  ///
  /// In pt, this message translates to:
  /// **'Você não adivinhou'**
  String get youDidntGuess;

  /// No description provided for @nextWithTicket.
  ///
  /// In pt, this message translates to:
  /// **'Próximo · 1 ticket'**
  String get nextWithTicket;

  /// No description provided for @finish.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get finish;

  /// No description provided for @hintDirector.
  ///
  /// In pt, this message translates to:
  /// **'Diretor'**
  String get hintDirector;

  /// No description provided for @hintYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get hintYear;

  /// No description provided for @hintRuntime.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get hintRuntime;

  /// No description provided for @unknownDirector.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get unknownDirector;

  /// No description provided for @runtimeMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min'**
  String runtimeMinutes(int minutes);

  /// No description provided for @oneTicket.
  ///
  /// In pt, this message translates to:
  /// **'1 ticket'**
  String get oneTicket;

  /// No description provided for @noTicketsLower.
  ///
  /// In pt, this message translates to:
  /// **'sem tickets'**
  String get noTicketsLower;

  /// No description provided for @noTicketsForHint.
  ///
  /// In pt, this message translates to:
  /// **'Sem tickets para comprar dica'**
  String get noTicketsForHint;

  /// No description provided for @buyHintSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Comprar dica {label} por {cost} ticket'**
  String buyHintSemantics(Object label, int cost);

  /// No description provided for @ticketsEarned.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{+1 ticket!} other{+{count} tickets!}}'**
  String ticketsEarned(int count);

  /// No description provided for @rewardDailyWin.
  ///
  /// In pt, this message translates to:
  /// **'Desafio diário concluído'**
  String get rewardDailyWin;

  /// No description provided for @rewardStreak.
  ///
  /// In pt, this message translates to:
  /// **'Sequência de {days} dias'**
  String rewardStreak(int days);

  /// No description provided for @rewardStageComplete.
  ///
  /// In pt, this message translates to:
  /// **'Estágio {id} completo'**
  String rewardStageComplete(int id);

  /// No description provided for @streakAtRisk.
  ///
  /// In pt, this message translates to:
  /// **'Sua sequência está em risco'**
  String get streakAtRisk;

  /// No description provided for @streakRecoverBody.
  ///
  /// In pt, this message translates to:
  /// **'Você não jogou em {day}. Use {cost} tickets para proteger esse dia e manter a sequência.'**
  String streakRecoverBody(Object day, int cost);

  /// No description provided for @protectStreak.
  ///
  /// In pt, this message translates to:
  /// **'Proteger sequência · {cost} tickets'**
  String protectStreak(int cost);

  /// No description provided for @protecting.
  ///
  /// In pt, this message translates to:
  /// **'Protegendo…'**
  String get protecting;

  /// No description provided for @needTickets.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de {cost} tickets'**
  String needTickets(int cost);

  /// No description provided for @streakProtected.
  ///
  /// In pt, this message translates to:
  /// **'Sequência protegida!'**
  String get streakProtected;

  /// No description provided for @statGames.
  ///
  /// In pt, this message translates to:
  /// **'JOGOS'**
  String get statGames;

  /// No description provided for @statWinsCaps.
  ///
  /// In pt, this message translates to:
  /// **'VITÓRIAS'**
  String get statWinsCaps;

  /// No description provided for @statRate.
  ///
  /// In pt, this message translates to:
  /// **'TAXA'**
  String get statRate;

  /// No description provided for @statAverage.
  ///
  /// In pt, this message translates to:
  /// **'MÉDIA'**
  String get statAverage;

  /// No description provided for @statAverageSub.
  ///
  /// In pt, this message translates to:
  /// **'dicas'**
  String get statAverageSub;

  /// No description provided for @statAveragePosterSub.
  ///
  /// In pt, this message translates to:
  /// **'níveis'**
  String get statAveragePosterSub;

  /// No description provided for @currentStreakTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sequência Atual'**
  String get currentStreakTitle;

  /// No description provided for @dayCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 dias} =1{1 dia} other{{count} dias}}'**
  String dayCount(int count);

  /// No description provided for @bestLabel.
  ///
  /// In pt, this message translates to:
  /// **'Melhor'**
  String get bestLabel;

  /// No description provided for @playToSeeDistribution.
  ///
  /// In pt, this message translates to:
  /// **'Jogue para ver a distribuição'**
  String get playToSeeDistribution;

  /// No description provided for @pointsDistribution.
  ///
  /// In pt, this message translates to:
  /// **'DISTRIBUIÇÃO DE PONTOS'**
  String get pointsDistribution;

  /// No description provided for @achievementsHeader.
  ///
  /// In pt, this message translates to:
  /// **'CONQUISTAS'**
  String get achievementsHeader;

  /// No description provided for @yourProfileHeader.
  ///
  /// In pt, this message translates to:
  /// **'SEU PERFIL'**
  String get yourProfileHeader;

  /// No description provided for @profileSummary.
  ///
  /// In pt, this message translates to:
  /// **'Você vai melhor em {best} ({bestPct}%) e pior em {worst} ({worstPct}%).'**
  String profileSummary(Object best, int bestPct, Object worst, int worstPct);

  /// No description provided for @byGenre.
  ///
  /// In pt, this message translates to:
  /// **'Por gênero'**
  String get byGenre;

  /// No description provided for @byDecade.
  ///
  /// In pt, this message translates to:
  /// **'Por década'**
  String get byDecade;

  /// No description provided for @recentGamesHeader.
  ///
  /// In pt, this message translates to:
  /// **'JOGOS RECENTES'**
  String get recentGamesHeader;

  /// No description provided for @unknownMovie.
  ///
  /// In pt, this message translates to:
  /// **'Filme desconhecido'**
  String get unknownMovie;

  /// No description provided for @cluesUsedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 dicas} =1{1 dica} other{{count} dicas}}'**
  String cluesUsedCount(int count);

  /// No description provided for @defeatShort.
  ///
  /// In pt, this message translates to:
  /// **'Derrota'**
  String get defeatShort;

  /// No description provided for @bucketSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{label}: {pct} por cento de acerto em {played} jogos'**
  String bucketSemantics(Object label, int pct, int played);

  /// No description provided for @bucketValue.
  ///
  /// In pt, this message translates to:
  /// **'{pct}% · {played}'**
  String bucketValue(int pct, int played);

  /// No description provided for @achievementUnlocked.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueada'**
  String get achievementUnlocked;

  /// No description provided for @achievementInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em progresso {progress}'**
  String achievementInProgress(Object progress);

  /// No description provided for @achFirstWin.
  ///
  /// In pt, this message translates to:
  /// **'Primeira vitória'**
  String get achFirstWin;

  /// No description provided for @achFirstWinDesc.
  ///
  /// In pt, this message translates to:
  /// **'Acerte seu primeiro desafio diário.'**
  String get achFirstWinDesc;

  /// No description provided for @achPerfect.
  ///
  /// In pt, this message translates to:
  /// **'Sem titubear'**
  String get achPerfect;

  /// No description provided for @achPerfectDesc.
  ///
  /// In pt, this message translates to:
  /// **'Acerte na primeira dica, valendo 10 pontos.'**
  String get achPerfectDesc;

  /// No description provided for @achStreak7.
  ///
  /// In pt, this message translates to:
  /// **'Semana cheia'**
  String get achStreak7;

  /// No description provided for @achStreak7Desc.
  ///
  /// In pt, this message translates to:
  /// **'7 dias seguidos acertando.'**
  String get achStreak7Desc;

  /// No description provided for @achStreak30.
  ///
  /// In pt, this message translates to:
  /// **'Mês perfeito'**
  String get achStreak30;

  /// No description provided for @achStreak30Desc.
  ///
  /// In pt, this message translates to:
  /// **'30 dias seguidos acertando.'**
  String get achStreak30Desc;

  /// No description provided for @achGames50.
  ///
  /// In pt, this message translates to:
  /// **'Frequentador'**
  String get achGames50;

  /// No description provided for @achGames50Desc.
  ///
  /// In pt, this message translates to:
  /// **'Jogue 50 desafios diários.'**
  String get achGames50Desc;

  /// No description provided for @achStages5.
  ///
  /// In pt, this message translates to:
  /// **'Maratonista'**
  String get achStages5;

  /// No description provided for @achStages5Desc.
  ///
  /// In pt, this message translates to:
  /// **'Complete 5 estágios.'**
  String get achStages5Desc;

  /// No description provided for @achTickets100.
  ///
  /// In pt, this message translates to:
  /// **'Bilheteria'**
  String get achTickets100;

  /// No description provided for @achTickets100Desc.
  ///
  /// In pt, this message translates to:
  /// **'Ganhe 100 tickets jogando.'**
  String get achTickets100Desc;

  /// No description provided for @quickGuide.
  ///
  /// In pt, this message translates to:
  /// **'GUIA RÁPIDO'**
  String get quickGuide;

  /// No description provided for @gotItLetsPlay.
  ///
  /// In pt, this message translates to:
  /// **'Entendi, vamos jogar!'**
  String get gotItLetsPlay;

  /// No description provided for @languageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Padrão do sistema'**
  String get languageSystem;

  /// No description provided for @contentLanguageNote.
  ///
  /// In pt, this message translates to:
  /// **'As dicas e os títulos dos filmes vêm do catálogo em português.'**
  String get contentLanguageNote;

  /// No description provided for @rewardedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ganhar tickets'**
  String get rewardedTitle;

  /// No description provided for @rewardedBody.
  ///
  /// In pt, this message translates to:
  /// **'Assista a um anúncio opcional e ganhe {amount} tickets. Restam {remaining} recompensas hoje.'**
  String rewardedBody(int amount, int remaining);

  /// No description provided for @rewardedAction.
  ///
  /// In pt, this message translates to:
  /// **'Assistir e ganhar +{amount} tickets'**
  String rewardedAction(int amount);

  /// No description provided for @rewardedDone.
  ///
  /// In pt, this message translates to:
  /// **'Tickets adicionados!'**
  String get rewardedDone;

  /// No description provided for @passTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cineus Pass'**
  String get passTitle;

  /// No description provided for @passBody.
  ///
  /// In pt, this message translates to:
  /// **'Todo o gameplay continua gratuito. O Pass remove anúncios não opcionais e pode incluir benefícios de conveniência.'**
  String get passBody;

  /// No description provided for @passActive.
  ///
  /// In pt, this message translates to:
  /// **'Pass ativo · sem anúncios não opcionais'**
  String get passActive;

  /// No description provided for @passGet.
  ///
  /// In pt, this message translates to:
  /// **'Obter Pass {price}'**
  String passGet(String price);

  /// No description provided for @passRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar compra'**
  String get passRestore;

  /// No description provided for @tickets.
  ///
  /// In pt, this message translates to:
  /// **'{current}/{max}'**
  String tickets(int current, int max);

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cinema, todo dia.'**
  String get homeTitle;

  /// No description provided for @dailyFree.
  ///
  /// In pt, this message translates to:
  /// **'GRÁTIS'**
  String get dailyFree;

  /// No description provided for @dailyWinPoints.
  ///
  /// In pt, this message translates to:
  /// **'{score} pontos · Acertou'**
  String dailyWinPoints(int score);

  /// No description provided for @dailyLost.
  ///
  /// In pt, this message translates to:
  /// **'Concluído · Não foi desta vez'**
  String get dailyLost;

  /// No description provided for @dailyPlaying.
  ///
  /// In pt, this message translates to:
  /// **'Partida em andamento'**
  String get dailyPlaying;

  /// No description provided for @ticketBalance.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 tickets} =1{1 ticket} other{{count} tickets}}'**
  String ticketBalance(int count);

  /// No description provided for @ticketDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seus tickets'**
  String get ticketDetailsTitle;

  /// No description provided for @ticketDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diários'**
  String get ticketDaily;

  /// No description provided for @ticketBonus.
  ///
  /// In pt, this message translates to:
  /// **'Bônus'**
  String get ticketBonus;

  /// No description provided for @ticketDailyDetail.
  ///
  /// In pt, this message translates to:
  /// **'{count} de {max}'**
  String ticketDailyDetail(int count, int max);

  /// No description provided for @ticketResetInfo.
  ///
  /// In pt, this message translates to:
  /// **'Os tickets diários são repostos na virada UTC. Os bônus continuam com você.'**
  String get ticketResetInfo;

  /// No description provided for @ticketUsageInfo.
  ///
  /// In pt, this message translates to:
  /// **'Daily e desafios de amigos são gratuitos. Iniciar ou refazer um filme de estágio e cada dica extra custam 1 ticket.'**
  String get ticketUsageInfo;

  /// No description provided for @ticketBalanceFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seu saldo.'**
  String get ticketBalanceFailed;

  /// No description provided for @ticketResetCountdown.
  ///
  /// In pt, this message translates to:
  /// **'Reposição em {hours}h {minutes}m'**
  String ticketResetCountdown(Object hours, Object minutes);

  /// No description provided for @confirmGuess.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar palpite'**
  String get confirmGuess;

  /// No description provided for @selectedMovieLabel.
  ///
  /// In pt, this message translates to:
  /// **'Filme selecionado'**
  String get selectedMovieLabel;

  /// No description provided for @selectMovieSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar {title}, {year}'**
  String selectMovieSemantics(Object title, int year);

  /// No description provided for @guessSaveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar seu palpite. Tente novamente.'**
  String get guessSaveFailed;

  /// No description provided for @savingGuess.
  ///
  /// In pt, this message translates to:
  /// **'Salvando palpite…'**
  String get savingGuess;

  /// No description provided for @gameActionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a ação. Tente novamente.'**
  String get gameActionFailed;

  /// No description provided for @hintSaveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a compra da dica. Confira seu saldo e tente novamente.'**
  String get hintSaveFailed;

  /// No description provided for @wrongGuessRevealed.
  ///
  /// In pt, this message translates to:
  /// **'Palpite incorreto. Novo passo revelado.'**
  String get wrongGuessRevealed;

  /// No description provided for @clueRevealedAnnouncement.
  ///
  /// In pt, this message translates to:
  /// **'Dica {number} revelada.'**
  String clueRevealedAnnouncement(int number);

  /// No description provided for @posterRevealedAnnouncement.
  ///
  /// In pt, this message translates to:
  /// **'Nível {number} revelado.'**
  String posterRevealedAnnouncement(int number);

  /// No description provided for @lastGuessLabel.
  ///
  /// In pt, this message translates to:
  /// **'Último palpite: {title}'**
  String lastGuessLabel(Object title);

  /// No description provided for @ticketHelpAction.
  ///
  /// In pt, this message translates to:
  /// **'Entender os tickets'**
  String get ticketHelpAction;

  /// No description provided for @ticketEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Sem tickets para dicas extras. Você pode continuar esta partida gratuitamente.'**
  String get ticketEmptyHint;

  /// No description provided for @noTicketDailyTip.
  ///
  /// In pt, this message translates to:
  /// **'O desafio diário é gratuito nos dois modos.'**
  String get noTicketDailyTip;

  /// No description provided for @gameAnswer.
  ///
  /// In pt, this message translates to:
  /// **'Responder'**
  String get gameAnswer;

  /// No description provided for @posterStep.
  ///
  /// In pt, this message translates to:
  /// **'Nível {step} de {total}'**
  String posterStep(int step, int total);

  /// No description provided for @searchResultCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 filme encontrado} other{{count} filmes encontrados}}'**
  String searchResultCount(int count);

  /// No description provided for @challengeInputLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código ou link Cineus'**
  String get challengeInputLabel;

  /// No description provided for @pasteChallenge.
  ///
  /// In pt, this message translates to:
  /// **'Colar código ou link'**
  String get pasteChallenge;

  /// No description provided for @challengeLoadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o desafio. Tente novamente.'**
  String get challengeLoadFailed;

  /// No description provided for @editChallenge.
  ///
  /// In pt, this message translates to:
  /// **'Editar código ou link'**
  String get editChallenge;

  /// No description provided for @resultUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Este resultado não está disponível. Volte ao jogo ou à tela inicial.'**
  String get resultUnavailable;

  /// No description provided for @returnToGame.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao jogo'**
  String get returnToGame;

  /// No description provided for @resultProgress.
  ///
  /// In pt, this message translates to:
  /// **'Passos: {step}/{total}'**
  String resultProgress(int step, int total);

  /// No description provided for @resultScore.
  ///
  /// In pt, this message translates to:
  /// **'{score, plural, =0{0 pontos} =1{1 ponto} other{{score} pontos}}'**
  String resultScore(int score);

  /// No description provided for @shareImage.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar cartão'**
  String get shareImage;

  /// No description provided for @copyResultText.
  ///
  /// In pt, this message translates to:
  /// **'Copiar resultado em texto'**
  String get copyResultText;

  /// No description provided for @shareCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu cartão de resultado'**
  String get shareCardTitle;

  /// No description provided for @shareFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o compartilhamento. Tente novamente.'**
  String get shareFailed;

  /// No description provided for @copyFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível copiar. Tente novamente.'**
  String get copyFailed;

  /// No description provided for @challengeInviteHelp.
  ///
  /// In pt, this message translates to:
  /// **'Envie o código ou link para um amigo jogar este filme no mesmo modo.'**
  String get challengeInviteHelp;

  /// No description provided for @shareChallengeCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar convite'**
  String get shareChallengeCopy;

  /// No description provided for @dailyInviteWarning.
  ///
  /// In pt, this message translates to:
  /// **'O convite abre este mesmo filme. O cartão do Daily continua sem a resposta.'**
  String get dailyInviteWarning;

  /// No description provided for @sharePreviewAction.
  ///
  /// In pt, this message translates to:
  /// **'Ver cartão'**
  String get sharePreviewAction;

  /// No description provided for @shareModeClues.
  ///
  /// In pt, this message translates to:
  /// **'Dicas'**
  String get shareModeClues;

  /// No description provided for @shareModePoster.
  ///
  /// In pt, this message translates to:
  /// **'Poster'**
  String get shareModePoster;

  /// No description provided for @resultVictoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Acertou!'**
  String get resultVictoryLabel;

  /// No description provided for @resultDefeatLabel.
  ///
  /// In pt, this message translates to:
  /// **'Não foi desta vez'**
  String get resultDefeatLabel;

  /// No description provided for @challengeEntryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Cole o código ou link que um amigo enviou. O modo do jogo vem no convite.'**
  String get challengeEntryHelp;

  /// No description provided for @stagesCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Seu próximo estágio'**
  String get stagesCurrent;

  /// No description provided for @stageOpen.
  ///
  /// In pt, this message translates to:
  /// **'Ver partidas'**
  String get stageOpen;

  /// No description provided for @stageUnlockAfter.
  ///
  /// In pt, this message translates to:
  /// **'Complete {stage} neste modo para desbloquear.'**
  String stageUnlockAfter(Object stage);

  /// No description provided for @stageCompleteLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estágio concluído'**
  String get stageCompleteLabel;

  /// No description provided for @stageCostHelp.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar ou tentar novamente custa 1 ticket. Retomar uma partida é grátis.'**
  String get stageCostHelp;

  /// No description provided for @stageNoTicketsHelp.
  ///
  /// In pt, this message translates to:
  /// **'Sem tickets para uma nova partida? Continue as partidas em andamento grátis ou jogue o Daily. Confira quando seu saldo será renovado.'**
  String get stageNoTicketsHelp;

  /// No description provided for @stageLoadingAction.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo partida…'**
  String get stageLoadingAction;

  /// No description provided for @statsOverview.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get statsOverview;

  /// No description provided for @statsAchievementsTab.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get statsAchievementsTab;

  /// No description provided for @statsDailyOnly.
  ///
  /// In pt, this message translates to:
  /// **'Histórico do Daily · {mode}'**
  String statsDailyOnly(Object mode);

  /// No description provided for @statsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua história começa aqui'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Conclua um desafio diário para registrar seu primeiro resultado.'**
  String get statsEmptyBody;

  /// No description provided for @streakEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sequência ativa'**
  String get streakEmpty;

  /// No description provided for @streakDailyHelp.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias diárias consecutivas neste modo. Dias protegidos mantêm a sequência, mas não somam vitórias.'**
  String get streakDailyHelp;

  /// No description provided for @protectedDays.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 dias protegidos} =1{1 dia protegido} other{{count} dias protegidos}}'**
  String protectedDays(int count);

  /// No description provided for @protectedDaysHelp.
  ///
  /// In pt, this message translates to:
  /// **'Proteções registradas no histórico, válidas para os dois modos.'**
  String get protectedDaysHelp;

  /// No description provided for @achievementScopeDailyClues.
  ///
  /// In pt, this message translates to:
  /// **'Daily · Dicas'**
  String get achievementScopeDailyClues;

  /// No description provided for @achievementScopeStagesBoth.
  ///
  /// In pt, this message translates to:
  /// **'Estágios · Dicas e Poster'**
  String get achievementScopeStagesBoth;

  /// No description provided for @achievementScopeRewardsBoth.
  ///
  /// In pt, this message translates to:
  /// **'Recompensas · Dicas e Poster'**
  String get achievementScopeRewardsBoth;

  /// No description provided for @achievementRulesHelp.
  ///
  /// In pt, this message translates to:
  /// **'As conquistas de vitórias, pontos, sequência e partidas usam o Daily de Dicas. Estágios completos e tickets ganhos somam os dois modos. Convites não contam como Daily.'**
  String get achievementRulesHelp;

  /// No description provided for @achievementLockedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não desbloqueada'**
  String get achievementLockedLabel;

  /// No description provided for @achievementProgress.
  ///
  /// In pt, this message translates to:
  /// **'{done} de {total} conquistas desbloqueadas'**
  String achievementProgress(int done, int total);

  /// No description provided for @streakProtectFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível proteger sua sequência. Tente novamente.'**
  String get streakProtectFailed;

  /// No description provided for @stageDailyAction.
  ///
  /// In pt, this message translates to:
  /// **'Ver Daily grátis'**
  String get stageDailyAction;

  /// No description provided for @guideTitle.
  ///
  /// In pt, this message translates to:
  /// **'Experimente os três modos'**
  String get guideTitle;

  /// No description provided for @guideCluesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dicas: do mistério à resposta'**
  String get guideCluesTitle;

  /// No description provided for @guideCluesBody.
  ///
  /// In pt, this message translates to:
  /// **'Acerte com até 10 dicas. Cada revelação ou erro reduz a nota em 1 ponto.'**
  String get guideCluesBody;

  /// No description provided for @guidePosterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Poster: revele aos poucos'**
  String get guidePosterTitle;

  /// No description provided for @guidePosterBody.
  ///
  /// In pt, this message translates to:
  /// **'Acerte com até 5 níveis de desfoque. Revelar mais ou errar reduz a nota em 1 ponto.'**
  String get guidePosterBody;

  /// No description provided for @guideAnswerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha, confira e confirme'**
  String get guideAnswerTitle;

  /// No description provided for @guideAnswerBody.
  ///
  /// In pt, this message translates to:
  /// **'Busque pelo título em português ou original. Selecione o filme com o ano correto e confirme.'**
  String get guideAnswerBody;

  /// No description provided for @guideWrongTitle.
  ///
  /// In pt, this message translates to:
  /// **'Um erro avança o jogo'**
  String get guideWrongTitle;

  /// No description provided for @guideWrongBody.
  ///
  /// In pt, this message translates to:
  /// **'Errar revela automaticamente a próxima dica ou nível. Na última tentativa, um erro encerra a partida com zero pontos.'**
  String get guideWrongBody;

  /// No description provided for @guideTicketsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tickets: saiba quando usar'**
  String get guideTicketsTitle;

  /// No description provided for @guideTicketsBody.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar ou refazer um estágio custa 1 ticket. Retomar é grátis. Em Precisa de ajuda?, use 1 ticket ou um vídeo opcional para liberar a ajuda e guardar 1 ticket. Diários e convites de filmes são gratuitos.'**
  String get guideTicketsBody;

  /// No description provided for @guideTicketsRenewal.
  ///
  /// In pt, this message translates to:
  /// **'O saldo diário volta a 10 à meia-noite UTC. Tickets extras ficam guardados. Concluir o diário de Cores rende +2 uma vez por data; estágios não dão essa recompensa.'**
  String get guideTicketsRenewal;

  /// No description provided for @guideDailyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Diários no Início'**
  String get guideDailyTitle;

  /// No description provided for @guideDailyBody.
  ///
  /// In pt, this message translates to:
  /// **'Dicas, Pôster e Cores têm um diário gratuito no Início. Eles mudam à meia-noite UTC. A contagem na tela mostra quanto falta.'**
  String get guideDailyBody;

  /// No description provided for @guideStagesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avance no seu ritmo'**
  String get guideStagesTitle;

  /// No description provided for @guideStagesBody.
  ///
  /// In pt, this message translates to:
  /// **'Nas abas Filmes, Pôsteres e Cores, conclua as partidas para liberar o estágio seguinte. Filmes e Pôsteres têm 10 partidas por estágio; Cores tem duas partidas de cinco personagens diferentes. O progresso é separado em cada modo.'**
  String get guideStagesBody;

  /// No description provided for @guideSaveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar que você viu o guia. Tente novamente.'**
  String get guideSaveFailed;

  /// No description provided for @settingsPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get settingsPreferences;

  /// No description provided for @settingsHelpSection.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e suporte'**
  String get settingsHelpSection;

  /// No description provided for @supportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Suporte'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In pt, this message translates to:
  /// **'Encontre ajuda ou relate um problema no GitHub. Abrir o link não envia uma mensagem automaticamente. Evite publicar dados pessoais.'**
  String get supportBody;

  /// No description provided for @supportOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir suporte'**
  String get supportOpen;

  /// No description provided for @supportCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link de suporte'**
  String get supportCopy;

  /// No description provided for @supportOpenFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o navegador. Copie o link para acessar o suporte.'**
  String get supportOpenFailed;

  /// No description provided for @supportCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link de suporte copiado.'**
  String get supportCopied;

  /// No description provided for @supportCopyFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível copiar. Você pode selecionar o link abaixo.'**
  String get supportCopyFailed;

  /// No description provided for @searchEmptyHelp.
  ///
  /// In pt, this message translates to:
  /// **'Confira a grafia ou tente o título original. Selecione um filme com o ano correto antes de confirmar.'**
  String get searchEmptyHelp;

  /// No description provided for @colorTrainingBadge.
  ///
  /// In pt, this message translates to:
  /// **'TREINO'**
  String get colorTrainingBadge;

  /// No description provided for @colorRoundProgress.
  ///
  /// In pt, this message translates to:
  /// **'Rodada {current}/{total}'**
  String colorRoundProgress(int current, int total);

  /// No description provided for @colorComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get colorComplete;

  /// No description provided for @colorTrainingRulesBody.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste a cor, confirme e compare com a referência. São cinco rodadas e uma média final. A dica desconta 1 ponto.'**
  String get colorTrainingRulesBody;

  /// No description provided for @colorConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar cor'**
  String get colorConfirm;

  /// No description provided for @colorNextRound.
  ///
  /// In pt, this message translates to:
  /// **'Próxima rodada'**
  String get colorNextRound;

  /// No description provided for @colorSeeFinal.
  ///
  /// In pt, this message translates to:
  /// **'Ver média final'**
  String get colorSeeFinal;

  /// No description provided for @colorPlayAgain.
  ///
  /// In pt, this message translates to:
  /// **'Jogar novamente'**
  String get colorPlayAgain;

  /// No description provided for @colorRestart.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar treino'**
  String get colorRestart;

  /// No description provided for @colorHintAction.
  ///
  /// In pt, this message translates to:
  /// **'Usar dica · −1 ponto'**
  String get colorHintAction;

  /// No description provided for @colorHintApplied.
  ///
  /// In pt, this message translates to:
  /// **'Dica usada · −1 ponto'**
  String get colorHintApplied;

  /// No description provided for @colorRoundResult.
  ///
  /// In pt, this message translates to:
  /// **'Seu tom, lado a lado.'**
  String get colorRoundResult;

  /// No description provided for @colorReferenceTone.
  ///
  /// In pt, this message translates to:
  /// **'Referência'**
  String get colorReferenceTone;

  /// No description provided for @colorScoreValue.
  ///
  /// In pt, this message translates to:
  /// **'{score} / 10'**
  String colorScoreValue(String score);

  /// No description provided for @colorFinalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cinco cores. Sua memória.'**
  String get colorFinalTitle;

  /// No description provided for @colorAverageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sua média'**
  String get colorAverageLabel;

  /// No description provided for @colorDiscardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair deste treino?'**
  String get colorDiscardTitle;

  /// No description provided for @colorDiscardBody.
  ///
  /// In pt, this message translates to:
  /// **'O progresso desta partida será perdido. Um novo treino começa na primeira rodada.'**
  String get colorDiscardBody;

  /// No description provided for @colorKeepPlaying.
  ///
  /// In pt, this message translates to:
  /// **'Continuar jogando'**
  String get colorKeepPlaying;

  /// No description provided for @colorDiscardAction.
  ///
  /// In pt, this message translates to:
  /// **'Descartar partida'**
  String get colorDiscardAction;

  /// No description provided for @colorDailyBadge.
  ///
  /// In pt, this message translates to:
  /// **'DIÁRIO'**
  String get colorDailyBadge;

  /// No description provided for @colorDailyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desafio diário'**
  String get colorDailyTitle;

  /// No description provided for @colorResume.
  ///
  /// In pt, this message translates to:
  /// **'Continuar partida'**
  String get colorResume;

  /// No description provided for @colorResumeRound.
  ///
  /// In pt, this message translates to:
  /// **'Continuar · rodada {round}/5'**
  String colorResumeRound(int round);

  /// No description provided for @colorPendingDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diário pendente'**
  String get colorPendingDaily;

  /// No description provided for @colorOldDailyPolicy.
  ///
  /// In pt, this message translates to:
  /// **'Pode terminar esta partida quando quiser. Ela mantém a data original e não ocupa o diário de hoje.'**
  String get colorOldDailyPolicy;

  /// No description provided for @colorHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Cores'**
  String get colorHistory;

  /// No description provided for @colorOpenHistory.
  ///
  /// In pt, this message translates to:
  /// **'Ver meu histórico'**
  String get colorOpenHistory;

  /// No description provided for @colorHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não concluiu uma partida nesta categoria.'**
  String get colorHistoryEmpty;

  /// No description provided for @colorHistoryFive.
  ///
  /// In pt, this message translates to:
  /// **'Cinco respostas confirmadas. Abra para rever cada rodada.'**
  String get colorHistoryFive;

  /// No description provided for @colorSeeResult.
  ///
  /// In pt, this message translates to:
  /// **'Rever resultado'**
  String get colorSeeResult;

  /// No description provided for @colorSaving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando sua partida…'**
  String get colorSaving;

  /// No description provided for @colorSaveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente novamente antes de sair; a partida não avançou.'**
  String get colorSaveFailed;

  /// No description provided for @colorReloadSaved.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar a versão salva'**
  String get colorReloadSaved;

  /// No description provided for @colorBackHub.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para Cores'**
  String get colorBackHub;

  /// No description provided for @colorLoadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir os dados de Cores. Eles foram preservados. Tente novamente; uma partida de versão incompatível precisa de uma atualização do app.'**
  String get colorLoadFailed;

  /// No description provided for @colorLoading.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo suas cores salvas…'**
  String get colorLoading;

  /// No description provided for @colorReplaceTrainingBody.
  ///
  /// In pt, this message translates to:
  /// **'Começar outro treino substitui o treino em andamento. Seus resultados concluídos continuam no histórico.'**
  String get colorReplaceTrainingBody;

  /// No description provided for @colorSavedRules.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste a cor e confirme para comparar com a referência. São cinco rodadas e uma média final. A dica desconta 1 ponto. Estágios ficam em Cores; o diário fica no Início.'**
  String get colorSavedRules;

  /// No description provided for @colorReplaceTrainingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Começar outro treino?'**
  String get colorReplaceTrainingTitle;

  /// No description provided for @colorReplaceTrainingAction.
  ///
  /// In pt, this message translates to:
  /// **'Substituir treino'**
  String get colorReplaceTrainingAction;

  /// No description provided for @colorGuideTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como jogar Cores'**
  String get colorGuideTitle;

  /// No description provided for @colorGuideAdjustTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dê cor ao personagem'**
  String get colorGuideAdjustTitle;

  /// No description provided for @colorGuideAdjustBody.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste a cor do personagem e veja o resultado em tempo real.'**
  String get colorGuideAdjustBody;

  /// No description provided for @colorGuideResultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compare sua escolha'**
  String get colorGuideResultTitle;

  /// No description provided for @colorGuideResultBody.
  ///
  /// In pt, this message translates to:
  /// **'Cores próximas à referência recebem até 10 pontos. Cada partida tem cinco rodadas; a nota final é a média.'**
  String get colorGuideResultBody;

  /// No description provided for @colorGuideHintRule.
  ///
  /// In pt, this message translates to:
  /// **'Uma ajuda por rodada desconta 1 ponto. A dica rápida é gratuita; a orientação de ajustes usa 1 ticket ou um vídeo opcional.'**
  String get colorGuideHintRule;

  /// No description provided for @colorGuideDailyRule.
  ///
  /// In pt, this message translates to:
  /// **'Na aba Cores, cada estágio reúne dez personagens diferentes em duas partidas de cinco. Conclua as duas para abrir o próximo. O desafio diário fica no Início.'**
  String get colorGuideDailyRule;

  /// No description provided for @colorGuideSaveRule.
  ///
  /// In pt, this message translates to:
  /// **'A partida é salva neste aparelho e pode ser retomada. Um diário antigo mantém sua data. Limpar os dados ou desinstalar o app remove o histórico local.'**
  String get colorGuideSaveRule;

  /// No description provided for @colorGuideSaveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar o tutorial. Tente novamente; nenhuma partida foi criada.'**
  String get colorGuideSaveFailed;

  /// No description provided for @colorGuideDone.
  ///
  /// In pt, this message translates to:
  /// **'Entendi, vamos jogar'**
  String get colorGuideDone;

  /// No description provided for @colorGuideNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo passo'**
  String get colorGuideNext;

  /// No description provided for @colorGuidePrevious.
  ///
  /// In pt, this message translates to:
  /// **'Passo anterior'**
  String get colorGuidePrevious;

  /// No description provided for @colorRewardSaving.
  ///
  /// In pt, this message translates to:
  /// **'Registrando seus +2 tickets…'**
  String get colorRewardSaving;

  /// No description provided for @colorRewardEarned.
  ///
  /// In pt, this message translates to:
  /// **'+2 tickets recebidos pelo diário. A recompensa desta data já está no seu saldo.'**
  String get colorRewardEarned;

  /// No description provided for @colorRewardFailed.
  ///
  /// In pt, this message translates to:
  /// **'Seu resultado está salvo. Não foi possível confirmar os tickets; tente novamente para recuperar a recompensa.'**
  String get colorRewardFailed;

  /// No description provided for @colorStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas de Cores'**
  String get colorStatsTitle;

  /// No description provided for @colorStatsCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Partidas concluídas'**
  String get colorStatsCompleted;

  /// No description provided for @colorStatsMean.
  ///
  /// In pt, this message translates to:
  /// **'Média das partidas'**
  String get colorStatsMean;

  /// No description provided for @colorStatsBest.
  ///
  /// In pt, this message translates to:
  /// **'Melhor média'**
  String get colorStatsBest;

  /// No description provided for @colorStatsRounds.
  ///
  /// In pt, this message translates to:
  /// **'Média por rodada'**
  String get colorStatsRounds;

  /// No description provided for @colorStatsRoundsBody.
  ///
  /// In pt, this message translates to:
  /// **'Cada posição reúne as notas das suas partidas concluídas nesta categoria.'**
  String get colorStatsRoundsBody;

  /// No description provided for @colorStatsRound.
  ///
  /// In pt, this message translates to:
  /// **'Rodada {round}'**
  String colorStatsRound(int round);

  /// No description provided for @colorStatsRecent.
  ///
  /// In pt, this message translates to:
  /// **'Últimos resultados'**
  String get colorStatsRecent;

  /// No description provided for @colorStatsScope.
  ///
  /// In pt, this message translates to:
  /// **'As notas de Cores são independentes. Elas não alteram vitórias ou sequências de Dicas e Pôster.'**
  String get colorStatsScope;

  /// No description provided for @colorStatsOpen.
  ///
  /// In pt, this message translates to:
  /// **'Ver minhas estatísticas'**
  String get colorStatsOpen;

  /// No description provided for @colorShareTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minha memória tem cor.'**
  String get colorShareTitle;

  /// No description provided for @colorSharePrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Só as notas: personagens, perguntas e cores ficam fora deste cartão.'**
  String get colorSharePrivacy;

  /// No description provided for @colorShareText.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar texto'**
  String get colorShareText;

  /// No description provided for @colorHomeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Você lembra o tom? Recolora cinco personagens e compare sua memória com a referência.'**
  String get colorHomeDescription;

  /// No description provided for @colorExactTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar {label}'**
  String colorExactTitle(String label);

  /// No description provided for @colorExactRange.
  ///
  /// In pt, this message translates to:
  /// **'Valor de 0 a {max}. Você pode usar casas decimais.'**
  String colorExactRange(int max);

  /// No description provided for @colorExactInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Digite um número entre 0 e {max}.'**
  String colorExactInvalid(int max);

  /// No description provided for @colorExactSemantic.
  ///
  /// In pt, this message translates to:
  /// **'{value} de {max}'**
  String colorExactSemantic(int max, String value);

  /// No description provided for @colorExactApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar valor'**
  String get colorExactApply;

  /// No description provided for @colorExactCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get colorExactCancel;

  /// No description provided for @colorDecrease.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir {label}'**
  String colorDecrease(String label);

  /// No description provided for @colorIncrease.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar {label}'**
  String colorIncrease(String label);

  /// No description provided for @colorCreditsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fontes de Cores'**
  String get colorCreditsTitle;

  /// No description provided for @colorCreditsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Referências utilizadas no acervo de Cores. Os tons correspondem às partes e versões indicadas; as artes são interpretações visuais.'**
  String get colorCreditsDescription;

  /// No description provided for @colorCreditsGenerated.
  ///
  /// In pt, this message translates to:
  /// **'Ilustração gerada para o Cineus'**
  String get colorCreditsGenerated;

  /// No description provided for @colorCreditsReference.
  ///
  /// In pt, this message translates to:
  /// **'Ilustração baseada em imagem de referência'**
  String get colorCreditsReference;

  /// No description provided for @colorCreditsStudy.
  ///
  /// In pt, this message translates to:
  /// **'Referência de estudo de cor'**
  String get colorCreditsStudy;

  /// No description provided for @colorCreditsArt.
  ///
  /// In pt, this message translates to:
  /// **'Origem da imagem de referência'**
  String get colorCreditsArt;

  /// No description provided for @homeDailyAction.
  ///
  /// In pt, this message translates to:
  /// **'Jogar o diário'**
  String get homeDailyAction;

  /// No description provided for @homeDailyCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Diário concluído'**
  String get homeDailyCompleted;

  /// No description provided for @homeStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minhas estatísticas'**
  String get homeStatsTitle;

  /// No description provided for @homeCluesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Teste seus conhecimentos sobre filmes.'**
  String get homeCluesDescription;

  /// No description provided for @homePosterDescription.
  ///
  /// In pt, this message translates to:
  /// **'Qual é o filme pelo pôster?'**
  String get homePosterDescription;

  /// No description provided for @homeChallengeUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar.'**
  String get homeChallengeUnavailable;

  /// No description provided for @filmsToStart.
  ///
  /// In pt, this message translates to:
  /// **'para iniciar'**
  String get filmsToStart;

  /// No description provided for @filmsInStage.
  ///
  /// In pt, this message translates to:
  /// **'neste estágio'**
  String get filmsInStage;

  /// No description provided for @filmsAllStages.
  ///
  /// In pt, this message translates to:
  /// **'Todos os estágios'**
  String get filmsAllStages;

  /// No description provided for @filmsUnlockAfter.
  ///
  /// In pt, this message translates to:
  /// **'Complete o {stage}'**
  String filmsUnlockAfter(String stage);

  /// No description provided for @filmsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum estágio disponível.'**
  String get filmsEmpty;

  /// No description provided for @colorEnlargeCharacter.
  ///
  /// In pt, this message translates to:
  /// **'Ampliar personagem'**
  String get colorEnlargeCharacter;

  /// No description provided for @colorZoomHint.
  ///
  /// In pt, this message translates to:
  /// **'Use dois dedos para ampliar os detalhes.'**
  String get colorZoomHint;

  /// No description provided for @colorStagesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Relembre as cores e avance por estágios.'**
  String get colorStagesSubtitle;

  /// No description provided for @colorStageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estágio {stage}'**
  String colorStageTitle(int stage);

  /// No description provided for @colorStageProgress.
  ///
  /// In pt, this message translates to:
  /// **'{done} / {total} desenhos concluídos'**
  String colorStageProgress(int done, int total);

  /// No description provided for @colorStageStructure.
  ///
  /// In pt, this message translates to:
  /// **'10 desenhos distintos · 2 partidas de 5'**
  String get colorStageStructure;

  /// No description provided for @colorStageReturn.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao estágio'**
  String get colorStageReturn;

  /// No description provided for @colorStageMatch.
  ///
  /// In pt, this message translates to:
  /// **'Partida {match}'**
  String colorStageMatch(int match);

  /// No description provided for @colorStageStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar · 1 ticket'**
  String get colorStageStart;

  /// No description provided for @colorStageResume.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get colorStageResume;

  /// No description provided for @colorStageOpen.
  ///
  /// In pt, this message translates to:
  /// **'Ver partidas'**
  String get colorStageOpen;

  /// No description provided for @colorStageLocked.
  ///
  /// In pt, this message translates to:
  /// **'Complete o Estágio {stage}'**
  String colorStageLocked(int stage);

  /// No description provided for @colorStageDailyHome.
  ///
  /// In pt, this message translates to:
  /// **'Os desafios diários estão no Início.'**
  String get colorStageDailyHome;

  /// No description provided for @colorStageLegacy.
  ///
  /// In pt, this message translates to:
  /// **'Retomar treino anterior'**
  String get colorStageLegacy;

  /// No description provided for @colorStagesAndTraining.
  ///
  /// In pt, this message translates to:
  /// **'Estágios e treino'**
  String get colorStagesAndTraining;

  /// No description provided for @splashWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Cinema, memória e cor.'**
  String get splashWelcome;

  /// No description provided for @colorStageGamesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Partidas do estágio'**
  String get colorStageGamesTitle;

  /// No description provided for @resultNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get resultNext;

  /// No description provided for @stagePlay.
  ///
  /// In pt, this message translates to:
  /// **'Jogar'**
  String get stagePlay;

  /// No description provided for @stageRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get stageRetry;

  /// No description provided for @stageContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get stageContinue;

  /// No description provided for @guidePracticeNotice.
  ///
  /// In pt, this message translates to:
  /// **'Exemplo livre · não usa tickets nem altera seu progresso.'**
  String get guidePracticeNotice;

  /// No description provided for @guideColorsBody.
  ///
  /// In pt, this message translates to:
  /// **'Recrie a cor de uma região do personagem. Ajuste tom, intensidade e brilho e compare depois de confirmar.'**
  String get guideColorsBody;

  /// No description provided for @guideTryColors.
  ///
  /// In pt, this message translates to:
  /// **'Experimentar Cores'**
  String get guideTryColors;

  /// No description provided for @guideDemoReset.
  ///
  /// In pt, this message translates to:
  /// **'Experimentar de novo'**
  String get guideDemoReset;

  /// No description provided for @guideDemoComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluir partida do exemplo'**
  String get guideDemoComplete;

  /// No description provided for @guideDemoUnlocked.
  ///
  /// In pt, this message translates to:
  /// **'Estágio 2 liberado no exemplo.'**
  String get guideDemoUnlocked;

  /// No description provided for @guideDemoCorrect.
  ///
  /// In pt, this message translates to:
  /// **'Acertou o exemplo! O resultado mostra seus pontos e o filme.'**
  String get guideDemoCorrect;

  /// No description provided for @guideDemoWrong.
  ///
  /// In pt, this message translates to:
  /// **'Neste exemplo, errar revela outra dica: o filme é de Christopher Nolan. Você ainda pode tentar Interestelar.'**
  String get guideDemoWrong;

  /// No description provided for @guideDemoClues.
  ///
  /// In pt, this message translates to:
  /// **'Um grupo viaja pelo espaço em busca de um novo lar.|A Terra enfrenta uma crise de alimentos.|O tempo passa de forma diferente em outro planeta.|Um pai promete voltar para a filha.|A viagem atravessa um buraco de minhoca.|Um robô chamado TARS acompanha a equipe.|Há um planeta coberto por água.|O protagonista se chama Cooper.|Christopher Nolan dirigiu o filme.|Matthew McConaughey interpreta Cooper.'**
  String get guideDemoClues;

  /// No description provided for @guideSaveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Partida e histórico'**
  String get guideSaveTitle;

  /// No description provided for @guideSaveBody.
  ///
  /// In pt, this message translates to:
  /// **'Pode sair e continuar a partida. O progresso e as estatísticas ficam neste aparelho; limpar seus dados ou desinstalar o app remove os registros locais.'**
  String get guideSaveBody;

  /// No description provided for @guideResultsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resultado e cartão'**
  String get guideResultsTitle;

  /// No description provided for @guideResultsBody.
  ///
  /// In pt, this message translates to:
  /// **'Próximo abre a próxima partida. Ver cartão mostra o pôster, a marca e seus pontos; o compartilhamento fica dentro do cartão. A barra usa verde para 7–10, amarelo para 4–6 e vermelho para 0–3 pontos. Desafiar amigo cria um convite de filme. Em Cores, veja as cinco notas e sua média.'**
  String get guideResultsBody;

  /// No description provided for @guideColorsEconomy.
  ///
  /// In pt, this message translates to:
  /// **'Estágios custam 1 ticket; retomar é grátis. O diário gratuito rende +2 ao concluir. Dica rápida e orientação de ajustes descontam 1 ponto na rodada; a orientação usa ticket ou vídeo opcional.'**
  String get guideColorsEconomy;

  /// No description provided for @guideJourneyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Diários e estágios'**
  String get guideJourneyTitle;

  /// No description provided for @guideEssentialsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu progresso e resultados'**
  String get guideEssentialsTitle;

  /// No description provided for @colorMysteryCharacters.
  ///
  /// In pt, this message translates to:
  /// **'Personagens misteriosos'**
  String get colorMysteryCharacters;

  /// No description provided for @colorStatsAllScope.
  ///
  /// In pt, this message translates to:
  /// **'Todas as partidas concluídas de Cores'**
  String get colorStatsAllScope;

  /// No description provided for @colorStatsPointScale.
  ///
  /// In pt, this message translates to:
  /// **'pontos de 0 a 10'**
  String get colorStatsPointScale;

  /// No description provided for @colorStatsRoundsPlayed.
  ///
  /// In pt, this message translates to:
  /// **'Rodadas concluídas'**
  String get colorStatsRoundsPlayed;

  /// No description provided for @achievementScopeColors.
  ///
  /// In pt, this message translates to:
  /// **'Cores · todos os modos'**
  String get achievementScopeColors;

  /// No description provided for @achievementScopeDailyPoster.
  ///
  /// In pt, this message translates to:
  /// **'Daily · Poster'**
  String get achievementScopeDailyPoster;

  /// No description provided for @achPosterFirst.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro enquadramento'**
  String get achPosterFirst;

  /// No description provided for @achPosterFirstDesc.
  ///
  /// In pt, this message translates to:
  /// **'Acerte um desafio diário de Poster.'**
  String get achPosterFirstDesc;

  /// No description provided for @achPosterPerfect.
  ///
  /// In pt, this message translates to:
  /// **'Olho clínico'**
  String get achPosterPerfect;

  /// No description provided for @achPosterPerfectDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ganhe 5 pontos em um diário de Poster, no primeiro nível de desfoque.'**
  String get achPosterPerfectDesc;

  /// No description provided for @achColorsFirst.
  ///
  /// In pt, this message translates to:
  /// **'Primeira pincelada'**
  String get achColorsFirst;

  /// No description provided for @achColorsFirstDesc.
  ///
  /// In pt, this message translates to:
  /// **'Conclua uma partida de Cores com cinco personagens.'**
  String get achColorsFirstDesc;

  /// No description provided for @achColors25.
  ///
  /// In pt, this message translates to:
  /// **'Ateliê de memórias'**
  String get achColors25;

  /// No description provided for @achColors25Desc.
  ///
  /// In pt, this message translates to:
  /// **'Conclua 25 partidas de Cores.'**
  String get achColors25Desc;

  /// No description provided for @achColorsExcellent.
  ///
  /// In pt, this message translates to:
  /// **'Memória cromática'**
  String get achColorsExcellent;

  /// No description provided for @achColorsExcellentDesc.
  ///
  /// In pt, this message translates to:
  /// **'Alcance média final de pelo menos 9 pontos em uma partida de Cores.'**
  String get achColorsExcellentDesc;

  /// No description provided for @achColorsStages3.
  ///
  /// In pt, this message translates to:
  /// **'Galeria em expansão'**
  String get achColorsStages3;

  /// No description provided for @achColorsStages3Desc.
  ///
  /// In pt, this message translates to:
  /// **'Complete os dois jogos de três estágios de Cores.'**
  String get achColorsStages3Desc;

  /// No description provided for @collectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minha coleção'**
  String get collectionTitle;

  /// No description provided for @collectionProfile.
  ///
  /// In pt, this message translates to:
  /// **'Meu perfil'**
  String get collectionProfile;

  /// No description provided for @collectionEditProfile.
  ///
  /// In pt, this message translates to:
  /// **'Editar perfil'**
  String get collectionEditProfile;

  /// No description provided for @collectionDisplayName.
  ///
  /// In pt, this message translates to:
  /// **'Nome de exibição'**
  String get collectionDisplayName;

  /// No description provided for @collectionNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Como quer aparecer?'**
  String get collectionNameHint;

  /// No description provided for @collectionShowIdentity.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar nome e avatar no cartão'**
  String get collectionShowIdentity;

  /// No description provided for @collectionNameInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Use até 24 caracteres, sem quebras de linha.'**
  String get collectionNameInvalid;

  /// No description provided for @collectionSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get collectionSave;

  /// No description provided for @collectionAvatars.
  ///
  /// In pt, this message translates to:
  /// **'Avatares'**
  String get collectionAvatars;

  /// No description provided for @collectionFrames.
  ///
  /// In pt, this message translates to:
  /// **'Molduras'**
  String get collectionFrames;

  /// No description provided for @collectionAppearances.
  ///
  /// In pt, this message translates to:
  /// **'Cartões'**
  String get collectionAppearances;

  /// No description provided for @collectionApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get collectionApply;

  /// No description provided for @collectionEquipped.
  ///
  /// In pt, this message translates to:
  /// **'Em uso'**
  String get collectionEquipped;

  /// No description provided for @collectionUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get collectionUnavailable;

  /// No description provided for @collectionPreview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia'**
  String get collectionPreview;

  /// No description provided for @collectionLoadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir sua coleção.'**
  String get collectionLoadFailed;

  /// No description provided for @collectionSaveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente novamente.'**
  String get collectionSaveFailed;

  /// No description provided for @collectionEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item nesta categoria.'**
  String get collectionEmpty;

  /// No description provided for @collectionAvatarOwl.
  ///
  /// In pt, this message translates to:
  /// **'Íris, a Última Técnica'**
  String get collectionAvatarOwl;

  /// No description provided for @collectionAvatarFox.
  ///
  /// In pt, this message translates to:
  /// **'Dante Rebobina'**
  String get collectionAvatarFox;

  /// No description provided for @collectionFrameGold.
  ///
  /// In pt, this message translates to:
  /// **'Luz dourada'**
  String get collectionFrameGold;

  /// No description provided for @collectionFrameBlue.
  ///
  /// In pt, this message translates to:
  /// **'Rolo azul'**
  String get collectionFrameBlue;

  /// No description provided for @collectionAppearanceNoir.
  ///
  /// In pt, this message translates to:
  /// **'Noite de cinema'**
  String get collectionAppearanceNoir;

  /// No description provided for @collectionPremiere.
  ///
  /// In pt, this message translates to:
  /// **'Coleção Estreia'**
  String get collectionPremiere;

  /// No description provided for @collectionTryPremiere.
  ///
  /// In pt, this message translates to:
  /// **'Experimentar coleção'**
  String get collectionTryPremiere;

  /// No description provided for @collectionPremierePreview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia da Coleção Estreia'**
  String get collectionPremierePreview;

  /// No description provided for @collectionFree.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito'**
  String get collectionFree;

  /// No description provided for @collectionPersonalize.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar'**
  String get collectionPersonalize;

  /// No description provided for @collectionAvatarCat.
  ///
  /// In pt, this message translates to:
  /// **'Otto Corte-Final'**
  String get collectionAvatarCat;

  /// No description provided for @collectionAvatarHare.
  ///
  /// In pt, this message translates to:
  /// **'Vitor Plano-Mestre'**
  String get collectionAvatarHare;

  /// No description provided for @collectionFrameMarquee.
  ///
  /// In pt, this message translates to:
  /// **'Luzes da estreia'**
  String get collectionFrameMarquee;

  /// No description provided for @collectionFrameDeco.
  ///
  /// In pt, this message translates to:
  /// **'Cinema Art Déco'**
  String get collectionFrameDeco;

  /// No description provided for @collectionFrameSpotlight.
  ///
  /// In pt, this message translates to:
  /// **'Sob os holofotes'**
  String get collectionFrameSpotlight;

  /// No description provided for @collectionAppearanceVelvet.
  ///
  /// In pt, this message translates to:
  /// **'Veludo da estreia'**
  String get collectionAppearanceVelvet;

  /// No description provided for @commerceRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar compras'**
  String get commerceRestore;

  /// No description provided for @commerceBuy.
  ///
  /// In pt, this message translates to:
  /// **'Comprar · {price}'**
  String commerceBuy(String price);

  /// No description provided for @commercePending.
  ///
  /// In pt, this message translates to:
  /// **'Compra pendente de confirmação.'**
  String get commercePending;

  /// No description provided for @commerceVerified.
  ///
  /// In pt, this message translates to:
  /// **'Compra confirmada. Seus itens estão na coleção.'**
  String get commerceVerified;

  /// No description provided for @commerceFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível confirmar. Tente restaurar quando a conexão voltar.'**
  String get commerceFailed;

  /// No description provided for @commerceCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Compra cancelada.'**
  String get commerceCancelled;

  /// No description provided for @commerceRestoring.
  ///
  /// In pt, this message translates to:
  /// **'Restauração solicitada. A confirmação pode levar alguns instantes.'**
  String get commerceRestoring;

  /// No description provided for @commerceUse.
  ///
  /// In pt, this message translates to:
  /// **'Usar coleção'**
  String get commerceUse;

  /// No description provided for @commercePermanent.
  ///
  /// In pt, this message translates to:
  /// **'Compra única · itens permanentes'**
  String get commercePermanent;

  /// No description provided for @commerceRecovery.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar acesso'**
  String get commerceRecovery;

  /// No description provided for @commerceRecoveryKey.
  ///
  /// In pt, this message translates to:
  /// **'Chave de recuperação'**
  String get commerceRecoveryKey;

  /// No description provided for @commerceRecoveryInfo.
  ///
  /// In pt, this message translates to:
  /// **'Guarde esta chave em local privado antes de reinstalar ou trocar de aparelho. Ela recupera o acesso comercial, não o progresso do jogo. Não compartilhe.'**
  String get commerceRecoveryInfo;

  /// No description provided for @commerceRecoverAction.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar'**
  String get commerceRecoverAction;

  /// No description provided for @commercePlus.
  ///
  /// In pt, this message translates to:
  /// **'Cineus Plus'**
  String get commercePlus;

  /// No description provided for @commerceClub.
  ///
  /// In pt, this message translates to:
  /// **'Cineus Clube'**
  String get commerceClub;

  /// No description provided for @commercePrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade dos anúncios'**
  String get commercePrivacy;

  /// No description provided for @commerceHideRewarded.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar ofertas de vídeo'**
  String get commerceHideRewarded;

  /// No description provided for @commerceClubTerms.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura mensal com renovação automática. Inclui a coleção do ciclo e remove interrupções durante a vigência. Cancele pela loja; itens já adquiridos permanecem.'**
  String get commerceClubTerms;

  /// No description provided for @commerceManage.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar assinatura'**
  String get commerceManage;

  /// No description provided for @missionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua jornada'**
  String get missionsTitle;

  /// No description provided for @missionsWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Missões da semana'**
  String get missionsWeekly;

  /// No description provided for @missionPlay.
  ///
  /// In pt, this message translates to:
  /// **'Conclua 3 partidas'**
  String get missionPlay;

  /// No description provided for @missionModes.
  ///
  /// In pt, this message translates to:
  /// **'Jogue nos 3 modos'**
  String get missionModes;

  /// No description provided for @missionDays.
  ///
  /// In pt, this message translates to:
  /// **'Jogue em 3 dias'**
  String get missionDays;

  /// No description provided for @missionClaim.
  ///
  /// In pt, this message translates to:
  /// **'Resgatar'**
  String get missionClaim;

  /// No description provided for @missionClaimed.
  ///
  /// In pt, this message translates to:
  /// **'Resgatado'**
  String get missionClaimed;

  /// No description provided for @discoveryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Personagens encontrados'**
  String get discoveryTitle;

  /// No description provided for @discoveryMystery.
  ///
  /// In pt, this message translates to:
  /// **'Personagem misterioso'**
  String get discoveryMystery;

  /// No description provided for @seasonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mostras de cinema'**
  String get seasonTitle;

  /// No description provided for @seasonArchive.
  ///
  /// In pt, this message translates to:
  /// **'Coleções anteriores'**
  String get seasonArchive;

  /// No description provided for @sponsorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sessão especial'**
  String get sponsorTitle;

  /// No description provided for @sponsorDemo.
  ///
  /// In pt, this message translates to:
  /// **'Demonstração · Estúdio Aurora'**
  String get sponsorDemo;

  /// No description provided for @sponsorDisclosure.
  ///
  /// In pt, this message translates to:
  /// **'Patrocínio'**
  String get sponsorDisclosure;

  /// No description provided for @sponsorGoal.
  ///
  /// In pt, this message translates to:
  /// **'Conclua 3 partidas durante o evento'**
  String get sponsorGoal;

  /// No description provided for @sponsorReward.
  ///
  /// In pt, this message translates to:
  /// **'Recompensa visual gratuita'**
  String get sponsorReward;

  /// No description provided for @collectionNight.
  ///
  /// In pt, this message translates to:
  /// **'Noite Estrelada'**
  String get collectionNight;

  /// No description provided for @collectionCity.
  ///
  /// In pt, this message translates to:
  /// **'Luzes da Cidade'**
  String get collectionCity;

  /// No description provided for @itemMissionFirefly.
  ///
  /// In pt, this message translates to:
  /// **'Enzo Replay'**
  String get itemMissionFirefly;

  /// No description provided for @itemMissionProjector.
  ///
  /// In pt, this message translates to:
  /// **'Projeção da semana'**
  String get itemMissionProjector;

  /// No description provided for @itemMissionConstellation.
  ///
  /// In pt, this message translates to:
  /// **'Constelação'**
  String get itemMissionConstellation;

  /// No description provided for @itemPlusCrown.
  ///
  /// In pt, this message translates to:
  /// **'Coroa do cinema'**
  String get itemPlusCrown;

  /// No description provided for @itemPlusPremiere.
  ///
  /// In pt, this message translates to:
  /// **'Veludo Plus'**
  String get itemPlusPremiere;

  /// No description provided for @itemNightRaccoon.
  ///
  /// In pt, this message translates to:
  /// **'Nara Estelar'**
  String get itemNightRaccoon;

  /// No description provided for @itemNightOtter.
  ///
  /// In pt, this message translates to:
  /// **'Ciro Maré-de-Cena'**
  String get itemNightOtter;

  /// No description provided for @itemNightOrbit.
  ///
  /// In pt, this message translates to:
  /// **'Órbita dourada'**
  String get itemNightOrbit;

  /// No description provided for @itemNightComet.
  ///
  /// In pt, this message translates to:
  /// **'Rastro de cometa'**
  String get itemNightComet;

  /// No description provided for @itemNightObservatory.
  ///
  /// In pt, this message translates to:
  /// **'Observatório'**
  String get itemNightObservatory;

  /// No description provided for @itemNightSky.
  ///
  /// In pt, this message translates to:
  /// **'Céu de cinema'**
  String get itemNightSky;

  /// No description provided for @itemCityPanda.
  ///
  /// In pt, this message translates to:
  /// **'Raul Duplo-Corte'**
  String get itemCityPanda;

  /// No description provided for @itemCityHummingbird.
  ///
  /// In pt, this message translates to:
  /// **'Sol Última-Tomada'**
  String get itemCityHummingbird;

  /// No description provided for @itemCitySkyline.
  ///
  /// In pt, this message translates to:
  /// **'Horizonte de luz'**
  String get itemCitySkyline;

  /// No description provided for @itemCityBridge.
  ///
  /// In pt, this message translates to:
  /// **'Ponte dourada'**
  String get itemCityBridge;

  /// No description provided for @itemCityRain.
  ///
  /// In pt, this message translates to:
  /// **'Chuva de estreia'**
  String get itemCityRain;

  /// No description provided for @itemCityNight.
  ///
  /// In pt, this message translates to:
  /// **'Cidade noturna'**
  String get itemCityNight;

  /// No description provided for @itemAuroraFrame.
  ///
  /// In pt, this message translates to:
  /// **'Primeira luz'**
  String get itemAuroraFrame;

  /// No description provided for @seasonRefresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar coleções'**
  String get seasonRefresh;

  /// No description provided for @seasonUpdateFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar. Sua coleção continua disponível.'**
  String get seasonUpdateFailed;

  /// No description provided for @sponsorJoin.
  ///
  /// In pt, this message translates to:
  /// **'Participar'**
  String get sponsorJoin;

  /// No description provided for @sponsorEnded.
  ///
  /// In pt, this message translates to:
  /// **'Evento encerrado'**
  String get sponsorEnded;

  /// No description provided for @collectionOwned.
  ///
  /// In pt, this message translates to:
  /// **'Adquirido'**
  String get collectionOwned;

  /// No description provided for @sponsorGoalCount.
  ///
  /// In pt, this message translates to:
  /// **'Conclua {count} partidas durante o evento'**
  String sponsorGoalCount(int count);

  /// No description provided for @guideCollectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua jornada e seus visuais'**
  String get guideCollectionTitle;

  /// No description provided for @guideCollectionBody.
  ///
  /// In pt, this message translates to:
  /// **'Missões da semana e eventos gratuitos desbloqueiam visuais. Confira e aplique em Minha coleção. Compras opcionais personalizam o cartão; não mudam sua pontuação.'**
  String get guideCollectionBody;

  /// No description provided for @collectionPreviewNotice.
  ///
  /// In pt, this message translates to:
  /// **'Prévia · sem alterar seus itens em uso.'**
  String get collectionPreviewNotice;

  /// No description provided for @commercePlusTerms.
  ///
  /// In pt, this message translates to:
  /// **'Compra única · sem interrupções, com moldura e cartão exclusivos.'**
  String get commercePlusTerms;

  /// No description provided for @commerceCollectionTerms.
  ///
  /// In pt, this message translates to:
  /// **'Compra única · 2 avatares, 3 molduras e 1 cartão.'**
  String get commerceCollectionTerms;

  /// No description provided for @commerceSubscriptionActive.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura ativa'**
  String get commerceSubscriptionActive;

  /// No description provided for @earnTickets.
  ///
  /// In pt, this message translates to:
  /// **'Ganhar tickets'**
  String get earnTickets;

  /// No description provided for @earnTicketsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Vídeos opcionais e mais partidas'**
  String get earnTicketsSubtitle;

  /// No description provided for @commerceComingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get commerceComingSoon;

  /// No description provided for @adSpaceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Publicidade'**
  String get adSpaceLabel;

  /// No description provided for @adSpaceReserved.
  ///
  /// In pt, this message translates to:
  /// **'Espaço reservado para anúncio'**
  String get adSpaceReserved;

  /// No description provided for @rewardedLoading.
  ///
  /// In pt, this message translates to:
  /// **'Preparando vídeo…'**
  String get rewardedLoading;

  /// No description provided for @rewardedUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum vídeo disponível agora.'**
  String get rewardedUnavailable;

  /// No description provided for @rewardedLimitReached.
  ///
  /// In pt, this message translates to:
  /// **'Você usou os vídeos de hoje.'**
  String get rewardedLimitReached;

  /// No description provided for @rewardedPlaceholderBody.
  ///
  /// In pt, this message translates to:
  /// **'Assista a um vídeo e ganhe tickets extras.'**
  String get rewardedPlaceholderBody;

  /// No description provided for @rewardedRetry.
  ///
  /// In pt, this message translates to:
  /// **'Carregar vídeo'**
  String get rewardedRetry;

  /// No description provided for @rewardedFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir. Tente novamente.'**
  String get rewardedFailed;

  /// No description provided for @rewardedCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Recompensa ainda não confirmada.'**
  String get rewardedCancelled;

  /// No description provided for @rewardedWatching.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando recompensa…'**
  String get rewardedWatching;

  /// No description provided for @rewardedPreviewLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vídeo recompensado · em breve'**
  String get rewardedPreviewLabel;

  /// No description provided for @ticketPacksTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pacotes de tickets'**
  String get ticketPacksTitle;

  /// No description provided for @ticketPackSmall.
  ///
  /// In pt, this message translates to:
  /// **'20 tickets'**
  String get ticketPackSmall;

  /// No description provided for @ticketPackLarge.
  ///
  /// In pt, this message translates to:
  /// **'60 tickets'**
  String get ticketPackLarge;

  /// No description provided for @ticketPacksNote.
  ///
  /// In pt, this message translates to:
  /// **'Mais partidas, sem esperar a renovação diária.'**
  String get ticketPacksNote;

  /// No description provided for @seasonIntro.
  ///
  /// In pt, this message translates to:
  /// **'Jogue, complete missões e encontre seu próximo personagem.'**
  String get seasonIntro;

  /// No description provided for @seasonCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Nesta temporada'**
  String get seasonCurrent;

  /// No description provided for @seasonNext.
  ///
  /// In pt, this message translates to:
  /// **'A seguir'**
  String get seasonNext;

  /// No description provided for @seasonFinished.
  ///
  /// In pt, this message translates to:
  /// **'Encerrada'**
  String get seasonFinished;

  /// No description provided for @seasonEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Novas temporadas estão a caminho.'**
  String get seasonEmpty;

  /// No description provided for @seasonItems.
  ///
  /// In pt, this message translates to:
  /// **'Seis visuais para descobrir'**
  String get seasonItems;

  /// No description provided for @seasonTry.
  ///
  /// In pt, this message translates to:
  /// **'Explorar coleção'**
  String get seasonTry;

  /// No description provided for @seasonPreviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Experimente os visuais'**
  String get seasonPreviewTitle;

  /// No description provided for @seasonAvailableOn.
  ///
  /// In pt, this message translates to:
  /// **'Chega em {date}'**
  String seasonAvailableOn(String date);

  /// No description provided for @seasonUntil.
  ///
  /// In pt, this message translates to:
  /// **'Até {date}'**
  String seasonUntil(String date);

  /// No description provided for @seasonOwnedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} de {total} na sua coleção'**
  String seasonOwnedCount(int count, int total);

  /// No description provided for @seasonEventTitle.
  ///
  /// In pt, this message translates to:
  /// **'Evento gratuito'**
  String get seasonEventTitle;

  /// No description provided for @seasonEventDemo.
  ///
  /// In pt, this message translates to:
  /// **'Evento de demonstração'**
  String get seasonEventDemo;

  /// No description provided for @seasonStoreSoon.
  ///
  /// In pt, this message translates to:
  /// **'As coleções estarão disponíveis em breve.'**
  String get seasonStoreSoon;

  /// No description provided for @commerceOptionalExtras.
  ///
  /// In pt, this message translates to:
  /// **'Jogue do seu jeito'**
  String get commerceOptionalExtras;

  /// No description provided for @commerceOptionalBody.
  ///
  /// In pt, this message translates to:
  /// **'Tickets para continuar jogando e uma opção para remover anúncios comuns. Vídeos com recompensa continuam opcionais.'**
  String get commerceOptionalBody;

  /// No description provided for @ticketLearnMore.
  ///
  /// In pt, this message translates to:
  /// **'Sobre os tickets'**
  String get ticketLearnMore;

  /// No description provided for @commerceLoading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando opções…'**
  String get commerceLoading;

  /// No description provided for @commerceCheckFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar suas compras.'**
  String get commerceCheckFailed;

  /// No description provided for @commerceOffersFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a loja.'**
  String get commerceOffersFailed;

  /// No description provided for @commerceNoOffers.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma oferta disponível agora.'**
  String get commerceNoOffers;

  /// No description provided for @commerceRestoreDone.
  ///
  /// In pt, this message translates to:
  /// **'Compras restauradas.'**
  String get commerceRestoreDone;

  /// No description provided for @commerceRestoreEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma compra ativa confirmada.'**
  String get commerceRestoreEmpty;

  /// No description provided for @commerceBenefitsActive.
  ///
  /// In pt, this message translates to:
  /// **'Vantagens ativas'**
  String get commerceBenefitsActive;

  /// No description provided for @commerceAdFreeActive.
  ///
  /// In pt, this message translates to:
  /// **'Publicidade removida. Vídeos com recompensa continuam opcionais.'**
  String get commerceAdFreeActive;

  /// No description provided for @collectionHowToGet.
  ///
  /// In pt, this message translates to:
  /// **'Como conseguir'**
  String get collectionHowToGet;

  /// No description provided for @collectionOnlyOwned.
  ///
  /// In pt, this message translates to:
  /// **'Meus itens'**
  String get collectionOnlyOwned;

  /// No description provided for @collectionAllItems.
  ///
  /// In pt, this message translates to:
  /// **'Todos os itens'**
  String get collectionAllItems;

  /// No description provided for @collectionUnlockMission.
  ///
  /// In pt, this message translates to:
  /// **'Conclua missões da semana para desbloquear este visual.'**
  String get collectionUnlockMission;

  /// No description provided for @collectionUnlockEvent.
  ///
  /// In pt, this message translates to:
  /// **'Este visual é a recompensa de um evento.'**
  String get collectionUnlockEvent;

  /// No description provided for @collectionUnlockSeason.
  ///
  /// In pt, this message translates to:
  /// **'Encontre esta coleção em Temporadas.'**
  String get collectionUnlockSeason;

  /// No description provided for @collectionUnlockSoon.
  ///
  /// In pt, this message translates to:
  /// **'Este visual estará disponível na loja em breve.'**
  String get collectionUnlockSoon;

  /// No description provided for @collectionUnlocked.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueado'**
  String get collectionUnlocked;

  /// No description provided for @helpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de ajuda?'**
  String get helpTitle;

  /// No description provided for @helpUseTicket.
  ///
  /// In pt, this message translates to:
  /// **'Usar 1 ticket'**
  String get helpUseTicket;

  /// No description provided for @helpWatch.
  ///
  /// In pt, this message translates to:
  /// **'Vídeo · ajuda + 1 ticket'**
  String get helpWatch;

  /// No description provided for @helpVideoSoon.
  ///
  /// In pt, this message translates to:
  /// **'Vídeo em breve'**
  String get helpVideoSoon;

  /// No description provided for @helpVideoUsed.
  ///
  /// In pt, this message translates to:
  /// **'Vídeo já usado nesta partida'**
  String get helpVideoUsed;

  /// No description provided for @helpVideoTerms.
  ///
  /// In pt, this message translates to:
  /// **'1 por partida · compartilha o limite diário de vídeos.'**
  String get helpVideoTerms;

  /// No description provided for @helpPending.
  ///
  /// In pt, this message translates to:
  /// **'Confirmando recompensa…'**
  String get helpPending;

  /// No description provided for @helpPendingBody.
  ///
  /// In pt, this message translates to:
  /// **'Pode continuar jogando. A recompensa será recuperada quando for confirmada.'**
  String get helpPendingBody;

  /// No description provided for @helpClaim.
  ///
  /// In pt, this message translates to:
  /// **'Receber ajuda'**
  String get helpClaim;

  /// No description provided for @helpStored.
  ///
  /// In pt, this message translates to:
  /// **'Os 2 tickets ficaram no seu saldo.'**
  String get helpStored;

  /// No description provided for @helpDone.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda liberada. +1 ticket no saldo.'**
  String get helpDone;

  /// No description provided for @helpNoAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Você já usou as ajudas disponíveis.'**
  String get helpNoAvailable;

  /// No description provided for @helpColorGuidance.
  ///
  /// In pt, this message translates to:
  /// **'Orientação de cor'**
  String get helpColorGuidance;

  /// No description provided for @helpColorGuidanceBody.
  ///
  /// In pt, this message translates to:
  /// **'Uma sugestão de tom e ajuste. −1 ponto nesta rodada.'**
  String get helpColorGuidanceBody;

  /// No description provided for @helpColorSimple.
  ///
  /// In pt, this message translates to:
  /// **'Dica rápida'**
  String get helpColorSimple;

  /// No description provided for @helpColorSimpleBody.
  ///
  /// In pt, this message translates to:
  /// **'Dica do personagem · −1 ponto'**
  String get helpColorSimpleBody;

  /// No description provided for @helpAdOffer.
  ///
  /// In pt, this message translates to:
  /// **'Assista a um anúncio para liberar esta ajuda e guardar 1 ticket.'**
  String get helpAdOffer;

  /// No description provided for @helpColorFamily.
  ///
  /// In pt, this message translates to:
  /// **'Experimente a família de {family}.'**
  String helpColorFamily(String family);

  /// No description provided for @helpFamilyRed.
  ///
  /// In pt, this message translates to:
  /// **'vermelhos'**
  String get helpFamilyRed;

  /// No description provided for @helpFamilyOrange.
  ///
  /// In pt, this message translates to:
  /// **'laranjas'**
  String get helpFamilyOrange;

  /// No description provided for @helpFamilyYellow.
  ///
  /// In pt, this message translates to:
  /// **'amarelos'**
  String get helpFamilyYellow;

  /// No description provided for @helpFamilyGreen.
  ///
  /// In pt, this message translates to:
  /// **'verdes'**
  String get helpFamilyGreen;

  /// No description provided for @helpFamilyCyan.
  ///
  /// In pt, this message translates to:
  /// **'cianos'**
  String get helpFamilyCyan;

  /// No description provided for @helpFamilyBlue.
  ///
  /// In pt, this message translates to:
  /// **'azuis'**
  String get helpFamilyBlue;

  /// No description provided for @helpFamilyPurple.
  ///
  /// In pt, this message translates to:
  /// **'roxos'**
  String get helpFamilyPurple;

  /// No description provided for @helpFamilyPink.
  ///
  /// In pt, this message translates to:
  /// **'rosas'**
  String get helpFamilyPink;

  /// No description provided for @helpFamilyNeutral.
  ///
  /// In pt, this message translates to:
  /// **'tons neutros'**
  String get helpFamilyNeutral;

  /// No description provided for @helpBrighter.
  ///
  /// In pt, this message translates to:
  /// **'Aumente um pouco o brilho.'**
  String get helpBrighter;

  /// No description provided for @helpDarker.
  ///
  /// In pt, this message translates to:
  /// **'Diminua um pouco o brilho.'**
  String get helpDarker;

  /// No description provided for @helpMoreSaturation.
  ///
  /// In pt, this message translates to:
  /// **'Aumente um pouco a intensidade.'**
  String get helpMoreSaturation;

  /// No description provided for @helpLessSaturation.
  ///
  /// In pt, this message translates to:
  /// **'Diminua um pouco a intensidade.'**
  String get helpLessSaturation;

  /// No description provided for @helpAdjustClose.
  ///
  /// In pt, this message translates to:
  /// **'Os ajustes estão próximos; refine o tom.'**
  String get helpAdjustClose;

  /// No description provided for @archiveMode.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo'**
  String get archiveMode;

  /// No description provided for @practiceMode.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get practiceMode;

  /// No description provided for @activityAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas as partidas'**
  String get activityAll;

  /// No description provided for @activityDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diários'**
  String get activityDaily;

  /// No description provided for @activityStage.
  ///
  /// In pt, this message translates to:
  /// **'Estágios'**
  String get activityStage;

  /// No description provided for @activityInvites.
  ///
  /// In pt, this message translates to:
  /// **'Convites'**
  String get activityInvites;

  /// No description provided for @activityContext.
  ///
  /// In pt, this message translates to:
  /// **'Atividade'**
  String get activityContext;

  /// No description provided for @presenceStreak.
  ///
  /// In pt, this message translates to:
  /// **'Dias jogados seguidos'**
  String get presenceStreak;

  /// No description provided for @nextGoal.
  ///
  /// In pt, this message translates to:
  /// **'Sua próxima meta'**
  String get nextGoal;

  /// No description provided for @continueGame.
  ///
  /// In pt, this message translates to:
  /// **'Continuar partida'**
  String get continueGame;

  /// No description provided for @practiceAgain.
  ///
  /// In pt, this message translates to:
  /// **'Rever no treino'**
  String get practiceAgain;

  /// No description provided for @masteryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu domínio'**
  String get masteryTitle;

  /// No description provided for @archiveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Diários anteriores'**
  String get archiveTitle;

  /// No description provided for @archiveDescription.
  ///
  /// In pt, this message translates to:
  /// **'Jogue no seu ritmo, sem alterar o resultado de hoje.'**
  String get archiveDescription;

  /// No description provided for @editorialFeedback.
  ///
  /// In pt, this message translates to:
  /// **'Reportar um problema'**
  String get editorialFeedback;

  /// No description provided for @feedbackSent.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado! Relato salvo para revisão.'**
  String get feedbackSent;

  /// No description provided for @feedbackClue.
  ///
  /// In pt, this message translates to:
  /// **'Dica ou resposta'**
  String get feedbackClue;

  /// No description provided for @feedbackArtwork.
  ///
  /// In pt, this message translates to:
  /// **'Imagem ou personagem'**
  String get feedbackArtwork;

  /// No description provided for @feedbackDifficulty.
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade'**
  String get feedbackDifficulty;

  /// No description provided for @feedbackOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro problema'**
  String get feedbackOther;

  /// No description provided for @feedbackNote.
  ///
  /// In pt, this message translates to:
  /// **'Descrição opcional'**
  String get feedbackNote;

  /// No description provided for @sendFeedback.
  ///
  /// In pt, this message translates to:
  /// **'Enviar relato'**
  String get sendFeedback;

  /// No description provided for @neutralCard.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar resposta'**
  String get neutralCard;

  /// No description provided for @quickStart.
  ///
  /// In pt, this message translates to:
  /// **'Jogar um exemplo'**
  String get quickStart;

  /// No description provided for @backupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu progresso'**
  String get backupTitle;

  /// No description provided for @backupSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar backup'**
  String get backupSave;

  /// No description provided for @backupRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar backup'**
  String get backupRestore;

  /// No description provided for @backupCode.
  ///
  /// In pt, this message translates to:
  /// **'Chave de recuperação'**
  String get backupCode;

  /// No description provided for @backupSaved.
  ///
  /// In pt, this message translates to:
  /// **'Backup salvo.'**
  String get backupSaved;

  /// No description provided for @backupConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar este progresso? Seu progresso local será combinado com o backup.'**
  String get backupConfirm;

  /// No description provided for @metricsConsent.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar dados de uso'**
  String get metricsConsent;

  /// No description provided for @metricsConsentBody.
  ///
  /// In pt, this message translates to:
  /// **'Ajude a melhorar o jogo. Seus palpites e nomes não são enviados.'**
  String get metricsConsentBody;

  /// No description provided for @metricsDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar dados de uso'**
  String get metricsDelete;

  /// No description provided for @friendGames.
  ///
  /// In pt, this message translates to:
  /// **'Desafios entre amigos'**
  String get friendGames;

  /// No description provided for @friendJoin.
  ///
  /// In pt, this message translates to:
  /// **'Abrir convite'**
  String get friendJoin;

  /// No description provided for @friendCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar desafio'**
  String get friendCreate;

  /// No description provided for @connectedRequired.
  ///
  /// In pt, this message translates to:
  /// **'Conecte-se para usar este recurso.'**
  String get connectedRequired;

  /// No description provided for @missionDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Item já adquirido · recompensa alternativa'**
  String get missionDuplicate;

  /// No description provided for @itemMissionCapybara.
  ///
  /// In pt, this message translates to:
  /// **'Breno Efeito-Bruto'**
  String get itemMissionCapybara;

  /// No description provided for @itemMissionAxolotl.
  ///
  /// In pt, this message translates to:
  /// **'Bento Rolo-Perdido'**
  String get itemMissionAxolotl;

  /// No description provided for @itemMissionPenguin.
  ///
  /// In pt, this message translates to:
  /// **'Glifo Caça-Cenas'**
  String get itemMissionPenguin;

  /// No description provided for @archiveMore.
  ///
  /// In pt, this message translates to:
  /// **'Ver mais dias'**
  String get archiveMore;

  /// No description provided for @masteryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Conclua partidas para descobrir seus temas.'**
  String get masteryEmpty;

  /// No description provided for @playerDataTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados e recuperação'**
  String get playerDataTitle;

  /// No description provided for @dataActionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir. Tente novamente.'**
  String get dataActionFailed;

  /// No description provided for @backupRestored.
  ///
  /// In pt, this message translates to:
  /// **'Progresso recuperado.'**
  String get backupRestored;

  /// No description provided for @recoveryKeepPrivate.
  ///
  /// In pt, this message translates to:
  /// **'Guarde esta chave em local seguro. Ela permite recuperar seus dados e compras. Não a compartilhe.'**
  String get recoveryKeepPrivate;

  /// No description provided for @backupScope.
  ///
  /// In pt, this message translates to:
  /// **'Salva partidas, estágios e histórico. Tickets comprados são recuperados pelo servidor; o saldo diário e os bônus deste aparelho permanecem locais.'**
  String get backupScope;

  /// No description provided for @recoverAnotherDevice.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar de outro aparelho'**
  String get recoverAnotherDevice;

  /// No description provided for @backupDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar backup da nuvem'**
  String get backupDelete;

  /// No description provided for @backupDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Apagar a cópia salva? O progresso neste aparelho será mantido.'**
  String get backupDeleteConfirm;

  /// No description provided for @metricsDeletionQueued.
  ///
  /// In pt, this message translates to:
  /// **'Dados locais apagados. A exclusão online está pendente.'**
  String get metricsDeletionQueued;

  /// No description provided for @friendActionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir este convite. Confira o código, a conexão e se ele ainda está disponível.'**
  String get friendActionFailed;

  /// No description provided for @friendPlayFirst.
  ///
  /// In pt, this message translates to:
  /// **'Conclua uma partida de Dicas ou Pôster para criar um confronto.'**
  String get friendPlayFirst;

  /// No description provided for @friendChooseGame.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma partida concluída'**
  String get friendChooseGame;

  /// No description provided for @friendCreated.
  ///
  /// In pt, this message translates to:
  /// **'Convite válido por 7 dias'**
  String get friendCreated;

  /// No description provided for @friendPrivateRules.
  ///
  /// In pt, this message translates to:
  /// **'Um confronto privado por convite, com a mesma partida. Pontuações informadas pelo aparelho, sem ranking ou prêmios.'**
  String get friendPrivateRules;

  /// No description provided for @friendYou.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get friendYou;

  /// No description provided for @friendOther.
  ///
  /// In pt, this message translates to:
  /// **'Amigo'**
  String get friendOther;

  /// No description provided for @nextAction.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get nextAction;

  /// No description provided for @purchasedTickets.
  ///
  /// In pt, this message translates to:
  /// **'Comprados'**
  String get purchasedTickets;

  /// No description provided for @ticketPackAmount.
  ///
  /// In pt, this message translates to:
  /// **'{count} tickets'**
  String ticketPackAmount(int count);

  /// No description provided for @ticketPackTerms.
  ///
  /// In pt, this message translates to:
  /// **'Compra avulsa. Tickets não expiram; precisam de conexão para usar e recuperar. Não aumentam sua pontuação.'**
  String get ticketPackTerms;

  /// No description provided for @missionPlayCount.
  ///
  /// In pt, this message translates to:
  /// **'Conclua {count} partidas'**
  String missionPlayCount(int count);

  /// No description provided for @missionModesCount.
  ///
  /// In pt, this message translates to:
  /// **'Jogue em {count} modos'**
  String missionModesCount(int count);

  /// No description provided for @missionDaysCount.
  ///
  /// In pt, this message translates to:
  /// **'Jogue em {count} dias'**
  String missionDaysCount(int count);

  /// No description provided for @masteryStageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Guardião do estágio {count}'**
  String masteryStageTitle(int count);

  /// No description provided for @masteryTitles.
  ///
  /// In pt, this message translates to:
  /// **'Títulos conquistados'**
  String get masteryTitles;

  /// No description provided for @masteryAnimation.
  ///
  /// In pt, this message translates to:
  /// **'Animação'**
  String get masteryAnimation;

  /// No description provided for @masteryFantasy.
  ///
  /// In pt, this message translates to:
  /// **'Fantasia'**
  String get masteryFantasy;

  /// No description provided for @masteryClassics.
  ///
  /// In pt, this message translates to:
  /// **'Clássicos até 1989'**
  String get masteryClassics;

  /// No description provided for @assistedResult.
  ///
  /// In pt, this message translates to:
  /// **'Com ajuda'**
  String get assistedResult;

  /// No description provided for @presenceDays.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias jogados'**
  String presenceDays(int count);

  /// No description provided for @resultScoreScale.
  ///
  /// In pt, this message translates to:
  /// **'{score}/{total} pontos'**
  String resultScoreScale(int score, int total);

  /// No description provided for @stageBonusOffer.
  ///
  /// In pt, this message translates to:
  /// **'Conclusão: +{count} tickets'**
  String stageBonusOffer(int count);

  /// No description provided for @stageBonusTitleOffer.
  ///
  /// In pt, this message translates to:
  /// **'Conclusão: +{count} tickets e um título'**
  String stageBonusTitleOffer(int count);

  /// No description provided for @manageProgress.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar progresso'**
  String get manageProgress;

  /// No description provided for @progressOnDevice.
  ///
  /// In pt, this message translates to:
  /// **'Salvo automaticamente neste aparelho.'**
  String get progressOnDevice;

  /// No description provided for @backupCloudUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Backup na nuvem em breve.'**
  String get backupCloudUnavailable;

  /// No description provided for @backupCloudChecking.
  ///
  /// In pt, this message translates to:
  /// **'Consultando backup…'**
  String get backupCloudChecking;

  /// No description provided for @backupCloudEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem um backup na nuvem.'**
  String get backupCloudEmpty;

  /// No description provided for @backupCloudError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível consultar o backup.'**
  String get backupCloudError;

  /// No description provided for @backupCloudLastSaved.
  ///
  /// In pt, this message translates to:
  /// **'Na nuvem · {date}'**
  String backupCloudLastSaved(String date);

  /// No description provided for @backupOptions.
  ///
  /// In pt, this message translates to:
  /// **'Recuperação e outras opções'**
  String get backupOptions;

  /// No description provided for @backupDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Backup da nuvem apagado. Seu progresso local foi mantido.'**
  String get backupDeleted;

  /// No description provided for @metricsDeletedLocal.
  ///
  /// In pt, this message translates to:
  /// **'Dados de uso deste aparelho apagados.'**
  String get metricsDeletedLocal;

  /// No description provided for @metricsDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Dados de uso apagados.'**
  String get metricsDeleted;

  /// No description provided for @metricsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'O envio de dados está desativado nesta versão.'**
  String get metricsUnavailable;

  /// No description provided for @journeyMasteryShortcut.
  ///
  /// In pt, this message translates to:
  /// **'Domínio'**
  String get journeyMasteryShortcut;

  /// No description provided for @journeyFriendsShortcut.
  ///
  /// In pt, this message translates to:
  /// **'Amigos'**
  String get journeyFriendsShortcut;

  /// No description provided for @audienceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua faixa etária'**
  String get audienceTitle;

  /// No description provided for @audienceBody.
  ///
  /// In pt, this message translates to:
  /// **'O Cineus foi pensado para pessoas a partir de 16 anos.'**
  String get audienceBody;

  /// No description provided for @audiencePrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Informe apenas sua faixa etária. Não guardamos sua data de nascimento. Compras no app são destinadas a adultos.'**
  String get audiencePrivacy;

  /// No description provided for @audienceUnder16.
  ///
  /// In pt, this message translates to:
  /// **'Tenho menos de 16 anos'**
  String get audienceUnder16;

  /// No description provided for @audienceTeen.
  ///
  /// In pt, this message translates to:
  /// **'Tenho 16 ou 17 anos'**
  String get audienceTeen;

  /// No description provided for @audienceAdult.
  ///
  /// In pt, this message translates to:
  /// **'Tenho 18 anos ou mais'**
  String get audienceAdult;

  /// No description provided for @audienceUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Esta versão é destinada a pessoas a partir de 16 anos.'**
  String get audienceUnavailable;

  /// No description provided for @audiencePurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras disponíveis para maiores de 18 anos'**
  String get audiencePurchases;

  /// No description provided for @showcaseAnimation.
  ///
  /// In pt, this message translates to:
  /// **'Mundos de animação'**
  String get showcaseAnimation;

  /// No description provided for @showcaseFantasy.
  ///
  /// In pt, this message translates to:
  /// **'Além da imaginação'**
  String get showcaseFantasy;

  /// No description provided for @showcaseClassics.
  ///
  /// In pt, this message translates to:
  /// **'Clássicos em cartaz'**
  String get showcaseClassics;

  /// No description provided for @showcasePlay.
  ///
  /// In pt, this message translates to:
  /// **'Escolher partidas'**
  String get showcasePlay;

  /// No description provided for @showcasePractice.
  ///
  /// In pt, this message translates to:
  /// **'Uma seleção para jogar no seu ritmo. Seu avanço fica salvo.'**
  String get showcasePractice;

  /// No description provided for @showcaseRewards.
  ///
  /// In pt, this message translates to:
  /// **'Os visuais entram na rotação das missões. O que você já conquistou continua seu.'**
  String get showcaseRewards;

  /// No description provided for @showcaseFilm.
  ///
  /// In pt, this message translates to:
  /// **'Filme {number}'**
  String showcaseFilm(int number);
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'es':
      return AppL10nEs();
    case 'pt':
      return AppL10nPt();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
