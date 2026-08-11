// The ticket economy: earning (D1), paid hints (D12) and streak freezes (D7).
//
// `extraTickets` existed from the start but nothing ever incremented it — the
// economy was one-way. These cover the earning paths and the idempotency that
// keeps a reward from paying twice.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/data/repositories/reward_repository_impl.dart';
import 'package:cineus/domain/entities/extra_hint.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/ticket_reward.dart';

import 'support/test_database.dart';

void main() {
  GameSession wonDaily(String date, {GameMode mode = GameMode.clue}) =>
      GameSession.daily(
        mode: mode,
        date: date,
        movieId: 1,
      ).copyWith(status: GameStatus.won, score: 9);

  GameSession wonStage(int stageId, {GameMode mode = GameMode.clue}) =>
      GameSession.stage(
        mode: mode,
        stageId: stageId,
        movieId: 1,
      ).copyWith(status: GameStatus.won, score: 8);

  group('RewardRules — o que rende ticket', () {
    test('vitória diária rende o bônus do dia', () {
      final r = RewardRules.evaluate(
        finished: wonDaily('2026-08-10'),
        stageNowComplete: false,
        currentStreak: 1,
      );
      expect(r.map((x) => x.key), ['daily_win_clue_2026-08-10']);
      expect(r.single.amount, RewardRules.dailyWin);
      expect(r.single.kind, RewardKind.dailyWin);
    });

    test('derrota não rende nada', () {
      final r = RewardRules.evaluate(
        finished: GameSession.daily(
          mode: GameMode.clue,
          date: '2026-08-10',
          movieId: 1,
        ).copyWith(status: GameStatus.lost),
        stageNowComplete: false,
        currentStreak: 5,
      );
      expect(r, isEmpty);
    });

    test('marco de sequência a cada 7 dias', () {
      for (final streak in [7, 14, 21]) {
        final r = RewardRules.evaluate(
          finished: wonDaily('2026-08-10'),
          stageNowComplete: false,
          currentStreak: streak,
        );
        expect(
          r.any((x) => x.key == 'streak_$streak'),
          isTrue,
          reason: 'streak $streak',
        );
      }
      for (final streak in [1, 6, 8, 13]) {
        final r = RewardRules.evaluate(
          finished: wonDaily('2026-08-10'),
          stageNowComplete: false,
          currentStreak: streak,
        );
        expect(
          r.any((x) => x.key.startsWith('streak_')),
          isFalse,
          reason: 'streak $streak não é marco',
        );
      }
    });

    test('estágio só rende quando fecha por completo', () {
      final incompleto = RewardRules.evaluate(
        finished: wonStage(3),
        stageNowComplete: false,
        currentStreak: 0,
      );
      expect(incompleto, isEmpty);

      final completo = RewardRules.evaluate(
        finished: wonStage(3),
        stageNowComplete: true,
        currentStreak: 0,
      );
      expect(completo.single.key, 'stage_clue_3');
      expect(completo.single.amount, RewardRules.stageCompletion);
      expect(completo.single.kind, RewardKind.stageComplete);
      expect(completo.single.value, 3);
    });

    test('os dois modos rendem separadamente', () {
      final clue = RewardRules.evaluate(
        finished: wonStage(3, mode: GameMode.clue),
        stageNowComplete: true,
        currentStreak: 0,
      );
      final poster = RewardRules.evaluate(
        finished: wonStage(3, mode: GameMode.poster),
        stageNowComplete: true,
        currentStreak: 0,
      );
      expect(clue.single.key, isNot(poster.single.key));
    });

    test('partida de estágio não rende bônus diário nem sequência', () {
      final r = RewardRules.evaluate(
        finished: wonStage(1),
        stageNowComplete: false,
        currentStreak: 7,
      );
      expect(r, isEmpty);
    });
  });

  group('RewardRepository — pagar só uma vez', () {
    late Database db;
    late RewardRepositoryImpl repo;

    setUp(() async {
      db = await openTestDatabase();
      repo = RewardRepositoryImpl(
        TestDatabaseProvider(db),
        now: () => DateTime.utc(2026, 8, 10, 12),
      );
    });

    tearDown(() async => db.close());

    const reward = TicketReward(
      key: 'stage_clue_1',
      amount: 10,
      kind: RewardKind.stageComplete,
      value: 1,
    );

    test('primeira reivindicação passa, a segunda não', () async {
      expect(await repo.claim(reward), isTrue);
      expect(await repo.claim(reward), isFalse);
      expect(await repo.totalEarned(), 10);
    });

    test('acumula recompensas distintas', () async {
      await repo.claim(reward);
      await repo.claim(
        const TicketReward(
          key: 'streak_7',
          amount: 5,
          kind: RewardKind.streakMilestone,
          value: 7,
        ),
      );
      expect(await repo.totalEarned(), 15);
      expect(await repo.claimedKeys(), {'stage_clue_1', 'streak_7'});
    });

    test('congelar um dia é idempotente', () async {
      expect(await repo.freezeStreakDay('2026-08-09'), isTrue);
      expect(await repo.freezeStreakDay('2026-08-09'), isFalse);
      expect(await repo.streakFreezes(), {'2026-08-09'});
    });
  });

  group('Streak freeze muda o cálculo da sequência', () {
    final today = DateTime.utc(2026, 8, 10);

    GameSession won(String date) => GameSession.daily(
      mode: GameMode.clue,
      date: date,
      movieId: 1,
    ).copyWith(status: GameStatus.won, score: 8);

    test('sem congelar, o buraco quebra a sequência', () {
      final s = GameRepositoryImpl.computeStats([
        won('2026-08-10'),
        won('2026-08-08'),
        won('2026-08-07'),
      ], todayUtc: today);
      expect(s.currentStreak, 1);
    });

    test('congelando o dia perdido, a sequência atravessa', () {
      final s = GameRepositoryImpl.computeStats(
        [won('2026-08-10'), won('2026-08-08'), won('2026-08-07')],
        todayUtc: today,
        streakFreezes: {'2026-08-09'},
      );
      expect(s.currentStreak, 3);
    });

    test('congelar o dia errado não ajuda', () {
      final s = GameRepositoryImpl.computeStats(
        [won('2026-08-10'), won('2026-08-08')],
        todayUtc: today,
        streakFreezes: {'2026-08-05'},
      );
      expect(s.currentStreak, 1);
    });

    test('buraco de dois dias exige os dois congelados', () {
      final sessions = [won('2026-08-10'), won('2026-08-07')];
      expect(
        GameRepositoryImpl.computeStats(
          sessions,
          todayUtc: today,
          streakFreezes: {'2026-08-09'},
        ).currentStreak,
        1,
      );
      expect(
        GameRepositoryImpl.computeStats(
          sessions,
          todayUtc: today,
          streakFreezes: {'2026-08-08', '2026-08-09'},
        ).currentStreak,
        2,
      );
    });

    test('congelar não inventa vitória: totalGames não muda', () {
      final s = GameRepositoryImpl.computeStats(
        [won('2026-08-10'), won('2026-08-08')],
        todayUtc: today,
        streakFreezes: {'2026-08-09'},
      );
      expect(s.totalGames, 2);
      expect(s.totalWins, 2);
    });

    test('mantém a sequência viva quando o último jogo foi anteontem', () {
      final s = GameRepositoryImpl.computeStats(
        [won('2026-08-08'), won('2026-08-07')],
        todayUtc: today,
        streakFreezes: {'2026-08-09'},
      );
      expect(s.currentStreak, 2);
    });
  });

  group('ExtraHint', () {
    test('custa um ticket e tem emoji', () {
      for (final h in ExtraHint.values) {
        expect(h.ticketCost, 1);
        expect(h.emoji, isNotEmpty);
        // O rótulo visível vive na camada de apresentação (i18n).
      }
    });

    test('a sessão registra as dicas compradas por nome', () {
      var s = GameSession.daily(
        mode: GameMode.clue,
        date: '2026-08-10',
        movieId: 1,
      );
      expect(s.purchasedHints, isEmpty);
      expect(s.hasHint(ExtraHint.director), isFalse);

      s = s.copyWith(extraHints: [ExtraHint.director.name]);
      expect(s.hasHint(ExtraHint.director), isTrue);
      expect(s.hasHint(ExtraHint.year), isFalse);
      expect(s.purchasedHints, {ExtraHint.director});
    });

    test('nome desconhecido é ignorado em vez de estourar', () {
      final s = GameSession.daily(
        mode: GameMode.clue,
        date: '2026-08-10',
        movieId: 1,
      ).copyWith(extraHints: ['director', 'dica_que_nao_existe_mais']);
      expect(s.purchasedHints, {ExtraHint.director});
    });

    test('dicas sobrevivem ao round-trip no banco', () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final repo = GameRepositoryImpl(TestDatabaseProvider(db));

      await repo.saveSession(
        GameSession.daily(
          mode: GameMode.clue,
          date: '2026-08-10',
          movieId: 1,
        ).copyWith(extraHints: [ExtraHint.year.name, ExtraHint.runtime.name]),
      );

      final loaded = (await repo.getDailySession(GameMode.clue, '2026-08-10'))!;
      expect(loaded.purchasedHints, {ExtraHint.year, ExtraHint.runtime});
    });
  });
}
