import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/screens/game_screen.dart';
import 'package:cineus/presentation/screens/visual_screen.dart';
import 'package:cineus/presentation/screens/generic_search_screen.dart';
import 'package:cineus/presentation/widgets/extra_hints_bar.dart';
import 'package:cineus/presentation/widgets/clue_card_widget.dart';
import 'package:cineus/presentation/visuals/cineus_assets.dart';
import 'support/test_database.dart';

class GateDatabase extends TestDatabaseProvider {
  Future<void>? gate;
  GateDatabase(super.db);
  @override
  Future<Database> get database async {
    if (gate != null) await gate;
    return db;
  }
}

Future<void> settleData(WidgetTester tester) async {
  for (var n = 0; n < 4; n++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> withApp(
  WidgetTester tester,
  Widget Function(ProviderContainer) screen,
  Future<void> Function(ProviderContainer, Database) action, {
  double scale = 1,
  double width = 390,
  bool last = false,
  double keyboard = 0,
  Future<void> Function(ProviderContainer, Database)? prepare,
}) async {
  late Database db;
  late ProviderContainer c;
  await tester.runAsync(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    const seed = DatabaseSeeder();
    await seed.ensureCanonicalSchema(db);
    await seed.seedFromJsonAsset(db);
    await seed.syncStages(db);
    c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(GateDatabase(db))],
    );
    await c.read(ticketNotifierProvider.notifier).ready;
    for (final provider in [clueGameProvider, posterGameProvider]) {
      await c.read(provider.notifier).loadStageFilm(1, 1, [1, 2, 3]);
      if (last) {
        while (c.read(provider).canRevealMore) {
          await c.read(provider.notifier).revealNext();
        }
      }
    }
    for (final font in {
      'Nunito': 'Nunito-400.ttf',
      'Fredoka': 'Fredoka-700.ttf',
    }.entries) {
      await (FontLoader(
        font.key,
      )..addFont(rootBundle.load('assets/fonts/${font.value}'))).load();
    }
    if (prepare != null) await prepare(c, db);
  });
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('pt'),
          theme: AppTheme.dark,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
              viewInsets: EdgeInsets.only(bottom: keyboard),
              padding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: screen(c),
        ),
      ),
    );
    await settleData(tester);
    await action(c, db);
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      c.dispose();
      await db.close();
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

Widget game(ProviderContainer c) => GameScreen(
  expectedKind: SessionKind.stage,
  onNavigateToSearch: () {},
  onNavigateToVictory: () {},
  onNavigateToDefeat: () {},
  onNavigateToStats: () {},
  onNavigateToHowToPlay: () {},
  onNavigateBack: () {},
);

Future<void> selectFirst(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Interestelar');
  await tester.pump(const Duration(milliseconds: 400));
  await settleData(tester);
  await tester.ensureVisible(find.byKey(const ValueKey('movie-option-1')));
  await tester.tap(find.byKey(const ValueKey('movie-option-1')));
  await tester.pump();
}

