import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/repositories/rewarded_help_repository.dart';
import 'package:cineus/domain/entities/extra_hint.dart';
import 'package:cineus/domain/services/monetization_service.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/rewarded_help_provider.dart';
import 'package:cineus/domain/entities/color_training_session.dart';
import 'color_training_session_test.dart' show trainingFixture;
import 'monetization_experience_test.dart' show ExperienceAds;
import 'support/test_database.dart';

class HelpAds extends ExperienceAds implements TrackedRewardedAds {
  int shown = 0;
  bool pending = false;
  Completer<bool>? gate;
  @override
  bool get rewardPending => pending;
  @override
  Future<bool> showRewardedTracked(
    Future<void> Function(String) started,
  ) async {
    shown++;
    await started(('attempt$shown'.padRight(43, 'a')));
    return gate?.future ?? completed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  late HelpAds ads;
  late RewardedHelpRepository journal;
  late DateTime now;
  setUp(() async {
    final db = await openTestDatabase();
    await const DatabaseSeeder().ensureCanonicalSchema(db);
    await const DatabaseSeeder().seedFromJsonAsset(db);
    await const DatabaseSeeder().syncStages(db);
    now = DateTime.utc(2026, 10, 16, 18);
    ads = HelpAds()
      ..available = true
      ..completed = true;
    c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
        monetizationServiceProvider.overrideWithValue(ads),
        appClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    await c.read(ticketNotifierProvider.notifier).ready;
    await c.read(monetizationNotifierProvider.notifier).load();
    journal = c.read(rewardedHelpRepositoryProvider);
  });

  test('fresh daily allowance is ten; bonus survives UTC renewal', () async {
    expect(c.read(ticketNotifierProvider).dailyTickets, 10);
    await c.read(ticketNotifierProvider.notifier).addTickets(4);
    await c.read(ticketNotifierProvider.notifier).debitTickets(count: 10);
    now = now.add(const Duration(days: 1));
    await c.read(ticketNotifierProvider.notifier).refreshBalance();
    expect(c.read(ticketNotifierProvider).dailyTickets, 10);
    expect(c.read(ticketNotifierProvider).extraTickets, 4);
  });

  test(
    'an existing same-day allowance is preserved until the next renewal',
    () async {
      final db = await c.read(databaseProvider).database;
      await db.update('player_tickets', {
        'daily_tickets': 17,
        'extra_tickets': 3,
      }, where: 'id=1');
      await c.read(ticketNotifierProvider.notifier).refreshBalance();
      expect(c.read(ticketNotifierProvider).total, 20);
      now = now.add(const Duration(days: 1));
      await c.read(ticketNotifierProvider.notifier).refreshBalance();
      expect(c.read(ticketNotifierProvider).total, 13);
    },
  );

  test(
    'reservations serialize across callers and attempts cannot bind two games',
    () async {
      final reservations = await Future.wait(
        List.generate(8, (_) => journal.reserve('clue:1', 'year')),
      );
      expect(reservations.where((ok) => ok), hasLength(1));
      final attempt = 'a' * 43;
      await journal.bind('clue:1', attempt);
      await journal.reserve('poster:1', 'year');
      expect(journal.bind('poster:1', attempt), throwsA(anything));
      expect(
        journal.reserve("clue:1'; DROP TABLE game_sessions", 'year'),
        throwsArgumentError,
      );
    },
  );

  test(
    'video grants selected hint plus one ticket, persists limit and preserves movie score',
    () async {
      final game = c.read(clueGameProvider.notifier);
      await game.loadStageFilm(1, 1, [1, 2, 3]);
      final session = c.read(clueGameProvider).session!;
      final score = session.potentialScore;
      final actions = c.read(rewardedHelpActionsProvider);
      Future<bool> purchase() => purchaseRoundHelp(
        c.read(ticketNotifierProvider.notifier),
        () => game.grantHint(ExtraHint.year, expectedSessionId: session.id),
      );
      final result = await actions.acquire(
        gameKey: 'clue:${session.id}',
        option: 'year',
        purchase: purchase,
      );
      expect(result, HelpResult.granted);
      expect(c.read(ticketNotifierProvider).total, 11);
      expect(c.read(clueGameProvider).purchasedHints, contains(ExtraHint.year));
      expect(c.read(clueGameProvider).session!.potentialScore, score);
      final restoredJournal = RewardedHelpRepository(
        c.read(databaseProvider),
        () => now,
      );
      expect((await restoredJournal.read('clue:${session.id}'))!.used, isTrue);
      expect(
        await actions.acquire(
          gameKey: 'clue:${session.id}',
          option: 'director',
          purchase: purchase,
        ),
        HelpResult.unavailable,
      );
      expect(ads.shown, 1);
    },
  );

  test(
    'cancelled video releases reservation without hint, credit, debit or quota',
    () async {
      ads.completed = false;
      var granted = 0;
      final result = await c
          .read(rewardedHelpActionsProvider)
          .acquire(
            gameKey: 'poster:1',
            option: 'year',
            purchase: () async {
              granted++;
              return true;
            },
          );
      expect(result, HelpResult.cancelled);
      expect(await journal.read('poster:1'), isNull);
      expect(granted, 0);
      expect(c.read(ticketNotifierProvider).total, 10);
      expect(c.read(monetizationNotifierProvider).rewardedUsedToday, 0);
    },
  );

  test(
    'delayed verified reward recovers original help with no second video',
    () async {
      ads.completed = false;
      ads.pending = true;
      final actions = c.read(rewardedHelpActionsProvider);
      Future<bool> purchase() => purchaseRoundHelp(
        c.read(ticketNotifierProvider.notifier),
        () async => true,
      );
      expect(
        await actions.acquire(
          gameKey: 'colors:training-one',
          option: 'guidance:aang',
          purchase: purchase,
        ),
        HelpResult.pending,
      );
      expect((await journal.read('colors:training-one'))!.pending, isTrue);
      expect(c.read(ticketNotifierProvider).total, 10);
      // Controlled fixture for the existing signed SSV credit callback.
      await c.read(ticketNotifierProvider.notifier).addTickets(2);
      await journal.delivered('attempt1'.padRight(43, 'a'));
      ads.pending = false;
      expect(
        await actions.acquire(
          gameKey: 'colors:training-one',
          option: 'guidance:aang',
          purchase: purchase,
        ),
        HelpResult.granted,
      );
      expect(ads.shown, 1);
      expect(c.read(ticketNotifierProvider).total, 11);
    },
  );

  test(
    'changing movie during video preserves both tickets without applying hint to next game',
    () async {
      final game = c.read(clueGameProvider.notifier);
      await game.loadStageFilm(1, 1, [1, 2, 3]);
      final old = c.read(clueGameProvider).session!;
      ads.gate = Completer<bool>();
      final result = c
          .read(rewardedHelpActionsProvider)
          .acquire(
            gameKey: 'clue:${old.id}',
            option: 'year',
            purchase: () => purchaseRoundHelp(
              c.read(ticketNotifierProvider.notifier),
              () => game.grantHint(ExtraHint.year, expectedSessionId: old.id),
            ),
          );
      while (ads.shown == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await game.loadStageFilm(1, 2, [1, 2, 3]);
      ads.gate!.complete(true);
      expect(await result, HelpResult.savedAsTickets);
      expect(c.read(clueGameProvider).purchasedHints, isEmpty);
      expect(c.read(ticketNotifierProvider).total, 12);
    },
  );

  test(
    'failed help persistence refunds the debit and never erases verified reward',
    () async {
      final result = await c
          .read(rewardedHelpActionsProvider)
          .acquire(
            gameKey: 'clue:77',
            option: 'year',
            purchase: () => purchaseRoundHelp(
              c.read(ticketNotifierProvider.notifier),
              () async => throw StateError('Disk unavailable'),
            ),
          );
      expect(result, HelpResult.failed);
      expect(c.read(ticketNotifierProvider).total, 12);
      expect((await journal.read('clue:77'))!.used, isTrue);
    },
  );

  test('three daily videos are shared by help and wallet rewards', () async {
    final n = c.read(monetizationNotifierProvider.notifier);
    expect(await n.watchRewardedForTickets(), isTrue);
    expect(await n.watchRewardedForTickets(), isTrue);
    expect(
      await c
          .read(rewardedHelpActionsProvider)
          .acquire(
            gameKey: 'poster:4',
            option: 'year',
            purchase: () => purchaseRoundHelp(
              c.read(ticketNotifierProvider.notifier),
              () async => true,
            ),
          ),
      HelpResult.granted,
    );
    expect(c.read(monetizationNotifierProvider).rewardedRemaining, 0);
    expect(
      await c
          .read(rewardedHelpActionsProvider)
          .acquire(
            gameKey: 'poster:5',
            option: 'year',
            purchase: () async => true,
          ),
      HelpResult.unavailable,
    );
  });

  test(
    'color guidance snapshots the chosen sliders, survives resume, costs one point and resets per round',
    () async {
      final questions = trainingFixture();
      final game = ColorTrainingSession.draw(questions);
      final target = game.question;
      game.choose(ColorSelection(35, 80, 70), target.id);
      expect(game.useGuidance(target.id), isTrue);
      final restored = game.clone();
      expect(restored.guidanceAt!.toJson(), [35, 80, 70]);
      expect(restored.hintUsed, isTrue);
      expect(restored.useGuidance(target.id), isFalse);
      restored.confirm(target.id);
      expect(restored.answers.single.hintUsed, isTrue);
      restored.advance(target.id);
      expect(restored.guidanceAt, isNull);
      expect(restored.hintUsed, isFalse);
    },
  );
}
