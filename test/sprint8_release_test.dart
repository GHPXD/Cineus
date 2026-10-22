import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/core/theme/app_fonts.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/visuals/poster_assets.dart';
import 'package:cineus/presentation/widgets/cineus_poster.dart';
import 'package:cineus/presentation/screens/settings_screen.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/reminder_notifier.dart';
import 'package:cineus/presentation/providers/game_actions.dart';
import 'package:cineus/presentation/providers/reward_notifier.dart';
import 'package:cineus/presentation/screens/font_licenses_screen.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/repositories/game_repository.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'sprint5_progression_test.dart' show progressionFixture;
import 'reminder_test.dart' show FakeNotificationService, InMemoryMeta;

class PendingHistoryRepository extends Fake implements GameRepository {
  final history = Completer<List<GameSession>>();
  @override
  Future<List<GameSession>> getFinishedDailySessions({
    GameMode mode = GameMode.clue,
  }) => history.future;
}

class FailingNotifications extends FakeNotificationService {
  String? failure;
  Completer<bool>? gate;
  @override
  Future<bool> requestPermission() async {
    if (failure == 'permission') throw StateError('permission unavailable');
    if (gate != null) {
      permissionPrompts++;
      return gate!.future;
    }
    return super.requestPermission();
  }

  @override
  Future<bool> hasPermission() async {
    if (failure == 'restore') throw StateError('permission check unavailable');
    return super.hasPermission();
  }

  @override
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (failure == 'schedule') throw StateError('schedule unavailable');
    return super.scheduleDailyReminder(
      title: title,
      body: body,
      channelName: channelName,
      channelDescription: channelDescription,
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    if (failure == 'cancel') throw StateError('cancel unavailable');
    return super.cancelDailyReminder();
  }
}

class FailingMeta extends InMemoryMeta {
  bool failRead = false, failWrite = false;
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('storage unavailable');
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('storage unavailable');
    return super.write(key, value);
  }
}

Future<ReminderNotifier> reminder(
  FailingNotifications service,
  FailingMeta meta,
) async {
  final n = ReminderNotifier(
    service: service,
    meta: meta,
    l10n: () => AppL10n.delegate.load(const Locale('pt')),
  );
  await n.ready;
  addTearDown(n.dispose);
  return n;
}

