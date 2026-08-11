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

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cineus'**
  String get appTitle;

  /// No description provided for @shareWin.
  ///
  /// In pt, this message translates to:
  /// **'🎬 Cineus #{challenge}\nAcertei na dica {clue}/{total} · {score}pts\n\n{grid}\n\ncineus.app'**
  String shareWin(
    Object challenge,
    int clue,
    int total,
    int score,
    Object grid,
  );

  /// No description provided for @shareLose.
  ///
  /// In pt, this message translates to:
  /// **'🎬 Cineus #{challenge} · Derrota\n\n{grid}\n\ncineus.app'**
  String shareLose(Object challenge, Object grid);

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

  /// No description provided for @semGuessThisMovie.
  ///
  /// In pt, this message translates to:
  /// **'Palpitar {title}'**
  String semGuessThisMovie(Object title);

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
  /// **'Adivinha o filme em até 10 dicas.\nQuanto menos usar, mais pontos.'**
  String get appTagline;

  /// No description provided for @splashCredits.
  ///
  /// In pt, this message translates to:
  /// **'CINEUS v1.0 · FLUTTER · DART · TMDB'**
  String get splashCredits;

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

  /// No description provided for @errorWithMessage.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {message}'**
  String errorWithMessage(Object message);

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

  /// No description provided for @genericLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar. Tente novamente.'**
  String get genericLoadError;

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

  /// No description provided for @notPlayedToday.
  ///
  /// In pt, this message translates to:
  /// **'Não jogado hoje'**
  String get notPlayedToday;

  /// No description provided for @inProgressEllipsis.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento...'**
  String get inProgressEllipsis;

  /// No description provided for @scoreWithCheck.
  ///
  /// In pt, this message translates to:
  /// **'{score} pts ✅'**
  String scoreWithCheck(int score);

  /// No description provided for @notThisTimeSkull.
  ///
  /// In pt, this message translates to:
  /// **'Não foi dessa vez 💀'**
  String get notThisTimeSkull;

  /// No description provided for @dailyDone.
  ///
  /// In pt, this message translates to:
  /// **'Desafio de hoje concluído!'**
  String get dailyDone;

  /// No description provided for @playChallenge.
  ///
  /// In pt, this message translates to:
  /// **'Jogar Desafio'**
  String get playChallenge;

  /// No description provided for @continueClues.
  ///
  /// In pt, this message translates to:
  /// **'Continuar Dicas'**
  String get continueClues;

  /// No description provided for @playPoster.
  ///
  /// In pt, this message translates to:
  /// **'Jogar Poster'**
  String get playPoster;

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

  /// No description provided for @statStreak.
  ///
  /// In pt, this message translates to:
  /// **'Sequência'**
  String get statStreak;

  /// No description provided for @quickActionStages.
  ///
  /// In pt, this message translates to:
  /// **'Estágios'**
  String get quickActionStages;

  /// No description provided for @quickActionStagesSub.
  ///
  /// In pt, this message translates to:
  /// **'Filmes por nível'**
  String get quickActionStagesSub;

  /// No description provided for @quickActionStatsSub.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico'**
  String get quickActionStatsSub;

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

  /// No description provided for @tryAnswerClue.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Responder · Dica {clue}'**
  String tryAnswerClue(int clue);

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

  /// No description provided for @fewPointsLeft.
  ///
  /// In pt, this message translates to:
  /// **'Poucos pontos restantes!'**
  String get fewPointsLeft;

  /// No description provided for @lastClueNowOrNever.
  ///
  /// In pt, this message translates to:
  /// **'Última dica! É agora ou nunca.'**
  String get lastClueNowOrNever;

  /// No description provided for @youGotIt.
  ///
  /// In pt, this message translates to:
  /// **'Você acertou! ✅'**
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

  /// No description provided for @scoreHintMax.
  ///
  /// In pt, this message translates to:
  /// **'Acerte agora e leve o máximo'**
  String get scoreHintMax;

  /// No description provided for @scoreHintStillWorth.
  ///
  /// In pt, this message translates to:
  /// **'{revealed} dicas reveladas · ainda vale a pena'**
  String scoreHintStillWorth(int revealed);

  /// No description provided for @scoreHintRunningOut.
  ///
  /// In pt, this message translates to:
  /// **'Atenção — os pontos estão acabando'**
  String get scoreHintRunningOut;

  /// No description provided for @scoreHintNextLeaves.
  ///
  /// In pt, this message translates to:
  /// **'Revelar dica {next} te deixa com apenas {points}pt'**
  String scoreHintNextLeaves(int next, int points);

  /// No description provided for @scoreHintLastChance.
  ///
  /// In pt, this message translates to:
  /// **'Última chance — vale apenas 1pt'**
  String get scoreHintLastChance;

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

  /// No description provided for @searchPoints.
  ///
  /// In pt, this message translates to:
  /// **'{points} pontos'**
  String searchPoints(int points);

  /// No description provided for @searchAvailableSuffix.
  ///
  /// In pt, this message translates to:
  /// **' disponíveis'**
  String get searchAvailableSuffix;

  /// No description provided for @blurLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desfoque '**
  String get blurLabel;

  /// No description provided for @resultWin.
  ///
  /// In pt, this message translates to:
  /// **'🎉 ACERTOU!'**
  String get resultWin;

  /// No description provided for @resultLose.
  ///
  /// In pt, this message translates to:
  /// **'💔 NÃO FOI DESSA VEZ'**
  String get resultLose;

  /// No description provided for @theMovieWas.
  ///
  /// In pt, this message translates to:
  /// **'O FILME ERA'**
  String get theMovieWas;

  /// No description provided for @gotItOnClue.
  ///
  /// In pt, this message translates to:
  /// **'Acertou na {clue}ª dica!'**
  String gotItOnClue(int clue);

  /// No description provided for @yourResult.
  ///
  /// In pt, this message translates to:
  /// **'SEU RESULTADO'**
  String get yourResult;

  /// No description provided for @share.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get share;

  /// No description provided for @resultShared.
  ///
  /// In pt, this message translates to:
  /// **'Resultado compartilhado! 🎬'**
  String get resultShared;

  /// No description provided for @resultCopied.
  ///
  /// In pt, this message translates to:
  /// **'Resultado copiado! 📋'**
  String get resultCopied;

  /// No description provided for @playPosterArrow.
  ///
  /// In pt, this message translates to:
  /// **'Jogar Poster →'**
  String get playPosterArrow;

  /// No description provided for @nextFilmCost.
  ///
  /// In pt, this message translates to:
  /// **'Próximo Filme · 1 🎫'**
  String get nextFilmCost;

  /// No description provided for @noTicketsForNext.
  ///
  /// In pt, this message translates to:
  /// **'Sem 🎫 para o próximo'**
  String get noTicketsForNext;

  /// No description provided for @nextChallengeIn.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO DESAFIO EM'**
  String get nextChallengeIn;

  /// No description provided for @stagesSubtitleClues.
  ///
  /// In pt, this message translates to:
  /// **'Complete os estágios para desbloquear mais filmes.'**
  String get stagesSubtitleClues;

  /// No description provided for @stagesSubtitlePosters.
  ///
  /// In pt, this message translates to:
  /// **'Adivinhe os filmes pelo poster desfocado.'**
  String get stagesSubtitlePosters;

  /// No description provided for @stageWord.
  ///
  /// In pt, this message translates to:
  /// **'ESTÁGIO'**
  String get stageWord;

  /// No description provided for @locked.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueado'**
  String get locked;

  /// No description provided for @filmsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} filmes'**
  String filmsCount(int count);

  /// No description provided for @stageSemanticsLocked.
  ///
  /// In pt, this message translates to:
  /// **'{name}, bloqueado'**
  String stageSemanticsLocked(Object name);

  /// No description provided for @stageSemanticsComplete.
  ///
  /// In pt, this message translates to:
  /// **'{name}, completo'**
  String stageSemanticsComplete(Object name);

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
  /// **'Não iniciado • 1 🎫'**
  String get slotNotStarted;

  /// No description provided for @slotMissedRetry.
  ///
  /// In pt, this message translates to:
  /// **'Não acertou • 1 🎫 para rejogar'**
  String get slotMissedRetry;

  /// No description provided for @slotInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get slotInProgress;

  /// No description provided for @slotPoints.
  ///
  /// In pt, this message translates to:
  /// **'{score} pontos'**
  String slotPoints(int score);

  /// No description provided for @slotCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get slotCompleted;

  /// No description provided for @actionPlay.
  ///
  /// In pt, this message translates to:
  /// **'Jogar'**
  String get actionPlay;

  /// No description provided for @actionContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// No description provided for @actionRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar'**
  String get actionRetry;

  /// No description provided for @noTicketsShort.
  ///
  /// In pt, this message translates to:
  /// **'Sem 🎫'**
  String get noTicketsShort;

  /// No description provided for @revealMore.
  ///
  /// In pt, this message translates to:
  /// **'Revelar mais · −1 pt'**
  String get revealMore;

  /// No description provided for @tryAnswerPoints.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Responder · {points} pts'**
  String tryAnswerPoints(int points);

  /// No description provided for @wrongAttemptsHeader.
  ///
  /// In pt, this message translates to:
  /// **'TENTATIVAS ERRADAS'**
  String get wrongAttemptsHeader;

  /// No description provided for @worthPoints.
  ///
  /// In pt, this message translates to:
  /// **'Vale {points} pts'**
  String worthPoints(int points);

  /// No description provided for @gameOver.
  ///
  /// In pt, this message translates to:
  /// **'Game Over'**
  String get gameOver;

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
  /// **'{score} pontos'**
  String pointsPlain(int score);

  /// No description provided for @youDidntGuess.
  ///
  /// In pt, this message translates to:
  /// **'Você não adivinhou'**
  String get youDidntGuess;

  /// No description provided for @nextWithTicket.
  ///
  /// In pt, this message translates to:
  /// **'Próximo · 1 🎫'**
  String get nextWithTicket;

  /// No description provided for @finish.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get finish;

  /// No description provided for @extraHintsHeader.
  ///
  /// In pt, this message translates to:
  /// **'DICAS EXTRAS'**
  String get extraHintsHeader;

  /// No description provided for @extraHintsNoPointCost.
  ///
  /// In pt, this message translates to:
  /// **'não custam pontos'**
  String get extraHintsNoPointCost;

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
  /// **'1 🎫'**
  String get oneTicket;

  /// No description provided for @noTicketsLower.
  ///
  /// In pt, this message translates to:
  /// **'sem 🎫'**
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
  /// **'Você não jogou em {day}. Gaste {cost} 🎫 para proteger esse dia e manter a sequência.'**
  String streakRecoverBody(Object day, int cost);

  /// No description provided for @protectStreak.
  ///
  /// In pt, this message translates to:
  /// **'Proteger sequência · {cost} 🎫'**
  String protectStreak(int cost);

  /// No description provided for @protecting.
  ///
  /// In pt, this message translates to:
  /// **'Protegendo…'**
  String get protecting;

  /// No description provided for @needTickets.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de {cost} 🎫'**
  String needTickets(int cost);

  /// No description provided for @streakProtected.
  ///
  /// In pt, this message translates to:
  /// **'Sequência protegida! 🔥'**
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

  /// No description provided for @currentStreakTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sequência Atual'**
  String get currentStreakTitle;

  /// No description provided for @dayCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 dia} other{{count} dias}}'**
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
  /// **'{count} dicas'**
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

  /// No description provided for @howItWorks.
  ///
  /// In pt, this message translates to:
  /// **'Como funciona\no Cineus'**
  String get howItWorks;

  /// No description provided for @rule1Title.
  ///
  /// In pt, this message translates to:
  /// **'10 dicas progressivas'**
  String get rule1Title;

  /// No description provided for @rule1Desc.
  ///
  /// In pt, this message translates to:
  /// **'Cada desafio tem 10 dicas, da mais abstrata e conceitual até a mais óbvia. Você escolhe quando revelar a próxima.'**
  String get rule1Desc;

  /// No description provided for @rule2Title.
  ///
  /// In pt, this message translates to:
  /// **'Menos dicas = mais pontos'**
  String get rule2Title;

  /// No description provided for @rule2Desc.
  ///
  /// In pt, this message translates to:
  /// **'Cada dica revelada custa 1 ponto. Acerte na primeira e ganhe 10; na décima, apenas 1.'**
  String get rule2Desc;

  /// No description provided for @rule3Title.
  ///
  /// In pt, this message translates to:
  /// **'Busca com autocomplete'**
  String get rule3Title;

  /// No description provided for @rule3Desc.
  ///
  /// In pt, this message translates to:
  /// **'Digite o título no campo de busca — não precisa acertar acentos nem a grafia exata. Vale o título em português ou o original.'**
  String get rule3Desc;

  /// No description provided for @rule4Title.
  ///
  /// In pt, this message translates to:
  /// **'Um desafio por dia'**
  String get rule4Title;

  /// No description provided for @rule4Desc.
  ///
  /// In pt, this message translates to:
  /// **'Novo filme todo dia à meia-noite UTC. Compartilhe seu resultado sem spoilers e compare com amigos.'**
  String get rule4Desc;

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

  /// No description provided for @tickets.
  ///
  /// In pt, this message translates to:
  /// **'{current}/{max}'**
  String tickets(int current, int max);
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