void main() {
  for (final mode in GameMode.values) {
    for (final last in [false, true]) {
      testWidgets(
        '${mode.name} / last=$last: 320px 200% actions and content do not overlap',
        (tester) async {
          await withApp(
            tester,
            mode == GameMode.clue
                ? game
                : (_) => const VisualScreen(expectedKind: SessionKind.stage),
            (c, db) async {
              final answer = tester.getRect(
                find.byKey(const ValueKey('game-answer')),
              );
              expect(answer.bottom, lessThanOrEqualTo(616));
              expect(answer.height, greaterThanOrEqualTo(48));
              if (last) {
                expect(find.byKey(const ValueKey('game-reveal')), findsNothing);
                expect(find.text('Última tentativa!'), findsNothing);
              }
              if (mode == GameMode.clue) {
                await Scrollable.ensureVisible(
                  tester.element(
                    find.byWidgetPredicate(
                      (w) => w is ClueCard && w.clueNumber == 10,
                    ),
                  ),
                  alignment: 1,
                );
                await tester.pump();
                final lastRect = tester.getRect(
                  find.byWidgetPredicate(
                    (w) => w is ClueCard && w.clueNumber == 10,
                  ),
                );
                expect(
                  lastRect.bottom,
                  lessThanOrEqualTo(
                    tester
                            .getTopLeft(
                              find.byKey(const ValueKey('game-actions')),
                            )
                            .dy +
                        1,
                  ),
                );
              }
            },
            scale: 2,
            width: 320,
            last: last,
          );
        },
      );
    }
  }
  testWidgets('Poster answer and reveal visible initially at 390px', (
    tester,
  ) async {
    await withApp(
      tester,
      (_) => const VisualScreen(expectedKind: SessionKind.stage),
      (c, db) async {
        for (final key in ['game-answer', 'game-reveal']) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(rect.top, greaterThan(0));
          expect(rect.bottom, lessThanOrEqualTo(616));
        }
        expect(find.text('Nível 1 de 5'), findsOneWidget);
      },
    );
  });
  testWidgets('selecting a film does not send; rapid confirms submit once', (
    tester,
  ) async {
    var sends = 0, backs = 0;
    final pending = Completer<void>();
    await withApp(
      tester,
      (_) => GenericSearchScreen(
        onBack: () {
          backs++;
        },
        onSubmitGuess: (movie) async {
          sends++;
          await pending.future;
        },
      ),
      (c, db) async {
        await selectFirst(tester);
        expect(sends, 0);
        await tester.tap(find.byKey(const ValueKey('confirm-guess')));
        await tester.tap(find.byKey(const ValueKey('confirm-guess')));
        await tester.pump();
        expect(sends, 1);
        expect(backs, 0);
        expect(
          tester.widget<TextField>(find.byType(TextField)).enabled,
          isFalse,
        );
        pending.complete();
        await tester.pump();
        expect(backs, 1);
      },
    );
  });
  testWidgets('save failure keeps selection and allows retry once', (
    tester,
  ) async {
    var sends = 0, backs = 0;
    await withApp(
      tester,
      (_) => GenericSearchScreen(
        onBack: () {
          backs++;
        },
        onSubmitGuess: (movie) async {
          if (++sends == 1) throw StateError('Temporary failure');
        },
      ),
      (c, db) async {
        await selectFirst(tester);
        await tester.tap(find.byKey(const ValueKey('confirm-guess')));
        await tester.pump();
        expect(
          find.text('Não foi possível salvar seu palpite. Tente novamente.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('selected-movie')), findsOneWidget);
        expect(backs, 0);
        await tester.tap(find.byKey(const ValueKey('confirm-guess')));
        await tester.pump();
        expect(sends, 2);
        expect(backs, 1);
      },
    );
  });
  testWidgets(
    'query edit clears pending selection and semantics include year',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await withApp(
          tester,
          (_) =>
              GenericSearchScreen(onBack: () {}, onSubmitGuess: (_) async {}),
          (c, db) async {
            await selectFirst(tester);
            expect(
              find.bySemanticsLabel('Selecionar Interestelar, 2014'),
              findsOneWidget,
            );
            await tester.enterText(find.byType(TextField), 'Titanic');
            await tester.pump();
            expect(find.byKey(const ValueKey('confirm-guess')), findsNothing);
          },
        );
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'search + selection fits 320px/200% with keyboard and safe area',
    (tester) async {
      await withApp(
        tester,
        (_) => GenericSearchScreen(onBack: () {}, onSubmitGuess: (_) async {}),
        (c, db) async {
          await selectFirst(tester);
          final button = tester.getRect(
            find.byKey(const ValueKey('confirm-guess')),
          );
          expect(button.bottom, lessThanOrEqualTo(336));
          expect(button.height, greaterThanOrEqualTo(48));
        },
        width: 320,
        scale: 2,
        keyboard: 280,
      );
    },
  );
  testWidgets(
    'reveal scrolls new clue into view without motion and announces it',
    (tester) async {
      final announcements = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
        SystemChannels.accessibility,
        (message) async {
          announcements.add(message);
          return null;
        },
      );
      try {
        await withApp(
          tester,
          game,
          (c, db) async {
            await tester.tap(find.byKey(const ValueKey('game-reveal')));
            await settleData(tester);
            expect(c.read(clueGameProvider).step, 2);
            final newCard = find.byWidgetPredicate(
              (w) => w is ClueCard && w.clueNumber == 2,
            );
            expect(tester.getRect(newCard).top, greaterThanOrEqualTo(0));
            expect(
              tester.getRect(newCard).bottom,
              lessThanOrEqualTo(
                tester
                    .getTopLeft(find.byKey(const ValueKey('game-actions')))
                    .dy,
              ),
            );
            expect(announcements.toString(), contains('Dica 2 revelada.'));
          },
          width: 320,
          scale: 2,
        );
      } finally {
        tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
          SystemChannels.accessibility,
          null,
        );
      }
    },
  );
  testWidgets(
    'reveals blocked while persisting; error recoverable with score unchanged',
    (tester) async {
      await withApp(tester, game, (c, db) async {
        await tester.runAsync(
          () => db.execute(
            "CREATE TEMP TRIGGER test_failure BEFORE UPDATE ON game_sessions BEGIN SELECT RAISE(ABORT, 'fail'); END",
          ),
        );
        await tester.tap(find.byKey(const ValueKey('game-reveal')));
        await tester.tap(find.byKey(const ValueKey('game-reveal')));
        await settleData(tester);
        expect(c.read(clueGameProvider).step, 1);
        expect(
          find.text('Não foi possível salvar a ação. Tente novamente.'),
          findsOneWidget,
        );
        await tester.runAsync(() => db.execute('DROP TRIGGER test_failure'));
        await tester.tap(find.byKey(const ValueKey('game-reveal')));
        await settleData(tester);
        expect(c.read(clueGameProvider).step, 2);
      });
    },
  );
  testWidgets(
    'hint failure refunds exact debit; retry/rapid tap purchases only once',
    (tester) async {
      await withApp(
        tester,
        (c) => Scaffold(
          body: SingleChildScrollView(
            child: Consumer(
              builder: (_, ref, __) =>
                  ExtraHintsBar(state: ref.watch(clueGameProvider)),
            ),
          ),
        ),
        (c, db) async {
          await tester.runAsync(
            () => db.execute(
              "CREATE TEMP TRIGGER test_failure BEFORE UPDATE ON game_sessions BEGIN SELECT RAISE(ABORT, 'fail'); END",
            ),
          );
          await tester.tap(find.byKey(const ValueKey('round-help-entry')));
          await settleData(tester);
          await tester.tap(find.byKey(const ValueKey('help-pay-ticket')));
          await settleData(tester);
          for (
            var n = 0;
            n < 20 &&
                find
                    .textContaining(
                      'Não foi possível concluir a compra da dica',
                    )
                    .evaluate()
                    .isEmpty;
            n++
          ) {
            await settleData(tester);
          }
          expect(c.read(ticketNotifierProvider).total, 10);
          expect(
            find.text(
              'Não foi possível concluir a compra da dica. Confira seu saldo e tente novamente.',
            ),
            findsOneWidget,
          );
          await tester.runAsync(() => db.execute('DROP TRIGGER test_failure'));
          await tester.tap(find.byKey(const ValueKey('help-pay-ticket')));
          await tester.tap(find.byKey(const ValueKey('help-pay-ticket')));
          await settleData(tester);
          expect(c.read(ticketNotifierProvider).total, 9);
          expect(c.read(clueGameProvider).purchasedHints.length, 1);
        },
      );
    },
  );
  testWidgets('empty tickets leaves the game playable and opens help choices', (
    tester,
  ) async {
    await withApp(
      tester,
      (c) => Scaffold(body: ExtraHintsBar(state: c.read(clueGameProvider))),
      (c, db) async {
        await tester.tap(find.byKey(const ValueKey('round-help-entry')));
        await settleData(tester);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('help-pay-ticket')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('help-watch-video')),
              )
              .onPressed,
          isNull,
        );
        expect(c.read(ticketNotifierProvider).total, 0);
      },
      prepare: (c, db) async {
        await c.read(ticketNotifierProvider.notifier).consumeTicket(count: 10);
      },
    );
  });
  testWidgets('leaving during hint purchase does not refund a granted hint', (
    tester,
  ) async {
    await withApp(
      tester,
      (c) => Scaffold(
        body: Consumer(
          builder: (_, ref, __) =>
              ExtraHintsBar(state: ref.watch(clueGameProvider)),
        ),
      ),
      (c, db) async {
        await tester.tap(find.byKey(const ValueKey('round-help-entry')));
        await settleData(tester);
        final pending = Completer<void>();
        final storage = c.read(databaseProvider) as GateDatabase;
        storage.gate = pending.future;
        await tester.tap(find.byKey(const ValueKey('help-pay-ticket')));
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());
        pending.complete();
        for (var n = 0; n < 8; n++) {
          await settleData(tester);
        }
        expect(c.read(ticketNotifierProvider).total, 9);
        expect(c.read(clueGameProvider).purchasedHints.length, 1);
      },
    );
  });

  test(
    'six frequent categories plus Detail/Finalization have dedicated art',
    () {
      for (final category in [
        'Trama',
        'Revelação',
        'Conceito',
        'Mecânica',
        'Contexto',
        'Conflito',
        'Detalhe',
        'Finalização',
      ]) {
        expect(CineusAssets.forCategory(category), isNotNull);
      }
    },
  );
}