void main() {
  test(
    'late streak query must not reattach a disposed provider to the clock',
    () async {
      final games = PendingHistoryRepository();
      final c = ProviderContainer(
        overrides: [
          gameRepositoryProvider.overrideWithValue(games),
          appClockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 12)),
        ],
      );
      final subscription = c.listen(recoverableStreakDayProvider, (_, _) {});
      c.invalidate(recoverableStreakDayProvider);
      subscription.close();
      await c.pump();
      games.history.complete([
        GameSession.daily(
          mode: GameMode.clue,
          date: '2026-10-12',
          movieId: 1,
        ).copyWith(status: GameStatus.won),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(c.dispose, returnsNormally);
    },
  );
  test(
    'native URL delivery has one owner and notification uses the monochrome asset',
    () {
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains(
          'android:name="flutter_deeplinking_enabled" android:value="false"',
        ),
      );
      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        matches(RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false\s*/>')),
      );
      expect(
        File(
          'android/app/src/main/res/drawable-mdpi/cineus_monochrome.png',
        ).existsSync(),
        isTrue,
      );
    },
  );
  test(
    'post-game refresh safely ignores an already disposed provider scope',
    () {
      final c = ProviderContainer();
      final refresh = c.read(finishedGameRefreshProvider);
      c.dispose();
      expect(refresh, returnsNormally);
    },
  );
  testWidgets(
    'failed reward can be retried without paying claimed bonuses twice',
    (tester) async {
      await progressionFixture(tester, (c, db, router, ids) async {
        var fail = true, credited = 0;
        final repo = c.read(rewardRepositoryProvider);
        final n = RewardNotifier(
          rewards: repo,
          stages: c.read(stageRepositoryProvider),
          games: c.read(gameRepositoryProvider),
          credit: (amount) async {
            if (fail) {
              throw StateError('credit unavailable');
            }
            credited += amount;
          },
        );
        final won = GameSession.daily(
          mode: GameMode.clue,
          date: '2026-10-12',
          movieId: ids.first,
        ).copyWith(status: GameStatus.won, score: 10);
        try {
          await tester.runAsync(() async {
            await expectLater(n.evaluate(won), throwsStateError);
            expect(await repo.totalEarned(), 0);
            n.reportFailure(won);
            expect(n.state.hasError, isTrue);
            fail = false;
            await Future.wait([n.retryPending(), n.retryPending()]);
            expect(n.state.hasError, isFalse);
            expect(credited, greaterThan(0));
            expect(await repo.totalEarned(), credited);
            final previous = credited;
            await n.retryPending();
            await n.evaluate(won);
            expect(credited, previous);
          });
        } finally {
          n.dispose();
        }
      });
    },
  );
  testWidgets(
    'bundled font licenses are selectable and open without a database',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('pt'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const FontLicensesScreen(),
        ),
      );
      for (final family in ['Fredoka', 'Nunito']) {
        await tester.tap(find.widgetWithText(ChoiceChip, family));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        expect(
          tester.widget<SelectableText>(find.byType(SelectableText)).data,
          contains('SIL OPEN FONT LICENSE Version 1.1'),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
  test(
    'decode requests track physical pixels and stop at the original width',
    () {
      expect(PosterAssets.decodeWidth(38, 1), 64);
      expect(PosterAssets.decodeWidth(38, 3), 128);
      expect(PosterAssets.decodeWidth(120, 3), 384);
      expect(PosterAssets.decodeWidth(600, 3), 500);
      expect(PosterAssets.decodeWidth(double.infinity, 1), 500);
      expect(PosterAssets.path(1), 'assets/posters/1.jpg');
    },
  );
  testWidgets(
    'thumbnail requests a smaller image, full poster keeps source resolution',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: CineusPoster(movieId: 1, width: 38, height: 57)),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
      expect(
        (image.image as ResizeImage).width,
        PosterAssets.decodeWidth(38, tester.view.devicePixelRatio),
      );
      expect((image.image as ResizeImage).width, lessThan(500));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  for (final failure in ['permission', 'schedule']) {
    test(
      '$failure failure releases busy and retry keeps the user intent',
      () async {
        final s = FailingNotifications()..failure = failure, m = FailingMeta();
        final n = await reminder(s, m);
        await n.toggle(true);
        expect(n.state.hasError, isTrue);
        expect(n.state.busy, isFalse);
        expect(n.state.enabled, isFalse);
        expect(m.store['daily_reminder_enabled'], isNot('true'));
        s.failure = null;
        await n.retry();
        expect(n.state.enabled, isTrue);
        expect(n.state.hasError, isFalse);
      },
    );
  }
  test(
    'failed preference commit cancels the newly scheduled reminder',
    () async {
      final s = FailingNotifications(), m = FailingMeta();
      final n = await reminder(s, m);
      m.failWrite = true;
      await n.toggle(true);
      expect(s.scheduleCalls, 1);
      expect(s.cancelCalls, 1);
      expect(n.state.hasError, isTrue);
      expect(n.state.enabled, isFalse);
      expect(n.state.busy, isFalse);
      m.failWrite = false;
      await n.retry();
      expect(n.state.enabled, isTrue);
    },
  );
  test(
    'failed cancellation retry disables instead of enabling again',
    () async {
      final s = FailingNotifications(), m = FailingMeta();
      final n = await reminder(s, m);
      await n.toggle(true);
      s.failure = 'cancel';
      await n.toggle(false);
      expect(n.state.hasError, isTrue);
      expect(n.state.enabled, isTrue);
      expect(n.state.busy, isFalse);
      s.failure = null;
      await n.retry();
      expect(n.state.enabled, isFalse);
      expect(s.permissionPrompts, 1);
    },
  );
  for (final failRead in [true, false]) {
    test(
      'restore failure is recoverable and never requests new permissions ($failRead)',
      () async {
        final s = FailingNotifications(),
            m = FailingMeta()..store['daily_reminder_enabled'] = 'true';
        m.failRead = failRead;
        if (!failRead) s.failure = 'restore';
        final n = await reminder(s, m);
        expect(n.state.hasError, isTrue);
        expect(n.state.busy, isFalse);
        m.failRead = false;
        s.failure = null;
        await n.retry();
        expect(n.state.enabled, isTrue);
        expect(s.permissionPrompts, 0);
      },
    );
  }
  test('rapid toggles request permission once and disposal is safe', () async {
    final s = FailingNotifications()..gate = Completer<bool>(),
        m = FailingMeta();
    final n = ReminderNotifier(
      service: s,
      meta: m,
      l10n: () => AppL10n.delegate.load(const Locale('pt')),
    );
    await n.ready;
    final pending = n.toggle(true);
    await n.toggle(true);
    expect(s.permissionPrompts, 1);
    n.dispose();
    s.gate!.complete(true);
    await pending;
  });
  test(
    'failed localized reschedule can be retried without permission prompt',
    () async {
      final s = FailingNotifications(), m = FailingMeta();
      final n = await reminder(s, m);
      await n.toggle(true);
      s.failure = 'schedule';
      await n.refreshCopy();
      expect(n.state.hasError, isTrue);
      expect(n.state.busy, isFalse);
      s.failure = null;
      await n.retry();
      expect(n.state.hasError, isFalse);
      expect(s.permissionPrompts, 1);
    },
  );
  testWidgets('settings error exposes retry and the title fits 320px/200%', (
    tester,
  ) async {
    final s = FailingNotifications()..failure = 'schedule', m = FailingMeta();
    final c = ProviderContainer(
      overrides: [
        appMetaRepositoryProvider.overrideWithValue(m),
        notificationServiceProvider.overrideWithValue(s),
      ],
    );
    try {
      await tester.runAsync(() async {
        await (FontLoader(
          AppFonts.display,
        )..addFont(rootBundle.load('assets/fonts/Fredoka-700.ttf'))).load();
      });
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('pt'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const SettingsScreen(),
          ),
        ),
      );
      await c.read(reminderNotifierProvider.notifier).ready;
      await c.read(reminderNotifierProvider.notifier).toggle(true);
      await tester.pump();
      expect(
        find.text('Não foi possível atualizar o lembrete. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('reminder-retry')), findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Configurações'),
      );
      expect(
        paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 13),
            )
            .map((b) => b.top)
            .toSet()
            .length,
        1,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      c.dispose();
    }
  });
}
